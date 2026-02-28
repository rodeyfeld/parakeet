defmodule ParakeetWeb.Router do
  use ParakeetWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ParakeetWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ParakeetWeb do
    pipe_through :browser

    live "/", HomeLive
    live "/den", DenLive
    live "/game/:code", GameLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", ParakeetWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:parakeet, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ParakeetWeb.Telemetry
    end
  end
end
