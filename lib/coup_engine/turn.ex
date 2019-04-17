defmodule CoupEngine.Turn do
  @moduledoc """
  One player's turn in the game
  """
  defstruct [:state, :player, :action, :target, :target_response, :player_response_to_target]

  alias CoupEngine.Player

  def initialize do
    %__MODULE__{
      player: %{state: "pending"},
      action: %{state: "pending"},
      target: %{state: "pending"},
      target_response: %{state: "pending"},
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
  def set_target(turn, players, session_id) do
    player =
      players
      |> Enum.find(fn player -> player.session_id == session_id end)
      |> Map.put(:state, "ok")

    updated_turn = turn |> Map.put(:target, player)

    {:ok, updated_turn, player}
  end

  def get_action_success_next_turn(turn, "1coin") do
    {:ok, turn |> Map.put(:state, "ended")}
  end

  def get_action_success_next_turn(turn, _) do
    {:ok, turn}
  end
end
