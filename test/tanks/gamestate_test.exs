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

  # test "Move tank (setting velocity)" do
  #   Tank.set_velocity(pid, 2)

  #   assert GameState.get_tanks() == [%{pid: pid, tank: %Tank{velocity: 2}}]
  # end
end
