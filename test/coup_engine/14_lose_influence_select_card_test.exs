defmodule CoupEngine.LoseInfluenceSelectCardTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Card, Game, Player}

  describe "select_card" do
    setup do
      state =
        initial_state(%{
          state: "lose_influence_select_card",
          players: [
            %Player{
              name: "Jaslyn",
              session_id: "session_id2",
              coins: 0,
              hand: [
                %Card{type: "Captain", state: "default"},
                %Card{type: "Duke", state: "default"}
              ]
            }
          ]
        })

      {:reply, :ok, updated_state, _continue} =
        Game.handle_call({:select_card, "session_id2", 0}, "_pid", state)

      {:ok, %{updated_state: updated_state}}
    end

    test "should change card state to selected", %{updated_state: updated_state} do
      captain =
        updated_state.players
        |> Enum.at(0)
        |> Map.get(:hand)
        |> Enum.at(0)

      assert captain.state == "selected"
    end
  end
end
