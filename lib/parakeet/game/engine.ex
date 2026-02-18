defmodule Parakeet.Game.Engine do
    alias Parakeet.Game.{Card, CardStack, Player, Deck}
    use GenServer

    defstruct [
        :players,
        :pile,
        :challenger,

    ]

    defp start_game(player_names) do
        players = Enum.map(player_names, fn name -> %Player{name: name} end)
        deck = CardStack.shuffle(Deck.new())

        players = Deck.deal(players, deck)


        players =
            for player_name <- player_names, do: %Player{name: player_name}

        # or
      %__MODULE__{players: players}
    end



    defp add_player(%__MODULE__{players: players} = state, name) do
        %{state | players: players ++ [%Player{name: name}]}
    end


end
