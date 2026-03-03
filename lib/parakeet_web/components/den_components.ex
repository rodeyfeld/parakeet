defmodule ParakeetWeb.DenComponents do
  use ParakeetWeb, :html

  attr :table, :map, required: true

  def waiting_room(assigns) do
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
            class="rounded-full bg-zinc-800 border border-zinc-700 px-4 py-1.5 text-sm font-medium"
          >
            {name}
          </span>
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

  def create_join_forms(assigns) do
    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <div class="rounded-xl border border-zinc-700 bg-zinc-900/60 p-6 space-y-4">
        <h2 class="text-lg font-semibold">Create a Table</h2>
        <.form for={%{}} phx-submit="create_table" id="create-table-form" class="space-y-3">
          <.input
            type="text"
            name="table_name"
            value=""
            label="Table Name"
            placeholder=""
          />
          <button
            type="submit"
            class="w-full rounded-lg bg-emerald-600 hover:bg-emerald-500 text-white px-4 py-2.5 font-semibold transition-all hover:scale-[1.02] active:scale-95"
          >
            Create Table
          </button>
        </.form>
      </div>

      <div class="rounded-xl border border-zinc-700 bg-zinc-900/60 p-6 space-y-4">
        <h2 class="text-lg font-semibold">Join a Table</h2>
        <.form for={%{}} phx-submit="join_table" id="join-table-form" class="space-y-3">
          <.input
            type="text"
            name="code"
            value=""
            label="Table Code"
            placeholder="ABC123"
            class="font-mono tracking-widest uppercase text-center text-lg rounded-lg border border-zinc-700 bg-zinc-800 px-3 py-2 w-full focus:outline-none focus:ring-2 focus:ring-emerald-500/50"
          />
          <button
            type="submit"
            class="w-full rounded-lg border border-zinc-600 hover:border-zinc-400 text-white px-4 py-2.5 font-semibold transition-all hover:scale-[1.02] active:scale-95"
          >
            Join Table
          </button>
        </.form>
      </div>
    </div>
    """
  end

  attr :tables, :list, required: true

  def open_tables(assigns) do
    ~H"""
    <div class="rounded-xl border border-zinc-700 bg-zinc-900/60 p-6 space-y-4">
      <div class="flex items-center justify-between">
        <h2 class="text-lg font-semibold">Open Tables</h2>
        <button
          phx-click="refresh_tables"
          id="refresh-tables-btn"
          class="text-sm text-zinc-400 hover:text-white transition-colors"
        >
          Refresh
        </button>
      </div>
      <%= if @tables == [] do %>
        <p class="text-sm text-zinc-500">No tables open yet.</p>
      <% else %>
        <div class="space-y-2">
          <.table_row :for={table <- @tables} table={table} />
        </div>
      <% end %>
    </div>
    """
  end

  attr :table, :map, required: true

  def table_row(assigns) do
    ~H"""
    <div class="flex items-center justify-between rounded-lg bg-zinc-800/60 border border-zinc-700/50 px-4 py-3">
      <div>
        <div class="font-medium">{@table.name}</div>
        <div class="text-sm text-zinc-400">
          {length(@table.player_names)} players · <span class="font-mono">{@table.code}</span>
        </div>
      </div>
      <%= cond do %>
        <% @table.game_status == :finished -> %>
          <span class="text-xs text-zinc-500 font-medium">Finished</span>
        <% @table.game_status == :running -> %>
          <span class="text-xs text-amber-400 font-medium">In Game</span>
        <% true -> %>
          <button
            phx-click="join_table"
            phx-value-code={@table.code}
            class="rounded-lg border border-zinc-600 hover:border-zinc-400 text-sm text-white px-3 py-1.5 font-medium transition-all hover:scale-105 active:scale-95"
          >
            Join
          </button>
      <% end %>
    </div>
    """
  end
end
