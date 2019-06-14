defmodule CoupEngine.CheckForWinTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Game, Player, Turn}

  describe "check_for_win, given two players alive" do
    setup do
      state =
        initial_state(%{
          state: "checking_for_win",
          players: [
            %Player{name: "Jany", session_id: "session_id1", coins: 0, state: "alive"},
            %Player{name: "Naz", session_id: "session_id2", coins: 0, state: "dead"},
            %Player{name: "Celine", session_id: "session_id3", coins: 2, state: "alive"}
          ],
          turn: %Turn{
            player: %Player{name: "Jany", session_id: "session_id1"},
            action: %{action: "1coin", state: "ok"},
            state: "active"
          }
        })

      {:noreply, updated_state, _continue} = Game.handle_info(:check_for_win, state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should update game state to checking_revealed_card", %{updated_state: updated_state} do
      assert updated_state.state == "checking_revealed_card"
    end

    test "should send check_revealed_card for next alive player" do
      assert_receive {:check_revealed_card, 10}
    end
  end

  describe "check_for_win, given one player alive" do
    setup do
      state =
        initial_state(%{
          state: "checking_for_win",
          players: [
            %Player{name: "Jany", session_id: "session_id1", coins: 0, state: "alive"},
            %Player{name: "Naz", session_id: "session_id2", coins: 0, state: "dead"},
            %Player{name: "Celine", session_id: "session_id3", coins: 2, state: "dead"}
          ],
          turn: %Turn{
            player: %Player{name: "Jany", session_id: "session_id1"},
            action: %{action: "1coin", state: "ok"},
            state: "active"
          }
        })

      {:noreply, updated_state, _continue} = Game.handle_info(:check_for_win, state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should set game state to won", %{updated_state: updated_state} do
      assert updated_state.state == "won"
    end

    test "should update Jany's state to won", %{updated_state: updated_state} do
      jany = updated_state.players |> Enum.at(0)
      assert jany.state == "won"
    end

    test "should update toast to 'Jany has won!'", %{
      updated_state: updated_state
    } do
      latest_toast = updated_state.toast |> Enum.at(-1)
      assert latest_toast.body == "Jany has won!"
    end

    test "should send play_again_question to self" do
      assert_receive {:play_again_question, 2000}
    end
  end
end
