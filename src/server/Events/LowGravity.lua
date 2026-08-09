local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

return {
	Id = "low_gravity",
	Name = "Low Gravity",
	Weight = 1,
	StartMessage = "Gravity just got very negotiable.",

	Run = function(context)
		workspace.Gravity = 45
		context.DiscoveryService:UnlockForAll(Constants.Discoveries.LowGravity.Id)
		task.wait(Constants.EventDuration)
		workspace.Gravity = Constants.NormalGravity
	end,
}

