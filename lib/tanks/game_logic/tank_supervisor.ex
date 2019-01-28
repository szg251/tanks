defmodule Tanks.GameLogic.TankSupervisor do
  use DynamicSupervisor

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add_tank() do
    DynamicSupervisor.start_child(__MODULE__, Tanks.GameLogic.Tank)
  end

  @spec remove_tank(pid()) :: :ok | {:error, :not_found}
  def remove_tank(tank_pid) do
    DynamicSupervisor.terminate_child(__MODULE__, tank_pid)
  end

  def get_tanks do
    DynamicSupervisor.which_children(__MODULE__)
  end
end
