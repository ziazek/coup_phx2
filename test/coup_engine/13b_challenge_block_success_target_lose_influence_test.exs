defmodule CoupEngine.ChallengeBlockSuccessTargetLoseInfluenceTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Card, Game, Player, Turn}

  describe "challenge_block_success_target_lose_influence, player has one card" do
    setup do
      state =
        initial_state(%{
          state: "challenge_block_success_target_lose_influence",
          players: [
            %Player{name: "Jany", session_id: "session_id1", coins: 0},
            %Player{
              name: "Vincent",
              session_id: "session_id2",
              coins: 0,
              hand: [%Card{type: "Captain", state: "default"}, %Card{type: "Duke", state: "dead"}]
            }
          ],
          turn: %Turn{
            player: %Player{name: "Jany", session_id: "session_id1"},
            action: %{action: "coup", state: "ok"},
            target: %Player{
              name: "Vincent",
              session_id: "session_id2",
              hand: [%Card{type: "Captain", state: "default"}, %Card{type: "Duke", state: "dead"}]
            },
            state: "active"
          }
        })

      {:noreply, updated_state, _continue} = Game.handle_info(:lose_influence, state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should change player state to dead", %{updated_state: updated_state} do
      vincent = updated_state.players |> Enum.at(1)
      assert vincent.state == "dead"
    end

    test "should change player card state to dead", %{updated_state: updated_state} do
      vincent = updated_state.players |> Enum.at(1)
      captain_card = vincent.hand |> Enum.at(0)
      assert captain_card.state == "dead"
    end

    test "should change game state to action_success", %{updated_state: updated_state} do
      assert updated_state.state == "action_success"
    end

    test "should update toast to 'Vincent loses 1 influence. Player has died.'", %{
      updated_state: updated_state
    } do
      latest_toast = updated_state.toast |> Enum.at(-1)
      assert latest_toast.body == "Vincent loses 1 influence. Player has died."
    end

    test "should send action_success to self" do
      assert_receive {:action_success, 1000}
    end
  end

  describe "challenge_block_success_target_lose_influence, player has 2 cards" do
    setup do
      state =
        initial_state(%{
          state: "challenge_block_success_target_lose_influence",
          players: [
            %Player{name: "Jany", session_id: "session_id1", coins: 0},
            %Player{
              name: "Vincent",
              session_id: "session_id2",
              coins: 0,
              hand: [
                %Card{type: "Captain", state: "default"},
                %Card{type: "Duke", state: "default"}
              ]
            }
          ],
          turn: %Turn{
            player: %Player{name: "Jany", session_id: "session_id1"},
            action: %{action: "coup", state: "ok"},
            target: %Player{
              name: "Vincent",
              session_id: "session_id2",
              hand: [
                %Card{type: "Captain", state: "default"},
                %Card{type: "Duke", state: "default"}
              ]
            },
            state: "active"
          }
        })

      {:noreply, updated_state, _continue} = Game.handle_info(:lose_influence, state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should change game state to challenge_block_success_target_lose_influence_select_card",
         %{
           updated_state: updated_state
         } do
      assert updated_state.state == "challenge_block_success_target_lose_influence_select_card"
    end

    test "should update player display_state to lose_influence_select_card", %{
      updated_state: updated_state
    } do
      vincent = updated_state.players |> Enum.at(1)
      assert vincent.display_state == "lose_influence_select_card"
    end

    test "should update toast to 'Vincent loses 1 influence. Choosing card to discard...'", %{
      updated_state: updated_state
    } do
      latest_toast = updated_state.toast |> Enum.at(-1)
      assert latest_toast.body == "Vincent loses 1 influence. Choosing card to discard..."
    end
  end
end
