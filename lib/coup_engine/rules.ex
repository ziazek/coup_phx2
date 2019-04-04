defmodule CoupEngine.Rules do
  @moduledoc """
  The Rules act as a finite state machine for the Game.

  - adding_players
  - game_started
  - deck_shuffled
  """
  alias __MODULE__

  @min_players 2
  @max_players 6

  defstruct state: :initialized, current_player: 0

  @type t :: %Rules{
          state: atom(),
          current_player: integer()
        }

  #### Add players ####

  @spec check(Rules.t(), atom(), pos_integer() | atom()) ::
          {:ok, Rules.t()} | {:error, String.t()}
  def check(%Rules{state: :adding_players} = rules, :add_player, players_count)
      when players_count < @max_players,
      do: {:ok, rules}

  def check(%Rules{state: :adding_players} = _rules, :add_player, _players_count),
    do: {:error, "maximum number of players reached"}

  #### Start game ####

  def check(%Rules{state: :adding_players} = rules, :start_game, players_count)
      when players_count >= @min_players,
      do: {:ok, %Rules{rules | state: :game_started}}

  def check(%Rules{state: :adding_players} = _rules, :start_game, _players_count),
    do: {:error, "insufficient players"}

  #### Attempt action ####

  def check(%Rules{state: :player_action} = rules, :attempt_action, :take_one_coin),
    do: {:ok, %Rules{rules | state: :action_success}}

  def check(%Rules{state: :player_action} = rules, :attempt_action, _),
    do: {:ok, %Rules{rules | state: :opponent_responses}}

  def check(_, _, _), do: {:error, "action not found"}

  #### Shuffle deck ####

  def check(%Rules{state: :game_started} = rules, :shuffle),
    do: {:ok, %Rules{rules | state: :deck_shuffled}}

  #### Draw card ####

  def check(%Rules{state: :deck_shuffled} = rules, :draw_card),
    do: {:ok, %Rules{rules | state: :drawing_cards}}

  def check(%Rules{state: :drawing_cards} = rules, :draw_card),
    do: {:ok, %Rules{rules | state: :drawing_cards}}

  #### Start turn ####

  def check(%Rules{state: :cards_drawn} = rules, :start_turn),
    do: {:ok, %Rules{rules | state: :player_action}}

  def check(_, _), do: {:error, "action not found"}

  @doc """
  Checks whether all players have 2 cards
  """
  def check_cards_drawn(%Rules{state: :drawing_cards} = rules, players) do
    all_have_2_cards = Enum.all?(players, fn player -> length(player.hand) == 2 end)

    if all_have_2_cards do
      {:ok, %Rules{rules | state: :cards_drawn}}
    else
      {:ok, rules}
    end
  end
end
