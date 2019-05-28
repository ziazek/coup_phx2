defmodule CoupEngine.Players do
  @moduledoc """
  Modifies the players list
  """

  alias CoupEngine.{Actions, Card, Player}

  @spec get_player([%Player{}], String.t()) :: %Player{} | nil
  def get_player(players, session_id) do
    Enum.find(players, fn player -> player.session_id == session_id end)
  end

  @spec get_winner([%Player{}]) :: %Player{} | nil
  def get_winner(players) do
    Enum.find(players, fn player -> player.state == "won" end)
  end

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
          player
          |> Map.put(:actions_panel_mode, "responses")
          |> Map.put(:responses, Actions.default_responses())
        end
      end)

    {:ok, players}
  end

  @spec apply_action([%Player{}], String.t(), map(), String.t()) :: {:ok, [%Player{}]}
  def apply_action(players, "1coin", session_id, _target) do
    players =
      players
      |> only_current_player(session_id, fn player ->
        player |> Map.put(:coins, player.coins + 1)
      end)

    {:ok, players}
  end

  def apply_action(players, "foreignaid", session_id, _target) do
    players =
      players
      |> only_current_player(session_id, fn player ->
        player |> Map.put(:coins, player.coins + 2)
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

  def apply_action(players, "3coins", session_id, _target) do
    players =
      players
      |> only_current_player(session_id, fn player ->
        player |> Map.put(:coins, player.coins + 3)
      end)

    {:ok, players}
  end

  @apply_action_do_nothing ["coup", "assassinate", "changecard"]
  def apply_action(players, action, _session_id, _target)
      when action in @apply_action_do_nothing do
    {:ok, players}
  end

  def apply_action(_, _, _) do
    {:error, "Undefined action"}
  end

  defp coins_deductable(target_coins, max_amt) do
    min(target_coins, max_amt)
  end

  @spec deduct_action_cost([%Player{}], String.t(), String.t()) :: {:ok, [%Player{}]}
  def deduct_action_cost(players, session_id, action) do
    {:ok, cost} = Actions.get_cost(action)

    players =
      players
      |> only_current_player(session_id, fn player ->
        player |> Map.put(:coins, player.coins - cost)
      end)

    {:ok, players}
  end

  @select_target_actions ["coup", "steal", "assassinate"]
  @spec set_display_state([%Player{}], String.t(), String.t()) :: {:ok, [%Player{}]}
  def set_display_state(players, session_id, action) when action in @select_target_actions do
    players =
      players
      |> only_current_player(session_id, fn player ->
        player |> Map.put(:display_state, "select_target")
      end)

    {:ok, players}
  end

  @awaiting_actions ["foreignaid", "3coins", "changecard"]
  def set_display_state(players, session_id, action) when action in @awaiting_actions do
    players =
      players
      |> Enum.map(fn player ->
        if player.session_id == session_id do
          player |> Map.put(:display_state, "awaiting_opponent_response")
        else
          player |> Map.put(:display_state, "responses")
        end
      end)

    {:ok, players}
  end

  def set_display_state(players, session_id, "lose_influence_select_card") do
    players =
      players
      |> only_current_player(session_id, fn player ->
        player |> Map.put(:display_state, "lose_influence_select_card")
      end)

    {:ok, players}
  end

  def set_display_state(players, session_id, "change_card_draw_card") do
    players =
      players
      |> only_current_player(session_id, fn player ->
        player |> Map.put(:display_state, "change_card")
      end)

    {:ok, players}
  end

  def set_display_state(players, _, _), do: {:ok, players}

  @opponent_responses_actions ["steal", "3coins", "assassinate"]

  @spec set_opponent_display_state([%Player{}], String.t(), String.t()) :: {:ok, [%Player{}]}
  def set_opponent_display_state(
        players,
        session_id,
        action
      )
      when action in @opponent_responses_actions do
    players =
      players
      |> only_opponents(session_id, fn player ->
        player |> Map.put(:display_state, "responses")
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
      |> Enum.map(fn player ->
        player
        |> Map.put(:display_state, "default")
      end)

    {:ok, players}
  end

  @spec set_card_selected([%Player{}], String.t(), non_neg_integer()) :: {:ok, [%Player{}]}
  def set_card_selected(players, session_id, index) do
    players =
      players
      |> only_current_player(session_id, fn player ->
        hand =
          player.hand
          |> Enum.map(fn card -> card |> Map.put(:state, "default") end)
          |> List.update_at(index, fn card -> card |> Map.put(:state, "selected") end)

        player |> Map.put(:hand, hand)
      end)

    {:ok, players}
  end

  @spec change_card_set_card_selected([%Player{}], String.t(), non_neg_integer()) ::
          {:ok, [%Player{}]}
  def change_card_set_card_selected(players, session_id, index) do
    players =
      players
      |> only_current_player(session_id, fn player ->
        hand =
          player.change_card_hand
          |> List.update_at(index, &toggle_card_state/1)

        player |> Map.put(:change_card_hand, hand)
      end)

    {:ok, players}
  end

  defp toggle_card_state(card) do
    next_state = if card.state == "default", do: "selected", else: "default"
    card |> Map.put(:state, next_state)
  end

  @spec reveal_card([%Player{}], boolean(), String.t(), String.t()) :: {:ok, [%Player{}]}
  def reveal_card(players, false = _challenge_success, session_id, claimed_character) do
    players =
      players
      |> only_current_player(session_id, fn player ->
        hand =
          player.hand
          |> do_reveal_card(claimed_character)

        player |> Map.put(:hand, hand)
      end)

    {:ok, players}
  end

  def reveal_card(players, true, _, _), do: {:ok, players}

  defp do_reveal_card(cards, claimed_character) do
    cards
    |> Enum.map(fn card ->
      if card.type == claimed_character do
        card |> Map.put(:state, "revealed")
      else
        card
      end
    end)
  end

  @spec set_opponent_responses([%Player{}], String.t(), String.t()) :: {:ok, [%Player{}]}
  def set_opponent_responses(players, session_id, action) do
    players =
      players
      |> Enum.map(fn player ->
        if player.session_id == session_id do
          player
        else
          player
          |> Map.put(:responses, Actions.opponent_responses_for(action))
        end
      end)

    {:ok, players}
  end

  @targetable_actions ["steal", "assassinate"]
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

  @spec generate_change_card_hand([%Player{}], String.t(), [%Card{}]) ::
          {:ok, [%Player{}], [%Card{}]}
  def generate_change_card_hand(players, session_id, deck) do
    [top_card_1, top_card_2 | rest] = deck

    players =
      players
      |> only_current_player(session_id, fn player ->
        live_cards = player.hand |> Enum.filter(fn card -> card.state != "dead" end)

        player
        |> Map.put(:change_card_hand, live_cards ++ [top_card_1, top_card_2])
      end)

    {:ok, players, rest}
  end

  @doc """
  Copies the selected cards in Player's change_card_hand to hand
  """

  @spec change_card_confirm([%Player{}], String.t()) :: {:ok, [%Player{}], String.t(), [%Card{}]}
  def change_card_confirm(players, session_id) do
    player = players |> get_player(session_id)

    returned_cards =
      player.change_card_hand |> Enum.filter(fn card -> card.state != "selected" end)

    players =
      players
      |> only_current_player(session_id, fn player ->
        selected_cards =
          player.change_card_hand
          |> Enum.filter(fn card -> card.state == "selected" end)
          |> Enum.map(fn card -> card |> Map.put(:state, "default") end)

        dead_cards = player.hand |> Enum.filter(fn card -> card.state == "dead" end)

        player
        |> Map.put(:hand, selected_cards ++ dead_cards)
        |> Map.put(:change_card_hand, [])
        |> Map.put(:display_state, "default")
      end)

    description =
      "#{player.name} selected #{length(player.hand)} cards. Remaining cards returned, deck shuffled."

    {:ok, players, description, returned_cards}
  end

  @doc """
  Checks whether there is a winner
  """

  @spec check_for_win([%Player{}]) :: {:ok, boolean()}
  def check_for_win(players) do
    alive = players |> Enum.filter(fn player -> player.state == "alive" end)
    {:ok, length(alive) == 1}
  end

  @doc """
  Assigns state "win" to winner
  """

  @spec assign_win([%Player{}], boolean()) :: {:ok, [%Player{}], %Player{}}
  def assign_win(players, true) do
    players =
      players
      |> Enum.map(fn player ->
        if player.state == "alive" do
          player |> Map.put(:state, "won")
        else
          player
        end
      end)

    winner = players |> get_winner()

    {:ok, players, winner}
  end

  def assign_win(players, false), do: {:ok, players, nil}

  @doc """
  Checks whether any of the players' cards state is 'revealed'
  """

  @spec check_revealed_card([%Player{}]) :: {:ok, boolean()}
  def check_revealed_card(players) do
    result =
      players
      |> Enum.any?(fn player ->
        Enum.any?(player.hand, fn card -> card.state == "revealed" end)
      end)

    {:ok, result}
  end

  @doc """
  Returns any revealed cards to the deck
  """

  @spec return_revealed_card([%Player{}], [%Card{}]) :: {:ok, [%Player{}], [%Card{}]}
  def return_revealed_card(players, deck) do
    {players, deck} =
      players
      |> Enum.map_reduce(deck, fn player, deck_acc ->
        revealed_cards = player.hand |> find_revealed_cards()
        converted_hand = player.hand |> convert_revealed_cards_to_replacing()
        updated_player = player |> Map.put(:hand, converted_hand)

        {updated_player, deck_acc ++ revealed_cards}
      end)

    {:ok, players, deck}
  end

  defp find_revealed_cards(cards) do
    cards
    |> Enum.filter(fn card -> card.state == "revealed" end)
    |> Enum.map(fn card -> card |> Map.put(:state, "default") end)
  end

  defp convert_revealed_cards_to_replacing(cards) do
    cards
    |> Enum.map(fn card ->
      if card.state == "revealed" do
        card
        |> Map.put(:state, "replacing")
        |> Map.put(:type, "")
      else
        card
      end
    end)
  end

  @doc """
  Replaces any pending-replacement card with the top card from deck
  """

  @spec draw_revealed_replacement_card([%Player{}], [%Card{}]) :: {:ok, [%Player{}], [%Card{}]}
  def draw_revealed_replacement_card(players, deck) do
    {players, deck} =
      players
      |> Enum.map_reduce(deck, fn player, deck_acc ->
        if has_replacing?(player.hand) do
          [first_card | rest] = deck_acc

          hand =
            player.hand
            |> Enum.map(fn card ->
              if card.state == "replacing" do
                first_card
              else
                card
              end
            end)

          updated_player = player |> Map.put(:hand, hand)
          {updated_player, rest}
        else
          {player, deck_acc}
        end
      end)

    {:ok, players, deck}
  end

  defp has_replacing?(cards) do
    cards |> Enum.any?(fn card -> card.state == "replacing" end)
  end

  ## UTILITIES ##

  @spec only_current_player([%Player{}], String.t(), fun()) :: [%Player{}]
  defp only_current_player(players, session_id, fun) do
    players
    |> Enum.map(fn player ->
      if player.session_id == session_id do
        apply(fun, [player])
      else
        player
      end
    end)
  end

  @spec only_opponents([%Player{}], String.t(), fun()) :: [%Player{}]
  defp only_opponents(players, session_id, fun) do
    players
    |> Enum.map(fn player ->
      if player.session_id != session_id do
        apply(fun, [player])
      else
        player
      end
    end)
  end
end
