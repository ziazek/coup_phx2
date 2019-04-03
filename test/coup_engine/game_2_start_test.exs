defmodule CoupEngine.Game2StartTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Game, Rules}

  describe "shuffle" do
    test "should change the order of the deck" do
      state =
        initial_state(%{
          rules: %Rules{state: :game_started},
          deck: [
            %{type: "Captain"},
            %{type: "Ambassador"},
            %{type: "Duke"},
            %{type: "Assassin"},
            %{type: "Contessa"}
          ]
        })

      {:noreply, resulting_state} = Game.handle_info(:shuffle, state)

      assert resulting_state.deck != state.deck
      assert resulting_state.rules.state == :deck_shuffled
    end
  end
end
