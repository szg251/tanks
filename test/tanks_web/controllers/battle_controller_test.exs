defmodule TanksWeb.BattleControllerTest do
  use TanksWeb.ConnCase

  alias Tanks.BattleLodge

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  def fixture(:battle) do
    {:ok, battle} = BattleLodge.create_battle(@create_attrs)
    battle
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all battles", %{conn: conn} do
      conn = get(conn, Routes.battle_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create battle" do
    test "renders battle when data is valid", %{conn: conn} do
      conn = post(conn, Routes.battle_path(conn, :create), battle: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.battle_path(conn, :show, id))

      assert %{
               "id" => id
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.battle_path(conn, :create), battle: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete battle" do
    setup [:create_battle]

    test "deletes chosen battle", %{conn: conn, battle: battle} do
      conn = delete(conn, Routes.battle_path(conn, :delete, battle))
      assert response(conn, 204)

      assert_error_sent(404, fn ->
        get(conn, Routes.battle_path(conn, :show, battle))
      end)
    end
  end

  defp create_battle(_) do
    battle = fixture(:battle)
    {:ok, battle: battle}
  end
end
