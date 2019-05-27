defmodule CoupEngine.Actions do
  @moduledoc """
  Generates lists of actions, responses
  """

  alias CoupEngine.Action

  @must_coup_at 10

  @actions %{
    "1coin" => %{
      claimed_character: nil,
      description: "chose TAKE ONE COIN.",
      cost: 0
    },
    "foreignaid" => %{
      claimed_character: nil,
      description: "chose FOREIGN AID.",
      cost: 0
    },
    "coup" => %{
      claimed_character: nil,
      description: "chose COUP. Selecting target...",
      cost: 7
    },
    "steal" => %{
      claimed_character: "Captain",
      description: "chose STEAL. Selecting target...",
      cost: 0
    },
    "3coins" => %{
      claimed_character: "Duke",
      description: "chose TAKE 3 COINS. (Claims DUKE)",
      cost: 0
    },
    "assassinate" => %{
      claimed_character: "Assassin",
      description: "chose ASSASSINATE. Selecting target...",
      cost: 3
    },
    "changecard" => %{
      claimed_character: "Ambassador",
      description: "chose CHANGE CARD.",
      cost: 0
    }
  }

  @blocks %{
    "block_as_duke" => %{
      action: %Action{
        action: "block_as_duke",
        label: "Block as Duke",
        state: "ok"
      },
      claimed_character: "Duke"
    },
    "block_as_captain" => %{
      action: %Action{
        action: "block_as_captain",
        label: "Block as Captain",
        state: "ok"
      },
      claimed_character: "Captain"
    },
    "block_as_ambassador" => %{
      action: %Action{
        action: "block_as_ambassador",
        label: "Block as Ambassador",
        state: "ok"
      },
      claimed_character: "Ambassador"
    },
    "block_as_contessa" => %{
      action: %Action{
        action: "block_as_contessa",
        label: "Block as Contessa",
        state: "ok"
      },
      claimed_character: "Contessa"
    }
  }

  @spec allow_block_action() :: %Action{}
  def allow_block_action do
    %Action{
      action: "allow",
      label: "Allow",
      state: "ok"
    }
  end

  @spec challenge_block_action() :: %Action{}
  def challenge_block_action do
    %Action{
      action: "challenge_block",
      label: "Challenge",
      state: "ok"
    }
  end

  @spec get_block_action(String.t()) :: {:ok, %Action{}}
  def get_block_action(block_name) do
    block_action =
      @blocks
      |> Map.get(block_name)
      |> Map.get(:action)

    {:ok, block_action}
  end

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

  @spec get_cost(String.t()) :: {:ok, pos_integer()}
  def get_cost(action) do
    cost =
      @actions
      |> Map.get(action)
      |> Map.get(:cost)

    {:ok, cost}
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
  def enable_actions_for_coins(coins) when coins >= 10 do
    default_actions()
    |> Enum.map(fn action ->
      if action.action == "coup" do
        action |> Map.put(:state, "enabled")
      else
        action
      end
    end)
  end

  def enable_actions_for_coins(coins) do
    default_actions()
    |> Enum.map(fn action ->
      if coins >= @actions[action.action].cost do
        action |> Map.put(:state, "enabled")
      else
        action
      end
    end)
  end

  def get_select_target_description("coup", player_name, target_player_name) do
    {:ok, "#{player_name} COUPS #{target_player_name}."}
  end

  def get_select_target_description("steal", player_name, target_player_name) do
    {:ok, "#{player_name} STEALS from #{target_player_name}."}
  end

  def get_select_target_description("assassinate", player_name, target_player_name) do
    {:ok, "#{player_name} ASSASSINATES #{target_player_name}."}
  end

  def get_select_target_description(_, _, _), do: {:error, "Invalid action, cannot describe"}

  def get_action_success_description("1coin", player_name, _target_name) do
    {:ok, "#{player_name} received 1 coin."}
  end

  def get_action_success_description("foreignaid", player_name, _target_name) do
    {:ok, "#{player_name} received 2 coins."}
  end

  def get_action_success_description("steal", player_name, target_name) do
    {:ok, "#{player_name} stole 2 coins from #{target_name}."}
  end

  def get_action_success_description("3coins", player_name, _target_name) do
    {:ok, "#{player_name} took 3 coins."}
  end

  def get_action_success_description("coup", _player_name, _target_name) do
    {:ok, "COUP is successful."}
  end

  def get_action_success_description("assassinate", _player_name, _target_name) do
    {:ok, "ASSASSINATION is successful."}
  end

  def get_action_success_description("changecard", player_name, _target_name) do
    {:ok, "#{player_name} draws the top 2 cards. Selecting..."}
  end

  def get_action_success_description(_, _, _), do: {:error, "Invalid action, cannot describe"}

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
        label: "Change Card",
        state: "disabled"
      }
    ]
  end

  @spec default_responses() :: [%Action{}]
  def default_responses do
    [
      %Action{
        action: "allow",
        label: "Allow",
        state: "disabled"
      },
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

  @spec opponent_responses_for(String.t()) :: [%Action{}]
  def opponent_responses_for("foreignaid") do
    [
      %Action{
        action: "allow",
        label: "Allow",
        state: "enabled"
      },
      %Action{
        action: "challenge",
        label: "Challenge",
        state: "disabled"
      },
      %Action{
        action: "block_as_duke",
        label: "Block as Duke",
        state: "enabled"
      }
    ]
  end

  def opponent_responses_for("3coins") do
    [
      %Action{
        action: "allow",
        label: "Allow",
        state: "enabled"
      },
      %Action{
        action: "challenge",
        label: "Challenge",
        state: "enabled"
      }
    ]
  end

  def opponent_responses_for("changecard") do
    [
      %Action{
        action: "allow",
        label: "Allow",
        state: "enabled"
      },
      %Action{
        action: "challenge",
        label: "Challenge",
        state: "enabled"
      }
    ]
  end

  def opponent_responses_for(_), do: default_responses()

  def target_selected_target_responses_for("steal") do
    [
      %Action{
        action: "allow",
        label: "Allow",
        state: "enabled"
      },
      %Action{
        action: "challenge",
        label: "Challenge",
        state: "enabled"
      },
      %Action{
        action: "block_as_ambassador",
        label: "Block as Ambassador",
        state: "enabled"
      },
      %Action{
        action: "block_as_captain",
        label: "Block as Captain",
        state: "enabled"
      }
    ]
  end

  def target_selected_target_responses_for("assassinate") do
    [
      %Action{
        action: "allow",
        label: "Allow",
        state: "enabled"
      },
      %Action{
        action: "challenge",
        label: "Challenge",
        state: "enabled"
      },
      %Action{
        action: "block_as_contessa",
        label: "Block as Contessa",
        state: "enabled"
      }
    ]
  end

  def target_selected_target_responses_for(_action), do: []

  def target_selected_opponent_responses_for("steal") do
    [
      %Action{
        action: "allow",
        label: "Allow",
        state: "enabled"
      },
      %Action{
        action: "challenge",
        label: "Challenge",
        state: "enabled"
      }
    ]
  end

  def target_selected_opponent_responses_for("assassinate") do
    [
      %Action{
        action: "allow",
        label: "Allow",
        state: "enabled"
      },
      %Action{
        action: "challenge",
        label: "Challenge",
        state: "enabled"
      }
    ]
  end

  def target_selected_opponent_responses_for(_action), do: []

  @spec player_responses_to_block() :: [%Action{}]
  def player_responses_to_block do
    [
      %Action{
        action: "allow_block",
        label: "Allow",
        state: "enabled"
      },
      %Action{
        action: "challenge_block",
        label: "Challenge",
        state: "enabled"
      }
    ]
  end
end
