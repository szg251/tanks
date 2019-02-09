defmodule TanksWeb.GameChannel do
  use TanksWeb, :channel

  alias Tanks.GameLogic.Battle
  alias Tanks.GameLogic.Tank

  def join("game:" <> battle_name, _payload, socket) do
    case Tanks.Lodge.get_battle(battle_name) do
      {:ok, battle} ->
        Battle.create_tank(battle.pid, socket.assigns.user_id)

        Battle.subscribe(battle.pid, socket.assigns.user_id, self())
        {:ok, socket |> assign(:battle_pid, battle.pid)}

      {:error, reason} ->
        {:error, %{reason: reason}}
    end
  end

  def handle_in("move", %{"move" => velocity}, socket) do
    {:ok, tankPid} = Battle.get_pid(socket.assigns.battle_pid, socket.assigns.user_id)
    Tank.set_movement(tankPid, velocity)
    {:noreply, socket}
  end

  def handle_in("move_turret", %{"angle" => velocity}, socket) do
    {:ok, tankPid} = Battle.get_pid(socket.assigns.battle_pid, socket.assigns.user_id)
    Tank.set_turret_angle_velocity(tankPid, velocity)
    {:noreply, socket}
  end

  def handle_in("fire", %{}, socket) do
    Battle.fire(socket.assigns.battle_pid, socket.assigns.user_id)
    {:noreply, socket}
  end

  def handle_info({:broadcast, game_state}, socket) do
    push(socket, "sync", game_state)
    {:noreply, socket}
  end

  def handle_info({:end_battle, tanks}, socket) do
    push(socket, "end_battle", %{tanks: tanks})
    {:noreply, socket}
  end

  def handle_info({:DOWN, error}, socket) do
    IO.inspect(error)
    {:noreply, socket}
  end
end
