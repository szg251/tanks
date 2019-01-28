defmodule GameStateTest do
  use ExUnit.Case
  doctest GameState
  doctest Field

  setup do
    Application.stop(:tanks)
    :ok = Application.start(:tanks)
  end

  test "Removing a tank also stops its process" do
    {:ok, pid} = GameState.create_tank("test")
    GameState.remove_tank("test")

    assert !Process.alive?(pid)
  end

  test "Bullet out of field" do
    GameState.create_tank("test")
    GameState.fire("test")

    bullets = GameState.get_state().bullets
    assert length(bullets) == 1

    for _ <- 0..115 do
      Process.send(GameState, :tick, [])
    end

    new_bullets = GameState.get_state().bullets
    assert length(new_bullets) == 0
  end

  test "Evaluate hits" do
    {:ok, tankPid} = GameState.create_tank("test")
    tanks = [tankPid]

    bullets = [
      %Bullet{width: 3, height: 3, x: 10, y: 560, velocity_x: 0, velocity_y: 0},
      %Bullet{width: 3, height: 3, x: 15, y: 560, velocity_x: 0, velocity_y: 0},
      %Bullet{width: 3, height: 3, x: 10, y: 450, velocity_x: 0, velocity_y: 0}
    ]

    remained_bullets = GameState.get_hits(tanks, bullets)

    assert length(remained_bullets) == 1

    hit_tank = Tank.get_state(tankPid)

    assert hit_tank == %Tank{health: 60}
  end
end
