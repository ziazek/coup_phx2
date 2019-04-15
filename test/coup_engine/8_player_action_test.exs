defmodule CoupEngine.PlayerActionTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Game, Player, Action}

  describe "when player has < 10 coins" do
    setup do
      state =
        initial_state(%{
          state: "cards_drawn",
          players: [
            %Player{name: "TH", actions_panel_mode: "actions", coins: 8},
            %Player{name: "Naz"}
          ]
        })

      {:noreply, updated_state, _continue} = Game.handle_info({:start_turn, 0}, state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should show all possible actions", %{updated_state: updated_state} do
      player = updated_state.players |> Enum.at(0)

      assert player.actions == [
               %Action{
                 action: "coup",
                 label: "Coup",
                 state: "enabled"
               },
               %Action{
                 action: "1coin",
                 label: "1 coin",
                 state: "enabled"
               },
               %Action{
                 action: "foreignaid",
                 label: "Foreign Aid",
                 state: "enabled"
               },
               %Action{
                 action: "3coins",
                 label: "3 coins",
                 state: "enabled"
               },
               %Action{
                 action: "steal",
                 label: "Steal",
                 state: "enabled"
               },
               %Action{
                 action: "assassinate",
                 label: "Assassinate",
                 state: "enabled"
               },
               %Action{
                 action: "changecard",
                 label: "Change card",
                 state: "enabled"
               }
             ]
    end
  end
end
