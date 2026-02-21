defmodule ParakeetWeb.GameLive do
  use ParakeetWeb, :live_view

  alias Parakeet.Game.{Engine, CardStack}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       pid: nil,
       game: nil,
       player_names: "Alice, Bob",
       log: []
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-6">
        <h1 class="text-3xl font-bold tracking-tight">NOBOLO</h1>

        <%= if @pid == nil do %>
          <%!-- Lobby --%>
          <div class="rounded-xl border border-base-300 bg-base-200/50 p-6 space-y-4">
            <h2 class="text-lg font-semibold">Start a New Game</h2>
            <.form for={%{}} phx-submit="start_game" id="start-game-form" class="flex gap-3 items-end">
              <div class="flex-1">
                <label class="text-sm font-medium text-base-content/70 mb-1 block">
                  Player Names (comma-separated)
                </label>
                <input
                  type="text"
                  name="player_names"
                  value={@player_names}
                  class="input input-bordered w-full rounded-lg px-3 py-2 bg-base-100 border border-base-300 focus:outline-none focus:ring-2 focus:ring-primary/50"
                  placeholder="Alice, Bob, Charlie"
                />
              </div>
              <button
                type="submit"
                class="btn btn-primary rounded-lg px-6 py-2 font-semibold transition-all hover:scale-105 active:scale-95"
              >
                Start Game
              </button>
            </.form>
          </div>
        <% else %>
          <%!-- Game Board --%>
          <div class="space-y-6">
            <%!-- Controls --%>
            <div class="flex gap-3 flex-wrap">
              <button
                phx-click="play_turn"
                id="play-turn-btn"
                class="btn btn-primary rounded-lg px-5 py-2 font-semibold transition-all hover:scale-105 active:scale-95"
              >
                Play Turn
              </button>
              <%= for {player, idx} <- Enum.with_index(@game.players) do %>
                <%= if player.alive do %>
                  <button
                    phx-click="slap"
                    phx-value-idx={idx}
                    id={"slap-btn-#{idx}"}
                    class="btn btn-warning rounded-lg px-5 py-2 font-semibold transition-all hover:scale-105 active:scale-95"
                  >
                    {player.name} Slaps!
                  </button>
                <% end %>
              <% end %>
              <button
                phx-click="reset"
                id="reset-btn"
                class="btn btn-ghost rounded-lg px-5 py-2 font-semibold ml-auto transition-all hover:scale-105 active:scale-95"
              >
                Reset
              </button>
            </div>

            <%!-- Game State --%>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <%!-- Players --%>
              <%= for {player, idx} <- Enum.with_index(@game.players) do %>
                <div class={[
                  "rounded-xl border p-4 space-y-2 transition-all",
                  if(idx == @game.current_player_idx,
                    do: "border-primary bg-primary/10 ring-2 ring-primary/30",
                    else: "border-base-300 bg-base-200/50"
                  ),
                  if(!player.alive, do: "opacity-40")
                ]}>
                  <div class="flex items-center justify-between">
                    <h3 class="font-bold text-lg">{player.name}</h3>
                    <%= if idx == @game.current_player_idx do %>
                      <span class="text-xs font-semibold uppercase tracking-wider text-primary animate-pulse">
                        Current
                      </span>
                    <% end %>
                  </div>
                  <div class="text-sm text-base-content/70">
                    Cards: <span class="font-mono font-bold">{CardStack.count(player.hand)}</span>
                  </div>
                  <%= if !player.alive do %>
                    <div class="text-sm font-semibold text-error">Eliminated</div>
                  <% end %>
                </div>
              <% end %>

              <%!-- Pile --%>
              <div class="rounded-xl border border-accent bg-accent/10 p-4 space-y-2">
                <h3 class="font-bold text-lg">Pile</h3>
                <div class="text-sm text-base-content/70">
                  Cards: <span class="font-mono font-bold">{CardStack.count(@game.pile)}</span>
                </div>
                <%= if length(@game.pile.cards) > 0 do %>
                  <div class="text-sm">
                    Top: <span class="font-semibold">{format_card(hd(@game.pile.cards))}</span>
                  </div>
                <% end %>
                <%= if @game.challenger_idx != nil do %>
                  <div class="mt-2 rounded-lg bg-warning/20 border border-warning/40 px-3 py-2 text-sm">
                    <div class="font-semibold text-warning">Challenge Active!</div>
                    <div>Challenger: {Enum.at(@game.players, @game.challenger_idx).name}</div>
                    <div>Card: {format_card(@game.challenge_card)}</div>
                    <div>Chances left: <span class="font-mono font-bold">{@game.chances}</span></div>
                  </div>
                <% end %>
              </div>
            </div>

            <%!-- Log --%>
            <div class="rounded-xl border border-base-300 bg-base-200/50 p-4 space-y-2 max-h-64 overflow-y-auto">
              <h3 class="font-bold text-lg sticky top-0 bg-base-200/50">Game Log</h3>
              <div id="game-log" class="space-y-1 text-sm font-mono">
                <div class="hidden only:block text-base-content/50">No actions yet</div>
                <%= for {msg, i} <- Enum.with_index(@log) do %>
                  <div id={"log-#{i}"} class="text-base-content/80">{msg}</div>
                <% end %>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("start_game", %{"player_names" => names}, socket) do
    player_names =
      names
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    case Parakeet.Game.Supervisor.start_game(player_names) do
      {:ok, pid} ->
        game = Engine.get_state(pid)

        {:noreply,
         assign(socket,
           pid: pid,
           game: game,
           log: ["Game started with #{Enum.join(player_names, ", ")}"]
         )}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to start game: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("play_turn", _params, socket) do
    game = Engine.play_turn(socket.assigns.pid)
    current = Enum.at(game.players, game.current_player_idx)

    top_card =
      if length(game.pile.cards) > 0,
        do: format_card(hd(game.pile.cards)),
        else: "empty"

    msg = "Turn played → pile top: #{top_card}, next: #{current.name}"

    {:noreply, assign(socket, game: game, log: socket.assigns.log ++ [msg])}
  end

  @impl true
  def handle_event("slap", %{"idx" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    player = Enum.at(socket.assigns.game.players, idx)
    game = Engine.slap(socket.assigns.pid, idx)

    slapped_player = Enum.at(game.players, idx)
    old_count = CardStack.count(player.hand)
    new_count = CardStack.count(slapped_player.hand)

    msg =
      if new_count > old_count,
        do: "#{player.name} slapped! Won the pile! (#{old_count} → #{new_count} cards)",
        else: "#{player.name} bad slap! Lost 2 cards (#{old_count} → #{new_count} cards)"

    {:noreply, assign(socket, game: game, log: socket.assigns.log ++ [msg])}
  end

  @impl true
  def handle_event("reset", _params, socket) do
    if socket.assigns.pid && Process.alive?(socket.assigns.pid) do
      GenServer.stop(socket.assigns.pid)
    end

    {:noreply,
     assign(socket,
       pid: nil,
       game: nil,
       log: []
     )}
  end

  defp format_card(nil), do: "none"

  defp format_card(card) do
    face =
      case card.face do
        :ace -> "A"
        :king -> "K"
        :queen -> "Q"
        :jack -> "J"
        :number -> "#{card.value}"
      end

    suit =
      case card.suit do
        :hearts -> "♥"
        :diamonds -> "♦"
        :clubs -> "♣"
        :spades -> "♠"
      end

    "#{face}#{suit}"
  end
end
