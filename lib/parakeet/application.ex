defmodule Parakeet.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ParakeetWeb.Telemetry,
      Parakeet.Repo,
      {DNSCluster, query: Application.get_env(:parakeet, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Parakeet.PubSub},
      # Start a worker by calling: Parakeet.Worker.start_link(arg)
      # {Parakeet.Worker, arg},
      # Pitboss Requires Registry
      {Registry, keys: :unique, name: Parakeet.Den.Registry},
      Parakeet.Den.PitBoss,
      Parakeet.Game.Supervisor,
      # Start to serve requests, typically the last entry
      ParakeetWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Parakeet.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ParakeetWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
