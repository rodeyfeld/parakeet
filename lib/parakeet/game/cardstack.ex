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

  def pop_top_n(stack, 0), do: {%__MODULE__{cards: []}, stack}
  def pop_top_n(%__MODULE__{cards: []} = stack, _n), do: {%__MODULE__{cards: []}, stack}

  def pop_top_n(stack, n) do
    {card, stack} = pop_top(stack)
    {%__MODULE__{cards: popped}, stack} = pop_top_n(stack, n - 1)
    {%__MODULE__{cards: [card | popped]}, stack}
  end

  def push_top_n(stack, %__MODULE__{cards: []}), do: stack

  def push_top_n(stack, %__MODULE__{cards: [card | rest]}) do
    stack = push_top(stack, card)
    push_top_n(stack, %__MODULE__{cards: rest})
  end

  def push_bottom_n(stack, %__MODULE__{cards: []}), do: stack

  def push_bottom_n(stack, %__MODULE__{cards: [card | rest]}) do
    stack = push_bottom(stack, card)
    push_bottom_n(stack, %__MODULE__{cards: rest})
  end

  def clear(%__MODULE__{} = stack), do: {stack, %__MODULE__{cards: []}}
end
