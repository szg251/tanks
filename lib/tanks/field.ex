defmodule Field do
  @field_width 1000
  @field_height 600
  @gravity 0.1

  @doc """
  Moving an object on the field
  results in :error if out of boundaries

    # Examples

    iex> Field.move_object(%{width: 10, x: 0, velocity_x: -5, height: 10, y: 0, velocity_y: 5})
    :error

    iex> Field.move_object(%{width: 10, x: 10, velocity_x: -5, height: 10, y: 10, velocity_y: 5})
    {:ok, %{width: 10, x: 5, velocity_x: -5, height: 10, y: 15, velocity_y: 5}}

  """

  def move_object(object) when is_map(object) do
    new_x = object.x + object.velocity_x
    new_y = object.y + object.velocity_y

    cond do
      new_x < 0 or new_x > @field_width - object.width -> :error
      new_y < 0 or new_y > @field_height - object.height -> :error
      true -> {:ok, %{object | x: new_x, y: new_y}}
    end
  end

  @doc """
  Applying gravity (set velocity_y)

    # Example

    iex> Field.apply_gravity(%{velocity_y: 5})
    %{velocity_y: 5.1}

  """
  def apply_gravity(object) when is_map(object) do
    %{object | velocity_y: object.velocity_y + @gravity}
  end

  @doc """
  Detects whether two objects are colliding

    # Examples

    iex> Field.colliding?(
    ...> [{0, 0}, {10, 0}, {10, 10}, {0, 10}],
    ...> [{10, 10}, {20, 10}, {20, 20}, {10, 20}])
    true

    iex> Field.colliding?(
    ...> [{0, 0}, {10, 0}, {10, 10}, {0, 10}],
    ...> [{20, 20}, {30, 20}, {30, 30}, {20, 30}])
    false

  """
  def colliding?(object1, object2) do
    shape1 = Collidex.Geometry.Polygon.make(object1)
    shape2 = Collidex.Geometry.Polygon.make(object2)

    case Collidex.Detector.collision?(shape1, shape2) do
      {:collision, _} -> true
      _ -> false
    end
  end
end
