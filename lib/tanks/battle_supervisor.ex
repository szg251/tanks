defmodule Tanks.BattleSupervisor do
  use DynamicSupervisor

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_battle() do
    {:ok, tank_sup_pid} =
      DynamicSupervisor.start_child(__MODULE__, Tanks.GameLogic.TankSupervisor)

    DynamicSupervisor.start_child(__MODULE__, {Tanks.GameLogic.Battle, tank_sup_pid})
  end

  def close_battle(battle_pid) do
    DynamicSupervisor.terminate_child(__MODULE__, battle_pid)
  end

  def get_battles do
    DynamicSupervisor.which_children(__MODULE__)
  end
end
