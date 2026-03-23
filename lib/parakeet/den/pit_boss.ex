defmodule Parakeet.Den.PitBoss do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_table(session_token, player_name, table_name, liveview_pid) do
    code = :crypto.strong_rand_bytes(3) |> Base.encode16()

    DynamicSupervisor.start_child(
      __MODULE__,
      {Parakeet.Den.Table, {session_token, player_name, table_name, code, liveview_pid}}
    )
  end

  def find_table(code) do
    case Registry.lookup(Parakeet.Den.Registry, code) do
      [{pid, _}] -> {:ok, pid}
      [] -> :not_found
    end
  end

  def find_table_by_token(session_token) do
    case Registry.lookup(Parakeet.Den.SessionRegistry, session_token) do
      [{pid, _code}] -> {:ok, pid}
      [] -> :not_found
    end
  end

  def list_tables do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.flat_map(fn {_, pid, _, _} ->
      try do
        case Parakeet.Den.Table.get_state(pid) do
          %{player_names: []} -> []
          table -> [table]
        end
      catch
        :exit, _ -> []
      end
    end)
    |> Enum.reverse()
  end
end
