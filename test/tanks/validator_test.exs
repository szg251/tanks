defmodule ValidatorTest do
  use ExUnit.Case
  use ExCheck

  doctest Tanks.Validator

  describe "comined validator" do
    property "valid values" do
      validators = [Tanks.Validator.min(5), Tanks.Validator.max(10)]

      for_all str in binary() do
        implies(String.length(str) >= 5 and String.length(str) <= 10) do
          {:ok, str} == Tanks.Validator.valid?(validators, str)
        end
      end
    end

    property "short strings" do
      validators = [Tanks.Validator.min(5), Tanks.Validator.max(10)]

      for_all str in binary() do
        implies(String.length(str) < 5) do
          {:error, "too short"} == Tanks.Validator.valid?(validators, str)
        end
      end
    end

    property "long strings" do
      validators = [Tanks.Validator.min(5), Tanks.Validator.max(10)]

      for_all str in binary() do
        implies(String.length(str) > 10) do
          {:error, "too long"} == Tanks.Validator.valid?(validators, str)
        end
      end
    end
  end
end
