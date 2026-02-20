defmodule Parakeet.Game.Engine do
	alias Parakeet.Game.{Card, CardStack, Player, Deck}
	use GenServer

	defstruct [
		:players,
		:pile,
		:challenger_idx,
		:current_player_idx
	]

	def start_game(player_names) do
		players = Enum.map(player_names, fn name -> %Player{name: name} end)
		deck = CardStack.shuffle(Deck.new())

		players = Deck.deal(players, deck, 0)
		%__MODULE__{players: players}
	end

	defp handle_empty_hand(state) do
		players = List.update_at(state.players, state.current_player_idx, fn %Player{} = player -> %Player{player | alive: false} end)
		%{state | players: players}
	end

	defp handle_play_card(state) do
		player = Enum.at(state.players, state.current_player_idx)
		{card, hand} = CardStack.pop_top(player.hand)
		players =
				List.update_at(state.players, state.current_player_idx, fn %Player{} = player ->
					%Player{player | hand: hand}
				end)
		pile = CardStack.push_top(state.pile, card)
		%{state | players: players, pile: pile}
	end



	defp get_next_alive_player_idx(state, idx) do
		next_idx = rem(idx + 1, length(state.players))
		cond do
			Enum.at(state.players, next_idx).alive == false ->
				get_next_alive_player_idx(state, next_idx)
			true ->
				next_idx
		end
	end

	def resolve_turn(state) do
		player = Enum.at(state.players, state.current_player_idx)
		state = cond do
			CardStack.count(player.hand) == 0 ->
				handle_empty_hand(state)
			true ->
				handle_play_card(state)
		end
		next_player_alive_idx = get_next_alive_player_idx(state, state.current_player_idx)
		%{state | current_player_idx: next_player_alive_idx}
	end

	# defp add_player(%__MODULE__{players: players} = state, name) do
	#     %{state | players: players ++ [%Player{name: name}]}
	# end
end
