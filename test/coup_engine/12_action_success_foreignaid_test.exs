defmodule CoupEngine.ActionSuccessForeignaidTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Game, Player, Turn}

  describe "action_success, foreignaid" do
    setup do
      state =
        initial_state(%{
          state: "action_success",
          players: [
            %Player{name: "Jany", session_id: "session_id1", coins: 0}
          ],
          turn: %Turn{
            player: %Player{name: "Jany", session_id: "session_id1"},
            action: %{action: "foreignaid", state: "ok"}
          }
        })

      {:noreply, updated_state, _continue} = Game.handle_info(:action_success, state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should increase player's coins by 2", %{updated_state: updated_state} do
      player = updated_state.players |> Enum.at(0)
      assert player.coins == 2
    end

    test "should update toast to 'Jany received 2 coins.'", %{updated_state: updated_state} do
      latest_toast = updated_state.toast |> Enum.at(-1)
      assert latest_toast.body == "Jany received 2 coins."
    end

    test "should mark turn as ended", %{updated_state: updated_state} do
      assert updated_state.turn.state == "ended"
    end

    test "should send end_turn to self" do
      assert_receive {:end_turn, 1000}
    end
  end
end
