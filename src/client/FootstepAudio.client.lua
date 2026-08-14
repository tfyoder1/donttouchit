local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local footstepConfig = Constants.AudioAssets and Constants.AudioAssets.Footsteps
if not footstepConfig then
	return
end

local random = Random.new()
local character = nil
local humanoid = nil
local rootPart = nil
local stepAccumulator = 0
local defaultRunningConnection = nil
local floorRaycastParams = RaycastParams.new()
floorRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
floorRaycastParams.IgnoreWater = false

local function normalizeSoundId(soundId)
	if typeof(soundId) == "number" then
		return "rbxassetid://" .. tostring(soundId)
	end

	if typeof(soundId) ~= "string" or soundId == "" then
		return nil
	end

	if string.match(soundId, "^%d+$") then
		return "rbxassetid://" .. soundId
	end

	return soundId
end

local function positionInZone(position, zone)
	if not zone or not zone.Min or not zone.Max then
		return false
	end

	return position.X >= zone.Min.X
		and position.X <= zone.Max.X
		and position.Y >= zone.Min.Y
		and position.Y <= zone.Max.Y
		and position.Z >= zone.Min.Z
		and position.Z <= zone.Max.Z
end

local function muteDefaultRunningSound(instance)
	if instance and instance:IsA("Sound") and instance.Name == "Running" then
		instance.Volume = 0
	end
end

local function watchDefaultRunningSound(root)
	if defaultRunningConnection then
		defaultRunningConnection:Disconnect()
		defaultRunningConnection = nil
	end

	if not root then
		return
	end

	muteDefaultRunningSound(root:FindFirstChild("Running"))
	defaultRunningConnection = root.ChildAdded:Connect(muteDefaultRunningSound)
end

local function getRoomIdForPosition(position)
	for _, roomId in ipairs(Constants.RoomDetectionOrder or Constants.DiscoveryRoomOrder or Constants.RoomOrder or {}) do
		local room = Constants.GetRoom(roomId)
		if room and positionInZone(position, room.Zone) then
			return roomId
		end
	end

	return nil
end

local function getAreaSoundId(position)
	local areaOrder = footstepConfig.AreaOrder or {}
	local areas = footstepConfig.Areas or {}

	for _, areaId in ipairs(areaOrder) do
		local area = areas[areaId]
		if area and positionInZone(position, area.Zone) then
			return area.SoundId
		end
	end

	return nil
end

local function getTaggedPartSoundId(part)
	local taggedPartSoundIds = footstepConfig.TaggedParts
	if not part or not taggedPartSoundIds then
		return nil
	end

	local current = part
	while current and current ~= Workspace do
		for tagName, soundId in pairs(taggedPartSoundIds) do
			if typeof(tagName) == "string" and CollectionService:HasTag(current, tagName) then
				return soundId
			end
		end
		current = current.Parent
	end

	return nil
end

local function getFloorPart()
	if not rootPart then
		return nil
	end

	floorRaycastParams.FilterDescendantsInstances = if character then { character } else {}
	local result = Workspace:Raycast(rootPart.Position, Vector3.new(0, -8, 0), floorRaycastParams)
	local instance = result and result.Instance
	if instance and instance:IsA("BasePart") then
		return instance
	end

	return nil
end

local function getMaterialSoundId(material)
	local materialIds = footstepConfig.Materials
	local materialName = material and material.Name

	if not materialIds or not materialName then
		return nil
	end

	return materialIds[materialName]
end

local function getFootstepSoundId(position, floorMaterial, floorPart)
	local taggedPartSoundId = getTaggedPartSoundId(floorPart)
	if taggedPartSoundId then
		return taggedPartSoundId
	end

	local areaSoundId = getAreaSoundId(position)
	if areaSoundId then
		return areaSoundId
	end

	local roomId = getRoomIdForPosition(position)
	local materialSoundId = getMaterialSoundId(floorMaterial)

	if roomId == "CaveEntrance" and materialSoundId == footstepConfig.Materials.Grass then
		return materialSoundId
	elseif roomId == "Island" and materialSoundId == footstepConfig.Materials.Grass then
		return materialSoundId
	end

	local roomSoundId = roomId and footstepConfig.Rooms and footstepConfig.Rooms[roomId]
	if roomSoundId then
		return roomSoundId
	end

	return materialSoundId
end

local function isGroundedMoving()
	if not humanoid or humanoid.Health <= 0 or not rootPart then
		return false, 0
	end

	local state = humanoid:GetState()
	if state == Enum.HumanoidStateType.Freefall
		or state == Enum.HumanoidStateType.FallingDown
		or state == Enum.HumanoidStateType.Jumping
		or state == Enum.HumanoidStateType.Climbing
		or state == Enum.HumanoidStateType.Swimming
		or state == Enum.HumanoidStateType.Seated
		or humanoid.FloorMaterial == Enum.Material.Air
	then
		return false, 0
	end

	local velocity = rootPart.AssemblyLinearVelocity
	local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	if humanoid.MoveDirection.Magnitude < 0.05 or horizontalSpeed < 1.2 then
		return false, horizontalSpeed
	end

	return true, horizontalSpeed
end

local function getStepInterval(horizontalSpeed)
	local minInterval = tonumber(footstepConfig.MinIntervalSeconds) or 0.24
	local maxInterval = tonumber(footstepConfig.MaxIntervalSeconds) or 0.48
	local speed = math.clamp(horizontalSpeed, 4, 24)
	local alpha = (speed - 4) / 20

	return maxInterval + (minInterval - maxInterval) * alpha
end

local function playFootstep(soundId)
	soundId = normalizeSoundId(soundId)
	if not soundId or not rootPart then
		return
	end

	local sound = Instance.new("Sound")
	sound.Name = "DontTouchItLocalFootstep"
	sound.SoundId = soundId
	sound.Volume = math.clamp(tonumber(footstepConfig.Volume) or 0.32, 0, 1)
	sound.PlaybackSpeed = random:NextNumber(0.96, 1.04)
	sound.RollOffMinDistance = 3
	sound.RollOffMaxDistance = tonumber(footstepConfig.RollOffMaxDistance) or 18
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.Parent = rootPart
	sound:Play()

	Debris:AddItem(sound, 2.5)
end

local function setCharacter(nextCharacter)
	character = nextCharacter
	humanoid = nil
	rootPart = nil
	stepAccumulator = 0

	if defaultRunningConnection then
		defaultRunningConnection:Disconnect()
		defaultRunningConnection = nil
	end

	if not character then
		return
	end

	humanoid = character:FindFirstChildOfClass("Humanoid")
	rootPart = character:FindFirstChild("HumanoidRootPart")

	if not humanoid then
		humanoid = character:WaitForChild("Humanoid", 8)
	end

	if not rootPart then
		rootPart = character:WaitForChild("HumanoidRootPart", 8)
	end

	watchDefaultRunningSound(rootPart)
end

player.CharacterAdded:Connect(setCharacter)
player.CharacterRemoving:Connect(function()
	setCharacter(nil)
end)

if player.Character then
	setCharacter(player.Character)
end

RunService.Heartbeat:Connect(function(deltaTime)
	local moving, horizontalSpeed = isGroundedMoving()
	if not moving then
		stepAccumulator = 0
		return
	end

	stepAccumulator += deltaTime
	local interval = getStepInterval(horizontalSpeed)
	if stepAccumulator < interval then
		return
	end

	stepAccumulator = math.max(0, stepAccumulator - interval)
	playFootstep(getFootstepSoundId(rootPart.Position, humanoid.FloorMaterial, getFloorPart()))
end)
