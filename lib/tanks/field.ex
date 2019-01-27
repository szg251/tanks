defmodule Field do
  @field_width 1000
  @field_height 600
  @gravity 5

  @doc """
  Moving an object on the field
  results in :error if out of boundaries

    # Examples

    iex> Field.move_object(10, 0, -5, 10, 0)
    :error

    iex> Field.move_object(10, 10, -5, 10, 10, 5)
    {:ok, 5, 15}

  """
  def move_object(
        object_width,
        object_x,
        velocity_x,
        object_height,
        object_y,
        velocity_y \\ 0,
        gravity \\ false
      ) do
    newX = object_x + velocity_x

    newY = if gravity, do: object_y + velocity_y + @gravity, else: object_y + velocity_y

    cond do
      newX < 0 or newX > @field_width - object_width -> :error
      newY < 0 or newY > @field_height - object_height -> :error
      true -> {:ok, newX, newY}
    end
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
