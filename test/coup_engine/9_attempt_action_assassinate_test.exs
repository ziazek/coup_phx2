defmodule CoupEngine.AttemptActionAssassinateTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Action, Game, Player, Turn}

  describe "action assassinate" do
    setup do
      state =
        initial_state(%{
          state: "player_action",
          players: [
            %Player{name: "Ken", session_id: "session_id1", coins: 3},
            %Player{name: "Zek", session_id: "session_id2"},
            %Player{name: "Naz", session_id: "session_id3"}
          ],
          turn: %Turn{
            player: %Player{name: "Ken", session_id: "session_id1"},
            action: %{state: "pending"}
          }
        })

      {:reply, :ok, updated_state, _continue} =
        Game.handle_call({:action, "assassinate"}, "_pid", state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should set turn action", %{updated_state: updated_state} do
      assert updated_state.turn.action == %Action{
               action: "assassinate",
               label: "Assassinate",
               state: "ok"
             }
    end

    test "should set turn player_claimed_character to Assassin", %{updated_state: updated_state} do
      assert updated_state.turn.player_claimed_character == "Assassin"
    end

    test "should update toast to 'Ken chose ASSASSINATE. Selecting target...'", %{
      updated_state: updated_state
    } do
      latest_toast = updated_state.toast |> Enum.at(-1)
      assert latest_toast.body == "Ken chose ASSASSINATE. Selecting target..."
    end

    test "should reduce ken's coins by 3", %{updated_state: updated_state} do
      ken = updated_state.players |> Enum.at(0)

      assert ken.coins == 0
    end

    test "should set game state to select_target", %{updated_state: updated_state} do
      assert updated_state.state == "select_target"
    end

    test "should update Ken display_state to select_target", %{
      updated_state: updated_state
    } do
      ken = updated_state.players |> Enum.at(0)

      assert ken.display_state == "select_target"
    end
  end
end
