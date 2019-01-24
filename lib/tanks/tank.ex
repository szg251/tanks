defmodule Tank do
  use GenServer

  @max_velocity 5

  defstruct health: 100, width: 50, height: 20, x: 0, y: 0, velocity: 0

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    {:ok, %Tank{}}
  end

  # Validate and set velocity
  def set_velocity(tankPid, velocity) do
    GenServer.cast(tankPid, {:set_velocity, velocity})
  end

  # Move tank
  def move(tankPid) do
    GenServer.cast(tankPid, :move)
  end

  # Get current state of tank
  def get_state(tankPid) do
    GenServer.call(tankPid, :get_state)
  end

  def handle_cast({:set_velocity, velocity}, tank) do
    newTank = %Tank{tank | velocity: velocity |> min(@max_velocity) |> max(-@max_velocity)}

    {:noreply, newTank}
  end

  def handle_cast(:move, tank) do
    {newX, newY} = Field.move_object(tank.width, tank.x, tank.velocity, tank.height, tank.y)
    newTank = %Tank{tank | x: newX, y: newY}

    {:noreply, newTank}
  end

  def handle_call(:get_state, _from, tank) do
    {:reply, tank, tank}
  end
end
