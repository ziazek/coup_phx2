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

  def mount(%{session_id: session_id, name: name, path_params: path_params} = _session, socket) do
    if connected?(socket), do: :timer.send_interval(1000, self(), :tick)

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
      |> assign(error: nil)
      |> assign(game_pid: game_pid)
      |> fetch()

    {:ok, socket}
  end

  ### EVENT LISTENERS

  def handle_info(:player_joined, socket) do
    {:noreply, fetch(socket)}
  end

  def handle_info(:game_started, socket) do
    {:noreply, fetch(socket)}
  end

  def handle_info(:tick, socket) do
    {:noreply, put_date(socket)}
  end

  ### EVENTS

  def handle_event("start_game", _path, socket) do
    case Game.start_game(socket.assigns.game_pid) do
      :ok ->
        {:noreply, socket |> assign(:error, nil)}

      {:error, reason} ->
        {:noreply, socket |> assign(:error, reason)}
    end
  end

  ### HELPERS

  defp put_date(socket) do
    assign(socket, date: Timex.local() |> Timex.to_datetime("Asia/Singapore"))
  end

  defp fetch(socket) do
    socket
    |> assign(players: Game.list_players(socket.assigns.game_pid))
    |> assign(state: Game.get_game_state(socket.assigns.game_pid))
  end
end
