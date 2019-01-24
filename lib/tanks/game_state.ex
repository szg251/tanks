defmodule GameState do
  defstruct nextId: 0, tanks: Map.new()
end

defmodule Tank do
  @max_velocity 5

  defstruct health: 100, width: 50, height: 20, x: 0, y: 0, velocity: 0

  # Move a tank (validate and set velocity)
  def move(tank, velocity) do
    %Tank{tank | velocity: velocity |> min(@max_velocity) |> max(-@max_velocity)}
  end
end

defmodule Field do
  @field_width 1000
  @field_height 600

  def move_object(object_width, object_x, velocity_x, object_height, object_y, velocity_y \\ 0) do
    newX = (object_x + velocity_x) |> min(@field_width - object_width) |> max(0)
    newY = (object_y + velocity_y) |> min(@field_height - object_height) |> max(0)

    {newX, newY}
  end
end

defmodule Tanks.GameState do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts ++ [name: __MODULE__])
  end

  def join do
    GenServer.call(__MODULE__, :join)
  end

  def get_tanks do
    GenServer.call(__MODULE__, :get_tanks)
  end

  def leave(tankId) do
    GenServer.cast(__MODULE__, {:leave, tankId})
  end

  def move(tankId, velocity) do
    GenServer.cast(__MODULE__, {:move, tankId, velocity})
  end

  defp schedule_tick() do
    Process.send_after(self(), :tick, 100)
  end

  ### SERVER

  def init(:ok) do
    schedule_tick()
    {:ok, %GameState{}}
  end

  # Evaluate movement
  def handle_info(:tick, state) do
    updateTank = fn {k, tank} ->
      {newX, newY} = Field.move_object(tank.width, tank.x, tank.velocity, tank.height, tank.y)
      {k, %Tank{tank | x: newX, y: newY}}
    end

    newTanks = state.tanks |> Enum.map(updateTank) |> Enum.into(%{})
    newState = %GameState{state | tanks: newTanks}

    schedule_tick()
    {:noreply, newState}
  end

  # Create a new tank
  def handle_call(:join, _from, state) do
    newState = %{
      state
      | tanks: state.tanks |> Map.put(state.nextId, %Tank{}),
        nextId: state.nextId + 1
    }

    {:reply, state.nextId, newState}
  end

  # Get all tanks
  def handle_call(:get_tanks, _from, state) do
    {:reply, state.tanks, state}
  end

  def handle_cast({:leave, tankId}, state) do
    newState = %{state | tanks: Map.delete(state.tanks, tankId)}
    {:noreply, newState}
  end

  # Move a tank (set the velocity)
  def handle_cast({:move, tankId, velocity}, state) do
    updateTank = fn tank -> Tank.move(tank, velocity) end

    newTanks = Map.update!(state.tanks, tankId, updateTank)
    newState = %GameState{state | tanks: newTanks}

    {:noreply, newState}
  end
end
