# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :coup_phx2,
  ecto_repos: [CoupPhx2.Repo]

# Configures the endpoint
config :coup_phx2, CoupPhx2Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "aQTQqRR6dfuBERg8pcTl5X0F71fxNFQhlEsJNDSAjWvl7j6ruZRBPQ69aMwoehRb",
  render_errors: [view: CoupPhx2Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: CoupPhx2.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [
    signing_salt: "7szqDN2zJXwIMjq1naqRn582kxSXApT3"
  ]

# Configures game pubsub
config :coup_phx2, :game_pubsub, Phoenix.PubSub

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# LiveView
config :phoenix, template_engines: [leex: Phoenix.LiveView.Engine]

# Test watcher
if Mix.env() == :dev do
  config :mix_test_watch,
    tasks: [
      "test",
      "credo"
    ]
end

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
