defmodule CoupEngine.SelectTargetCoupTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Action, Game, Player, Turn}

  describe "select_target, coup" do
    setup do
      state =
        initial_state(%{
          state: "select_target",
          players: [
            %Player{name: "Jany", session_id: "session_id1", display_state: "select_target"},
            %Player{name: "Vincent", session_id: "session_id2"}
          ],
          turn: %Turn{
            player: %Player{name: "Jany", session_id: "session_id1"},
            action: %Action{
              action: "coup",
              label: "Coup",
              state: "ok"
            },
            target: %{state: "pending"}
          }
        })

      {:reply, :ok, updated_state, _continue} =
        Game.handle_call({:select_target, "session_id2"}, "_pid", state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should set turn target to player", %{updated_state: updated_state} do
      turn = updated_state.turn
      assert turn.target.name == "Vincent"
      assert turn.target.session_id == "session_id2"
      assert turn.target.state == "ok"
    end

    test "should update toast to 'Jany COUPS Vincent.'", %{
      updated_state: updated_state
    } do
      latest_toast = updated_state.toast |> Enum.at(-1)
      assert latest_toast.body == "Jany COUPS Vincent."
    end

    test "should set Jany's display_state to default", %{updated_state: updated_state} do
      jany = updated_state.players |> Enum.at(0)
      assert jany.display_state == "default"
    end

    test "should set game state to action_success", %{updated_state: updated_state} do
      assert updated_state.state == "action_success"
    end

    test "should send action_success to self" do
      assert_receive {:action_success, 1000}
    end
  end
end
