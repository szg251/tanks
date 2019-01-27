defmodule Bullet do
  @enforce_keys [:x, :y, :velocity_x, :velocity_y]
  @derive {Jason.Encoder, only: [:x, :y]}
  defstruct width: 3, height: 3, x: 0, y: 0, velocity_x: 0, velocity_y: 0

  @doc """
  Evaluate the movement of a bullet

    iex> bullet = %Bullet{x: 50, y: 50, velocity_x: 5, velocity_y: -5}
    iex> Bullet.move(bullet)
    {:ok, %Bullet{x: 55, y: 45.1, velocity_x: 5, velocity_y: -4.9}}

  """
  def move(bullet) do
    bullet
    |> Field.apply_gravity()
    |> Field.move_object()
  end

  def to_api(%Bullet{x: x, y: y}) do
    %{
      x: round(x),
      y: round(y)
    }
  end
end

defmodule Tank do
  use GenServer

  @max_velocity 5
  @max_turret_angle_velocity 0.03
  @max_turret_angle 0.5
  @min_turret_angle -0.2
  @bullet_velocity 8
  @loading_speed 1

  @derive {Jason.Encoder, only: [:health, :x, :y, :turret_angle, :load, :direction]}
  defstruct health: 100,
            width: 60,
            height: 40,
            x: 0,
            y: 560,
            load: 100,
            velocity_x: 0,
            velocity_y: 0,
            direction: :right,
            turret_angle: 0.0,
            turret_angle_velocity: 0.0

  def to_api(tank) do
    %Tank{
      tank
      | x: round(tank.x),
        y: round(tank.y)
    }
  end

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
    iex> Tank.set_movement(pid, -10)
    iex> Tank.get_state(pid)
    %Tank{velocity_x: -5, direction: :left}

  """
  def set_movement(tankPid, velocity) do
    GenServer.cast(tankPid, {:set_movement, velocity})
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
    %Tank{turret_angle_velocity: -0.03}

  """
  def set_turret_angle_velocity(tankPid, angle) do
    GenServer.cast(tankPid, {:set_turret_angle_velocity, angle})
  end

  @doc """
  Evaluate the movement of a tank

    ## Example

    iex> {:ok, pid} = Tank.start_link([])
    iex> Tank.set_movement(pid, 10)
    iex> Tank.set_turret_angle_velocity(pid, 0.03)
    iex> Tank.fire(pid)
    iex> Tank.eval(pid)
    iex> Tank.get_state(pid)
    %Tank{velocity_x: 5, turret_angle_velocity: 0.03, x: 5, turret_angle: 0.03, load: 1}

  """
  def eval(tankPid) do
    GenServer.cast(tankPid, :eval)
  end

  @doc """
  Fire a bullet

    ## Example

    iex> {:ok, pid} = Tank.start_link([])
    iex> Tank.fire(pid)
    {:ok, %Bullet{x: 70, y: 564, velocity_x: 8, velocity_y: 0}}

  """
  def fire(tankPid) do
    GenServer.call(tankPid, :fire)
  end

  @doc """
  Injure hits

    iex> {:ok, pid} = Tank.start_link([])
    iex> Tank.injure(pid, 10)
    iex> Tank.get_state(pid)
    %Tank{health: 90}
  """
  def injure(tankPid, healthPenalty) do
    GenServer.cast(tankPid, {:injure, healthPenalty})
  end

  ##########
  # SERVER #
  ##########

  def init(:ok) do
    {:ok, %Tank{}}
  end

  def handle_cast({:set_movement, velocity}, tank) do
    direction =
      cond do
        velocity < 0 -> :left
        velocity > 0 -> :right
        velocity == 0 -> tank.direction
      end

    velocity_x = velocity |> min(@max_velocity) |> max(-@max_velocity)
    newTank = %Tank{tank | velocity_x: velocity_x, direction: direction}

    {:noreply, newTank}
  end

  def handle_cast(:eval, tank) do
    new_tank =
      case Field.move_object(tank) do
        {:ok, moved_tank} -> moved_tank
        :error -> tank
      end
      |> move_turret()
      |> load_bullet()

    {:noreply, new_tank}
  end

  def handle_cast({:set_turret_angle_velocity, angle}, tank) do
    newAngle =
      angle
      |> min(@max_turret_angle_velocity)
      |> max(-@max_turret_angle_velocity)

    {:noreply, %Tank{tank | turret_angle_velocity: newAngle}}
  end

  def handle_cast({:injure, healthPenalty}, tank) do
    {:noreply, %Tank{tank | health: tank.health - healthPenalty}}
  end

  def handle_call(:get_state, _from, tank) do
    {:reply, tank, tank}
  end

  def handle_call(:fire, _from, tank) do
    if tank.load != 100 do
      {:reply, :error, tank}
    else
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

      {:reply, {:ok, bullet}, %Tank{tank | load: 0}}
    end
  end

  defp move_turret(tank) do
    %Tank{
      tank
      | turret_angle:
          (tank.turret_angle + tank.turret_angle_velocity)
          |> min(@max_turret_angle)
          |> max(@min_turret_angle)
    }
  end

  defp load_bullet(tank) do
    %Tank{
      tank
      | load: (tank.load + @loading_speed) |> min(100)
    }
  end
end
