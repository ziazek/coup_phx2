defmodule CoupEngine.ChangeCardDrawCardTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Card, Game, Player, Turn}

  describe "change_card_draw_card, 2 live cards" do
    setup do
      state =
        initial_state(%{
          state: "change_card_draw_card",
          deck: [
            %Card{type: "Ambassador", state: "default"},
            %Card{type: "Assassin", state: "default"},
            %Card{type: "Contessa", state: "default"}
          ],
          players: [
            %Player{
              name: "Jany",
              session_id: "session_id1",
              coins: 0,
              hand: [
                %Card{type: "Duke", state: "default"},
                %Card{type: "Captain", state: "default"}
              ],
              change_card_hand: []
            }
          ],
          turn: %Turn{
            player: %Player{name: "Jany", session_id: "session_id1"},
            action: %{action: "changecard", state: "ok"},
            state: "active"
          }
        })

      {:noreply, updated_state, _continue} = Game.handle_info(:change_card_draw_card, state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should change game state to change_card_cards_drawn", %{updated_state: updated_state} do
      assert updated_state.state == "change_card_cards_drawn"
    end

    test "should change Jany's display_state to change_card", %{updated_state: updated_state} do
      jany = updated_state.players |> Enum.at(0)
      assert jany.display_state == "change_card"
    end

    test "should populate change_card_hand with 4 cards", %{updated_state: updated_state} do
      change_card_hand =
        updated_state.players
        |> Enum.at(0)
        |> Map.get(:change_card_hand)

      assert length(change_card_hand) == 4
      card1 = change_card_hand |> Enum.at(0)
      card2 = change_card_hand |> Enum.at(1)
      card3 = change_card_hand |> Enum.at(2)
      card4 = change_card_hand |> Enum.at(3)
      assert card1.type == "Duke"
      assert card2.type == "Captain"
      assert card3.type == "Ambassador"
      assert card4.type == "Assassin"
    end

    test "should remove top 2 cards from the deck", %{updated_state: updated_state} do
      assert updated_state.deck == [
               %Card{type: "Contessa", state: "default"}
             ]
    end
  end

  describe "change_card_draw_card, 1 live card" do
    setup do
      state =
        initial_state(%{
          state: "change_card_draw_card",
          deck: [
            %Card{type: "Ambassador", state: "default"},
            %Card{type: "Assassin", state: "default"},
            %Card{type: "Contessa", state: "default"}
          ],
          players: [
            %Player{
              name: "Jany",
              session_id: "session_id1",
              coins: 0,
              hand: [
                %Card{type: "Duke", state: "default"},
                %Card{type: "Captain", state: "dead"}
              ],
              change_card_hand: []
            }
          ],
          turn: %Turn{
            player: %Player{name: "Jany", session_id: "session_id1"},
            action: %{action: "changecard", state: "ok"},
            state: "active"
          }
        })

      {:noreply, updated_state, _continue} = Game.handle_info(:change_card_draw_card, state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should populate change_card_hand with 3 cards", %{updated_state: updated_state} do
      change_card_hand =
        updated_state.players
        |> Enum.at(0)
        |> Map.get(:change_card_hand)

      assert length(change_card_hand) == 3
      card1 = change_card_hand |> Enum.at(0)
      card2 = change_card_hand |> Enum.at(1)
      card3 = change_card_hand |> Enum.at(2)
      assert card1.type == "Duke"
      assert card2.type == "Ambassador"
      assert card3.type == "Assassin"
    end
  end
end
