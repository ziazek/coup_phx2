defmodule CoupEngine.StartGameTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Game, Player}

  describe "start_game, game_state: adding_players, sufficient players" do
    setup do
      state =
        initial_state(%{
          game_name: "StartGameTest",
          state: "adding_players",
          players: [
            %Player{},
            %Player{}
          ]
        })

      {:reply, :ok, updated_state, _cont} = Game.handle_call(:start_game, "_pid", state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should return ok", %{updated_state: updated_state} do
      assert updated_state.state == "game_started"
    end

    test "should update toast to 'Game is starting.'", %{updated_state: updated_state} do
      latest_toast = updated_state.toast |> Enum.at(-1)
      assert latest_toast.body == "Game is starting. Shuffling deck..."
    end

    test "should send shuffle to self after 1000ms" do
      # uses ProcessMock
      assert_receive {:shuffle, 1000}
    end
  end

  describe "start_game, insufficient players" do
    test "should return error" do
      state =
        initial_state(%{
          game_name: "StartGameTest",
          state: "adding_players",
          players: [
            %Player{}
          ]
        })

      {:reply, {:error, reason}, _state} = Game.handle_call(:start_game, "_pid", state)
      assert reason == "Insufficient players. Need at least 2."
    end
  end
end
