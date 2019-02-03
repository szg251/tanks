defmodule Tanks.BattleLodge.BattleSummary do
  defstruct [:name, :pid, :player_count]
end

defmodule Tanks.BattleLodge do
  use GenServer

  alias Tanks.BattleSupervisor
  alias Tanks.BattleLodge.BattleSummary

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts ++ [name: __MODULE__])
  end

  @doc """
  Start a battle server

  ## Example

    iex> {:ok, battle} = Tanks.BattleLodge.start_battle("test")
    iex> is_pid(battle.pid)
    true

    iex> Tanks.BattleLodge.start_battle("test")
    iex> Tanks.BattleLodge.start_battle("test")
    :error

  """
  def start_battle(name) when is_binary(name) do
    GenServer.call(__MODULE__, {:start_battle, name})
  end

  @doc """
  Close a battle server

  ## Example

    iex> Tanks.BattleLodge.start_battle("test")
    iex> Tanks.BattleLodge.close_battle("test")
    iex> Tanks.BattleLodge.list_battles()
    []

  """
  def close_battle(name) when is_binary(name) do
    GenServer.cast(__MODULE__, {:close_battle, name})
  end

  @doc """
  List battle servers

  ## Example

    iex> {:ok, battle} = Tanks.BattleLodge.start_battle("test")
    iex> [battle2] = Tanks.BattleLodge.list_battles()
    iex> battle == battle2
    true

    iex> {:ok, battle} = Tanks.BattleLodge.start_battle("test")
    iex> Tanks.GameLogic.Battle.create_tank(battle.pid, "test")
    iex> [battle2] = Tanks.BattleLodge.list_battles()
    iex> {battle.player_count, battle2.player_count}
    {0, 1}

  """
  def list_battles do
    GenServer.call(__MODULE__, :list_battles)
  end

  @doc """
  Get battle summary by name

  ## Example

    iex> Tanks.BattleLodge.start_battle("test")
    iex> Tanks.BattleLodge.list_battles()
    iex> {:ok, battle} = Tanks.BattleLodge.get_summary("test")
    iex> {is_pid(battle.pid), battle.player_count}
    {true, 0}

  """
  def get_summary(name) do
    GenServer.call(__MODULE__, {:get_summary, name})
  end

  def init(:ok) do
    :ets.new(:battles, [:named_table])
    {:ok, Map.new()}
  end

  def handle_call({:start_battle, name}, _from, state) do
    {:ok, pid} = BattleSupervisor.start_battle()
    success = :ets.insert_new(:battles, {name, pid})

    if success do
      {:reply, {:ok, to_summary({name, pid})}, state}
    else
      {:reply, :error, state}
    end
  end

  def handle_call(:list_battles, _from, state) do
    list = :ets.tab2list(:battles) |> Enum.map(&to_summary(&1))

    {:reply, list, state}
  end

  def handle_call({:get_summary, name}, _from, state) do
    case :ets.lookup(:battles, name) do
      [] -> {:reply, :error, state}
      [battle] -> {:reply, {:ok, to_summary(battle)}, state}
    end
  end

  def handle_cast({:close_battle, name}, state) do
    [{^name, battle_pid}] = :ets.lookup(:battles, name)
    :ets.delete(:battles, name)
    BattleSupervisor.close_battle(battle_pid)

    {:noreply, state}
  end

  defp to_summary({name, pid}) do
    %BattleSummary{name: name, pid: pid, player_count: Tanks.GameLogic.Battle.count_tanks(pid)}
  end
end
