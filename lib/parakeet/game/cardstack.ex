defmodule Parakeet.Game.CardStack do
  alias Parakeet.Game.Card

  @type cards :: [Card.t()]

  @type t :: %__MODULE__{cards: cards}

  @derive Jason.Encoder
  defstruct [:cards]

  def count(%__MODULE__{cards: cards}), do: length(cards)
  def shuffle(%__MODULE__{cards: cards}), do: %__MODULE__{cards: Enum.shuffle(cards)}

  def push_top(%__MODULE__{cards: cards}, card),
    do: %__MODULE__{cards: [card | cards]}

  def push_bottom(%__MODULE__{cards: cards}, card),
    do: %__MODULE__{cards: cards ++ [card]}

  def pop_top(%__MODULE__{cards: []}), do: :empty
  def pop_top(%__MODULE__{cards: [top | rest]}), do: {top, %__MODULE__{cards: rest}}

  def clear(%__MODULE__{cards: cards}), do: {cards, %__MODULE__{cards: []}}
end
