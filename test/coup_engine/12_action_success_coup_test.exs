defmodule CoupEngine.ActionSuccessCoupTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Game, Player, Turn}

  describe "action_success, coup" do
    setup do
      state =
        initial_state(%{
          state: "action_success",
          players: [
            %Player{name: "Jany", session_id: "session_id1"},
            %Player{name: "Vincent", session_id: "session_id2"}
          ],
          turn: %Turn{
            player: %Player{name: "Jany", session_id: "session_id1"},
            action: %{action: "coup", state: "ok"},
            target: %Player{name: "Vincent", session_id: "session_id2"},
            state: "active"
          }
        })

      {:noreply, updated_state, _continue} = Game.handle_info(:action_success, state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should change game state to target_lose_influence", %{updated_state: updated_state} do
      assert updated_state.state == "target_lose_influence"
    end

    test "should update toast to 'COUP is successful.'", %{
      updated_state: updated_state
    } do
      latest_toast = updated_state.toast |> Enum.at(-1)
      assert latest_toast.body == "COUP is successful."
    end

    test "should not mark turn as ended", %{updated_state: updated_state} do
      assert updated_state.turn.state == "active"
    end

    test "should send lose_influence to self" do
      assert_receive {:lose_influence, 1000}
    end
  end
end
