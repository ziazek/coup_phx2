defmodule CoupPhx2Web.HomeLive do
  @moduledoc """
  A clock from the live_view_examples repo. For verifying that LiveView is working.
  """
  use Phoenix.LiveView
  alias CoupPhx2.User
  alias CoupPhx2Web.Router.Helpers

  def render(assigns), do: CoupPhx2Web.GameView.render("home.html", assigns)

  def mount(_session, socket) do
    if connected?(socket), do: :timer.send_interval(1000, self(), :tick)

    socket =
      socket
      |> put_date()
      |> assign(%{
        changeset: User.changeset(%User{}, %{name: "Your name"})
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
      random_id = Coup.IdGenerator.randstring(6)

      {:stop,
       socket
       |> put_flash(:info, "game created")
       |> redirect(
         to:
           Helpers.page_path(
             CoupPhx2Web.Endpoint,
             :save_name,
             game: random_id,
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
