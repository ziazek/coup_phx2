defmodule CoupEngine.Game do
  @moduledoc """
  This Genserver encapsulates a single game of Coup.
  """

  use GenServer

  alias CoupEngine.{Deck, Player, GameStateMachine, Toast, Turn}

  @pubsub Application.get_env(:coup_phx2, :game_pubsub)
  @process Application.get_env(:coup_phx2, :game_process)

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

  @spec start_game(pid()) :: any()
  def start_game(pid), do: GenServer.call(pid, :start_game)

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
       ],
       turn: Turn.initialize()
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
  def handle_call(
        {:add_player, session_id, name},
        _from,
        %{players: players, toast: toast} = state_data
      ) do
    with {:ok, next_state} <-
           GameStateMachine.check(state_data.state, :add_player, length(players)),
         :ok <- session_id_does_not_exist(session_id, players) do
      players =
        players ++
          [
            Player.initialize(session_id, name, %{role: "player"})
          ]

      toast = toast |> Toast.add("#{name} has joined the game.")

      state_data
      |> Map.put(:players, players)
      |> Map.put(:toast, toast)
      |> Map.put(:state, next_state)
      |> reply_success(:ok, :broadcast_change)
    else
      error -> {:reply, error, state_data}
    end
  end

  @spec handle_call(:start_game, any(), map()) :: {:reply, :ok | :error, map()}
  def handle_call(:start_game, _from, %{players: players, toast: toast} = state_data) do
    with {:ok, next_state} <-
           GameStateMachine.check(state_data.state, :start_game, length(players)) do
      toast = toast |> Toast.add("Game is starting. Shuffling deck...")

      @process.send_after(self(), :shuffle, 1000)

      state_data
      |> Map.put(:toast, toast)
      |> Map.put(:state, next_state)
      |> reply_success(:ok, :broadcast_change)
    else
      error -> {:reply, error, state_data}
    end
  end

  @spec handle_continue(:broadcast_change, map()) :: {:noreply, map()}
  def handle_continue(:broadcast_change, %{game_name: game_name} = state) do
    @pubsub.broadcast(:game_pubsub, game_name, :game_data_changed)
    {:noreply, state}
  end

  @spec handle_info(:shuffle, map()) :: {:noreply, map()} | {:noreply, map(), {:continue, atom()}}
  def handle_info(:shuffle, %{deck: deck, toast: toast} = state_data) do
    with {:ok, next_state} <- GameStateMachine.check(state_data.state, :shuffle) do
      @process.send_after(self(), {:draw_card, 0}, 1000)

      toast = toast |> Toast.add("Deck shuffled.")

      state_data
      |> Map.put(:deck, Enum.shuffle(deck))
      |> Map.put(:toast, toast)
      |> Map.put(:state, next_state)
      |> noreply(:broadcast_change)
    else
      _error ->
        # FUTURE: show error toast to creator
        {:noreply, state_data}
    end
  end

  @spec handle_info({:draw_card, non_neg_integer()}, map()) ::
          {:noreply, map()} | {:noreply, map(), {:continue, atom()}}
  def handle_info(
        {:draw_card, player_index},
        %{deck: deck, players: players, toast: toast} = state_data
      ) do
    with {:ok, next_state} <- GameStateMachine.check(state_data.state, :draw_card),
         {:ok, card, deck_rem} <- Deck.draw_top_card(deck),
         {:ok, player, players} <- Player.add_to_hand(players, player_index, card),
         {:ok, next_state} <- GameStateMachine.check_cards_drawn(next_state, players) do
      next_player_draw_card(next_state, players, player_index)

      toast =
        if next_state == "cards_drawn" do
          toast |> Toast.add("All players have drawn their cards.")
        else
          toast |> Toast.add("#{player.name} drew a card.")
        end

      state_data
      |> Map.put(:deck, deck_rem)
      |> Map.put(:players, players)
      |> Map.put(:toast, toast)
      |> Map.put(:state, next_state)
      |> noreply(:broadcast_change)
    else
      {:error, reason} ->
        toast = toast |> Toast.add(reason)
        state_data = state_data |> Map.put(:toast, toast)
        {:noreply, state_data}
    end
  end

  ### SERVER UTILITIES

  @spec reply_success(map(), any(), atom()) ::
          {:reply, any(), map()} | {:reply, any(), map(), {:continue, atom()}}
  defp reply_success(state_data, reply, broadcast \\ :no_broadcast) do
    case broadcast do
      :broadcast_change ->
        {:reply, reply, state_data, {:continue, :broadcast_change}}

      _any ->
        {:reply, reply, state_data}
    end
  end

  @spec noreply(map(), atom()) :: {:noreply, map()} | {:noreply, map(), {:continue, atom()}}
  defp noreply(state_data, broadcast \\ :no_broadcast) do
    case broadcast do
      :broadcast_change ->
        {:noreply, state_data, {:continue, :broadcast_change}}

      _any ->
        {:noreply, state_data}
    end
  end

  ### PRIVATE

  defp session_id_does_not_exist(session_id, players) do
    case Enum.find(players, fn player -> player.session_id == session_id end) do
      nil -> :ok
      _found -> {:error, "player exists"}
    end
  end

  defp next_player_draw_card("drawing_cards", players, player_index) do
    next_index = if player_index == length(players) - 1, do: 0, else: player_index + 1

    @process.send_after(self(), {:draw_card, next_index}, 1_000)
  end

  defp next_player_draw_card(_rules, _, _), do: :do_nothing
end
