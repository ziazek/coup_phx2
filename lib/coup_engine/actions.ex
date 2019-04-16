defmodule CoupEngine.Actions do
  @moduledoc """
  Generates lists of actions, responses
  """

  alias CoupEngine.Action

  @actions %{
    "1coin" => %{
      claimed_character: nil,
      description: "took one coin."
    }
  }

  @spec get_claimed_character(String.t()) :: {:ok, nil | String.t()}
  def get_claimed_character(action) do
    character =
      @actions
      |> Map.get(action)
      |> Map.get(:claimed_character)

    {:ok, character}
  end

  @spec get_description(String.t()) :: {:ok, nil | String.t()}
  def get_description(action) do
    description =
      @actions
      |> Map.get(action)
      |> Map.get(:description)

    {:ok, description}
  end

  @spec get_turn_action(String.t()) :: {:ok, %Action{}}
  def get_turn_action(action) do
    turn_action =
      default_actions()
      |> Enum.find(fn a -> a.action == action end)
      |> Map.put(:state, "ok")

    {:ok, turn_action}
  end

  @spec enable_actions_for_coins(non_neg_integer()) :: [%Action{}]
  def enable_actions_for_coins(coins) do
    default_actions()
    |> Enum.map(fn action ->
      action |> Map.put(:state, "enabled")
    end)
  end

  @spec default_actions() :: [%Action{}]
  def default_actions do
    [
      %Action{
        action: "coup",
        label: "Coup",
        state: "disabled"
      },
      %Action{
        action: "1coin",
        label: "1 coin",
        state: "disabled"
      },
      %Action{
        action: "foreignaid",
        label: "Foreign Aid",
        state: "disabled"
      },
      %Action{
        action: "3coins",
        label: "3 coins",
        state: "disabled"
      },
      %Action{
        action: "steal",
        label: "Steal",
        state: "disabled"
      },
      %Action{
        action: "assassinate",
        label: "Assassinate",
        state: "disabled"
      },
      %Action{
        action: "changecard",
        label: "Change card",
        state: "disabled"
      }
    ]
  end

  @spec default_responses() :: [%Action{}]
  def default_responses do
    [
      %Action{
        action: "challenge",
        label: "Challenge",
        state: "disabled"
      },
      %Action{
        action: "block",
        label: "Block",
        state: "disabled"
      }
    ]
  end
end
