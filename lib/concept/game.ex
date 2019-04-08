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
    step(state_data.next_step, state_data) |> reply_success(:ok)
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
      players: [
        %{name: "Penguin", session_id: "session1", role: "creator", hand: [], classes: "player"},
        %{name: "Giraffe", session_id: "session2", role: "player", hand: [], classes: "player"},
        %{
          name: "<pending>",
          session_id: nil,
          role: "player",
          hand: [],
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
        %{name: "Penguin", session_id: "session1", role: "creator", hand: [], classes: "player"},
        %{name: "Giraffe", session_id: "session2", role: "player", hand: [], classes: "player"},
        %{name: "Monkey", session_id: "session3", role: "player", hand: [], classes: "player"},
        %{
          name: "<pending>",
          session_id: nil,
          role: "player",
          hand: [],
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
        %{name: "Penguin", session_id: "session1", role: "creator", hand: [], classes: "player"},
        %{name: "Giraffe", session_id: "session2", role: "player", hand: [], classes: "player"},
        %{name: "Monkey", session_id: "session3", role: "player", hand: [], classes: "player"},
        %{name: "Gorilla", session_id: "session4", role: "player", hand: [], classes: "player"},
        %{
          name: "<pending>",
          session_id: nil,
          role: "player",
          hand: [],
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
        %{name: "Penguin", session_id: "session1", role: "creator", hand: [], classes: "player"},
        %{name: "Giraffe", session_id: "session2", role: "player", hand: [], classes: "player"},
        %{name: "Monkey", session_id: "session3", role: "player", hand: [], classes: "player"},
        %{name: "Gorilla", session_id: "session4", role: "player", hand: [], classes: "player"},
        %{name: "SeaLion", session_id: "session5", role: "player", hand: [], classes: "player"},
        %{
          name: "<pending>",
          session_id: nil,
          role: "player",
          hand: [],
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
        %{name: "Penguin", session_id: "session1", role: "creator", hand: [], classes: "player"},
        %{name: "Giraffe", session_id: "session2", role: "player", hand: [], classes: "player"},
        %{name: "Monkey", session_id: "session3", role: "player", hand: [], classes: "player"},
        %{name: "Gorilla", session_id: "session4", role: "player", hand: [], classes: "player"},
        %{name: "SeaLion", session_id: "session5", role: "player", hand: [], classes: "player"},
        %{name: "Bear", session_id: "session6", role: "player", hand: [], classes: "player"}
      ]
    })
  end

  defp step(:addcard1, state) do
    state
    |> Map.merge(%{
      next_step: :addcard2,
      players: [
        %{
          name: "Penguin",
          session_id: "session1",
          role: "creator",
          hand: [
            %{type: "Captain"}
          ],
          classes: "player"
        },
        %{name: "Giraffe", session_id: "session2", role: "player", hand: [], classes: "player"},
        %{name: "Monkey", session_id: "session3", role: "player", hand: [], classes: "player"},
        %{name: "Gorilla", session_id: "session4", role: "player", hand: [], classes: "player"},
        %{name: "SeaLion", session_id: "session5", role: "player", hand: [], classes: "player"},
        %{name: "Bear", session_id: "session6", role: "player", hand: [], classes: "player"}
      ]
    })
  end

  defp step(:addcard2, state) do
    state
    |> Map.merge(%{
      next_step: :addcard3,
      players: [
        %{
          name: "Penguin",
          session_id: "session1",
          role: "creator",
          hand: [
            %{type: "Captain"},
            %{type: "Contessa"}
          ],
          classes: "player"
        },
        %{name: "Giraffe", session_id: "session2", role: "player", hand: [], classes: "player"},
        %{name: "Monkey", session_id: "session3", role: "player", hand: [], classes: "player"},
        %{name: "Gorilla", session_id: "session4", role: "player", hand: [], classes: "player"},
        %{name: "SeaLion", session_id: "session5", role: "player", hand: [], classes: "player"},
        %{name: "Bear", session_id: "session6", role: "player", hand: [], classes: "player"}
      ]
    })
  end

  defp step(:addcard3, state) do
    state
    |> Map.merge(%{
      next_step: :addcard4,
      players: [
        %{
          name: "Penguin",
          session_id: "session1",
          role: "creator",
          hand: [
            %{type: "Captain"},
            %{type: "Contessa"}
          ],
          classes: "player"
        },
        %{
          name: "Giraffe",
          session_id: "session2",
          role: "player",
          hand: [
            %{type: "Captain"},
            %{type: "Contessa"}
          ],
          classes: "player"
        },
        %{name: "Monkey", session_id: "session3", role: "player", hand: [], classes: "player"},
        %{name: "Gorilla", session_id: "session4", role: "player", hand: [], classes: "player"},
        %{name: "SeaLion", session_id: "session5", role: "player", hand: [], classes: "player"},
        %{name: "Bear", session_id: "session6", role: "player", hand: [], classes: "player"}
      ]
    })
  end

  defp state_template(map_to_merge \\ %{}) do
    %{
      game_name: "CONCEPT1",
      next_step: :adduser1,
      players: [
        %{name: "Penguin", session_id: "session1", role: "creator", hand: [], classes: "player"},
        %{
          name: "<pending>",
          session_id: nil,
          role: "player",
          hand: [],
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
      state: "init"
    }
    |> Map.merge(map_to_merge)
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
