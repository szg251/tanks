defmodule Field do
  @field_width 1000
  @field_height 600

  def move_object(object_width, object_x, velocity_x, object_height, object_y, velocity_y \\ 0) do
    newX = (object_x + velocity_x) |> min(@field_width - object_width) |> max(0)
    newY = (object_y + velocity_y) |> min(@field_height - object_height) |> max(0)

    cond do
      newX < 0 or newX > @field_width - object_width -> :error
      newY < 0 or newY > @field_height - object_height -> :error
      true -> {:ok, newX, newY}
    end
  end
end

defmodule GameState do
  use GenServer

  defstruct tanks: Map.new(),
            bullets: []

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts ++ [name: __MODULE__])
  end

  def create_tank(tankId) do
    GenServer.call(__MODULE__, {:create_tank, tankId})
  end

  def get_tanks do
    GenServer.call(__MODULE__, :get_tanks)
  end

  def get_bullets do
    GenServer.call(__MODULE__, :get_bullets)
  end

  def fire(tankId) do
    GenServer.cast(__MODULE__, {:fire, tankId})
  end

  def remove_tank(tankId) do
    GenServer.cast(__MODULE__, {:remove_tank, tankId})
  end

  defp schedule_tick() do
    Process.send_after(self(), :tick, 100)
  end

  ### SERVER ###

  def init(:ok) do
    schedule_tick()
    {:ok, %GameState{}}
  end

  # Evaluate movement
  def handle_info(:tick, state) do
    state.tanks |> Map.values() |> Enum.map(&Tank.move(&1))
    bullets = state.bullets |> Enum.map(&Bullet.move(&1))
    schedule_tick()
    {:noreply, %GameState{state | bullets: bullets}}
  end

  # Create a new tank
  def handle_call({:create_tank, tankId}, _from, state) do
    if !Map.has_key?(state.tanks, tankId) do
      {:ok, tankPid} = Tank.start_link([])
      newState = %GameState{state | tanks: state.tanks |> Map.put_new(tankId, tankPid)}
      {:reply, {:ok, tankPid}, newState}
    else
      {:reply, {:error, "Already existing"}, state}
    end
  end

  # Get all tanks
  def handle_call(:get_tanks, _from, state) do
    tanks =
      state.tanks
      |> Map.values()
      |> Enum.map(fn pid -> %{pid: pid, tank: Tank.get_state(pid)} end)

    {:reply, tanks, state}
  end

  # Get all bullets
  def handle_call(:get_bullets, _from, state) do
    {:reply, state.bullets, state}
  end

  def handle_cast({:fire, tankId}, state) do
    case Map.fetch(state.tanks, tankId) do
      {:ok, tankPid} ->
        newState = %GameState{state | bullets: [Tank.fire(tankPid) | state.bullets]}
        {:noreply, newState}

      :error ->
        {:noreply, state}
    end
  end

  # Remove tank
  def handle_cast({:remove_tank, tankId}, state) do
    newState = %GameState{state | tanks: Map.delete(state.tanks, tankId)}
    {:noreply, newState}
  end
end
