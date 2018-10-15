defmodule TanksWeb.GameChannel do
  use TanksWeb, :channel
  import Integer
  alias TanksWeb.Presence

  def join("game:lobby", payload, socket) do
    if authorized?(payload) do
      is_team_b =
        Presence.list(socket)
        |> Map.size()
        |> Integer.is_odd()

      Presence.track(socket, socket.assigns.user_id, initTank(is_team_b))

      send(self(), :eval_turn)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("move", %{"move" => move}, socket) do
    Presence.update(socket, socket.assigns.user_id, fn tank ->
      %{tank | "move" => move}
    end)

    {:noreply, socket}
  end

  def handle_in("move_turret", %{"angle" => angle}, socket) do
    Presence.update(socket, socket.assigns.user_id, fn tank ->
      %{tank | "moveTurret" => angle}
    end)

    {:noreply, socket}
  end

  def handle_in("fire", %{}, socket) do
    Presence.update(socket, socket.assigns.user_id, fn tank ->
      if tank["load"] <= 0 do
        %{tank | "bullets" => [initBullet(tank) | tank["bullets"]], "load" => 100}
      else
        tank
      end
    end)

    {:noreply, socket}
  end

  def handle_info(:eval_turn, socket) do
    game_state = %{
      "tanks" =>
        Presence.list(socket)
        |> Map.values()
        |> Enum.map(fn presence -> hd(presence.metas) end)
    }

    Presence.update(socket, socket.assigns.user_id, fn tank ->
      tank |> update_tank |> eval_hits(game_state)
    end)

    broadcast(socket, "sync", game_state)
    :timer.sleep(30)

    send(self(), :eval_turn)
    {:noreply, socket}
  end

  defp update_tank(tank) do
    %{
      tank
      | "x" => (tank["x"] + tank["move"]) |> max(0) |> min(900),
        "turretAngle" => (tank["turretAngle"] + tank["moveTurret"]) |> max(0) |> min(0.5),
        "load" => (tank["load"] - 1) |> max(0),
        "bullets" =>
          tank["bullets"]
          |> Enum.map(&update_bullet(&1))
          |> Enum.filter(fn %{"x" => x, "y" => y} -> x < 1000 && y < 600 end)
    }
  end

  defp update_bullet(bullet) do
    %{
      bullet
      | "x" => bullet["x"] + div(bullet["vel_x"], 100),
        "y" => bullet["y"] + div(bullet["vel_y"], 100),
        "vel_y" => min(100, bullet["vel_y"] + 5)
    }
  end

  defp eval_hits(tank, game_state) do
    bullets =
      game_state["tanks"]
      |> Enum.map(fn tank -> tank["bullets"] end)
      |> Enum.concat()

    remaining_bullets =
      bullets
      |> Enum.filter(fn bullet ->
        tank["x"] > bullet["x"] || bullet["x"] > tank["x"] + 70 ||
          (tank["y"] > bullet["y"] || bullet["y"] > tank["y"] + 40)
      end)

    if length(bullets) !== length(remaining_bullets) do
      %{tank | "life" => (tank["life"] - 1) |> max(0)}
    else
      tank
    end
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end

  defp initTank(team_b) do
    defaults = %{
      "x" => 0,
      "y" => 500,
      "direction" => :right,
      "move" => 0,
      "load" => 0,
      "turretAngle" => 0,
      "moveTurret" => 0,
      "bullets" => [],
      "life" => 100
    }

    if team_b do
      %{defaults | "x" => 900, "direction" => :left}
    else
      defaults
    end
  end

  defp initBullet(tank) do
    case tank["direction"] do
      :left ->
        %{
          "x" => tank["x"] + 20 - round(20 * :math.cos(tank["turretAngle"])),
          "y" => tank["y"] + 14 - round(20 * :math.sin(tank["turretAngle"])),
          "vel_x" => round(-800 * :math.cos(tank["turretAngle"])),
          "vel_y" => round(-800 * :math.sin(tank["turretAngle"]))
        }

      :right ->
        %{
          "x" => tank["x"] + 50 + round(20 * :math.cos(tank["turretAngle"])),
          "y" => tank["y"] + 14 - round(20 * :math.sin(tank["turretAngle"])),
          "vel_x" => round(800 * :math.cos(tank["turretAngle"])),
          "vel_y" => round(-800 * :math.sin(tank["turretAngle"]))
        }
    end
  end
end
