defmodule ParakeetWeb.PageController do
  use ParakeetWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
