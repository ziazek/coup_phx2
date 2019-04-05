defmodule CoupEngine.Player do
  @moduledoc """
  Player functions
  """

  defstruct role: "player",
            name: "Player",
            session_id: nil,
            hand: [],
            coins: 0,
            possible_actions: [],
            possible_responses: []

  alias __MODULE__
  alias CoupEngine.{PossibleAction, PossibleResponse}

  def add_to_hand(players, player_index, card) do
    player = get_player(players, player_index)

    hand = player.hand ++ [card]

    player = player |> Map.put(:hand, hand)

    players = players |> List.replace_at(player_index, player)

    {:ok, player, players}
  end

  def get_player(players, player_index) do
    players |> Enum.at(player_index)
  end

  def get_player_by_session_id(players, session_id) do
    players |> Enum.find(fn player -> player.session_id == session_id end)
  end

  def add_possible_actions_to_player(players, player_index) do
    players =
      players
      |> List.update_at(player_index, fn p -> p |> do_add_possible_actions(p.coins) end)

    {:ok, players}
  end

  defp do_add_possible_actions(player, coins) when coins >= 10 do
    player
    |> Map.put(:possible_actions, [
      %PossibleAction{action: :coup, select_target: true}
    ])
  end

  defp do_add_possible_actions(player, coins) when coins >= 7 do
    player
    |> Map.put(:possible_actions, [
      %PossibleAction{action: :coup, select_target: true},
      %PossibleAction{action: :take_one_coin},
      %PossibleAction{action: :take_foreign_aid},
      %PossibleAction{action: :take_three_coins, claimed_character: "Duke"},
      %PossibleAction{
        action: :change_card,
        claimed_character: "Ambassador",
        select_target: true
      },
      %PossibleAction{
        action: :assassinate,
        claimed_character: "Assassin",
        select_target: true
      },
      %PossibleAction{action: :steal, claimed_character: "Captain", select_target: true}
    ])
  end

  defp do_add_possible_actions(player, coins) when coins >= 3 do
    player
    |> Map.put(:possible_actions, [
      %PossibleAction{action: :take_one_coin},
      %PossibleAction{action: :take_foreign_aid},
      %PossibleAction{action: :take_three_coins, claimed_character: "Duke"},
      %PossibleAction{
        action: :change_card,
        claimed_character: "Ambassador",
        select_target: true
      },
      %PossibleAction{
        action: :assassinate,
        claimed_character: "Assassin",
        select_target: true
      },
      %PossibleAction{action: :steal, claimed_character: "Captain", select_target: true}
    ])
  end

  defp do_add_possible_actions(player, _coins) do
    player
    |> Map.put(:possible_actions, [
      %PossibleAction{action: :take_one_coin},
      %PossibleAction{action: :take_foreign_aid},
      %PossibleAction{action: :take_three_coins, claimed_character: "Duke"},
      %PossibleAction{
        action: :change_card,
        claimed_character: "Ambassador",
        select_target: true
      },
      %PossibleAction{action: :steal, claimed_character: "Captain", select_target: true}
    ])
  end

  @spec add_possible_responses([%Player{}], atom(), %Player{}, String.t() | nil) ::
          {:ok, [%Player{}]}
  def add_possible_responses(players, :take_foreign_aid, current_player, _target_player_id) do
    players =
      players
      |> Enum.map(fn p ->
        p |> add_block_response("Duke", {:except, current_player.session_id})
      end)

    {:ok, players}
  end

  def add_possible_responses(players, :take_three_coins, current_player, _target_player_id) do
    players =
      players
      |> Enum.map(fn p ->
        p |> add_challenge_response(current_player.session_id)
      end)

    {:ok, players}
  end

  def add_possible_responses(players, :assassinate, current_player, target_player_id) do
    players =
      players
      |> Enum.map(fn p ->
        p
        |> add_challenge_response(current_player.session_id)
        |> add_block_response("Contessa", {:only, target_player_id})
      end)

    {:ok, players}
  end

  def add_possible_responses(players, :steal, current_player, target_player_id) do
    players =
      players
      |> Enum.map(fn p ->
        p
        |> add_challenge_response(current_player.session_id)
        |> add_block_response("Ambassador", {:only, target_player_id})
        |> add_block_response("Captain", {:only, target_player_id})
      end)

    {:ok, players}
  end

  def add_possible_responses(players, _action, _current_player, _target_player_id),
    do: {:ok, players}

  defp add_challenge_response(%{session_id: session_id} = player, current_id)
       when session_id != current_id do
    player
    |> Map.put(
      :possible_responses,
      player.possible_responses ++
        [
          %PossibleResponse{
            response: :challenge
          }
        ]
    )
  end

  defp add_challenge_response(player, _current_id), do: player

  defp add_block_response(%{session_id: session_id} = player, character, {:except, current_id})
       when session_id != current_id do
    player
    |> Map.put(
      :possible_responses,
      player.possible_responses ++
        [
          %PossibleResponse{
            response: :block,
            claimed_character: character
          }
        ]
    )
  end

  defp add_block_response(
         %{session_id: session_id} = player,
         character,
         {:only, target_player_id}
       )
       when session_id == target_player_id do
    player
    |> Map.put(
      :possible_responses,
      player.possible_responses ++
        [
          %PossibleResponse{
            response: :block,
            claimed_character: character
          }
        ]
    )
  end

  defp add_block_response(player, _character, _), do: player
end
