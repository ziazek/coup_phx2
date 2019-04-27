defmodule CoupEngine.StartTurnTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Game, Player, Turn}

  describe "start_turn" do
    setup do
      state =
        initial_state(%{
          state: "cards_drawn",
          players: [
            %Player{name: "TH"},
            %Player{name: "Naz"}
          ]
        })

      {:noreply, updated_state, _continue} = Game.handle_info({:start_turn, 0}, state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should set game_state to player_action", %{
      updated_state: updated_state
    } do
      assert updated_state.state == "player_action"
    end

    test "should initialize turn", %{updated_state: updated_state} do
      %Turn{
        player: %Player{
          name: "TH",
          actions_panel_mode: actions_panel_mode,
          state: "ok",
          actions: actions
        },
        action: %{state: "pending"},
        player_response_to_block: %{state: "pending"},
        target: %{state: "pending"},
        target_response: %{state: "pending"}
      } = updated_state.turn

      assert actions_panel_mode == "actions"
      assert length(actions) > 0
    end

    test "should set acting player actions_panel_mode to actions", %{updated_state: updated_state} do
      player = updated_state.players |> Enum.at(0)
      assert player.actions_panel_mode == "actions"
    end

    test "should update toast to `It's TH's turn`", %{updated_state: updated_state} do
      latest_toast = updated_state.toast |> Enum.at(-1)
      assert latest_toast.body == "It's TH's turn."
    end

    test "should set opponents actions_panel_mode to responses", %{
      updated_state: updated_state
    } do
      player = updated_state.players |> Enum.at(1)
      assert player.actions_panel_mode == "responses"
    end
  end
end
