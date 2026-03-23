defmodule ParakeetWeb.GameComponents do
  use ParakeetWeb, :html

  alias Parakeet.Game.CardStack

  @parrot_body_d "M418.133,401.067c0-4.71-3.814-8.533-8.533-8.533c-35.507,0-126.652-2.867-205.781-29.423c-89.941-30.182-135.552-80.572-135.552-149.769c0-119.236,50.244-196.275,128-196.275c17.161,0,31.838,6.391,41.361,17.997c5.854,7.142,9.438,15.889,10.795,25.566c0.026,0.307,0.085,0.589,0.137,0.887c0.87,6.972,0.623,14.404-0.93,22.144c-0.922,4.617,2.082,9.114,6.699,10.035c4.617,0.93,9.114-2.065,10.035-6.69c0.35-1.741,0.538-3.456,0.785-5.18c9.839,15.821,7.578,31.607,4.506,41.182c-17.775-10.76-33.758-3.038-34.534-2.637c-4.215,2.108-5.931,7.228-3.823,11.443c2.116,4.215,7.228,5.922,11.452,3.823c0.111-0.068,11.691-5.658,24.286,6.929c1.604,1.613,3.78,2.5,6.033,2.5c0.35,0,0.691-0.017,1.041-0.06c2.611-0.324,4.924-1.835,6.272-4.079c9.916-16.521,18.876-54.989-15.437-85.077c-2.039-11.802-6.733-22.596-14.123-31.607C238.003,8.61,218.633,0,196.267,0C109.5,0,51.2,85.734,51.2,213.342c0,77.338,49.527,133.171,147.191,165.948c81.51,27.358,174.857,30.31,211.209,30.31C414.319,409.6,418.133,405.777,418.133,401.067z"
  @parrot_eye_d "M187.733,68.267c0,9.412,7.654,17.067,17.067,17.067s17.067-7.654,17.067-17.067c0-9.412-7.654-17.067-17.067-17.067S187.733,58.854,187.733,68.267z"
  @parrot_wing_d "M355.9,215.834C319.232,179.157,242.338,153.6,196.267,153.6c-62.285,0-93.867,22.963-93.867,68.267c0,64.58,119.151,136.533,290.133,136.533c4.719,0,8.533-3.823,8.533-8.533s-3.814-8.533-8.533-8.533c-153.788,0-273.067-64.222-273.067-119.467c0-23.834,8.73-51.2,76.8-51.2c15.59,0,33.698,3.012,52.036,8.064c-13.244,14.865-32.239,45.679-25.071,95.548c0.614,4.258,4.267,7.322,8.439,7.322c0.401,0,0.811-0.026,1.229-0.085c4.668-0.674,7.902-5.001,7.236-9.668c-7.552-52.48,17.749-79.701,26.53-87.424c12.655,4.403,25.02,9.694,36.412,15.531c-13.773,13.986-36.582,44.817-29.926,91.392c0.606,4.25,4.258,7.322,8.44,7.322c0.401,0,0.811-0.026,1.22-0.085c4.668-0.666,7.902-4.992,7.236-9.66c-6.255-43.759,18.347-71.04,28.518-80.265c9.916,6.118,18.628,12.604,25.267,19.243c1.63,1.63,4.045,4.181,6.818,7.262c-15.053,11.639-32.512,36.002-26.266,73.446c0.691,4.164,4.309,7.125,8.405,7.125c0.469,0,0.93-0.034,1.408-0.119c4.651-0.768,7.791-5.171,7.014-9.822c-5.513-33.101,11.255-50.586,20.446-57.489c28.911,36.591,78.319,116.685,81.877,240.939c-53.675-29.611-68.676-57.301-68.992-57.907c-2.116-4.181-7.228-5.871-11.426-3.772c-4.216,2.116-5.931,7.236-3.823,11.452c0.751,1.502,19.149,37.077,89.156,72.09c1.203,0.597,2.509,0.896,3.814,0.896c1.562,0,3.115-0.427,4.48-1.271c2.517-1.553,4.053-4.301,4.053-7.262C460.8,333.909,380.51,240.444,355.9,215.834z"

  @ai_avatar_d "M327.294,61.106c-0.835-2.324-3.042-3.883-5.512-3.883H175.641c-1.475,0-2.893,0.555-3.974,1.553 l-49.009,45.261L61.705,43.083c-0.066-0.062-0.152-0.1-0.217-0.163c-0.211-0.194-0.452-0.352-0.689-0.518 c-0.255-0.168-0.495-0.331-0.764-0.454c-0.08-0.037-0.14-0.101-0.223-0.135c-0.169-0.071-0.343-0.077-0.515-0.128 c-0.298-0.094-0.586-0.183-0.895-0.223c-0.28-0.043-0.552-0.043-0.832-0.043s-0.549,0-0.832,0.043 c-0.309,0.046-0.603,0.135-0.9,0.229c-0.163,0.052-0.34,0.058-0.503,0.129c-0.083,0.034-0.14,0.092-0.217,0.135 c-0.274,0.128-0.526,0.297-0.778,0.469c-0.234,0.157-0.469,0.314-0.68,0.503c-0.071,0.063-0.151,0.1-0.223,0.163L1.717,94.809 c-1.675,1.675-2.179,4.191-1.27,6.381c0.906,2.19,3.045,3.614,5.409,3.614h45.864v67.335c0,0.017,0.006,0.028,0.006,0.04 s-0.006,0.023-0.006,0.034c0,0.046,0.029,0.092,0.035,0.144c0.031,0.691,0.194,1.344,0.446,1.955 c0.077,0.178,0.157,0.349,0.246,0.521c0.3,0.56,0.669,1.075,1.129,1.509c0.06,0.058,0.083,0.138,0.143,0.195l63.427,55.625 c0.049,0.039,0.112,0.057,0.166,0.103c0.274,0.897,0.698,1.749,1.381,2.436l49.798,49.804c1.121,1.115,2.622,1.716,4.144,1.716 c0.755,0,1.515-0.144,2.241-0.446c2.189-0.903,3.613-3.042,3.613-5.409v-92.174L325.504,67.61 C327.409,66.041,328.129,63.437,327.294,61.106z M63.42,157.998V98.942V61.358l48.323,48.323L63.42,157.998z M19.98,93.087 l31.729-31.729v31.729H19.98z M166.764,266.229l-35.4-35.406l35.4-31.306V266.229z M121.118,220.084l-54.805-48.065L177.934,68.935 h127.472L121.118,220.084z"

  @playcard_d "M463.164,146.031l-77.369,288.746c-1.677,6.26-7.362,10.4-13.556,10.401c-1.198,0-2.414-0.155-3.625-0.479 l-189.261-50.712c-7.472-2.003-11.922-9.711-9.919-17.183l2.041-7.616c1.287-4.801,6.222-7.647,11.023-6.363 c4.801,1.287,7.65,6.222,6.363,11.023l-1.013,3.78l181.587,48.656l75.314-281.076l-77.031-20.64 c-4.801-1.287-7.651-6.222-6.364-11.023s6.225-7.648,11.022-6.364l80.869,21.668C460.718,130.853,465.167,138.56,463.164,146.031z M166.128,56.029c-4.971,0-9,4.029-9,9v8.565c0,4.971,4.029,9,9,9s9-4.029,9-9v-8.565C175.128,60.058,171.099,56.029,166.128,56.029 z M280.889,176.762c2.202,3.114,2.202,7.278,0,10.393l-41.716,58.996c-1.687,2.385-4.427,3.804-7.349,3.804 c-2.921,0-5.662-1.418-7.348-3.804l-41.718-58.996c-2.202-3.114-2.202-7.278,0-10.393l41.718-58.996 c1.687-2.385,4.427-3.804,7.348-3.804c2.922,0,5.662,1.418,7.349,3.804L280.889,176.762z M262.518,181.958l-30.694-43.408 l-30.694,43.408l30.694,43.407L262.518,181.958z M343.016,380.764l-2.216,8.273c-1.286,4.801,1.563,9.736,6.365,11.022 c0.78,0.209,1.563,0.309,2.334,0.309c3.974,0,7.611-2.653,8.688-6.674l2.216-8.273c1.286-4.801-1.563-9.736-6.365-11.022 C349.237,373.111,344.302,375.963,343.016,380.764z M112.375,215.913c2.577-0.69,5.056-1.089,7.454-1.195V32.492 c0-7.736,6.293-14.029,14.028-14.029h195.935c7.736,0,14.03,6.293,14.03,14.029v182.225c2.396,0.106,4.875,0.505,7.45,1.195 c16.511,4.424,26.346,21.457,21.922,37.968c-4.28,15.974-17.951,28.108-29.372,36.404v41.139c0,7.736-6.294,14.03-14.03,14.03 H133.857c-7.735,0-14.028-6.294-14.028-14.03v-41.137c-11.422-8.295-25.093-20.428-29.376-36.405 c-2.143-7.996-1.042-16.35,3.1-23.523C97.695,223.186,104.38,218.055,112.375,215.913z M343.821,267.05 c6.531-6.172,10.424-12,11.985-17.828c1.855-6.924-2.27-14.067-9.194-15.923c-1.047-0.281-1.97-0.451-2.791-0.538V267.05z M137.829,327.454h187.992v-41.7c-0.001-0.08-0.001-0.161,0-0.241v-59.907c-0.003-0.13-0.003-0.261,0-0.391V36.463H137.829v188.755 c0.003,0.13,0.003,0.261,0,0.392v59.898c0.001,0.084,0.001,0.168,0,0.252V327.454z M107.84,249.222 c1.563,5.83,5.457,11.66,11.989,17.832v-34.292c-0.822,0.086-1.746,0.256-2.794,0.537c-3.353,0.898-6.156,3.051-7.894,6.061 C107.404,242.369,106.942,245.871,107.84,249.222z M173.576,405.019l-79.363,21.265L18.897,145.209l77.031-20.641 c4.801-1.287,7.651-6.222,6.364-11.023c-1.287-4.801-6.225-7.65-11.022-6.364L10.402,128.85c-3.614,0.968-6.637,3.29-8.512,6.538 c-1.876,3.249-2.376,7.029-1.407,10.644l77.37,288.743c0.968,3.616,3.29,6.641,6.54,8.518c2.166,1.25,4.567,1.89,7,1.89 c1.216,0,2.439-0.16,3.644-0.482l83.199-22.293c4.801-1.287,7.651-6.222,6.364-11.022 C183.312,406.581,178.377,403.734,173.576,405.019z M51.298,156.782c-4.801,1.287-7.65,6.222-6.364,11.023l2.217,8.274 c1.078,4.021,4.714,6.673,8.688,6.673c0.771,0,1.555-0.1,2.335-0.309c4.801-1.287,7.65-6.222,6.364-11.023l-2.217-8.274 C61.034,158.344,56.101,155.496,51.298,156.782z M297.52,281.322c-4.971,0-9,4.029-9,9v8.565c0,4.971,4.029,9,9,9s9-4.029,9-9 v-8.565C306.52,285.352,302.491,281.322,297.52,281.322z"

  @slap_d "M316.26 30.982c66.658 35.958 111.957 106.423 111.957 187.47 0 117.567-95.305 212.872-212.87 212.872-81.016 0-151.456-45.26-187.427-111.87C54.146 421.63 146.772 497.02 257.195 497.02c130.85 0 236.703-105.857 236.703-236.706 0-110.448-75.424-203.12-177.638-229.332zM173.027 49.174c-.513-.002-1.022.008-1.525.03-4.83.2-8.995 1.528-12.078 3.548L146.79 160.74l-15.458 28.592c6.213 10.643 11.196 21.47 14.826 32.496l-17.75 5.844c-2.052-6.233-4.63-12.46-7.703-18.682l-.025.047c-12.95-22.565-27.376-41.2-38.912-47.967-6.19-3.63-10.49-4.2-15.262-2.35-3.982 1.546-9.023 5.83-14.383 13.985 33.155 41.62 40.914 80.725 46.535 106.195 1.802 8.16 1.855 15.758 3.23 21.36l.305 1.234-.04 1.272c-.754 25.344 10.396 43.41 26.146 55.218 15.704 11.776 36.216 16.526 52.104 13.748 19.725-4.198 32.415-11.058 45.717-22.464 11.922-10.57 33.085-26.408 45.062-36.42 37.06-30.977 98.058-63.045 108.02-68.21 2.108-10.902-4.806-22.478-13.655-27.152l-74.184 42.71c-3.954-7.074-8.448-13.68-13.392-19.895l91.505-99.21c-.33-6.228-3.38-13.547-8.305-19.252-4.444-5.147-9.932-8.334-14.133-9.373l-95.07 101.33c-6.066-5.157-12.43-10.054-19.002-14.772l66.1-125.216c-4.527-6.72-9.388-10.572-15.26-13.237-5.445-2.47-12.303-3.794-19.887-4.892l-60.463 123.8c-7.348-4.592-14.772-9.118-22.182-13.656l14.055-108.806c-3.996-3.416-10.597-6.564-17.572-7.512-1.603-.218-3.188-.326-4.73-.33z"

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
  attr :challenger_idx, :any, required: true
  attr :player_idx, :any, required: true
  attr :card_delta, :atom, default: nil

  def parrot_avatar(assigns) do
    active? = assigns.idx == assigns.current_player_idx
    is_me? = assigns.idx == assigns.player_idx
    is_challenger? = assigns.challenger_idx != nil and assigns.idx == assigns.challenger_idx
    is_challenged? = assigns.challenger_idx != nil and active?
    fill = player_fill(assigns.idx)
    card_count = CardStack.count(assigns.player.hand)

    glow_color =
      cond do
        is_challenged? -> "#ef4444"
        is_challenger? -> "#f59e0b"
        active? -> "#34d399"
        true -> fill
      end

    glowing? = (active? or is_challenger?) and assigns.player.alive

    bump_color =
      case assigns.card_delta do
        :up -> "#34d399"
        :down -> "#ef4444"
        _ -> "#34d399"
      end

    assigns =
      assigns
      |> assign(:active?, active?)
      |> assign(:is_me?, is_me?)
      |> assign(:is_challenger?, is_challenger?)
      |> assign(:glowing?, glowing?)
      |> assign(:fill, fill)
      |> assign(:glow_color, glow_color)
      |> assign(:card_count, card_count)
      |> assign(:bump_color, bump_color)
      |> assign(:bot?, assigns.player.bot)
      |> assign(:ai_d, @ai_avatar_d)
      |> assign(:body_d, @parrot_body_d)
      |> assign(:eye_d, @parrot_eye_d)
      |> assign(:wing_d, @parrot_wing_d)

    ~H"""
    <div class="flex flex-col items-center gap-1 min-w-[3.5rem]">
      <div
        class={[
          "w-11 h-11 rounded-full flex items-center justify-center border-2 transition-all",
          if(@glowing?,
            do: "animate-[glow-pulse_2s_ease-in-out_infinite] bg-zinc-800/80",
            else: "border-transparent bg-zinc-800/40"
          ),
          if(!@player.alive, do: "opacity-30 grayscale")
        ]}
        style={
          if(@glowing?,
            do: "--glow-color: #{@glow_color}; border-color: #{@glow_color};",
            else: ""
          )
        }
      >
        <%= if @bot? do %>
          <svg viewBox="0 0 327.638 327.638" class="w-7 h-7" xmlns="http://www.w3.org/2000/svg">
            <path fill={@fill} d={@ai_d} />
          </svg>
        <% else %>
          <svg viewBox="0 0 512 512" class="w-7 h-7" xmlns="http://www.w3.org/2000/svg">
            <path fill={@fill} d={@body_d} />
            <path fill="white" d={@eye_d} />
            <path fill={@fill} d={@wing_d} />
          </svg>
        <% end %>
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
          "text-lg font-bold font-mono inline-flex items-center gap-0.5",
          if(@is_me?, do: "text-sky-400", else: "text-zinc-500")
        ]}>
          <span
            id={"count-#{@idx}-#{@card_count}"}
            class="inline-block animate-[count-bump_0.4s_ease-out]"
            style={"--bump-color: #{@bump_color}"}
          >
            {@card_count}
          </span>
        </div>
      </div>
    </div>
    """
  end

  # -- Card History --

  attr :cards, :list, required: true
  attr :game, :map, required: true

  def card_history(assigns) do
    visible = assigns.cards |> Enum.take(4) |> Enum.reverse()
    assigns = assign(assigns, :visible, visible)

    ~H"""
    <div class="grid grid-cols-2 items-center min-h-[2rem] mt-2">
      <div class="flex justify-end gap-3">
        <span
          :for={card <- @visible}
          class={[
            "text-xl font-bold font-mono opacity-80",
            if(card.suit in [:hearts, :diamonds], do: "text-red-400", else: "text-zinc-400")
          ]}
        >
          {format_face(card)}{suit_symbol(card.suit)}
        </span>
      </div>
      <div class="pl-3 flex items-center gap-2">
        <%= if @game.challenger_idx != nil do %>
          <span class="w-px h-6 bg-zinc-700"></span>
          <span class="inline-flex items-center gap-2 rounded-full bg-amber-900/40 border border-amber-700/30 px-3 py-1 text-base font-mono">
            <span class="font-bold text-amber-300">{format_card(@game.challenge_card)}</span>
            <span class="text-zinc-500">&middot;</span>
            <span class="font-bold text-white text-lg">{@game.chances}</span>
            <span class="text-zinc-400 text-sm">left</span>
          </span>
        <% end %>
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
        scale = 1.0 + i * 0.08
        z = 10 - i
        %{card: card, angle: angle, scale: scale, z: z}
      end)
      |> Enum.reverse()

    assigns =
      assigns
      |> assign(:card_transforms, card_transforms)
      |> assign(:pile_size, pile_size)
      |> assign(:penalty_count, penalty_count)

    ~H"""
    <div class="relative w-full flex items-center justify-center" style="min-height: 300px;">
      <%= if @pile_size > 0 do %>
        <div class="relative" style="width: 140px; height: 196px;">
          <div
            :for={ct <- @card_transforms}
            class="absolute inset-0"
            style={"transform: rotate(#{ct.angle}deg) scale(#{ct.scale}); z-index: #{ct.z}; transform-origin: center;"}
          >
            <.playing_card card={ct.card} />
          </div>
        </div>
      <% else %>
        <div
          class="rounded-xl border-2 border-dashed border-zinc-700 flex items-center justify-center"
          style="width: 140px; height: 196px;"
        >
          <span class="text-zinc-600 text-sm">Empty</span>
        </div>
      <% end %>

      <div class="absolute top-1 right-1 flex items-center gap-1.5">
        <span class="text-base text-zinc-300 font-mono font-bold">{@pile_size} in pile</span>
        <%= if @penalty_count > 0 do %>
          <span class="text-xs px-2 py-0.5 rounded-full bg-rose-900/30 border border-rose-700/40 text-rose-400 font-semibold">
            +{@penalty_count}
          </span>
        <% end %>
      </div>

    </div>
    """
  end

  # -- Game Controls --

  attr :game, :map, required: true
  attr :player_idx, :any, required: true
  attr :cooldown?, :boolean, default: false

  def game_controls(assigns) do
    my_turn? = assigns.player_idx == assigns.game.current_player_idx

    alive? =
      assigns.player_idx != nil and
        Enum.at(assigns.game.players, assigns.player_idx).alive

    pending_challenge? = assigns.game.challenger_idx != nil and assigns.game.chances == 0
    current_player = Enum.at(assigns.game.players, assigns.game.current_player_idx)
    can_play? = my_turn? and alive? and not assigns.cooldown? and not pending_challenge?
    can_slap? = alive? and not assigns.cooldown?

    assigns =
      assigns
      |> assign(:can_play?, can_play?)
      |> assign(:can_slap?, can_slap?)
      |> assign(:my_turn?, my_turn?)
      |> assign(:current_player_name, current_player.name)
      |> assign(:playcard_d, @playcard_d)
      |> assign(:slap_d, @slap_d)

    ~H"""
    <div class="flex items-start justify-center gap-8">
      <div class="flex flex-col items-center gap-1.5">
        <button
          phx-click="play_turn"
          id="play-turn-btn"
          disabled={not @can_play?}
          class={[
            "w-20 h-20 rounded-full border-2 flex items-center justify-center transition-colors",
            if(@can_play?,
              do: "bg-emerald-600 border-emerald-500 hover:bg-emerald-500 text-white",
              else: "bg-zinc-800 border-zinc-700 text-zinc-500 cursor-not-allowed"
            )
          ]}
        >
          <svg viewBox="0 0 463.644 463.644" class="w-9 h-9 fill-current">
            <path d={@playcard_d} />
          </svg>
        </button>
        <span class={[
          "text-xs font-semibold",
          if(@can_play?, do: "text-emerald-400", else: "text-zinc-500")
        ]}>
          <%= if @my_turn? do %>
            Play
          <% else %>
            {@current_player_name}...
          <% end %>
        </span>
      </div>
      <div class="flex flex-col items-center gap-1.5">
        <button
          phx-click="slap"
          id="slap-btn"
          disabled={not @can_slap?}
          class={[
            "w-20 h-20 rounded-full border-2 flex items-center justify-center transition-colors",
            if(@can_slap?,
              do: "bg-amber-600 border-amber-500 hover:bg-amber-500 text-white",
              else: "bg-zinc-800 border-zinc-700 text-zinc-500 cursor-not-allowed"
            )
          ]}
        >
          <svg viewBox="0 0 512 512" class="w-9 h-9 fill-current">
            <path d={@slap_d} />
          </svg>
        </button>
        <span class={[
          "text-xs font-semibold",
          if(@can_slap?, do: "text-amber-400", else: "text-zinc-500")
        ]}>
          Slap!
        </span>
      </div>
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
    <details
      id="game-log-drawer"
      phx-hook=".KeepOpen"
      class="group rounded-xl border border-zinc-700 bg-zinc-900/60"
    >
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
    <div class="w-[140px] h-[196px] rounded-xl bg-white shadow-lg relative overflow-hidden select-none">
      <div class="absolute inset-[3px] rounded-lg border border-zinc-200">
        <div class={[
          "absolute top-2 left-2.5 flex flex-col items-center leading-none",
          suit_color_card(@card.suit)
        ]}>
          <span class="text-xl font-bold">{format_face(@card)}</span>
          <span class="text-sm">{suit_symbol(@card.suit)}</span>
        </div>
        <div class={[
          "absolute bottom-2 right-2.5 flex flex-col items-center leading-none rotate-180",
          suit_color_card(@card.suit)
        ]}>
          <span class="text-xl font-bold">{format_face(@card)}</span>
          <span class="text-sm">{suit_symbol(@card.suit)}</span>
        </div>
        <div class={["absolute inset-0 flex items-center justify-center", suit_color_card(@card.suit)]}>
          <span class="text-5xl">{suit_symbol(@card.suit)}</span>
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
