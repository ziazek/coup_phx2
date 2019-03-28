defmodule CoupEngine.GameTest do
  use ExUnit.Case, async: true

  alias CoupEngine.{Game, Rules}

  test "init/1 should return the initial state" do
    result = Game.init("TH")

    assert result ==
             {:ok,
              %{
                players: [
                  %{role: "creator", name: "TH"}
                ],
                deck: [],
                discard: [],
                rules: %Rules{}
              }}
  end

  describe "add_player" do
    test "given a new player, should add a player to the state" do
      state =
        initial_state(%{
          players: [
            %{role: "creator", name: "TH"}
          ]
        })

      result = Game.handle_call({:add_player, "Naz"}, "_pid", state)

      expected_state =
        initial_state(%{
          players: [
            %{role: "creator", name: "TH"},
            %{role: "player", name: "Naz"}
          ]
        })

      assert result == {:reply, :ok, expected_state}
    end

    # max players = 6
    test "given max players, should not add player" do
      state =
        initial_state(%{
          players: [
            %{role: "creator", name: "TH"},
            %{role: "member", name: "A1"},
            %{role: "member", name: "A2"},
            %{role: "member", name: "A3"},
            %{role: "member", name: "A4"},
            %{role: "member", name: "A5"}
          ]
        })

      result = Game.handle_call({:add_player, "LateGuy"}, "_pid", state)

      expected_state =
        initial_state(%{
          players: [
            %{role: "creator", name: "TH"},
            %{role: "member", name: "A1"},
            %{role: "member", name: "A2"},
            %{role: "member", name: "A3"},
            %{role: "member", name: "A4"},
            %{role: "member", name: "A5"}
          ]
        })

      assert result == {:reply, :error, "maximum number of players reached"}
    end
  end

  describe "start_game" do
    test "given insufficient players, should return :error" do
    end
  end

  defp initial_state(map_to_merge) do
    %{
      players: [],
      deck: [],
      discard: [],
      rules: %Rules{}
    }
    |> Map.merge(map_to_merge)
  end
end
