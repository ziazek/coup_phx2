defmodule CoupEngine.ActionSuccessStealTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Action, Game, Player, Turn}

  describe "action_success, steal, target has 2 coins" do
    setup do
      state =
        initial_state(%{
          state: "action_success",
          players: [
            %Player{name: "Ken", session_id: "session_id1", coins: 0},
            %Player{name: "Zek", session_id: "session_id2", coins: 2},
            %Player{name: "Naz", session_id: "session_id3"}
          ],
          turn: %Turn{
            player: %Player{name: "Ken", session_id: "session_id1"},
            action: %Action{
              action: "steal",
              label: "Steal",
              state: "ok"
            },
            target: %Player{name: "Zek", session_id: "session_id2"},
            opponent_responses: %{
              "session_id2" => "allow",
              "session_id3" => "pending"
            }
          }
        })

      {:noreply, updated_state, _continue} = Game.handle_info(:action_success, state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should increase Ken's coins by 2", %{updated_state: updated_state} do
      ken = updated_state.players |> Enum.at(0)
      assert ken.coins == 2
    end

    test "should set Zek's coins to 0", %{updated_state: updated_state} do
      zek = updated_state.players |> Enum.at(1)
      assert zek.coins == 0
    end

    test "should update toast to 'Ken stole 2 coins from Zek.'", %{updated_state: updated_state} do
      latest_toast = updated_state.toast |> Enum.at(-1)
      assert latest_toast.body == "Ken stole 2 coins from Zek."
    end

    test "should mark turn as ended", %{updated_state: updated_state} do
      assert updated_state.turn.state == "ended"
    end

    test "should send end_turn to self" do
      assert_receive {:end_turn, 1000}
    end
  end

  describe "action_success, steal, target has 1 coin" do
    setup do
      state =
        initial_state(%{
          state: "action_success",
          players: [
            %Player{name: "Ken", session_id: "session_id1", coins: 0},
            %Player{name: "Zek", session_id: "session_id2", coins: 1}
          ],
          turn: %Turn{
            player: %Player{name: "Ken", session_id: "session_id1"},
            action: %Action{
              action: "steal",
              label: "Steal",
              state: "ok"
            },
            target: %Player{name: "Zek", session_id: "session_id2"},
            opponent_responses: %{
              "session_id2" => "allow",
              "session_id3" => "pending"
            }
          }
        })

      {:noreply, updated_state, _continue} = Game.handle_info(:action_success, state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should increase Ken's coins by 1", %{updated_state: updated_state} do
      ken = updated_state.players |> Enum.at(0)
      assert ken.coins == 1
    end

    test "should set Zek's coins to 0", %{updated_state: updated_state} do
      zek = updated_state.players |> Enum.at(1)
      assert zek.coins == 0
    end
  end
end
