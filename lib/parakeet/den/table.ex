defmodule Parakeet.Den.Table do
  require Logger
  use GenServer

  @grace_period_ms 30_000

  @type engine_status :: :waiting | :running | :finished

  defstruct [
    :name,
    :code,
    :engine_pid,
    player_names: [],
    connections: %{},
    game_status: :waiting
  ]

  def start_link({player_name, table_name, code, liveview_pid}) do
    GenServer.start_link(__MODULE__, {player_name, table_name, code, liveview_pid},
      name: {:via, Registry, {Parakeet.Den.Registry, code}}
    )
  end

  @impl true
  def init({player_name, table_name, code, liveview_pid}) do
    {:ok, create_table(player_name, table_name, code, liveview_pid)}
  end

  def get_state(pid), do: GenServer.call(pid, :get_state)
  def start_game(pid), do: GenServer.call(pid, :start_game)

  def join(pid, player_name, liveview_pid),
    do: GenServer.call(pid, {:join, player_name, liveview_pid})

  def rejoin(pid, player_name, liveview_pid),
    do: GenServer.call(pid, {:rejoin, player_name, liveview_pid})

  def update_game_status(pid, status),
    do: GenServer.cast(pid, {:update_game_status, status})

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call(:start_game, _from, state) do
    new_state = start_engine(state)
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call({:join, player_name, liveview_pid}, _from, state) do
    new_state = handle_join(state, player_name, liveview_pid)
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call({:rejoin, player_name, liveview_pid}, _from, state) do
    new_state = handle_rejoin(state, player_name, liveview_pid)
    {:reply, new_state, new_state}
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
  def handle_info({:evict, player_name}, state) do
    Logger.debug("Evicting #{player_name} from table #{state.code}")

    case handle_evict(state, player_name) do
      {:stop, new_state} ->
        Logger.info("Table #{state.code} is empty, shutting down")
        {:stop, :normal, new_state}

      {:ok, new_state} ->
        {:noreply, new_state}
    end
  end

  defp create_table(player_name, table_name, code, liveview_pid) do
    ref = Process.monitor(liveview_pid)

    %__MODULE__{
      player_names: [player_name],
      name: table_name,
      code: code,
      connections: %{player_name => %{ref: ref, timer: nil}}
    }
  end

  defp start_engine(state) do
    {:ok, engine_pid} = Parakeet.Game.Supervisor.start_game(state.player_names)
    %{state | engine_pid: engine_pid, game_status: :running}
  end

  defp handle_join(state, player_name, liveview_pid) do
    ref = Process.monitor(liveview_pid)

    %{
      state
      | player_names: state.player_names ++ [player_name],
        connections: Map.put(state.connections, player_name, %{ref: ref, timer: nil})
    }
  end

  defp handle_rejoin(state, player_name, liveview_pid) do
    case Map.get(state.connections, player_name) do
      %{timer: timer} when timer != nil ->
        Process.cancel_timer(timer)
        ref = Process.monitor(liveview_pid)
        connections = Map.put(state.connections, player_name, %{ref: ref, timer: nil})
        %{state | connections: connections}

      _ ->
        state
    end
  end

  defp handle_disconnect(state, ref) do
    case Enum.find(state.connections, fn {_name, conn} -> conn.ref == ref end) do
      {player_name, _conn} ->
        Logger.debug("Player #{player_name} disconnected, grace period: #{@grace_period_ms}ms")
        timer = Process.send_after(self(), {:evict, player_name}, @grace_period_ms)
        connections = Map.put(state.connections, player_name, %{ref: nil, timer: timer})
        %{state | connections: connections}

      nil ->
        state
    end
  end

  defp handle_evict(state, player_name) do
    state = %{
      state
      | player_names: List.delete(state.player_names, player_name),
        connections: Map.delete(state.connections, player_name)
    }

    if state.player_names == [] do
      {:stop, state}
    else
      {:ok, state}
    end
  end
end
