defmodule CoupEngine.Game2StartTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Game, Player, Rules}

  describe "shuffle" do
    test "should change the order of the deck" do
      state =
        initial_state(%{
          rules: %Rules{state: :game_started},
          deck: [
            %{type: "Captain"},
            %{type: "Captain"},
            %{type: "Ambassador"},
            %{type: "Ambassador"},
            %{type: "Duke"},
            %{type: "Duke"},
            %{type: "Assassin"},
            %{type: "Assassin"},
            %{type: "Contessa"},
            %{type: "Contessa"}
          ]
        })

      {:noreply, resulting_state} = Game.handle_info(:shuffle, state)

      assert resulting_state.deck != state.deck
      assert resulting_state.rules.state == :deck_shuffled
    end
  end

  describe ":draw_card, player_index" do
    test "should add top card to player's hand" do
      state =
        initial_state(%{
          rules: %Rules{state: :deck_shuffled},
          deck: [
            %{type: "Captain"},
            %{type: "Ambassador"}
          ],
          players: [
            %Player{
              role: "creator",
              name: "Player 1",
              session_id: "session_id1",
              hand: []
            },
            %Player{
              role: "player",
              name: "Player 2",
              session_id: "session_id2",
              hand: []
            }
          ]
        })

      {:noreply, resulting_state} = Game.handle_info({:draw_card, 0}, state)

      first_card_in_deck = resulting_state.deck |> Enum.at(0)
      assert first_card_in_deck.type == "Ambassador"
      first_player = resulting_state.players |> Enum.at(0)
      assert Enum.at(first_player.hand, 0).type == "Captain"
    end

    test "should set game state to 'cards_drawn' when all players have 2 cards" do
      state =
        initial_state(%{
          rules: %Rules{state: :deck_shuffled},
          deck: [
            %{type: "Captain"},
            %{type: "Ambassador"}
          ],
          players: [
            %Player{
              role: "creator",
              name: "Player 1",
              session_id: "session_id1",
              hand: [
                %{type: "Captain"},
                %{type: "Captain"}
              ]
            },
            %Player{
              role: "player",
              name: "Player 2",
              session_id: "session_id2",
              hand: [%{type: "Ambassador"}]
            }
          ]
        })

      {:noreply, resulting_state} = Game.handle_info({:draw_card, 1}, state)

      assert resulting_state.rules.state == :cards_drawn
    end
  end
end
