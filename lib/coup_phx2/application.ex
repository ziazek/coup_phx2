defmodule CoupPhx2.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {Registry, keys: :unique, name: Registry.Game},
      {Registry, keys: :unique, name: Registry.Concept},
      {Phoenix.PubSub.PG2, name: :game_pubsub},
      CoupEngine.GameSupervisor,
      Concept.GameSupervisor,
      # Start the Ecto repository
      CoupPhx2.Repo,
      # Start the endpoint when the application starts
      CoupPhx2Web.Endpoint
      # Starts a worker by calling: CoupPhx2.Worker.start_link(arg)
      # {CoupPhx2.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CoupPhx2.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    CoupPhx2Web.Endpoint.config_change(changed, removed)
    :ok
  end
end
