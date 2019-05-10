defmodule CoupEngine.Turn do
  @moduledoc """
  One player's turn in the game
  """
  defstruct [
    :state,
    :player,
    :player_claimed_character,
    :action,
    :target,
    :target_response,
    :blocker_claimed_character,
    :player_response_to_block,
    :challenge_block_result,
    :opponent_responses
  ]

  alias CoupEngine.{Actions, Player}

  def initialize do
    %__MODULE__{
      player: %{state: "pending"},
      player_claimed_character: nil,
      action: %{state: "pending"},
      target: %{state: "pending"},
      target_response: %{state: "pending"},
      blocker_claimed_character: nil,
      player_response_to_block: %{state: "pending"},
      state: "active",
      opponent_responses: nil,
      challenge_block_result: nil
    }
  end

  @spec build(%__MODULE__{}, [%Player{}], non_neg_integer()) :: {:ok, %__MODULE__{}}
  def build(turn, players, player_index) do
    player = players |> Enum.at(player_index) |> Map.put(:state, "ok")

    opponent_responses =
      players
      |> Enum.filter(fn p -> p.session_id != player.session_id end)
      |> Enum.map(fn p -> {p.session_id, "pending"} end)
      |> Enum.into(%{})

    updated_turn = turn |> Map.merge(%{player: player, opponent_responses: opponent_responses})

    {:ok, updated_turn}
  end

  @spec set_target(%__MODULE__{}, [%Player{}], String.t(), String.t()) ::
          {:ok, %__MODULE__{}, %Player{}}
  def set_target(turn, players, session_id, state \\ "ok") do
    player =
      players
      |> Enum.find(fn player -> player.session_id == session_id end)
      |> Map.put(:state, state)

    updated_turn = turn |> Map.put(:target, player)

    {:ok, updated_turn, player}
  end

  @spec put_action(%__MODULE__{}, String.t()) :: {:ok, %__MODULE__{}}
  def put_action(turn, action) do
    {:ok, turn_action} = Actions.get_turn_action(action)
    {:ok, claimed_character} = Actions.get_claimed_character(action)

    turn =
      turn
      |> Map.put(:action, turn_action)
      |> Map.put(:player_claimed_character, claimed_character)

    {:ok, turn}
  end

  @spec set_opponent_allow(%__MODULE__{}, [%Player{}], String.t()) ::
          {:ok, %__MODULE__{}, %Player{}}
  def set_opponent_allow(turn, players, session_id) do
    player =
      players
      |> Enum.find(fn player -> player.session_id == session_id end)

    updated_opponent_responses = turn.opponent_responses |> Map.put(session_id, "allow")

    updated_turn = turn |> Map.put(:opponent_responses, updated_opponent_responses)

    {:ok, updated_turn, player}
  end

  # {:ok, turn, player} <- Turn.set_opponent_challenge(turn, players, challenger_session_id)
  @spec set_opponent_challenge(%__MODULE__{}, [%Player{}], String.t()) ::
          {:ok, %__MODULE__{}, %Player{}}
  def set_opponent_challenge(turn, players, challenger_session_id) do
    player = players |> Enum.find(fn player -> player.session_id == challenger_session_id end)

    updated_opponent_responses =
      turn.opponent_responses |> Map.put(challenger_session_id, "challenge")

    updated_turn = turn |> Map.put(:opponent_responses, updated_opponent_responses)

    {:ok, updated_turn, player}
  end

  @spec set_block_target_response(%__MODULE__{}, [%Player{}], String.t(), String.t()) ::
          {:ok, %__MODULE__{}}
  def set_block_target_response(turn, players, session_id, "block_as_duke") do
    with {:ok, turn, _player} <- set_target(turn, players, session_id, "block_as_duke"),
         {:ok, turn} <- set_target_response(turn, "block_as_duke") do
      turn = turn |> Map.put(:blocker_claimed_character, "Duke")
      {:ok, turn}
    end
  end

  def set_block_target_response(turn, players, session_id, "block_as_captain") do
    with {:ok, turn, _player} <- set_target(turn, players, session_id, "block_as_captain"),
         {:ok, turn} <- set_target_response(turn, "block_as_captain") do
      turn = turn |> Map.put(:blocker_claimed_character, "Captain")
      {:ok, turn}
    end
  end

  def set_block_target_response(turn, players, session_id, "block_as_ambassador") do
    with {:ok, turn, _player} <- set_target(turn, players, session_id, "block_as_ambassador"),
         {:ok, turn} <- set_target_response(turn, "block_as_ambassador") do
      turn = turn |> Map.put(:blocker_claimed_character, "Ambassador")
      {:ok, turn}
    end
  end

  def set_block_target_response(turn, players, session_id, _block_action) do
    {:ok, turn, _player} = set_target(turn, players, session_id, "ok")
    {:ok, turn}
  end

  @spec set_target_response(%__MODULE__{}, String.t()) :: {:ok, %__MODULE__{}}
  defp set_target_response(turn, block_action) do
    {:ok, action} = Actions.get_block_action(block_action)

    turn =
      turn
      |> Map.put(:target_response, action)

    {:ok, turn}
  end

  @spec set_player_allow_block(%__MODULE__{}) :: {:ok, %__MODULE__{}}
  def set_player_allow_block(turn) do
    turn =
      turn
      |> Map.put(:state, "ended")
      |> Map.put(:player_response_to_block, Actions.allow_block_action())

    {:ok, turn}
  end

  @spec set_player_challenge_block(%__MODULE__{}) :: {:ok, %__MODULE__{}}
  def set_player_challenge_block(turn) do
    turn =
      turn
      |> Map.put(:player_response_to_block, Actions.challenge_block_action())

    {:ok, turn}
  end

  @turn_ended_actions ["1coin", "foreignaid", "steal", "3coins"]
  @spec get_action_success_next_turn(%__MODULE__{}, String.t()) :: {:ok, %__MODULE__{}}
  def get_action_success_next_turn(turn, action) when action in @turn_ended_actions do
    {:ok, turn |> Map.put(:state, "ended")}
  end

  def get_action_success_next_turn(turn, _) do
    {:ok, turn}
  end
end
