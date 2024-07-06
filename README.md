# FlyCooldown
Simple library to quickly apply cooldowns to server and client sided actions.

Usage;
```lua
local Cooldown = require(rs:WaitForChild('CooldownUtils'))

local equip_cooldown = 2.0

local cooldown = Cooldown.new(equip_cooldown)

cooldown.callback = function(player, cooldown_time)
	print(`Cooldown for {player.UserId} expired! [{cooldown_time}s]`)
end

RenderDrone.OnServerEvent:Connect(function(player: Player, drone_name: string)
		local cooldown_finished = cooldown:check(player)
		if not cooldown_finished then
			return
		end
		
		local player_data = PlayerDataService.GetPlayerDataInstance(player)
		local owns_drone = player_data:HasGear(drone_name)
		if owns_drone then
			for _, p:Player in players:GetPlayers() do
				if p.UserId ~= player.UserId then
					RenderDrone:FireClient(p, player, drone_name)
				end
			end
		else
			DeleteDrone:FireClient(player)
		end

		cooldown:apply(player, equip_cooldown)
end)
```
