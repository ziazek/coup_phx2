defmodule CoupEngine.AddPlayerTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Game, Player, Toast}

  describe "add_player/3" do
    setup do
      state =
        initial_state(%{
          state: "adding_players",
          players: [
            %Player{
              name: "GroupCreator",
              session_id: "session_id1",
              role: "creator"
            }
          ]
        })

      {:ok, %{state: state}}
    end

    test "should add player with actions populated", %{state: state} do
      {:reply, :ok, updated_state, _continue} =
        Game.handle_call({:add_player, "session_id2", "A1"}, "_pid", state)

      assert length(updated_state.players) == 2
      player2 = updated_state.players |> Enum.at(1)
      assert length(player2.actions) == 7
    end

    test "should update toast", %{state: state} do
      {:reply, :ok, updated_state, _continue} =
        Game.handle_call({:add_player, "session_id2", "A1"}, "_pid", state)

      assert updated_state.toast == [
               %Toast{body: "Waiting for players"},
               %Toast{body: "A1 has joined the game."}
             ]
    end

    test "given duplicate session_id, should return error", %{state: state} do
      result = Game.handle_call({:add_player, "session_id1", "GroupCreator"}, "_pid", state)

      assert result == {:reply, {:error, "player exists"}, state}
    end

    test "should not add player if game state is not :adding_players", %{state: state} do
      state = state |> Map.put(:state, "started")

      result = Game.handle_call({:add_player, "session_id2", "A1"}, "_pid", state)

      assert result == {:reply, {:error, "invalid game state"}, state}
    end

    test "should use handle_continue to broadcast to game channel that game state has changed", %{
      state: state
    } do
      state = state |> Map.put(:game_name, "Game1")

      {:reply, :ok, _new_state, continue} =
        Game.handle_call({:add_player, "session_id2", "A1"}, "_pid", state)

      assert continue == {:continue, :broadcast_change}
    end
  end

  describe "add_player/3, given max players (6)" do
    setup do
      state =
        initial_state(%{
          state: "adding_players",
          players: [
            %Player{
              name: "GroupCreator",
              session_id: "session_id1",
              role: "creator"
            },
            %Player{
              name: "A1",
              session_id: "session_id2",
              role: "player"
            },
            %Player{
              name: "A2",
              session_id: "session_id3",
              role: "player"
            },
            %Player{
              name: "A3",
              session_id: "session_id4",
              role: "player"
            },
            %Player{
              name: "A4",
              session_id: "session_id5",
              role: "player"
            },
            %Player{
              name: "A5",
              session_id: "session_id6",
              role: "player"
            }
          ]
        })

      {:ok, %{state: state}}
    end

    test "should not add player", %{state: state} do
      {:reply, {:error, reason}, _state} =
        Game.handle_call({:add_player, "session_id7", "A6"}, "_pid", state)

      assert reason == "maximum number of players reached"
    end
  end
end
