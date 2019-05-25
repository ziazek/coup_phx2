defmodule CoupEngine.ActionSuccessAssassinateTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Action, Game, Player, Turn}

  describe "action_success, assassinate" do
    setup do
      state =
        initial_state(%{
          state: "action_success",
          players: [
            %Player{name: "Ken", session_id: "session_id1"},
            %Player{name: "Zek", session_id: "session_id2"}
          ],
          turn: %Turn{
            player: %Player{name: "Ken", session_id: "session_id1"},
            action: %Action{
              action: "assassinate",
              label: "Assassinate",
              state: "ok"
            },
            state: "active",
            target: %Player{name: "Zek", session_id: "session_id2"}
          }
        })

      {:noreply, updated_state, _continue} = Game.handle_info(:action_success, state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should change game state to target_lose_influence", %{updated_state: updated_state} do
      assert updated_state.state == "target_lose_influence"
    end

    test "should update toast to 'ASSASSINATION is successful.'", %{
      updated_state: updated_state
    } do
      latest_toast = updated_state.toast |> Enum.at(-1)
      assert latest_toast.body == "ASSASSINATION is successful."
    end

    test "should not mark turn as ended", %{updated_state: updated_state} do
      assert updated_state.turn.state == "active"
    end

    test "should send lose_influence to self" do
      assert_receive {:lose_influence, 1000}
    end
  end
end
