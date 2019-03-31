defmodule CoupEngine.Game do
  @moduledoc """
  This Genserver encapsulates a single game of Coup.
  """

  # Child spec for supervisor
  use GenServer, start: {__MODULE__, :start_link, []}, restart: :transient
  alias CoupEngine.Rules

  ### CLIENT ###

  def start_link({game_name, session_id, player_name}) do
    GenServer.start_link(__MODULE__, {game_name, session_id, player_name},
      name: via_tuple(game_name)
    )
  end

  def via_tuple(name), do: {:via, Registry, {Registry.Game, name}}

  def add_player(game, session_id, player_name),
    do: GenServer.call(game, {:add_player, session_id, player_name})

  def list_players(game),
    do: GenServer.call(game, :list_players)

  ### SERVER ###

  @spec init({String.t(), String.t(), String.t()}) :: {:ok, map()}
  def init({game_name, session_id, player_name}) do
    {:ok,
     %{
       game_name: game_name,
       players: [
         %{name: player_name, session_id: session_id, role: "creator"}
       ],
       deck: [],
       discard: [],
       rules: %Rules{state: :adding_players}
     }}
  end

  @spec handle_call({:add_player, String.t(), String.t()}, any(), map()) ::
          {:reply, :ok | :error, map()}
  def handle_call({:add_player, session_id, player_name}, _from, %{players: players} = state_data) do
    with {:ok, rules} <- Rules.check(state_data.rules, :add_player, length(players)) do
      # TODO: don't add if the session_id exists
      updated_players =
        players ++
          [
            %{
              name: player_name,
              session_id: session_id,
              role: "player"
            }
          ]

      Phoenix.PubSub.broadcast(:game_pubsub, state_data.game_name, :player_joined)

      state_data
      |> Map.put(:players, updated_players)
      |> Map.put(:rules, rules)
      |> reply_success(:ok)
    else
      {:error, reason} -> {:reply, {:error, reason}, state_data}
    end
  end

  # TODO: test this
  def handle_call(:list_players, _from, %{players: players} = state_data) do
    state_data |> reply_success(%{players: players})
  end

  def handle_call(:start_game, _from, %{players: players} = state_data) do
    with {:ok, rules} <- Rules.check(state_data.rules, :start_game, length(players)) do
      # TODO: send to self
      # Process.send_after(self(), :shuffle_deck, 1_000)
      # then handle_info
      state_data
      |> Map.put(:rules, rules)
      |> reply_success(:ok)
    else
      {:error, reason} -> {:reply, {:error, reason}, state_data}
    end
  end

  defp reply_success(state_data, reply) do
    {:reply, reply, state_data}
  end
end
