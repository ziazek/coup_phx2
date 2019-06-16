defmodule CoupEngine.JoinNextGameTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Game, Player}

  describe "play_again_invitation" do
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

      {:noreply, updated_state, _continue} = Game.handle_info(:play_again_invitation, state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should update game state to play_again_invitation", %{updated_state: updated_state} do
      assert updated_state.state == "play_again_invitation"
    end

    test "should generate a random 6 character string under play_again", %{
      updated_state: updated_state
    } do
      assert updated_state.play_again |> String.length() == 6
    end
  end
end
