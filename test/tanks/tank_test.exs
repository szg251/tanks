defmodule TankTest do
  use ExUnit.Case
  doctest Tank
  doctest Bullet

  test "Firing with different turret angles" do
    {:ok, pid} = Tank.start_link([])
    bullet1 = Tank.fire(pid)

    Tank.set_turret_angle_velocity(pid, 0.1)
    Tank.eval(pid)
    bullet2 = Tank.fire(pid)

    assert bullet1 !== bullet2
  end
end
