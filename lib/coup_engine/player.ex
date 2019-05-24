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
            # select_target, lose_influence_select_card, awaiting_opponent_response
            display_state: "default",
            actions: [],
            responses: [],
            state: nil

  alias __MODULE__
  alias CoupEngine.{Actions, Card}

  @spec initialize(String.t(), String.t(), map()) :: %__MODULE__{}
  def initialize(session_id, player_name, attrs) do
    %Player{
      session_id: session_id,
      name: player_name,
      actions: Actions.default_actions(),
      responses: Actions.default_responses()
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

  @spec get_live_cards(%Player{}) :: [%Card{}]
  def get_live_cards(player) do
    player.hand |> Enum.filter(fn card -> card.state != "dead" end)
  end

  ### PRIVATE

  defp get_player(players, player_index) do
    players |> Enum.at(player_index)
  end
end
