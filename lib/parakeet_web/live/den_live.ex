defmodule ParakeetWeb.DenLive do
  use ParakeetWeb, :live_view

  alias Parakeet.Den.{PitBoss, Table}

  import ParakeetWeb.DenComponents

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
          <.waiting_room table={@table} />
        <% else %>
          <.create_join_forms />
          <.open_tables tables={@tables} />
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
