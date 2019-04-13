defmodule CoupEngineArchive.GamePlayerActionTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Game, Player, PossibleAction, PossibleResponse, Response, Rules, Turn}

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

      %Turn{
        description: "Naz's turn",
        player: %Player{name: "Naz", possible_actions: possible_actions},
        action: :pending,
        claimed_character: nil,
        # rationale for putting opponent responses in an array:
        # we may have an "allow" response in the future, to proceed to the next step
        # once all opponents click "allow" - instead of waiting for the timer to run out.
        opponent_responses: [
          %Response{
            player: %Player{name: "Celine"},
            response: :pending
          }
        ]
      } = resulting_state.turn

      assert length(possible_actions) > 0
    end

    test "when player has >= 10 coins, should set game state to 'player_action', possible actions only 'coup'" do
      state =
        initial_state(%{
          rules: %Rules{state: :cards_drawn},
          players: [%Player{name: "Naz", coins: 10}, %Player{name: "Celine"}]
        })

      {:noreply, resulting_state} = Game.handle_info({:start_turn, 0}, state)

      assert resulting_state.rules.state == :player_action
      player = resulting_state.players |> Enum.at(0)

      assert player.possible_actions == [
               %PossibleAction{action: :coup, select_target: true}
             ]
    end

    test "when player has < 10 coins, should show all possible actions" do
      state =
        initial_state(%{
          rules: %Rules{state: :cards_drawn},
          players: [%Player{name: "Naz", coins: 9}, %Player{name: "Celine"}]
        })

      {:noreply, resulting_state} = Game.handle_info({:start_turn, 0}, state)

      assert resulting_state.rules.state == :player_action
      player = resulting_state.players |> Enum.at(0)

      assert player.possible_actions == [
               %PossibleAction{action: :coup, select_target: true},
               %PossibleAction{action: :take_one_coin},
               %PossibleAction{action: :take_foreign_aid},
               %PossibleAction{action: :take_three_coins, claimed_character: "Duke"},
               %PossibleAction{
                 action: :change_card,
                 claimed_character: "Ambassador",
                 select_target: true
               },
               %PossibleAction{
                 action: :assassinate,
                 claimed_character: "Assassin",
                 select_target: true
               },
               %PossibleAction{action: :steal, claimed_character: "Captain", select_target: true}
             ]
    end

    test "when player has < 7 coins, should not show coup" do
      state =
        initial_state(%{
          rules: %Rules{state: :cards_drawn},
          players: [%Player{name: "Naz", coins: 6}, %Player{name: "Celine"}]
        })

      {:noreply, resulting_state} = Game.handle_info({:start_turn, 0}, state)

      assert resulting_state.rules.state == :player_action
      player = resulting_state.players |> Enum.at(0)

      assert player.possible_actions == [
               %PossibleAction{action: :take_one_coin},
               %PossibleAction{action: :take_foreign_aid},
               %PossibleAction{action: :take_three_coins, claimed_character: "Duke"},
               %PossibleAction{
                 action: :change_card,
                 claimed_character: "Ambassador",
                 select_target: true
               },
               %PossibleAction{
                 action: :assassinate,
                 claimed_character: "Assassin",
                 select_target: true
               },
               %PossibleAction{action: :steal, claimed_character: "Captain", select_target: true}
             ]
    end

    test "when player has < 3 coins, should not show assassinate" do
      state =
        initial_state(%{
          rules: %Rules{state: :cards_drawn},
          players: [%Player{name: "Naz", coins: 2}, %Player{name: "Celine"}]
        })

      {:noreply, resulting_state} = Game.handle_info({:start_turn, 0}, state)

      assert resulting_state.rules.state == :player_action
      player = resulting_state.players |> Enum.at(0)

      assert player.possible_actions == [
               %PossibleAction{action: :take_one_coin},
               %PossibleAction{action: :take_foreign_aid},
               %PossibleAction{action: :take_three_coins, claimed_character: "Duke"},
               %PossibleAction{
                 action: :change_card,
                 claimed_character: "Ambassador",
                 select_target: true
               },
               %PossibleAction{action: :steal, claimed_character: "Captain", select_target: true}
             ]
    end
  end

  describe "attempt_action, take_one_coin" do
    test "should set action to take_one_coin, game state to 'action_success'" do
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

    test "should set player possible responses to :block, 'Duke'" do
      state =
        initial_state(%{
          rules: %Rules{state: :player_action},
          players: [
            %Player{name: "Naz", session_id: "session1"},
            %Player{name: "TH", session_id: "session2"},
            %Player{name: "Jany", session_id: "session3"}
          ],
          turn: %Turn{
            description: "Naz's turn",
            player: %Player{name: "Naz", session_id: "session1"},
            action: :pending
          }
        })

      {:reply, :ok, resulting_state} =
        Game.handle_call({:attempt_action, :take_foreign_aid}, "_pid", state)

      naz = resulting_state.players |> Enum.at(0)
      th = resulting_state.players |> Enum.at(1)
      jany = resulting_state.players |> Enum.at(2)

      assert naz.possible_responses == []

      assert th.possible_responses == [
               %PossibleResponse{
                 response: :block,
                 claimed_character: "Duke"
               }
             ]

      assert jany.possible_responses == [
               %PossibleResponse{
                 response: :block,
                 claimed_character: "Duke"
               }
             ]
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

    test "should set possible responses to :challenge" do
      state =
        initial_state(%{
          rules: %Rules{state: :player_action},
          players: [
            %Player{name: "Naz", session_id: "session1"},
            %Player{name: "TH", session_id: "session2"},
            %Player{name: "Jany", session_id: "session3"}
          ],
          turn: %Turn{
            description: "Naz's turn",
            player: %Player{name: "Naz", session_id: "session1"},
            action: :pending
          }
        })

      {:reply, :ok, resulting_state} =
        Game.handle_call({:attempt_action, :take_three_coins}, "_pid", state)

      naz = resulting_state.players |> Enum.at(0)
      th = resulting_state.players |> Enum.at(1)
      jany = resulting_state.players |> Enum.at(2)

      assert naz.possible_responses == []

      assert th.possible_responses == [
               %PossibleResponse{
                 response: :challenge
               }
             ]

      assert jany.possible_responses == [
               %PossibleResponse{
                 response: :challenge
               }
             ]
    end
  end

  # describe "attempt_action, change_card" do
  #
  # end
  #
  # describe "select_card_1, change_card" do
  #
  # end
  #
  # describe "select_card_2, change_card" do
  #
  # end

  describe "attempt_action, assassinate" do
    test "should set game state to 'select_target' and claimed_character 'Assassin'" do
      state =
        initial_state(%{
          rules: %Rules{state: :player_action},
          players: [
            %Player{name: "Naz", coins: 3},
            %Player{name: "Justin", session_id: "session1"}
          ],
          turn: %Turn{
            description: "Naz's turn",
            player: %Player{name: "Naz", coins: 3},
            action: :pending
          }
        })

      {:reply, :ok, resulting_state} =
        Game.handle_call({:attempt_action, :assassinate}, "_pid", state)

      assert resulting_state.turn.action == :assassinate
      assert resulting_state.turn.claimed_character == "Assassin"
      assert resulting_state.turn.target_player_id == nil
      assert resulting_state.rules.state == :select_target
      player = resulting_state.players |> Enum.at(0)
      assert player.coins == 0
    end

    # TODO
    # test "should set possible targets" do
    # end

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

  describe "select_target, assassinate" do
    test "should set game state to 'opponent_responses' and target_player_id to session_id of target" do
      state =
        initial_state(%{
          rules: %Rules{state: :select_target},
          players: [
            %Player{name: "Naz", coins: 3},
            %Player{name: "Justin", session_id: "session1"}
          ],
          turn: %Turn{
            description: "Naz's turn",
            player: %Player{name: "Naz", coins: 3},
            action: :assassinate
          }
        })

      {:reply, :ok, resulting_state} = Game.handle_call({:set_target, "session1"}, "_pid", state)

      assert resulting_state.turn.action == :assassinate
      assert resulting_state.turn.target_player_id == "session1"
      assert resulting_state.rules.state == :opponent_responses
    end

    test "should set possible responses to :challenge, set target possible responses to :challenge and :block" do
      state =
        initial_state(%{
          rules: %Rules{state: :select_target},
          players: [
            %Player{name: "Naz", session_id: "session1", coins: 3},
            %Player{name: "TH", session_id: "session2"},
            %Player{name: "Jany", session_id: "session3"}
          ],
          turn: %Turn{
            description: "Naz's turn",
            player: %Player{name: "Naz", session_id: "session1", coins: 3},
            action: :assassinate
          }
        })

      {:reply, :ok, resulting_state} = Game.handle_call({:set_target, "session2"}, "_pid", state)

      naz = resulting_state.players |> Enum.at(0)
      th = resulting_state.players |> Enum.at(1)
      jany = resulting_state.players |> Enum.at(2)

      assert naz.possible_responses == []

      assert th.possible_responses == [
               %PossibleResponse{
                 response: :challenge
               },
               %PossibleResponse{
                 response: :block,
                 claimed_character: "Contessa"
               }
             ]

      assert jany.possible_responses == [
               %PossibleResponse{
                 response: :challenge
               }
             ]
    end
  end

  describe "attempt_action, steal" do
    test "should set game state to 'select_target' and claimed_character 'Captain'" do
      state =
        initial_state(%{
          rules: %Rules{state: :player_action},
          players: [
            %Player{name: "Naz", coins: 0},
            %Player{name: "Justin", session_id: "session1", coins: 3}
          ],
          turn: %Turn{
            description: "Naz's turn",
            player: %Player{name: "Naz", coins: 0},
            action: :pending
          }
        })

      {:reply, :ok, resulting_state} = Game.handle_call({:attempt_action, :steal}, "_pid", state)

      assert resulting_state.turn.action == :steal
      assert resulting_state.turn.claimed_character == "Captain"
      assert resulting_state.rules.state == :select_target
    end

    # TODO
    # test "when all opponents have 0 coins, should return error"

    # TODO
    # test "should set possible targets" do
    # end
  end

  describe "select_target, steal" do
    test "should set game state to 'opponent_responses' and target_player_id to session_id of target" do
      state =
        initial_state(%{
          rules: %Rules{state: :select_target},
          players: [
            %Player{name: "Naz"},
            %Player{name: "Justin", coins: 3, session_id: "session1"}
          ],
          turn: %Turn{
            description: "Naz's turn",
            player: %Player{name: "Naz"},
            action: :steal
          }
        })

      {:reply, :ok, resulting_state} = Game.handle_call({:set_target, "session1"}, "_pid", state)

      assert resulting_state.turn.action == :steal
      assert resulting_state.turn.target_player_id == "session1"
      assert resulting_state.rules.state == :opponent_responses
    end

    test "should set possible responses to :challenge, set target possible responses to :challenge and :block" do
      state =
        initial_state(%{
          rules: %Rules{state: :select_target},
          players: [
            %Player{name: "Naz", session_id: "session1"},
            %Player{name: "TH", session_id: "session2", coins: 3},
            %Player{name: "Jany", session_id: "session3"}
          ],
          turn: %Turn{
            description: "Naz's turn",
            player: %Player{name: "Naz", session_id: "session1"},
            action: :steal
          }
        })

      {:reply, :ok, resulting_state} = Game.handle_call({:set_target, "session2"}, "_pid", state)

      naz = resulting_state.players |> Enum.at(0)
      th = resulting_state.players |> Enum.at(1)
      jany = resulting_state.players |> Enum.at(2)

      assert naz.possible_responses == []

      assert th.possible_responses == [
               %PossibleResponse{
                 response: :challenge
               },
               %PossibleResponse{
                 response: :block,
                 claimed_character: "Ambassador"
               },
               %PossibleResponse{
                 response: :block,
                 claimed_character: "Captain"
               }
             ]

      assert jany.possible_responses == [
               %PossibleResponse{
                 response: :challenge
               }
             ]
    end

    test "given target has zero coins, should return error" do
      state =
        initial_state(%{
          rules: %Rules{state: :select_target},
          players: [
            %Player{name: "Naz", coins: 1},
            %Player{name: "Justin", session_id: "session1", coins: 0}
          ],
          turn: %Turn{
            description: "Naz's turn",
            player: %Player{name: "Naz", coins: 1},
            action: :steal
          }
        })

      {:reply, {:error, "target has no coins"}, resulting_state} =
        Game.handle_call({:set_target, "session1"}, "_pid", state)

      assert resulting_state.turn.action == :steal
      assert resulting_state.rules.state == :select_target
    end
  end

  describe "attempt_action, coup" do
    test "when game state is 'player_action', should set game state to select_target" do
      state =
        initial_state(%{
          rules: %Rules{state: :player_action},
          players: [%Player{name: "Naz", coins: 7}, %Player{name: "Justin", coins: 0}],
          turn: %Turn{
            description: "Naz's turn",
            player: %Player{name: "Naz", coins: 7},
            action: :pending
          }
        })

      {:reply, :ok, resulting_state} = Game.handle_call({:attempt_action, :coup}, "_pid", state)

      assert resulting_state.turn.action == :coup
      assert resulting_state.rules.state == :select_target
    end

    # TODO: should not include players who have died
    # test "should set possible targets" do
    # end

    test "when player has insufficient coins, should return error" do
      state =
        initial_state(%{
          rules: %Rules{state: :player_action},
          players: [%Player{name: "Naz", coins: 6}, %Player{name: "Justin", coins: 0}],
          turn: %Turn{
            description: "Naz's turn",
            player: %Player{name: "Naz", coins: 6},
            action: :pending
          }
        })

      {:reply, {:error, "insufficient coins"}, resulting_state} =
        Game.handle_call({:attempt_action, :coup, 1}, "_pid", state)

      assert resulting_state.turn.action == :pending
      assert resulting_state.turn.target_player_id == nil
      assert resulting_state.rules.state == :player_action
    end
  end

  describe "select_target, coup" do
    test "should set game state to 'action_success' and target_player_id to session_id of target" do
      state =
        initial_state(%{
          rules: %Rules{state: :select_target},
          players: [
            %Player{name: "Naz"},
            %Player{name: "Justin", coins: 3, session_id: "session1"}
          ],
          turn: %Turn{
            description: "Naz's turn",
            player: %Player{name: "Naz"},
            action: :coup
          }
        })

      {:reply, :ok, resulting_state} = Game.handle_call({:set_target, "session1"}, "_pid", state)

      assert resulting_state.turn.action == :coup
      assert resulting_state.turn.target_player_id == "session1"
      assert resulting_state.rules.state == :action_success
    end
  end
end
