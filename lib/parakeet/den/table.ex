defmodule Parakeet.Den.Table do
  alias Parakeet.Game.{Engine}
  require Logger
  use GenServer

  defstruct [
    :player_names,
    :name,
    :code,
    :engine_pid,
  ]

  def start_link({player_name, table_name, code}) do
    GenServer.start_link(__MODULE__, {player_name, table_name, code},
    name: {:via, Registry, {Parakeet.Den.Registry, code}})
  end

  @impl true
  def init({player_name, table_name, code}) do
    {:ok, create_table(player_name, table_name, code)}
  end

  def get_state(pid), do: GenServer.call(pid, :get_state)
  def start_game(pid), do: GenServer.call(pid, :start_game)
  def join(pid, player_name), do: GenServer.call(pid, {:join, player_name})


  @impl true
  def handle_call(:start_game, _from, state) do
    new_state = start_engine(state)
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:join, player_name}, _from, state) do
    new_state = join_table(state, player_name)
    {:reply, new_state, new_state}
  end

  defp create_table(player_name, table_name, code) do
    %__MODULE__{
      player_names: [player_name],
      name: table_name,
      code: code,
    }
  end

  defp start_engine(state) do
    {:ok, engine_pid} = Parakeet.Game.Supervisor.start_game(state.player_names)
    %{state | engine_pid: engine_pid}
  end

  defp join_table(state, player_name) do
    %{state | player_names: state.player_names ++ [player_name]}
  end

end
