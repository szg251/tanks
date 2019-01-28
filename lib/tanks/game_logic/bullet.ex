defmodule Tanks.GameLogic.Bullet do
  alias Tanks.GameLogic.Bullet
  alias Tanks.GameLogic.Field

  @enforce_keys [:x, :y, :velocity_x, :velocity_y]
  @derive {Jason.Encoder, only: [:x, :y]}
  defstruct width: 3, height: 3, x: 0, y: 0, velocity_x: 0, velocity_y: 0

  @doc """
  Evaluate the movement of a bullet

    iex> bullet = %Bullet{x: 50, y: 50, velocity_x: 5, velocity_y: -5}
    iex> Bullet.move(bullet)
    {:ok, %Bullet{x: 55, y: 45.1, velocity_x: 5, velocity_y: -4.9}}

  """
  def move(bullet) do
    bullet
    |> Field.apply_gravity()
    |> Field.move_object()
  end

  def to_api(%Bullet{x: x, y: y}) do
    %{
      x: round(x),
      y: round(y)
    }
  end
end
