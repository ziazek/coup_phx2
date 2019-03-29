defmodule CoupPhx2Web.GameLive do
  @moduledoc """
  A clock from the live_view_examples repo. For verifying that LiveView is working.
  """
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    <div>
      <small>Session ID: <%= @user_id %></small>
      <h2 phx-click="boom">It's <%= Timex.format!(@date, "{UNIX}") %></h2>
    </div>
    """
  end

  @doc """
  Redirect to set a session UUID if none exists.
  """
  def mount(%{user_id: nil, path_params: path_params} = session, socket) do
    %{"name" => game_name} = path_params

    {:stop,
     socket
     |> redirect(
       to:
         CoupPhx2Web.Router.Helpers.page_path(
           CoupPhx2Web.Endpoint,
           :save_name,
           game: game_name
         )
     )}
  end

  def mount(%{user_id: user_id, path_params: path_params} = _session, socket) do
    if connected?(socket), do: :timer.send_interval(1000, self(), :tick)

    %{"name" => game_name} = path_params

    socket =
      socket
      |> put_date()
      |> assign(user_id: user_id)

    {:ok, socket}
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
