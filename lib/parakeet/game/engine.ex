defmodule Parakeet.Game.Engine do
	alias Parakeet.Game.{Card, CardStack, Player, Deck, Slap}
	use GenServer

	defstruct [
		:players,
		:pile,
		:challenger_idx,
		:chances,
		:challenge_card,
		:current_player_idx
	]

	def start_game(player_names) do
		players = Enum.map(player_names, fn name -> %Player{name: name} end)
		deck = CardStack.shuffle(Deck.new())

		players = Deck.deal(players, deck, 0)
		%__MODULE__{
			players: players,
			pile: %CardStack{cards: []},
			current_player_idx: 0,
			chances: 0,
			challenger_idx: nil,
			challenge_card: nil
		}
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

	defp handle_empty_hand(state) do
		players = List.update_at(state.players, state.current_player_idx, fn %Player{} = player -> %Player{player | alive: false} end)
		state = %{state | players: players}
		%{state | current_player_idx: get_next_alive_player_idx(state, state.current_player_idx)}
	end

	defp handle_challenge_initiate(state, challenge_card) do
		%{state | current_player_idx: get_next_alive_player_idx(state, state.current_player_idx), chances: Card.challenge_chances(challenge_card), challenge_card: challenge_card, challenger_idx: state.current_player_idx}
	end

	defp handle_challenge_chance(state) do
		new_chances = state.chances - 1
		cond do
			new_chances <= 0 ->
				handle_challenge_win(state)
			true ->
				%{state | chances: new_chances}

		end
	end

	defp handle_play_card(state) do
		player = Enum.at(state.players, state.current_player_idx)
		{card, hand} = CardStack.pop_top(player.hand)
		players =
				List.update_at(state.players, state.current_player_idx, fn %Player{} = player ->
					%Player{player | hand: hand}
				end)
		pile = CardStack.push_top(state.pile, card)
		state = %{state | players: players, pile: pile}
		cond do
			Card.face?(card) ->
				handle_challenge_initiate(state, card)
		  state.challenger_idx != nil ->
				handle_challenge_chance(state)
			true ->
				next_idx = get_next_alive_player_idx(state, state.current_player_idx)
				%{state | current_player_idx: next_idx}
		end
	end

	defp handle_slap_penalty(state, slapper_idx) do
		player = Enum.at(state.players, slapper_idx)
		{penalty_stack, new_hand} = CardStack.pop_top_n(player.hand, 2)
		players =
			List.update_at(state.players, slapper_idx, fn %Player{} = player ->
				%Player{player | hand: new_hand}
			end)
		pile = CardStack.push_bottom_n(state.pile, penalty_stack)
		%{state | players: players, pile: pile}
	end

	defp handle_challenge_win(state) do
		player = Enum.at(state.players, state.challenger_idx)
		{pile_stack, empty_pile} = CardStack.clear(state.pile)
		new_hand = CardStack.push_bottom_n(player.hand, pile_stack)
		players =
			List.update_at(state.players, state.challenger_idx, fn %Player{} = player ->
				%Player{player | hand: new_hand}
			end)
		%{state | challenger_idx: nil, pile: empty_pile, players: players, current_player_idx: state.challenger_idx, chances: 0, challenge_card: nil}
	end

	defp handle_slap_success(state, slapper_idx) do
		player = Enum.at(state.players, slapper_idx)
		{pile_stack, empty_pile} = CardStack.clear(state.pile)
		new_hand = CardStack.push_bottom_n(player.hand, pile_stack)
		players =
			List.update_at(state.players, slapper_idx, fn %Player{} = player ->
				%Player{player | hand: new_hand}
			end)
		%{state | challenger_idx: nil, players: players, pile: empty_pile, current_player_idx: slapper_idx, chances: 0, challenge_card: nil}
	end

	def handle_slap(state, slapper_idx) do
		case Slap.slap_type(state.pile) do
			:no_slap ->	handle_slap_penalty(state, slapper_idx)
		  _slap_type ->	handle_slap_success(state, slapper_idx)
		end
	end

	def handle_turn(state) do
		player = Enum.at(state.players, state.current_player_idx)
		cond do
			CardStack.count(player.hand) == 0 ->
				handle_empty_hand(state)
			true ->
				handle_play_card(state)
		end
	end
end
