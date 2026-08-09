local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local PlayerScale = require(script.Parent.Parent:WaitForChild("PlayerScale"))

return {
	Id = "tiny_players",
	Name = "Tiny Players",
	Weight = 1,
	StartMessage = "Everyone has been made travel-size.",

	Run = function(context)
		local snapshots = {}

		local ok, errorMessage = pcall(function()
			for _, player in ipairs(context.Players) do
				local snapshot = PlayerScale.Apply(player, 0.45)
				if snapshot then
					table.insert(snapshots, snapshot)
				end
			end

			context.DiscoveryService:UnlockForPlayers(context.Players, Constants.Discoveries.TinyPlayers.Id)
			task.wait(Constants.EventDuration)
		end)

		for _, snapshot in ipairs(snapshots) do
			PlayerScale.Restore(snapshot)
		end

		if not ok then
			error(errorMessage)
		end
	end,
}
