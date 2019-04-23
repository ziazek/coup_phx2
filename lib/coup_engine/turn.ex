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
    :player_response_to_target
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
      player_response_to_target: %{state: "pending"},
      state: "active"
    }
  end

  @spec build(%__MODULE__{}, [%Player{}], non_neg_integer()) :: {:ok, %__MODULE__{}}
  def build(turn, players, player_index) do
    player = players |> Enum.at(player_index) |> Map.put(:state, "ok")

    updated_turn = turn |> Map.merge(%{player: player})

    {:ok, updated_turn}
  end

  @spec set_target(%__MODULE__{}, [%Player{}], String.t()) :: {:ok, %__MODULE__{}, %Player{}}
  def set_target(turn, players, session_id, state \\ "ok") do
    player =
      players
      |> Enum.find(fn player -> player.session_id == session_id end)
      |> Map.put(:state, state)

    updated_turn = turn |> Map.put(:target, player)

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

  def set_block_target_response(turn, players, session_id, _block_action) do
    {:ok, turn, _player} = set_target(turn, players, session_id, "ok")
    {:ok, turn}
  end

  @spec set_target_response(%__MODULE__{}, String.t()) ::
          {:ok, %__MODULE__{}}
  defp set_target_response(turn, block_action) do
    {:ok, action} = Actions.get_block_action(block_action)

    turn =
      turn
      |> Map.put(:target_response, action)

    {:ok, turn}
  end

  @spec get_action_success_next_turn(%__MODULE__{}, String.t()) :: {:ok, %__MODULE__{}}
  def get_action_success_next_turn(turn, "1coin") do
    {:ok, turn |> Map.put(:state, "ended")}
  end

  def get_action_success_next_turn(turn, _) do
    {:ok, turn}
  end
end
