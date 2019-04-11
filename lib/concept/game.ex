defmodule Concept.Game do
  @moduledoc """
  This Genserver encapsulates a single game of Coup.
  """

  # Child spec for supervisor
  # , start: {__MODULE__, :start_link, []}, restart: :transient
  use GenServer

  def start_link({game_name, session_id, player_name}) do
    GenServer.start_link(__MODULE__, {game_name, session_id, player_name},
      name: via_tuple(game_name)
    )
  end

  def via_tuple(name), do: {:via, Registry, {Registry.Game, name}}

  def add_player(game, session_id, player_name),
    do: GenServer.call(game, {:add_player, session_id, player_name})

  def get_game_data(game), do: GenServer.call(game, :get_game_data)

  def next_step(game), do: GenServer.call(game, :next_step)

  ### SERVER ###

  @spec init({String.t(), String.t(), String.t()}) :: {:ok, map()}
  def init({game_name, _session_id, _player_name}) do
    {:ok, state_template(%{game_name: game_name})}
  end

  def handle_call(:get_game_data, _from, state_data) do
    state_data |> reply_success(state_data)
  end

  def handle_call(:next_step, _from, state_data) do
    Phoenix.PubSub.broadcast(:game_pubsub, state_data.game_name, :state_updated)
    state_data.next_step |> step(state_data) |> reply_success(:ok)
  end

  ### SERVER UTILITIES

  defp reply_success(state_data, reply) do
    {:reply, reply, state_data}
  end

  ### PRIVATE

  # defp session_id_does_not_exist(session_id, players) do
  #   case Enum.find(players, fn player -> player.session_id == session_id end) do
  #     nil -> :ok
  #     _found -> {:error, "player exists"}
  #   end
  # end

  defp step(:adduser1, state) do
    state
    |> Map.merge(%{
      next_step: :adduser2,
      toast: [
        %{body: "Waiting for players", classes: "fadeOutUp animated exiting"},
        %{body: "Giraffe has joined.", classes: "fadeInUp animated"}
      ],
      players: [
        %{
          name: "Penguin",
          session_id: "session1",
          role: "creator",
          hand: [],
          coins: 0,
          classes: "player"
        },
        %{
          name: "Giraffe",
          session_id: "session2",
          role: "player",
          hand: [],
          coins: 0,
          classes: "player"
        },
        %{
          name: "<pending>",
          session_id: nil,
          role: "player",
          hand: [],
          coins: 0,
          classes: "player collapsed"
        }
      ]
    })
  end

  defp step(:adduser2, state) do
    state
    |> Map.merge(%{
      next_step: :adduser3,
      players: [
        %{
          name: "Penguin",
          session_id: "session1",
          role: "creator",
          hand: [],
          coins: 0,
          classes: "player"
        },
        %{
          name: "Giraffe",
          session_id: "session2",
          role: "player",
          hand: [],
          coins: 0,
          classes: "player"
        },
        %{
          name: "Zebra",
          session_id: "session3",
          role: "player",
          hand: [],
          coins: 0,
          classes: "player"
        },
        %{
          name: "<pending>",
          session_id: nil,
          role: "player",
          hand: [],
          coins: 0,
          classes: "player collapsed"
        }
      ]
    })
  end

  defp step(:adduser3, state) do
    state
    |> Map.merge(%{
      next_step: :adduser4,
      players: [
        %{
          name: "Penguin",
          session_id: "session1",
          role: "creator",
          hand: [],
          coins: 0,
          classes: "player"
        },
        %{
          name: "Giraffe",
          session_id: "session2",
          role: "player",
          hand: [],
          coins: 0,
          classes: "player"
        },
        %{
          name: "Zebra",
          session_id: "session3",
          role: "player",
          hand: [],
          coins: 0,
          classes: "player"
        },
        %{
          name: "Gorilla",
          session_id: "session4",
          role: "player",
          hand: [],
          coins: 0,
          classes: "player"
        },
        %{
          name: "<pending>",
          session_id: nil,
          role: "player",
          hand: [],
          coins: 0,
          classes: "player collapsed"
        }
      ]
    })
  end

  defp step(:adduser4, state) do
    state
    |> Map.merge(%{
      next_step: :adduser5,
      players: [
        %{
          name: "Penguin",
          session_id: "session1",
          role: "creator",
          hand: [],
          coins: 0,
          classes: "player"
        },
        %{
          name: "Giraffe",
          session_id: "session2",
          role: "player",
          hand: [],
          coins: 0,
          classes: "player"
        },
        %{
          name: "Zebra",
          session_id: "session3",
          role: "player",
          hand: [],
          coins: 0,
          classes: "player"
        },
        %{
          name: "Gorilla",
          session_id: "session4",
          role: "player",
          hand: [],
          coins: 0,
          classes: "player"
        },
        %{
          name: "SeaLion",
          session_id: "session5",
          role: "player",
          hand: [],
          coins: 0,
          classes: "player"
        },
        %{
          name: "<pending>",
          session_id: nil,
          role: "player",
          hand: [],
          coins: 0,
          classes: "player collapsed"
        }
      ]
    })
  end

  defp step(:adduser5, state) do
    state
    |> Map.merge(%{
      next_step: :addcard1,
      players: [
        %{
          name: "Penguin",
          session_id: "session1",
          role: "creator",
          hand: [],
          coins: 0,
          classes: "player"
        },
        %{
          name: "Giraffe",
          session_id: "session2",
          role: "player",
          hand: [],
          coins: 0,
          classes: "player"
        },
        %{
          name: "Zebra",
          session_id: "session3",
          role: "player",
          hand: [],
          coins: 0,
          classes: "player"
        },
        %{
          name: "Gorilla",
          session_id: "session4",
          role: "player",
          hand: [],
          coins: 0,
          classes: "player"
        },
        %{
          name: "SeaLion",
          session_id: "session5",
          role: "player",
          hand: [],
          coins: 0,
          classes: "player"
        },
        %{
          name: "Bear",
          session_id: "session6",
          role: "player",
          hand: [],
          coins: 0,
          classes: "player"
        }
      ]
    })
  end

  defp step(:addcard1, state) do
    state
    |> Map.merge(%{
      next_step: :addcard2,
      current_player: %{
        name: "Penguin",
        session_id: "session1",
        role: "creator",
        actions: default_actions,
        actions_panel_mode: "actions_disabled",
        display_state: "default",
        hand: [
          %{type: "Captain"}
        ],
        coins: 0,
        classes: "player"
      },
      players: [
        %{
          name: "Penguin",
          session_id: "session1",
          role: "creator",
          hand: [
            %{type: "Captain"}
          ],
          coins: 0,
          classes: "player"
        },
        %{
          name: "Giraffe",
          session_id: "session2",
          role: "player",
          hand: [],
          coins: 0,
          classes: "player"
        },
        %{
          name: "Zebra",
          session_id: "session3",
          role: "player",
          hand: [],
          coins: 0,
          classes: "player"
        },
        %{
          name: "Gorilla",
          session_id: "session4",
          role: "player",
          hand: [],
          coins: 0,
          classes: "player"
        },
        %{
          name: "SeaLion",
          session_id: "session5",
          role: "player",
          hand: [],
          coins: 0,
          classes: "player"
        },
        %{
          name: "Bear",
          session_id: "session6",
          role: "player",
          hand: [],
          coins: 0,
          classes: "player"
        }
      ],
      deck: state.deck |> List.delete_at(0)
    })
  end

  defp step(:addcard2, state) do
    state
    |> Map.merge(%{
      next_step: :addcard3,
      current_player: %{
        name: "Penguin",
        session_id: "session1",
        role: "creator",
        actions: default_actions,
        actions_panel_mode: "actions_disabled",
        hand: [
          %{type: "Captain"},
          %{type: "Contessa"}
        ],
        coins: 0,
        classes: "player"
      },
      players: [
        %{
          name: "Penguin",
          session_id: "session1",
          role: "creator",
          hand: [
            %{type: "Captain"},
            %{type: "Contessa"}
          ],
          coins: 0,
          classes: "player"
        },
        %{
          name: "Giraffe",
          session_id: "session2",
          role: "player",
          hand: [],
          coins: 0,
          classes: "player"
        },
        %{
          name: "Zebra",
          session_id: "session3",
          role: "player",
          hand: [],
          coins: 0,
          classes: "player"
        },
        %{
          name: "Gorilla",
          session_id: "session4",
          role: "player",
          hand: [],
          coins: 0,
          classes: "player"
        },
        %{
          name: "SeaLion",
          session_id: "session5",
          role: "player",
          hand: [],
          coins: 0,
          classes: "player"
        },
        %{
          name: "Bear",
          session_id: "session6",
          role: "player",
          hand: [],
          coins: 0,
          classes: "player"
        }
      ]
    })
  end

  defp step(:addcard3, state) do
    state
    |> Map.merge(%{
      next_step: :actions1,
      players: [
        %{
          name: "Penguin",
          session_id: "session1",
          role: "creator",
          hand: [
            %{type: "Captain"},
            %{type: "Contessa"}
          ],
          coins: 0,
          classes: "player"
        },
        %{
          name: "Giraffe",
          session_id: "session2",
          role: "player",
          hand: [
            %{type: "Assassn"},
            %{type: "Contessa"}
          ],
          coins: 0,
          classes: "player"
        },
        %{
          name: "Zebra",
          session_id: "session3",
          role: "player",
          hand: [],
          coins: 0,
          classes: "player"
        },
        %{
          name: "Gorilla",
          session_id: "session4",
          role: "player",
          hand: [],
          coins: 0,
          classes: "player"
        },
        %{
          name: "SeaLion",
          session_id: "session5",
          role: "player",
          hand: [],
          coins: 0,
          classes: "player"
        },
        %{
          name: "Bear",
          session_id: "session6",
          role: "player",
          hand: [],
          coins: 0,
          classes: "player"
        }
      ]
    })
  end

  defp step(:actions1, state) do
    penguin = %{
      name: "Penguin",
      session_id: "session1",
      role: "creator",
      hand: [
        %{type: "Captain"},
        %{type: "Contessa"}
      ],
      display_state: "default",
      actions_panel_mode: "actions",
      actions: [
        %{
          action: "coup",
          label: "Coup",
          state: "disabled"
        },
        %{
          action: "1coin",
          label: "1 coin",
          state: "enabled"
        },
        %{
          action: "foreignaid",
          label: "Foreign Aid",
          state: "enabled"
        },
        %{
          action: "3coins",
          label: "3 coins",
          state: "enabled"
          # show exclamation mark if this is "unsafe" (is a bluff)
        },
        %{
          action: "steal",
          label: "Steal",
          state: "enabled"
        },
        %{
          action: "assassinate",
          label: "Assassinate",
          state: "enabled"
        },
        %{
          action: "changecard",
          label: "Change card",
          state: "enabled"
        }
      ],
      responses: [
        %{
          action: "challenge",
          label: "Challenge",
          state: "disabled"
        },
        %{
          action: "block",
          label: "Block",
          state: "disabled"
        }
      ],
      coins: 0,
      classes: "player"
    }

    players = state.players |> List.replace_at(0, penguin)

    state
    |> Map.merge(%{
      next_step: :actions2,
      current_player: penguin,
      players: players,
      turn: %{
        player: %{state: "ok", name: "Penguin"},
        action: %{state: "thinking", label: nil, action: nil},
        # action: %{state: "pending", label: "Steal", action: "steal"},
        target: %{state: "pending"},
        target_response: %{state: "pending"},
        player_response_to_target: %{state: "pending"}
      }
    })
  end

  defp step(:actions2, state) do
    penguin =
      state.current_player
      |> Map.put(:display_state, "select_target")

    state
    |> Map.merge(%{
      next_step: :actions3,
      current_player: penguin
    })
  end

  defp step(:actions3, state) do
    penguin =
      state.current_player
      |> Map.put(:display_state, "change_card")
      |> Map.put(:change_card_hand, [
        %{type: "Captain", state: "default"},
        %{type: "Contessa", state: "default"},
        %{type: "Duke", state: "default"},
        %{type: "Assassin", state: "default"}
      ])

    state
    |> Map.merge(%{
      next_step: :actions4,
      current_player: penguin
    })
  end

  defp step(:actions4, state) do
    penguin =
      state.current_player
      |> Map.put(:change_card_hand, [
        %{type: "Captain", state: "selected"},
        %{type: "Contessa", state: "default"},
        %{type: "Duke", state: "default"},
        %{type: "Assassin", state: "default"}
      ])

    state
    |> Map.merge(%{
      next_step: :actions5,
      current_player: penguin
    })
  end

  defp step(:actions5, state) do
    penguin =
      state.current_player
      |> Map.put(:change_card_hand, [
        %{type: "Captain", state: "selected"},
        %{type: "Contessa", state: "default"},
        %{type: "Duke", state: "selected"},
        %{type: "Assassin", state: "default"}
      ])

    state
    |> Map.merge(%{
      next_step: :lose_challenge1,
      current_player: penguin
    })
  end

  defp step(:lose_challenge1, state) do
    penguin =
      state.current_player
      |> Map.put(:display_state, "default")
      |> Map.merge(%{
        hand: [
          %{type: "Captain", state: "dead"},
          %{type: "Contessa"}
        ]
      })

    players =
      state.players
      |> List.update_at(0, fn _player ->
        %{
          name: "Penguin",
          session_id: "session1",
          role: "creator",
          hand: [
            %{type: "Captain", state: "dead"},
            %{type: "Contessa"}
          ],
          coins: 0,
          classes: "player"
        }
      end)

    state
    |> Map.merge(%{
      next_step: :lose_challenge2,
      current_player: penguin,
      players: players
    })
  end

  defp state_template(map_to_merge \\ %{}) do
    %{
      game_name: "CONCEPT1",
      next_step: :adduser1,
      toast: [
        %{body: "Waiting for players", classes: "fadeInUp animated"}
      ],
      current_player: %{
        name: "Penguin",
        session_id: "session1",
        role: "creator",
        hand: [],
        change_card_hand: [],
        actions_panel_mode: "actions_disabled",
        display_state: "default",
        actions: default_actions,
        coins: 0,
        classes: "player"
      },
      players: [
        %{
          name: "Penguin",
          session_id: "session1",
          role: "creator",
          hand: [],
          coins: 0,
          classes: "player"
        },
        %{
          name: "<pending>",
          session_id: nil,
          role: "player",
          hand: [],
          coins: 0,
          classes: "player collapsed"
        }
      ],
      deck: [
        %{type: "Captain"},
        %{type: "Captain"},
        %{type: "Contessa"},
        %{type: "Contessa"},
        %{type: "Duke"},
        %{type: "Duke"}
      ],
      turn: %{
        player: %{state: "pending"},
        action: %{state: "pending", label: nil, action: nil},
        target: %{state: "pending"},
        target_response: %{state: "pending"},
        player_response_to_target: %{state: "pending"}
      },
      state: "init"
    }
    |> Map.merge(map_to_merge)
  end

  defp default_actions do
    [
      %{
        action: "coup",
        label: "Coup",
        state: "disabled"
      },
      %{
        action: "1coin",
        label: "1 coin",
        state: "disabled"
      },
      %{
        action: "foreignaid",
        label: "Foreign Aid",
        state: "disabled"
      },
      %{
        action: "3coins",
        label: "3 coins",
        state: "disabled"
        # show exclamation mark if this is "unsafe" (is a bluff)
      },
      %{
        action: "steal",
        label: "Steal",
        state: "disabled"
      },
      %{
        action: "assassinate",
        label: "Assassinate",
        state: "disabled"
      },
      %{
        action: "changecard",
        label: "Change card",
        state: "disabled"
      }
    ]
  end
end

# def handle_call({:add_player, session_id, player_name}, _from, %{players: players} = state_data) do
#   # with {:ok, rules} <- Rules.check(state_data.rules, :add_player, length(players)),
#   with :ok <- session_id_does_not_exist(session_id, players) do
#     updated_players =
#       players ++
#         [
#           %{
#             name: player_name,
#             session_id: session_id,
#             role: "player",
#             hand: []
#           }
#         ]
#
#     Phoenix.PubSub.broadcast(:game_pubsub, state_data.game_name, :player_joined)
#
#     state_data
#     |> Map.put(:players, updated_players)
#     |> reply_success(:ok)
#
#     # |> Map.put(:rules, rules)
#   else
#     {:error, reason} -> {:reply, {:error, reason}, state_data}
#   end
# end
