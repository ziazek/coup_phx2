defmodule CoupEngine.JoinNextGameTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Game, Player, Turn}

  describe "play_again_question" do
    setup do
      state =
        initial_state(%{
          state: "won",
          players: [
            %Player{name: "Jany", session_id: "session_id1", coins: 0, state: "won"},
            %Player{name: "DeadPlayer", session_id: "session_id2", coins: 0, state: "dead"},
            %Player{name: "Celine", session_id: "session_id3", coins: 2, state: "dead"}
          ]
        })

      {:reply, updated_state, _continue} = Game.handle_info(:play_again_question, state)

      {:ok, %{updated_state: updated_state}}
    end

    # should initialize the array of players under "next_game"

    test "should initialize the array of players under 'next_game'" do

    end
    # check that the

  end

  describe "play again" do
    setup do
      state =
        initial_state(%{
          state: "won",
          players: [
            %Player{name: "Jany", session_id: "session_id1", coins: 0, state: "won"},
            %Player{name: "DeadPlayer", session_id: "session_id2", coins: 0, state: "dead"},
            %Player{name: "Celine", session_id: "session_id3", coins: 2, state: "dead"}
          ]
        })

      {:reply, :ok, updated_state, _continue} = Game.handle_call(:prep_next_turn, "_pid", state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should update game state to next_turn_prepped", %{updated_state: updated_state} do
      assert updated_state.state == "next_turn_prepped"
    end

    test "should reset turn to all attributes pending", %{updated_state: updated_state} do
      turn = updated_state.turn
      assert turn.player.state == "pending"
      assert turn.action.state == "pending"
      assert turn.target.state == "pending"
      assert turn.target_response.state == "pending"
      assert turn.player_response_to_block.state == "pending"
    end

    test "should send {:start_turn, 2} to self" do
      assert_receive {{:start_turn, 2}, 200}
    end
  end

  describe "join next game" do
    # should start a timer after the second player has joined
  end
end
