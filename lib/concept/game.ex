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

  ### SERVER ###

  @spec init({String.t(), String.t(), String.t()}) :: {:ok, map()}
  def init({game_name, session_id, player_name}) do
    {:ok,
     %{
       game_name: game_name,
       players: [
         %{name: player_name, session_id: session_id, role: "creator", hand: []}
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
     }}
  end

  def handle_call({:add_player, session_id, player_name}, _from, %{players: players} = state_data) do
    # with {:ok, rules} <- Rules.check(state_data.rules, :add_player, length(players)),
    with :ok <- session_id_does_not_exist(session_id, players) do
      updated_players =
        players ++
          [
            %{
              name: player_name,
              session_id: session_id,
              role: "player",
              hand: []
            }
          ]

      Phoenix.PubSub.broadcast(:game_pubsub, state_data.game_name, :player_joined)

      state_data
      |> Map.put(:players, updated_players)
      |> reply_success(:ok)

      # |> Map.put(:rules, rules)
    else
      {:error, reason} -> {:reply, {:error, reason}, state_data}
    end
  end

  def handle_call(:get_game_data, _from, state_data) do
    state_data |> reply_success(state_data)
  end

  ### SERVER UTILITIES

  defp reply_success(state_data, reply) do
    {:reply, reply, state_data}
  end

  ### PRIVATE

  defp session_id_does_not_exist(session_id, players) do
    case Enum.find(players, fn player -> player.session_id == session_id end) do
      nil -> :ok
      _found -> {:error, "player exists"}
    end
  end
end
