defmodule CoupEngine.AttemptActionChangeCardTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Action, Game, Player, Turn}

  describe "action changecard" do
    setup do
      state =
        initial_state(%{
          state: "player_action",
          players: [
            %Player{name: "Ken", session_id: "session_id1"},
            %Player{name: "Zek", session_id: "session_id2"},
            %Player{name: "Naz", session_id: "session_id3"}
          ],
          turn: %Turn{
            player: %Player{name: "Ken", session_id: "session_id1"},
            action: %{state: "pending"}
          }
        })

      {:reply, :ok, updated_state, _continue} =
        Game.handle_call({:action, "changecard"}, "_pid", state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should set turn action", %{updated_state: updated_state} do
      assert updated_state.turn.action == %Action{
               action: "changecard",
               label: "Change Card",
               state: "ok"
             }
    end

    test "should update toast to 'Ken chose CHANGE CARD.'", %{updated_state: updated_state} do
      latest_toast = updated_state.toast |> Enum.at(-1)
      assert latest_toast.body == "Ken chose CHANGE CARD."
    end

    test "should set game state to awaiting_opponent_response", %{updated_state: updated_state} do
      assert updated_state.state == "awaiting_opponent_response"
    end

    test "should update Zek and Naz available response to Allow and Challenge", %{
      updated_state: updated_state
    } do
      zek = updated_state.players |> Enum.at(1)
      naz = updated_state.players |> Enum.at(2)

      zek_available_responses =
        zek.responses |> Enum.filter(fn action -> action.state == "enabled" end)

      naz_available_responses =
        naz.responses |> Enum.filter(fn action -> action.state == "enabled" end)

      zek_response0 = zek_available_responses |> Enum.at(0)
      zek_response1 = zek_available_responses |> Enum.at(1)
      naz_response0 = naz_available_responses |> Enum.at(0)
      naz_response1 = naz_available_responses |> Enum.at(1)
      assert zek_response0.action == "allow"
      assert zek_response0.label == "Allow"
      assert zek_response1.action == "challenge"
      assert zek_response1.label == "Challenge"
      assert naz_response0.action == "allow"
      assert naz_response0.label == "Allow"
      assert naz_response1.action == "challenge"
      assert naz_response1.label == "Challenge"
    end

    test "should update Zek and Naz display_state to responses", %{updated_state: updated_state} do
      zek = updated_state.players |> Enum.at(1)
      naz = updated_state.players |> Enum.at(2)

      assert zek.display_state == "responses"
      assert naz.display_state == "responses"
    end

    test "should update Ken display_state to awaiting_opponent_response", %{
      updated_state: updated_state
    } do
      ken = updated_state.players |> Enum.at(0)

      assert ken.display_state == "awaiting_opponent_response"
    end
  end
end
