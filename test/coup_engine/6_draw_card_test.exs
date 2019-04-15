defmodule CoupEngine.DrawCardTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Game, Card, Player}

  describe "draw_card, player_index" do
    setup do
      state =
        initial_state(%{
          state: "deck_shuffled",
          deck: [
            %Card{type: "Duke", state: "default"},
            %Card{type: "Captain", state: "default"},
            %Card{type: "Ambassador", state: "default"},
            %Card{type: "Captain", state: "default"},
            %Card{type: "Captain", state: "default"},
            %Card{type: "Duke", state: "default"},
            %Card{type: "Duke", state: "default"},
            %Card{type: "Ambassador", state: "default"},
            %Card{type: "Ambassador", state: "default"},
            %Card{type: "Assassin", state: "default"},
            %Card{type: "Assassin", state: "default"},
            %Card{type: "Assassin", state: "default"},
            %Card{type: "Contessa", state: "default"},
            %Card{type: "Contessa", state: "default"},
            %Card{type: "Contessa", state: "default"}
          ],
          players: [
            %Player{name: "TH", hand: []},
            %Player{name: "Naz", hand: []}
          ]
        })

      {:noreply, updated_state, _continue} = Game.handle_info({:draw_card, 0}, state)

      {:ok, %{state: state, updated_state: updated_state}}
    end

    test "should add top card to the hand of player at index 0", %{updated_state: updated_state} do
      first_card_in_deck = updated_state.deck |> Enum.at(0)
      assert first_card_in_deck.type == "Captain"
      assert length(updated_state.deck) == 14

      first_player = updated_state.players |> Enum.at(0)
      assert first_player.hand |> Enum.at(0) |> Map.get(:type) == "Duke"
    end

    test "should update toast to 'TH drew a card.'", %{updated_state: updated_state} do
      latest_toast = updated_state.toast |> Enum.at(-1)
      assert latest_toast.body == "TH drew a card."
    end

    test "should send draw_card to self after 1000ms" do
      assert_receive {{:draw_card, 1}, 1000}
    end
  end

  describe "draw_card, last player" do
    setup do
      state =
        initial_state(%{
          state: "deck_shuffled",
          deck: [
            %Card{type: "Captain", state: "default"},
            %Card{type: "Captain", state: "default"},
            %Card{type: "Duke", state: "default"},
            %Card{type: "Duke", state: "default"},
            %Card{type: "Ambassador", state: "default"},
            %Card{type: "Ambassador", state: "default"},
            %Card{type: "Assassin", state: "default"},
            %Card{type: "Assassin", state: "default"},
            %Card{type: "Assassin", state: "default"},
            %Card{type: "Contessa", state: "default"},
            %Card{type: "Contessa", state: "default"},
            %Card{type: "Contessa", state: "default"}
          ],
          players: [
            %Player{
              name: "TH",
              hand: [
                %Card{type: "Duke", state: "default"},
                %Card{type: "Captain", state: "default"}
              ]
            },
            %Player{
              name: "Naz",
              hand: [
                %Card{type: "Ambassador", state: "default"}
              ]
            }
          ]
        })

      {:noreply, updated_state, _continue} = Game.handle_info({:draw_card, 1}, state)

      {:ok, %{state: state, updated_state: updated_state}}
    end

    test "should update state to cards_drawn", %{updated_state: updated_state} do
      assert updated_state.state == "cards_drawn"
    end

    test "should update toast to 'All players have drawn their cards.'", %{
      updated_state: updated_state
    } do
      latest_toast = updated_state.toast |> Enum.at(-1)
      assert latest_toast.body == "All players have drawn their cards."
    end

    test "should not send draw_card to self" do
      refute_receive {{:draw_card, 0}, 1000}
    end

    test "should send start_turn to self" do
      assert_receive {{:start_turn, 0}, 1000}
    end
  end
end
