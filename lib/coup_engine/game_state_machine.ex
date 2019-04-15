defmodule CoupEngine.GameStateMachine do
  @moduledoc """
  Game state machine. checks if an action is allowed for the current game state
  """

  @min_players 2
  @max_players 6

  alias CoupEngine.Player

  @spec check(String.t(), atom()) :: {:ok, String.t()} | {:error, String.t()}
  def check("game_started", :shuffle), do: {:ok, "deck_shuffled"}
  def check("deck_shuffled", :draw_card), do: {:ok, "drawing_cards"}
  def check("drawing_cards", :draw_card), do: {:ok, "drawing_cards"}
  def check("cards_drawn", :start_turn), do: {:ok, "player_action"}
  def check(_, _), do: {:error, "invalid game state"}

  @spec check(String.t(), atom(), pos_integer()) :: {:ok, String.t()} | {:error, String.t()}
  def check("adding_players", :add_player, count) when count < @max_players,
    do: {:ok, "adding_players"}

  def check("adding_players", :add_player, count) when count >= @max_players,
    do: {:error, "maximum number of players reached"}

  def check("adding_players", :start_game, count) when count >= @min_players,
    do: {:ok, "game_started"}

  def check("adding_players", :start_game, count) when count < @min_players,
    do: {:error, "Insufficient players. Need at least #{@min_players}."}

  def check(_, _, _), do: {:error, "invalid game state"}

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
end
