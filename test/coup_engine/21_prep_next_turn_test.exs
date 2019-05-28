defmodule CoupEngine.PrepNextTurnTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Game, Player, Turn}

  describe "prep next turn" do
    setup do
      state =
        initial_state(%{
          state: "turn_ended",
          players: [
            %Player{name: "Jany", session_id: "session_id1", coins: 0},
            %Player{name: "DeadPlayer", session_id: "session_id2", coins: 0, state: "dead"},
            %Player{name: "Celine", session_id: "session_id3", coins: 2}
          ],
          turn: %Turn{
            player: %Player{name: "Jany", session_id: "session_id1"},
            action: %{action: "1coin", state: "ok"},
            state: "active"
          }
        })

      {:noreply, updated_state, _continue} = Game.handle_info(:prep_next_turn, state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should update game state to next_turn_prepped", %{updated_state: updated_state} do
      assert updated_state.state == "next_turn_prepped"
    end

    test "should reset turn to all attributes pending", %{updated_state: updated_state} do
      turn = updated_state.turn
      assert turn.player.state == "pending"
      assert turn.action.state == "pending"
      assert turn.target.state == "pending"
      assert turn.target_response.state == "pending"
      assert turn.player_response_to_block.state == "pending"
    end

    test "should send {:start_turn, 2} to self" do
      assert_receive {{:start_turn, 2}, 200}
    end
  end
end
