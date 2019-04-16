defmodule CoupEngine.AttemptActionTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Action, Game, Player, Turn}

  describe "action 1coin" do
    setup do
      state =
        initial_state(%{
          state: "player_action",
          turn: %Turn{
            player: %Player{name: "Jany"},
            action: %{state: "pending"}
          }
        })

      {:reply, :ok, updated_state, _continue} =
        Game.handle_call({:action, "1coin"}, "_pid", state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should set turn action", %{updated_state: updated_state} do
      assert updated_state.turn.action == %Action{
               action: "1coin",
               label: "1 coin",
               state: "ok"
             }
    end

    test "should update toast to 'Jany took one coin.'", %{updated_state: updated_state} do
      latest_toast = updated_state.toast |> Enum.at(-1)
      assert latest_toast.body == "Jany took one coin."
    end

    test "should set game state to action_success", %{updated_state: updated_state} do
      assert updated_state.state == "action_success"
    end
  end
end
