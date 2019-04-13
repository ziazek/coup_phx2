defmodule CoupEngine.Player do
  @moduledoc """
  A player
  """

  defstruct name: "<set name>",
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
  alias CoupEngine.ActionFactory

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
end
