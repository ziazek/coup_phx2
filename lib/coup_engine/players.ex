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

  @spec apply_action([%Player{}], String.t(), String.t()) :: {:ok, [%Player{}], String.t()}
  def apply_action(players, session_id, "1coin") do
    players =
      players
      |> Enum.map(fn player ->
        if player.session_id == session_id do
          player |> Map.put(:coins, player.coins + 1)
        else
          player
        end
      end)

    player = Enum.find(players, fn p -> p.session_id == session_id end)

    description = "#{player.name} received 1 coin."

    {:ok, players, description}
  end

  def apply_action(_, _, _) do
    {:error, "Undefined action"}
  end

  @spec set_display_state([%Player{}], String.t(), String.t()) :: {:ok, [%Player{}]}
  def set_display_state(players, session_id, "coup") do
    players =
      players
      |> Enum.map(fn player ->
        if player.session_id == session_id do
          player |> Map.put(:display_state, "select_target")
        else
          player
        end
      end)

    {:ok, players}
  end

  def set_display_state(players, _, _), do: {:ok, players}
end
