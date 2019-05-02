defmodule CoupEngine.AttemptActionStealTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Action, Game, Player, Turn}

  describe "action steal" do
    setup do
      state =
        initial_state(%{
          state: "player_action",
          players: [
            %Player{name: "Ken", session_id: "session_id1"},
            %Player{name: "Zek", session_id: "session_id2", coins: 2},
            %Player{name: "Naz", session_id: "session_id3"}
          ],
          turn: %Turn{
            player: %Player{name: "Ken", session_id: "session_id1"},
            action: %{state: "pending"}
          }
        })

      {:reply, :ok, updated_state, _continue} =
        Game.handle_call({:action, "steal"}, "_pid", state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should set turn action", %{updated_state: updated_state} do
      assert updated_state.turn.action == %Action{
               action: "steal",
               label: "Steal",
               state: "ok"
             }
    end

    test "should set turn player_claimed_character to Captain", %{updated_state: updated_state} do
      assert updated_state.turn.player_claimed_character == "Captain"
    end

    test "should update toast to 'Ken chose STEAL. Selecting target...'", %{
      updated_state: updated_state
    } do
      latest_toast = updated_state.toast |> Enum.at(-1)
      assert latest_toast.body == "Ken chose STEAL. Selecting target..."
    end

    test "should set game state to select_target", %{updated_state: updated_state} do
      assert updated_state.state == "select_target"
    end

    test "should update Ken display_state to select_target", %{
      updated_state: updated_state
    } do
      ken = updated_state.players |> Enum.at(0)

      assert ken.display_state == "select_target"
    end
  end
end
