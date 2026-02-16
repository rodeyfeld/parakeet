defmodule Parakeet.Game.Slap do
  alias Parakeet.Game.{CardStack, Card}

  @type slap_types :: :no_slap | :three_in_order | :king_queen | :add_to_ten | :doubles | :sandwich

  # def is_valid_slap(cards: cards), do

  # end

  def three_in_order?(%CardStack{cards: [top, second, third | _]}) do
    ascending = (Card.get_value_up(third) == second.value and Card.get_value_up(second) == top.value)
    descending = (Card.get_value_down(third) == second.value and Card.get_value_down(second) == top.value)

    ascending or descending
  end
  def three_in_order?(%CardStack{}), do: false
end
