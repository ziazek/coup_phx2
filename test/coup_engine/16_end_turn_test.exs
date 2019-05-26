defmodule CoupEngine.EndTurnTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Game, Player, Turn}

  describe "end_turn" do
    setup do
      state =
        initial_state(%{
          state: "turn_ending",
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

      {:noreply, updated_state, _continue} = Game.handle_info(:end_turn, state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should update game state to checking_for_win", %{updated_state: updated_state} do
      assert updated_state.state == "checking_for_win"
    end

    test "should add current turn to past_turns", %{updated_state: updated_state} do
      assert length(updated_state.past_turns) == 1
      last_past_turn = updated_state.past_turns |> Enum.at(-1)
      assert last_past_turn.player.name == "Jany"
    end

    test "should send check_for_win to self" do
      assert_receive {:check_for_win, 10}
    end
  end
end
