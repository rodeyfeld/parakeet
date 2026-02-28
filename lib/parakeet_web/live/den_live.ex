defmodule ParakeetWeb.DenLive do
  use ParakeetWeb, :live_view

  alias Parakeet.Den.{PitBoss, Table}

  @refresh_interval_ms 3_000

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: schedule_refresh()

    {:ok,
     assign(socket,
       pid: nil,
       table: nil,
       player_name: nil,
       tables: PitBoss.list_tables()
     )}
  end

  @impl true
  def handle_params(%{"code" => code, "name" => name}, _uri, socket) do
    if connected?(socket) and socket.assigns.pid == nil do
      case PitBoss.find_table(code) do
        {:ok, pid} ->
          table = Table.rejoin(pid, name, self())
          {:noreply, assign(socket, pid: pid, table: table, player_name: name)}

        :not_found ->
          {:noreply,
           socket
           |> put_flash(:error, "Table no longer exists")
           |> push_patch(to: ~p"/den?name=#{name}")}
      end
    else
      {:noreply, assign(socket, player_name: name)}
    end
  end

  def handle_params(%{"name" => name}, _uri, socket) do
    {:noreply, assign(socket, player_name: name)}
  end

  def handle_params(_params, _uri, socket) do
    if connected?(socket) do
      {:noreply, push_navigate(socket, to: ~p"/")}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(:refresh, socket) do
    schedule_refresh()

    cond do
      socket.assigns.pid != nil ->
        table = Table.get_state(socket.assigns.pid)

        if table.engine_pid != nil do
          {:noreply,
           push_navigate(socket, to: ~p"/game/#{table.code}?name=#{socket.assigns.player_name}")}
        else
          {:noreply, assign(socket, table: table)}
        end

      true ->
        {:noreply, assign(socket, tables: PitBoss.list_tables())}
    end
  end

  defp schedule_refresh, do: Process.send_after(self(), :refresh, @refresh_interval_ms)

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-2xl mx-auto space-y-8">
        <div class="flex items-center justify-between">
          <h1 class="text-3xl font-bold tracking-tight">The Den</h1>
          <div class="flex items-center gap-3">
            <span class="text-sm text-zinc-400">
              Playing as <span class="font-semibold text-white">{@player_name}</span>
            </span>
            <.link
              navigate={~p"/"}
              class="text-sm text-zinc-500 hover:text-zinc-300 transition-colors"
            >
              Change name
            </.link>
          </div>
        </div>

        <%= if @table do %>
          <%!-- Table Waiting Room --%>
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
                <%= for name <- @table.player_names do %>
                  <span class="rounded-full bg-zinc-800 border border-zinc-700 px-4 py-1.5 text-sm font-medium">
                    {name}
                  </span>
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
                      do:
                        "bg-emerald-600 hover:bg-emerald-500 text-white hover:scale-105 active:scale-95",
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
        <% else %>
          <%!-- Create / Join --%>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <%!-- Create Table --%>
            <div class="rounded-xl border border-zinc-700 bg-zinc-900/60 p-6 space-y-4">
              <h2 class="text-lg font-semibold">Create a Table</h2>
              <.form for={%{}} phx-submit="create_table" id="create-table-form" class="space-y-3">
                <.input
                  type="text"
                  name="table_name"
                  value=""
                  label="Table Name"
                  placeholder="Friday Night Cards"
                />
                <button
                  type="submit"
                  class="w-full rounded-lg bg-emerald-600 hover:bg-emerald-500 text-white px-4 py-2.5 font-semibold transition-all hover:scale-[1.02] active:scale-95"
                >
                  Create Table
                </button>
              </.form>
            </div>

            <%!-- Join Table --%>
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

          <%!-- Open Tables --%>
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
              <p class="text-sm text-zinc-500">No tables open yet. Create one!</p>
            <% else %>
              <div class="space-y-2">
                <%= for table <- @tables do %>
                  <div class="flex items-center justify-between rounded-lg bg-zinc-800/60 border border-zinc-700/50 px-4 py-3">
                    <div>
                      <div class="font-medium">{table.name}</div>
                      <div class="text-sm text-zinc-400">
                        {length(table.player_names)} players ·
                        <span class="font-mono">{table.code}</span>
                      </div>
                    </div>
                    <%= cond do %>
                      <% table.game_status == :finished -> %>
                        <span class="text-xs text-zinc-500 font-medium">Finished</span>
                      <% table.game_status == :running -> %>
                        <span class="text-xs text-amber-400 font-medium">In Game</span>
                      <% true -> %>
                        <button
                          phx-click="join_table"
                          phx-value-code={table.code}
                          class="rounded-lg border border-zinc-600 hover:border-zinc-400 text-sm text-white px-3 py-1.5 font-medium transition-all hover:scale-105 active:scale-95"
                        >
                          Join
                        </button>
                    <% end %>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("create_table", %{"table_name" => table_name}, socket) do
    player_name = socket.assigns.player_name

    case PitBoss.start_table(player_name, table_name, self()) do
      {:ok, pid} ->
        table = Table.get_state(pid)

        {:noreply,
         socket
         |> assign(pid: pid, table: table, tables: PitBoss.list_tables())
         |> push_patch(to: ~p"/den?code=#{table.code}&name=#{player_name}")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to create table: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("join_table", %{"code" => code}, socket) do
    player_name = socket.assigns.player_name

    case PitBoss.find_table(code) do
      {:ok, pid} ->
        table = Table.join(pid, player_name, self())

        {:noreply,
         socket
         |> assign(pid: pid, table: table)
         |> push_patch(to: ~p"/den?code=#{table.code}&name=#{player_name}")}

      :not_found ->
        {:noreply, put_flash(socket, :error, "Table not found: #{code}")}
    end
  end

  @impl true
  def handle_event("start_game", _params, socket) do
    table = Table.start_game(socket.assigns.pid)

    {:noreply,
     push_navigate(socket, to: ~p"/game/#{table.code}?name=#{socket.assigns.player_name}")}
  end

  @impl true
  def handle_event("leave_table", _params, socket) do
    {:noreply,
     socket
     |> assign(pid: nil, table: nil, tables: PitBoss.list_tables())
     |> push_patch(to: ~p"/den?name=#{socket.assigns.player_name}")}
  end

  @impl true
  def handle_event("refresh_tables", _params, socket) do
    {:noreply, assign(socket, tables: PitBoss.list_tables())}
  end
end
