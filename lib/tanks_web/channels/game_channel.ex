defmodule TanksWeb.GameChannel do
  use TanksWeb, :channel

  alias Tanks.GameLogic.Battle
  alias Tanks.GameLogic.Tank

  @tick_rate 30

  def join("game:" <> battle_name, _payload, socket) do
    case Tanks.Lodge.get_summary(battle_name) do
      {:ok, battle} ->
        Battle.create_tank(battle.pid, socket.assigns.user_id)
        schedule_push(%Battle{})
        {:ok, socket |> assign(:battle_pid, battle.pid)}

      :error ->
        {:error, socket}
    end
  end

  defp schedule_push(prev_state) do
    Process.send_after(self(), {:broadcast, prev_state}, @tick_rate)
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

  def handle_info({:broadcast, prev_game_state}, socket) do
    game_state = Battle.get_state(socket.assigns.battle_pid) |> Battle.to_api()

    if game_state !== prev_game_state do
      push(socket, "sync", game_state)
      assign(socket, :game_state, game_state)
    end

    schedule_push(game_state)
    {:noreply, socket}
  end
end
