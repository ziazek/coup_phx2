defmodule CoupPhx2.Repo do
  use Ecto.Repo,
    otp_app: :coup_phx2,
    adapter: Ecto.Adapters.Postgres
end
