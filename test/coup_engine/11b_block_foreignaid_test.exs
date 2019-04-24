defmodule CoupEngine.BlockForeignaidTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Action, Game, Player, Turn}

  describe "block foreignaid" do
    setup do
      state =
        initial_state(%{
          state: "awaiting_opponent_response",
          players: [
            %Player{name: "Ken", session_id: "session_id1"},
            %Player{name: "Zek", session_id: "session_id2", actions_panel_mode: "responses"},
            %Player{name: "Naz", session_id: "session_id3", actions_panel_mode: "responses"}
          ],
          turn: %Turn{
            player: %Player{name: "Ken", session_id: "session_id1"},
            action: %Action{
              action: "foreignaid",
              label: "Foreign Aid",
              state: "ok"
            }
          }
        })

      {:reply, :ok, updated_state, _continue} =
        Game.handle_call({:block, "session_id2", "block_as_duke"}, "_pid", state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should set turn target to Zek, target_response state to block_as_duke", %{
      updated_state: updated_state
    } do
      assert updated_state.turn.target == %Player{
               name: "Zek",
               session_id: "session_id2",
               state: "block_as_duke",
               actions_panel_mode: "responses"
             }

      assert updated_state.turn.target_response == %Action{
               action: "block_as_duke",
               label: "Block as Duke",
               state: "ok"
             }
    end

    test "should set blocker_claimed_character to Duke", %{updated_state: updated_state} do
      assert updated_state.turn.blocker_claimed_character == "Duke"
    end

    test "should update toast to 'Zek blocks. (Claims DUKE)'", %{updated_state: updated_state} do
      latest_toast = updated_state.toast |> Enum.at(-1)
      assert latest_toast.body == "Zek blocks. (Claims DUKE)"
    end

    test "should set game state to awaiting_response_to_block", %{updated_state: updated_state} do
      assert updated_state.state == "awaiting_response_to_block"
    end

    test "should update Ken available response to Allow and Challenge", %{
      updated_state: updated_state
    } do
      ken = updated_state.players |> Enum.at(0)

      assert ken.responses == [
               %Action{
                 action: "allow",
                 label: "Allow",
                 state: "enabled"
               },
               %Action{
                 action: "challenge",
                 label: "Challenge",
                 state: "enabled"
               }
             ]
    end

    test "should update Zek and Naz actions_panel_mode to actions_disabled", %{
      updated_state: updated_state
    } do
      zek = updated_state.players |> Enum.at(1)
      naz = updated_state.players |> Enum.at(2)

      assert zek.actions_panel_mode == "actions_disabled"
      assert naz.actions_panel_mode == "actions_disabled"
    end

    test "should update Zek and Naz display_state to awaiting_response_to_block", %{
      updated_state: updated_state
    } do
      zek = updated_state.players |> Enum.at(1)
      naz = updated_state.players |> Enum.at(2)

      assert zek.display_state == "awaiting_response_to_block"
      assert naz.display_state == "awaiting_response_to_block"
    end

    test "should update Ken actions_panel_mode to responses", %{
      updated_state: updated_state
    } do
      ken = updated_state.players |> Enum.at(0)

      assert ken.actions_panel_mode == "responses"
    end

    test "should update Ken display_state to responding_to_block", %{
      updated_state: updated_state
    } do
      ken = updated_state.players |> Enum.at(0)

      assert ken.display_state == "responding_to_block"
    end
  end
end
