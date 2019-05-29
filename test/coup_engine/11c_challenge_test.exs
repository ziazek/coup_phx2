defmodule CoupEngine.ChallengeTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Action, Card, Game, Player, Turn}

  describe "challenge Captain claim, success" do
    setup do
      state =
        initial_state(%{
          state: "awaiting_opponent_response",
          players: [
            %Player{
              name: "Ken",
              session_id: "session_id1",
              hand: [
                %Card{type: "Duke", state: "default"},
                %Card{type: "Assassin", state: "dead"}
              ]
            },
            %Player{name: "Zek", session_id: "session_id2"}
          ],
          turn: %Turn{
            player: %Player{name: "Ken", session_id: "session_id1"},
            target: %Player{name: "Zek", session_id: "session_id2"},
            action: %Action{
              action: "steal",
              label: "Steal",
              state: "ok"
            },
            player_claimed_character: "Captain",
            opponent_responses: %{
              "session_id2" => "pending"
            }
          }
        })

      {:reply, :ok, updated_state, _continue} =
        Game.handle_call({:challenge, "session_id2"}, "_pid", state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should update game state to player_lose_influence", %{
      updated_state: updated_state
    } do
      assert updated_state.state == "player_lose_influence"
    end

    test "should update toast to 'Zek challenges and succeeds.'", %{updated_state: updated_state} do
      latest_toast = updated_state.toast |> Enum.at(-1)
      assert latest_toast.body == "Zek challenges and succeeds."
    end

    test "should reset opponent responses to disabled", %{updated_state: updated_state} do
      responses = updated_state.players |> Enum.at(1) |> Map.get(:responses)

      assert responses == [
               %Action{
                 action: "allow",
                 label: "Allow",
                 state: "disabled"
               },
               %Action{
                 action: "challenge",
                 label: "Challenge",
                 state: "disabled"
               },
               %Action{
                 action: "block",
                 label: "Block",
                 state: "disabled"
               }
             ]
    end

    test "should update opponent_responses session_id2 to challenge", %{
      updated_state: updated_state
    } do
      zek_response = updated_state.turn.opponent_responses |> Map.get("session_id2")
      assert zek_response == "challenge"
    end

    test "should send lose_influence to self" do
      assert_receive {:lose_influence, 1000}
    end
  end

  describe "challenge Captain claim, fail" do
    setup do
      state =
        initial_state(%{
          state: "awaiting_opponent_response",
          players: [
            %Player{
              name: "Ken",
              session_id: "session_id1",
              hand: [
                %Card{type: "Captain", state: "default"},
                %Card{type: "Assassin", state: "dead"}
              ]
            },
            %Player{name: "Zek", session_id: "session_id2"}
          ],
          turn: %Turn{
            player: %Player{name: "Ken", session_id: "session_id1"},
            target: %Player{name: "Zek", session_id: "session_id2"},
            action: %Action{
              action: "steal",
              label: "Steal",
              state: "ok"
            },
            player_claimed_character: "Captain",
            opponent_responses: %{
              "session_id2" => "pending"
            }
          }
        })

      {:reply, :ok, updated_state, _continue} =
        Game.handle_call({:challenge, "session_id2"}, "_pid", state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should update game state to challenger_lose_influence", %{
      updated_state: updated_state
    } do
      assert updated_state.state == "challenger_lose_influence"
    end

    test "should update toast to 'Zek challenges and fails.'", %{updated_state: updated_state} do
      latest_toast = updated_state.toast |> Enum.at(-1)
      assert latest_toast.body == "Zek challenges and fails."
    end

    test "should reset opponent responses to disabled", %{updated_state: updated_state} do
      responses = updated_state.players |> Enum.at(1) |> Map.get(:responses)

      assert responses == [
               %Action{
                 action: "allow",
                 label: "Allow",
                 state: "disabled"
               },
               %Action{
                 action: "challenge",
                 label: "Challenge",
                 state: "disabled"
               },
               %Action{
                 action: "block",
                 label: "Block",
                 state: "disabled"
               }
             ]
    end

    test "should change Captain card state to revealed", %{updated_state: updated_state} do
      captain =
        updated_state.players
        |> Enum.at(0)
        |> Map.get(:hand)
        |> Enum.at(0)

      assert captain.state == "revealed"
    end

    test "should update opponent_responses session_id2 to challenge", %{
      updated_state: updated_state
    } do
      zek_response = updated_state.turn.opponent_responses |> Map.get("session_id2")
      assert zek_response == "challenge"
    end

    test "should send lose_influence to self" do
      assert_receive {:lose_influence, 1000}
    end
  end
end
