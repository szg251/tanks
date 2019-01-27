defmodule TankTest do
  use ExUnit.Case
  doctest Tank
  doctest Bullet

  test "Firing a bullet resets load counter" do
    {:ok, pid} = Tank.start_link([])
    Tank.fire(pid)

    tank = Tank.get_state(pid)
    assert tank == %Tank{load: 0}
  end

  test "Cannot fire while loading" do
    {:ok, pid} = Tank.start_link([])
    Tank.fire(pid)
    bullet = Tank.fire(pid)

    assert bullet == :error
  end

  test "Firing from different turret angles" do
    {:ok, pid} = Tank.start_link([])
    {:ok, bullet1} = Tank.fire(pid)

    Tank.set_turret_angle_velocity(pid, 0.04)
    # Wait 100 steps to reload
    for _ <- 0..100, do: Tank.eval(pid)
    {:ok, bullet2} = Tank.fire(pid)

    assert bullet1.y !== bullet2.y
    assert bullet1.velocity_y !== bullet2.velocity_y
  end
end
