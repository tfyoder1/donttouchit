local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local PlayerScale = require(script.Parent.Parent:WaitForChild("PlayerScale"))
local RemoteService = require(script.Parent.Parent:WaitForChild("RemoteService"))
local transformCameraRemote = RemoteService.GetRemote(Constants.Remotes.TransformCamera)

return {
	Id = "tiny_players",
	Name = "Tiny Players",
	Weight = 1,
	StartMessage = "Everyone has been made travel-size.",

	Run = function(context)
		local ok, errorMessage = pcall(function()
			for _, player in ipairs(context.Players) do
				PlayerScale.ApplyTemporary(player, 0.45, Constants.SizeTransformDuration or Constants.EventDuration)
				transformCameraRemote:FireClient(player, {
					Action = "SizeTransform",
					Scale = 0.45,
					Duration = Constants.SizeTransformCameraDuration or 3,
					Label = "Tiny mode",
				})
			end

			context.DiscoveryService:UnlockForPlayers(context.Players, Constants.Discoveries.TinyPlayers.Id)
			task.wait(Constants.SizeTransformDuration or Constants.EventDuration)
		end)

		if not ok then
			error(errorMessage)
		end
	end,
}
