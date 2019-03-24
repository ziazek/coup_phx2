defmodule CoupPhx2Web.Router do
  use CoupPhx2Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    # plug :fetch_flash
    plug Phoenix.LiveView.Flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_layout, {CoupPhx2Web.LayoutView, :app}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CoupPhx2Web do
    pipe_through :browser

    get "/", PageController, :index
    live("/clock", ClockLive)
  end

  # Other scopes may use custom stacks.
  # scope "/api", CoupPhx2Web do
  #   pipe_through :api
  # end
end
