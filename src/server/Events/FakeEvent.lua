local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local function launchPlayer(player)
	local character = player and player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")

	if not rootPart then
		return
	end

	rootPart.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity + Vector3.new(0, 80, 0)
end

return {
	Id = "fake_event",
	Name = "Fake Event",
	Weight = 1,
	StartMessage = "See? Nothing happened.",

	Run = function(context)
		task.wait(3)

		context.BroadcastMessage("Okay, one small thing happened.")
		Lighting.Brightness = 6
		Lighting.Ambient = Color3.fromRGB(255, 120, 220)
		task.wait(0.3)
		Lighting.Brightness = 1
		Lighting.Ambient = Color3.fromRGB(90, 220, 255)

		launchPlayer(context.TriggeringPlayer)
		context.DiscoveryService:Unlock(context.TriggeringPlayer, Constants.Discoveries.DelayedSurprise.Id)

		task.wait(math.max(1, Constants.EventDuration - 3))
	end,
}
