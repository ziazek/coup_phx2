defmodule CoupPhx2Web.PageController do
  use CoupPhx2Web, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
