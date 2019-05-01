defmodule CoupEngine.SelectTargetStealTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Action, Game, Player, Turn}

  describe "select_target, steal" do
    setup do
      state =
        initial_state(%{
          state: "select_target",
          players: [
            %Player{name: "Ken", session_id: "session_id1", display_state: "select_target"},
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
            target: %{state: "pending"}
          }
        })

      {:reply, :ok, updated_state, _continue} =
        Game.handle_call({:select_target, "session_id2"}, "_pid", state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should set game state to awaiting_opponent_response", %{updated_state: updated_state} do
      assert updated_state.state == "awaiting_opponent_response"
    end

    test "should set turn target to Zek", %{updated_state: updated_state} do
      turn = updated_state.turn
      assert turn.target.name == "Zek"
      assert turn.target.session_id == "session_id2"
      assert turn.target.state == "ok"
    end

    test "should update toast to 'Ken STEALS from Zek.'", %{
      updated_state: updated_state
    } do
      latest_toast = updated_state.toast |> Enum.at(-1)
      assert latest_toast.body == "Ken STEALS from Zek."
    end

    test "should update Zek available responses to Allow, Challenge, Block as Captain, Block as Ambassador",
         %{
           updated_state: updated_state
         } do
      zek = updated_state.players |> Enum.at(1)

      zek_available_responses =
        zek.responses |> Enum.filter(fn action -> action.state == "enabled" end)

      zek_response0 = zek_available_responses |> Enum.at(0)
      zek_response1 = zek_available_responses |> Enum.at(1)
      zek_response2 = zek_available_responses |> Enum.at(2)
      zek_response3 = zek_available_responses |> Enum.at(3)
      assert zek_response0.action == "allow"
      assert zek_response0.label == "Allow"
      assert zek_response1.action == "challenge"
      assert zek_response1.label == "Challenge"
      assert zek_response2.action == "block_as_ambassador"
      assert zek_response2.label == "Block as Ambassador"
      assert zek_response3.action == "block_as_captain"
      assert zek_response3.label == "Block as Captain"
    end

    test "should update Naz available responses to Allow, Challenge",
         %{
           updated_state: updated_state
         } do
      naz = updated_state.players |> Enum.at(2)

      naz_available_responses =
        naz.responses |> Enum.filter(fn action -> action.state == "enabled" end)

      naz_response0 = naz_available_responses |> Enum.at(0)
      naz_response1 = naz_available_responses |> Enum.at(1)

      assert naz_response0.action == "allow"
      assert naz_response0.label == "Allow"
      assert naz_response1.action == "challenge"
      assert naz_response1.label == "Challenge"
    end

    test "should set Ken's display_state to default", %{updated_state: updated_state} do
      ken = updated_state.players |> Enum.at(0)
      assert ken.display_state == "default"
    end

    test "should update Zek and Naz display_state to responses", %{updated_state: updated_state} do
      zek = updated_state.players |> Enum.at(1)
      naz = updated_state.players |> Enum.at(2)

      assert zek.display_state == "responses"
      assert naz.display_state == "responses"
    end
  end
end
