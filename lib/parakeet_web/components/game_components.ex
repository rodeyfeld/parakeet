defmodule ParakeetWeb.GameComponents do
  use ParakeetWeb, :html

  alias Parakeet.Game.CardStack

  def format_card(nil), do: "none"
  def format_card(card), do: "#{format_face(card)}#{suit_symbol(card.suit)}"

  def format_face(%{face: :ace}), do: "A"
  def format_face(%{face: :king}), do: "K"
  def format_face(%{face: :queen}), do: "Q"
  def format_face(%{face: :jack}), do: "J"
  def format_face(%{face: :number, value: v}), do: "#{v}"

  def suit_symbol(:hearts), do: "♥"
  def suit_symbol(:diamonds), do: "♦"
  def suit_symbol(:clubs), do: "♣"
  def suit_symbol(:spades), do: "♠"

  def suit_color(:hearts), do: "text-red-400"
  def suit_color(:diamonds), do: "text-red-400"
  def suit_color(:clubs), do: "text-zinc-300"
  def suit_color(:spades), do: "text-zinc-300"

  # -- Function Components --

  def game_rules(assigns) do
    ~H"""
    <details class="group rounded-xl border border-zinc-700 bg-zinc-900/60">
      <summary class="cursor-pointer select-none px-5 py-3 flex items-center justify-between text-sm font-semibold text-zinc-300 hover:text-white transition-colors">
        <span class="flex items-center gap-2">
          <.icon
            name="hero-book-open"
            class="w-4 h-4 text-zinc-500 group-open:text-amber-400 transition-colors"
          /> How to Play
        </span>
        <.icon
          name="hero-chevron-down"
          class="w-4 h-4 text-zinc-500 group-open:rotate-180 transition-transform duration-200"
        />
      </summary>
      <div class="px-5 pb-4 pt-1 text-sm text-zinc-400 space-y-4 border-t border-zinc-800">
        <p>
          The deck is split evenly between all players. Players place cards from the top of their deck onto the pile in turn order.
          Win by collecting all the cards.
        </p>
        <div>
          <h4 class="font-semibold text-zinc-200 mb-1">Slaps</h4>
          <p class="mb-2">
            When the pile matches any of these patterns, the first player to slap takes it:
          </p>
          <ul class="space-y-1 pl-4 list-disc marker:text-zinc-600">
            <li>Two identical cards in a row</li>
            <li>A "sandwich" &mdash; two matching cards separated by one card</li>
            <li>Three cards in numeric order</li>
            <li>Queen followed by King</li>
            <li>Two numbered cards adding up to ten</li>
          </ul>
          <p class="mt-2 text-zinc-500">
            Bad slap? You lose 2 cards from your hand to the bottom of the pile.
          </p>
        </div>
        <div>
          <h4 class="font-semibold text-zinc-200 mb-1">Challenges</h4>
          <p class="mb-2">
            When a face card is played, the next player must beat it by playing their own face card within a limited number of tries.
            If they fail, the challenger takes the pile.
          </p>
          <ul class="space-y-1 pl-4 list-disc marker:text-zinc-600">
            <li><span class="font-mono text-zinc-300">Jack</span> &mdash; 1 chance</li>
            <li><span class="font-mono text-zinc-300">Queen</span> &mdash; 2 chances</li>
            <li><span class="font-mono text-zinc-300">King</span> &mdash; 3 chances</li>
            <li><span class="font-mono text-zinc-300">Ace</span> &mdash; 4 chances</li>
          </ul>
          <p class="mt-2 text-zinc-500">
            A slap can be performed at any time during a challenge.
          </p>
        </div>
      </div>
    </details>
    """
  end

  attr :winner, :string, required: true

  def game_over_banner(assigns) do
    ~H"""
    <div class="rounded-xl border border-amber-500/50 bg-gradient-to-r from-amber-900/30 to-yellow-900/20 p-6 text-center space-y-3">
      <div class="text-4xl font-black tracking-tight text-amber-300">Game Over</div>
      <div class="text-xl text-zinc-200">
        <span class="font-bold text-white">{@winner}</span> wins!
      </div>
      <div class="text-sm text-zinc-500">This game will close in 2 minutes.</div>
      <.link
        navigate={~p"/den"}
        class="inline-block mt-2 rounded-lg bg-zinc-700 hover:bg-zinc-600 text-white px-6 py-2.5 font-semibold transition-all"
      >
        Back to Lobby
      </.link>
    </div>
    """
  end

  attr :game, :map, required: true
  attr :player_idx, :any, required: true

  def game_controls(assigns) do
    my_turn? = assigns.player_idx == assigns.game.current_player_idx
    alive? = assigns.player_idx != nil and Enum.at(assigns.game.players, assigns.player_idx).alive
    current_player = Enum.at(assigns.game.players, assigns.game.current_player_idx)

    assigns =
      assigns
      |> assign(:my_turn?, my_turn?)
      |> assign(:alive?, alive?)
      |> assign(:current_player_name, current_player.name)

    ~H"""
    <div class="flex flex-col gap-3 w-48">
      <button
        phx-click="play_turn"
        id="play-turn-btn"
        disabled={not (@my_turn? and @alive?)}
        class={[
          "rounded-lg px-5 py-2.5 font-semibold transition-all w-full",
          if(@my_turn? and @alive?,
            do: "bg-emerald-600 hover:bg-emerald-500 text-white hover:scale-105 active:scale-95",
            else: "bg-zinc-800 border border-zinc-700 text-zinc-500 cursor-not-allowed"
          )
        ]}
      >
        <%= if @my_turn? and @alive? do %>
          Play Card
        <% else %>
          Waiting for {@current_player_name}...
        <% end %>
      </button>
      <button
        phx-click="slap"
        id="slap-btn"
        disabled={not @alive?}
        class={[
          "rounded-lg px-5 py-2.5 font-semibold transition-all w-full",
          if(@alive?,
            do: "bg-amber-600 hover:bg-amber-500 text-white hover:scale-105 active:scale-95",
            else: "bg-zinc-800 border border-zinc-700 text-zinc-500 cursor-not-allowed"
          )
        ]}
      >
        Slap!
      </button>
    </div>
    """
  end

  attr :player, :map, required: true
  attr :idx, :integer, required: true
  attr :current_player_idx, :integer, required: true
  attr :player_idx, :any, required: true

  def player_card(assigns) do
    ~H"""
    <div class={[
      "rounded-xl border p-4 space-y-2 transition-all",
      if(@idx == @current_player_idx,
        do: "border-emerald-500 bg-emerald-500/10 ring-2 ring-emerald-500/30",
        else: "border-zinc-700 bg-zinc-900/60"
      ),
      if(!@player.alive, do: "opacity-40"),
      if(@idx == @player_idx, do: "ring-1 ring-sky-500/40")
    ]}>
      <div class="flex items-center justify-between">
        <h3 class="font-bold text-lg">
          {@player.name}
          <%= if @idx == @player_idx do %>
            <span class="text-xs text-sky-400 font-normal">(you)</span>
          <% end %>
        </h3>
        <%= if @idx == @current_player_idx do %>
          <span class="text-xs font-semibold uppercase tracking-wider text-emerald-400 animate-pulse">
            Current
          </span>
        <% end %>
      </div>
      <div class="text-sm text-zinc-400">
        Cards: <span class="font-mono font-bold text-white">{CardStack.count(@player.hand)}</span>
      </div>
      <%= if !@player.alive do %>
        <div class="text-sm font-semibold text-red-400">Eliminated</div>
      <% end %>
    </div>
    """
  end

  attr :game, :map, required: true

  def pile(assigns) do
    visible_cards = assigns.game.pile.cards |> Enum.take(5) |> Enum.reverse()
    last_idx = max(length(visible_cards) - 1, 0)

    assigns =
      assigns
      |> assign(:visible_cards, visible_cards)
      |> assign(:last_idx, last_idx)

    ~H"""
    <div class="rounded-xl border border-zinc-700 bg-zinc-900/60 p-4 space-y-3">
      <div class="flex items-center justify-between">
        <h3 class="font-bold text-lg">Pile</h3>
        <span class="font-mono text-sm text-zinc-400">
          {CardStack.count(@game.pile)} cards
        </span>
      </div>

      <%= if length(@game.pile.cards) > 0 do %>
        <div class="flex items-end gap-1.5">
          <.playing_card
            :for={{card, i} <- Enum.with_index(@visible_cards)}
            card={card}
            top={i == @last_idx}
          />
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
    """
  end

  attr :log, :list, required: true

  def game_log(assigns) do
    ~H"""
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
    """
  end

  attr :event_flash, :map, default: nil

  def event_flash(assigns) do
    ~H"""
    <%= if @event_flash do %>
      <div
        id="event-flash"
        class="relative overflow-hidden rounded-xl border px-5 py-4 animate-fade-in-scale"
        style="animation: fade-in-scale 0.3s ease-out"
      >
        <div class={[
          "absolute inset-0 opacity-20",
          event_flash_bg(@event_flash.type)
        ]}>
        </div>
        <div class="relative flex items-center gap-3">
          <div class={[
            "flex items-center justify-center w-10 h-10 rounded-full text-lg font-bold shrink-0",
            event_flash_icon_class(@event_flash.type)
          ]}>
            {event_flash_icon(@event_flash.type)}
          </div>
          <div>
            <div class={[
              "text-lg font-bold tracking-tight",
              event_flash_text_class(@event_flash.type)
            ]}>
              {@event_flash.label}
            </div>
            <div class="text-sm text-zinc-400">{@event_flash.detail}</div>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  defp event_flash_bg(:slap), do: "bg-gradient-to-r from-amber-500 to-orange-500"
  defp event_flash_bg(:challenge_win), do: "bg-gradient-to-r from-emerald-500 to-teal-500"
  defp event_flash_bg(_), do: "bg-gradient-to-r from-zinc-500 to-zinc-600"

  defp event_flash_icon(:slap), do: "✋"
  defp event_flash_icon(:challenge_win), do: "👑"
  defp event_flash_icon(_), do: "⚡"

  defp event_flash_icon_class(:slap),
    do: "bg-amber-500/20 text-amber-300 border border-amber-500/30"

  defp event_flash_icon_class(:challenge_win),
    do: "bg-emerald-500/20 text-emerald-300 border border-emerald-500/30"

  defp event_flash_icon_class(_), do: "bg-zinc-500/20 text-zinc-300 border border-zinc-500/30"

  defp event_flash_text_class(:slap), do: "text-amber-300"
  defp event_flash_text_class(:challenge_win), do: "text-emerald-300"
  defp event_flash_text_class(_), do: "text-zinc-200"

  attr :card, :map, required: true
  attr :top, :boolean, default: false

  def playing_card(assigns) do
    ~H"""
    <div class={[
      "rounded-lg border flex flex-col items-center justify-center font-mono transition-all",
      if(@top,
        do: "w-14 h-20 text-lg border-zinc-500 bg-zinc-800",
        else: "w-10 h-14 text-xs border-zinc-700 bg-zinc-800/60 opacity-60"
      ),
      suit_color(@card.suit)
    ]}>
      <span class="font-bold">{format_face(@card)}</span>
      <span>{suit_symbol(@card.suit)}</span>
    </div>
    """
  end
end
