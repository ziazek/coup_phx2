defmodule CoupEngine.CheckRevealedCardTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Card, Game, Player, Turn}

  # check revealed card - prep_next_turn, or
  # return revealed card
  # shuffle deck
  # draw replacement card

  describe "revealed card exists" do
    setup do
      state =
        initial_state(%{
          state: "checking_revealed_card",
          players: [
            %Player{
              name: "Jany",
              session_id: "session_id1",
              coins: 0,
              state: "alive",
              hand: [
                %Card{type: "Captain", state: "default"},
                %Card{type: "Assassin", state: "revealed"}
              ]
            },
            %Player{name: "Naz", session_id: "session_id2", coins: 0, state: "alive"}
          ],
          turn: %Turn{
            player: %Player{name: "Jany", session_id: "session_id1"},
            action: %{action: "assassinate", state: "ok"},
            state: "active"
          }
        })

      {:noreply, updated_state, _continue} = Game.handle_info(:check_revealed_card, state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should update game state to return_revealed_card", %{updated_state: updated_state} do
      assert updated_state.state == "return_revealed_card"
    end

    test "should update toast to 'Returning the revealed card and shuffling it into the deck...'",
         %{
           updated_state: updated_state
         } do
      latest_toast = updated_state.toast |> Enum.at(-1)
      assert latest_toast.body == "Returning the revealed card and shuffling it into the deck..."
    end

    test "should send return_revealed_card to self" do
      assert_received {:return_revealed_card, 10}
    end
  end

  describe "revealed card doesn't exist" do
    setup do
      state =
        initial_state(%{
          state: "checking_revealed_card",
          players: [
            %Player{
              name: "Jany",
              session_id: "session_id1",
              coins: 0,
              state: "alive",
              hand: [
                %Card{type: "Captain", state: "default"},
                %Card{type: "Assassin", state: "default"}
              ]
            },
            %Player{name: "Naz", session_id: "session_id2", coins: 0, state: "alive"}
          ],
          turn: %Turn{
            player: %Player{name: "Jany", session_id: "session_id1"},
            action: %{action: "assassinate", state: "ok"},
            state: "active"
          }
        })

      {:noreply, updated_state, _continue} = Game.handle_info(:check_revealed_card, state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should update game state to turn_ended", %{updated_state: updated_state} do
      assert updated_state.state == "turn_ended"
    end

    test "should send prep_next_turn to self" do
      assert_receive {:prep_next_turn, 200}
    end
  end
end
