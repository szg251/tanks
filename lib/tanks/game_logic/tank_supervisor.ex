defmodule Tanks.GameLogic.TankSupervisor do
  use DynamicSupervisor

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add_tank(tank_sup_pid) do
    DynamicSupervisor.start_child(tank_sup_pid, Tanks.GameLogic.Tank)
  end

  def remove_tank(tank_sup_pid, tank_pid) do
    DynamicSupervisor.terminate_child(tank_sup_pid, tank_pid)
  end

  def get_tanks(tank_sup_pid) do
    DynamicSupervisor.which_children(tank_sup_pid)
  end
end
