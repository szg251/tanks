defmodule BattleTest do
  use ExUnit.Case

  alias Tanks.GameLogic.Battle
  alias Tanks.GameLogic.TankSupervisor
  alias Tanks.GameLogic.Tank
  alias Tanks.GameLogic.Bullet

  doctest Tanks.GameLogic.Battle
  doctest Tanks.GameLogic.Field

  setup do
    Application.stop(:tanks)
    :ok = Application.start(:tanks)
  end

  test "Removing a tank also stops its process" do
    {:ok, tank_sup_pid} = TankSupervisor.start_link([])
    {:ok, game_pid} = Battle.start_link(tank_sup_pid)
    {:ok, pid} = Battle.create_tank(game_pid, "test")
    Battle.remove_tank(game_pid, "test")

    assert !Process.alive?(pid)
  end

  test "Bullet out of field" do
    {:ok, tank_sup_pid} = TankSupervisor.start_link([])
    {:ok, game_pid} = Battle.start_link(tank_sup_pid)
    Battle.create_tank(game_pid, "test")
    Battle.fire(game_pid, "test")

    bullets = Battle.get_state(game_pid).bullets
    assert length(bullets) == 1

    for _ <- 0..115 do
      Process.send(game_pid, :tick, [])
    end

    new_bullets = Battle.get_state(game_pid).bullets
    assert length(new_bullets) == 0
  end

  test "Evaluate hits" do
    {:ok, tank_sup_pid} = TankSupervisor.start_link([])
    {:ok, game_pid} = Battle.start_link(tank_sup_pid)
    {:ok, tank_pid} = Battle.create_tank(game_pid, "test")
    tanks = [tank_pid]

    bullets = [
      %Bullet{width: 3, height: 3, x: 10, y: 560, velocity_x: 0, velocity_y: 0},
      %Bullet{width: 3, height: 3, x: 15, y: 560, velocity_x: 0, velocity_y: 0},
      %Bullet{width: 3, height: 3, x: 10, y: 450, velocity_x: 0, velocity_y: 0}
    ]

    remained_bullets = Battle.get_hits(tanks, bullets)

    assert length(remained_bullets) == 1

    hit_tank = Tank.get_state(tank_pid)

    assert hit_tank == %Tank{health: 60}
  end

  test "Tank process restarts when killed" do
    {:ok, tank_sup_pid} = TankSupervisor.start_link([])
    {:ok, game_pid} = Battle.start_link(tank_sup_pid)
    {:ok, pid} = Battle.create_tank(game_pid, "test")

    Process.exit(pid, :kill)
    new_pid = Battle.get_pid(game_pid, "test")
    assert pid != new_pid
  end
end
