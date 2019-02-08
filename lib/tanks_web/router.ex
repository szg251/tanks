defmodule TanksWeb.Router do
  use TanksWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/api", TanksWeb do
    pipe_through(:api)

    resources("/players", PlayerController, only: [:index, :create, :delete])
    resources("/battles", BattleController, only: [:index, :show, :create, :delete])
  end

  scope "/", TanksWeb do
    # Use the default browser stack
    pipe_through(:browser)

    get("/*anything", PageController, :index)
  end
end
