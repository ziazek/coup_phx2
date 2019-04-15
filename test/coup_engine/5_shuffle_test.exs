defmodule CoupEngine.ShuffleTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Game, Card}

  describe "shuffle" do
    setup do
      state =
        initial_state(%{
          state: "game_started",
          deck: [
            %Card{type: "Captain", state: "default"},
            %Card{type: "Captain", state: "default"},
            %Card{type: "Captain", state: "default"},
            %Card{type: "Duke", state: "default"},
            %Card{type: "Duke", state: "default"},
            %Card{type: "Duke", state: "default"},
            %Card{type: "Ambassador", state: "default"},
            %Card{type: "Ambassador", state: "default"},
            %Card{type: "Ambassador", state: "default"},
            %Card{type: "Assassin", state: "default"},
            %Card{type: "Assassin", state: "default"},
            %Card{type: "Assassin", state: "default"},
            %Card{type: "Contessa", state: "default"},
            %Card{type: "Contessa", state: "default"},
            %Card{type: "Contessa", state: "default"}
          ]
        })

      {:noreply, updated_state, _continue} = Game.handle_info(:shuffle, state)

      {:ok, %{state: state, updated_state: updated_state}}
    end

    test "should change the order of the deck", %{state: state, updated_state: updated_state} do
      refute updated_state.deck == state.deck
      assert updated_state.state == "deck_shuffled"
    end

    test "should update toast to 'Deck shuffled.'", %{updated_state: updated_state} do
      latest_toast = updated_state.toast |> Enum.at(-1)
      assert latest_toast.body == "Deck shuffled."
    end

    test "should send draw_card to self after 1000ms" do
      assert_receive {{:draw_card, 0}, 1000}
    end
  end
end
