defmodule GameState do
  use GenServer

  @tick_rate 30

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

      iex> GameState.get_state()
      %{tanks: [], bullets: []}

      iex> GameState.create_tank("test")
      iex> GameState.get_state()
      %{tanks: [%Tank{}], bullets: []}

  """
  def get_state do
    GenServer.call(__MODULE__, :get_state)
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
  Fires a bullet from the specified tank

    ## Example

    iex> GameState.create_tank("test")
    iex> GameState.fire("test")
    iex> GameState.get_state().bullets
    [%Bullet{x: 70, y: 564, velocity_x: 8, velocity_y: 0}]

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
    tankPids = state.tanks |> Map.values()

    tankPids |> Enum.map(&Tank.eval(&1))

    bullets =
      state.bullets
      |> Enum.reduce([], fn bullet, acc ->
        case Bullet.move(bullet) do
          {:ok, nextBullet} -> [nextBullet | acc]
          :error -> acc
        end
      end)

    remaining_bullets = GameState.get_hits(tankPids, bullets)

    schedule_tick()
    {:noreply, %GameState{state | bullets: remaining_bullets}}
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
      tanks = Map.delete(state.tanks, tankId)
      Process.exit(pid, "Removed")
      {:reply, :ok, %GameState{state | tanks: tanks}}
    else
      {:reply, :error, state}
    end
  end

  # Get all tanks
  def handle_call(:get_state, _from, state) do
    tanks =
      state.tanks
      |> Map.values()
      |> Enum.map(&Tank.get_state(&1))

    {:reply, %{tanks: tanks, bullets: state.bullets}, state}
  end

  # Get tank PID
  def handle_call({:get_pid, tankId}, _from, state) do
    {:reply, state.tanks |> Map.fetch(tankId), state}
  end

  # Fire a bullet
  def handle_cast({:fire, tankId}, state) do
    case Map.fetch(state.tanks, tankId) do
      {:ok, tankPid} ->
        case Tank.fire(tankPid) do
          {:ok, bullet} -> {:noreply, %GameState{state | bullets: [bullet | state.bullets]}}
          :error -> {:noreply, state}
        end

      :error ->
        {:noreply, state}
    end

    # with {:ok, tankPid} <- Map.fetch(state.tanks, tankId),
    #      {:ok, bullet} <- Tank.fire(tankPid) do
    #   {:noreply, %GameState{state | bullets: [bullet | state.bullets]}}
    # end
  end

  def to_api(%{tanks: tanks, bullets: bullets}) do
    %{
      tanks: tanks |> Enum.map(&Tank.to_api(&1)),
      bullets: bullets |> Enum.map(&Bullet.to_api(&1))
    }
  end

  def get_hits(tankPids, bullets) do
    hit_bullets =
      for tankPid <- tankPids, bullet <- bullets do
        tank = Tank.get_state(tankPid)

        if Field.colliding?(tank, bullet) do
          Tank.injure(tankPid, 20)
          bullet
        end
      end

    bullets
    |> Enum.filter(fn bullet ->
      Enum.all?(hit_bullets, fn hit_bullet -> hit_bullet != bullet end)
    end)
  end
end
