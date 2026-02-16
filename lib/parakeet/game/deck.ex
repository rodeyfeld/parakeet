defmodule Parakeet.Game.Deck do
  alias Parakeet.Game.{Card, CardStack}
  @card_definitions [
    {:ace, 14},
    {:king, 13},
    {:queen, 12},
    {:jack, 11},
    {:number, 10}, {:number, 9}, {:number, 8}, {:number, 7},
    {:number, 6}, {:number, 5}, {:number, 4}, {:number, 3}, {:number, 2}
  ]

  def new do
    cards =
      for suit <- [:hearts, :diamonds, :clubs, :spades],
        {face, value} <- @card_definitions do
          %Card{face: face, suit: suit, value: value}
        end
    %CardStack{cards: cards}
  end

end
