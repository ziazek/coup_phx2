defmodule CoupPhx2Web.ConceptLive do
  @moduledoc """
  A clock from the live_view_examples repo. For verifying that LiveView is working.
  """
  use Phoenix.LiveView

  # alias CoupEngine.{Game, GameSupervisor}
  alias __MODULE__
  alias Concept.{Game, GameSupervisor}

  def render(assigns), do: CoupPhx2Web.ConceptView.render("index.html", assigns)

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
    # if connected?(socket), do: :timer.send_interval(250, self(), :tick)

    %{"name" => game_name} = path_params

    game_pid =
      case GameSupervisor.start_game({game_name, session_id, name}) do
        {:ok, pid} ->
          pid

        {:error, {:already_started, pid}} ->
          # Game.add_player(pid, session_id, name)
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

  def handle_info(:tick, socket) do
    socket =
      socket
      |> put_date()

    {:noreply, socket}
  end

  def handle_info(:state_updated, socket) do
    {:noreply, socket |> fetch()}
  end

  ### CLICK EVENTS

  def handle_event("next_step", _value, socket) do
    Game.next_step(socket.assigns.game_pid)
    {:noreply, socket}
  end

  ### HELPERS

  defp put_date(socket) do
    assign(socket, date: Timex.local() |> Timex.to_datetime("Asia/Singapore"))
  end

  defp fetch(socket) do
    data = Game.get_game_data(socket.assigns.game_pid)

    socket
    |> assign(data: data)
  end
end
