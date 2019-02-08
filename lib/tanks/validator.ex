defmodule Tanks.Validator do
  @type result(error, ok) :: {:error, error} | {:ok, ok}

  @type validator(value) ::
          ({:error, binary()} | {:ok, value} -> {:error, binary()} | {:ok, value})

  # Create a minimum length validator
  @spec min(integer()) :: validator(binary())

  def custom(condition, message) do
    fn validatee ->
      bind(validatee, fn str ->
        if condition.(str) do
          {:ok, str}
        else
          {:error, message}
        end
      end)
    end
  end

  def min(n) when is_integer(n) do
    custom(&(String.length(&1) >= n), "too short")
  end

  # Create a maximum length validator
  @spec max(integer()) :: validator(binary())

  def max(n) when is_integer(n) do
    custom(&(String.length(&1) <= n), "too long")
  end

  def regex(regex, message) do
    custom(&Regex.match?(regex, &1), message)
  end

  def no_special_chars do
    regex(~r/^[a-zA-Z0-9_]*$/, "contains special characters")
  end

  def compose(validator1, validator2)
      when is_function(validator1) and is_function(validator2) do
    fn arg -> validator1.(validator2.(arg)) end
  end

  @doc """
  Validates a value with a validator or a list of validators

    # Example

    iex> Tanks.Validator.valid?(Tanks.Validator.max(10), "stringstring")
    {:error, "too long"}

    iex> validators = [Tanks.Validator.min(5), Tanks.Validator.max(10)]
    iex> Tanks.Validator.valid?(validators, "str")
    {:error, "too short"}

  """
  @spec valid?(validator(binary()) | list(validator(binary())), binary()) ::
          result(binary(), binary())

  def valid?(validators, str) when is_list(validators) do
    validator = Enum.reduce(validators, &compose(&1, &2))
    validator.({:ok, str})
  end

  def valid?(validator, str) do
    validator.({:ok, str})
  end

  @spec map(
          result(binary(), any()),
          (binary() -> any())
        ) :: result(binary(), any())
  def map(validated, func) when is_function(func, 1) do
    case validated do
      {:ok, value} -> {:ok, func.(value)}
      {:error, _} -> validated
    end
  end

  @spec bind(
          result(binary(), binary()),
          (binary() -> result(binary(), binary()))
        ) :: result(binary(), binary())

  def bind(validated, func) when is_function(func, 1) do
    case validated do
      {:ok, value} -> func.(value)
      {:error, _} -> validated
    end
  end
end
