defmodule Jamify.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      JamifyWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:jamify, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Jamify.PubSub},
      {Jamify.JamSessionSupervisor, []},
      {Registry, name: :jam_session_registry, keys: :unique},
      # Start a worker by calling: Jamify.Worker.start_link(arg)
      # {Jamify.Worker, arg},
      # Start to serve requests, typically the last entry
      JamifyWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Jamify.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    JamifyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
