defmodule ParakeetWeb.DenComponents do
  use ParakeetWeb, :html

  @parrot_body_d "M418.133,401.067c0-4.71-3.814-8.533-8.533-8.533c-35.507,0-126.652-2.867-205.781-29.423c-89.941-30.182-135.552-80.572-135.552-149.769c0-119.236,50.244-196.275,128-196.275c17.161,0,31.838,6.391,41.361,17.997c5.854,7.142,9.438,15.889,10.795,25.566c0.026,0.307,0.085,0.589,0.137,0.887c0.87,6.972,0.623,14.404-0.93,22.144c-0.922,4.617,2.082,9.114,6.699,10.035c4.617,0.93,9.114-2.065,10.035-6.69c0.35-1.741,0.538-3.456,0.785-5.18c9.839,15.821,7.578,31.607,4.506,41.182c-17.775-10.76-33.758-3.038-34.534-2.637c-4.215,2.108-5.931,7.228-3.823,11.443c2.116,4.215,7.228,5.922,11.452,3.823c0.111-0.068,11.691-5.658,24.286,6.929c1.604,1.613,3.78,2.5,6.033,2.5c0.35,0,0.691-0.017,1.041-0.06c2.611-0.324,4.924-1.835,6.272-4.079c9.916-16.521,18.876-54.989-15.437-85.077c-2.039-11.802-6.733-22.596-14.123-31.607C238.003,8.61,218.633,0,196.267,0C109.5,0,51.2,85.734,51.2,213.342c0,77.338,49.527,133.171,147.191,165.948c81.51,27.358,174.857,30.31,211.209,30.31C414.319,409.6,418.133,405.777,418.133,401.067z"
  @parrot_eye_d "M187.733,68.267c0,9.412,7.654,17.067,17.067,17.067s17.067-7.654,17.067-17.067c0-9.412-7.654-17.067-17.067-17.067S187.733,58.854,187.733,68.267z"
  @parrot_wing_d "M355.9,215.834C319.232,179.157,242.338,153.6,196.267,153.6c-62.285,0-93.867,22.963-93.867,68.267c0,64.58,119.151,136.533,290.133,136.533c4.719,0,8.533-3.823,8.533-8.533s-3.814-8.533-8.533-8.533c-153.788,0-273.067-64.222-273.067-119.467c0-23.834,8.73-51.2,76.8-51.2c15.59,0,33.698,3.012,52.036,8.064c-13.244,14.865-32.239,45.679-25.071,95.548c0.614,4.258,4.267,7.322,8.439,7.322c0.401,0,0.811-0.026,1.229-0.085c4.668-0.674,7.902-5.001,7.236-9.668c-7.552-52.48,17.749-79.701,26.53-87.424c12.655,4.403,25.02,9.694,36.412,15.531c-13.773,13.986-36.582,44.817-29.926,91.392c0.606,4.25,4.258,7.322,8.44,7.322c0.401,0,0.811-0.026,1.22-0.085c4.668-0.666,7.902-4.992,7.236-9.66c-6.255-43.759,18.347-71.04,28.518-80.265c9.916,6.118,18.628,12.604,25.267,19.243c1.63,1.63,4.045,4.181,6.818,7.262c-15.053,11.639-32.512,36.002-26.266,73.446c0.691,4.164,4.309,7.125,8.405,7.125c0.469,0,0.93-0.034,1.408-0.119c4.651-0.768,7.791-5.171,7.014-9.822c-5.513-33.101,11.255-50.586,20.446-57.489c28.911,36.591,78.319,116.685,81.877,240.939c-53.675-29.611-68.676-57.301-68.992-57.907c-2.116-4.181-7.228-5.871-11.426-3.772c-4.216,2.116-5.931,7.236-3.823,11.452c0.751,1.502,19.149,37.077,89.156,72.09c1.203,0.597,2.509,0.896,3.814,0.896c1.562,0,3.115-0.427,4.48-1.271c2.517-1.553,4.053-4.301,4.053-7.262C460.8,333.909,380.51,240.444,355.9,215.834z"
  @ai_avatar_d "M327.294,61.106c-0.835-2.324-3.042-3.883-5.512-3.883H175.641c-1.475,0-2.893,0.555-3.974,1.553 l-49.009,45.261L61.705,43.083c-0.066-0.062-0.152-0.1-0.217-0.163c-0.211-0.194-0.452-0.352-0.689-0.518 c-0.255-0.168-0.495-0.331-0.764-0.454c-0.08-0.037-0.14-0.101-0.223-0.135c-0.169-0.071-0.343-0.077-0.515-0.128 c-0.298-0.094-0.586-0.183-0.895-0.223c-0.28-0.043-0.552-0.043-0.832-0.043s-0.549,0-0.832,0.043 c-0.309,0.046-0.603,0.135-0.9,0.229c-0.163,0.052-0.34,0.058-0.503,0.129c-0.083,0.034-0.14,0.092-0.217,0.135 c-0.274,0.128-0.526,0.297-0.778,0.469c-0.234,0.157-0.469,0.314-0.68,0.503c-0.071,0.063-0.151,0.1-0.223,0.163L1.717,94.809 c-1.675,1.675-2.179,4.191-1.27,6.381c0.906,2.19,3.045,3.614,5.409,3.614h45.864v67.335c0,0.017,0.006,0.028,0.006,0.04 s-0.006,0.023-0.006,0.034c0,0.046,0.029,0.092,0.035,0.144c0.031,0.691,0.194,1.344,0.446,1.955 c0.077,0.178,0.157,0.349,0.246,0.521c0.3,0.56,0.669,1.075,1.129,1.509c0.06,0.058,0.083,0.138,0.143,0.195l63.427,55.625 c0.049,0.039,0.112,0.057,0.166,0.103c0.274,0.897,0.698,1.749,1.381,2.436l49.798,49.804c1.121,1.115,2.622,1.716,4.144,1.716 c0.755,0,1.515-0.144,2.241-0.446c2.189-0.903,3.613-3.042,3.613-5.409v-92.174L325.504,67.61 C327.409,66.041,328.129,63.437,327.294,61.106z M63.42,157.998V98.942V61.358l48.323,48.323L63.42,157.998z M19.98,93.087 l31.729-31.729v31.729H19.98z M166.764,266.229l-35.4-35.406l35.4-31.306V266.229z M121.118,220.084l-54.805-48.065L177.934,68.935 h127.472L121.118,220.084z"

  attr :table, :map, required: true

  def waiting_room(assigns) do
    bot_names = Map.get(assigns.table, :bot_names, [])

    assigns =
      assigns
      |> assign(:bot_names, bot_names)
      |> assign(:body_d, @parrot_body_d)
      |> assign(:eye_d, @parrot_eye_d)
      |> assign(:wing_d, @parrot_wing_d)
      |> assign(:ai_d, @ai_avatar_d)

    ~H"""
    <div class="rounded-xl border border-zinc-200 bg-white/90 p-6 shadow-sm space-y-5 dark:border-zinc-500/55 dark:bg-zinc-800/70 dark:shadow-none">
      <div class="flex items-center justify-between">
        <h2 class="text-xl font-semibold text-zinc-900 dark:text-white">{@table.name}</h2>
        <div class="flex items-center gap-2 rounded-lg bg-zinc-100 px-3 py-1.5 border border-zinc-200 dark:bg-zinc-700/80 dark:border-zinc-500/50">
          <span class="text-xs uppercase tracking-wider text-zinc-500 dark:text-zinc-400">Code</span>
          <span class="font-mono font-bold text-lg tracking-widest text-zinc-900 dark:text-white">
            {@table.code}
          </span>
        </div>
      </div>

      <div class="space-y-2">
        <h3 class="text-sm font-medium text-zinc-600 uppercase tracking-wider dark:text-zinc-400">
          Players
        </h3>
        <div class="flex flex-wrap gap-2">
          <span
            :for={name <- @table.player_names}
            class={[
              "rounded-full border px-4 py-1.5 text-sm font-medium inline-flex items-center gap-1.5",
              if(name in @bot_names,
                do: "bg-violet-900/40 border-violet-600/50 text-violet-300",
                else:
                  "bg-zinc-100 border-zinc-200 text-zinc-900 dark:bg-zinc-700/75 dark:border-zinc-500/50 dark:text-zinc-50"
              )
            ]}
          >
            <%= if name in @bot_names do %>
              <svg viewBox="0 0 327.638 327.638" class="w-4 h-4" xmlns="http://www.w3.org/2000/svg">
                <path fill="currentColor" d={@ai_d} />
              </svg>
            <% else %>
              <svg viewBox="0 0 512 512" class="w-4 h-4" xmlns="http://www.w3.org/2000/svg">
                <path fill="#34d399" d={@body_d} />
                <path fill="white" d={@eye_d} />
                <path fill="#34d399" d={@wing_d} />
              </svg>
            <% end %>
            {name}
            <%= if name in @bot_names and @table.engine_pid == nil do %>
              <button
                phx-click="remove_bot"
                phx-value-name={name}
                class="text-violet-500 hover:text-violet-300 transition-colors -mr-1"
              >
                <.icon name="hero-x-mark-mini" class="w-3.5 h-3.5" />
              </button>
            <% end %>
          </span>

          <%= if @table.engine_pid == nil and length(@table.player_names) < 6 do %>
            <button
              phx-click="add_bot"
              id="add-bot-btn"
              class="rounded-full border border-dashed border-zinc-400 px-4 py-1.5 text-sm text-zinc-600 hover:text-violet-600 hover:border-violet-500 transition-all inline-flex items-center gap-1.5 dark:border-zinc-500 dark:text-zinc-300 dark:hover:text-violet-300"
            >
              <.icon name="hero-cpu-chip-mini" class="w-3.5 h-3.5" /> Add Bot
            </button>
          <% end %>
        </div>
      </div>

      <div class="flex gap-3 pt-2">
        <%= if @table.engine_pid == nil do %>
          <button
            phx-click="start_game"
            id="start-game-btn"
            class={[
              "rounded-lg px-6 py-2.5 font-semibold transition-all",
              if(length(@table.player_names) >= 2,
                do: "bg-emerald-600 hover:bg-emerald-500 text-white hover:scale-105 active:scale-95",
                else: "bg-zinc-200 text-zinc-500 cursor-not-allowed dark:bg-zinc-800/80"
              )
            ]}
            disabled={length(@table.player_names) < 2}
          >
            Start Game
          </button>
        <% else %>
          <%= if @table.game_status == :finished do %>
            <div class="rounded-lg bg-zinc-100 border border-zinc-300 px-4 py-2.5 text-sm text-zinc-600 font-medium dark:bg-zinc-800/80 dark:border-zinc-500/50 dark:text-zinc-300">
              Game finished
            </div>
          <% else %>
            <div class="rounded-lg bg-emerald-900/40 border border-emerald-700/50 px-4 py-2.5 text-sm text-emerald-400 font-medium">
              Game in progress
            </div>
          <% end %>
        <% end %>
        <button
          phx-click="leave_table"
          id="leave-table-btn"
          class="rounded-lg border border-zinc-400 px-5 py-2.5 text-sm font-medium text-zinc-700 hover:text-zinc-900 hover:border-zinc-600 transition-all ml-auto dark:border-zinc-500 dark:text-zinc-200 dark:hover:text-white dark:hover:border-zinc-400"
        >
          Leave
        </button>
      </div>
    </div>
    """
  end

  attr :table, :map, required: true

  def active_table_banner(assigns) do
    ~H"""
    <div class="rounded-xl border border-emerald-300/80 bg-emerald-50/90 p-5 shadow-sm space-y-3 dark:border-emerald-700/50 dark:bg-emerald-900/20 dark:shadow-none">
      <div class="flex items-center justify-between">
        <div class="space-y-1">
          <div class="text-xs uppercase tracking-wider text-emerald-700 font-semibold dark:text-emerald-400">
            Active Table
          </div>
          <h2 class="text-lg font-bold text-zinc-900 dark:text-white">{@table.name}</h2>
        </div>
        <div class="flex items-center gap-2 rounded-lg bg-white px-3 py-1.5 border border-emerald-200 dark:bg-zinc-700/85 dark:border-zinc-500/45">
          <span class="text-xs uppercase tracking-wider text-zinc-500 dark:text-zinc-400">Code</span>
          <span class="font-mono font-bold tracking-widest text-zinc-900 dark:text-white">
            {@table.code}
          </span>
        </div>
      </div>
      <div class="text-sm text-zinc-600 dark:text-zinc-400">
        {length(@table.player_names)} players: {Enum.join(@table.player_names, ", ")}
      </div>
      <div class="flex gap-3">
        <button
          phx-click="rejoin_table"
          id="rejoin-table-btn"
          class="rounded-lg bg-emerald-600 hover:bg-emerald-500 text-white px-5 py-2 font-semibold text-sm transition-all hover:scale-[1.02] active:scale-95"
        >
          Rejoin
        </button>
        <button
          phx-click="leave_table"
          id="leave-active-table-btn"
          class="rounded-lg border border-zinc-400 px-5 py-2 text-sm font-medium text-zinc-700 hover:text-zinc-900 hover:border-zinc-600 transition-all dark:border-zinc-500 dark:text-zinc-200 dark:hover:text-white dark:hover:border-zinc-400"
        >
          Leave
        </button>
      </div>
    </div>
    """
  end
end
