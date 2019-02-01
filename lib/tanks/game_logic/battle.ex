defmodule Tanks.GameLogic.Battle do
  use GenServer

  alias Tanks.GameLogic.Battle
  alias Tanks.GameLogic.Tank
  alias Tanks.GameLogic.Bullet

  @tick_rate 30

  # @enforce_keys [:tank_sup_pid]
  defstruct tanks: Map.new(),
            tank_sup_pid: nil,
            bullets: []

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Creates a tank

  ## Example

      iex> {:ok, game_pid} = Tanks.GameLogic.Battle.start_link([])
      iex> {:ok, pid} = Tanks.GameLogic.Battle.create_tank(game_pid, "test")
      iex> is_pid(pid)
      true

  """
  def create_tank(game_pid, tank_id) do
    GenServer.call(game_pid, {:create_tank, tank_id})
  end

  @doc """
  Removes a tank and stops its process

    ## Example

    iex> {:ok, game_pid} = Tanks.GameLogic.Battle.start_link([])
    iex> Tanks.GameLogic.Battle.remove_tank(game_pid, "test")
    :error

    iex> {:ok, game_pid} = Tanks.GameLogic.Battle.start_link([])
    iex> Tanks.GameLogic.Battle.create_tank(game_pid, "test")
    iex> Tanks.GameLogic.Battle.remove_tank(game_pid, "test")
    :ok

  """
  def remove_tank(game_pid, tank_id) do
    GenServer.call(game_pid, {:remove_tank, tank_id})
  end

  @doc """
  Get all tanks

  ## Example

      iex> {:ok, game_pid} = Tanks.GameLogic.Battle.start_link([])
      iex> Tanks.GameLogic.Battle.get_state(game_pid)
      %{tanks: [], bullets: []}

      iex> {:ok, game_pid} = Tanks.GameLogic.Battle.start_link([])
      iex> Tanks.GameLogic.Battle.create_tank(game_pid, "test")
      iex> Tanks.GameLogic.Battle.get_state(game_pid)
      %{tanks: [%Tanks.GameLogic.Tank{}], bullets: []}

  """
  def get_state(game_pid) do
    GenServer.call(game_pid, :get_state)
  end

  @doc """
  Get PID by tankId

    ## Examples

    iex> {:ok, game_pid} = Tanks.GameLogic.Battle.start_link([])
    iex> Tanks.GameLogic.Battle.get_pid(game_pid, "test")
    :error

    iex> {:ok, game_pid} = Tanks.GameLogic.Battle.start_link([])
    iex> Tanks.GameLogic.Battle.create_tank(game_pid, "test")
    iex> {:ok, pid} = Tanks.GameLogic.Battle.get_pid(game_pid, "test")
    iex> is_pid(pid)
    true

  """
  def get_pid(game_pid, tank_id) do
    GenServer.call(game_pid, {:get_pid, tank_id})
  end

  @doc """
  Fires a bullet from the specified tank

    ## Example

    iex> {:ok, game_pid} = Tanks.GameLogic.Battle.start_link([])
    iex> Tanks.GameLogic.Battle.create_tank(game_pid, "test")
    iex> Tanks.GameLogic.Battle.fire(game_pid, "test")
    iex> Tanks.GameLogic.Battle.get_state(game_pid).bullets
    [%Bullet{x: 70, y: 574, velocity_x: 8, velocity_y: 0}]

  """
  def fire(game_pid, tank_id) do
    GenServer.cast(game_pid, {:fire, tank_id})
  end

  defp schedule_tick() do
    Process.send_after(self(), :tick, @tick_rate)
  end

  ##########
  # SERVER #
  ##########

  def init(:ok) do
    {:ok, tank_sup_pid} = Tanks.GameLogic.TankSupervisor.start_link([])
    schedule_tick()
    {:ok, %Battle{tank_sup_pid: tank_sup_pid}}
  end

  # Evaluate movement
  def handle_info(:tick, state) do
    tank_pids = state.tanks |> Map.values()

    tank_pids |> Enum.map(&Tank.eval(&1))

    bullets =
      state.bullets
      |> Enum.reduce([], fn bullet, acc ->
        case Bullet.move(bullet) do
          {:ok, nextBullet} -> [nextBullet | acc]
          :error -> acc
        end
      end)

    remaining_bullets = Battle.get_hits(tank_pids, bullets)

    schedule_tick()
    {:noreply, %Battle{state | bullets: remaining_bullets}}
  end

  # Handle stopped processes
  def handle_info({:DOWN, _ref, :process, old_pid, _reason}, state) do
    tanks =
      for {k, pid} <- state.tanks, into: %{} do
        if pid == old_pid do
          {:ok, new_pid} = Tanks.GameLogic.TankSupervisor.add_tank(state.tank_sup_pid)
          {k, new_pid}
        else
          {k, pid}
        end
      end

    {:noreply, %Battle{tanks: tanks}}
  end

  # Create a new tank
  def handle_call({:create_tank, tank_id}, _from, state) do
    if !Map.has_key?(state.tanks, tank_id) do
      {:ok, tank_pid} = Tanks.GameLogic.TankSupervisor.add_tank(state.tank_sup_pid)
      Process.monitor(tank_pid)

      newState = %Battle{state | tanks: state.tanks |> Map.put_new(tank_id, tank_pid)}
      {:reply, {:ok, tank_pid}, newState}
    else
      {:reply, {:error, "Already existing"}, state}
    end
  end

  # Remove tank
  def handle_call({:remove_tank, tank_id}, _from, state) do
    if Map.has_key?(state.tanks, tank_id) do
      tank_pid = Map.fetch!(state.tanks, tank_id)
      tanks = Map.delete(state.tanks, tank_id)
      Tanks.GameLogic.TankSupervisor.remove_tank(state.tank_sup_pid, tank_pid)
      {:reply, :ok, %Battle{state | tanks: tanks}}
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
  def handle_call({:get_pid, tank_id}, _from, state) do
    {:reply, state.tanks |> Map.fetch(tank_id), state}
  end

  # Fire a bullet
  def handle_cast({:fire, tank_id}, state) do
    case Map.fetch(state.tanks, tank_id) do
      {:ok, tank_pid} ->
        case Tank.fire(tank_pid) do
          {:ok, bullet} -> {:noreply, %Battle{state | bullets: [bullet | state.bullets]}}
          :error -> {:noreply, state}
        end

      :error ->
        {:noreply, state}
    end
  end

  def to_api(%{tanks: tanks, bullets: bullets}) do
    %{
      tanks: tanks |> Enum.map(&Tank.to_api(&1)),
      bullets: bullets |> Enum.map(&Bullet.to_api(&1))
    }
  end

  def get_hits(tank_pids, bullets) do
    hit_bullets =
      for tank_pid <- tank_pids, bullet <- bullets do
        tank = Tank.get_state(tank_pid)

        if Tanks.GameLogic.Field.colliding?(tank, bullet) do
          Tank.injure(tank_pid, 20)
          bullet
        end
      end

    bullets
    |> Enum.filter(fn bullet ->
      Enum.all?(hit_bullets, fn hit_bullet -> hit_bullet != bullet end)
    end)
  end
end
