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
end
