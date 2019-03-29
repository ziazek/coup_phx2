defmodule CoupPhx2Web.HomeLive do
  @moduledoc """
  A clock from the live_view_examples repo. For verifying that LiveView is working.
  """
  use Phoenix.LiveView

  # def render(assigns) do
  #   ~L"""
  #   <div>
  #     <h2 phx-click="boom">It's <%= Timex.format!(@date, "{UNIX}") %></h2>
  #   </div>
  #   """
  # end

  def render(assigns), do: CoupPhx2Web.GameView.render("home.html", assigns)

  def mount(_session, socket) do
    if connected?(socket), do: :timer.send_interval(1000, self(), :tick)

    {:ok, put_date(socket)}
  end

  def handle_info(:tick, socket) do
    {:noreply, put_date(socket)}
  end

  def handle_event("new_game", _path, socket) do
    random_id = Coup.IdGenerator.randstring(6)

    {:stop,
     socket
     |> put_flash(:info, "game created")
     |> redirect(
       to:
         CoupPhx2Web.Router.Helpers.page_path(
           CoupPhx2Web.Endpoint,
           :save_name,
           game: random_id
         )
     )}
  end

  defp put_date(socket) do
    assign(socket, date: Timex.local() |> Timex.to_datetime("Asia/Singapore"))
  end
end
