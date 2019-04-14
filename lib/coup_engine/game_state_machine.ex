defmodule CoupEngine.GameStateMachine do
  @moduledoc """
  Game state machine. checks if an action is allowed for the current game state
  """

  @max_players 6

  @spec check(String.t(), atom()) :: {:ok, String.t()} | {:error, String.t()}
  def check(_, _), do: {:error, "invalid game state"}

  @spec check(String.t(), atom(), pos_integer()) :: {:ok, String.t()} | {:error, String.t()}
  def check("adding_players", :add_player, count) when count < @max_players,
    do: {:ok, "adding_players"}

  def check("adding_players", :add_player, count) when count >= @max_players,
    do: {:error, "maximum number of players reached"}

  def check(_, _, _), do: {:error, "invalid game state"}
end
