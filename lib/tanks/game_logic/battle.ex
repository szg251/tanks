defmodule Tanks.GameLogic.Battle.Broadcast do
  @derive Jason.Encoder
  defstruct bullets: [],
            tanks: [],
            remaining_time: 5 * 60
end

defmodule Tanks.GameLogic.Battle do
  use GenServer, restart: :temporary

  alias Tanks.GameLogic.Battle
  alias Tanks.GameLogic.Tank
  alias Tanks.GameLogic.Bullet

  @tick_rate 30

  defstruct name: nil,
            tanks: Map.new(),
            tank_sup_pid: nil,
            bullets: [],
            remaining_ticks: round(5 * 60 * 1000 / @tick_rate),
            subscribers: Map.new(),
            prev_broadcast: %Battle.Broadcast{}

  def start_link({tank_sup_pid, name}) when is_pid(tank_sup_pid) do
    GenServer.start_link(__MODULE__, {:ok, tank_sup_pid, name}, [])
  end

  def subscribe(game_pid, id, pid) do
    GenServer.cast(game_pid, {:subscribe, id, pid})
  end

  def unsubscribe(game_pid, id) do
    GenServer.cast(game_pid, {:unsubscribe, id})
  end

  @doc """
  Creates a tank

  ## Example

    iex> {:ok, tank_sup_pid} = Tanks.GameLogic.TankSupervisor.start_link([])
    iex> {:ok, game_pid} = Tanks.GameLogic.Battle.start_link({tank_sup_pid, "test"})
    iex> {:ok, pid} = Tanks.GameLogic.Battle.create_tank(game_pid, "test")
    iex> is_pid(pid)
    true

  """
  def create_tank(game_pid, player_name, seed \\ :erlang.now()) do
    GenServer.call(game_pid, {:create_tank, player_name, seed})
  end

  @doc """
  Removes a tank and stops its process

    ## Example

    iex> {:ok, tank_sup_pid} = Tanks.GameLogic.TankSupervisor.start_link([])
    iex> {:ok, game_pid} = Tanks.GameLogic.Battle.start_link({tank_sup_pid, "test"})
    iex> Tanks.GameLogic.Battle.remove_tank(game_pid, "test")
    :error

    iex> {:ok, tank_sup_pid} = Tanks.GameLogic.TankSupervisor.start_link([])
    iex> {:ok, game_pid} = Tanks.GameLogic.Battle.start_link({tank_sup_pid, "test"})
    iex> Tanks.GameLogic.Battle.create_tank(game_pid, "test")
    iex> Tanks.GameLogic.Battle.remove_tank(game_pid, "test")
    :ok

  """
  def remove_tank(game_pid, player_name) do
    GenServer.call(game_pid, {:remove_tank, player_name})
  end

  @doc """
  Get all tanks

  ## Example

    iex> {:ok, tank_sup_pid} = Tanks.GameLogic.TankSupervisor.start_link([])
    iex> {:ok, game_pid} = Tanks.GameLogic.Battle.start_link({tank_sup_pid, "test"})
    iex> Tanks.GameLogic.Battle.get_state(game_pid)
    %{tanks: [], bullets: [], remaining_ticks: 5 * 2_000}

    iex> {:ok, tank_sup_pid} = Tanks.GameLogic.TankSupervisor.start_link([])
    iex> {:ok, game_pid} = Tanks.GameLogic.Battle.start_link({tank_sup_pid, "test"})
    iex> Tanks.GameLogic.Battle.create_tank(game_pid, "test", 0)
    iex> Tanks.GameLogic.Battle.get_state(game_pid)
    %{tanks: [%Tanks.GameLogic.Tank{x: 16, player_name: "test"}], bullets: [], remaining_ticks: 5 * 2_000}

  """
  def get_state(game_pid) do
    GenServer.call(game_pid, :get_state)
  end

  @doc """
  Get PID by tankId

    ## Examples

    iex> {:ok, tank_sup_pid} = Tanks.GameLogic.TankSupervisor.start_link([])
    iex> {:ok, game_pid} = Tanks.GameLogic.Battle.start_link({tank_sup_pid, "test"})
    iex> Tanks.GameLogic.Battle.get_pid(game_pid, "test")
    :error

    iex> {:ok, tank_sup_pid} = Tanks.GameLogic.TankSupervisor.start_link([])
    iex> {:ok, game_pid} = Tanks.GameLogic.Battle.start_link({tank_sup_pid, "test"})
    iex> Tanks.GameLogic.Battle.create_tank(game_pid, "test")
    iex> {:ok, pid} = Tanks.GameLogic.Battle.get_pid(game_pid, "test")
    iex> is_pid(pid)
    true

  """
  def get_pid(game_pid, player_name) do
    GenServer.call(game_pid, {:get_pid, player_name})
  end

  @doc """
  Count tanks

    ## Example

    iex> {:ok, tank_sup_pid} = Tanks.GameLogic.TankSupervisor.start_link([])
    iex> {:ok, game_pid} = Tanks.GameLogic.Battle.start_link({tank_sup_pid, "test"})
    iex> Tanks.GameLogic.Battle.count_tanks(game_pid)
    0

    iex> {:ok, tank_sup_pid} = Tanks.GameLogic.TankSupervisor.start_link([])
    iex> {:ok, game_pid} = Tanks.GameLogic.Battle.start_link({tank_sup_pid, "test"})
    iex> Tanks.GameLogic.Battle.create_tank(game_pid, "test")
    iex> Tanks.GameLogic.Battle.count_tanks(game_pid)
    1


  """
  def count_tanks(game_pid) do
    GenServer.call(game_pid, :count_tanks)
  end

  @doc """
  Fires a bullet from the specified tank

    ## Example

    iex> {:ok, tank_sup_pid} = Tanks.GameLogic.TankSupervisor.start_link([])
    iex> {:ok, game_pid} = Tanks.GameLogic.Battle.start_link({tank_sup_pid, "test"})
    iex> Tanks.GameLogic.Battle.create_tank(game_pid, "test")
    iex> Tanks.GameLogic.Battle.fire(game_pid, "test")
    iex> Tanks.GameLogic.Battle.get_state(game_pid).bullets |> length
    1

  """
  def fire(game_pid, player_name) do
    GenServer.cast(game_pid, {:fire, player_name})
  end

  defp schedule_tick() do
    Process.send_after(self(), :tick, @tick_rate)
  end

  ##########
  # SERVER #
  ##########

  def init({:ok, tank_sup_pid, name}) when is_pid(tank_sup_pid) do
    schedule_tick()
    {:ok, %Battle{tank_sup_pid: tank_sup_pid, name: name}}
  end

  # Evaluate movement
  def handle_info(:tick, state) do
    tank_pids = state.tanks |> Map.values()

    tank_pids |> Enum.each(&Tank.eval(&1))

    bullets =
      state.bullets
      |> Enum.reduce([], fn bullet, acc ->
        case Bullet.move(bullet) do
          {:ok, nextBullet} -> [nextBullet | acc]
          :error -> acc
        end
      end)

    remaining_bullets = Battle.get_hits(tank_pids, bullets)
    remaining_ticks = state.remaining_ticks - 1

    new_state = %Battle{state | bullets: remaining_bullets, remaining_ticks: remaining_ticks}

    if remaining_ticks > 0 do
      next_broadcast =
        %{
          tanks: get_tank_states(state.tanks),
          bullets: remaining_bullets,
          remaining_ticks: remaining_ticks
        }
        |> to_api

      if state.prev_broadcast != next_broadcast do
        state.subscribers
        |> Map.values()
        |> Enum.each(&Process.send(&1, {:broadcast, next_broadcast}, []))
      end

      schedule_tick()
      {:noreply, %{new_state | prev_broadcast: next_broadcast}}
    else
      tanks = get_tank_states(state.tanks)

      state.subscribers
      |> Map.values()
      |> Enum.each(&Process.send(&1, {:end_battle, tanks}, []))

      Tanks.Lodge.close_battle(state.name)
      {:noreply, state}
    end
  end

  # Handle stopped processes
  def handle_info({:DOWN, _ref, :process, old_pid, _reason}, state) do
    tanks =
      state.tanks
      |> Enum.reduce([], fn {k, pid}, arr ->
        if old_pid == pid, do: [{k, pid} | arr], else: arr
      end)
      |> Enum.into(%{})

    {:noreply, %Battle{tanks: tanks}}
  end

  # Create a new tank
  def handle_call({:create_tank, player_name, seed}, _from, state) do
    if !Map.has_key?(state.tanks, player_name) do
      {:ok, tank_pid} =
        Tanks.GameLogic.TankSupervisor.add_tank(state.tank_sup_pid, player_name, seed)

      Process.monitor(tank_pid)

      newState = %Battle{state | tanks: state.tanks |> Map.put_new(player_name, tank_pid)}
      {:reply, {:ok, tank_pid}, newState}
    else
      {:reply, {:error, "Already existing"}, state}
    end
  end

  # Remove tank
  def handle_call({:remove_tank, player_name}, _from, state) do
    if Map.has_key?(state.tanks, player_name) do
      tank_pid = Map.fetch!(state.tanks, player_name)
      tanks = Map.delete(state.tanks, player_name)
      Tanks.GameLogic.TankSupervisor.remove_tank(state.tank_sup_pid, tank_pid)
      {:reply, :ok, %Battle{state | tanks: tanks}}
    else
      {:reply, :error, state}
    end
  end

  # Get all tanks
  def handle_call(:get_state, _from, state) do
    tanks = get_tank_states(state.tanks)

    {:reply, %{tanks: tanks, bullets: state.bullets, remaining_ticks: state.remaining_ticks},
     state}
  end

  # Get tank PID
  def handle_call({:get_pid, player_name}, _from, state) do
    {:reply, state.tanks |> Map.fetch(player_name), state}
  end

  # Count tanks
  def handle_call(:count_tanks, _from, state) do
    {:reply, state.tanks |> Map.size(), state}
    # {:reply, Tanks.GameLogic.TankSupervisor.count_tanks(state.tank_sup_pid).active, state}
  end

  def handle_cast({:subscribe, id, pid}, state) do
    Process.send(pid, {:broadcast, state.prev_broadcast}, [])
    {:noreply, %Battle{state | subscribers: Map.put(state.subscribers, id, pid)}}
  end

  def handle_cast({:unsubscribe, id}, state) do
    {:noreply, %Battle{state | subscribers: Map.delete(state.subscribers, id)}}
  end

  # Fire a bullet
  def handle_cast({:fire, player_name}, state) do
    case Map.fetch(state.tanks, player_name) do
      {:ok, tank_pid} ->
        case Tank.fire(tank_pid) do
          {:ok, bullet} -> {:noreply, %Battle{state | bullets: [bullet | state.bullets]}}
          :error -> {:noreply, state}
        end

      :error ->
        {:noreply, state}
    end
  end

  def to_api(%{tanks: tanks, bullets: bullets, remaining_ticks: remaining_ticks}) do
    %Battle.Broadcast{
      tanks: tanks |> Enum.map(&Tank.to_api(&1)),
      bullets: bullets |> Enum.map(&Bullet.to_api(&1)),
      remaining_time: (remaining_ticks * @tick_rate / 1000) |> round()
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

  defp get_tank_states(tanks) do
    tanks
    |> Map.values()
    |> Enum.map(&Tank.get_state(&1))
  end
end
