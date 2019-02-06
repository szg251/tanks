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

    get("/battles/:battle_name", BattleController, :show)
    get("/battles", BattleController, :index)
    post("/battles", BattleController, :create)
    delete("/battles/:battle_name", BattleController, :delete)
  end

  scope "/", TanksWeb do
    # Use the default browser stack
    pipe_through(:browser)

    get("/*anything", PageController, :index)
  end
end
