defmodule CoupEngine.ChallengeBlockTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Action, Card, Game, Player, Turn}

  describe "challenge block success" do
    setup do
      state =
        initial_state(%{
          state: "awaiting_response_to_block",
          players: [
            %Player{name: "Ken", session_id: "session_id1"},
            %Player{
              name: "Naz",
              session_id: "session_id2",
              hand: [%Card{type: "Captain", state: "default"}, %Card{type: "Duke", state: "dead"}]
            }
          ],
          turn: %Turn{
            player: %Player{name: "Ken", session_id: "session_id1"},
            action: %Action{
              action: "foreignaid",
              label: "Foreign Aid",
              state: "ok"
            },
            blocker_claimed_character: "Duke",
            target: %Player{name: "Naz", session_id: "session_id2", state: "block_as_duke"},
            target_response: %Action{
              action: "block_as_duke",
              label: "Block as Duke",
              state: "ok"
            }
          }
        })

      {:reply, :ok, updated_state, _continue} = Game.handle_call(:challenge_block, "_pid", state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should update game state to target_lose_influence", %{updated_state: updated_state} do
      assert updated_state.state == "target_lose_influence"
    end

    test "should update turn player_response_to_block to challenge_block", %{
      updated_state: updated_state
    } do
      assert updated_state.turn.player_response_to_block == %Action{
               action: "challenge_block",
               label: "Challenge",
               state: "ok"
             }
    end

    #
    # test "should update toast to 'Naz allows the block.'", %{updated_state: updated_state} do
    #   latest_toast = updated_state.toast |> Enum.at(-1)
    #   assert latest_toast.body == "Naz allows the block."
    # end
    #
    # test "should mark turn as ended", %{updated_state: updated_state} do
    #   assert updated_state.turn.state == "ended"
    # end
    #
    # test "should send end_turn to self" do
    #   assert_receive {:end_turn, 1000}
    # end
  end

  # describe "challenge block fail" do
  #   # player lose card
  # end
end
