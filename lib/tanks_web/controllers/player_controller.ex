defmodule TanksWeb.PlayerController do
  use TanksWeb, :controller

  alias Tanks.Lodge

  action_fallback(TanksWeb.FallbackController)

  def index(conn, _params) do
    players = Lodge.list_players()
    render(conn, "index.json", players: players)
  end

  def create(conn, %{"player" => %{"name" => name}}) do
    if !is_binary(name) do
      conn
      |> put_status(422)
      |> put_view(TanksWeb.ErrorView)
      |> render("422.json")
    else
      case Lodge.create_player(name) do
        {:ok, player_name} ->
          conn
          |> put_status(:created)
          |> render("show.json", player: player_name)

        {:error, message = "player already exists"} ->
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

  def delete(conn, %{"id" => name}) do
    with :ok <- Lodge.remove_player(name) do
      send_resp(conn, :no_content, "")
    end
  end
end
