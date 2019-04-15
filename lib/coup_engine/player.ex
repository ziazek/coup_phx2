defmodule CoupEngine.Player do
  @moduledoc """
  A player
  """

  defstruct name: "<NAME_NOT_SET>",
            role: "player",
            session_id: nil,
            coins: 0,
            hand: [],
            change_card_hand: [],
            actions_panel_mode: "actions_disabled",
            display_state: "default",
            actions: [],
            responses: []

  alias __MODULE__
  alias CoupEngine.{ActionFactory, Card}

  @spec initialize(String.t(), String.t(), map()) :: %__MODULE__{}
  def initialize(session_id, player_name, attrs) do
    %Player{
      session_id: session_id,
      name: player_name,
      actions: ActionFactory.default_actions(),
      responses: ActionFactory.default_responses()
    }
    |> Map.merge(attrs)
  end

  @spec add_to_hand(list(), non_neg_integer(), %Card{}) :: {:ok, %__MODULE__{}, [%__MODULE__{}]}
  def add_to_hand(players, player_index, card) do
    player = get_player(players, player_index)

    player = player |> Map.put(:hand, player.hand ++ [card])

    players = players |> List.replace_at(player_index, player)

    {:ok, player, players}
  end

  ### PRIVATE

  defp get_player(players, player_index) do
    players |> Enum.at(player_index)
  end
end
