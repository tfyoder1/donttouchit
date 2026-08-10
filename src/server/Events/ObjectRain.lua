local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local COLORS = {
	Color3.fromRGB(255, 84, 84),
	Color3.fromRGB(255, 221, 84),
	Color3.fromRGB(84, 180, 255),
	Color3.fromRGB(102, 255, 166),
	Color3.fromRGB(218, 108, 255),
}

return {
	Id = "object_rain",
	Name = "Object Rain",
	Weight = 1,
	StartMessage = "The ceiling is dropping things inside the room.",

	Run = function(context)
		local folder = Instance.new("Folder")
		folder.Name = "TemporaryObjectRain"
		folder.Parent = workspace
		CollectionService:AddTag(folder, Constants.Tags.TemporaryObject)

		local random = Random.new()

		if context.BroadcastMessage then
			context.BroadcastMessage("Object rain is actually inside the ceiling this time. Look up.")
		end

		for index = 1, 72 do
			local blob = Instance.new("Part")
			blob.Name = "FallingBlob"
			if index % 3 == 0 then
				blob.Shape = Enum.PartType.Ball
			end
			blob.Size = Vector3.new(
				random:NextNumber(1.1, 2.4),
				random:NextNumber(0.8, 2.0),
				random:NextNumber(1.1, 2.4)
			)
			blob.Color = COLORS[random:NextInteger(1, #COLORS)]
			blob.Material = index % 4 == 0 and Enum.Material.Neon or Enum.Material.SmoothPlastic
			blob.CFrame = CFrame.new(random:NextNumber(-18, 18), random:NextNumber(10.8, 14), random:NextNumber(-14, 14))
			blob.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.25, 0.75)
			blob.Parent = folder
			CollectionService:AddTag(blob, Constants.Tags.TemporaryObject)
			blob.AssemblyLinearVelocity = Vector3.new(random:NextNumber(-5, 5), random:NextNumber(-42, -26), random:NextNumber(-5, 5))
			blob.AssemblyAngularVelocity = Vector3.new(random:NextNumber(-7, 7), random:NextNumber(-7, 7), random:NextNumber(-7, 7))
			Debris:AddItem(blob, Constants.EventDuration + 4)

			if index % 12 == 0 then
				task.wait(0.08)
			end
		end

		context.DiscoveryService:UnlockForAll(Constants.Discoveries.ObjectRain.Id)
		task.wait(Constants.EventDuration)
	end,
}
