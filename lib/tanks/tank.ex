defmodule Bullet do
  @enforce_keys [:x, :y, :velocity_x, :velocity_y]
  defstruct [:x, :y, :velocity_x, :velocity_y]

  def move(bullet) do
    movement = Field.move_object(3, bullet.x, bullet.velocity_x, 3, bullet.y, bullet.velocity_y)

    case movement do
      {:ok, newX, newY} -> %Bullet{bullet | x: newX, y: newY}
      :error -> :error
    end
  end
end

defmodule Tank do
  use GenServer

  @max_velocity 5

  defstruct health: 100,
            width: 50,
            height: 20,
            x: 0,
            y: 0,
            velocity: 0,
            direction: :right,
            turretAngle: 0

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    {:ok, %Tank{}}
  end

  # Validate and set velocity
  @spec set_velocity(atom() | pid() | {atom(), any()} | {:via, atom(), any()}, any()) :: :ok
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

  def fire(tankPid) do
    GenServer.call(tankPid, :fire)
  end

  def handle_cast({:set_velocity, velocity}, tank) do
    newTank = %Tank{tank | velocity: velocity |> min(@max_velocity) |> max(-@max_velocity)}

    {:noreply, newTank}
  end

  def handle_cast(:move, tank) do
    movement = Field.move_object(tank.width, tank.x, tank.velocity, tank.height, tank.y)

    case movement do
      {:ok, newX, newY} -> {:noreply, %Tank{tank | x: newX, y: newY}}
      :error -> {:noreply, tank}
    end
  end

  def handle_call(:get_state, _from, tank) do
    {:reply, tank, tank}
  end

  def handle_call(:fire, _from, tank) do
    bullet =
      case tank.direction do
        :left ->
          %Bullet{
            x: tank.x + 20 - round(20 * :math.cos(tank.turretAngle)),
            y: tank.y + 14 - round(20 * :math.sin(tank.turretAngle)),
            velocity_x: round(-800 * :math.cos(tank.turretAngle)),
            velocity_y: round(-800 * :math.sin(tank.turretAngle))
          }

        :right ->
          %Bullet{
            x: tank.x + 50 + round(20 * :math.cos(tank.turretAngle)),
            y: tank.y + 14 - round(20 * :math.sin(tank.turretAngle)),
            velocity_x: round(800 * :math.cos(tank.turretAngle)),
            velocity_y: round(-800 * :math.sin(tank.turretAngle))
          }
      end

    {:reply, bullet, tank}
  end
end
