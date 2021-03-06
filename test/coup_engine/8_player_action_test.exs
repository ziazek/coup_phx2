defmodule CoupEngine.PlayerActionTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Action, Game, Player}

  describe "turn opponent_responses, no dead player" do
    setup do
      state =
        initial_state(%{
          state: "cards_drawn",
          players: [
            %Player{name: "TH", session_id: "sess1", state: "alive"},
            %Player{name: "Ken", session_id: "sess2", state: "alive"},
            %Player{name: "Naz", session_id: "sess3", state: "alive"}
          ]
        })

      {:noreply, updated_state, _continue} = Game.handle_info({:start_turn, 0}, state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should be initialized to all opponents' session_ids, pending", %{
      updated_state: updated_state
    } do
      assert updated_state.turn.opponent_responses == %{
               "sess2" => "pending",
               "sess3" => "pending"
             }
    end
  end

  describe "turn opponent_responses, 1 dead player" do
    setup do
      state =
        initial_state(%{
          state: "cards_drawn",
          players: [
            %Player{name: "TH", session_id: "sess1", state: "alive"},
            %Player{name: "Ken", session_id: "sess2", state: "alive"},
            %Player{name: "Naz", session_id: "sess3", state: "dead"}
          ]
        })

      {:noreply, updated_state, _continue} = Game.handle_info({:start_turn, 0}, state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should be initialized to only Ken's session_ids, pending", %{
      updated_state: updated_state
    } do
      assert updated_state.turn.opponent_responses == %{
               "sess2" => "pending"
             }
    end
  end

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
                 label: "Change Card",
                 state: "enabled"
               }
             ]
    end
  end

  describe "when player has >= 10 coins" do
    setup do
      state =
        initial_state(%{
          state: "cards_drawn",
          players: [
            %Player{name: "TH", actions_panel_mode: "actions", coins: 10},
            %Player{name: "Naz"}
          ]
        })

      {:noreply, updated_state, _continue} = Game.handle_info({:start_turn, 0}, state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should only see Coup enabled", %{updated_state: updated_state} do
      player = updated_state.players |> Enum.at(0)
      enabled_actions = player.actions |> Enum.filter(fn(action) -> action.state == "enabled" end)
      assert enabled_actions == [
        %Action{
          action: "coup",
          label: "Coup",
          state: "enabled"
        }
      ]
    end
  end

  describe "when player has < 3 coins" do
    setup do
      state =
        initial_state(%{
          state: "cards_drawn",
          players: [
            %Player{name: "TH", actions_panel_mode: "actions", coins: 2},
            %Player{name: "Naz"}
          ]
        })

      {:noreply, updated_state, _continue} = Game.handle_info({:start_turn, 0}, state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should see all enabled except coup and assassinate", %{updated_state: updated_state} do
      player = updated_state.players |> Enum.at(0)
      enabled_actions =
        player.actions
        |> Enum.filter(fn(action) -> action.state == "enabled" end)
        |> Enum.map(fn(action) -> action.action end)
      assert enabled_actions == [
        "1coin", "foreignaid", "3coins", "steal", "changecard"
      ]
    end

  end
end
