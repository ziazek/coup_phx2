defmodule CoupEngineArchive.GameOpponentReponsesTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Game, Player, Response, Rules, Turn}

  describe "game state: :action_success" do
    test "should not allow opponent response" do
      state =
        initial_state(%{
          rules: %Rules{state: :action_success},
          players: [
            %Player{name: "Naz", coins: 6},
            %Player{name: "Justin", session_id: "session1", coins: 0}
          ],
          turn: %Turn{
            description: "Naz's turn",
            player: %Player{name: "Naz", coins: 6},
            action: :steal,
            target_player_id: "session1",
            opponent_responses: [
              %Response{
                player: %Player{name: "Justin", session_id: "session1", coins: 0},
                response: :pending,
                claimed_character: nil
              }
            ]
          }
        })

      {:reply, {:error, "action not found"}, resulting_state} =
        Game.handle_call({:opponent_response, "session1", :challenge}, "_pid", state)

      opponent_response = resulting_state.turn.opponent_responses |> Enum.at(0)
      assert opponent_response.response == :pending
      assert resulting_state.rules.state == :action_success
    end
  end

  describe "game state: :opponent_responses, action: steal, response: :challenge" do
    test "should set game state to :player_called_out" do
      state =
        initial_state(%{
          rules: %Rules{state: :opponent_responses},
          turn: %Turn{
            description: "Naz's turn",
            player: %Player{name: "Naz", coins: 6},
            action: :steal,
            target_player_id: "session1",
            opponent_responses: [
              %Response{
                player: %Player{name: "Justin", session_id: "session1", coins: 0},
                response: :pending,
                claimed_character: nil
              }
            ]
          }
        })

      {:reply, :ok, resulting_state} =
        Game.handle_call({:opponent_response, "session1", :challenge}, "_pid", state)

      opponent_response = resulting_state.turn.opponent_responses |> Enum.at(0)
      assert opponent_response.response == :challenge
      assert resulting_state.rules.state == :player_challenged
    end
  end

  describe "game state :opponent_responses, action: steal, response: block" do
    test "if player is target, should set opponent response to :block, claimed_character to 'Captain', game state unchanged" do
      # note: if another player calls out the acting player, the block is ignored since the action can't take place anyway

      state =
        initial_state(%{
          rules: %Rules{state: :opponent_responses},
          turn: %Turn{
            description: "Naz's turn",
            player: %Player{name: "Naz", coins: 6},
            action: :steal,
            target_player_id: "session1",
            opponent_responses: [
              %Response{
                player: %Player{name: "Justin", session_id: "session1", coins: 0},
                response: :pending,
                claimed_character: nil
              }
            ]
          }
        })

      {:reply, :ok, resulting_state} =
        Game.handle_call({:opponent_response, "session1", {:block, "Captain"}}, "_pid", state)

      opponent_response = resulting_state.turn.opponent_responses |> Enum.at(0)
      assert opponent_response.response == :block
      assert opponent_response.claimed_character == "Captain"
    end

    test "if player is not target, should return error" do
      state =
        initial_state(%{
          rules: %Rules{state: :opponent_responses},
          turn: %Turn{
            description: "Naz's turn",
            player: %Player{name: "Naz", coins: 6},
            action: :steal,
            target_player_id: "session2",
            opponent_responses: [
              %Response{
                player: %Player{name: "Justin", session_id: "session1", coins: 0},
                response: :pending,
                claimed_character: nil
              }
            ]
          }
        })

      {:reply, {:error, "invalid response"}, _resulting_state} =
        Game.handle_call({:opponent_response, "session1", {:block, "Captain"}}, "_pid", state)
    end
  end

  describe "game state :opponent_responses, action: assassinate, response: block" do
    test "if player is target, should set opponent response to :block, claimed_character to 'Contessa', game state unchanged" do
      # later test: if player does not have Contessa, should lose two lives
      state =
        initial_state(%{
          rules: %Rules{state: :opponent_responses},
          turn: %Turn{
            description: "Naz's turn",
            player: %Player{name: "Naz", coins: 6},
            action: :assassinate,
            target_player_id: "session1",
            opponent_responses: [
              %Response{
                player: %Player{name: "Justin", session_id: "session1", coins: 0},
                response: :pending,
                claimed_character: nil
              }
            ]
          }
        })

      {:reply, :ok, resulting_state} =
        Game.handle_call({:opponent_response, "session1", {:block, "Contessa"}}, "_pid", state)

      opponent_response = resulting_state.turn.opponent_responses |> Enum.at(0)
      assert opponent_response.response == :block
      assert opponent_response.claimed_character == "Contessa"
    end
  end
end
