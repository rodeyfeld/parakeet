defmodule Parakeet.Den.Table do
  require Logger
  use GenServer

  @grace_period_ms 30_000

  @type engine_status :: :waiting | :running | :finished

  defstruct [
    :name,
    :code,
    :host,
    :engine_pid,
    players: %{},
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

  def rejoin(pid, session_token, liveview_pid),
    do: GenServer.call(pid, {:rejoin, session_token, liveview_pid})

  def leave(pid, session_token),
    do: GenServer.call(pid, {:leave, session_token})

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
  def handle_call({:rejoin, session_token, liveview_pid}, _from, state) do
    new_state = handle_rejoin(state, session_token, liveview_pid)
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
  def handle_cast({:update_game_status, status}, state) do
    {:noreply, %{state | game_status: status}}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    {:noreply, handle_disconnect(state, ref)}
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

  # --- Private ---

  defp create_table(session_token, player_name, table_name, code, liveview_pid) do
    ref = Process.monitor(liveview_pid)
    Registry.register(Parakeet.Den.SessionRegistry, session_token, code)

    %__MODULE__{
      name: table_name,
      code: code,
      host: session_token,
      players: %{session_token => %{name: player_name, ref: ref, timer: nil}}
    }
  end

  defp start_engine(state) do
    {:ok, engine_pid} = Parakeet.Game.Dealer.start_game(player_names(state))
    %{state | engine_pid: engine_pid, game_status: :running}
  end

  defp handle_join(state, session_token, player_name, liveview_pid) do
    ref = Process.monitor(liveview_pid)
    Registry.register(Parakeet.Den.SessionRegistry, session_token, state.code)

    players =
      Map.put(state.players, session_token, %{name: player_name, ref: ref, timer: nil})

    %{state | players: players}
  end

  defp handle_rejoin(state, session_token, liveview_pid) do
    case Map.get(state.players, session_token) do
      %{timer: timer} = player when timer != nil ->
        Process.cancel_timer(timer)
        ref = Process.monitor(liveview_pid)
        players = Map.put(state.players, session_token, %{player | ref: ref, timer: nil})
        %{state | players: players}

      _ ->
        state
    end
  end

  defp handle_disconnect(state, ref) do
    case Enum.find(state.players, fn {_token, p} -> p.ref == ref end) do
      {session_token, player} ->
        Logger.debug("Player #{player.name} disconnected, grace period: #{@grace_period_ms}ms")
        timer = Process.send_after(self(), {:evict, session_token}, @grace_period_ms)
        players = Map.put(state.players, session_token, %{player | ref: nil, timer: timer})

        %{state | players: players}
        |> maybe_reassign_host(session_token)

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

        state = %{state | players: remaining}

        if remaining == %{}, do: {:stop, state}, else: {:ok, state}
    end
  end

  defp maybe_reassign_host(%{host: host} = state, removed_token) when host == removed_token do
    new_host = state.players |> Map.keys() |> Enum.random()
    %{state | host: new_host}
  end

  defp maybe_reassign_host(state, _removed_token), do: state

  defp player_names(state) do
    Enum.map(state.players, fn {_token, p} -> p.name end)
  end

  defp to_map(state) do
    host_player = Map.get(state.players, state.host)

    %{
      name: state.name,
      code: state.code,
      engine_pid: state.engine_pid,
      game_status: state.game_status,
      player_names: player_names(state),
      host: if(host_player, do: host_player.name)
    }
  end
end
