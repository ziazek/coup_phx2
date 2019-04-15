defmodule CoupEngine.Turn do
  @moduledoc """
  One player's turn in the game
  """
  defstruct [:player, :action, :target, :target_response, :player_response_to_target]

  def initialize do
    %__MODULE__{
      player: %{state: "pending"},
      action: %{state: "pending"},
      target: %{state: "pending"},
      target_response: %{state: "pending"},
      player_response_to_target: %{state: "pending"}
    }
  end

  def build(turn, players, player_index) do
    player = players |> Enum.at(player_index) |> Map.put(:state, "ok")

    updated_turn = turn |> Map.merge(%{player: player})

    {:ok, updated_turn}
  end
end
