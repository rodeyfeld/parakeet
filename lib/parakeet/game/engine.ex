defmodule Parakeet.Game.Engine do
  alias Parakeet.Game.{Card, CardStack, Player, Deck, Slap}
  require Logger
  use GenServer

  defstruct [
    :players,
    :pile,
    :penalty_pile,
    :challenger_idx,
    :chances,
    :challenge_card,
    :current_player_idx
  ]

  def start_link(player_names) do
    GenServer.start_link(__MODULE__, player_names)
  end

  def get_state(pid), do: GenServer.call(pid, :get_state)
  def play_turn(pid), do: GenServer.call(pid, :play_turn)
  def slap(pid, player_idx), do: GenServer.call(pid, {:slap, player_idx})

  @impl true
  def handle_call(:play_turn, _from, state) do
    new_state = handle_turn(state)
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:slap, player_idx}, _from, state) do
    new_state = handle_slap(state, player_idx)
    {:reply, new_state, new_state}
  end

  @impl true
  def init(player_names) do
    {:ok, start_game(player_names)}
  end

  defp start_game(player_names) do
    players = Enum.map(player_names, fn name -> %Player{name: name} end)
    deck = CardStack.shuffle(Deck.new())

    players = Deck.deal(players, deck, 0)

    %__MODULE__{
      players: players,
      pile: %CardStack{cards: []},
      penalty_pile: %CardStack{cards: []},
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
    Logger.debug("handle_empty_hand: player #{state.current_player_idx} has no cards")

    players =
      List.update_at(state.players, state.current_player_idx, fn %Player{} = player ->
        %Player{player | alive: false}
      end)

    state = %{state | players: players}
    %{state | current_player_idx: get_next_alive_player_idx(state, state.current_player_idx)}
  end

  defp handle_challenge_initiate(state, challenge_card) do
    Logger.debug(
      "handle_challenge_initiate: player #{state.current_player_idx} played #{challenge_card.face} (#{Card.challenge_chances(challenge_card)} chances)"
    )

    %{
      state
      | current_player_idx: get_next_alive_player_idx(state, state.current_player_idx),
        chances: Card.challenge_chances(challenge_card),
        challenge_card: challenge_card,
        challenger_idx: state.current_player_idx
    }
  end

  defp handle_challenge_chance(state) do
    Logger.debug(
      "handle_challenge_chance: player #{state.current_player_idx} uses a chance (#{state.chances - 1} remaining)"
    )

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

    Logger.debug(
      "handle_play_card: player #{state.current_player_idx} (#{player.name}) plays #{card.face} of #{card.suit} (value: #{card.value})"
    )

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

    penalty_desc =
      penalty_stack.cards
      |> Enum.map(fn c -> "#{c.face} of #{c.suit} (#{c.value})" end)
      |> Enum.join(", ")

    Logger.debug(
      "handle_slap_penalty: #{player.name} bad slap! loses #{CardStack.count(penalty_stack)} cards to penalty pile: [#{penalty_desc}]"
    )

    players =
      List.update_at(state.players, slapper_idx, fn %Player{} = player ->
        %Player{player | hand: new_hand}
      end)

    penalty_pile = CardStack.push_bottom_n(state.penalty_pile, penalty_stack)
    state = %{state | players: players, penalty_pile: penalty_pile}

    if CardStack.count(new_hand) == 0 do
      Logger.debug("handle_slap_penalty: #{player.name} lost all cards — eliminated")

      players =
        List.update_at(state.players, slapper_idx, fn %Player{} = p ->
          %Player{p | alive: false}
        end)

      %{state | players: players}
    else
      state
    end
  end

  defp handle_challenge_win(state) do
    challenger = Enum.at(state.players, state.challenger_idx)

    Logger.debug(
      "handle_challenge_win: #{challenger.name} wins the pile (#{CardStack.count(state.pile)} + #{CardStack.count(state.penalty_pile)} penalty cards) — new round"
    )

    {pile_stack, empty_pile} = CardStack.clear(state.pile)
    {pen_stack, empty_pen} = CardStack.clear(state.penalty_pile)
    new_hand = CardStack.push_bottom_n(challenger.hand, pile_stack)
    new_hand = CardStack.push_bottom_n(new_hand, pen_stack)

    players =
      List.update_at(state.players, state.challenger_idx, fn %Player{} = player ->
        %Player{player | hand: new_hand}
      end)

    %{
      state
      | challenger_idx: nil,
        pile: empty_pile,
        penalty_pile: empty_pen,
        players: players,
        current_player_idx: state.challenger_idx,
        chances: 0,
        challenge_card: nil
    }
  end

  defp handle_slap_success(state, slapper_idx) do
    slapper = Enum.at(state.players, slapper_idx)

    Logger.debug(
      "handle_slap_success: #{slapper.name} slaps and wins the pile (#{CardStack.count(state.pile)} + #{CardStack.count(state.penalty_pile)} penalty cards) — new round"
    )

    {pile_stack, empty_pile} = CardStack.clear(state.pile)
    {pen_stack, empty_pen} = CardStack.clear(state.penalty_pile)
    new_hand = CardStack.push_bottom_n(slapper.hand, pile_stack)
    new_hand = CardStack.push_bottom_n(new_hand, pen_stack)

    players =
      List.update_at(state.players, slapper_idx, fn %Player{} = player ->
        %Player{player | hand: new_hand}
      end)

    %{
      state
      | challenger_idx: nil,
        players: players,
        pile: empty_pile,
        penalty_pile: empty_pen,
        current_player_idx: slapper_idx,
        chances: 0,
        challenge_card: nil
    }
  end

  def handle_slap(state, slapper_idx) do
    slapper = Enum.at(state.players, slapper_idx)

    if not slapper.alive do
      Logger.debug("handle_slap: player #{slapper_idx} (#{slapper.name}) is dead, ignoring")
      state
    else
      Logger.debug("handle_slap: player #{slapper_idx} (#{slapper.name}) attempts slap")

      case Slap.slap_type(state.pile) do
        :no_slap -> handle_slap_penalty(state, slapper_idx)
        _slap_type -> handle_slap_success(state, slapper_idx)
      end
    end
  end

  def handle_turn(state) do
    player = Enum.at(state.players, state.current_player_idx)

    Logger.debug(
      "handle_turn: player #{state.current_player_idx} (#{player.name}), hand: #{CardStack.count(player.hand)} cards, pile: #{CardStack.count(state.pile)} cards"
    )

    cond do
      CardStack.count(player.hand) == 0 ->
        handle_empty_hand(state)

      true ->
        handle_play_card(state)
    end
  end
end
