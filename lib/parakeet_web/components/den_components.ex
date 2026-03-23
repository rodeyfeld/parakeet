defmodule ParakeetWeb.DenComponents do
  use ParakeetWeb, :html

  attr :table, :map, required: true

  def waiting_room(assigns) do
    bot_names = Map.get(assigns.table, :bot_names, [])
    assigns = assign(assigns, :bot_names, bot_names)

    ~H"""
    <div class="rounded-xl border border-zinc-700 bg-zinc-900/60 p-6 space-y-5">
      <div class="flex items-center justify-between">
        <h2 class="text-xl font-semibold">{@table.name}</h2>
        <div class="flex items-center gap-2 rounded-lg bg-zinc-800 px-3 py-1.5 border border-zinc-700">
          <span class="text-xs uppercase tracking-wider text-zinc-400">Code</span>
          <span class="font-mono font-bold text-lg tracking-widest">{@table.code}</span>
        </div>
      </div>

      <div class="space-y-2">
        <h3 class="text-sm font-medium text-zinc-400 uppercase tracking-wider">Players</h3>
        <div class="flex flex-wrap gap-2">
          <span
            :for={name <- @table.player_names}
            class={[
              "rounded-full border px-4 py-1.5 text-sm font-medium inline-flex items-center gap-1.5",
              if(name in @bot_names,
                do: "bg-violet-900/40 border-violet-600/50 text-violet-300",
                else: "bg-zinc-800 border-zinc-700"
              )
            ]}
          >
            <%= if name in @bot_names do %>
              <.icon name="hero-cpu-chip-mini" class="w-3.5 h-3.5 text-violet-400" />
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
              class="rounded-full border border-dashed border-zinc-600 px-4 py-1.5 text-sm text-zinc-400 hover:text-violet-300 hover:border-violet-500 transition-all inline-flex items-center gap-1.5"
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
                else: "bg-zinc-800 text-zinc-500 cursor-not-allowed"
              )
            ]}
            disabled={length(@table.player_names) < 2}
          >
            Start Game
          </button>
        <% else %>
          <%= if @table.game_status == :finished do %>
            <div class="rounded-lg bg-zinc-800 border border-zinc-600 px-4 py-2.5 text-sm text-zinc-400 font-medium">
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
          class="rounded-lg border border-zinc-700 px-5 py-2.5 text-sm font-medium text-zinc-400 hover:text-white hover:border-zinc-500 transition-all ml-auto"
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
    <div class="rounded-xl border border-emerald-700/50 bg-emerald-900/20 p-5 space-y-3">
      <div class="flex items-center justify-between">
        <div class="space-y-1">
          <div class="text-xs uppercase tracking-wider text-emerald-400 font-semibold">
            Active Table
          </div>
          <h2 class="text-lg font-bold">{@table.name}</h2>
        </div>
        <div class="flex items-center gap-2 rounded-lg bg-zinc-800 px-3 py-1.5 border border-zinc-700">
          <span class="text-xs uppercase tracking-wider text-zinc-400">Code</span>
          <span class="font-mono font-bold tracking-widest">{@table.code}</span>
        </div>
      </div>
      <div class="text-sm text-zinc-400">
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
          class="rounded-lg border border-zinc-700 px-5 py-2 text-sm font-medium text-zinc-400 hover:text-white hover:border-zinc-500 transition-all"
        >
          Leave
        </button>
      </div>
    </div>
    """
  end
end
