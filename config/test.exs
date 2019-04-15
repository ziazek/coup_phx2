use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :coup_phx2, CoupPhx2Web.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :coup_phx2, CoupPhx2.Repo,
  username: "postgres",
  password: "postgres",
  database: "coup_phx2_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :coup_phx2, :game_pubsub, PubSubMock
config :coup_phx2, :game_process, ProcessMock
