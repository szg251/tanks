defmodule BattleLodgeTest do
  use ExUnit.Case

  doctest Tanks.BattleLodge

  setup do
    Application.stop(:tanks)
    :ok = Application.start(:tanks)
  end
end
