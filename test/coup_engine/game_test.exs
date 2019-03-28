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
                rules: %Rules{state: :adding_players}
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

      {:reply, {:error, reason}, state_data} = result

      assert reason == "maximum number of players reached"
      assert state_data == expected_state
    end
  end

  describe "start_game" do
    test "given sufficient players, should return :ok and state :game_started" do
      state =
        initial_state(%{
          players: [
            %{role: "creator", name: "TH"},
            %{role: "player", name: "Ken"}
          ]
        })

      result = Game.handle_call(:start_game, "_pid", state)

      expected_state =
        initial_state(%{
          players: [
            %{role: "creator", name: "TH"},
            %{role: "player", name: "Ken"}
          ],
          rules: %Rules{state: :game_started}
        })

      assert result == {:reply, :ok, expected_state}
    end

    test "given insufficient players, should return :error" do
      state =
        initial_state(%{
          players: [
            %{role: "creator", name: "TH"}
          ]
        })

      result = Game.handle_call(:start_game, "_pid", state)

      expected_state = state

      {:reply, {:error, reason}, state_data} = result

      assert reason == "insufficient players"
      assert state_data == expected_state
    end
  end

  defp initial_state(map_to_merge) do
    %{
      players: [],
      deck: [],
      discard: [],
      rules: %Rules{state: :adding_players}
    }
    |> Map.merge(map_to_merge)
  end
end
