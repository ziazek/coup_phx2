defmodule CoupEngine.Game do
  @moduledoc """
  This Genserver encapsulates a single game of Coup.
  """

  use GenServer

  alias CoupEngine.{Actions, Challenge, Deck, GameStateMachine, Player, Players, Toast, Turn}

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

  @spec action(pid(), String.t()) :: any()
  def action(pid, action_name), do: GenServer.call(pid, {:action, action_name})

  @spec select_target(pid(), String.t()) :: any()
  def select_target(pid, session_id), do: GenServer.call(pid, {:select_target, session_id})

  @spec select_card(pid(), String.t(), non_neg_integer()) :: any()
  def select_card(pid, session_id, index),
    do: GenServer.call(pid, {:select_card, session_id, index})

  @spec lose_influence_confirm(pid()) :: any()
  def lose_influence_confirm(pid),
    do: GenServer.call(pid, :lose_influence_confirm)

  @spec allow(pid(), String.t()) :: any()
  def allow(pid, session_id),
    do: GenServer.call(pid, {:allow, session_id})

  @spec block(pid(), String.t(), String.t()) :: any()
  def block(pid, session_id, name),
    do: GenServer.call(pid, {:block, session_id, name})

  @spec allow_block(pid()) :: any()
  def allow_block(pid),
    do: GenServer.call(pid, :allow_block)

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
       turn: Turn.initialize(),
       past_turns: []
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

      @process.send_after(self(), :shuffle, 1_000)

      state_data
      |> Map.put(:toast, toast)
      |> Map.put(:state, next_state)
      |> reply_success(:ok, :broadcast_change)
    else
      error -> {:reply, error, state_data}
    end
  end

  @spec handle_call({:action, String.t()}, any(), map()) ::
          {:noreply, map()} | {:noreply, map(), {:continue, atom()}}
  def handle_call(
        {:action, action},
        _from,
        %{toast: toast, players: players, turn: turn} = state_data
      ) do
    with {:ok, next_state} <- GameStateMachine.check(state_data.state, :action, action),
         {:ok, _claimed_character} <- Actions.get_claimed_character(action),
         {:ok, description} <- Actions.get_description(action),
         {:ok, turn_action} <- Actions.get_turn_action(action),
         {:ok, players} <- Players.set_display_state(players, turn.player.session_id, action),
         {:ok, players} <- Players.set_opponent_responses(players, turn.player.session_id, action) do
      toast = toast |> Toast.add("#{turn.player.name} #{description}")
      turn = turn |> Map.put(:action, turn_action)
      action_send_after(next_state)

      state_data
      |> Map.put(:turn, turn)
      |> Map.put(:players, players)
      |> Map.put(:toast, toast)
      |> Map.put(:state, next_state)
      |> reply_success(:ok, :broadcast_change)
    else
      error -> {:reply, error, state_data}
    end
  end

  @spec handle_call({:select_target, String.t()}, any(), map()) ::
          {:noreply, map()} | {:noreply, map(), {:continue, atom()}}
  def handle_call(
        {:select_target, session_id},
        _from,
        %{toast: toast, players: players, turn: %{action: action, player: player} = turn} =
          state_data
      ) do
    with {:ok, next_state} <-
           GameStateMachine.check(state_data.state, :select_target, action.action),
         {:ok, turn, target_player} <- Turn.set_target(turn, players, session_id),
         {:ok, description} <-
           Actions.get_select_target_description(action.action, player.name, target_player.name),
         {:ok, players} <- Players.reset_display_state(players) do
      toast = toast |> Toast.add(description)
      select_target_send_after(next_state)

      state_data
      |> Map.put(:turn, turn)
      |> Map.put(:toast, toast)
      |> Map.put(:players, players)
      |> Map.put(:state, next_state)
      |> reply_success(:ok, :broadcast_change)
    else
      error -> {:reply, error, state_data}
    end
  end

  @spec handle_call({:block, String.t(), String.t()}, any(), map()) ::
          {:noreply, map()} | {:noreply, map(), {:continue, atom()}}
  def handle_call(
        {:block, session_id, block_action},
        _from,
        %{toast: toast, players: players, turn: %{action: action, player: player} = turn} =
          state_data
      ) do
    with {:ok, next_state} <-
           GameStateMachine.check(state_data.state, :block, action.action, block_action),
         {:ok, turn} <- Turn.set_block_target_response(turn, players, session_id, block_action),
         {:ok, players} <- Players.set_response_to_block(players, player.session_id) do
      claimed_character = turn |> Map.get(:blocker_claimed_character) |> String.upcase()
      toast = toast |> Toast.add("#{turn.target.name} blocks. (Claims #{claimed_character})")

      state_data
      |> Map.put(:players, players)
      |> Map.put(:turn, turn)
      |> Map.put(:toast, toast)
      |> Map.put(:state, next_state)
      |> reply_success(:ok, :broadcast_change)
    else
      error -> {:reply, error, state_data}
    end
  end

  @spec handle_call({:allow, String.t()}, any(), map()) ::
          {:noreply, map()} | {:noreply, map(), {:continue, atom()}}
  def handle_call(
        {:allow, session_id},
        _from,
        %{toast: toast, players: players, turn: %{action: action, player: player} = turn} =
          state_data
      ) do
    with {:ok, _next_state} <- GameStateMachine.check(state_data.state, :allow),
         {:ok, turn, player} <- Turn.set_opponent_allow(turn, players, session_id),
         {:ok, next_state} <-
           GameStateMachine.check_all_opponents_allow(state_data.state, turn.opponent_responses) do
      toast = toast |> Toast.add("#{player.name} allows.")
      action_send_after(next_state)

      state_data
      |> Map.put(:turn, turn)
      |> Map.put(:toast, toast)
      |> Map.put(:state, next_state)
      |> reply_success(:ok, :broadcast_change)
    else
      error -> {:reply, error, state_data}
    end
  end

  @spec handle_call(:allow_block, any(), map()) ::
          {:noreply, map()} | {:noreply, map(), {:continue, atom()}}
  def handle_call(
        :allow_block,
        _from,
        %{toast: toast, turn: %{target: target} = turn} = state_data
      ) do
    with {:ok, next_state} <- GameStateMachine.check(state_data.state, :allow_block),
         {:ok, turn} <- Turn.set_player_allow_block(turn) do
      toast = toast |> Toast.add("#{target.name} allows the block.")
      @process.send_after(self(), :end_turn, 1_000)

      state_data
      |> Map.put(:turn, turn)
      |> Map.put(:toast, toast)
      |> Map.put(:state, next_state)
      |> reply_success(:ok, :broadcast_change)
    else
      error -> {:reply, error, state_data}
    end
  end

  @spec handle_call(:challenge_block, any(), map()) ::
          {:noreply, map()} | {:noreply, map(), {:continue, atom()}}
  def handle_call(
        :challenge_block,
        _from,
        %{
          toast: toast,
          players: players,
          turn:
            %{
              action: action,
              blocker_claimed_character: blocker_claimed_character,
              target: target
            } = turn
        } = state_data
      ) do
    with {:ok, challenge_success} <-
           Challenge.challenge_block(players, target.session_id, blocker_claimed_character),
         {:ok, next_state} <-
           GameStateMachine.check(state_data.state, :challenge_block, challenge_success) do
      toast = toast |> Toast.add("#{target.name} allows the block.")
      @process.send_after(self(), :end_turn, 1_000)

      state_data
      |> Map.put(:turn, turn)
      |> Map.put(:toast, toast)
      |> Map.put(:state, next_state)
      |> reply_success(:ok, :broadcast_change)
    else
      error -> {:reply, error, state_data}
    end
  end

  @spec handle_call({:select_card, String.t(), non_neg_integer()}, any(), map()) ::
          {:noreply, map()} | {:noreply, map(), {:continue, atom()}}
  def handle_call(
        {:select_card, session_id, index},
        _from,
        %{players: players} = state_data
      ) do
    with {:ok, next_state} <- GameStateMachine.check(state_data.state, :select_card),
         {:ok, players} <- Players.set_card_selected(players, session_id, index) do
      state_data
      |> Map.put(:players, players)
      |> Map.put(:state, next_state)
      |> reply_success(:ok, :broadcast_change)
    else
      error -> {:reply, error, state_data}
    end
  end

  @spec handle_call(:lose_influence_confirm, any(), map()) ::
          {:noreply, map()} | {:noreply, map(), {:continue, atom()}}
  def handle_call(
        :lose_influence_confirm,
        _from,
        %{players: players, turn: %{target: %{session_id: target_session_id}}, toast: toast} =
          state_data
      ) do
    with {:ok, next_state} <- GameStateMachine.check(state_data.state, :lose_influence_confirm),
         {:ok, players, description} <- Players.lose_influence(players, target_session_id),
         {:ok, players} <- Players.reset_display_state(players) do
      toast = toast |> Toast.add(description)

      @process.send_after(self(), :end_turn, 1_000)

      state_data
      |> Map.put(:players, players)
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
      @process.send_after(self(), {:draw_card, 0}, 1_000)

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
      draw_card_or_start_turn(next_state, players, player_index)
      toast = draw_card_toast(toast, next_state, player)

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

  @spec handle_info({:start_turn, non_neg_integer()}, map()) ::
          {:noreply, map()} | {:noreply, map(), {:continue, atom()}}
  def handle_info(
        {:start_turn, player_index},
        %{players: players, toast: toast, turn: turn} = state_data
      ) do
    with {:ok, next_state} <- GameStateMachine.check(state_data.state, :start_turn),
         {:ok, players} <- Players.start_turn(players, player_index),
         {:ok, updated_turn} <- Turn.build(turn, players, player_index) do
      player = players |> Enum.at(player_index)
      toast = toast |> Toast.add("It's #{player.name}'s turn.")

      state_data
      |> Map.put(:players, players)
      |> Map.put(:turn, updated_turn)
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

  @spec handle_info(:action_success, map()) ::
          {:noreply, map()} | {:noreply, map(), {:continue, atom()}}
  def handle_info(
        :action_success,
        %{
          players: players,
          toast: toast,
          turn: %{action: action, player: player, target: target} = turn
        } = state_data
      ) do
    with {:ok, next_state} <-
           GameStateMachine.check(state_data.state, :action_success, action.action),
         {:ok, players} <-
           Players.apply_action(players, action.action, player.session_id, target),
         {:ok, description} <-
           Actions.get_action_success_description(action.action, player.name, target),
         {:ok, turn} <- Turn.get_action_success_next_turn(turn, action.action) do
      toast = toast |> Toast.add(description)
      action_success_send_after(action.action)

      state_data
      |> Map.put(:players, players)
      |> Map.put(:turn, turn)
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

  @spec handle_info(:lose_influence, map()) ::
          {:noreply, map()} | {:noreply, map(), {:continue, atom()}}
  def handle_info(
        :lose_influence,
        %{
          turn: %{
            target: %{hand: target_hand}
          }
        } = state_data
      ) do
    live_cards = target_hand |> Enum.filter(fn card -> card.state != "dead" end)

    case length(live_cards) do
      1 -> do_lose_influence(:die, state_data)
      2 -> do_lose_influence(:select_card, state_data)
    end
  end

  @spec handle_info(:end_turn, map()) ::
          {:noreply, map()} | {:noreply, map(), {:continue, atom()}}
  def handle_info(
        :end_turn,
        %{players: players, toast: toast, past_turns: past_turns, turn: %{player: player} = turn} =
          state_data
      ) do
    with {:ok, next_state} <- GameStateMachine.check(state_data.state, :end_turn) do
      start_next_turn(players, player.session_id)

      state_data
      |> Map.put(:past_turns, past_turns ++ [turn])
      |> Map.put(:turn, Turn.initialize())
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
  defp reply_success(state_data, reply, broadcast) do
    case broadcast do
      :broadcast_change ->
        {:reply, reply, state_data, {:continue, :broadcast_change}}
        #
        # _any ->
        #   {:reply, reply, state_data}
    end
  end

  @spec noreply(map(), atom()) :: {:noreply, map()} | {:noreply, map(), {:continue, atom()}}
  defp noreply(state_data, broadcast) do
    case broadcast do
      :broadcast_change ->
        {:noreply, state_data, {:continue, :broadcast_change}}
        #
        # _any ->
        #   {:noreply, state_data}
    end
  end

  ### PRIVATE HANDLER HELPERS

  defp do_lose_influence(
         :die,
         %{
           players: players,
           toast: toast,
           turn:
             %{
               target: %{session_id: target_session_id} = target
             } = _turn
         } = state_data
       ) do
    with {:ok, next_state} <- GameStateMachine.check(state_data.state, :lose_influence, :die),
         {:ok, players} <- Players.kill_player_and_last_card(players, target_session_id) do
      toast = toast |> Toast.add("#{target.name} loses 1 influence. Player has died.")
      @process.send_after(self(), :end_turn, 1_000)

      state_data
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

  defp do_lose_influence(
         :select_card,
         %{
           players: players,
           toast: toast,
           turn:
             %{
               target: %{session_id: target_session_id} = target
             } = _turn
         } = state_data
       ) do
    with {:ok, next_state} <-
           GameStateMachine.check(state_data.state, :lose_influence, :select_card),
         {:ok, players} <-
           Players.set_display_state(players, target_session_id, "lose_influence_select_card") do
      toast = toast |> Toast.add("#{target.name} loses 1 influence. Choosing card to discard...")

      state_data
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

  ### PRIVATE

  defp session_id_does_not_exist(session_id, players) do
    case Enum.find(players, fn player -> player.session_id == session_id end) do
      nil -> :ok
      _found -> {:error, "player exists"}
    end
  end

  defp draw_card_or_start_turn("drawing_cards", players, player_index) do
    next_player_draw_card("drawing_cards", players, player_index)
  end

  defp draw_card_or_start_turn("cards_drawn", _, _) do
    @process.send_after(self(), {:start_turn, 0}, 1_000)
  end

  defp next_player_draw_card("drawing_cards", players, player_index) do
    next_index = if player_index == length(players) - 1, do: 0, else: player_index + 1

    @process.send_after(self(), {:draw_card, next_index}, 1_000)
  end

  defp draw_card_toast(toast, next_state, player) do
    if next_state == "cards_drawn" do
      toast |> Toast.add("All players have drawn their cards.")
    else
      toast |> Toast.add("#{player.name} drew a card.")
    end
  end

  defp action_send_after("action_success") do
    @process.send_after(self(), :action_success, 1_000)
  end

  defp action_send_after(_) do
    :do_nothing
  end

  defp select_target_send_after("action_success") do
    @process.send_after(self(), :action_success, 1_000)
  end

  defp select_target_send_after(_) do
    :do_nothing
  end

  defp action_success_send_after("coup") do
    @process.send_after(self(), :lose_influence, 1_000)
  end

  defp action_success_send_after("1coin") do
    @process.send_after(self(), :end_turn, 1_000)
  end

  defp action_success_send_after("foreignaid") do
    @process.send_after(self(), :end_turn, 1_000)
  end

  defp action_success_send_after(_) do
    :do_nothing
  end

  defp start_next_turn(players, session_id) do
    current_index = Enum.find_index(players, fn p -> p.session_id == session_id end)
    next_index = get_next_index(players, current_index)

    @process.send_after(self(), {:start_turn, next_index}, 200)
  end

  defp get_next_index(players, index) do
    next_index = if index == length(players) - 1, do: 0, else: index + 1
    next_player_state = players |> Enum.at(next_index) |> Map.get(:state)

    if next_player_state == "dead" do
      get_next_index(players, next_index)
    else
      next_index
    end
  end
end
