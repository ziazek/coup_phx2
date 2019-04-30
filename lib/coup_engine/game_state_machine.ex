defmodule CoupEngine.GameStateMachine do
  @moduledoc """
  Game state machine. checks if an action is allowed for the current game state
  """

  @min_players 2
  @max_players 6

  alias CoupEngine.Player

  ### Arity 2 ###

  @spec check(String.t(), atom()) :: {:ok, String.t()} | {:error, String.t()}
  def check("game_started", :shuffle), do: {:ok, "deck_shuffled"}
  def check("deck_shuffled", :draw_card), do: {:ok, "drawing_cards"}
  def check("drawing_cards", :draw_card), do: {:ok, "drawing_cards"}
  def check("cards_drawn", :start_turn), do: {:ok, "player_action"}
  def check("lose_influence_select_card", :select_card), do: {:ok, "lose_influence_card_selected"}
  def check("awaiting_opponent_response", :allow), do: {:ok, "awaiting_opponent_response"}

  def check("lose_influence_card_selected", :select_card),
    do: {:ok, "lose_influence_card_selected"}

  def check("lose_influence_card_selected", :lose_influence_confirm),
    do: {:ok, "turn_ending"}

  def check("awaiting_response_to_block", :allow_block), do: {:ok, "turn_ending"}
  def check("turn_ending", :end_turn), do: {:ok, "turn_ended"}
  def check("turn_ended", :start_turn), do: {:ok, "player_action"}
  def check(_, _), do: {:error, "invalid game state"}

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
  def check("player_action", :action, "coup"), do: {:ok, "select_target"}
  def check("player_action", :action, "steal"), do: {:ok, "select_target"}

  def check("select_target", :select_target, "coup"), do: {:ok, "action_success"}
  def check("select_target", :select_target, "steal"), do: {:ok, "awaiting_opponent_response"}

  def check("awaiting_response_to_block", :challenge_block, true),
    do: {:ok, "target_lose_influence"}

  def check("awaiting_response_to_block", :challenge_block, false),
    do: {:ok, "player_lose_influence"}

  def check("action_success", :action_success, "1coin"), do: {:ok, "turn_ending"}
  def check("action_success", :action_success, "foreignaid"), do: {:ok, "turn_ending"}
  def check("action_success", :action_success, "coup"), do: {:ok, "target_lose_influence"}

  def check("target_lose_influence", :lose_influence, :select_card),
    do: {:ok, "lose_influence_select_card"}

  def check("target_lose_influence", :lose_influence, :die),
    do: {:ok, "turn_ending"}

  def check("player_lose_influence", :lose_influence, :select_card),
    do: {:ok, "lose_influence_select_card"}

  def check("player_lose_influence", :lose_influence, :die),
    do: {:ok, "turn_ending"}

  def check(_, _, _), do: {:error, "invalid game state"}

  @spec check(String.t(), atom(), String.t(), String.t()) ::
          {:ok, String.t()} | {:error, String.t()}

  def check("awaiting_opponent_response", :block, "foreignaid", "block_as_duke"),
    do: {:ok, "awaiting_response_to_block"}

  def check(_, _, _, _), do: {:error, "invalid game state"}

  @doc """
  Checks whether all players have 2 cards
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
  Checks whether all opponents have allowed
  """
  @spec check_all_opponents_allow(String.t(), map()) :: {:ok, String.t()}
  def check_all_opponents_allow(current_state, opponent_responses) do
    if Enum.all?(opponent_responses, fn {_session_id, response} -> response == "allow" end) do
      {:ok, "action_success"}
    else
      {:ok, current_state}
    end
  end
end
