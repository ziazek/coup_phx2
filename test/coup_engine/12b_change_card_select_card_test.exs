defmodule CoupEngine.ChangeCardSelectCardTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Card, Game, Player, Turn}

  describe "change_card_select_card, given 0 cards selected, 2 cards required" do
    setup do
      state =
        initial_state(%{
          state: "change_card_cards_drawn",
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
                %Card{type: "Contessa", state: "default"}
              ]
            }
          ],
          turn: %Turn{
            player: %Player{name: "Jany", session_id: "session_id1"},
            action: %{action: "changecard", state: "ok"},
            state: "active"
          }
        })

      {:reply, :ok, updated_state, _continue} = Game.handle_call({:change_card_select_card, "session_id1", 0}, "_pid", state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should change game state to change_card_selecting_cards", %{updated_state: updated_state} do
      assert updated_state.state == "change_card_selecting_cards"
    end

    test "should change Duke state to selected", %{updated_state: updated_state} do
      duke =
        updated_state.players
        |> Enum.at(0)
        |> Map.get(:change_card_hand)
        |> Enum.at(0)

      assert duke.state == "selected"
    end
  end

  describe "change_card_select_card, given 1 card selected, 2 cards required" do
    setup do
      state =
        initial_state(%{
          state: "change_card_cards_drawn",
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
                %Card{type: "Captain", state: "selected"},
                %Card{type: "Contessa", state: "default"}
              ]
            }
          ],
          turn: %Turn{
            player: %Player{name: "Jany", session_id: "session_id1"},
            action: %{action: "changecard", state: "ok"},
            state: "active"
          }
        })

      {:reply, :ok, updated_state, _continue} = Game.handle_call({:change_card_select_card, "session_id1", 0}, "_pid", state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should change game state to change_card_selecting_cards", %{updated_state: updated_state} do
      assert updated_state.state == "change_card_cards_selected"
    end
  end

  describe "change_card_select_card, given card already selected" do
    setup do
      state =
        initial_state(%{
          state: "change_card_cards_drawn",
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
                %Card{type: "Duke", state: "selected"},
                %Card{type: "Captain", state: "default"},
                %Card{type: "Contessa", state: "default"}
              ]
            }
          ],
          turn: %Turn{
            player: %Player{name: "Jany", session_id: "session_id1"},
            action: %{action: "changecard", state: "ok"},
            state: "active"
          }
        })

      {:reply, :ok, updated_state, _continue} = Game.handle_call({:change_card_select_card, "session_id1", 0}, "_pid", state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should maintain game state at change_card_selecting_cards", %{updated_state: updated_state} do
      assert updated_state.state == "change_card_selecting_cards"
    end

    test "should deselect: set Duke state to default", %{updated_state: updated_state} do
      duke =
        updated_state.players
        |> Enum.at(0)
        |> Map.get(:change_card_hand)
        |> Enum.at(0)

      assert duke.state == "default"
    end
  end

  describe "change_card_cards_selected, deselecting a card" do
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
                %Card{type: "Duke", state: "selected"},
                %Card{type: "Captain", state: "selected"},
                %Card{type: "Contessa", state: "default"},
                %Card{type: "Assassin", state: "default"}
              ]
            }
          ],
          turn: %Turn{
            player: %Player{name: "Jany", session_id: "session_id1"},
            action: %{action: "changecard", state: "ok"},
            state: "active"
          }
        })

      {:reply, :ok, updated_state, _continue} = Game.handle_call({:change_card_select_card, "session_id1", 0}, "_pid", state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should change game state to change_card_selecting_cards", %{updated_state: updated_state} do
      assert updated_state.state == "change_card_selecting_cards"
    end
  end
end
