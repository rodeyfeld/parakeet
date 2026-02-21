defmodule Parakeet.Game.Supervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_game(player_names) do
    DynamicSupervisor.start_child(__MODULE__, {Parakeet.Game.Engine, player_names})
  end
end
