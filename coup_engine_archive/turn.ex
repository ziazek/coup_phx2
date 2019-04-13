defmodule CoupEngineArchive.Turn do
  @moduledoc """
  A player's turn. Keeps track of current player's claimed character and the claimed character of anyone who blocks any action.
  """
  defstruct description: nil,
            player: nil,
            player_index: 0,
            target_player_id: nil,
            action: :pending,
            claimed_character: nil,
            opponent_responses: []

  alias __MODULE__
  alias CoupEngineArchive.{Response, Player}

  @spec build([%Player{}], integer()) :: %Turn{}
  def build(players, player_index) do
    current_player = players |> Enum.at(player_index)
    opponents = Enum.filter(players, fn p -> p != current_player end)

    %Turn{
      player: current_player,
      player_index: player_index,
      description: "#{current_player.name}'s turn",
      opponent_responses:
        Enum.map(opponents, fn opp ->
          %Response{
            player: opp
          }
        end)
    }
  end

  @spec get_claimed_character(atom()) :: {:ok, String.t()}
  def get_claimed_character(:take_three_coins), do: {:ok, "Duke"}
  def get_claimed_character(:assassinate), do: {:ok, "Assassin"}
  def get_claimed_character(:steal), do: {:ok, "Captain"}
  def get_claimed_character(_action), do: {:ok, nil}

  @spec deduct_coins_for_attempted_action([%Player{}], non_neg_integer(), atom()) ::
          {:ok, [%Player{}]}
  def deduct_coins_for_attempted_action(players, index, :assassinate) do
    players =
      players
      |> List.update_at(index, fn player ->
        player |> Map.put(:coins, player.coins - 3)
      end)

    {:ok, players}
  end

  def deduct_coins_for_attempted_action(players, _index, _action), do: {:ok, players}

  @spec check_coins(atom(), non_neg_integer()) :: :ok | {:error, String.t()}
  def check_coins(:assassinate, coins) when coins >= 3, do: :ok
  def check_coins(:assassinate, _coins), do: {:error, "insufficient coins"}
  def check_coins(:coup, coins) when coins >= 7, do: :ok
  def check_coins(:coup, _coins), do: {:error, "insufficient coins"}
  def check_coins(_, _), do: :ok

  @spec check_target_coins(atom(), [%Player{}], String.t() | nil) :: :ok | {:error, String.t()}
  def check_target_coins(:steal, _players, nil), do: :ok

  def check_target_coins(:steal, players, target_player_id) do
    target = Player.get_player_by_session_id(players, target_player_id)
    do_check_target_coins(target.coins)
  end

  def check_target_coins(_, _, _), do: :ok

  @spec do_check_target_coins(non_neg_integer()) :: :ok | {:error, String.t()}
  defp do_check_target_coins(coins) when coins > 0, do: :ok
  defp do_check_target_coins(_coins), do: {:error, "target has no coins"}

  @spec put_opponent_response(%Turn{}, String.t(), atom() | {atom(), String.t()}) ::
          {:ok, %Turn{}}
  def put_opponent_response(%Turn{} = turn, session_id, {:block, character}) do
    index =
      turn.opponent_responses
      |> Enum.find_index(fn opp -> opp.player.session_id == session_id end)

    opponent_responses =
      turn.opponent_responses
      |> List.update_at(index, fn r ->
        r
        |> Map.put(:response, :block)
        |> Map.put(:claimed_character, character)
      end)

    turn =
      turn
      |> Map.put(:opponent_responses, opponent_responses)

    {:ok, turn}
  end

  def put_opponent_response(%Turn{} = turn, session_id, response) do
    index =
      turn.opponent_responses
      |> Enum.find_index(fn opp -> opp.player.session_id == session_id end)

    opponent_responses =
      turn.opponent_responses
      |> List.update_at(index, fn r -> r |> Map.put(:response, response) end)

    turn =
      turn
      |> Map.put(:opponent_responses, opponent_responses)

    {:ok, turn}
  end
end
