defmodule CoupEngine.GameTest do
  use ExUnit.Case, async: true

  alias CoupEngine.{Game, Rules}

  test "init/1 should return the initial state" do
    result = Game.init("TH")

    assert result ==
             {:ok,
              %{
                players: [
                  %{role: "creator", name: "TH"}
                ],
                deck: [],
                discard: [],
                rules: %Rules{}
              }}
  end

  test "handle_call :add_player should add a player to the state" do
    state = %{
      players: [
        %{role: "creator", name: "TH"}
      ],
      deck: [],
      discard: [],
      rules: %Rules{}
    }

    result = Game.handle_call({:add_player, "Naz"}, "_pid", state)

    expected_state = %{
      players: [
        %{role: "creator", name: "TH"},
        %{role: "player", name: "Naz"}
      ],
      deck: [],
      discard: [],
      rules: %Rules{}
    }

    assert result == {:reply, :ok, expected_state}
  end
end
