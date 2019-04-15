defmodule CoupEngine.Turn do
  @moduledoc """
  One player's turn in the game
  """
  defstruct [:player, :action, :target, :target_response, :player_response_to_target]

  def initialize do
    %{
      player: %{state: "pending"},
      action: %{state: "pending"},
      target: %{state: "pending"},
      target_response: %{state: "pending"},
      player_response_to_target: %{state: "pending"}
    }
  end
end
