defmodule CoupEngine.Players do
  @moduledoc """
  Modifies the players list
  """

  alias CoupEngine.{Actions, Player}

  @spec start_turn([%Player{}], non_neg_integer()) :: {:ok, [%Player{}]}
  def start_turn(players, player_index) do
    players =
      players
      |> Enum.with_index()
      |> Enum.map(fn {player, index} ->
        if index == player_index do
          player
          |> Map.put(:actions_panel_mode, "actions")
          |> Map.put(:actions, Actions.enable_actions_for_coins(player.coins))
        else
          player |> Map.put(:actions_panel_mode, "responses")
        end
      end)

    {:ok, players}
  end
end
