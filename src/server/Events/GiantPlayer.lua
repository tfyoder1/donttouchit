local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local PlayerScale = require(script.Parent.Parent:WaitForChild("PlayerScale"))
local RemoteService = require(script.Parent.Parent:WaitForChild("RemoteService"))
local transformCameraRemote = RemoteService.GetRemote(Constants.Remotes.TransformCamera)

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

		local ok, errorMessage = pcall(function()
			PlayerScale.ApplyTemporary(chosenPlayer, 2.25, Constants.SizeTransformDuration or Constants.EventDuration)
			transformCameraRemote:FireClient(chosenPlayer, {
				Action = "SizeTransform",
				Scale = 2.25,
				Duration = Constants.SizeTransformCameraDuration or 3,
				Label = "Giant mode",
			})

			context.BroadcastMessage(chosenPlayer.DisplayName .. " is huge now. Seems fine.")
			context.DiscoveryService:UnlockForPlayers(context.Players, Constants.Discoveries.GiantPlayer.Id)

			task.wait(Constants.SizeTransformDuration or Constants.EventDuration)
		end)

		if not ok then
			error(errorMessage)
		end
	end,
}
