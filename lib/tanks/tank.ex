defmodule Bullet do
  @enforce_keys [:x, :y, :velocity_x, :velocity_y]
  defstruct [:x, :y, :velocity_x, :velocity_y]

  @doc """
  Evaluate the movement of a bullet

    iex> bullet = %Bullet{x: 50, y: 50, velocity_x: 5, velocity_y: -5}
    iex> Bullet.move(bullet)
    {:ok, %Bullet{x: 55, y: 50, velocity_x: 5, velocity_y: -5}}

  """
  def move(bullet) do
    movement =
      Field.move_object(3, bullet.x, bullet.velocity_x, 3, bullet.y, bullet.velocity_y, true)

    case movement do
      {:ok, newX, newY} -> {:ok, %Bullet{bullet | x: newX, y: newY}}
      :error -> :error
    end
  end
end

defmodule Tank do
  use GenServer

  @max_velocity 5
  @max_turret_angle_velocity 0.1
  @max_turret_angle 1
  @bullet_velocity 8

  defstruct health: 100,
            width: 50,
            height: 20,
            x: 0,
            y: 550,
            velocity: 0,
            direction: :right,
            turret_angle: 0.0,
            turret_angle_velocity: 0.0

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Get current state of a tank

    ## Example

    iex> {:ok, pid} = Tank.start_link([])
    iex> Tank.get_state(pid)
    %Tank{}

  """
  def get_state(tankPid) do
    GenServer.call(tankPid, :get_state)
  end

  @doc """
  Validate and set velocity

    ## Example

    iex> {:ok, pid} = Tank.start_link([])
    iex> Tank.set_velocity(pid, 10)
    iex> Tank.get_state(pid)
    %Tank{velocity: 5}

  """
  def set_velocity(tankPid, velocity) do
    GenServer.cast(tankPid, {:set_velocity, velocity})
  end

  @doc """
  Validate and set turret angle

    ## Examples

    iex> {:ok, pid} = Tank.start_link([])
    iex> Tank.set_turret_angle_velocity(pid, 0.01)
    iex> Tank.get_state(pid)
    %Tank{turret_angle_velocity: 0.01}

    iex> {:ok, pid} = Tank.start_link([])
    iex> Tank.set_turret_angle_velocity(pid, -0.7)
    iex> Tank.get_state(pid)
    %Tank{turret_angle_velocity: -0.1}

  """
  def set_turret_angle_velocity(tankPid, angle) do
    GenServer.cast(tankPid, {:set_turret_angle_velocity, angle})
  end

  @doc """
  Evaluate the movement of a tank

    ## Example

    iex> {:ok, pid} = Tank.start_link([])
    iex> Tank.set_velocity(pid, 10)
    iex> Tank.set_turret_angle_velocity(pid, 0.1)
    iex> Tank.eval(pid)
    iex> Tank.get_state(pid)
    %Tank{velocity: 5, turret_angle_velocity: 0.1, x: 5, turret_angle: 0.1}

  """
  def eval(tankPid) do
    GenServer.cast(tankPid, :eval)
  end

  @doc """
  Fire a bullet

    ## Example

    iex> {:ok, pid} = Tank.start_link([])
    iex> Tank.fire(pid)
    %Bullet{x: 70, y: 564, velocity_x: 8, velocity_y: 0}

  """
  def fire(tankPid) do
    GenServer.call(tankPid, :fire)
  end

  ##########
  # SERVER #
  ##########

  def init(:ok) do
    {:ok, %Tank{}}
  end

  def handle_cast({:set_velocity, velocity}, tank) do
    newTank = %Tank{tank | velocity: velocity |> min(@max_velocity) |> max(-@max_velocity)}

    {:noreply, newTank}
  end

  def handle_cast(:eval, tank) do
    movement = Field.move_object(tank.width, tank.x, tank.velocity, tank.height, tank.y)

    new_tank =
      case movement do
        {:ok, newX, newY} -> %Tank{tank | x: newX, y: newY}
        :error -> tank
      end
      |> move_turret()

    {:noreply, new_tank}
  end

  def handle_cast({:set_turret_angle_velocity, angle}, tank) do
    newAngle =
      angle
      |> min(@max_turret_angle_velocity)
      |> max(-@max_turret_angle_velocity)

    {:noreply, %Tank{tank | turret_angle_velocity: newAngle}}
  end

  def handle_call(:get_state, _from, tank) do
    {:reply, tank, tank}
  end

  def handle_call(:fire, _from, tank) do
    bullet =
      case tank.direction do
        :left ->
          %Bullet{
            x: tank.x + 20 - round(20 * :math.cos(tank.turret_angle)),
            y: tank.y + 14 - round(20 * :math.sin(tank.turret_angle)),
            velocity_x: round(-@bullet_velocity * :math.cos(tank.turret_angle)),
            velocity_y: round(-@bullet_velocity * :math.sin(tank.turret_angle))
          }

        :right ->
          %Bullet{
            x: tank.x + 50 + round(20 * :math.cos(tank.turret_angle)),
            y: tank.y + 14 - round(20 * :math.sin(tank.turret_angle)),
            velocity_x: round(@bullet_velocity * :math.cos(tank.turret_angle)),
            velocity_y: round(-@bullet_velocity * :math.sin(tank.turret_angle))
          }
      end

    {:reply, bullet, tank}
  end

  defp move_turret(tank) do
    %Tank{
      tank
      | turret_angle:
          (tank.turret_angle + tank.turret_angle_velocity)
          |> max(-@max_turret_angle)
          |> min(@max_turret_angle)
    }
  end
end
