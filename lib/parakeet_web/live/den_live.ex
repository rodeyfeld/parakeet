defmodule ParakeetWeb.DenLive do
  use ParakeetWeb, :live_view

  alias Parakeet.Den.{PitBoss, Table}

  import ParakeetWeb.DenComponents
  import ParakeetWeb.LobbyComponents

  @refresh_interval_ms 3_000

  @impl true
  def mount(_params, session, socket) do
    player_name = session["player_name"]
    session_token = session["session_token"]

    if player_name == nil or session_token == nil do
      {:ok, push_navigate(socket, to: ~p"/")}
    else
      if connected?(socket), do: schedule_refresh()

      socket =
        socket
        |> assign(
          pid: nil,
          table: nil,
          player_name: player_name,
          session_token: session_token,
          tables: []
        )
        |> check_active_table()
        |> then(fn s -> assign(s, tables: PitBoss.list_tables()) end)

      {:ok, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-2xl mx-auto space-y-8">
        <div class="flex items-center justify-between">
          <h1 class="text-3xl font-bold tracking-tight">Tables</h1>
          <div class="flex items-center gap-3">
            <span class="text-sm text-zinc-400">
              Playing as <span class="font-semibold text-white">{@player_name}</span>
            </span>
            <.link
              href={~p"/session"}
              method="delete"
              class="text-sm text-zinc-500 hover:text-zinc-300 transition-colors"
            >
              Change name
            </.link>
          </div>
        </div>

        <%= if @table do %>
          <.waiting_room table={@table} />
        <% else %>
          <%= if @active_table do %>
            <.active_table_banner table={@active_table} />
          <% end %>
          <.create_join_forms />
          <.open_tables tables={@tables} />
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_info(:refresh, socket) do
    schedule_refresh()

    if socket.assigns.pid != nil do
      try do
        table = Table.get_state(socket.assigns.pid)

        if table.engine_pid != nil do
          {:noreply, push_navigate(socket, to: ~p"/game/#{table.code}")}
        else
          {:noreply, assign(socket, table: table)}
        end
      catch
        :exit, _ ->
          {:noreply, handle_dead_table(socket)}
      end
    else
      {:noreply, socket |> assign(tables: PitBoss.list_tables()) |> check_active_table()}
    end
  end

  defp schedule_refresh, do: Process.send_after(self(), :refresh, @refresh_interval_ms)

  @impl true
  def handle_event("create_table", %{"table_name" => table_name}, socket) do
    if socket.assigns.active_table do
      {:noreply, put_flash(socket, :error, "Leave your current table first")}
    else
      case PitBoss.start_table(
             socket.assigns.session_token,
             socket.assigns.player_name,
             table_name,
             self()
           ) do
        {:ok, pid} ->
          table = Table.get_state(pid)

          {:noreply,
           socket
           |> assign(pid: pid, table: table, active_table: nil, tables: PitBoss.list_tables())}

        {:error, reason} ->
          {:noreply, put_flash(socket, :error, "Failed to create table: #{inspect(reason)}")}
      end
    end
  end

  @impl true
  def handle_event("join_table", %{"code" => code}, socket) do
    if socket.assigns.active_table do
      {:noreply, put_flash(socket, :error, "Leave your current table first")}
    else
      case PitBoss.find_table(code) do
        {:ok, pid} ->
          table =
            Table.join(pid, socket.assigns.session_token, socket.assigns.player_name, self())

          {:noreply,
           socket
           |> assign(pid: pid, table: table, active_table: nil)}

        :not_found ->
          {:noreply, put_flash(socket, :error, "Table not found: #{code}")}
      end
    end
  end

  @impl true
  def handle_event("start_game", _params, socket) do
    table = Table.start_game(socket.assigns.pid)
    {:noreply, push_navigate(socket, to: ~p"/game/#{table.code}")}
  catch
    :exit, _ -> {:noreply, handle_dead_table(socket)}
  end

  @impl true
  def handle_event("rejoin_table", _params, socket) do
    case PitBoss.find_table_by_token(socket.assigns.session_token) do
      {:ok, pid} ->
        table =
          Table.rejoin(pid, socket.assigns.session_token, socket.assigns.player_name, self())

        {:noreply, assign(socket, pid: pid, table: table, active_table: nil)}

      :not_found ->
        {:noreply, assign(socket, active_table: nil)}
    end
  end

  @impl true
  def handle_event("leave_table", _params, socket) do
    pid = socket.assigns.pid || socket.assigns[:active_table_pid]
    if pid, do: Table.leave(pid, socket.assigns.session_token)

    {:noreply,
     assign(socket,
       pid: nil,
       table: nil,
       active_table: nil,
       active_table_pid: nil,
       tables: PitBoss.list_tables()
     )}
  catch
    :exit, _ -> {:noreply, handle_dead_table(socket)}
  end

  @impl true
  def handle_event("add_bot", _params, socket) do
    table = Table.add_bot(socket.assigns.pid)
    {:noreply, assign(socket, table: table)}
  catch
    :exit, _ -> {:noreply, handle_dead_table(socket)}
  end

  @impl true
  def handle_event("remove_bot", %{"name" => name}, socket) do
    table = Table.remove_bot(socket.assigns.pid, name)
    {:noreply, assign(socket, table: table)}
  catch
    :exit, _ -> {:noreply, handle_dead_table(socket)}
  end

  @impl true
  def handle_event("refresh_tables", _params, socket) do
    {:noreply, assign(socket, tables: PitBoss.list_tables())}
  end

  defp handle_dead_table(socket) do
    socket
    |> put_flash(:error, "Table closed — it may have timed out")
    |> assign(
      pid: nil,
      table: nil,
      active_table: nil,
      active_table_pid: nil,
      tables: PitBoss.list_tables()
    )
  end

  defp check_active_table(socket) do
    if connected?(socket) do
      case PitBoss.find_table_by_token(socket.assigns.session_token) do
        {:ok, pid} ->
          try do
            table = Table.get_state(pid)

            if table.engine_pid != nil do
              assign(socket, active_table: table, active_table_pid: pid)
            else
              Table.leave(pid, socket.assigns.session_token)
              assign(socket, active_table: nil, active_table_pid: nil)
            end
          catch
            :exit, _ -> assign(socket, active_table: nil, active_table_pid: nil)
          end

        :not_found ->
          assign(socket, active_table: nil, active_table_pid: nil)
      end
    else
      assign(socket, active_table: nil, active_table_pid: nil)
    end
  end
end
