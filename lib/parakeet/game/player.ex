defmodule Parakeet.Game.Player do
  alias Parakeet.Game.CardStack

  @type t :: %__MODULE__{name: String.t(), alive: boolean(), hand: CardStack.t()}


  @derive Jason.Encoder
  defstruct [:name, alive: true, hand: %CardStack{}]
end
