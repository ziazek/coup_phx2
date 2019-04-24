defmodule CoupEngine.AllowForeignaidTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Action, Game, Player, Turn}

  describe "allow foreignaid" do
    setup do
      state =
        initial_state(%{
          state: "awaiting_opponent_response",
          players: [
            %Player{name: "Ken", session_id: "session_id1"},
            %Player{name: "Zek", session_id: "session_id2", actions_panel_mode: "responses"},
            %Player{name: "Naz", session_id: "session_id3", actions_panel_mode: "responses"}
          ],
          turn: %Turn{
            player: %Player{name: "Ken", session_id: "session_id1"},
            action: %Action{
              action: "foreignaid",
              label: "Foreign Aid",
              state: "ok"
            },
            opponent_responses: %{
              "session_id2" => "pending",
              "session_id3" => "pending"
            }
          }
        })

      {:reply, :ok, updated_state, _continue} =
        Game.handle_call({:allow, "session_id2"}, "_pid", state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should set opponent_responses session_id2 to allow", %{
      updated_state: updated_state
    } do
      zek_response = updated_state.turn.opponent_responses |> Map.get("session_id2")
      assert zek_response == "allow"
    end

    test "should update toast to 'Zek allows.'", %{updated_state: updated_state} do
      latest_toast = updated_state.toast |> Enum.at(-1)
      assert latest_toast.body == "Zek allows."
    end
  end

  # describe "last player to allow"
  # test "should trigger action_success"
end
