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
    {:ok, pid} = GameState.create_tank("test")
    GameState.fire("test")

    bullets = GameState.get_bullets()
    assert length(bullets) == 1

    for n <- 0..115 do
      Process.send(GameState, :tick, [])
    end

    new_bullets = GameState.get_bullets()
    assert length(new_bullets) == 0
  end
end
