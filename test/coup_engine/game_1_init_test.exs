defmodule CoupEngine.Game1InitTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Game, Rules}

  test "init/1 should return the initial state" do
    result = Game.init({"game_id1", "session_id1", "Player 1"})

    {:ok,
     %{
       game_name: "game_id1",
       players: players,
       deck: deck,
       discard: [],
       rules: %Rules{state: :adding_players}
     }} = result

    assert players == [
             %{
               role: "creator",
               name: "Player 1",
               session_id: "session_id1"
             }
           ]

    assert deck == [
             %{type: "Captain"},
             %{type: "Captain"},
             %{type: "Captain"},
             %{type: "Duke"},
             %{type: "Duke"},
             %{type: "Duke"},
             %{type: "Ambassador"},
             %{type: "Ambassador"},
             %{type: "Ambassador"},
             %{type: "Assassin"},
             %{type: "Assassin"},
             %{type: "Assassin"},
             %{type: "Contessa"},
             %{type: "Contessa"},
             %{type: "Contessa"}
           ]

    assert length(deck) == 15
  end

  describe "add_player" do
    test "given a new player, should add a player to the state" do
      state =
        initial_state(%{
          players: [
            %{
              role: "creator",
              name: "Player 1",
              session_id: "session_id1"
            }
          ]
        })

      result = Game.handle_call({:add_player, "sessionid2", "Player 2"}, "_pid", state)

      expected_state =
        initial_state(%{
          players: [
            %{
              role: "creator",
              name: "Player 1",
              session_id: "session_id1"
            },
            %{
              role: "player",
              name: "Player 2",
              session_id: "sessionid2"
            }
          ]
        })

      assert result == {:reply, :ok, expected_state}
    end

    # max players = 6
    test "given max players, should not add player" do
      state =
        initial_state(%{
          players: [
            %{role: "creator", name: "TH", session_id: "session_id1"},
            %{role: "player", name: "A1", session_id: "session_id2"},
            %{role: "player", name: "A2", session_id: "session_id3"},
            %{role: "player", name: "A3", session_id: "session_id4"},
            %{role: "player", name: "A4", session_id: "session_id5"},
            %{role: "player", name: "A5", session_id: "session_id6"}
          ]
        })

      result = Game.handle_call({:add_player, "session_id_x", "LateGuy"}, "_pid", state)

      expected_state =
        initial_state(%{
          players: [
            %{role: "creator", name: "TH", session_id: "session_id1"},
            %{role: "player", name: "A1", session_id: "session_id2"},
            %{role: "player", name: "A2", session_id: "session_id3"},
            %{role: "player", name: "A3", session_id: "session_id4"},
            %{role: "player", name: "A4", session_id: "session_id5"},
            %{role: "player", name: "A5", session_id: "session_id6"}
          ]
        })

      {:reply, {:error, reason}, state_data} = result

      assert reason == "maximum number of players reached"
      assert state_data == expected_state
    end

    test "given duplicate session_id, should not add player" do
      state =
        initial_state(%{
          players: [
            %{role: "creator", name: "TH", session_id: "session_id1"},
            %{role: "player", name: "A1", session_id: "session_id2"}
          ]
        })

      result = Game.handle_call({:add_player, "session_id2", "A1"}, "_pid", state)

      expected_state = state

      assert result == {:reply, {:error, "player exists"}, expected_state}
    end
  end

  describe "get_player" do
    test "given a session_id, should return the player" do
      state =
        initial_state(%{
          players: [
            %{role: "creator", name: "TH", session_id: "session_id1"},
            %{role: "player", name: "A1", session_id: "session_id2"}
          ]
        })

      result = Game.handle_call({:get_player, "session_id2"}, "_pid", state)

      assert result == {:reply, %{role: "player", name: "A1", session_id: "session_id2"}, state}
    end
  end

  describe "list_players" do
    test "should list players" do
      state =
        initial_state(%{
          players: [
            %{role: "creator", name: "TH", session_id: "session_id1"},
            %{role: "player", name: "A1", session_id: "session_id2"}
          ]
        })

      result = Game.handle_call(:list_players, "_pid", state)

      assert result ==
               {:reply,
                [
                  %{role: "creator", name: "TH", session_id: "session_id1"},
                  %{role: "player", name: "A1", session_id: "session_id2"}
                ], state}
    end
  end

  describe "get_game_state" do
    test "should return game Rules' state" do
      state = initial_state(%{rules: %Rules{state: :some_game_state}})

      result = Game.handle_call(:get_game_state, "_pid", state)

      assert result == {:reply, :some_game_state, state}
    end
  end

  describe "get_game_data" do
    test "should return game's state data" do
      state = initial_state()

      result = Game.handle_call(:get_game_data, "_pid", state)

      assert result == {:reply, state, state}
    end
  end

  describe "start_game" do
    test "given sufficient players, should return :ok and state :game_started" do
      state =
        initial_state(%{
          players: [
            %{role: "creator", name: "TH"},
            %{role: "player", name: "Ken"}
          ]
        })

      result = Game.handle_call(:start_game, "_pid", state)

      expected_state =
        initial_state(%{
          players: [
            %{role: "creator", name: "TH"},
            %{role: "player", name: "Ken"}
          ],
          rules: %Rules{state: :game_started}
        })

      assert result == {:reply, :ok, expected_state}
    end

    test "given insufficient players, should return :error" do
      state =
        initial_state(%{
          players: [
            %{role: "creator", name: "TH"}
          ]
        })

      result = Game.handle_call(:start_game, "_pid", state)

      expected_state = state

      {:reply, {:error, reason}, state_data} = result

      assert reason == "insufficient players"
      assert state_data == expected_state
    end
  end
end
