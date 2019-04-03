defmodule CoupPhx2Web.GameCase do
  @moduledoc """
  This module defines the test case to be used by
  channel tests.

  Such tests rely on `Phoenix.ChannelTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias CoupEngine.{Game, Rules}

      defp initial_state(map_to_merge \\ %{}) do
        %{
          game_name: "",
          players: [],
          deck: [],
          discard: [],
          rules: %Rules{state: :adding_players}
        }
        |> Map.merge(map_to_merge)
      end
    end
  end

  # setup tags do
  #   :ok = Ecto.Adapters.SQL.Sandbox.checkout(CoupPhx2.Repo)
  #
  #   unless tags[:async] do
  #     Ecto.Adapters.SQL.Sandbox.mode(CoupPhx2.Repo, {:shared, self()})
  #   end
  #
  #   :ok
  # end
end
