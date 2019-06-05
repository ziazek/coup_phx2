defmodule CoupEngine.ReturnRevealedCardTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Card, Game, Player, Turn}

  describe "return revealed card" do
    setup do
      state =
        initial_state(%{
          state: "return_revealed_card",
          deck: [
            %Card{type: "Contessa", state: "default"},
            %Card{type: "Contessa", state: "default"},
            %Card{type: "Contessa", state: "default"},
            %Card{type: "Duke", state: "default"},
            %Card{type: "Duke", state: "default"},
            %Card{type: "Duke", state: "default"},
            %Card{type: "Captain", state: "default"},
            %Card{type: "Captain", state: "default"},
            %Card{type: "Ambassador", state: "default"},
            %Card{type: "Ambassador", state: "default"},
            %Card{type: "Ambassador", state: "default"}
          ],
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

      {:noreply, updated_state, _continue} = Game.handle_info(:return_revealed_card, state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should update game state to draw_revealed_replacement_card", %{
      updated_state: updated_state
    } do
      assert updated_state.state == "draw_revealed_replacement_card"
    end

    test "should update Assassin type to blank, state to replacing", %{
      updated_state: updated_state
    } do
      card =
        updated_state.players
        |> Enum.at(0)
        |> Map.get(:hand)
        |> Enum.at(1)

      assert card.type == ""
      assert card.state == "replacing"
    end

    test "should add Assassin to the deck", %{updated_state: updated_state} do
      assert Enum.member?(updated_state.deck, %Card{type: "Assassin", state: "default"})
    end

    test "should shuffle deck", %{updated_state: updated_state} do
      refute updated_state.deck == [
               %Card{type: "Contessa", state: "default"},
               %Card{type: "Contessa", state: "default"},
               %Card{type: "Contessa", state: "default"},
               %Card{type: "Duke", state: "default"},
               %Card{type: "Duke", state: "default"},
               %Card{type: "Duke", state: "default"},
               %Card{type: "Captain", state: "default"},
               %Card{type: "Captain", state: "default"},
               %Card{type: "Ambassador", state: "default"},
               %Card{type: "Ambassador", state: "default"},
               %Card{type: "Ambassador", state: "default"},
               %Card{type: "Assassin", state: "default"}
             ]
    end

    test "should send draw_revealed_replacement_card to self" do
      assert_received {:draw_revealed_replacement_card, 1000}
    end
  end

  describe "return revealed card, 1 card dead" do
    setup do
      state =
        initial_state(%{
          state: "return_revealed_card",
          deck: [
            %Card{type: "Contessa", state: "default"},
            %Card{type: "Contessa", state: "default"},
            %Card{type: "Contessa", state: "default"},
            %Card{type: "Duke", state: "default"},
            %Card{type: "Duke", state: "default"},
            %Card{type: "Duke", state: "default"},
            %Card{type: "Captain", state: "default"},
            %Card{type: "Captain", state: "default"},
            %Card{type: "Ambassador", state: "default"},
            %Card{type: "Ambassador", state: "default"},
            %Card{type: "Ambassador", state: "default"}
          ],
          players: [
            %Player{
              name: "Jany",
              session_id: "session_id1",
              coins: 0,
              state: "alive",
              hand: [
                %Card{type: "Captain", state: "dead"},
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

      {:noreply, updated_state, _continue} = Game.handle_info(:return_revealed_card, state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should update Assassin type to blank, state to replacing", %{
      updated_state: updated_state
    } do
      card =
        updated_state.players
        |> Enum.at(0)
        |> Map.get(:hand)
        |> Enum.at(1)

      assert card.type == ""
      assert card.state == "replacing"
    end

    test "should not update dead Captain", %{
      updated_state: updated_state
    } do
      captain =
        updated_state.players
        |> Enum.at(0)
        |> Map.get(:hand)
        |> Enum.at(0)

      assert captain.type == "Captain"
      assert captain.state == "dead"
    end

    test "should add Assassin to the deck", %{updated_state: updated_state} do
      assert Enum.member?(updated_state.deck, %Card{type: "Assassin", state: "default"})
    end

    test "should not add Captain to the deck", %{updated_state: updated_state} do
      captains = updated_state.deck |> Enum.filter(fn card -> card.type == "Captain" end)
      assert length(captains) == 2
    end
  end
end
