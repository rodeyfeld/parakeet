defmodule Parakeet.Den.Table do
  require Logger
  use GenServer, restart: :temporary

  @grace_period_ms 30_000
  @max_players 6
  @bot_pool ~w(Polly Tweety Coco Kiwi Rio Mango Skye Pip Zazu Iago)

  @type engine_status :: :waiting | :running | :finished

  defstruct [
    :name,
    :code,
    :host,
    :engine_pid,
    players: %{},
    bots: [],
    game_status: :waiting
  ]

  def start_link({session_token, player_name, table_name, code, liveview_pid}) do
    GenServer.start_link(__MODULE__, {session_token, player_name, table_name, code, liveview_pid},
      name: {:via, Registry, {Parakeet.Den.Registry, code}}
    )
  end

  @impl true
  def init({session_token, player_name, table_name, code, liveview_pid}) do
    {:ok, create_table(session_token, player_name, table_name, code, liveview_pid)}
  end

  def get_state(pid), do: GenServer.call(pid, :get_state)
  def start_game(pid), do: GenServer.call(pid, :start_game)

  def join(pid, session_token, player_name, liveview_pid),
    do: GenServer.call(pid, {:join, session_token, player_name, liveview_pid})

  def rejoin(pid, session_token, player_name, liveview_pid),
    do: GenServer.call(pid, {:rejoin, session_token, player_name, liveview_pid})

  def leave(pid, session_token),
    do: GenServer.call(pid, {:leave, session_token})

  def engine_idx(pid, session_token),
    do: GenServer.call(pid, {:engine_idx, session_token})

  def add_bot(pid), do: GenServer.call(pid, :add_bot)
  def remove_bot(pid, bot_name), do: GenServer.call(pid, {:remove_bot, bot_name})

  def update_game_status(pid, status),
    do: GenServer.cast(pid, {:update_game_status, status})

  # --- Callbacks ---

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, to_map(state), state}
  end

  @impl true
  def handle_call(:start_game, _from, state) do
    new_state = start_engine(state)
    {:reply, to_map(new_state), new_state}
  end

  @impl true
  def handle_call({:join, session_token, player_name, liveview_pid}, _from, state) do
    new_state = handle_join(state, session_token, player_name, liveview_pid)
    {:reply, to_map(new_state), new_state}
  end

  @impl true
  def handle_call({:rejoin, session_token, player_name, liveview_pid}, _from, state) do
    new_state = handle_rejoin(state, session_token, player_name, liveview_pid)
    {:reply, to_map(new_state), new_state}
  end

  @impl true
  def handle_call({:leave, session_token}, _from, state) do
    case remove_player(state, session_token) do
      {:stop, new_state} ->
        {:stop, :normal, :ok, new_state}

      {:ok, new_state} ->
        {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call({:engine_idx, session_token}, _from, state) do
    player = Map.get(state.players, session_token)
    {:reply, if(player, do: player.engine_idx), state}
  end

  @impl true
  def handle_call(:add_bot, _from, state) do
    total = length(player_names(state))

    if total >= @max_players or state.engine_pid != nil do
      {:reply, to_map(state), state}
    else
      name = next_bot_name(state.bots)
      new_state = %{state | bots: state.bots ++ [name]}
      {:reply, to_map(new_state), new_state}
    end
  end

  @impl true
  def handle_call({:remove_bot, bot_name}, _from, state) do
    if state.engine_pid != nil do
      {:reply, to_map(state), state}
    else
      new_state = %{state | bots: List.delete(state.bots, bot_name)}
      {:reply, to_map(new_state), new_state}
    end
  end

  @impl true
  def handle_cast({:update_game_status, status}, state) do
    {:noreply, %{state | game_status: status}}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    state = handle_disconnect(state, ref)

    if state.engine_pid == nil and Enum.all?(state.players, fn {_, p} -> p.timer != nil end) do
      Logger.info("Table #{state.code} has no connected players, shutting down")
      {:stop, :normal, state}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_info({:evict, session_token}, state) do
    player = Map.get(state.players, session_token)
    label = if player, do: player.name, else: session_token
    Logger.debug("Evicting #{label} from table #{state.code}")

    case remove_player(state, session_token) do
      {:stop, new_state} ->
        Logger.info("Table #{state.code} is empty, shutting down")
        {:stop, :normal, new_state}

      {:ok, new_state} ->
        {:noreply, new_state}
    end
  end

  @impl true
  def terminate(_reason, state) do
    stop_engine(state.engine_pid)
    :ok
  end

  # --- Private ---

  defp stop_engine(nil), do: :ok

  defp stop_engine(pid) do
    if Process.alive?(pid), do: GenServer.stop(pid, :normal)
  catch
    :exit, _ -> :ok
  end

  defp create_table(session_token, player_name, table_name, code, liveview_pid) do
    ref = Process.monitor(liveview_pid)
    Registry.register(Parakeet.Den.SessionRegistry, session_token, code)

    %__MODULE__{
      name: table_name,
      code: code,
      host: session_token,
      players: %{session_token => %{name: player_name, engine_idx: nil, ref: ref, timer: nil}}
    }
  end

  defp start_engine(state) do
    human_players =
      Enum.reject(state.players, fn {_token, p} -> p.timer != nil end)

    human_specs = Enum.map(human_players, fn {_token, p} -> %{name: p.name, bot: false} end)
    bot_specs = Enum.map(state.bots, fn name -> %{name: name, bot: true} end)
    player_specs = human_specs ++ bot_specs

    {:ok, engine_pid} = Parakeet.Game.Dealer.start_game(player_specs, "game:#{state.code}")

    token_to_idx =
      human_players
      |> Enum.map(fn {token, _p} -> token end)
      |> Enum.with_index()
      |> Map.new()

    players =
      Map.new(state.players, fn {token, p} ->
        {token, %{p | engine_idx: Map.get(token_to_idx, token)}}
      end)

    human_count = map_size(token_to_idx)

    state.bots
    |> Enum.with_index(human_count)
    |> Enum.each(fn {name, idx} ->
      case Parakeet.Game.BotSupervisor.start_bot(%{
             engine_pid: engine_pid,
             player_idx: idx,
             topic: "game:#{state.code}",
             name: name
           }) do
        {:ok, pid} ->
          Logger.debug("Started bot #{name} (idx #{idx}) at #{inspect(pid)}")

        {:error, reason} ->
          Logger.error("Failed to start bot #{name}: #{inspect(reason)}")
      end
    end)

    %{state | engine_pid: engine_pid, game_status: :running, players: players}
  end

  defp handle_join(state, session_token, player_name, liveview_pid) do
    ref = Process.monitor(liveview_pid)
    Registry.register(Parakeet.Den.SessionRegistry, session_token, state.code)

    players =
      Map.put(state.players, session_token, %{
        name: player_name,
        engine_idx: nil,
        ref: ref,
        timer: nil
      })

    %{state | players: players}
  end

  defp handle_rejoin(state, session_token, player_name, liveview_pid) do
    case Map.get(state.players, session_token) do
      nil ->
        state

      player ->
        if player.timer, do: Process.cancel_timer(player.timer)
        if player.ref, do: Process.demonitor(player.ref, [:flush])
        ref = Process.monitor(liveview_pid)

        players =
          Map.put(state.players, session_token, %{
            player
            | name: player_name,
              ref: ref,
              timer: nil
          })

        %{state | players: players}
    end
  end

  defp handle_disconnect(state, ref) do
    case Enum.find(state.players, fn {_token, p} -> p.ref == ref end) do
      {session_token, player} ->
        Logger.debug("Player #{player.name} disconnected, grace period: #{@grace_period_ms}ms")
        timer = Process.send_after(self(), {:evict, session_token}, @grace_period_ms)
        players = Map.put(state.players, session_token, %{player | ref: nil, timer: timer})

        %{state | players: players}
        |> reassign_host(session_token)

      nil ->
        state
    end
  end

  defp remove_player(state, session_token) do
    case Map.pop(state.players, session_token) do
      {nil, _players} ->
        {:ok, state}

      {player, remaining} ->
        if player.ref, do: Process.demonitor(player.ref, [:flush])
        if player.timer, do: Process.cancel_timer(player.timer)
        Registry.unregister(Parakeet.Den.SessionRegistry, session_token)

        state =
          if state.engine_pid && player.engine_idx do
            game = Parakeet.Game.Engine.forfeit(state.engine_pid, player.engine_idx)

            Phoenix.PubSub.broadcast(
              Parakeet.PubSub,
              "game:#{state.code}",
              {:game_update, game, "#{player.name} left the game", nil}
            )

            if game.status == :finished, do: %{state | game_status: :finished}, else: state
          else
            state
          end

        state = %{state | players: remaining}

        if remaining == %{} do
          stop_engine(state.engine_pid)
          {:stop, state}
        else
          {:ok, state}
        end
    end
  end

  defp reassign_host(%{host: host} = state, removed_token) when host == removed_token do
    new_host = state.players |> Map.keys() |> Enum.random()
    %{state | host: new_host}
  end

  defp reassign_host(state, _removed_token), do: state

  defp player_names(state) do
    human_players =
      if state.engine_pid == nil do
        Enum.reject(state.players, fn {_token, p} -> p.timer != nil end)
      else
        state.players
      end

    human_names = Enum.map(human_players, fn {_token, p} -> p.name end)
    human_names ++ state.bots
  end

  defp next_bot_name(existing_bots) do
    Enum.find(@bot_pool, fn name -> name not in existing_bots end) ||
      "Bot #{length(existing_bots) + 1}"
  end

  defp to_map(state) do
    host_player = Map.get(state.players, state.host)

    %{
      name: state.name,
      code: state.code,
      engine_pid: state.engine_pid,
      game_status: state.game_status,
      player_names: player_names(state),
      bot_names: state.bots,
      host: if(host_player, do: host_player.name)
    }
  end
end
