defmodule CoupEngine.Player do
  defstruct role: "player", name: "Player", session_id: nil, hand: [], coins: 0

  @moduledoc """
  Player functions
  """

  def add_to_hand(players, player_index, card) do
    player =
      players
      |> Enum.at(player_index)

    hand = player.hand ++ [card]

    player = player |> Map.put(:hand, hand)

    players = players |> List.replace_at(player_index, player)

    {:ok, player, players}
  end
end
