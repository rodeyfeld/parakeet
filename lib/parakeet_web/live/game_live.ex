defmodule ParakeetWeb.GameLive do
  use ParakeetWeb, :live_view

  alias Parakeet.Den.{PitBoss, Table}
  alias Parakeet.Game.{Engine, CardStack}

  @impl true
  def mount(%{"code" => code} = params, _session, socket) do
    player_name = params["name"]

    case PitBoss.find_table(code) do
      {:ok, table_pid} ->
        table = Table.get_state(table_pid)

        cond do
          table.engine_pid == nil ->
            {:ok,
             socket
             |> put_flash(:error, "Game hasn't started yet")
             |> push_navigate(to: ~p"/den?code=#{code}&name=#{player_name}")}

          true ->
            if connected?(socket), do: Phoenix.PubSub.subscribe(Parakeet.PubSub, "game:#{code}")

            game = Engine.get_state(table.engine_pid)
            player_idx = Enum.find_index(game.players, fn p -> p.name == player_name end)

            {:ok,
             assign(socket,
               code: code,
               table_pid: table_pid,
               engine_pid: table.engine_pid,
               game: game,
               player_name: player_name,
               player_idx: player_idx,
               log: ["Game started!"]
             )}
        end

      :not_found ->
        {:ok,
         socket
         |> put_flash(:error, "Table not found")
         |> push_navigate(to: ~p"/den")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-6">
        <div class="flex items-center justify-between">
          <h1 class="text-3xl font-bold tracking-tight">NOBOLO</h1>
          <div class="flex items-center gap-3">
            <span class="text-sm text-zinc-400">
              Playing as <span class="font-semibold text-white">{@player_name}</span>
            </span>
            <.link
              navigate={~p"/den"}
              class="rounded-lg border border-zinc-700 px-4 py-2 text-sm font-medium text-zinc-400 hover:text-white hover:border-zinc-500 transition-all"
            >
              Leave Game
            </.link>
          </div>
        </div>

        <div class="space-y-6">
          <%= if @game.status == :finished do %>
            <div class="rounded-xl border border-amber-500/50 bg-gradient-to-r from-amber-900/30 to-yellow-900/20 p-6 text-center space-y-3">
              <div class="text-4xl font-black tracking-tight text-amber-300">Game Over</div>
              <div class="text-xl text-zinc-200">
                <span class="font-bold text-white">{@game.winner}</span> wins!
              </div>
              <div class="text-sm text-zinc-500">This game will close in 2 minutes.</div>
              <.link
                navigate={~p"/den"}
                class="inline-block mt-2 rounded-lg bg-zinc-700 hover:bg-zinc-600 text-white px-6 py-2.5 font-semibold transition-all"
              >
                Back to Lobby
              </.link>
            </div>
          <% else %>
            <%!-- Controls --%>
            <div class="flex gap-3 flex-wrap items-center">
              <%= if @player_idx == @game.current_player_idx do %>
                <button
                  phx-click="play_turn"
                  id="play-turn-btn"
                  class="rounded-lg bg-emerald-600 hover:bg-emerald-500 text-white px-5 py-2 font-semibold transition-all hover:scale-105 active:scale-95"
                >
                  Play Card
                </button>
              <% else %>
                <div class="rounded-lg bg-zinc-800 border border-zinc-700 px-5 py-2 text-sm text-zinc-500">
                  Waiting for {Enum.at(@game.players, @game.current_player_idx).name}...
                </div>
              <% end %>
              <%= if @player_idx != nil and Enum.at(@game.players, @player_idx).alive do %>
                <button
                  phx-click="slap"
                  id="slap-btn"
                  class="rounded-lg bg-amber-600 hover:bg-amber-500 text-white px-5 py-2 font-semibold transition-all hover:scale-105 active:scale-95"
                >
                  Slap!
                </button>
              <% end %>
            </div>
          <% end %>

          <%!-- Game State --%>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <%!-- Players --%>
            <%= for {player, idx} <- Enum.with_index(@game.players) do %>
              <div class={[
                "rounded-xl border p-4 space-y-2 transition-all",
                if(idx == @game.current_player_idx,
                  do: "border-emerald-500 bg-emerald-500/10 ring-2 ring-emerald-500/30",
                  else: "border-zinc-700 bg-zinc-900/60"
                ),
                if(!player.alive, do: "opacity-40"),
                if(idx == @player_idx, do: "ring-1 ring-sky-500/40")
              ]}>
                <div class="flex items-center justify-between">
                  <h3 class="font-bold text-lg">
                    {player.name}
                    <%= if idx == @player_idx do %>
                      <span class="text-xs text-sky-400 font-normal">(you)</span>
                    <% end %>
                  </h3>
                  <%= if idx == @game.current_player_idx do %>
                    <span class="text-xs font-semibold uppercase tracking-wider text-emerald-400 animate-pulse">
                      Current
                    </span>
                  <% end %>
                </div>
                <div class="text-sm text-zinc-400">
                  Cards:
                  <span class="font-mono font-bold text-white">{CardStack.count(player.hand)}</span>
                </div>
                <%= if !player.alive do %>
                  <div class="text-sm font-semibold text-red-400">Eliminated</div>
                <% end %>
              </div>
            <% end %>

            <%!-- Pile --%>
            <div class="rounded-xl border border-zinc-700 bg-zinc-900/60 p-4 space-y-3">
              <div class="flex items-center justify-between">
                <h3 class="font-bold text-lg">Pile</h3>
                <span class="font-mono text-sm text-zinc-400">
                  {CardStack.count(@game.pile)} cards
                </span>
              </div>

              <%= if length(@game.pile.cards) > 0 do %>
                <div class="flex items-end gap-1.5">
                  <%= for {card, i} <- @game.pile.cards |> Enum.take(5) |> Enum.reverse() |> Enum.with_index() do %>
                    <div class={[
                      "rounded-lg border flex flex-col items-center justify-center font-mono transition-all",
                      if(i == 4 or i == length(Enum.take(@game.pile.cards, 5)) - 1,
                        do: "w-14 h-20 text-lg border-zinc-500 bg-zinc-800",
                        else: "w-10 h-14 text-xs border-zinc-700 bg-zinc-800/60 opacity-60"
                      ),
                      suit_color(card.suit)
                    ]}>
                      <span class="font-bold">{format_face(card)}</span>
                      <span>{suit_symbol(card.suit)}</span>
                    </div>
                  <% end %>
                </div>
              <% else %>
                <div class="rounded-lg border border-dashed border-zinc-700 w-14 h-20 flex items-center justify-center">
                  <span class="text-zinc-600 text-xs">Empty</span>
                </div>
              <% end %>

              <%= if CardStack.count(@game.penalty_pile) > 0 do %>
                <div class="rounded-lg bg-rose-900/20 border border-rose-700/30 px-3 py-2 text-sm flex items-center gap-2">
                  <span class="text-rose-400 font-semibold">Penalty pot</span>
                  <span class="font-mono font-bold text-white">
                    {CardStack.count(@game.penalty_pile)}
                  </span>
                  <span class="text-zinc-400">cards</span>
                </div>
              <% end %>

              <%= if @game.challenger_idx != nil do %>
                <div class="rounded-lg bg-amber-900/30 border border-amber-700/40 px-3 py-2 text-sm">
                  <div class="font-semibold text-amber-400">Challenge Active!</div>
                  <div class="text-zinc-300">
                    Challenger: {Enum.at(@game.players, @game.challenger_idx).name}
                  </div>
                  <div class="text-zinc-300">Card: {format_card(@game.challenge_card)}</div>
                  <div class="text-zinc-300">
                    Chances left: <span class="font-mono font-bold text-white">{@game.chances}</span>
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <%!-- Log --%>
          <div class="rounded-xl border border-zinc-700 bg-zinc-900/60 p-4 space-y-2 max-h-64 overflow-y-auto">
            <h3 class="font-bold text-lg sticky top-0 bg-zinc-900/90 pb-1 z-10">Game Log</h3>
            <div id="game-log" class="space-y-1 text-sm font-mono">
              <div class="hidden only:block text-zinc-500">No actions yet</div>
              <%= for {msg, i} <- @log |> Enum.reverse() |> Enum.with_index() do %>
                <div
                  id={"log-#{i}"}
                  class={[
                    "text-zinc-400",
                    if(i == 0, do: "text-zinc-200 font-semibold")
                  ]}
                >
                  {msg}
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("play_turn", _params, socket) do
    old_pile_count = CardStack.count(socket.assigns.game.pile)
    game = Engine.play_turn(socket.assigns.engine_pid)
    current = Enum.at(game.players, game.current_player_idx)

    top_card =
      if length(game.pile.cards) > 0,
        do: format_card(hd(game.pile.cards)),
        else: "empty"

    msgs = ["#{current.name} plays → pile top: #{top_card}"]

    msgs =
      if old_pile_count > 0 and CardStack.count(game.pile) == 0 do
        msgs ++ ["── New round ── #{current.name} collects the pile"]
      else
        msgs
      end

    for msg <- msgs, do: broadcast_game_update(socket.assigns.code, game, msg)
    maybe_notify_game_over(socket, game)

    {:noreply, assign(socket, game: game, log: socket.assigns.log ++ msgs)}
  end

  @impl true
  def handle_event("slap", _params, socket) do
    idx = socket.assigns.player_idx
    player = Enum.at(socket.assigns.game.players, idx)
    game = Engine.slap(socket.assigns.engine_pid, idx)

    slapped_player = Enum.at(game.players, idx)
    old_count = CardStack.count(player.hand)
    new_count = CardStack.count(slapped_player.hand)

    msgs =
      if new_count > old_count do
        [
          "#{player.name} slapped! Won the pile! (#{old_count} → #{new_count} cards)",
          "── New round ── #{player.name} starts"
        ]
      else
        ["#{player.name} bad slap! Lost 2 cards (#{old_count} → #{new_count} cards)"]
      end

    for msg <- msgs, do: broadcast_game_update(socket.assigns.code, game, msg)
    maybe_notify_game_over(socket, game)

    {:noreply, assign(socket, game: game, log: socket.assigns.log ++ msgs)}
  end

  @impl true
  def handle_info({:game_update, game, msg}, socket) do
    {:noreply, assign(socket, game: game, log: socket.assigns.log ++ [msg])}
  end

  defp maybe_notify_game_over(socket, game) do
    if game.status == :finished do
      Table.update_game_status(socket.assigns.table_pid, :finished)
    end
  end

  defp broadcast_game_update(code, game, msg) do
    Phoenix.PubSub.broadcast_from(
      Parakeet.PubSub,
      self(),
      "game:#{code}",
      {:game_update, game, msg}
    )
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

  defp suit_color(:hearts), do: "text-red-400"
  defp suit_color(:diamonds), do: "text-red-400"
  defp suit_color(:clubs), do: "text-zinc-300"
  defp suit_color(:spades), do: "text-zinc-300"
end
