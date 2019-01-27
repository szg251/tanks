defmodule TanksWeb.GameChannel do
  use TanksWeb, :channel
  @tick_rate 30

  def join("game:lobby", _payload, socket) do
    GameState.create_tank(socket.assigns.user_id)

    schedule_push(%GameState{})
    {:ok, socket}
  end

  defp schedule_push(prev_state) do
    Process.send_after(self(), {:broadcast, prev_state}, @tick_rate)
  end

  def handle_in("move", %{"move" => velocity}, socket) do
    {:ok, tankPid} = GameState.get_pid(socket.assigns.user_id)
    Tank.set_movement(tankPid, velocity)
    {:noreply, socket}
  end

  def handle_in("move_turret", %{"angle" => velocity}, socket) do
    {:ok, tankPid} = GameState.get_pid(socket.assigns.user_id)
    Tank.set_turret_angle_velocity(tankPid, velocity)
    {:noreply, socket}
  end

  def handle_in("fire", %{}, socket) do
    GameState.fire(socket.assigns.user_id)
    {:noreply, socket}
  end

  def handle_info({:broadcast, prev_game_state}, socket) do
    game_state = GameState.get_state() |> GameState.to_api()

    if game_state !== prev_game_state do
      push(socket, "sync", game_state)
      assign(socket, :game_state, game_state)
    end

    schedule_push(game_state)
    {:noreply, socket}
  end
end
