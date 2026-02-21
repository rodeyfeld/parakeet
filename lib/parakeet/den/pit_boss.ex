defmodule Parakeet.Den.PitBoss do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_table(player_name, table_name, liveview_pid) do
    code = :crypto.strong_rand_bytes(3) |> Base.encode16()

    DynamicSupervisor.start_child(
      __MODULE__,
      {Parakeet.Den.Table, {player_name, table_name, code, liveview_pid}}
    )
  end

  def find_table(code) do
    case Registry.lookup(Parakeet.Den.Registry, code) do
      [{pid, _}] -> {:ok, pid}
      [] -> :not_found
    end
  end

  def list_tables do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.map(fn {_, pid, _, _} ->
      Parakeet.Den.Table.get_state(pid)
    end)
  end
end
