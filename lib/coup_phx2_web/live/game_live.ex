defmodule CoupPhx2Web.GameLive do
  @moduledoc """
  A clock from the live_view_examples repo. For verifying that LiveView is working.
  """
  use Phoenix.LiveView

  alias CoupEngine.{Game, GameSupervisor}

  def render(assigns), do: CoupPhx2Web.GameView.render("game.html", assigns)
  # def render(assigns) do
  #   ~L"""
  #   <div>
  #     <p><small>Session ID: <%= @session_id %></small></p>
  #     <p><small>Name: <%= @name %></small></p>
  #     <h2 phx-click="boom">It's <%= Timex.format!(@date, "{UNIX}") %></h2>
  #   </div>
  #   """
  # end

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

    socket =
      socket
      |> put_date()
      |> assign(session_id: session_id)
      |> assign(name: name)
      |> assign(game_pid: game_pid)
      |> assign(players: Game.list_players(game_pid))

    {:ok, socket}
  end

  def handle_info(:player_joined, socket) do
    players = Game.list_players(socket.assigns.game_pid)

    socket =
      socket
      |> assign(players: players)

    {:noreply, socket}
  end

  def handle_info(:tick, socket) do
    {:noreply, put_date(socket)}
  end

  def handle_event("nav", _path, socket) do
    {:noreply, socket}
  end

  defp put_date(socket) do
    assign(socket, date: Timex.local() |> Timex.to_datetime("Asia/Singapore"))
  end
end
