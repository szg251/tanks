defmodule GameState do
  defstruct nextId: 0, tanks: Map.new()
end

defmodule Tank do
  defstruct x: 0, y: 0, inertia: 0
end

defmodule Tanks.GameState do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts ++ [name: __MODULE__])
  end

  def join do
    GenServer.call(__MODULE__, :join)
  end

  def get_tanks do
    GenServer.call(__MODULE__, :get_tanks)
  end

  def leave(tankId) do
    GenServer.cast(__MODULE__, {:leave, tankId})
  end

  def move(tankId, inertia) do
    GenServer.cast(__MODULE__, {:move, tankId, inertia})
  end

  def init(:ok) do
    {:ok, %GameState{}}
  end

  def handle_call(:join, _from, state) do
    newState = %{
      state
      | tanks: Map.put(state.tanks, state.nextId, %Tank{}),
        nextId: state.nextId + 1
    }

    {:reply, state.nextId, newState}
  end

  def handle_call(:get_tanks, _from, state) do
    {:reply, state.tanks, state}
  end

  def handle_cast({:leave, tankId}, state) do
    newState = %{state | tanks: Map.delete(state.tanks, tankId)}
    {:noreply, newState}
  end

  def handle_cast({:move, tankId, inertia}, state) do
    updateTank = fn tank -> %Tank{tank | inertia: inertia |> min(5) |> max(-5)} end

    newTanks = Map.update!(state.tanks, tankId, updateTank) |> IO.inspect()
    newState = %GameState{state | tanks: newTanks}

    {:noreply, newState}
  end
end
