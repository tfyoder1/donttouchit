local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local COLORS = {
	Color3.fromRGB(255, 84, 84),
	Color3.fromRGB(255, 221, 84),
	Color3.fromRGB(84, 180, 255),
	Color3.fromRGB(102, 255, 166),
	Color3.fromRGB(218, 108, 255),
}

local function getRootPart(player)
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function openFloorSlots(random)
	local openedCount = 0
	local fallbackFloor = nil

	for _, floor in ipairs(CollectionService:GetTagged(Constants.Tags.FloorSection)) do
		if floor:IsA("BasePart") then
			fallbackFloor = fallbackFloor or floor
			if random:NextNumber() <= 0.32 then
				floor.Transparency = 1
				floor.CanCollide = false
				openedCount += 1
			end
		end
	end

	if openedCount == 0 and fallbackFloor then
		fallbackFloor.Transparency = 1
		fallbackFloor.CanCollide = false
	end
end

local function createMovePrompt(blob, context, random)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ObjectRainMovePrompt"
	prompt.ActionText = "Shove"
	prompt.ObjectText = "Rain Object"
	prompt.HoldDuration = 0.08
	prompt.RequiresLineOfSight = false
	prompt.ClickablePrompt = true
	prompt.MaxActivationDistance = 9
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.Parent = blob

	prompt.Triggered:Connect(function(player)
		if context.RecordInteraction then
			context.RecordInteraction(player)
		end

		local rootPart = getRootPart(player)
		local shove = nil
		if rootPart then
			local away = blob.Position - rootPart.Position
			shove = Vector3.new(away.X, 0, away.Z)
		end

		if not shove or shove.Magnitude < 0.1 then
			shove = Vector3.new(random:NextNumber(-1, 1), 0, random:NextNumber(-1, 1))
		end

		if shove.Magnitude < 0.1 then
			shove = Vector3.new(1, 0, 0)
		end

		blob.AssemblyLinearVelocity = shove.Unit * 38 + Vector3.new(0, -42, 0)
		blob.AssemblyAngularVelocity = Vector3.new(
			random:NextNumber(-12, 12),
			random:NextNumber(-12, 12),
			random:NextNumber(-12, 12)
		)
	end)
end

local function startBasementWatcher(folder, context)
	task.spawn(function()
		local downstairsY = Constants.Room.RecoveryY + 9
		local awarded = false

		while folder.Parent and not awarded do
			local rainParts = {}
			for _, child in ipairs(folder:GetChildren()) do
				if child:IsA("BasePart") and CollectionService:HasTag(child, Constants.Tags.ObjectRainObject) then
					table.insert(rainParts, child)
				end
			end

			if #rainParts > 0 then
				local allDownstairs = true
				for _, part in ipairs(rainParts) do
					if part.Position.Y > downstairsY then
						allDownstairs = false
						break
					end
				end

				if allDownstairs then
					awarded = true
					context.DiscoveryService:UnlockForAll(Constants.Discoveries.RainBasement.Id)
					if context.BroadcastMessage then
						context.BroadcastMessage("Secret found: the object rain has been relocated downstairs.")
					end
				end
			end

			task.wait(2)
		end
	end)
end

return {
	Id = "object_rain",
	Name = "Object Rain",
	Weight = 0,
	StartMessage = "Button milestone reached: the ceiling is dropping things inside the room.",

	Run = function(context)
		local folder = Instance.new("Folder")
		folder.Name = "TemporaryObjectRain"
		folder.Parent = workspace
		CollectionService:AddTag(folder, Constants.Tags.TemporaryObject)

		local random = Random.new()

		if context.BroadcastMessage then
			context.BroadcastMessage("Object rain is actually inside the ceiling this time. Look up.")
		end

		openFloorSlots(random)
		if context.BroadcastMessage then
			context.BroadcastMessage("The floor opened sorting slots. Shove every rain object downstairs for a secret.")
		end

		for index = 1, 110 do
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
			blob.CFrame = CFrame.new(
				random:NextNumber(-18, 18),
				random:NextNumber(Constants.Room.TVHeight - 5, Constants.Room.TVHeight - 1.5),
				random:NextNumber(-14, 14)
			)
			blob.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.25, 0.75)
			blob.Parent = folder
			CollectionService:AddTag(blob, Constants.Tags.TemporaryObject)
			CollectionService:AddTag(blob, Constants.Tags.ObjectRainObject)
			createMovePrompt(blob, context, random)
			blob.AssemblyLinearVelocity = Vector3.new(random:NextNumber(-5, 5), random:NextNumber(-42, -26), random:NextNumber(-5, 5))
			blob.AssemblyAngularVelocity = Vector3.new(random:NextNumber(-7, 7), random:NextNumber(-7, 7), random:NextNumber(-7, 7))

			if index % 10 == 0 then
				task.wait(0.05)
			end
		end

		startBasementWatcher(folder, context)
		context.DiscoveryService:UnlockForAll(Constants.Discoveries.ObjectRain.Id)
		task.wait(1)
	end,
}
