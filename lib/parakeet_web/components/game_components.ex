defmodule ParakeetWeb.GameComponents do
  use ParakeetWeb, :html

  alias Parakeet.Game.CardStack

  @parrot_body_d "M418.133,401.067c0-4.71-3.814-8.533-8.533-8.533c-35.507,0-126.652-2.867-205.781-29.423c-89.941-30.182-135.552-80.572-135.552-149.769c0-119.236,50.244-196.275,128-196.275c17.161,0,31.838,6.391,41.361,17.997c5.854,7.142,9.438,15.889,10.795,25.566c0.026,0.307,0.085,0.589,0.137,0.887c0.87,6.972,0.623,14.404-0.93,22.144c-0.922,4.617,2.082,9.114,6.699,10.035c4.617,0.93,9.114-2.065,10.035-6.69c0.35-1.741,0.538-3.456,0.785-5.18c9.839,15.821,7.578,31.607,4.506,41.182c-17.775-10.76-33.758-3.038-34.534-2.637c-4.215,2.108-5.931,7.228-3.823,11.443c2.116,4.215,7.228,5.922,11.452,3.823c0.111-0.068,11.691-5.658,24.286,6.929c1.604,1.613,3.78,2.5,6.033,2.5c0.35,0,0.691-0.017,1.041-0.06c2.611-0.324,4.924-1.835,6.272-4.079c9.916-16.521,18.876-54.989-15.437-85.077c-2.039-11.802-6.733-22.596-14.123-31.607C238.003,8.61,218.633,0,196.267,0C109.5,0,51.2,85.734,51.2,213.342c0,77.338,49.527,133.171,147.191,165.948c81.51,27.358,174.857,30.31,211.209,30.31C414.319,409.6,418.133,405.777,418.133,401.067z"
  @parrot_eye_d "M187.733,68.267c0,9.412,7.654,17.067,17.067,17.067s17.067-7.654,17.067-17.067c0-9.412-7.654-17.067-17.067-17.067S187.733,58.854,187.733,68.267z"
  @parrot_wing_d "M355.9,215.834C319.232,179.157,242.338,153.6,196.267,153.6c-62.285,0-93.867,22.963-93.867,68.267c0,64.58,119.151,136.533,290.133,136.533c4.719,0,8.533-3.823,8.533-8.533s-3.814-8.533-8.533-8.533c-153.788,0-273.067-64.222-273.067-119.467c0-23.834,8.73-51.2,76.8-51.2c15.59,0,33.698,3.012,52.036,8.064c-13.244,14.865-32.239,45.679-25.071,95.548c0.614,4.258,4.267,7.322,8.439,7.322c0.401,0,0.811-0.026,1.229-0.085c4.668-0.674,7.902-5.001,7.236-9.668c-7.552-52.48,17.749-79.701,26.53-87.424c12.655,4.403,25.02,9.694,36.412,15.531c-13.773,13.986-36.582,44.817-29.926,91.392c0.606,4.25,4.258,7.322,8.44,7.322c0.401,0,0.811-0.026,1.22-0.085c4.668-0.666,7.902-4.992,7.236-9.66c-6.255-43.759,18.347-71.04,28.518-80.265c9.916,6.118,18.628,12.604,25.267,19.243c1.63,1.63,4.045,4.181,6.818,7.262c-15.053,11.639-32.512,36.002-26.266,73.446c0.691,4.164,4.309,7.125,8.405,7.125c0.469,0,0.93-0.034,1.408-0.119c4.651-0.768,7.791-5.171,7.014-9.822c-5.513-33.101,11.255-50.586,20.446-57.489c28.911,36.591,78.319,116.685,81.877,240.939c-53.675-29.611-68.676-57.301-68.992-57.907c-2.116-4.181-7.228-5.871-11.426-3.772c-4.216,2.116-5.931,7.236-3.823,11.452c0.751,1.502,19.149,37.077,89.156,72.09c1.203,0.597,2.509,0.896,3.814,0.896c1.562,0,3.115-0.427,4.48-1.271c2.517-1.553,4.053-4.301,4.053-7.262C460.8,333.909,380.51,240.444,355.9,215.834z"

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

  # -- Parrot Avatar --

  attr :player, :map, required: true
  attr :idx, :integer, required: true
  attr :current_player_idx, :integer, required: true
  attr :player_idx, :any, required: true

  def parrot_avatar(assigns) do
    active? = assigns.idx == assigns.current_player_idx
    is_me? = assigns.idx == assigns.player_idx
    fill = player_fill(assigns.idx)

    assigns =
      assigns
      |> assign(:active?, active?)
      |> assign(:is_me?, is_me?)
      |> assign(:fill, fill)
      |> assign(:body_d, @parrot_body_d)
      |> assign(:eye_d, @parrot_eye_d)
      |> assign(:wing_d, @parrot_wing_d)

    ~H"""
    <div class="flex flex-col items-center gap-1 min-w-[3.5rem]">
      <div
        class={[
          "w-11 h-11 rounded-full flex items-center justify-center border-2 transition-all",
          if(@active? and @player.alive,
            do: "animate-[glow-pulse_2s_ease-in-out_infinite] bg-zinc-800/80",
            else: "border-transparent bg-zinc-800/40"
          ),
          if(!@player.alive, do: "opacity-30 grayscale")
        ]}
        style={if(@active? and @player.alive, do: "--glow-color: #{@fill}; border-color: #{@fill};", else: "")}
      >
        <svg viewBox="0 0 512 512" class="w-7 h-7" xmlns="http://www.w3.org/2000/svg">
          <path fill={@fill} d={@body_d} />
          <path fill="white" d={@eye_d} />
          <path fill={@fill} d={@wing_d} />
        </svg>
      </div>
      <div class="text-center w-full">
        <div class={[
          "text-xs font-semibold truncate max-w-[4rem] mx-auto",
          if(@active?, do: "text-white", else: "text-zinc-400"),
          if(!@player.alive, do: "line-through text-zinc-600")
        ]}>
          {@player.name}
        </div>
        <div class={[
          "text-[10px] font-mono",
          if(@is_me?, do: "text-sky-400", else: "text-zinc-500")
        ]}>
          {CardStack.count(@player.hand)}
          <%= if @is_me? do %>
            <span>&middot;you</span>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  # -- Pile --

  attr :game, :map, required: true

  def pile(assigns) do
    pile_size = CardStack.count(assigns.game.pile)
    visible = Enum.take(assigns.game.pile.cards, 4)
    penalty_count = CardStack.count(assigns.game.penalty_pile)

    card_transforms =
      visible
      |> Enum.with_index()
      |> Enum.map(fn {card, i} ->
        seed = {pile_size - i, card.face, card.suit, Map.get(card, :value, 0)}
        angle = rem(:erlang.phash2(seed), 360)
        x_off = rem(:erlang.phash2({seed, :x}), 25) - 12
        y_off = rem(:erlang.phash2({seed, :y}), 25) - 12
        scale = 1.0 + i * 0.08
        z = 10 - i
        %{card: card, angle: angle, x_off: x_off, y_off: y_off, scale: scale, z: z}
      end)
      |> Enum.reverse()

    assigns =
      assigns
      |> assign(:card_transforms, card_transforms)
      |> assign(:pile_size, pile_size)
      |> assign(:penalty_count, penalty_count)

    ~H"""
    <div class="relative w-full flex items-center justify-center" style="min-height: 240px;">
      <%= if @pile_size > 0 do %>
        <div class="relative" style="width: 96px; height: 134px;">
          <div
            :for={ct <- @card_transforms}
            class="absolute inset-0"
            style={"transform: rotate(#{ct.angle}deg) translate(#{ct.x_off}px, #{ct.y_off}px) scale(#{ct.scale}); z-index: #{ct.z}; transform-origin: center;"}
          >
            <.playing_card card={ct.card} />
          </div>
        </div>
      <% else %>
        <div
          class="rounded-xl border-2 border-dashed border-zinc-700 flex items-center justify-center"
          style="width: 96px; height: 134px;"
        >
          <span class="text-zinc-600 text-sm">Empty</span>
        </div>
      <% end %>

      <div class="absolute top-1 right-2 flex items-center gap-1.5">
        <span class="text-[10px] text-zinc-500 font-mono">{@pile_size} in pile</span>
        <%= if @penalty_count > 0 do %>
          <span class="text-[10px] px-1.5 py-0.5 rounded-full bg-rose-900/30 border border-rose-700/40 text-rose-400 font-semibold">
            +{@penalty_count}
          </span>
        <% end %>
      </div>

      <%= if @game.challenger_idx != nil do %>
        <div class="absolute bottom-1 inset-x-0 flex justify-center z-10">
          <div class="rounded-lg bg-amber-900/80 backdrop-blur-sm border border-amber-700/40 px-3 py-1.5 text-xs text-center">
            <span class="font-semibold text-amber-400">Challenge!</span>
            <span class="text-zinc-300 ml-1">
              {Enum.at(@game.players, @game.challenger_idx).name}
            </span>
            <span class="text-zinc-500 mx-0.5">&middot;</span>
            <span class="text-zinc-300">{format_card(@game.challenge_card)}</span>
            <span class="text-zinc-500 mx-0.5">&middot;</span>
            <span class="font-mono font-bold text-white">{@game.chances}</span>
            <span class="text-zinc-500 ml-0.5">left</span>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # -- Game Controls --

  attr :game, :map, required: true
  attr :player_idx, :any, required: true

  def game_controls(assigns) do
    my_turn? = assigns.player_idx == assigns.game.current_player_idx

    alive? =
      assigns.player_idx != nil and
        Enum.at(assigns.game.players, assigns.player_idx).alive

    current_player = Enum.at(assigns.game.players, assigns.game.current_player_idx)

    assigns =
      assigns
      |> assign(:my_turn?, my_turn?)
      |> assign(:alive?, alive?)
      |> assign(:current_player_name, current_player.name)

    ~H"""
    <div class="flex flex-col gap-2 w-full max-w-sm">
      <button
        phx-click="play_turn"
        id="play-turn-btn"
        disabled={not (@my_turn? and @alive?)}
        class={[
          "w-full rounded-xl border px-6 py-4 text-lg font-bold transition-colors",
          if(@my_turn? and @alive?,
            do: "bg-emerald-600 border-emerald-600 hover:bg-emerald-500 hover:border-emerald-500 text-white",
            else: "bg-zinc-800 border-zinc-700 text-zinc-500 cursor-not-allowed"
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
          "w-full rounded-xl border px-6 py-4 text-lg font-bold transition-colors",
          if(@alive?,
            do: "bg-amber-600 border-amber-600 hover:bg-amber-500 hover:border-amber-500 text-white",
            else: "bg-zinc-800 border-zinc-700 text-zinc-500 cursor-not-allowed"
          )
        ]}
      >
        Slap!
      </button>
    </div>
    """
  end

  # -- Game Over Banner --

  attr :winner, :string, required: true

  def game_over_banner(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center gap-4 py-8 text-center">
      <div class="text-5xl font-black tracking-tight text-emerald-400">Game Over</div>
      <div class="text-xl text-zinc-200">
        <span class="font-bold text-white">{@winner}</span> wins!
      </div>
      <div class="text-sm text-zinc-500">This game will close in 2 minutes.</div>
      <.link
        navigate={~p"/den"}
        class="rounded-lg bg-emerald-700 hover:bg-emerald-600 text-white px-6 py-2.5 font-semibold transition-all"
      >
        Back to Lobby
      </.link>
    </div>
    """
  end

  # -- Event Flash --

  attr :event_flash, :map, default: nil

  def event_flash(assigns) do
    ~H"""
    <%= if @event_flash do %>
      <div
        id="event-flash"
        class="absolute inset-x-0 bottom-0 z-20 flex justify-center pointer-events-none"
        style="animation: fade-in-scale 0.3s ease-out"
      >
        <div class="relative overflow-hidden rounded-xl border max-w-sm px-4 py-3 backdrop-blur-sm bg-zinc-900/80 pointer-events-auto">
          <div class={["absolute inset-0 opacity-20", event_flash_bg(@event_flash.type)]}></div>
          <div class="relative flex items-center gap-3">
            <div class={[
              "flex items-center justify-center w-8 h-8 rounded-full text-sm font-bold shrink-0",
              event_flash_icon_class(@event_flash.type)
            ]}>
              {event_flash_icon(@event_flash.type)}
            </div>
            <div>
              <div class={["font-bold tracking-tight", event_flash_text_class(@event_flash.type)]}>
                {@event_flash.label}
              </div>
              <div class="text-xs text-zinc-400">{@event_flash.detail}</div>
            </div>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  # -- Game Log Drawer --

  attr :log, :list, required: true

  def game_log(assigns) do
    ~H"""
    <details id="game-log-drawer" phx-hook=".KeepOpen" class="group rounded-xl border border-zinc-700 bg-zinc-900/60">
      <summary class="cursor-pointer select-none px-4 py-3 flex items-center justify-between text-sm font-semibold text-zinc-300 hover:text-white transition-colors">
        <span class="flex items-center gap-2">
          <.icon
            name="hero-chat-bubble-left"
            class="w-4 h-4 text-zinc-500 group-open:text-emerald-400 transition-colors"
          /> Game Log
        </span>
        <.icon
          name="hero-chevron-down"
          class="w-4 h-4 text-zinc-500 group-open:rotate-180 transition-transform duration-200"
        />
      </summary>
      <div class="px-4 pb-3 border-t border-zinc-800 max-h-60 overflow-y-auto">
        <div id="game-log" class="space-y-1 text-sm font-mono pt-2">
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
    </details>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".KeepOpen">
    export default {
      beforeUpdate() { this._open = this.el.open },
      updated() { this.el.open = this._open }
    }
    </script>
    """
  end

  # -- Game Rules --

  def game_rules(assigns) do
    ~H"""
    <details class="group rounded-xl border border-zinc-700 bg-zinc-900/60">
      <summary class="cursor-pointer select-none px-4 py-3 flex items-center justify-between text-sm font-semibold text-zinc-300 hover:text-white transition-colors">
        <span class="flex items-center gap-2">
          <.icon
            name="hero-book-open"
            class="w-4 h-4 text-zinc-500 group-open:text-emerald-400 transition-colors"
          /> How to Play
        </span>
        <.icon
          name="hero-chevron-down"
          class="w-4 h-4 text-zinc-500 group-open:rotate-180 transition-transform duration-200"
        />
      </summary>
      <div class="px-4 pb-3 pt-1 text-sm text-zinc-400 space-y-4 border-t border-zinc-800">
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

  # -- Playing Card --

  attr :card, :map, required: true

  def playing_card(assigns) do
    ~H"""
    <div class="w-24 h-[134px] rounded-lg bg-white shadow-lg relative overflow-hidden select-none">
      <div class="absolute inset-[2px] rounded-md border border-zinc-200">
        <div class={["absolute top-1.5 left-2 flex flex-col items-center leading-none", suit_color_card(@card.suit)]}>
          <span class="text-sm font-bold">{format_face(@card)}</span>
          <span class="text-[10px]">{suit_symbol(@card.suit)}</span>
        </div>
        <div class={["absolute bottom-1.5 right-2 flex flex-col items-center leading-none rotate-180", suit_color_card(@card.suit)]}>
          <span class="text-sm font-bold">{format_face(@card)}</span>
          <span class="text-[10px]">{suit_symbol(@card.suit)}</span>
        </div>
        <div class={["absolute inset-0 flex items-center justify-center", suit_color_card(@card.suit)]}>
          <span class="text-4xl">{suit_symbol(@card.suit)}</span>
        </div>
      </div>
    </div>
    """
  end

  defp suit_color_card(:hearts), do: "text-red-600"
  defp suit_color_card(:diamonds), do: "text-red-600"
  defp suit_color_card(:clubs), do: "text-zinc-800"
  defp suit_color_card(:spades), do: "text-zinc-800"

  # -- Private Helpers --

  defp player_fill(0), do: "#34d399"
  defp player_fill(1), do: "#38bdf8"
  defp player_fill(2), do: "#fbbf24"
  defp player_fill(3), do: "#fb7185"
  defp player_fill(4), do: "#a78bfa"
  defp player_fill(_), do: "#a1a1aa"

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
end
