defmodule CoupEngine.Turn do
  @moduledoc """
  A player's turn. Keeps track of current player's claimed character and the claimed character of anyone who blocks any action.
  """
  defstruct description: nil,
            player: nil,
            player_index: 0,
            target_player_index: nil,
            action: :pending,
            claimed_character: nil,
            opponent_responses: [],
            blocker: nil,
            blocker_responses: []

  alias __MODULE__
  alias CoupEngine.{Response, Player}

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
        end),
      blocker_responses: []
    }
  end

  @spec get_claimed_character(atom()) :: {:ok, String.t()}
  def get_claimed_character(:take_three_coins), do: {:ok, "Duke"}
  def get_claimed_character(:assassinate), do: {:ok, "Assassin"}
  def get_claimed_character(_action), do: {:ok, nil}

  @spec deduct_coins_for_attempted_action(%Player{}, atom()) :: {:ok, %Player{}}
  def deduct_coins_for_attempted_action(player, :assassinate) do
    player = player |> Map.put(:coins, player.coins - 3)
    {:ok, player}
  end

  def deduct_coins_for_attempted_action(player, _action), do: {:ok, player}

  @spec check_coins(atom(), non_neg_integer()) :: :ok | {:error, String.t()}
  def check_coins(:assassinate, coins) when coins >= 3, do: :ok
  def check_coins(:assassinate, _coins), do: {:error, "insufficient coins"}
  def check_coins(_, _), do: :ok
end
