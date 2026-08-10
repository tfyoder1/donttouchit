local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local PlayerScale = require(script.Parent.Parent:WaitForChild("PlayerScale"))

return {
	Id = "giant_player",
	Name = "Giant Player",
	Weight = 0,
	StartMessage = "One person has been promoted to problem size.",

	Run = function(context)
		if #context.Players == 0 then
			task.wait(1)
			return
		end

		local random = Random.new()
		local chosenPlayer = context.Players[random:NextInteger(1, #context.Players)]
		local snapshot = nil

		local ok, errorMessage = pcall(function()
			snapshot = PlayerScale.Apply(chosenPlayer, 2.25)

			context.BroadcastMessage(chosenPlayer.DisplayName .. " is huge now. Seems fine.")
			context.DiscoveryService:UnlockForPlayers(context.Players, Constants.Discoveries.GiantPlayer.Id)

			task.wait(Constants.EventDuration)
		end)

		PlayerScale.Restore(snapshot)

		if not ok then
			error(errorMessage)
		end
	end,
}
