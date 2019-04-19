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

  @spec apply_action([%Player{}], String.t(), map(), String.t()) :: {:ok, [%Player{}]}
  def apply_action(players, "1coin", session_id, _target) do
    players =
      players
      |> Enum.map(fn player ->
        if player.session_id == session_id do
          player |> Map.put(:coins, player.coins + 1)
        else
          player
        end
      end)

    {:ok, players}
  end

  def apply_action(players, "coup", _session_id, %{session_id: target_session_id} = _target) do
    players =
      players
      |> Enum.map(fn player ->
        if player.session_id == target_session_id do
          player |> Map.put(:display_state, "lose_influence")
        else
          player
        end
      end)

    {:ok, players}
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

  def set_display_state(players, session_id, "lose_influence_select_card") do
    players =
      players
      |> Enum.map(fn player ->
        if player.session_id == session_id do
          player |> Map.put(:display_state, "lose_influence_select_card")
        else
          player
        end
      end)

    {:ok, players}
  end

  def set_display_state(players, _, _), do: {:ok, players}

  @spec reset_display_state([%Player{}]) :: {:ok, [%Player{}]}
  def reset_display_state(players) do
    players =
      players
      |> Enum.map(fn player -> player |> Map.put(:display_state, "default") end)

    {:ok, players}
  end

  @spec set_card_selected([%Player{}], String.t(), non_neg_integer()) :: {:ok, [%Player{}]}
  def set_card_selected(players, session_id, index) do
    players =
      players
      |> Enum.map(fn player ->
        if player.session_id == session_id do
          hand =
            player.hand
            |> List.update_at(index, fn card -> card |> Map.put(:state, "selected") end)

          player |> Map.put(:hand, hand)
        else
          player
        end
      end)

    {:ok, players}
  end

  @spec kill_player_and_last_card([%Player{}], String.t()) :: {:ok, [%Player{}]}
  def kill_player_and_last_card(players, session_id) do
    players =
      players
      |> Enum.map(fn player ->
        if player.session_id == session_id do
          hand = player.hand |> Enum.map(fn card -> card |> Map.put(:state, "dead") end)

          player
          |> Map.put(:state, "dead")
          |> Map.put(:hand, hand)
        else
          player
        end
      end)

    {:ok, players}
  end
end
