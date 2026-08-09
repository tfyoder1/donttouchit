local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local COLORS = {
	Color3.fromRGB(255, 221, 161),
	Color3.fromRGB(246, 170, 118),
	Color3.fromRGB(255, 245, 210),
	Color3.fromRGB(213, 238, 188),
}

return {
	Id = "object_rain",
	Name = "Object Rain",
	Weight = 1,
	StartMessage = "The ceiling is serving dumplings.",

	Run = function(context)
		local folder = Instance.new("Folder")
		folder.Name = "TemporaryObjectRain"
		folder.Parent = workspace
		CollectionService:AddTag(folder, Constants.Tags.TemporaryObject)

		local random = Random.new()

		for index = 1, 42 do
			local blob = Instance.new("Part")
			blob.Name = "FallingBlob"
			blob.Shape = Enum.PartType.Ball
			blob.Size = Vector3.new(
				random:NextNumber(1.2, 2.8),
				random:NextNumber(0.8, 1.8),
				random:NextNumber(1.2, 2.8)
			)
			blob.Color = COLORS[random:NextInteger(1, #COLORS)]
			blob.Material = Enum.Material.SmoothPlastic
			blob.CFrame = CFrame.new(random:NextNumber(-18, 18), random:NextNumber(21, 32), random:NextNumber(-14, 14))
			blob.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.25, 0.75)
			blob.Parent = folder
			CollectionService:AddTag(blob, Constants.Tags.TemporaryObject)
			Debris:AddItem(blob, Constants.EventDuration + 4)

			if index % 8 == 0 then
				task.wait(0.1)
			end
		end

		context.DiscoveryService:UnlockForAll(Constants.Discoveries.ObjectRain.Id)
		task.wait(Constants.EventDuration)
	end,
}

