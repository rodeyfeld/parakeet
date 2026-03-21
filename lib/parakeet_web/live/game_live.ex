defmodule ParakeetWeb.GameLive do
  use ParakeetWeb, :live_view

  alias Parakeet.Den.{PitBoss, Table}
  alias Parakeet.Game.{Engine, CardStack}

  import ParakeetWeb.GameComponents

  @event_flash_ms 2_500

  @impl true
  def mount(%{"code" => code}, session, socket) do
    player_name = session["player_name"]

    case PitBoss.find_table(code) do
      {:ok, table_pid} ->
        table = Table.get_state(table_pid)

        cond do
          player_name == nil ->
            {:ok, push_navigate(socket, to: ~p"/")}

          table.engine_pid == nil ->
            {:ok,
             socket
             |> put_flash(:error, "Game hasn't started yet")
             |> push_navigate(to: ~p"/den")}

          true ->
            session_token = session["session_token"]

            if connected?(socket) do
              Phoenix.PubSub.subscribe(Parakeet.PubSub, "game:#{code}")
              Table.rejoin(table_pid, session_token, player_name, self())
            end

            game = Engine.get_state(table.engine_pid)
            player_idx = Table.engine_idx(table_pid, session_token)

            {:ok,
             assign(socket,
               code: code,
               table_pid: table_pid,
               session_token: session_token,
               engine_pid: table.engine_pid,
               game: game,
               player_name: player_name,
               player_idx: player_idx,
               log: ["Game started!"],
               event_flash: nil,
               event_flash_ref: nil
             )}
        end

      :not_found ->
        {:ok,
         socket
         |> put_flash(:error, "Table not found")
         |> push_navigate(to: ~p"/")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-6">
        <div class="flex items-center justify-between">
          <h1 class="text-3xl font-bold tracking-tight">Parakeet</h1>
          <div class="flex items-center gap-3">
            <span class="text-sm text-zinc-400">
              Playing as <span class="font-semibold text-white">{@player_name}</span>
            </span>
            <button
              phx-click="leave_game"
              id="leave-game-btn"
              class="rounded-lg border border-zinc-700 px-4 py-2 text-sm font-medium text-zinc-400 hover:text-white hover:border-zinc-500 transition-all"
            >
              Leave Game
            </button>
          </div>
        </div>

        <.game_rules />

        <div class="space-y-6">
          <%= if @game.status == :finished do %>
            <.game_over_banner winner={@game.winner} />
          <% else %>
            <.game_controls game={@game} player_idx={@player_idx} />
          <% end %>

          <.event_flash event_flash={@event_flash} />

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <.player_card
              :for={{player, idx} <- Enum.with_index(@game.players)}
              player={player}
              idx={idx}
              current_player_idx={@game.current_player_idx}
              player_idx={@player_idx}
            />
            <.pile game={@game} />
          </div>

          <.game_log log={@log} />
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("play_turn", _params, socket) do
    old_game = socket.assigns.game
    old_player = Enum.at(old_game.players, old_game.current_player_idx)
    {played_card, _} = CardStack.pop_top(old_player.hand)

    game = Engine.play_turn(socket.assigns.engine_pid)

    msgs = ["#{old_player.name} plays #{format_card(played_card)}"]

    {msgs, event_flash} =
      if CardStack.count(old_game.pile) > 0 and CardStack.count(game.pile) == 0 do
        collector = Enum.at(game.players, game.current_player_idx)

        flash = %{
          type: :challenge_win,
          label: "Challenge won!",
          detail: "#{collector.name} collects the pile"
        }

        {msgs ++ ["── New round ── #{collector.name} collects the pile"], flash}
      else
        {msgs, nil}
      end

    for msg <- msgs, do: broadcast_game_update(socket.assigns.code, game, msg, event_flash)
    maybe_notify_game_over(socket, game)

    socket =
      socket
      |> assign(game: game, log: socket.assigns.log ++ msgs)
      |> set_event_flash(event_flash)

    {:noreply, socket}
  end

  @impl true
  def handle_event("slap", _params, socket) do
    idx = socket.assigns.player_idx
    player = Enum.at(socket.assigns.game.players, idx)
    game = Engine.slap(socket.assigns.engine_pid, idx)

    slapped_player = Enum.at(game.players, idx)
    old_count = CardStack.count(player.hand)
    new_count = CardStack.count(slapped_player.hand)

    {msgs, event_flash} =
      if new_count > old_count do
        label = slap_label(game.slap_type)

        flash = %{
          type: :slap,
          label: String.capitalize(label),
          detail: "#{player.name} wins the pile!"
        }

        {[
           "#{player.name} slapped #{label}! Won the pile! (#{old_count} → #{new_count} cards)",
           "── New round ── #{player.name} starts"
         ], flash}
      else
        {["#{player.name} bad slap! Lost 2 cards (#{old_count} → #{new_count} cards)"], nil}
      end

    for msg <- msgs, do: broadcast_game_update(socket.assigns.code, game, msg, event_flash)
    maybe_notify_game_over(socket, game)

    socket =
      socket
      |> assign(game: game, log: socket.assigns.log ++ msgs)
      |> set_event_flash(event_flash)

    {:noreply, socket}
  end

  @impl true
  def handle_event("leave_game", _params, socket) do
    Table.leave(socket.assigns.table_pid, socket.assigns.session_token)
    {:noreply, push_navigate(socket, to: ~p"/den")}
  end

  @impl true
  def handle_info({:game_update, game, msg, event_flash}, socket) do
    socket =
      socket
      |> assign(game: game, log: socket.assigns.log ++ [msg])
      |> set_event_flash(event_flash)

    {:noreply, socket}
  end

  def handle_info({:game_update, game, msg}, socket) do
    {:noreply, assign(socket, game: game, log: socket.assigns.log ++ [msg])}
  end

  @impl true
  def handle_info(:clear_event_flash, socket) do
    {:noreply, assign(socket, event_flash: nil, event_flash_ref: nil)}
  end

  defp set_event_flash(socket, nil), do: socket

  defp set_event_flash(socket, flash) do
    if ref = socket.assigns.event_flash_ref, do: Process.cancel_timer(ref)
    ref = Process.send_after(self(), :clear_event_flash, @event_flash_ms)
    assign(socket, event_flash: flash, event_flash_ref: ref)
  end

  defp maybe_notify_game_over(socket, game) do
    if game.status == :finished do
      Table.update_game_status(socket.assigns.table_pid, :finished)
    end
  end

  defp broadcast_game_update(code, game, msg, event_flash) do
    Phoenix.PubSub.broadcast_from(
      Parakeet.PubSub,
      self(),
      "game:#{code}",
      {:game_update, game, msg, event_flash}
    )
  end

  defp slap_label(:doubles), do: "doubles"
  defp slap_label(:sandwich), do: "sandwich"
  defp slap_label(:three_in_order), do: "three in order"
  defp slap_label(:queen_king), do: "queen-king"
  defp slap_label(:add_to_ten), do: "adds to ten"
  defp slap_label(_), do: ""
end
