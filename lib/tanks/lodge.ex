defmodule Tanks.Lodge.BattleSummary do
  defstruct [:name, :pid, :player_count, :owner_name]

  @doc """
  Creates a battle summary
  """
  def create(name, pid, owner_name) when is_pid(pid) and is_binary(name) do
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
  alias Tanks.Lodge

  defstruct players: MapSet.new(), battles: Map.new()

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts ++ [name: __MODULE__])
  end

  @doc """
  Start a battle server

  ## Example

    iex> Tanks.Lodge.create_player("owner")
    iex> {:ok, battle} = Tanks.Lodge.start_battle("test", "owner")
    iex> is_pid(battle.pid)
    true

    iex> Tanks.Lodge.create_player("owner")
    iex> Tanks.Lodge.start_battle("test", "owner")
    iex> Tanks.Lodge.start_battle("test", "owner")
    {:error, "battle already exists"}

  """
  def start_battle(name, owner_name) when is_binary(name) do
    GenServer.call(__MODULE__, {:start_battle, name, owner_name})
  end

  @doc """
  Close a battle server

  ## Example

    iex> Tanks.Lodge.create_player("owner")
    iex> Tanks.Lodge.start_battle("test", "owner")
    iex> Tanks.Lodge.close_battle("test", "owner")
    iex> Tanks.Lodge.list_battles() |> length
    0

    iex> Tanks.Lodge.create_player("owner")
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

    iex> Tanks.Lodge.create_player("owner")
    iex> {:ok, battle} = Tanks.Lodge.start_battle("test", "owner")
    iex> [battle2] = Tanks.Lodge.list_battles()
    iex> battle == battle2
    true

    iex> Tanks.Lodge.create_player("owner")
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

    iex> Tanks.Lodge.create_player("owner")
    iex> Tanks.Lodge.start_battle("test", "owner")
    iex> Tanks.Lodge.list_battles()
    iex> {:ok, battle} = Tanks.Lodge.get_battle("test")
    iex> {is_pid(battle.pid), battle.player_count}
    {true, 0}

    iex> Tanks.Lodge.get_battle("test")
    {:error, "battle does not exist"}

  """
  def get_battle(name) do
    GenServer.call(__MODULE__, {:get_battle, name})
  end

  @doc """
  Create a player

  ## Example

    iex> Tanks.Lodge.create_player("owner")
    {:ok, %{name: "owner"}}

    iex> Tanks.Lodge.create_player("owner")
    iex> Tanks.Lodge.create_player("owner")
    {:error, "player already exists"}

  """
  def create_player(name) do
    GenServer.call(__MODULE__, {:create_player, name})
  end

  @doc """
  Get player

  ## Example

    iex> Tanks.Lodge.create_player("owner")
    iex> Tanks.Lodge.get_player("owner")
    {:ok, %{name: "owner"}}

    iex> Tanks.Lodge.get_player("owner")
    {:error, "player does not exist"}

  """
  def get_player(name) do
    GenServer.call(__MODULE__, {:get_player, name})
  end

  @doc """
  List all players

  ## Example

    iex> Tanks.Lodge.create_player("owner")
    iex> Tanks.Lodge.list_players()
    [%{name: "owner"}]

  """
  def list_players do
    GenServer.call(__MODULE__, :list_players)
  end

  @doc """
  Remove a player

  ## Example

    iex> Tanks.Lodge.create_player("owner")
    iex> Tanks.Lodge.remove_player("owner")
    iex> Tanks.Lodge.list_players()
    []

  """
  def remove_player(name) do
    GenServer.cast(__MODULE__, {:remove_player, name})
  end

  def init(:ok) do
    {:ok, %Lodge{}}
  end

  def handle_call({:start_battle, name, owner_name}, _from, state) do
    with {:ok, valid_name} <- name_valid?(name),
         {:ok, pid} <- BattleSupervisor.start_battle(),
         {:ok, usable_name} <-
           pipe_when(valid_name, &(!Map.has_key?(state.battles, &1)), "battle already exists"),
         {:ok, existing_player} <-
           pipe_when(owner_name, &(!Map.has_key?(state.players, &1)), "owner does not exist") do
      summary = BattleSummary.create(valid_name, pid, existing_player)

      new_state = %Lodge{
        state
        | battles: state.battles |> Map.put(usable_name, {pid, owner_name})
      }

      {:reply, {:ok, summary}, new_state}
    else
      error ->
        {:reply, error, state}
    end
  end

  def handle_call({:get_battle, battle_name}, _from, state) do
    case Map.fetch(state.battles, battle_name) do
      {:ok, {pid, owner_name}} ->
        {:reply, {:ok, BattleSummary.create(battle_name, pid, owner_name)}, state}

      :error ->
        {:reply, {:error, "battle does not exist"}, state}
    end
  end

  def handle_call({:create_player, player_name}, _from, state) do
    with {:ok, valid_name} <- name_valid?(player_name) do
      if !MapSet.member?(state.players, valid_name) do
        new_state = %Lodge{state | players: state.players |> MapSet.put(valid_name)}
        {:reply, {:ok, %{name: valid_name}}, new_state}
      else
        {:reply, {:error, "player already exists"}, state}
      end
    else
      error_result ->
        {:reply, error_result, state}
    end
  end

  def handle_call(:list_battles, _from, state) do
    list =
      state.battles
      |> Enum.map(fn {name, {pid, owner_name}} -> BattleSummary.create(name, pid, owner_name) end)

    {:reply, list, state}
  end

  def handle_call({:get_player, name}, _from, state) do
    result =
      if MapSet.member?(state.players, name) do
        {:ok, %{name: name}}
      else
        {:error, "player does not exist"}
      end

    {:reply, result, state}
  end

  def handle_call(:list_players, _from, state) do
    {:reply, MapSet.to_list(state.players) |> Enum.map(&%{name: &1}), state}
  end

  def handle_cast({:close_battle, name, player_name}, state) do
    case state.battles |> Map.fetch(name) do
      {:ok, {battle_pid, owner_name}} ->
        if owner_name == player_name do
          BattleSupervisor.close_battle(battle_pid)
          new_state = %Lodge{state | battles: Map.delete(state.battles, name)}
          {:noreply, new_state}
        else
          {:noreply, state}
        end

      :error ->
        {:noreply, state}
    end
  end

  def handle_cast({:remove_player, player_name}, state) do
    {:noreply, %Lodge{state | players: state.players |> MapSet.delete(player_name)}}
  end

  # Validate name
  defp name_valid?(name) do
    import Tanks.Validator

    valid?([no_special_chars(), min(1), max(20)], name)
  end

  # Puts a value into a result tuple according to a predicate
  defp pipe_when(value, func, error_message) do
    if func.(value) do
      {:ok, value}
    else
      {:error, error_message}
    end
  end
end
