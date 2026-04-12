defmodule ParakeetWeb.UserSocket do
  use Phoenix.Socket

  channel "game:*", ParakeetWeb.GameChannel

  @max_age 86_400

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case Phoenix.Token.verify(socket, "game_socket", token, max_age: @max_age) do
      {:ok, %{session_token: session_token, player_name: player_name}} ->
        socket =
          socket
          |> assign(:session_token, session_token)
          |> assign(:player_name, player_name)

        {:ok, socket}

      {:error, _reason} ->
        :error
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.session_token}"
end
