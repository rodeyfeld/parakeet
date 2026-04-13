defmodule ParakeetWeb.GameChannel do
  use ParakeetWeb, :channel

  alias Parakeet.Den.{PitBoss, Table}
  alias Parakeet.Game.{Card, CardStack, Engine, Slap}

  @impl true
  def join("game:" <> code, _params, socket) do
    session_token = socket.assigns.session_token
    player_name = socket.assigns.player_name

    case PitBoss.find_table(code) do
      {:ok, table_pid} ->
        table = Table.get_state(table_pid)

        cond do
          table.engine_pid == nil ->
            {:error, %{reason: "game_not_started"}}

          safe_get_state(table.engine_pid) == nil ->
            {:error, %{reason: "game_ended"}}

          true ->
            Phoenix.PubSub.subscribe(Parakeet.PubSub, "game:#{code}")
            Table.rejoin(table_pid, session_token, player_name, self())
            player_idx = Table.engine_idx(table_pid, session_token)
            game = Engine.get_state(table.engine_pid)

            socket =
              socket
              |> assign(:code, code)
              |> assign(:table_pid, table_pid)
              |> assign(:engine_pid, table.engine_pid)
              |> assign(:player_idx, player_idx)
              |> assign(:game, game)

            send(self(), :after_join)
            {:ok, socket}
        end

      :not_found ->
        {:error, %{reason: "table_not_found"}}
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    push(socket, "game_state", %{
      game: serialize_game(socket.assigns.game, socket.assigns.player_idx),
      log: "Game started!",
      event_flash: nil
    })

    {:noreply, socket}
  end

  def handle_info({:game_update, game, msg, event_flash}, socket) do
    maybe_notify_game_over(socket, game)
    socket = assign(socket, :game, game)

    push(socket, "game_state", %{
      game: serialize_game(game, socket.assigns.player_idx),
      log: msg,
      event_flash: serialize_event_flash(event_flash)
    })

    {:noreply, socket}
  end

  def handle_info({:game_update, game, msg}, socket) do
    maybe_notify_game_over(socket, game)
    socket = assign(socket, :game, game)

    push(socket, "game_state", %{
      game: serialize_game(game, socket.assigns.player_idx),
      log: msg,
      event_flash: nil
    })

    {:noreply, socket}
  end

  def handle_info({:game_finished, game}, socket) do
    Table.update_game_status(socket.assigns.table_pid, :finished)
    socket = assign(socket, :game, game)

    push(socket, "game_over", %{
      game: serialize_game(game, socket.assigns.player_idx)
    })

    {:noreply, socket}
  end

  def handle_info({:play_intent, player_idx, active}, socket) do
    push(socket, "play_intent", %{player_idx: player_idx, active: active})
    {:noreply, socket}
  end

  def handle_info({:challenge_resolved, game, challenge_card, pile_size}, socket) do
    maybe_notify_game_over(socket, game)
    winner = Enum.at(game.players, game.current_player_idx)
    socket = assign(socket, :game, game)

    push(socket, "game_state", %{
      game: serialize_game(game, socket.assigns.player_idx),
      log: "── New round ── #{winner.name} collects the pile",
      event_flash: %{
        type: "challenge_win",
        label: "Challenge",
        detail: "#{winner.name} wins #{pile_size} cards",
        winner_idx: game.current_player_idx,
        challenge_card: serialize_card(challenge_card),
        pile_size: pile_size
      }
    })

    {:noreply, socket}
  end

  @impl true
  def handle_in("play_intent", %{"active" => active}, socket) when is_boolean(active) do
    game = socket.assigns.game
    me = socket.assigns.player_idx
    player = Enum.at(game.players, me)

    valid? =
      game.status == :running and
        me == game.current_player_idx and
        player.alive and
        not player.bot

    if valid? do
      Phoenix.PubSub.broadcast_from(
        Parakeet.PubSub,
        self(),
        "game:#{socket.assigns.code}",
        {:play_intent, me, active}
      )
    end

    {:noreply, socket}
  end

  @impl true
  def handle_in("play_turn", _params, socket) do
    game = socket.assigns.game
    idx = socket.assigns.player_idx
    current_player = Enum.at(game.players, game.current_player_idx)

    cond do
      idx != game.current_player_idx ->
        {:noreply, socket}

      CardStack.count(current_player.hand) == 0 ->
        {:noreply, socket}

      true ->
        {played_card, _} = CardStack.pop_top(current_player.hand)
        new_game = Engine.play_turn(socket.assigns.engine_pid)
        msg = "#{current_player.name} plays #{format_card(played_card)}"

        broadcast_game_update(socket.assigns.code, new_game, msg, nil)
        maybe_notify_game_over(socket, new_game)

        push(socket, "game_state", %{
          game: serialize_game(new_game, socket.assigns.player_idx),
          log: msg,
          event_flash: nil
        })

        {:noreply, assign(socket, :game, new_game)}
    end
  end

  def handle_in("slap", _params, socket) do
    idx = socket.assigns.player_idx
    game = socket.assigns.game
    player = Enum.at(game.players, idx)

    if player == nil or not player.alive do
      {:noreply, socket}
    else
      old_count = CardStack.count(player.hand)
      old_pile = game.pile
      old_pile_size = CardStack.count(game.pile) + CardStack.count(game.penalty_pile)
      new_game = Engine.slap(socket.assigns.engine_pid, idx)
      slapped_player = Enum.at(new_game.players, idx)
      new_count = CardStack.count(slapped_player.hand)

      {msgs, event_flash} =
        if new_count > old_count do
          slap_t = new_game.slap_type
          label = slap_label(slap_t)

          slap_cards =
            old_pile
            |> Slap.pattern_cards(slap_t)
            |> Enum.map(&Card.to_client_map/1)

          flash = %{
            type: "slap",
            label: String.capitalize(label),
            detail: "#{player.name} wins #{old_pile_size} cards",
            winner_idx: idx,
            pile_size: old_pile_size,
            slap_cards: slap_cards
          }

          {[
             "#{player.name} slapped #{label}! Won the pile! (#{old_count} → #{new_count} cards)",
             "── New round ── #{player.name} starts"
           ], flash}
        else
          {["#{player.name} bad slap! Lost 2 cards (#{old_count} → #{new_count} cards)"], nil}
        end

      [first | rest] = msgs
      broadcast_game_update(socket.assigns.code, new_game, first, event_flash)

      for msg <- rest do
        broadcast_game_update(socket.assigns.code, new_game, msg, nil)
      end

      maybe_notify_game_over(socket, new_game)

      last_msg = List.last(msgs)

      push(socket, "game_state", %{
        game: serialize_game(new_game, socket.assigns.player_idx),
        log: last_msg,
        event_flash: serialize_event_flash(event_flash)
      })

      {:noreply, assign(socket, :game, new_game)}
    end
  end

  def handle_in("leave_game", _params, socket) do
    Table.leave(socket.assigns.table_pid, socket.assigns.session_token)
    {:reply, :ok, socket}
  end

  # -- Serialization --

  defp serialize_game(game, player_idx) do
    pile_cards = Enum.take(game.pile.cards, 4)
    pile_size = CardStack.count(game.pile)

    pile_transforms =
      pile_cards
      |> Enum.with_index()
      |> Enum.map(fn {card, i} ->
        seed = {pile_size - i, card.face, card.suit, Map.get(card, :value, 0)}
        angle = rem(:erlang.phash2(seed), 360)

        %{
          card: serialize_card(card),
          angle: angle
        }
      end)

    %{
      players:
        game.players
        |> Enum.with_index()
        |> Enum.map(fn {p, idx} ->
          %{
            name: p.name,
            alive: p.alive,
            card_count: CardStack.count(p.hand),
            bot: p.bot,
            idx: idx
          }
        end),
      pile: %{
        cards: pile_transforms,
        size: pile_size
      },
      penalty_count: CardStack.count(game.penalty_pile),
      current_player_idx: game.current_player_idx,
      challenger_idx: game.challenger_idx,
      chances: game.chances,
      challenge_card: serialize_card(game.challenge_card),
      status: game.status,
      winner: game.winner,
      slap_type: game.slap_type,
      player_idx: player_idx,
      slap_window_ms: Engine.slap_window_ms()
    }
  end

  defp serialize_card(nil), do: nil

  defp serialize_card(card), do: Card.to_client_map(card)

  defp serialize_event_flash(nil), do: nil

  defp serialize_event_flash(flash) do
    base = %{
      type: to_string(flash.type),
      label: flash[:label],
      detail: flash.detail,
      winner_idx: flash[:winner_idx],
      pile_size: flash[:pile_size]
    }

    base
    |> maybe_put(:challenge_card, flash[:challenge_card])
    |> maybe_put(:slap_cards, flash[:slap_cards])
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, val), do: Map.put(map, key, val)

  # -- Helpers --

  defp broadcast_game_update(code, game, msg, event_flash) do
    Phoenix.PubSub.broadcast_from(
      Parakeet.PubSub,
      self(),
      "game:#{code}",
      {:game_update, game, msg, event_flash}
    )
  end

  defp maybe_notify_game_over(socket, game) do
    if game.status == :finished do
      Table.update_game_status(socket.assigns.table_pid, :finished)
    end
  end

  defp safe_get_state(pid) do
    Engine.get_state(pid)
  catch
    :exit, _ -> nil
  end

  defp format_card(nil), do: "none"
  defp format_card(card), do: "#{format_face(card)}#{suit_symbol(card.suit)}"

  defp format_face(%{face: :ace}), do: "A"
  defp format_face(%{face: :king}), do: "K"
  defp format_face(%{face: :queen}), do: "Q"
  defp format_face(%{face: :jack}), do: "J"
  defp format_face(%{face: :number, value: v}), do: "#{v}"

  defp suit_symbol(:hearts), do: "♥"
  defp suit_symbol(:diamonds), do: "♦"
  defp suit_symbol(:clubs), do: "♣"
  defp suit_symbol(:spades), do: "♠"

  defp slap_label(:doubles), do: "doubles"
  defp slap_label(:sandwich), do: "sandwich"
  defp slap_label(:three_in_order), do: "three in order"
  defp slap_label(:queen_king), do: "queen-king"
  defp slap_label(:add_to_ten), do: "adds to ten"
  defp slap_label(_), do: ""
end
