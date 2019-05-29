defmodule CoupPhx2Web.PageController do
  use CoupPhx2Web, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def save_name(conn, %{"game" => game, "player_name" => player_name}) do
    conn
    |> put_session(:session_id, get_session(conn, :session_id) || Ecto.UUID.generate())
    |> put_session(:name, player_name)
    |> redirect(to: "/game/#{game}")
  end
end
