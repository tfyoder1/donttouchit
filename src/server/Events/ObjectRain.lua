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

local SUB_LEVEL_ONE_Y = Constants.Room.RecoveryY + 9.15
local SUB_LEVEL_ONE_EDGE_X = (Constants.Room.Width + 14) / 2 - 3
local SUB_LEVEL_ONE_EDGE_Z = (Constants.Room.Depth + 14) / 2 - 3

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

local function clampToSubLevel(position)
	return Vector3.new(
		math.clamp(position.X, -SUB_LEVEL_ONE_EDGE_X, SUB_LEVEL_ONE_EDGE_X),
		SUB_LEVEL_ONE_Y,
		math.clamp(position.Z, -SUB_LEVEL_ONE_EDGE_Z, SUB_LEVEL_ONE_EDGE_Z)
	)
end

local function nearestEdgeDirection(position)
	local candidates = {
		{ Distance = SUB_LEVEL_ONE_EDGE_X - position.X, Direction = Vector3.new(1, 0, 0) },
		{ Distance = position.X + SUB_LEVEL_ONE_EDGE_X, Direction = Vector3.new(-1, 0, 0) },
		{ Distance = SUB_LEVEL_ONE_EDGE_Z - position.Z, Direction = Vector3.new(0, 0, 1) },
		{ Distance = position.Z + SUB_LEVEL_ONE_EDGE_Z, Direction = Vector3.new(0, 0, -1) },
	}

	table.sort(candidates, function(left, right)
		return left.Distance < right.Distance
	end)

	return candidates[1].Direction
end

local function getSweepDirection(body, player)
	local rootPart = player and getRootPart(player)
	if rootPart then
		local away = body.Position - rootPart.Position
		local horizontal = Vector3.new(away.X, 0, away.Z)
		if horizontal.Magnitude > 0.25 then
			return horizontal.Unit
		end
	end

	return nearestEdgeDirection(body.Position)
end

local function shoveNearbyRain(origin, direction, radius, random)
	for _, part in ipairs(CollectionService:GetTagged(Constants.Tags.ObjectRainObject)) do
		if part:IsA("BasePart") and part.Parent then
			local delta = part.Position - origin
			local horizontalDelta = Vector3.new(delta.X, 0, delta.Z)
			if horizontalDelta.Magnitude <= radius and part.Position.Y <= Constants.Room.FloorY - 4 then
				local projected = part.Position + direction * 8
				local dropVelocity = if math.abs(projected.X) >= SUB_LEVEL_ONE_EDGE_X - 2 or math.abs(projected.Z) >= SUB_LEVEL_ONE_EDGE_Z - 2 then -24 else -5
				part.AssemblyLinearVelocity = direction * 54 + Vector3.new(0, dropVelocity, 0)
				part.AssemblyAngularVelocity = Vector3.new(
					random:NextNumber(-13, 13),
					random:NextNumber(-16, 16),
					random:NextNumber(-13, 13)
				)
			end
		end
	end
end

local function createToyPart(parent, name, size, cframe, color, material, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.TopSurface = Enum.SurfaceType.Smooth
	part.CanCollide = false
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	if shape then
		part.Shape = shape
	end
	part.Parent = parent
	return part
end

local function createSubLevelSweeper(folder, context, random)
	local model = Instance.new("Model")
	model.Name = "SubLevel1SweepToy"
	model.Parent = folder
	CollectionService:AddTag(model, Constants.Tags.TemporaryObject)

	local startCFrame = CFrame.lookAt(Vector3.new(-21, SUB_LEVEL_ONE_Y, 17), Vector3.new(-15, SUB_LEVEL_ONE_Y, 17))
	local body = createToyPart(model, "SweepToyBody", Vector3.new(3.35, 0.72, 3.35), startCFrame, Color3.fromRGB(54, 64, 73), Enum.Material.Metal, Enum.PartType.Cylinder)
	body.CanCollide = false
	local top = createToyPart(model, "SweepToyTop", Vector3.new(2.1, 0.38, 2.1), startCFrame * CFrame.new(0, 0.48, 0), Color3.fromRGB(84, 154, 255), Enum.Material.Neon, Enum.PartType.Cylinder)
	local bumper = createToyPart(model, "SweepToyBumper", Vector3.new(3.7, 0.32, 0.42), startCFrame * CFrame.new(0, -0.06, -1.62), Color3.fromRGB(255, 221, 84), Enum.Material.Neon)
	local antenna = createToyPart(model, "SweepToyAntenna", Vector3.new(0.16, 1.25, 0.16), startCFrame * CFrame.new(0.55, 1.05, 0.15), Color3.fromRGB(220, 232, 240), Enum.Material.Metal, Enum.PartType.Cylinder)
	local antennaTip = createToyPart(model, "SweepToyAntennaTip", Vector3.new(0.42, 0.42, 0.42), startCFrame * CFrame.new(0.55, 1.72, 0.15), Color3.fromRGB(255, 84, 84), Enum.Material.Neon, Enum.PartType.Ball)
	model.PrimaryPart = body

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SweepToyPrompt"
	prompt.ActionText = "Sweep"
	prompt.ObjectText = "Sub Level 1 Sweep Toy"
	prompt.HoldDuration = 0.05
	prompt.RequiresLineOfSight = false
	prompt.ClickablePrompt = true
	prompt.MaxActivationDistance = 12
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.Parent = body

	local sweeping = false
	local lastBroadcastAt = 0

	local function sweep(player, direction)
		if sweeping or not model.Parent or not body.Parent then
			return
		end

		sweeping = true
		direction = direction or nearestEdgeDirection(body.Position)

		if player and context.RecordInteraction then
			context.RecordInteraction(player)
		end

		if player and context.BroadcastMessage and os.clock() - lastBroadcastAt > 4 then
			lastBroadcastAt = os.clock()
			context.BroadcastMessage("Sub Level 1 sweep toy has entered appliance-with-a-purpose mode.")
		end

		for step = 1, 4 do
			if not model.Parent or not body.Parent then
				break
			end

			local nextPosition = clampToSubLevel(body.Position + direction * 3.6)
			model:PivotTo(CFrame.lookAt(nextPosition, nextPosition + direction) * CFrame.Angles(0, math.rad(step * 16), 0))
			shoveNearbyRain(body.Position, direction, 13.5, random)
			task.wait(0.18)
		end

		sweeping = false
	end

	prompt.Triggered:Connect(function(player)
		sweep(player, getSweepDirection(body, player))
	end)

	task.spawn(function()
		local directions = {
			Vector3.new(1, 0, 0),
			Vector3.new(0, 0, -1),
			Vector3.new(-1, 0, 0),
			Vector3.new(0, 0, 1),
		}
		local index = 1

		task.wait(1.6)
		while folder.Parent and model.Parent do
			sweep(nil, directions[index])
			index = (index % #directions) + 1
			task.wait(3.2)
		end
	end)

	if context.BroadcastMessage then
		context.BroadcastMessage("Sub Level 1 deployed a sweep toy in the corner. It looks helpfully underqualified.")
	end
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

		createSubLevelSweeper(folder, context, random)
		startBasementWatcher(folder, context)
		context.DiscoveryService:UnlockForAll(Constants.Discoveries.ObjectRain.Id)
		task.wait(1)
	end,
}
