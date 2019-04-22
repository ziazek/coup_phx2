defmodule CoupEngine.InitTest do
  use CoupPhx2Web.GameCase, async: true

  alias CoupEngine.{Action, Card, Game, Player, Toast}

  describe "init/1 initial game data" do
    setup do
      result = Game.init({"game_id1", "session_id1", "GroupCreator"})

      {:ok,
       %{
         game_name: game_name,
         players: players,
         deck: deck,
         state: state,
         toast: toast,
         turn: turn
       }} = result

      {:ok,
       %{
         game_name: game_name,
         players: players,
         deck: deck,
         state: state,
         toast: toast,
         turn: turn
       }}
    end

    test "should contain game name", %{game_name: game_name} do
      assert game_name == "game_id1"
    end

    test "should have state adding_players", %{state: state} do
      assert state == "adding_players"
    end

    test "should have a toast 'Waiting for players'", %{toast: toast} do
      assert toast == [%Toast{body: "Waiting for players"}]
    end

    test "should have a turn with all attributes pending", %{turn: turn} do
      assert turn.player.state == "pending"
      assert turn.action.state == "pending"
      assert turn.target.state == "pending"
      assert turn.target_response.state == "pending"
      assert turn.player_response_to_target.state == "pending"
    end

    test "should have a complete deck of 15 cards", %{deck: deck} do
      assert deck == [
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
    end

    test "should contain one player", %{players: players} do
      assert players == [
               %Player{
                 name: "GroupCreator",
                 session_id: "session_id1",
                 role: "creator",
                 coins: 0,
                 hand: [],
                 change_card_hand: [],
                 actions_panel_mode: "actions_disabled",
                 display_state: "default",
                 actions: [
                   %Action{
                     action: "coup",
                     label: "Coup",
                     state: "disabled"
                   },
                   %Action{
                     action: "1coin",
                     label: "1 coin",
                     state: "disabled"
                   },
                   %Action{
                     action: "foreignaid",
                     label: "Foreign Aid",
                     state: "disabled"
                   },
                   %Action{
                     action: "3coins",
                     label: "3 coins",
                     state: "disabled"
                   },
                   %Action{
                     action: "steal",
                     label: "Steal",
                     state: "disabled"
                   },
                   %Action{
                     action: "assassinate",
                     label: "Assassinate",
                     state: "disabled"
                   },
                   %Action{
                     action: "changecard",
                     label: "Change card",
                     state: "disabled"
                   }
                 ],
                 responses: [
                   %Action{
                     action: "allow",
                     label: "Allow",
                     state: "disabled"
                   },
                   %Action{
                     action: "challenge",
                     label: "Challenge",
                     state: "disabled"
                   },
                   %Action{
                     action: "block",
                     label: "Block",
                     state: "disabled"
                   }
                 ]
               }
             ]
    end
  end
end
