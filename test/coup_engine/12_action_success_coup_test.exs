defmodule CoupEngine.ActionSuccessCoupTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Game, Player, Turn}

  describe "action_success, coup, target has 2 cards" do
    setup do
      state =
        initial_state(%{
          state: "action_success",
          players: [
            %Player{name: "Jany", session_id: "session_id1", coins: 0},
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

    test "should change game state to lose_influence", %{updated_state: updated_state} do
      assert updated_state.state == "lose_influence"
    end

    test "should update Vincent's display_state to lose_influence", %{
      updated_state: updated_state
    } do
      vincent = updated_state.players |> Enum.at(1)
      assert vincent.display_state == "lose_influence"
    end

    test "should update toast to 'Vincent loses 1 influence. Choosing card to discard...'", %{
      updated_state: updated_state
    } do
      latest_toast = updated_state.toast |> Enum.at(-1)
      assert latest_toast.body == "Vincent loses 1 influence. Choosing card to discard..."
    end

    test "should not mark turn as ended", %{updated_state: updated_state} do
      assert updated_state.turn.state == "active"
    end

    test "should send end_turn to self" do
      assert_receive {:end_turn, 1000}
    end
  end
end
