defmodule CoupEngine.Rules do
  @moduledoc """
  The Rules act as a finite state machine for the Game.
  """
  alias __MODULE__

  @min_players 2
  @max_players 6

  defstruct state: :initialized

  @type t :: %Rules{
          state: atom()
        }

  #### Add players ####

  @spec check(Rules.t(), atom(), pos_integer()) :: {:ok, Rules.t()} | {:error, String.t()}
  def check(%Rules{state: :adding_players} = rules, :add_player, players_count)
      when players_count < @max_players,
      do: {:ok, rules}

  def check(%Rules{state: :adding_players} = rules, :add_player, _players_count),
    do: {:error, "maximum number of players reached"}

  #### Start game ####

  def check(%Rules{state: :adding_players} = rules, :start_game, players_count)
      when players_count >= @min_players,
      do: {:ok, %Rules{rules | state: :game_started}}

  def check(%Rules{state: :adding_players} = rules, :start_game, _players_count),
    do: {:error, "insufficient players"}

  #### Catchall ####

  def check(_, _, _), do: {:error, "action not found"}
end
