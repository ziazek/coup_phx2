defmodule CoupPhx2Web.GameLive do
  @moduledoc """
  A clock from the live_view_examples repo. For verifying that LiveView is working.
  """
  use Phoenix.LiveView

  alias CoupEngine.{Game, GameSupervisor}

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

    socket =
      socket
      |> put_date()
      |> assign(session_id: session_id)
      |> assign(game_pid: game_pid)
      |> fetch()

    {:ok, socket}
  end

  ### EVENTS ###

  def handle_event("start_game", _value, socket) do
    case Game.start_game(socket.assigns.game_pid) do
      :ok ->
        {:noreply, socket}

      {:error, reason} ->
        {:noreply, socket}
        # {:noreply, socket |> append_toast(:danger, reason)}
    end
  end

  def handle_event("action", action_name, socket) do
    case Game.action(socket.assigns.game_pid, action_name) do
      :ok ->
        {:noreply, socket}

      {:error, reason} ->
        {:noreply, socket}
        # {:noreply, socket |> append_toast(:danger, reason)}
    end
  end

  def handle_event("select_target", session_id, socket) do
    case Game.select_target(socket.assigns.game_pid, session_id) do
      :ok ->
        {:noreply, socket}

      {:error, reason} ->
        {:noreply, socket}
    end
  end

  def handle_event("select_card", index_str, socket) do
    session_id = socket.assigns.data.current_player.session_id
    index = String.to_integer(index_str)

    case Game.select_card(socket.assigns.game_pid, session_id, index) do
      :ok ->
        {:noreply, socket}

      {:error, reason} ->
        {:noreply, socket}
    end
  end

  def handle_event("lose_influence_confirm", _value, socket) do
    case Game.lose_influence_confirm(socket.assigns.game_pid) do
      :ok ->
        {:noreply, socket}

      {:error, reason} ->
        {:noreply, socket}
    end
  end

  def handle_info(:tick, socket) do
    socket =
      socket
      |> put_date()

    {:noreply, socket}
  end

  ### SUBSCRIBED EVENTS ###

  def handle_info(:game_data_changed, socket) do
    socket = socket |> fetch()
    {:noreply, socket}
  end

  ### PRIVATE ###

  defp put_date(socket) do
    assign(socket, date: Timex.local() |> Timex.to_datetime("Asia/Singapore"))
  end

  defp fetch(socket) do
    data = Game.get_game_data(socket.assigns.game_pid, socket.assigns.session_id)

    # IO.inspect(data, label: "data")

    socket
    |> assign(data: data)
  end
end
