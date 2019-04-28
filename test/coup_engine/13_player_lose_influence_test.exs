defmodule CoupEngine.PlayerLoseInfluenceTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Card, Game, Player, Turn}

  describe "lose_influence, player has one card" do
    setup do
      state =
        initial_state(%{
          state: "player_lose_influence",
          players: [
            %Player{
              name: "Jany",
              session_id: "session_id1",
              coins: 0,
              hand: [
                %Card{type: "Captain", state: "default"},
                %Card{type: "Duke", state: "dead"}
              ]
            },
            %Player{
              name: "Vincent",
              session_id: "session_id2",
              coins: 0
            }
          ],
          turn: %Turn{
            player: %Player{
              name: "Jany",
              session_id: "session_id1",
              hand: [
                %Card{type: "Captain", state: "default"},
                %Card{type: "Duke", state: "dead"}
              ]
            },
            action: %{action: "1coin", state: "ok"},
            target: %Player{
              name: "Vincent",
              session_id: "session_id2"
            },
            state: "active"
          }
        })

      {:noreply, updated_state, _continue} = Game.handle_info(:lose_influence, state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should change player state to dead", %{updated_state: updated_state} do
      jany = updated_state.players |> Enum.at(0)
      assert jany.state == "dead"
    end

    test "should change player card state to dead", %{updated_state: updated_state} do
      jany = updated_state.players |> Enum.at(0)
      captain_card = jany.hand |> Enum.at(0)
      assert captain_card.state == "dead"
    end

    test "should change game state to turn_ending", %{updated_state: updated_state} do
      assert updated_state.state == "turn_ending"
    end

    test "should update toast to 'Jany loses 1 influence. Player has died.'", %{
      updated_state: updated_state
    } do
      latest_toast = updated_state.toast |> Enum.at(-1)
      assert latest_toast.body == "Jany loses 1 influence. Player has died."
    end

    test "should send end_turn to self" do
      assert_receive {:end_turn, 1000}
    end
  end

  describe "lose_influence, player has 2 cards" do
    setup do
      state =
        initial_state(%{
          state: "player_lose_influence",
          players: [
            %Player{
              name: "Jany",
              session_id: "session_id1",
              coins: 0,
              hand: [
                %Card{type: "Captain", state: "default"},
                %Card{type: "Duke", state: "default"}
              ]
            },
            %Player{
              name: "Vincent",
              session_id: "session_id2",
              coins: 0
            }
          ],
          turn: %Turn{
            player: %Player{
              name: "Jany",
              session_id: "session_id1",
              hand: [
                %Card{type: "Captain", state: "default"},
                %Card{type: "Duke", state: "default"}
              ]
            },
            action: %{action: "1coin", state: "ok"},
            target: %Player{
              name: "Vincent",
              session_id: "session_id2"
            },
            state: "active"
          }
        })

      {:noreply, updated_state, _continue} = Game.handle_info(:lose_influence, state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should change game state to lose_influence_select_card", %{updated_state: updated_state} do
      assert updated_state.state == "lose_influence_select_card"
    end

    test "should update player display_state to lose_influence_select_card", %{
      updated_state: updated_state
    } do
      jany = updated_state.players |> Enum.at(0)
      assert jany.display_state == "lose_influence_select_card"
    end

    test "should update toast to 'Jany loses 1 influence. Choosing card to discard...'", %{
      updated_state: updated_state
    } do
      latest_toast = updated_state.toast |> Enum.at(-1)
      assert latest_toast.body == "Jany loses 1 influence. Choosing card to discard..."
    end
  end
end
