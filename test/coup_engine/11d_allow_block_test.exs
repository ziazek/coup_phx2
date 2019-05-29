defmodule CoupEngine.AllowBlockTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Action, Game, Player, Turn}

  describe "allow block" do
    setup do
      state =
        initial_state(%{
          state: "awaiting_response_to_block",
          players: [
            %Player{name: "Ken", session_id: "session_id1"},
            %Player{name: "Naz", session_id: "session_id2"}
          ],
          turn: %Turn{
            player: %Player{name: "Ken", session_id: "session_id1"},
            action: %Action{
              action: "foreignaid",
              label: "Foreign Aid",
              state: "ok"
            },
            target: %Player{name: "Naz", session_id: "session_id2", state: "block_as_duke"},
            target_response: %Action{
              action: "block_as_duke",
              label: "Block as Duke",
              state: "ok"
            }
          }
        })

      {:reply, :ok, updated_state, _continue} = Game.handle_call(:allow_block, "_pid", state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should update game state to turn_ending", %{updated_state: updated_state} do
      assert updated_state.state == "turn_ending"
    end

    test "should update turn player_response_to_block to allow", %{updated_state: updated_state} do
      assert updated_state.turn.player_response_to_block == %Action{
               action: "allow",
               label: "Allow",
               state: "ok"
             }
    end

    test "should update toast to 'Ken allows the block.'", %{updated_state: updated_state} do
      latest_toast = updated_state.toast |> Enum.at(-1)
      assert latest_toast.body == "Ken allows the block."
    end

    test "should mark turn as ended", %{updated_state: updated_state} do
      assert updated_state.turn.state == "ended"
    end

    test "should send end_turn to self" do
      assert_receive {:end_turn, 1000}
    end
  end
end
