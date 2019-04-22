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
            %Player{name: "Zek", session_id: "session_id2"},
            %Player{name: "Naz", session_id: "session_id3"}
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
        Game.handle_call({:block, "block_as_duke", "session_id2"}, "_pid", state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should set turn target to Zek, target_response state to block_as_duke", %{
      updated_state: updated_state
    } do
      assert updated_state.turn.target == %Player{
               name: "Zek",
               session_id: "session_id2",
               state: "block_as_duke"
             }

      assert updated_state.turn.target_response == %Action{
               action: "block_as_duke",
               label: "Block as Duke",
               state: "ok"
             }
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
                 label: "Allow",
                 state: "enabled"
               }
             ]
    end

    test "should update Zek and Naz display_state to awaiting_response_to_block", %{
      updated_state: updated_state
    } do
      zek = updated_state.players |> Enum.at(1)
      naz = updated_state.players |> Enum.at(2)

      assert zek.display_state == "awaiting_response_to_block"
      assert naz.display_state == "awaiting_response_to_block"
    end

    test "should update Ken display_state to response_to_block", %{
      updated_state: updated_state
    } do
      ken = updated_state.players |> Enum.at(0)

      assert ken.display_state == "response_to_block"
    end
  end
end
