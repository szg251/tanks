defmodule TanksWeb.Router do
  use TanksWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api" do
    pipe_through :api

    get "/battle", BattleController, :index
    post "/battle", BattleController, :create
    delete "/battle", BattleController, :delete
  end

  scope "/", TanksWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end


  # Other scopes may use custom stacks.
  # scope "/api", TanksWeb do
  #   pipe_through :api
  # end
end
