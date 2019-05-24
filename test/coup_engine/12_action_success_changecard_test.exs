defmodule CoupEngine.ActionSuccessChangeCardTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Game, Player, Turn}

  describe "action_success, changecard" do
    setup do
      state =
        initial_state(%{
          state: "action_success",
          players: [
            %Player{name: "Jany", session_id: "session_id1", coins: 0}
          ],
          turn: %Turn{
            player: %Player{name: "Jany", session_id: "session_id1"},
            action: %{action: "changecard", state: "ok"},
            target: %{state: "pending"},
            state: "active"
          }
        })

      {:noreply, updated_state, _continue} = Game.handle_info(:action_success, state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should change game state to change_card_draw_card", %{updated_state: updated_state} do
      assert updated_state.state == "change_card_draw_card"
    end
    
    # test "should change Jany's display_state to change_card", %{updated_state: updated_state} do
    #   jany = updated_state.players |> Enum.at(0)
    #   assert jany.display_state == "change_card"
    # end

    test "should update toast to 'Jany draws the top 2 cards. Selecting...'", %{
      updated_state: updated_state
    } do
      latest_toast = updated_state.toast |> Enum.at(-1)
      assert latest_toast.body == "Jany draws the top 2 cards. Selecting..."
    end

    test "should not mark turn as ended", %{updated_state: updated_state} do
      assert updated_state.turn.state == "active"
    end

    test "should send change_card_draw_card to self" do
      assert_receive {:change_card_draw_card, 1000}
    end
  end
end
