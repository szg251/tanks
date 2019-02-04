defmodule LodgeTest do
  use ExUnit.Case

  doctest Tanks.Lodge

  setup do
    Application.stop(:tanks)
    :ok = Application.start(:tanks)
  end
end
