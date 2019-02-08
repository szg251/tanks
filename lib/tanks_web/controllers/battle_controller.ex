defmodule TanksWeb.BattleController do
  use TanksWeb, :controller

  alias Tanks.Lodge
  alias Tanks.Lodge.BattleSummary

  action_fallback(TanksWeb.FallbackController)

  def index(conn, _params) do
    battles = Lodge.list_battles()
    render(conn, "index.json", battles: battles)
  end

  def create(conn, %{"battle" => %{"name" => name, "owner_name" => owner_name}}) do
    if !is_binary(name) do
      conn
      |> put_status(422)
      |> put_view(TanksWeb.ErrorView)
      |> render(:"422")
    else
      case Lodge.start_battle(name, owner_name) do
        {:ok, %BattleSummary{} = battle} ->
          conn
          |> put_status(:created)
          |> render("show.json", battle: battle)

        {:error, message = "battle already exists"} ->
          conn
          |> put_status(409)
          |> put_view(TanksWeb.ErrorView)
          |> render("error.json", messages: [message])

        {:error, message} ->
          conn
          |> put_status(400)
          |> put_view(TanksWeb.ErrorView)
          |> render("error.json", messages: [message])

        _ ->
          conn
          |> put_status(500)
          |> put_view(TanksWeb.ErrorView)
          |> render("error.json", messages: ["server error"])
      end
    end
  end

  def show(conn, %{"id" => name}) do
    case Lodge.get_battle(name) do
      {:ok, %BattleSummary{} = battle} ->
        render(conn, "show.json", battle: battle)

      {:error, message = "battle does not exist"} ->
        conn
        |> put_status(:not_found)
        |> put_view(TanksWeb.ErrorView)
        |> render("error.json", messages: [message])

      _ ->
        conn
        |> put_status(500)
        |> put_view(TanksWeb.ErrorView)
        |> render("error.json", messages: ["server error"])
    end
  end

  def delete(conn, %{"id" => battle_name, "player_name" => player_name}) do
    with :ok <- Lodge.close_battle(battle_name, player_name) do
      send_resp(conn, :no_content, "")
    end
  end
end
