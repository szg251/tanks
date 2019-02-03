defmodule TanksWeb.BattleController do
  use TanksWeb, :controller

  alias Tanks.BattleLodge
  alias Tanks.BattleLodge.BattleSummary

  action_fallback(TanksWeb.FallbackController)

  def index(conn, _params) do
    battles = BattleLodge.list_battles()
    render(conn, "index.json", battles: battles)
  end

  def create(conn, %{"battle" => %{"name" => battle_name}}) do
    with {:ok, %BattleSummary{} = battle} <- BattleLodge.start_battle(battle_name) do
      conn
      |> put_status(:created)
      |> render("show.json", battle: battle)
    end
  end

  def show(conn, %{"name" => name}) do
    with {:ok, %BattleSummary{} = battle} <- BattleLodge.get_summary(name) do
      render(conn, "show.json", battle: battle)
    end
  end

  def delete(conn, %{"name" => name}) do
    with :ok <- BattleLodge.close_battle(name) do
      send_resp(conn, :no_content, "")
    end
  end
end
