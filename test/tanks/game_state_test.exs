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
end
