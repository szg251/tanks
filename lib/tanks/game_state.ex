defmodule Field do
  @field_width 1000
  @field_height 600

  @doc """
  Moving an object on the field
  results in :error if out of boundaries

    #Examples

    iex> Field.move_object(10, 0, -5, 10, 0)
    :error

    iex> Field.move_object(10, 10, -5, 10, 10, 5)
    {:ok, 5, 15}

  """
  def move_object(object_width, object_x, velocity_x, object_height, object_y, velocity_y \\ 0) do
    newX = object_x + velocity_x
    newY = object_y + velocity_y

    cond do
      newX < 0 or newX > @field_width - object_width -> :error
      newY < 0 or newY > @field_height - object_height -> :error
      true -> {:ok, newX, newY}
    end
  end
end

defmodule GameState do
  use GenServer

  @tick_rate 100

  defstruct tanks: Map.new(),
            bullets: []

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts ++ [name: __MODULE__])
  end

  @doc """
  Creates a tank

  ## Example

      iex> {:ok, pid} = GameState.create_tank("test")
      iex> is_pid(pid)
      true

  """
  def create_tank(tankId) do
    GenServer.call(__MODULE__, {:create_tank, tankId})
  end

  @doc """
  Removes a tank and stops its process

    ## Example

    iex> GameState.remove_tank("test")
    :error

    iex> GameState.create_tank("test")
    iex> GameState.remove_tank("test")
    :ok

  """
  def remove_tank(tankId) do
    GenServer.call(__MODULE__, {:remove_tank, tankId})
  end

  @doc """
  Get all tanks

  ## Example

      iex> GameState.get_tanks()
      []

      iex> GameState.create_tank("test")
      iex> GameState.get_tanks()
      [%Tank{}]

  """
  def get_tanks do
    GenServer.call(__MODULE__, :get_tanks)
  end

  @doc """
  Get PID by tankId

    ## Examples

    iex> GameState.get_pid("test")
    :error

    iex> GameState.create_tank("test")
    iex> {:ok, pid} = GameState.get_pid("test")
    iex> is_pid(pid)
    true

  """
  def get_pid(tankId) do
    GenServer.call(__MODULE__, {:get_pid, tankId})
  end

  @doc """
  Get all bullets

    ## Example

    iex> GameState.get_bullets()
    []

  """
  def get_bullets do
    GenServer.call(__MODULE__, :get_bullets)
  end

  @doc """
  Fires a bullet from the specified tank

    ## Example

    iex> GameState.create_tank("test")
    iex> GameState.fire("test")
    iex> GameState.get_bullets()
    [%Bullet{x: 70, y: 14, velocity_x: 800, velocity_y: 0}]

  """
  def fire(tankId) do
    GenServer.cast(__MODULE__, {:fire, tankId})
  end

  defp schedule_tick() do
    Process.send_after(self(), :tick, @tick_rate)
  end

  ##########
  # SERVER #
  ##########

  def init(:ok) do
    schedule_tick()
    {:ok, %GameState{}}
  end

  # Evaluate movement
  def handle_info(:tick, state) do
    state.tanks |> Map.values() |> Enum.map(&Tank.move(&1))

    bullets =
      state.bullets
      |> Enum.reduce([], fn bullet, acc ->
        case Bullet.move(bullet) do
          {:ok, nextBullet} -> [nextBullet | acc]
          :error -> acc
        end
      end)

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

  # Remove tank
  def handle_call({:remove_tank, tankId}, _from, state) do
    if Map.has_key?(state.tanks, tankId) do
      pid = Map.fetch!(state.tanks, tankId)
      Process.exit(pid, "Removed")
      tanks = Map.delete(state.tanks, tankId)
      {:reply, :ok, %GameState{state | tanks: tanks}}
    else
      {:reply, :error, state}
    end
  end

  # Get all tanks
  def handle_call(:get_tanks, _from, state) do
    tanks =
      state.tanks
      |> Map.values()
      |> Enum.map(&Tank.get_state(&1))

    {:reply, tanks, state}
  end

  # Get tank PID
  def handle_call({:get_pid, tankId}, _from, state) do
    {:reply, state.tanks |> Map.fetch(tankId), state}
  end

  # Get all bullets
  def handle_call(:get_bullets, _from, state) do
    {:reply, state.bullets, state}
  end

  # Fire a bullet
  def handle_cast({:fire, tankId}, state) do
    case Map.fetch(state.tanks, tankId) do
      {:ok, tankPid} ->
        newState = %GameState{state | bullets: [Tank.fire(tankPid) | state.bullets]}
        {:noreply, newState}

      :error ->
        {:noreply, state}
    end
  end
end
