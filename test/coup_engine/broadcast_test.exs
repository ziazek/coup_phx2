defmodule CoupEngine.BroadcastTest do
  use CoupPhx2Web.GameCase, async: true
  alias CoupEngine.Game

  test "handle_continue :broadcast_to_all should broadcast using Phoenix.PubSub" do
    state = initial_state(%{game_name: "Game1"})

    Game.handle_continue(:broadcast_change, state)

    # This uses PubSubMock
    assert_receive {"Game1", :game_data_changed}
  end
end
