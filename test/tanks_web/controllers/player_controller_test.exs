defmodule TanksWeb.PlayerControllerTest do
  use TanksWeb.ConnCase

  alias Tanks.Lodge

  @create_attrs %{"name" => "test_name"}
  @invalid_attrs %{"name" => ""}

  def fixture(:player) do
    {:ok, player} = Lodge.create_player("test_name")
    player
  end

  setup %{conn: conn} do
    Application.stop(:tanks)
    :ok = Application.start(:tanks)
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all players", %{conn: conn} do
      conn = get(conn, Routes.player_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create player" do
    test "renders player when data is valid", %{conn: conn} do
      conn = post(conn, Routes.player_path(conn, :create), player: @create_attrs)
      assert %{"name" => name} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.player_path(conn, :index))
      assert [%{"name" => name}] = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.player_path(conn, :create), player: @invalid_attrs)
      assert response(conn, 400)
    end
  end

  describe "delete player" do
    setup [:create_player]

    test "deletes chosen player", %{conn: conn, player: player} do
      conn = delete(conn, Routes.player_path(conn, :delete, player.name))
      assert response(conn, 204)

      conn = get(conn, Routes.player_path(conn, :index))
      assert [] = json_response(conn, 200)["data"]
    end
  end

  defp create_player(_) do
    player = fixture(:player)
    {:ok, player: player}
  end
end
