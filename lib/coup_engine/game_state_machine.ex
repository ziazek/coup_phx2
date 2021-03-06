defmodule CoupEngine.GameStateMachine do
  @moduledoc """
  Game state machine. checks if an action is allowed for the current game state
  """

  @min_players 2
  @max_players 6

  alias CoupEngine.{Player, Players}

  ### Arity 2 ###

  @spec check(String.t(), atom()) :: {:ok, String.t()} | {:error, String.t()}
  def check("game_started", :shuffle), do: {:ok, "deck_shuffled"}
  def check("deck_shuffled", :draw_card), do: {:ok, "drawing_cards"}
  def check("drawing_cards", :draw_card), do: {:ok, "drawing_cards"}
  def check("cards_drawn", :start_turn), do: {:ok, "player_action"}
  def check("awaiting_opponent_response", :allow), do: {:ok, "awaiting_opponent_response"}
  def check("change_card_draw_card", :change_card_draw_card), do: {:ok, "change_card_cards_drawn"}
  def check("change_card_cards_drawn", :change_card_select_card), do: {:ok, "ok"}
  def check("change_card_selecting_cards", :change_card_select_card), do: {:ok, "ok"}
  def check("change_card_cards_selected", :change_card_select_card), do: {:ok, "ok"}
  def check("change_card_cards_selected", :change_card_confirm), do: {:ok, "turn_ending"}

  def check("lose_influence_select_card", :select_card), do: {:ok, "lose_influence_card_selected"}

  def check("challenger_lose_influence_select_card", :select_card),
    do: {:ok, "challenger_lose_influence_card_selected"}

  def check("lose_influence_card_selected", :select_card),
    do: {:ok, "lose_influence_card_selected"}

  def check("challenger_lose_influence_card_selected", :select_card),
    do: {:ok, "challenger_lose_influence_card_selected"}

  def check("challenge_block_success_target_lose_influence_select_card", :select_card),
    do: {:ok, "challenge_block_success_target_lose_influence_card_selected"}

  def check("challenge_block_success_target_lose_influence_card_selected", :select_card),
    do: {:ok, "challenge_block_success_target_lose_influence_card_selected"}

  def check("lose_influence_card_selected", :lose_influence_confirm),
    do: {:ok, "turn_ending"}

  def check("challenger_lose_influence_card_selected", :lose_influence_confirm),
    do: {:ok, "action_success"}

  def check(
        "challenge_block_success_target_lose_influence_card_selected",
        :lose_influence_confirm
      ),
      do: {:ok, "action_success"}

  def check("awaiting_response_to_block", :allow_block), do: {:ok, "turn_ending"}

  def check("return_revealed_card", :return_revealed_card),
    do: {:ok, "draw_revealed_replacement_card"}

  def check("draw_revealed_replacement_card", :draw_revealed_replacement_card),
    do: {:ok, "turn_ended"}

  def check("turn_ending", :end_turn), do: {:ok, "checking_for_win"}
  def check("turn_ended", :prep_next_turn), do: {:ok, "next_turn_prepped"}
  def check("next_turn_prepped", :start_turn), do: {:ok, "player_action"}
  def check("won", :play_again_invitation), do: {:ok, "play_again_invitation"}
  def check("play_again_invitation", :play_again), do: {:ok, "play_again_invitation"}
  def check(curr_state, action), do: {:error, "invalid game state, #{curr_state} #{action}"}

  ### Arity 3 ###

  @spec check(String.t(), atom(), atom() | pos_integer() | boolean() | String.t()) ::
          {:ok, String.t()} | {:error, String.t()}
  def check("adding_players", :add_player, count) when count < @max_players,
    do: {:ok, "adding_players"}

  def check("adding_players", :add_player, count) when count >= @max_players,
    do: {:error, "maximum number of players reached"}

  def check("adding_players", :start_game, count) when count >= @min_players,
    do: {:ok, "game_started"}

  def check("adding_players", :start_game, count) when count < @min_players,
    do: {:error, "Insufficient players. Need at least #{@min_players}."}

  def check("player_action", :action, "1coin"), do: {:ok, "action_success"}
  def check("player_action", :action, "foreignaid"), do: {:ok, "awaiting_opponent_response"}
  def check("player_action", :action, "3coins"), do: {:ok, "awaiting_opponent_response"}
  def check("player_action", :action, "changecard"), do: {:ok, "awaiting_opponent_response"}
  def check("player_action", :action, "coup"), do: {:ok, "select_target"}
  def check("player_action", :action, "steal"), do: {:ok, "select_target"}
  def check("player_action", :action, "assassinate"), do: {:ok, "select_target"}

  def check("select_target", :select_target, "coup"), do: {:ok, "action_success"}
  def check("select_target", :select_target, "steal"), do: {:ok, "awaiting_opponent_response"}

  def check("select_target", :select_target, "assassinate"),
    do: {:ok, "awaiting_opponent_response"}

  def check("awaiting_opponent_response", :challenge, true),
    do: {:ok, "player_lose_influence"}

  def check("awaiting_opponent_response", :challenge, false),
    do: {:ok, "challenger_lose_influence"}

  def check("awaiting_response_to_block", :challenge_block, true),
    do: {:ok, "challenge_block_success_target_lose_influence"}

  def check("awaiting_response_to_block", :challenge_block, false),
    do: {:ok, "player_lose_influence"}

  def check("action_success", :action_success, "1coin"), do: {:ok, "turn_ending"}
  def check("action_success", :action_success, "foreignaid"), do: {:ok, "turn_ending"}
  def check("action_success", :action_success, "steal"), do: {:ok, "turn_ending"}
  def check("action_success", :action_success, "3coins"), do: {:ok, "turn_ending"}
  def check("action_success", :action_success, "coup"), do: {:ok, "target_lose_influence"}
  def check("action_success", :action_success, "assassinate"), do: {:ok, "target_lose_influence"}
  def check("action_success", :action_success, "changecard"), do: {:ok, "change_card_draw_card"}

  def check("target_lose_influence", :lose_influence, :select_card),
    do: {:ok, "lose_influence_select_card"}

  def check("challenger_lose_influence", :lose_influence, :select_card),
    do: {:ok, "challenger_lose_influence_select_card"}

  def check("challenge_block_success_target_lose_influence", :lose_influence, :select_card),
    do: {:ok, "challenge_block_success_target_lose_influence_select_card"}

  def check("target_lose_influence", :lose_influence, :die),
    do: {:ok, "turn_ending"}

  def check("challenger_lose_influence", :lose_influence, :die),
    do: {:ok, "action_success"}

  def check("challenge_block_success_target_lose_influence", :lose_influence, :die),
    do: {:ok, "action_success"}

  def check("player_lose_influence", :lose_influence, :select_card),
    do: {:ok, "lose_influence_select_card"}

  def check("player_lose_influence", :lose_influence, :die),
    do: {:ok, "turn_ending"}

  def check("checking_for_win", :check_for_win, true), do: {:ok, "won"}
  def check("checking_for_win", :check_for_win, false), do: {:ok, "checking_revealed_card"}

  def check("checking_revealed_card", :check_revealed_card, true = _revealed_card_exists),
    do: {:ok, "return_revealed_card"}

  def check("checking_revealed_card", :check_revealed_card, false = _revealed_card_exists),
    do: {:ok, "turn_ended"}

  def check(curr_state, action, _),
    do: {:error, "invalid game state, #{curr_state} #{action} arity3"}

  @spec check(String.t(), atom(), String.t() | atom(), String.t()) ::
          {:ok, String.t()} | {:error, String.t()}

  # def check("challenger_lose_influence", :lose_influence, :die, "assassinate"),
  #   do: {:ok, "turn_ending"}
  #
  # def check("challenger_lose_influence", :lose_influence, :die, _action),
  #   do: {:ok, "action_success"}

  def check("awaiting_opponent_response", :block, "foreignaid", "block_as_duke"),
    do: {:ok, "awaiting_response_to_block"}

  def check("awaiting_opponent_response", :block, "steal", "block_as_captain"),
    do: {:ok, "awaiting_response_to_block"}

  def check("awaiting_opponent_response", :block, "steal", "block_as_ambassador"),
    do: {:ok, "awaiting_response_to_block"}

  def check("awaiting_opponent_response", :block, "assassinate", "block_as_contessa"),
    do: {:ok, "awaiting_response_to_block"}

  def check(curr_state, action, player_action, _),
    do: {:error, "invalid game state, #{curr_state} #{action} #{player_action} arity4"}

  @doc """
  Checks whether all players have 2 cards.
  """
  @spec check_cards_drawn(String.t(), [%Player{}]) :: {:ok, String.t()}
  def check_cards_drawn("drawing_cards", players) do
    all_have_2_cards = Enum.all?(players, fn player -> length(player.hand) == 2 end)

    if all_have_2_cards do
      {:ok, "cards_drawn"}
    else
      {:ok, "drawing_cards"}
    end
  end

  @doc """
  Checks whether all opponents have allowed.
  """
  @spec check_all_opponents_allow(String.t(), map()) :: {:ok, String.t()}
  def check_all_opponents_allow(current_state, opponent_responses) do
    if Enum.all?(opponent_responses, fn {_session_id, response} -> response == "allow" end) do
      {:ok, "action_success"}
    else
      {:ok, current_state}
    end
  end

  @doc """
  For change card action. Checks that user has selected sufficient cards to proceed.
  """
  @spec check_change_card_required_cards([%Player{}], String.t()) :: {:ok, String.t()}
  def check_change_card_required_cards(players, session_id) do
    player = Players.get_player(players, session_id)
    live_cards = Player.get_live_cards(player)

    selected_cards =
      player
      |> Map.get(:change_card_hand)
      |> Enum.filter(fn card -> card.state == "selected" end)

    if length(selected_cards) == length(live_cards) do
      {:ok, "change_card_cards_selected"}
    else
      {:ok, "change_card_selecting_cards"}
    end
  end
end
