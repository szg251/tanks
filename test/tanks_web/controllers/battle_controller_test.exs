defmodule TanksWeb.BattleControllerTest do
  use TanksWeb.ConnCase

  alias Tanks.Lodge

  @create_attrs %{"name" => "test_name", "owner_name" => "test_owner"}
  @invalid_attrs %{"name" => 123, "owner_name" => "test"}

  def fixture(:player) do
    {:ok, player} = Lodge.create_player("test_owner")
    :ok
  end

  def fixture(:battle) do
    {:ok, battle} = Lodge.start_battle("test_name", "test_owner")
    battle
  end

  setup %{conn: conn} do
    Application.stop(:tanks)
    :ok = Application.start(:tanks)
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all battles", %{conn: conn} do
      conn = get(conn, Routes.battle_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create battle" do
    setup [:create_player]

    test "renders battle when data is valid", %{conn: conn} do
      conn = post(conn, Routes.battle_path(conn, :create), battle: @create_attrs)

      assert %{
               "name" => name,
               "player_count" => player_count,
               "owner_name" => owner_name
             } = json_response(conn, 201)["data"]

      conn = get(conn, Routes.battle_path(conn, :show, name))

      assert %{
               "name" => name,
               "player_count" => player_count,
               "owner_name" => owner_name
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.battle_path(conn, :create), battle: @invalid_attrs)
      assert response(conn, 422)
    end
  end

  describe "show battle" do
    setup [:create_battle]

    test "renders battle", %{conn: conn, battle: battle} do
      conn = get(conn, Routes.battle_path(conn, :show, battle.name))

      assert json_response(conn, 200)["data"] == %{
               "name" => battle.name,
               "owner_name" => battle.owner_name,
               "player_count" => 0
             }
    end
  end

  describe "delete battle" do
    setup [:create_battle]

    test "deletes chosen battle", %{conn: conn, battle: battle} do
      conn =
        delete(conn, Routes.battle_path(conn, :delete, battle.name),
          player_name: battle.owner_name
        )

      assert response(conn, 204)

      assert response(get(conn, Routes.battle_path(conn, :show, battle.name)), 404)
    end
  end

  defp create_player(_) do
    fixture(:player)
  end

  defp create_battle(_) do
    fixture(:player)
    battle = fixture(:battle)
    {:ok, battle: battle}
  end
end
