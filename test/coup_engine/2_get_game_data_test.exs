defmodule CoupEngine.GetGameDataTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Game, Player}

  describe "get_game_data/2" do
    setup do
      state =
        initial_state(%{
          players: [
            %Player{role: "creator", name: "TH", session_id: "session_id1"},
            %Player{role: "player", name: "A1", session_id: "session_id2"}
          ]
        })

      result = Game.handle_call({:get_game_data, "session_id1"}, "pid", state)

      {:reply, game_data, _state} = result

      {:ok, %{game_data: game_data}}
    end

    test "should return game data", %{game_data: game_data} do
      assert length(game_data.players) == 2
      assert game_data.state == "adding_players"
    end

    test "should copy user to current_player based on session_id", %{game_data: game_data} do
      assert game_data.current_player.name == "TH"
    end
  end
end
