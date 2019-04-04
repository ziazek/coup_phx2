defmodule CoupEngine.Game do
  @moduledoc """
  This Genserver encapsulates a single game of Coup.
  """

  # Child spec for supervisor
  # , start: {__MODULE__, :start_link, []}, restart: :transient
  use GenServer
  alias CoupEngine.{Deck, Player, Rules, Turn}

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
  def get_game_data(game), do: GenServer.call(game, :get_game_data)

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
         %Player{name: player_name, session_id: session_id, role: "creator", hand: []}
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
            %Player{
              name: player_name,
              session_id: session_id,
              role: "player",
              hand: []
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

  def handle_call(:get_game_data, _from, state_data) do
    state_data |> reply_success(state_data)
  end

  def handle_call(:list_players, _from, %{players: players} = state_data) do
    state_data |> reply_success(players)
  end

  def handle_call(:start_game, _from, %{players: players} = state_data) do
    with {:ok, rules} <- Rules.check(state_data.rules, :start_game, length(players)) do
      Process.send_after(self(), :shuffle, 1_000)
      Phoenix.PubSub.broadcast(:game_pubsub, state_data.game_name, :game_started)

      state_data
      |> Map.put(:rules, rules)
      |> reply_success(:ok)
    else
      {:error, reason} -> {:reply, {:error, reason}, state_data}
    end
  end

  def handle_call({:attempt_action, action}, _from, %{turn: turn, players: players} = state_data) do
    do_attempt_action(action, turn, players, state_data)
  end

  def handle_call(
        {:attempt_action, action, target_player_index},
        _from,
        %{turn: turn, players: players} = state_data
      ) do
    do_attempt_action(action, turn, players, state_data, target_player_index)
  end

  def handle_info(:shuffle, %{deck: deck} = state_data) do
    with {:ok, rules} <- Rules.check(state_data.rules, :shuffle) do
      Phoenix.PubSub.broadcast(:game_pubsub, state_data.game_name, :deck_shuffled)
      Process.send_after(self(), {:draw_card, 0}, 1_000)

      updated_state_data =
        state_data
        |> Map.put(:deck, Enum.shuffle(deck))
        |> Map.put(:rules, rules)

      {:noreply, updated_state_data}
    else
      {:error, _reason} -> {:noreply, state_data}
    end
  end

  def handle_info({:draw_card, player_index}, %{players: players, deck: deck} = state_data) do
    with {:ok, rules} <- Rules.check(state_data.rules, :draw_card),
         {:ok, card, deck_rem} <- Deck.draw_top_card(deck),
         {:ok, player, players} <- Player.add_to_hand(players, player_index, card),
         {:ok, rules} <- Rules.check_cards_drawn(rules, players) do
      next_player_draw_card(rules, players, player_index)
      Phoenix.PubSub.broadcast(:game_pubsub, state_data.game_name, {:card_drawn, player})

      updated_state_data =
        state_data
        |> Map.put(:deck, deck_rem)
        |> Map.put(:players, players)
        |> Map.put(:rules, rules)

      {:noreply, updated_state_data}
    else
      {:error, _reason} -> {:noreply, state_data}
    end
  end

  def handle_info({:start_turn, player_index}, %{players: players} = state_data) do
    with {:ok, rules} <- Rules.check(state_data.rules, :start_turn) do
      updated_state_data =
        state_data
        |> Map.put(:turn, Turn.build(players, player_index))
        |> Map.put(:rules, rules)

      {:noreply, updated_state_data}
    else
      {:error, _reason} -> {:noreply, state_data}
    end
  end

  ### SERVER UTILITIES

  defp reply_success(state_data, reply) do
    {:reply, reply, state_data}
  end

  ### PRIVATE

  defp do_attempt_action(action, turn, players, state_data, target_player_index \\ nil) do
    with {:ok, rules} <- Rules.check(state_data.rules, :attempt_action, action),
         {:ok, character} <- Turn.get_claimed_character(action),
         :ok <- Turn.check_coins(action, turn.player.coins),
         {:ok, updated_player} <- Turn.deduct_coins_for_attempted_action(turn.player, action) do
      Phoenix.PubSub.broadcast(:game_pubsub, state_data.game_name, :action_attempted)

      turn =
        turn
        |> Map.put(:action, action)
        |> Map.put(:claimed_character, character)
        |> Map.put(:player, updated_player)
        |> Map.put(:target_player_index, target_player_index)

      players = List.replace_at(players, turn.player_index, updated_player)

      state_data
      |> Map.put(:turn, turn)
      |> Map.put(:players, players)
      |> Map.put(:rules, rules)
      |> reply_success(:ok)
    else
      {:error, reason} -> {:reply, {:error, reason}, state_data}
      _ -> {:reply, :error, state_data}
    end
  end

  defp session_id_does_not_exist(session_id, players) do
    case Enum.find(players, fn player -> player.session_id == session_id end) do
      nil -> :ok
      _found -> {:error, "player exists"}
    end
  end

  defp next_player_draw_card(%Rules{state: :drawing_cards}, players, player_index) do
    next_index = if player_index == length(players) - 1, do: 0, else: player_index + 1

    Process.send_after(self(), {:draw_card, next_index}, 1_000)
  end

  defp next_player_draw_card(_, _, _), do: :do_nothing
end
