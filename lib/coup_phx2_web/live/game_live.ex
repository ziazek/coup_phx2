defmodule CoupPhx2Web.GameLive do
  @moduledoc """
  A clock from the live_view_examples repo. For verifying that LiveView is working.
  """
  use Phoenix.LiveView

  alias CoupEngine.{Game, GameSupervisor}

  @toast_expiry 5000
  @toast_animation 600

  def render(assigns), do: CoupPhx2Web.GameView.render("game.html", assigns)

  @doc """
  Redirect to set a session UUID if none exists.
  """
  def mount(%{session_id: nil, path_params: path_params} = _session, socket) do
    %{"name" => game_name} = path_params

    {:stop,
     socket
     |> redirect(to: "/set_name/#{game_name}")}
  end

  @doc """
  Initializes the page on first load
  """
  def mount(%{session_id: session_id, name: name, path_params: path_params} = _session, socket) do
    if connected?(socket), do: :timer.send_interval(250, self(), :tick)

    %{"name" => game_name} = path_params

    game_pid =
      case GameSupervisor.start_game({game_name, session_id, name}) do
        {:ok, pid} ->
          pid

        {:error, {:already_started, pid}} ->
          Game.add_player(pid, session_id, name)
          pid
      end

    Phoenix.PubSub.subscribe(:game_pubsub, game_name)

    current_player = Game.get_player(game_pid, session_id)

    socket =
      socket
      |> put_date()
      |> assign(session_id: current_player.session_id)
      |> assign(name: current_player.name)
      |> assign(role: current_player.role)
      |> assign(toasts: [])
      |> assign(game_pid: game_pid)
      |> fetch()

    {:ok, socket}
  end

  ### EVENT LISTENERS

  def handle_info(:player_joined, socket) do
    socket =
      socket
      |> fetch()
      |> append_toast(:info, "Player joined.")

    {:noreply, socket}
  end

  def handle_info(:game_started, socket) do
    socket =
      socket
      |> fetch()
      |> append_toast(:info, "Game started!")

    {:noreply, socket}
  end

  def handle_info(:deck_shuffled, socket) do
    socket =
      socket
      |> fetch()
      |> append_toast(:info, "Deck shuffled.")

    {:noreply, socket}
  end

  def handle_info({:card_drawn, player}, socket) do
    socket =
      socket
      |> fetch()
      |> append_toast(:info, "#{player.name} drew a card.")

    {:noreply, socket}
  end

  def handle_info(:tick, socket) do
    socket =
      socket
      |> put_date()
      |> expire_toasts()

    {:noreply, socket}
  end

  ### EVENTS (clicks)

  def handle_event("start_game", _path, socket) do
    case Game.start_game(socket.assigns.game_pid) do
      :ok ->
        {:noreply, socket}

      {:error, reason} ->
        {:noreply, socket |> append_toast(:danger, reason)}
    end
  end

  # DEBUG CSS
  def handle_event("toast_test", _path, socket) do
    socket =
      socket
      |> append_toast(:info, "test test #{:rand.uniform(999_999)}")

    {:noreply, socket}
  end

  ### HELPERS

  defp put_date(socket) do
    assign(socket, date: Timex.local() |> Timex.to_datetime("Asia/Singapore"))
  end

  defp append_toast(socket, type, body) do
    toasts = socket.assigns.toasts
    expiry = Timex.shift(Timex.now(), milliseconds: @toast_expiry)

    toast = %{type: type, body: body, expiry: expiry, exiting: ""}

    socket
    |> assign(toasts: toasts ++ [toast])
  end

  defp expire_toasts(socket) do
    toasts =
      socket.assigns.toasts
      |> Enum.map(&add_exiting/1)
      |> Enum.filter(fn %{expiry: expiry} -> Timex.after?(expiry, Timex.now()) end)

    socket
    |> assign(toasts: toasts)
  end

  defp add_exiting(%{expiry: expiry} = toast) do
    exiting_time = Timex.shift(expiry, milliseconds: -@toast_animation)

    if Timex.before?(exiting_time, Timex.now()) do
      %{toast | exiting: "exiting"}
    else
      toast
    end
  end

  defp fetch(socket) do
    players = Game.list_players(socket.assigns.game_pid)
    player_chunks = players |> Enum.chunk_every(3)

    socket
    |> assign(players: players)
    |> assign(player_chunks: player_chunks)
    |> assign(state: Game.get_game_state(socket.assigns.game_pid))
    |> assign(data: Game.get_game_data(socket.assigns.game_pid))
  end
end
