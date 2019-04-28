defmodule CoupEngine.Challenge do
  @moduledoc """
  Determines if a challenge is successful or not.

  Challenge can be on an action or on a block.
  """

  alias CoupEngine.Player

  @doc """
  Checks a player's hand to find if the claimed character exists
  """
  @spec challenge_block([%Player{}], String.t(), String.t()) :: {:ok, boolean()}
  def challenge_block(players, session_id, claimed_character) do
    player = players |> Enum.find(fn p -> p.session_id == session_id end)

    live_characters =
      player.hand
      |> Enum.filter(fn card -> card.state != "dead" end)
      |> Enum.map(fn card -> card.type end)

    IO.inspect(live_characters, label: "live_characters")

    block_success = live_characters |> Enum.member?(claimed_character)

    {:ok, !block_success}
  end
end
