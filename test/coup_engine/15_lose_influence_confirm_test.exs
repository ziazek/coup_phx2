defmodule CoupEngine.LoseInfluenceConfirmTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Card, Game, Player, Turn}

  describe "lose_influence_confirm" do
    setup do
      state =
        initial_state(%{
          state: "lose_influence_card_selected",
          players: [
            %Player{name: "Jany", session_id: "session_id1"},
            %Player{
              name: "Jaslyn",
              session_id: "session_id2",
              hand: [
                %Card{type: "Captain", state: "selected"},
                %Card{type: "Duke", state: "default"}
              ],
              display_state: "lose_influence_select_card"
            }
          ],
          turn: %Turn{
            player: %Player{name: "Jany", session_id: "session_id1"},
            action: %{action: "coup", state: "ok"},
            target: %Player{
              name: "Jaslyn",
              session_id: "session_id2"
            },
            state: "active"
          }
        })

      {:reply, :ok, updated_state, _continue} =
        Game.handle_call(:lose_influence_confirm, "_pid", state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should change card state to dead", %{updated_state: updated_state} do
      captain =
        updated_state.players
        |> Enum.at(1)
        |> Map.get(:hand)
        |> Enum.at(0)

      assert captain.state == "dead"
    end

    test "should update Jaslyn display state to default", %{updated_state: updated_state} do
      jaslyn =
        updated_state.players
        |> Enum.at(1)

      assert jaslyn.display_state == "default"
    end

    test "should updated game state to turn_ending", %{updated_state: updated_state} do
      assert updated_state.state == "turn_ending"
    end

    test "should update toast to 'Jaslyn loses CAPTAIN.'", %{
      updated_state: updated_state
    } do
      latest_toast = updated_state.toast |> Enum.at(-1)
      assert latest_toast.body == "Jaslyn loses CAPTAIN."
    end

    test "should send end_turn to self" do
      assert_receive {:end_turn, 1000}
    end
  end
end
