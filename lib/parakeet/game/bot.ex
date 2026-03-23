defmodule Parakeet.Game.Bot do
  use GenServer, restart: :temporary
  require Logger

  alias Parakeet.Game.{Engine, CardStack, Slap}

  @min_play_delay_ms 500
  @max_play_delay_ms 1500
  @min_slap_delay_ms 750
  @max_slap_delay_ms 1500
  @slap_chance 0.6
  @pile_win_cooldown_ms 1500

  defstruct [
    :engine_pid,
    :player_idx,
    :topic,
    :name,
    :game,
    :play_timer,
    :slap_timer,
    cooldown_until: nil
  ]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    Process.monitor(opts.engine_pid)
    Phoenix.PubSub.subscribe(Parakeet.PubSub, opts.topic)

    game = Engine.get_state(opts.engine_pid)

    state = %__MODULE__{
      engine_pid: opts.engine_pid,
      player_idx: opts.player_idx,
      topic: opts.topic,
      name: opts.name,
      game: game
    }

    state =
      state
      |> maybe_schedule_play()
      |> maybe_schedule_slap()

    {:ok, state}
  end

  @impl true
  def handle_info({:game_update, game, _msg, event_flash}, state) do
    state = if event_flash, do: set_cooldown(state), else: state
    handle_react(react_to(state, game))
  end

  def handle_info({:game_update, game, _msg}, state) do
    handle_react(react_to(state, game))
  end

  def handle_info({:challenge_resolved, game}, state) do
    handle_react(react_to(set_cooldown(state), game))
  end

  def handle_info(:play_card, state) do
    state = %{state | play_timer: nil}
    player = Enum.at(state.game.players, state.player_idx)

    my_turn? =
      state.game.status == :running and
        state.game.current_player_idx == state.player_idx and
        player.alive and
        CardStack.count(player.hand) > 0

    if my_turn? do
      {played_card, _} = CardStack.pop_top(player.hand)
      game = Engine.play_turn(state.engine_pid, state.player_idx)

      msg = "#{state.name} plays #{format_card(played_card)}"
      broadcast_update(state, game, msg, nil)
      maybe_notify_game_over(state, game)

      %{state | game: game}
      |> react_to_own_action()
    else
      {:noreply, state}
    end
  end

  def handle_info(:attempt_slap, state) do
    state = %{state | slap_timer: nil}
    player = Enum.at(state.game.players, state.player_idx)

    if state.game.status == :running and player.alive do
      old_count = CardStack.count(player.hand)
      game = Engine.slap(state.engine_pid, state.player_idx)
      slapped_player = Enum.at(game.players, state.player_idx)
      new_count = CardStack.count(slapped_player.hand)

      {msgs, event_flash} =
        if new_count > old_count do
          label = slap_label(game.slap_type)

          flash = %{
            type: :slap,
            label: String.capitalize(label),
            detail: "#{state.name} wins the pile!"
          }

          {[
             "#{state.name} slapped #{label}! Won the pile! (#{old_count} → #{new_count} cards)",
             "── New round ── #{state.name} starts"
           ], flash}
        else
          {["#{state.name} bad slap! Lost 2 cards (#{old_count} → #{new_count} cards)"], nil}
        end

      for msg <- msgs, do: broadcast_update(state, game, msg, event_flash)
      maybe_notify_game_over(state, game)

      state = %{state | game: game}
      state = if new_count > old_count, do: set_cooldown(state), else: state

      react_to_own_action(state)
    else
      {:noreply, state}
    end
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    {:stop, :normal, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  defp handle_react({:stop, state}), do: {:stop, :normal, state}
  defp handle_react({:cont, state}), do: {:noreply, state}

  # -- Private --

  defp react_to_own_action(state) do
    if state.game.status == :finished do
      {:stop, :normal, state}
    else
      {:noreply,
       state
       |> maybe_schedule_play()
       |> maybe_schedule_slap()}
    end
  end

  defp react_to(state, game) do
    state = cancel_timers(state)
    state = %{state | game: game}

    if game.status == :finished do
      {:stop, state}
    else
      {:cont,
       state
       |> maybe_schedule_play()
       |> maybe_schedule_slap()}
    end
  end

  defp cancel_timers(state) do
    if state.play_timer, do: Process.cancel_timer(state.play_timer)
    if state.slap_timer, do: Process.cancel_timer(state.slap_timer)
    %{state | play_timer: nil, slap_timer: nil}
  end

  defp set_cooldown(state) do
    %{state | cooldown_until: System.monotonic_time(:millisecond) + @pile_win_cooldown_ms}
  end

  defp maybe_schedule_play(state) do
    player = Enum.at(state.game.players, state.player_idx)
    pending_challenge? = state.game.challenger_idx != nil and state.game.chances == 0

    can_play? =
      state.game.status == :running and
        state.game.current_player_idx == state.player_idx and
        player.alive and
        CardStack.count(player.hand) > 0 and
        not pending_challenge?

    if can_play? and state.play_timer == nil do
      now = System.monotonic_time(:millisecond)

      cooldown_remaining =
        if state.cooldown_until, do: max(state.cooldown_until - now, 0), else: 0

      delay = cooldown_remaining + Enum.random(@min_play_delay_ms..@max_play_delay_ms)
      timer = Process.send_after(self(), :play_card, delay)
      %{state | play_timer: timer}
    else
      state
    end
  end

  defp maybe_schedule_slap(state) do
    player = Enum.at(state.game.players, state.player_idx)
    now = System.monotonic_time(:millisecond)

    in_cooldown? = state.cooldown_until != nil and now < state.cooldown_until

    can_slap? =
      state.game.status == :running and
        player.alive and
        CardStack.count(state.game.pile) >= 2 and
        not in_cooldown?

    if can_slap? and state.slap_timer == nil do
      slap_type = Slap.slap_type(state.game.pile)

      if slap_type != :no_slap and :rand.uniform() <= @slap_chance do
        delay = Enum.random(@min_slap_delay_ms..@max_slap_delay_ms)
        timer = Process.send_after(self(), :attempt_slap, delay)
        %{state | slap_timer: timer}
      else
        state
      end
    else
      state
    end
  end

  defp broadcast_update(state, game, msg, event_flash) do
    Phoenix.PubSub.broadcast_from(
      Parakeet.PubSub,
      self(),
      state.topic,
      {:game_update, game, msg, event_flash}
    )
  end

  defp maybe_notify_game_over(_state, %{status: :finished, topic: topic} = game) do
    Phoenix.PubSub.broadcast(Parakeet.PubSub, topic, {:game_finished, game})
  end

  defp maybe_notify_game_over(_state, _game), do: :ok

  # Card formatting
  defp format_card(%{face: :ace, suit: s}), do: "A#{suit_sym(s)}"
  defp format_card(%{face: :king, suit: s}), do: "K#{suit_sym(s)}"
  defp format_card(%{face: :queen, suit: s}), do: "Q#{suit_sym(s)}"
  defp format_card(%{face: :jack, suit: s}), do: "J#{suit_sym(s)}"
  defp format_card(%{face: :number, value: v, suit: s}), do: "#{v}#{suit_sym(s)}"

  defp suit_sym(:hearts), do: "♥"
  defp suit_sym(:diamonds), do: "♦"
  defp suit_sym(:clubs), do: "♣"
  defp suit_sym(:spades), do: "♠"

  defp slap_label(:doubles), do: "doubles"
  defp slap_label(:sandwich), do: "sandwich"
  defp slap_label(:three_in_order), do: "three in order"
  defp slap_label(:queen_king), do: "queen-king"
  defp slap_label(:add_to_ten), do: "adds to ten"
  defp slap_label(_), do: ""
end
