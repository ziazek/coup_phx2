defmodule CoupEngine.ChangeCardConfirmTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Card, Game, Player, Turn}

  describe "change_card_confirm" do
    setup do
      state =
        initial_state(%{
          state: "change_card_cards_selected",
          players: [
            %Player{
              name: "Jany",
              session_id: "session_id1",
              coins: 0,
              hand: [
                %Card{type: "Duke", state: "default"},
                %Card{type: "Captain", state: "default"}
              ],
              change_card_hand: [
                %Card{type: "Duke", state: "default"},
                %Card{type: "Captain", state: "default"},
                %Card{type: "Contessa", state: "selected"},
                %Card{type: "Assassin", state: "selected"}
              ]
            }
          ],
          turn: %Turn{
            player: %Player{name: "Jany", session_id: "session_id1"},
            action: %{action: "changecard", state: "ok"},
            state: "active"
          }
        })

      {:reply, :ok, updated_state, _continue} = Game.handle_call(:change_card_confirm, "_pid", state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should change game state to turn_ending", %{updated_state: updated_state} do
      assert updated_state.state == "turn_ending"
    end

    test "should mark turn as ended", %{updated_state: updated_state} do
      assert updated_state.turn.state == "ended"
    end

    test "should send end_turn to self" do
      assert_receive {:end_turn, 1000}
    end

    test "should empty change_card_hand", %{updated_state: updated_state} do
      change_card_hand =
        updated_state.players
        |> Enum.at(0)
        |> Map.get(:change_card_hand)

      assert change_card_hand == []
    end

    test "should set player hand to Contessa and Assassin", %{updated_state: updated_state} do
      hand = updated_state.players |> Enum.at(0) |> Map.get(:hand)
      assert hand == [
        %Card{type: "Contessa", state: "default"},
        %Card{type: "Assassin", state: "default"}
      ]
    end
  end
end
