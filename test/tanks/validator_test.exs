defmodule ValidatorTest do
  use ExUnit.Case
  use ExCheck

  import Tanks.Validator

  doctest Tanks.Validator

  describe "single validator" do
    test "min valid" do
      validator = min(5)

      assert valid?(validator, "12345") == {:ok, "12345"}
    end

    test "min invalid" do
      validator = min(5)

      assert valid?(validator, "1234") == {:error, "too short"}
    end

    test "max valid" do
      validator = max(5)

      assert valid?(validator, "12345") == {:ok, "12345"}
    end

    test "max invalid" do
      validator = max(5)

      assert valid?(validator, "123456") == {:error, "too long"}
    end

    test "regex valid" do
      validator = regex(~r/^[0-9]*$/, "does not match regex")

      assert valid?(validator, "123") == {:ok, "123"}
    end

    test "regex invalid" do
      validator = regex(~r/^[0-9]*$/, "does not match regex")

      assert valid?(validator, "123a") == {:error, "does not match regex"}
    end
  end

  describe "comined validator" do
    property "valid values" do
      validators = [min(5), max(10)]

      for_all str in binary() do
        implies(String.length(str) >= 5 and String.length(str) <= 10) do
          {:ok, str} == valid?(validators, str)
        end
      end
    end

    property "invalid lengths" do
      validators = [min(5), max(10)]

      for_all str in binary() do
        implies(String.length(str) < 5 or String.length(str) > 10) do
          :error == valid?(validators, str) |> elem(0)
        end
      end
    end

    test "combined with regex - valid" do
      validators = [regex(~r/^[0-9]*$/, "does not match regex"), min(5), max(10)]

      assert valid?(validators, "12345") == {:ok, "12345"}
    end

    test "combined with regex - regex invalid" do
      validators = [regex(~r/^[0-9]*$/, "does not match regex"), min(5), max(8)]

      assert valid?(validators, "123a5") == {:error, "does not match regex"}
    end

    test "combined with regex - min invalid" do
      validators = [regex(~r/^[0-9]*$/, "does not match regex"), min(5), max(8)]

      assert valid?(validators, "1234") == {:error, "too short"}
    end

    test "combined with regex - max invalid" do
      validators = [regex(~r/^[0-9]*$/, "does not match regex"), min(5), max(8)]

      assert valid?(validators, "123456789") == {:error, "too long"}
    end
  end
end
