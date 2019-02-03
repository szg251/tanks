defmodule TanksWeb.BattleView do
  use TanksWeb, :view
  alias TanksWeb.BattleView

  def render("index.json", %{battles: battles}) do
    %{data: render_many(battles, BattleView, "battle.json")}
  end

  def render("show.json", %{battle: battle}) do
    %{data: render_one(battle, BattleView, "battle.json")}
  end

  def render("battle.json", %{battle: battle}) do
    %{name: battle.name, player_count: battle.player_count}
  end
end
