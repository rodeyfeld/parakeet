defmodule ParakeetWeb.DenLive do
  use ParakeetWeb, :live_view
  alias Parakeet.Den.{PitBoss, Table}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
      assign(socket,
      pid: nil,
      tables: PitBoss.list_tables()
    )}
  end

  @impl true
  def handle_event("create_table", %{"player_name" => player_name, "table_name" => table_name}, socket) do
    case Parakeet.Den.PitBoss.start_table(player_name, table_name) do
      {:ok, pid} ->
        table = Table.get_state(pid)

        {:noreply,
          assign(socket,
            pid: pid,
            table: table
          )
        }
      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to start table: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("join_table", %{"code" => code, "player_name" => player_name}, socket) do
    case Parakeet.Den.PitBoss.find_table(code) do
      {:ok, pid} ->
        state = Table.join(pid, player_name)
        {:noreply, assign(socket, pid: pid, table: state)}
      :not_found ->
        {:noreply, put_flash(socket, :error, "Table not found: #{code}")}
    end
  end

  @impl true
  def handle_event("list_tables", _params, socket) do
    tables = Parakeet.Den.PitBoss.list_tables()
    {:noreply, assign(socket, tables: tables)}
  end
end
