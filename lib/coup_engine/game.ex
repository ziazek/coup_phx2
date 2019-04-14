defmodule CoupEngine.Game do
  @moduledoc """
  This Genserver encapsulates a single game of Coup.
  """

  use GenServer

  alias CoupEngine.{Deck, Player, GameStateMachine, Toast}

  @pubsub Application.get_env(:coup_phx2, :game_pubsub)

  ### CLIENT ###

  @spec start_link({String.t(), String.t(), String.t()}) :: any()
  def start_link({game_name, session_id, player_name}) do
    GenServer.start_link(__MODULE__, {game_name, session_id, player_name},
      name: via_tuple(game_name)
    )
  end

  @spec via_tuple(String.t()) :: {:via, atom(), {atom(), String.t()}}
  def via_tuple(name), do: {:via, Registry, {Registry.Game, name}}

  @spec get_game_data(pid(), String.t()) :: any()
  def get_game_data(pid, session_id), do: GenServer.call(pid, {:get_game_data, session_id})

  @spec add_player(pid(), String.t(), String.t()) :: any()
  def add_player(pid, session_id, name), do: GenServer.call(pid, {:add_player, session_id, name})

  ### SERVER ###

  @spec init({String.t(), String.t(), String.t()}) :: {:ok, map()}
  def init({game_name, session_id, player_name}) do
    {:ok,
     %{
       game_name: game_name,
       players: [
         Player.initialize(session_id, player_name, %{role: "creator"})
       ],
       deck: Deck.build(3),
       state: "adding_players",
       toast: [
         Toast.initialize("Waiting for players")
       ]
     }}
  end

  @spec handle_call({:get_game_data, String.t()}, any(), map()) :: {:reply, map(), map()}
  def handle_call({:get_game_data, session_id}, _from, state_data) do
    current_player = Enum.find(state_data.players, fn p -> p.session_id == session_id end)

    state_data_with_current_player =
      state_data
      |> Map.put(:current_player, current_player)

    {:reply, state_data_with_current_player, state_data}
  end

  @spec handle_call({:add_player, String.t(), String.t()}, any(), map()) ::
          {:reply, :ok | :error, map()}
  def handle_call({:add_player, session_id, name}, _from, %{players: players} = state_data) do
    with {:ok, next_state} <-
           GameStateMachine.check(state_data.state, :add_player, length(players)),
         :ok <- session_id_does_not_exist(session_id, players) do
      players =
        players ++
          [
            Player.initialize(session_id, name, %{role: "player"})
          ]

      state_data
      |> Map.put(:players, players)
      |> reply_success(:ok, :broadcast_change)
    else
      error -> {:reply, error, state_data}
    end
  end

  def handle_continue(:broadcast_change, %{game_name: game_name} = state) do
    @pubsub.broadcast(:game_pubsub, game_name, :game_data_changed)
    {:noreply, state}
  end

  ### SERVER UTILITIES

  defp reply_success(state_data, reply, broadcast \\ :no_broadcast) do
    case broadcast do
      :no_broadcast ->
        {:reply, reply, state_data}

      :broadcast_change ->
        {:reply, reply, state_data, {:continue, :broadcast_change}}
    end
  end

  ### PRIVATE

  defp session_id_does_not_exist(session_id, players) do
    case Enum.find(players, fn player -> player.session_id == session_id end) do
      nil -> :ok
      _found -> {:error, "player exists"}
    end
  end
end
