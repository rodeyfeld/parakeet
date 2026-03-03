defmodule ParakeetWeb.Plugs.EnsureSessionToken do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    if get_session(conn, :session_token) do
      conn
    else
      token = Base.encode64(:crypto.strong_rand_bytes(16))
      put_session(conn, :session_token, token)
    end
  end
end
