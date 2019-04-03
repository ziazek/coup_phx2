defmodule CoupEngine.Game do
  @moduledoc """
  This Genserver encapsulates a single game of Coup.
  """

  # Child spec for supervisor
  # , start: {__MODULE__, :start_link, []}, restart: :transient
  use GenServer
  alias CoupEngine.Deck
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

  def get_player(game, session_id), do: GenServer.call(game, {:get_player, session_id})

  def get_game_state(game), do: GenServer.call(game, :get_game_state)

  def list_players(game),
    do: GenServer.call(game, :list_players)

  def start_game(game), do: GenServer.call(game, :start_game)

  ### SERVER ###

  @spec init({String.t(), String.t(), String.t()}) :: {:ok, map()}
  def init({game_name, session_id, player_name}) do
    {:ok,
     %{
       game_name: game_name,
       players: [
         %{name: player_name, session_id: session_id, role: "creator"}
       ],
       deck: Deck.build(3),
       discard: [],
       rules: %Rules{state: :adding_players}
     }}
  end

  @spec handle_call({:add_player, String.t(), String.t()}, any(), map()) ::
          {:reply, :ok | :error, map()}
  def handle_call({:add_player, session_id, player_name}, _from, %{players: players} = state_data) do
    with {:ok, rules} <- Rules.check(state_data.rules, :add_player, length(players)),
         :ok <- session_id_does_not_exist(session_id, players) do
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

  def handle_call({:get_player, session_id}, _from, %{players: players} = state_data) do
    player = Enum.find(players, fn p -> p.session_id == session_id end)
    state_data |> reply_success(player)
  end

  def handle_call(:get_game_state, _from, %{rules: %Rules{state: state}} = state_data) do
    state_data |> reply_success(state)
  end

  def handle_call(:list_players, _from, %{players: players} = state_data) do
    state_data |> reply_success(players)
  end

  def handle_call(:start_game, _from, %{players: players} = state_data) do
    with {:ok, rules} <- Rules.check(state_data.rules, :start_game, length(players)) do
      # TODO: send to self
      # Process.send_after(self(), :shuffle_deck, 1_000)
      # then handle_info
      Phoenix.PubSub.broadcast(:game_pubsub, state_data.game_name, :game_started)

      state_data
      |> Map.put(:rules, rules)
      |> reply_success(:ok)
    else
      {:error, reason} -> {:reply, {:error, reason}, state_data}
    end
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
