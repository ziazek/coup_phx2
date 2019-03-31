defmodule CoupPhx2Web.SetNameLive do
  @moduledoc """
  A clock from the live_view_examples repo. For verifying that LiveView is working.
  """
  use Phoenix.LiveView
  alias CoupPhx2.User

  def render(assigns), do: CoupPhx2Web.GameView.render("set_name.html", assigns)

  def mount(%{path_params: %{"game" => game}} = _session, socket) do
    if connected?(socket), do: :timer.send_interval(1000, self(), :tick)

    socket =
      socket
      |> put_date()
      |> assign(%{
        changeset: User.changeset(%User{}, %{name: "Your name"}),
        game: game
      })

    {:ok, socket}
  end

  def handle_event("validate", %{"user" => params}, socket) do
    changeset =
      %User{}
      |> User.changeset(params)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("save", %{"user" => params}, socket) do
    changeset =
      %User{}
      |> User.changeset(params)

    if changeset.valid? do
      {:stop,
       socket
       |> put_flash(:info, "joined game")
       |> redirect(
         to:
           CoupPhx2Web.Router.Helpers.page_path(
             CoupPhx2Web.Endpoint,
             :save_name,
             game: socket.assigns.game,
             player_name: Ecto.Changeset.get_field(changeset, :name)
           )
       )}
    else
      :boom
    end
  end

  def handle_info(:tick, socket) do
    {:noreply, put_date(socket)}
  end

  defp put_date(socket) do
    assign(socket, date: Timex.local() |> Timex.to_datetime("Asia/Singapore"))
  end
end
