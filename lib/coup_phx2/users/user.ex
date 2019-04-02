defmodule CoupPhx2.User do
  @moduledoc """
  User model. currently not backed by db
  """
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :name, :string
  end

  def changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
