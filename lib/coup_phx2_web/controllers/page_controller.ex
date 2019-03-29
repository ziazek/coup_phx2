defmodule CoupPhx2Web.PageController do
  use CoupPhx2Web, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def save_name(conn, %{"game" => game} = _params) do
    conn
    |> put_session(:user_id, get_session(conn, :user_id) || Ecto.UUID.generate())
    |> redirect(to: "/game/#{game}")
  end
end
