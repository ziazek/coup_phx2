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

  def apply_action(players, "foreignaid", session_id, _target) do
    players =
      players
      |> Enum.map(fn player ->
        if player.session_id == session_id do
          player |> Map.put(:coins, player.coins + 2)
        else
          player
        end
      end)

    {:ok, players}
  end

  def apply_action(players, "steal", session_id, target_session_id) do
    target = players |> Enum.find(fn p -> p.session_id == target_session_id end)

    players =
      players
      |> Enum.map(fn player ->
        cond do
          player.session_id == session_id ->
            player |> Map.put(:coins, player.coins + coins_deductable(target.coins, 2))

          player.session_id == target_session_id ->
            player |> Map.put(:coins, player.coins - coins_deductable(target.coins, 2))

          true ->
            player
        end
      end)

    {:ok, players}
  end

  def apply_action(players, "coup", _session_id, _target) do
    {:ok, players}
  end

  def apply_action(_, _, _) do
    {:error, "Undefined action"}
  end

  defp coins_deductable(target_coins, max_amt) do
    min(target_coins, max_amt)
  end

  @select_target_actions ["coup", "steal"]
  @spec set_display_state([%Player{}], String.t(), String.t()) :: {:ok, [%Player{}]}
  def set_display_state(players, session_id, action) when action in @select_target_actions do
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

  @spec set_opponent_display_state([%Player{}], String.t(), String.t()) :: {:ok, [%Player{}]}
  def set_opponent_display_state(
        players,
        session_id,
        "steal"
      ) do
    players =
      players
      |> Enum.map(fn player ->
        if player.session_id == session_id do
          player
        else
          player |> Map.put(:display_state, "responses")
        end
      end)

    {:ok, players}
  end

  def set_opponent_display_state(
        players,
        _player_session_id,
        _action
      ) do
    {:ok, players}
  end

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
            |> Enum.map(fn card -> card |> Map.put(:state, "default") end)
            |> List.update_at(index, fn card -> card |> Map.put(:state, "selected") end)

          player |> Map.put(:hand, hand)
        else
          player
        end
      end)

    {:ok, players}
  end

  @spec set_opponent_responses([%Player{}], String.t(), String.t()) :: {:ok, [%Player{}]}
  def set_opponent_responses(players, session_id, "foreignaid" = action) do
    players =
      players
      |> Enum.map(fn player ->
        if player.session_id == session_id do
          player
          |> Map.put(:display_state, "awaiting_opponent_response")
        else
          player
          |> Map.put(:display_state, "responses")
          |> Map.put(:responses, Actions.opponent_responses_for(action))
        end
      end)

    {:ok, players}
  end

  def set_opponent_responses(players, _session_id, _) do
    {:ok, players}
  end

  @targetable_actions ["steal"]
  @spec target_selected_set_opponent_responses([%Player{}], String.t(), String.t(), String.t()) ::
          {:ok, [%Player{}]}
  def target_selected_set_opponent_responses(
        players,
        player_session_id,
        target_session_id,
        action
      )
      when action in @targetable_actions do
    players =
      players
      |> Enum.map(fn player ->
        cond do
          player.session_id == player_session_id ->
            player

          player.session_id == target_session_id ->
            player |> Map.put(:responses, Actions.target_selected_target_responses_for(action))

          true ->
            # other opponent
            player |> Map.put(:responses, Actions.target_selected_opponent_responses_for(action))
        end
      end)

    {:ok, players}
  end

  def target_selected_set_opponent_responses(players, _, _, _action) do
    {:ok, players}
  end

  @spec set_response_to_block([%Player{}], String.t()) :: {:ok, [%Player{}]}
  def set_response_to_block(players, session_id) do
    players =
      players
      |> Enum.map(fn player ->
        if player.session_id == session_id do
          player
          |> Map.put(:responses, Actions.player_responses_to_block())
          |> Map.put(:actions_panel_mode, "responses")
          |> Map.put(:display_state, "responding_to_block")
        else
          player
          |> Map.put(:actions_panel_mode, "actions_disabled")
          |> Map.put(:display_state, "awaiting_response_to_block")
        end
      end)

    {:ok, players}
  end

  @spec lose_influence([%Player{}], String.t()) :: {:ok, [%Player{}], String.t()}
  def lose_influence(players, session_id) do
    player = Enum.find(players, fn player -> player.session_id == session_id end)
    player_index = Enum.find_index(players, fn p -> p == player end)
    %{hand: hand} = player
    card_lost = Enum.find(hand, fn card -> card.state == "selected" end)
    card_lost_index = Enum.find_index(hand, fn card -> card == card_lost end)

    updated_hand = List.replace_at(hand, card_lost_index, card_lost |> Map.put(:state, "dead"))

    updated_player = player |> Map.put(:hand, updated_hand)

    players =
      players
      |> List.replace_at(player_index, updated_player)

    card_name = card_lost |> Map.get(:type) |> String.upcase()
    description = "#{player.name} loses #{card_name}."

    {:ok, players, description}
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
