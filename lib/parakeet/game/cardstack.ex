defmodule Parakeet.Game.CardStack do
  alias Parakeet.Game.Card

  @type cards :: [Card.t()]

  @type t :: %__MODULE__{cards: cards}


  @derive Jason.Encoder
  defstruct [:cards]

  def count(%__MODULE__{cards: cards}), do: length(cards)
  def shuffle(%__MODULE__{cards: cards}), do:  %__MODULE__{cards: Enum.shuffle(cards)}
  def push_top(%__MODULE__{cards: cards}, card), do: [card] ++ cards
  def push_bottom(%__MODULE__{cards: cards}, card), do: cards ++ [card]
  def pop_top(%__MODULE__{cards: []}), do: nil
  def pop_top(%__MODULE__{cards: [top | rest]}), do: {top, %__MODULE__{cards: rest}}
  def clear(%__MODULE__{}), do: %__MODULE__{cards: []}
end
