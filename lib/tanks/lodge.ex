defmodule Tanks.Lodge.BattleSummary do
  defstruct [:name, :pid, :player_count, :owner_name]

  @doc """
  Creates a battle summary from ETS stored data
  """
  def create({name, pid, owner_name}) when is_pid(pid) and is_binary(name) do
    %Tanks.Lodge.BattleSummary{
      name: name,
      pid: pid,
      owner_name: owner_name,
      player_count: Tanks.GameLogic.Battle.count_tanks(pid)
    }
  end
end

defmodule Tanks.Lodge do
  use GenServer

  alias Tanks.BattleSupervisor
  alias Tanks.Lodge.BattleSummary

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts ++ [name: __MODULE__])
  end

  @doc """
  Start a battle server

  ## Example

    iex> {:ok, battle} = Tanks.Lodge.start_battle("test", "owner")
    iex> is_pid(battle.pid)
    true

    iex> Tanks.Lodge.start_battle("test", "owner")
    iex> Tanks.Lodge.start_battle("test", "owner")
    :error

  """
  def start_battle(name, owner_name) when is_binary(name) do
    GenServer.call(__MODULE__, {:start_battle, name, owner_name})
  end

  @doc """
  Close a battle server

  ## Example

    iex> Tanks.Lodge.start_battle("test", "owner")
    iex> Tanks.Lodge.close_battle("test", "owner")
    iex> Tanks.Lodge.list_battles() |> length
    0

    iex> Tanks.Lodge.start_battle("test", "owner")
    iex> Tanks.Lodge.close_battle("test", "someone else")
    iex> Tanks.Lodge.list_battles() |> length
    1

  """
  def close_battle(name, player_name) when is_binary(name) do
    GenServer.cast(__MODULE__, {:close_battle, name, player_name})
  end

  @doc """
  List battle servers

  ## Example

    iex> {:ok, battle} = Tanks.Lodge.start_battle("test", "owner")
    iex> [battle2] = Tanks.Lodge.list_battles()
    iex> battle == battle2
    true

    iex> {:ok, battle} = Tanks.Lodge.start_battle("test", "owner")
    iex> Tanks.GameLogic.Battle.create_tank(battle.pid, "test")
    iex> [battle2] = Tanks.Lodge.list_battles()
    iex> {battle.player_count, battle2.player_count}
    {0, 1}

  """
  def list_battles do
    GenServer.call(__MODULE__, :list_battles)
  end

  @doc """
  Get battle summary by name

  ## Example

    iex> Tanks.Lodge.start_battle("test", "owner")
    iex> Tanks.Lodge.list_battles()
    iex> {:ok, battle} = Tanks.Lodge.get_summary("test")
    iex> {is_pid(battle.pid), battle.player_count}
    {true, 0}

    iex> Tanks.Lodge.get_summary("test")
    :error

  """
  def get_summary(name) do
    GenServer.call(__MODULE__, {:get_summary, name})
  end

  def init(:ok) do
    :ets.new(:battles, [:named_table])
    {:ok, Map.new()}
  end

  def handle_call({:start_battle, name, owner_name}, _from, state) do
    {:ok, pid} = BattleSupervisor.start_battle()
    success = :ets.insert_new(:battles, {name, pid, owner_name})

    if success do
      {:reply, {:ok, BattleSummary.create({name, pid, owner_name})}, state}
    else
      {:reply, :error, state}
    end
  end

  def handle_call(:list_battles, _from, state) do
    list = :ets.tab2list(:battles) |> Enum.map(&BattleSummary.create(&1))

    {:reply, list, state}
  end

  def handle_call({:get_summary, name}, _from, state) do
    case :ets.lookup(:battles, name) do
      [] -> {:reply, :error, state}
      [battle] -> {:reply, {:ok, BattleSummary.create(battle)}, state}
    end
  end

  def handle_cast({:close_battle, name, player_name}, state) do
    [{^name, battle_pid, owner_name}] = :ets.lookup(:battles, name)

    if owner_name == player_name do
      :ets.delete(:battles, name)
      BattleSupervisor.close_battle(battle_pid)
    end

    {:noreply, state}
  end
end
