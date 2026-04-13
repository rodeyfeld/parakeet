defmodule ParakeetWeb.GameLive do
  use ParakeetWeb, :live_view

  alias Parakeet.Den.{PitBoss, Table}
  alias Parakeet.Game.Engine

  @impl true
  def mount(%{"code" => code}, session, socket) do
    player_name = session["player_name"]
    session_token = session["session_token"]

    case PitBoss.find_table(code) do
      {:ok, table_pid} ->
        table = Table.get_state(table_pid)

        cond do
          player_name == nil ->
            {:ok, push_navigate(socket, to: ~p"/")}

          table.engine_pid == nil ->
            {:ok,
             socket
             |> put_flash(:error, "Game hasn't started yet")
             |> push_navigate(to: ~p"/den")}

          safe_get_state(table.engine_pid) == nil ->
            {:ok,
             socket
             |> put_flash(:error, "Game is no longer running")
             |> push_navigate(to: ~p"/den")}

          true ->
            token =
              Phoenix.Token.sign(
                ParakeetWeb.Endpoint,
                "game_socket",
                %{session_token: session_token, player_name: player_name}
              )

            {:ok, assign(socket, code: code, game_token: token)}
        end

      :not_found ->
        {:ok,
         socket
         |> put_flash(:error, "Table not found")
         |> push_navigate(to: ~p"/")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div
        id="game"
        phx-hook="Game"
        phx-update="ignore"
        data-code={@code}
        data-token={@game_token}
      >
        <div class="flex items-center justify-center min-h-[60vh]">
          <span class="text-zinc-600 dark:text-zinc-400">Connecting to game...</span>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp safe_get_state(pid) do
    Engine.get_state(pid)
  catch
    :exit, _ -> nil
  end
end
