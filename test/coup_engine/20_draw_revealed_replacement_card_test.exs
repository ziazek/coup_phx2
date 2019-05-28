defmodule CoupEngine.DrawRevealedReplacementCardTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Card, Game, Player, Turn}

  describe "draw replacement for revealed card" do
    setup do
      state =
        initial_state(%{
          state: "draw_revealed_replacement_card",
          deck: [
            %Card{type: "Contessa", state: "default"},
            %Card{type: "Assassin", state: "default"}
          ],
          players: [
            %Player{
              name: "Jany",
              session_id: "session_id1",
              coins: 0,
              state: "alive",
              hand: [
                %Card{type: "Captain", state: "default"},
                %Card{type: "", state: "replacing"}
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

      {:noreply, updated_state, _continue} =
        Game.handle_info(:draw_revealed_replacement_card, state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should update game state to turn_ended", %{
      updated_state: updated_state
    } do
      assert updated_state.state == "turn_ended"
    end

    test "should update replacement slot with Contessa", %{
      updated_state: updated_state
    } do
      card =
        updated_state.players
        |> Enum.at(0)
        |> Map.get(:hand)
        |> Enum.at(1)

      assert card.type == "Contessa"
      assert card.state == "default"
    end

    test "should send prep_next_turn to self" do
      assert_receive {:prep_next_turn, 200}
    end
  end
end
