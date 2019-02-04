defmodule TanksWeb.BattleController do
  use TanksWeb, :controller

  alias Tanks.BattleLodge
  alias Tanks.BattleLodge.BattleSummary

  action_fallback(TanksWeb.FallbackController)

  def index(conn, _params) do
    battles = BattleLodge.list_battles()
    render(conn, "index.json", battles: battles)
  end

  def create(conn, %{"battle" => %{"name" => name, "owner_name" => owner_name}}) do
    if !is_binary(name) do
      conn
      |> put_status(422)
      |> put_view(TanksWeb.ErrorView)
      |> render(:"422")
    else
      with {:ok, %BattleSummary{} = battle} <- BattleLodge.start_battle(name, owner_name) do
        conn
        |> put_status(:created)
        |> render("show.json", battle: battle)
      end
    end
  end

  def show(conn, %{"battle_name" => name}) do
    with {:ok, %BattleSummary{} = battle} <- BattleLodge.get_summary(name) do
      render(conn, "show.json", battle: battle)
    else
      _ ->
        conn
        |> put_status(:not_found)
        |> put_view(TanksWeb.ErrorView)
        |> render(:"404")
    end
  end

  def delete(conn, %{"battle_name" => battle_name, "player_name" => player_name}) do
    with :ok <- BattleLodge.close_battle(battle_name, player_name) do
      send_resp(conn, :no_content, "")
    end
  end
end
