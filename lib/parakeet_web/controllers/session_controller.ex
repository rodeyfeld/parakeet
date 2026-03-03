defmodule ParakeetWeb.SessionController do
  use ParakeetWeb, :controller

  def create(conn, %{"name" => name}) do
    name = String.trim(name)

    if name == "" do
      conn
      |> put_flash(:error, "Enter a name to play")
      |> redirect(to: ~p"/")
    else
      conn
      |> put_session(:player_name, name)
      |> redirect(to: ~p"/den")
    end
  end

  def create(conn, _params) do
    conn
    |> put_flash(:error, "Enter a name to play")
    |> redirect(to: ~p"/")
  end

  def delete(conn, _params) do
    case get_session(conn, :session_token) do
      nil ->
        :ok

      token ->
        case Parakeet.Den.PitBoss.find_table_by_token(token) do
          {:ok, pid} -> Parakeet.Den.Table.leave(pid, token)
          :not_found -> :ok
        end
    end

    conn
    |> delete_session(:player_name)
    |> redirect(to: ~p"/")
  end
end
