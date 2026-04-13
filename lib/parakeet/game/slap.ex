defmodule Parakeet.Game.Slap do
  alias Parakeet.Game.{CardStack, Card}

  @type slap_type :: :no_slap | :three_in_order | :queen_king | :add_to_ten | :doubles | :sandwich
  @spec slap_type(CardStack.t()) :: slap_type()
  def slap_type(%CardStack{cards: cards}) do
    cond do
      doubles?(cards) -> :doubles
      queen_king?(cards) -> :queen_king
      sandwich?(cards) -> :sandwich
      three_in_order?(cards) -> :three_in_order
      adds_to_ten?(cards) -> :add_to_ten
      true -> :no_slap
    end
  end

  defp doubles?([top, second | _]), do: top.value == second.value
  defp doubles?(_), do: false

  defp queen_king?([top, second | _]), do: top.face == :queen and second.face == :king
  defp queen_king?(_), do: false

  defp sandwich?([top, _, third | _]), do: top.value == third.value
  defp sandwich?(_), do: false

  defp three_in_order?([top, second, third | _]) do
    ascending =
      Card.get_value_up(third) == second.value and Card.get_value_up(second) == top.value

    descending =
      Card.get_value_down(third) == second.value and Card.get_value_down(second) == top.value

    ascending or descending
  end

  defp three_in_order?(_), do: false

  defp adds_to_ten?([top, second | _]), do: top.value + second.value == 10
  defp adds_to_ten?(_), do: false

  @doc """
  Top-of-pile cards that formed the valid slap (for UI). Order is top-first (most recent play first).
  """
  @spec pattern_cards(CardStack.t(), slap_type()) :: [Card.t()]
  def pattern_cards(%CardStack{cards: cards}, slap_type)
      when slap_type in [:doubles, :queen_king, :add_to_ten] do
    Enum.take(cards, 2)
  end

  def pattern_cards(%CardStack{cards: cards}, slap_type)
      when slap_type in [:sandwich, :three_in_order] do
    Enum.take(cards, 3)
  end

  def pattern_cards(_, _), do: []
end
