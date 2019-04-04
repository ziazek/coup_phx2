defmodule CoupEngine.Game3FirstTurnTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Game, Player, Response, Rules, Turn}

  describe "start_turn" do
    test "should set game state to 'player_action', current_player to 0, initialize Turn" do
      state =
        initial_state(%{
          rules: %Rules{state: :cards_drawn},
          players: [%Player{name: "Naz"}, %Player{name: "Celine"}]
        })

      {:noreply, resulting_state} = Game.handle_info({:start_turn, 0}, state)

      assert resulting_state.rules.state == :player_action
      assert resulting_state.rules.current_player == 0

      assert resulting_state.turn == %Turn{
               description: "Naz's turn",
               player: %Player{name: "Naz"},
               action: :pending,
               claimed_character: nil,
               opponent_responses: [
                 %Response{
                   player: %Player{name: "Celine"},
                   response: :pending,
                   claimed_character: nil
                 }
                 # %{player: "Celine", response: :block, claimed_character: "Captain"}
               ],
               blocker: nil,
               blocker_responses: []
               # to be populated with every player except the blocker
             }
    end
  end

  describe "attempt_action, take_one_coin" do
    test "should set action to take_one_coin" do
      state =
        initial_state(%{
          rules: %Rules{state: :player_action},
          turn: %Turn{
            description: "Naz's turn",
            player: %Player{name: "Naz"},
            action: :pending
          }
        })

      {:reply, :ok, resulting_state} =
        Game.handle_call({:attempt_action, :take_one_coin}, "_pid", state)

      assert resulting_state.turn.action == :take_one_coin
      assert resulting_state.turn.claimed_character == nil
      assert resulting_state.rules.state == :action_success

      # TODO: after action_success, carry out the action
      # send_after(self(), :do_action, 1000)
      # then, reset the Turn and increment the player_index
    end
  end

  describe "attempt_action, take_foreign_aid" do
    test "should set game state to 'opponent_responses'" do
      state =
        initial_state(%{
          rules: %Rules{state: :player_action},
          turn: %Turn{
            description: "Naz's turn",
            player: %Player{name: "Naz"},
            action: :pending
          }
        })

      {:reply, :ok, resulting_state} =
        Game.handle_call({:attempt_action, :take_foreign_aid}, "_pid", state)

      assert resulting_state.turn.action == :take_foreign_aid
      assert resulting_state.turn.claimed_character == nil
      assert resulting_state.rules.state == :opponent_responses
    end
  end

  describe "attempt_action, take_three_coins" do
    test "should set game state to 'opponent_responses' and claimed_character 'Duke'" do
      state =
        initial_state(%{
          rules: %Rules{state: :player_action},
          turn: %Turn{
            description: "Naz's turn",
            player: %Player{name: "Naz"},
            action: :pending
          }
        })

      {:reply, :ok, resulting_state} =
        Game.handle_call({:attempt_action, :take_three_coins}, "_pid", state)

      assert resulting_state.turn.action == :take_three_coins
      assert resulting_state.turn.claimed_character == "Duke"
      assert resulting_state.rules.state == :opponent_responses
    end
  end

  describe "attempt_action, assassinate" do
    test "should set game state to 'opponent_responses' and claimed_character 'Assassin'" do
      state =
        initial_state(%{
          rules: %Rules{state: :player_action},
          players: [%Player{name: "Naz", coins: 3}, %Player{name: "Justin"}],
          turn: %Turn{
            description: "Naz's turn",
            player: %Player{name: "Naz", coins: 3},
            action: :pending
          }
        })

      {:reply, :ok, resulting_state} =
        Game.handle_call({:attempt_action, :assassinate, 1}, "_pid", state)

      assert resulting_state.turn.action == :assassinate
      assert resulting_state.turn.claimed_character == "Assassin"
      assert resulting_state.turn.player.coins == 0
      assert resulting_state.turn.target_player_index == 1
      assert resulting_state.rules.state == :opponent_responses
      player = resulting_state.players |> Enum.at(0)
      assert player.coins == 0
    end

    test "given insufficient coins, should return error" do
      state =
        initial_state(%{
          rules: %Rules{state: :player_action},
          players: [%Player{name: "Naz", coins: 1}, %Player{name: "Justin"}],
          turn: %Turn{
            description: "Naz's turn",
            player: %Player{name: "Naz", coins: 1},
            action: :pending
          }
        })

      {:reply, {:error, "insufficient coins"}, resulting_state} =
        Game.handle_call({:attempt_action, :assassinate, 1}, "_pid", state)

      assert resulting_state.turn.action == :pending
      assert resulting_state.rules.state == :player_action
      player = resulting_state.players |> Enum.at(0)
      assert player.coins == 1
    end
  end

  describe "attempt_action, steal" do
    # TODO next
    test "should set game state to 'opponent_responses' and claimed_character 'Captain'" do
      state =
        initial_state(%{
          rules: %Rules{state: :player_action},
          players: [%Player{name: "Naz", coins: 3}, %Player{name: "Justin", coins: 3}],
          turn: %Turn{
            description: "Naz's turn",
            player: %Player{name: "Naz", coins: 3},
            action: :pending
          }
        })

      {:reply, :ok, resulting_state} =
        Game.handle_call({:attempt_action, :assassinate, 1}, "_pid", state)

      assert resulting_state.turn.action == :assassinate
      assert resulting_state.turn.claimed_character == "Assassin"
      assert resulting_state.turn.player.coins == 0
      assert resulting_state.turn.target_player_index == 1
      assert resulting_state.rules.state == :opponent_responses
      player = resulting_state.players |> Enum.at(0)
      assert player.coins == 0
    end

    test "given target has zero coins, should return error" do
      state =
        initial_state(%{
          rules: %Rules{state: :player_action},
          players: [%Player{name: "Naz", coins: 1}, %Player{name: "Justin"}],
          turn: %Turn{
            description: "Naz's turn",
            player: %Player{name: "Naz", coins: 1},
            action: :pending
          }
        })

      {:reply, {:error, "insufficient coins"}, resulting_state} =
        Game.handle_call({:attempt_action, :assassinate, 1}, "_pid", state)

      assert resulting_state.turn.action == :pending
      assert resulting_state.rules.state == :player_action
      player = resulting_state.players |> Enum.at(0)
      assert player.coins == 1
    end
  end

  describe "respond_to_action, allow" do
    test "if opponent allows, should set opponent_reponses for TH to 'allow'" do
    end
  end

  describe "respond_to_action, calling out" do
    test "if opponent calls out correctly, should set game state to 'action_blocked'" do
    end
  end
end
