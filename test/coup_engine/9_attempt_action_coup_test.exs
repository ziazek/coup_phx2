defmodule CoupEngine.AttemptActionCoupTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Action, Game, Player, Turn}

  describe "action coup, with 7 coins" do
    setup do
      state =
        initial_state(%{
          state: "player_action",
          players: [
            %Player{name: "Jany", session_id: "session_id1", coins: 7},
            %Player{name: "Vincent", session_id: "session_id2", coins: 0}
          ],
          turn: %Turn{
            player: %Player{name: "Jany", session_id: "session_id1"},
            action: %{state: "pending"}
          }
        })

      {:reply, :ok, updated_state, _continue} = Game.handle_call({:action, "coup"}, "_pid", state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should set turn action", %{updated_state: updated_state} do
      assert updated_state.turn.action == %Action{
               action: "coup",
               label: "Coup",
               state: "ok"
             }
    end

    test "should update toast to 'Jany chose COUP. Selecting target...'", %{
      updated_state: updated_state
    } do
      latest_toast = updated_state.toast |> Enum.at(-1)
      assert latest_toast.body == "Jany chose COUP. Selecting target..."
    end

    test "should set game state to select_target", %{updated_state: updated_state} do
      assert updated_state.state == "select_target"
    end

    test "should set Jany's display_state to select_target", %{updated_state: updated_state} do
      jany = updated_state.players |> Enum.at(0)
      assert jany.display_state == "select_target"
    end

    test "should maintain Vincent's display_state at default", %{updated_state: updated_state} do
      vincent = updated_state.players |> Enum.at(1)
      assert vincent.display_state == "default"
    end

    # TODO
    # test "should deduct 7 coins from Jany" do
    #
    # end
  end

  # describe "action coup, insufficient coins"
end
