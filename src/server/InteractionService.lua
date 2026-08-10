local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local PlayerScale = require(script.Parent:WaitForChild("PlayerScale"))
local RemoteService = require(script.Parent:WaitForChild("RemoteService"))

local InteractionService = {}
InteractionService.__index = InteractionService

local COUCH_GET_UP_LABELS = {
	"Try to Get Up",
	"Ask Nicely",
	"Wiggle Free",
	"Negotiate Release",
	"Accept Cushion Fate",
}

local COUCH_REFUSAL_MESSAGES = {
	"The couch pretends not to hear you.",
	"The cushions tighten their argument.",
	"The couch is still considering your request.",
}

local SWITCH_ON_COLORS = {
	Color3.fromRGB(255, 224, 145),
	Color3.fromRGB(142, 210, 255),
	Color3.fromRGB(206, 153, 255),
	Color3.fromRGB(133, 255, 190),
	Color3.fromRGB(255, 144, 177),
}

local ROOM_MOODS = {
	{
		Label = "laundromat birthday",
		Color = Color3.fromRGB(151, 221, 232),
		Material = Enum.Material.Concrete,
	},
	{
		Label = "fresh cardboard",
		Color = Color3.fromRGB(219, 187, 122),
		Material = Enum.Material.WoodPlanks,
	},
	{
		Label = "polite dungeon",
		Color = Color3.fromRGB(150, 167, 177),
		Material = Enum.Material.Brick,
	},
	{
		Label = "arcade carpet energy",
		Color = Color3.fromRGB(85, 204, 154),
		Material = Enum.Material.Foil,
	},
	{
		Label = "unlicensed dentist",
		Color = Color3.fromRGB(236, 226, 202),
		Material = Enum.Material.Marble,
	},
}

local TV_ROOM_MOOD_SURFACES = {
	BackWall = true,
	Ceiling = true,
	FrontWallHeader = true,
	FrontWallLeft = true,
	FrontWallRight = true,
	LeftWall = true,
	RightWall = true,
}

local TV_SOUND_IDS = {
	Static = "rbxasset://sounds/electronicpingshort.wav",
	TestTone = "rbxasset://sounds/electronicpingshort.wav",
	Warning = "rbxasset://sounds/snap.wav",
}

local SNACK_BUTTON_ACTIVITIES = {
	"flight",
	"slow_motion",
	"mood",
	"rack_rattle",
}

local SNACK_FLIGHT_DURATION = 60
local SNACK_FLIGHT_INITIAL_BOOST = 16
local SNACK_FLIGHT_CEILING_Y = Constants.Rooms.SnackLab.Zone.Max.Y - 5.2
local SNACK_SLOW_MOTION_DURATION = 12
local SNACK_SUPER_WIND_GUSTS = 5

local SNACK_SOUND_PROFILES = {
	CRONCH = {
		Message = "CRONCH performs a literal structural crunch.",
		Color = Color3.fromRGB(255, 230, 118),
		Sounds = {
			{ Id = "rbxasset://sounds/snap.wav", Delay = 0, Volume = 0.8, Speed = 0.65 },
			{ Id = "rbxasset://sounds/snap.wav", Delay = 0.12, Volume = 0.8, Speed = 0.82 },
			{ Id = "rbxasset://sounds/button.wav", Delay = 0.22, Volume = 0.45, Speed = 0.5 },
		},
	},
	["ZAP CHIPS"] = {
		Message = "ZAP CHIPS emit snack electricity.",
		Color = Color3.fromRGB(111, 224, 255),
		Sounds = {
			{ Id = "rbxasset://sounds/electronicpingshort.wav", Delay = 0, Volume = 0.75, Speed = 1.7 },
			{ Id = "rbxasset://sounds/electronicpingshort.wav", Delay = 0.11, Volume = 0.65, Speed = 2.25 },
			{ Id = "rbxasset://sounds/snap.wav", Delay = 0.2, Volume = 0.55, Speed = 1.4 },
		},
	},
	MYSTERY = {
		Message = "MYSTERY makes a sound with no paperwork.",
		Color = Color3.fromRGB(196, 122, 255),
		Sounds = {
			{ Id = "rbxasset://sounds/electronicpingshort.wav", Delay = 0, Volume = 0.55, Speed = 0.35 },
			{ Id = "rbxasset://sounds/button.wav", Delay = 0.18, Volume = 0.45, Speed = 0.48 },
			{ Id = "rbxasset://sounds/electronicpingshort.wav", Delay = 0.34, Volume = 0.45, Speed = 0.72 },
		},
	},
	PUFFS = {
		Message = "PUFFS puff with tiny confidence.",
		Color = Color3.fromRGB(245, 248, 255),
		Sounds = {
			{ Id = "rbxasset://sounds/button.wav", Delay = 0, Volume = 0.32, Speed = 1.55 },
			{ Id = "rbxasset://sounds/button.wav", Delay = 0.1, Volume = 0.28, Speed = 1.85 },
			{ Id = "rbxasset://sounds/button.wav", Delay = 0.2, Volume = 0.24, Speed = 2.15 },
		},
	},
	NOPE = {
		Message = "NOPE refuses in audio form.",
		Color = Color3.fromRGB(255, 112, 122),
		Sounds = {
			{ Id = "rbxasset://sounds/snap.wav", Delay = 0, Volume = 0.65, Speed = 0.48 },
			{ Id = "rbxasset://sounds/snap.wav", Delay = 0.28, Volume = 0.65, Speed = 0.42 },
		},
	},
}

local function getPrompt(root)
	if root:IsA("ProximityPrompt") then
		return root
	end

	if root:IsA("BasePart") then
		return root:FindFirstChildOfClass("ProximityPrompt")
	end

	return root:FindFirstChild("InteractPrompt", true)
end

local function getHumanoid(player)
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

local function getRootPart(player)
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function teleportPlayer(player, destinationCFrame)
	local rootPart = getRootPart(player)
	if not rootPart or typeof(destinationCFrame) ~= "CFrame" then
		return
	end

	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
	rootPart.CFrame = destinationCFrame
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

local function countDictionary(dictionary)
	local count = 0
	for _, value in pairs(dictionary) do
		if value then
			count += 1
		end
	end

	return count
end

local function tweenPart(part, duration, properties, easingStyle, easingDirection)
	local tween = TweenService:Create(
		part,
		TweenInfo.new(duration, easingStyle or Enum.EasingStyle.Quad, easingDirection or Enum.EasingDirection.Out),
		properties
	)
	tween:Play()
	return tween
end

local function tweenModel(model, targetPivot, duration)
	local pivotValue = Instance.new("CFrameValue")
	pivotValue.Value = model:GetPivot()

	local connection = pivotValue:GetPropertyChangedSignal("Value"):Connect(function()
		if model.Parent then
			model:PivotTo(pivotValue.Value)
		end
	end)

	local tween = TweenService:Create(
		pivotValue,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		{ Value = targetPivot }
	)

	tween:Play()
	tween.Completed:Wait()
	connection:Disconnect()
	pivotValue:Destroy()
end

local function playSound(parent, soundId, volume, playbackSpeed)
	if not parent or not parent.Parent then
		return
	end

	local sound = Instance.new("Sound")
	sound.Name = "TemporarySound"
	sound.SoundId = soundId
	sound.Volume = volume or 0.7
	sound.PlaybackSpeed = playbackSpeed or 1
	sound.RollOffMaxDistance = 45
	sound.Parent = parent
	sound:Play()
	Debris:AddItem(sound, 3)
end

local function getInstanceAndDescendants(root)
	if not root then
		return {}
	end

	local instances = root:GetDescendants()
	table.insert(instances, root)
	return instances
end

local function setPromptEnabled(root, enabled)
	for _, instance in ipairs(getInstanceAndDescendants(root)) do
		if instance:IsA("ProximityPrompt") then
			instance.Enabled = enabled
		end
	end
end

local function setTextLabelText(root, labelName, text)
	local label = root and root:FindFirstChild(labelName, true)
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

local function setSurfaceGuiEnabled(root, labelName, enabled)
	local label = root and root:FindFirstChild(labelName, true)
	if label and label.Parent and label.Parent:IsA("SurfaceGui") then
		label.Parent.Enabled = enabled
	end
end

local function setFridgeContentVisible(root, visible)
	for _, instance in ipairs(getInstanceAndDescendants(root)) do
		if instance:IsA("BasePart") then
			local openTransparency = instance:GetAttribute("OpenTransparency")
			local openCanCollide = instance:GetAttribute("OpenCanCollide")

			if visible then
				instance.Transparency = if openTransparency ~= nil then openTransparency else 0
				instance.CanCollide = if openCanCollide ~= nil then openCanCollide else instance.CanCollide
			else
				instance.Transparency = 1
				instance.CanCollide = false
			end
		elseif instance:IsA("PointLight") or instance:IsA("SpotLight") or instance:IsA("SurfaceLight") then
			local openEnabled = instance:GetAttribute("OpenEnabled")
			instance.Enabled = visible and (openEnabled == nil or openEnabled == true)
		elseif instance:IsA("SurfaceGui") then
			local openEnabled = instance:GetAttribute("OpenEnabled")
			instance.Enabled = visible and (openEnabled == nil or openEnabled == true)
		end
	end
end

local function getFridgeDoorOpenCFrame(door)
	local baseCFrame = door:GetAttribute("BaseCFrame") or door.CFrame
	local hingeOffset = -door.Size.X / 2

	return baseCFrame
		* CFrame.new(hingeOffset, 0, 0)
		* CFrame.Angles(0, math.rad(-112), 0)
		* CFrame.new(-hingeOffset, 0, 0)
end

function InteractionService.new(eventManager, discoveryService, resetService, roomProgressService)
	local self = setmetatable({}, InteractionService)
	self.eventManager = eventManager
	self.discoveryService = discoveryService
	self.resetService = resetService
	self.roomProgressService = roomProgressService
	self.systemMessageRemote = RemoteService.GetRemote(Constants.Remotes.SystemMessage)
	self.snackEffectRemote = RemoteService.GetRemote(Constants.Remotes.SnackEffect)
	self.connectedPrompts = {}
	self.snackButtonRandom = Random.new()
	self.couchState = {}
	self.couchRiding = {}
	self.lampState = {}
	self.lightSwitchState = {
		IsOn = true,
		OnCycle = 0,
		Reacting = false,
		GiantAwardedByUserId = {},
		Switches = {},
	}
	self.floorPressStateByUserId = {}
	self.squishyState = {}
	self.tvState = {}
	self.applianceState = {}
	self.exitUnlocked = false
	self.underfloorReturnState = {}
	self.snackButtonState = {}
	self.snackFanState = {}
	self.roomMoodStateByRoomId = {}
	self.fridgeState = {}
	self.secretFridgeButtonState = {}
	self.toasterState = {}
	self.sinkState = {}
	self.mixerState = {}
	self.snackRackState = {}
	self.snackPackStateByUserId = {}
	self.slowMotionTokensByHumanoid = {}
	self.fruitBowlState = {}
	self.islandExitBounceAtByUserId = {}
	self.islandExitWarningsByUserId = {}
	self.islandExitTouchConnections = {}
	self.islandShovelState = {}
	self.islandTreasureState = {}
	self.islandColaState = {}
	self.secretDoorState = {}
	return self
end

function InteractionService:Initialize()
	if self.discoveryService.DiscoveryUnlocked then
		self.discoveryService.DiscoveryUnlocked:Connect(function(player)
			self:_checkExitUnlock(player)
			self:_refreshSecretDoorsForPlayer(player)
		end)
	end

	if self.discoveryService.SecretDoorChanged then
		self.discoveryService.SecretDoorChanged:Connect(function(player)
			self:_refreshSecretDoorsForPlayer(player)
		end)
	end

	Players.PlayerAdded:Connect(function(player)
		task.delay(1.5, function()
			if player.Parent then
				self:_refreshSecretDoorsForPlayer(player)
			end
		end)
	end)

	self:_connectTagged(Constants.Tags.MainButton, function(instance)
		self:_wireMainButton(instance)
	end)

	self:_connectTagged(Constants.Tags.LightSwitch, function(instance)
		self:_wireLightSwitch(instance)
	end)

	self:_connectTagged(Constants.Tags.FloorSection, function(instance)
		self:_wireFloorSection(instance)
	end)

	self:_connectTagged(Constants.Tags.Couch, function(instance)
		self:_wireCouch(instance)
	end)

	self:_connectTagged(Constants.Tags.FloorLamp, function(instance)
		self:_wireLamp(instance)
	end)

	self:_connectTagged(Constants.Tags.Squishy, function(instance)
		self:_wireSquishy(instance)
	end)

	self:_connectTagged(Constants.Tags.Television, function(instance)
		self:_wireTelevision(instance)
	end)

	self:_connectTagged(Constants.Tags.Appliance, function(instance)
		self:_wireAppliance(instance)
	end)

	self:_connectTagged(Constants.Tags.ExitDoor, function(instance)
		self:_wireExitDoor(instance)
	end)

	self:_connectTagged(Constants.Tags.HallDoor, function(instance)
		self:_wireHallDoor(instance)
	end)

	self:_connectTagged(Constants.Tags.ReferenceBook, function(instance)
		self:_wireReferenceBook(instance)
	end)

	self:_connectTagged(Constants.Tags.SecretRoomDoor, function(instance)
		self:_wireSecretRoomDoor(instance)
	end)

	self:_connectTagged(Constants.Tags.SecretRoomExit, function(instance)
		self:_wireSecretRoomExit(instance)
	end)

	self:_connectTagged(Constants.Tags.ResetRoomButton, function(instance)
		self:_wireResetRoomButton(instance)
	end)

	self:_connectTagged(Constants.Tags.UnderfloorReturn, function(instance)
		self:_wireUnderfloorReturn(instance)
	end)

	self:_connectTagged(Constants.Tags.SnackButton, function(instance)
		self:_wireSnackButton(instance)
	end)

	self:_connectTagged(Constants.Tags.SnackCeilingFan, function(instance)
		self:_wireSnackCeilingFan(instance)
	end)

	self:_connectTagged(Constants.Tags.SnackFridge, function(instance)
		self:_wireSnackFridge(instance)
	end)

	self:_connectTagged(Constants.Tags.FridgePizza, function(instance)
		self:_wireFridgePizza(instance)
	end)

	self:_connectTagged(Constants.Tags.FridgeBloxyCola, function(instance)
		self:_wireFridgeBloxyCola(instance)
	end)

	self:_connectTagged(Constants.Tags.SecretFridgeButton, function(instance)
		self:_wireSecretFridgeButton(instance)
	end)

	self:_connectTagged(Constants.Tags.SnackToaster, function(instance)
		self:_wireSnackToaster(instance)
	end)

	self:_connectTagged(Constants.Tags.SnackSink, function(instance)
		self:_wireSnackSink(instance)
	end)

	self:_connectTagged(Constants.Tags.SnackMixer, function(instance)
		self:_wireSnackMixer(instance)
	end)

	self:_connectTagged(Constants.Tags.SnackRack, function(instance)
		self:_wireSnackRack(instance)
	end)

	self:_connectTagged(Constants.Tags.SnackPack, function(instance)
		self:_wireSnackPack(instance)
	end)

	self:_connectTagged(Constants.Tags.FruitBowl, function(instance)
		self:_wireFruitBowl(instance)
	end)

	self:_connectTagged(Constants.Tags.IslandExit, function(instance)
		self:_wireIslandExit(instance)
	end)

	self:_connectTagged(Constants.Tags.IslandSharkSign, function(instance)
		self:_wireIslandWarningSign(instance, Constants.Discoveries.ReadSharkWarning.Id, "The shark sign feels less like advice and more like a countdown.")
	end)

	self:_connectTagged(Constants.Tags.IslandJellyfishSign, function(instance)
		self:_wireIslandWarningSign(instance, Constants.Discoveries.ReadJellyfishWarning.Id, "The jellyfish sign politely recommends owning fewer nerve endings.")
	end)

	self:_connectTagged(Constants.Tags.IslandShovel, function(instance)
		self:_wireIslandShovel(instance)
	end)

	self:_connectTagged(Constants.Tags.IslandTreasure, function(instance)
		self:_wireIslandTreasure(instance)
	end)

	self:_connectTagged(Constants.Tags.IslandBloxyCola, function(instance)
		self:_wireIslandBloxyCola(instance)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		self:_checkExitUnlock(player)
		self:_refreshSecretDoorsForPlayer(player)
	end
end

function InteractionService:_connectTagged(tagName, wireCallback)
	for _, instance in ipairs(CollectionService:GetTagged(tagName)) do
		wireCallback(instance)
	end

	CollectionService:GetInstanceAddedSignal(tagName):Connect(wireCallback)
end

function InteractionService:_connectPrompt(prompt, callback)
	if not prompt or self.connectedPrompts[prompt] then
		return
	end

	self.connectedPrompts[prompt] = true
	prompt.Triggered:Connect(function(player)
		if self.roomProgressService then
			self.roomProgressService:RecordInteraction(player)
		end

		callback(player)
	end)
end

function InteractionService:_wireMainButton(button)
	local prompt = getPrompt(button)

	self:_connectPrompt(prompt, function(player)
		local accepted = self.eventManager:TriggerRandom(player)
		if accepted and button:IsA("BasePart") then
			self:_cycleRoomMood("TVRoom")
			task.spawn(function()
				self:_pressButtonVisual(button)
			end)
		end
	end)
end

function InteractionService:_getRoomMoodSurfaces(roomId)
	local surfaces = {}
	local roomReferences = self.eventManager and self.eventManager.roomReferences

	if roomId == "TVRoom" then
		local roomRoot = roomReferences and roomReferences.Room or workspace:FindFirstChild("Room")
		if not roomRoot then
			return surfaces
		end

		for _, child in ipairs(roomRoot:GetChildren()) do
			if child:IsA("BasePart") and TV_ROOM_MOOD_SURFACES[child.Name] then
				table.insert(surfaces, child)
			end
		end
	elseif roomId == "SnackLab" then
		local snackLab = roomReferences and roomReferences.SnackLab and roomReferences.SnackLab.Model
		snackLab = snackLab or workspace:FindFirstChild("Room") and workspace.Room:FindFirstChild("SnackLabRoom")
		if not snackLab then
			return surfaces
		end

		for _, descendant in ipairs(snackLab:GetDescendants()) do
			if descendant:IsA("BasePart")
				and (descendant.Name:find("Wall", 1, true) or descendant.Name:find("Ceiling", 1, true))
			then
				table.insert(surfaces, descendant)
			end
		end
	end

	return surfaces
end

function InteractionService:_cycleRoomMood(roomId)
	local surfaces = self:_getRoomMoodSurfaces(roomId)
	if #surfaces == 0 then
		return
	end

	local nextIndex = ((self.roomMoodStateByRoomId[roomId] or 0) % #ROOM_MOODS) + 1
	self.roomMoodStateByRoomId[roomId] = nextIndex

	local mood = ROOM_MOODS[nextIndex]
	for _, part in ipairs(surfaces) do
		part.Material = mood.Material
		tweenPart(part, 0.35, {
			Color = mood.Color,
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end

	local room = Constants.GetRoom(roomId)
	self.systemMessageRemote:FireAllClients(("%s switched to %s walls."):format(room and room.Name or "The room", mood.Label))
end

function InteractionService:_pressButtonVisual(button)
	local visualParts = { button }
	local shine = button.Parent and button.Parent:FindFirstChild("BigRedButtonShine")
	if shine and shine:IsA("BasePart") then
		table.insert(visualParts, shine)
	end

	local baseColor = button:GetAttribute("BaseColor") or button.Color

	playSound(button, "rbxasset://sounds/button.wav", 0.45, 0.9)

	local downTween = nil
	for _, part in ipairs(visualParts) do
		local properties = {
			CFrame = (part:GetAttribute("BaseCFrame") or part.CFrame) + Vector3.new(0, -0.28, 0),
		}
		if part == button then
			properties.Color = Color3.fromRGB(165, 12, 23)
		end

		downTween = tweenPart(part, 0.1, properties, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end

	downTween.Completed:Wait()

	local upTween = nil
	for _, part in ipairs(visualParts) do
		local properties = {
			CFrame = part:GetAttribute("BaseCFrame") or part.CFrame,
		}
		if part == button then
			properties.Color = baseColor
		end

		upTween = tweenPart(part, 0.18, properties, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end

	upTween.Completed:Wait()
end

function InteractionService:_wireFloorSection(floorSection)
	local prompt = getPrompt(floorSection)

	self:_connectPrompt(prompt, function(player)
		local state = self.floorPressStateByUserId[player.UserId]
		if not state then
			state = {
				PressCount = 0,
			}
			self.floorPressStateByUserId[player.UserId] = state
		end

		state.PressCount += 1

		if state.PressCount < 5 then
			local message = Constants.FloorPressMessages[state.PressCount]
				or ("The floor reluctantly counts this as %d / 5."):format(state.PressCount)
			self.systemMessageRemote:FireClient(player, message)
			return
		end

		state.PressCount = 0
		local triggered = self.eventManager:TriggerById(player, "low_gravity")
		if not triggered then
			state.PressCount = 4
		end
	end)
end

function InteractionService:_wireLightSwitch(lightSwitch)
	local prompt = getPrompt(lightSwitch)
	local plate = lightSwitch:FindFirstChild("SwitchPlate", true)
	local lever = lightSwitch:FindFirstChild("SwitchLever", true)

	local state = self.lightSwitchState
	state.Switches[lightSwitch] = true
	self:_syncLightSwitches(state.IsOn)

	self:_connectPrompt(prompt, function(player)
		if not state or state.Reacting then
			return
		end

		state.Reacting = true
		state.IsOn = not state.IsOn

		if state.IsOn then
			state.OnCycle += 1
			local color = SWITCH_ON_COLORS[((state.OnCycle - 1) % #SWITCH_ON_COLORS) + 1]
			Lighting.Brightness = 2.2
			Lighting.ClockTime = 16
			Lighting.Ambient = color
			Lighting.OutdoorAmbient = color:Lerp(Color3.fromRGB(255, 255, 255), 0.22)
			self:_syncLightSwitches(true)

			playSound(plate or lever or lightSwitch, "rbxasset://sounds/electronicpingshort.wav", 0.55, 1.1)
			self.systemMessageRemote:FireClient(player, "The room lights came back in a different mood.")

			if lightSwitch:GetAttribute("UnlocksGiantDiscovery")
				and not state.GiantAwardedByUserId[player.UserId]
				and state.OnCycle >= 3
			then
				state.GiantAwardedByUserId[player.UserId] = true
				self:_lightSwitchGiant(player)
			end
		else
			Lighting.Brightness = 0.35
			Lighting.ClockTime = 0
			Lighting.Ambient = Color3.fromRGB(10, 12, 18)
			Lighting.OutdoorAmbient = Color3.fromRGB(5, 6, 10)
			self:_syncLightSwitches(false)

			playSound(plate or lever or lightSwitch, "rbxasset://sounds/button.wav", 0.45, 0.82)
			self.systemMessageRemote:FireClient(player, "The room goes suspiciously dark.")
		end

		task.wait(0.15)
		state.Reacting = false
	end)
end

function InteractionService:_syncLightSwitches(isOn)
	local state = self.lightSwitchState
	local colorIndex = math.max(1, state.OnCycle)
	local onColor = SWITCH_ON_COLORS[((colorIndex - 1) % #SWITCH_ON_COLORS) + 1]
	local plateColor = if isOn
		then onColor:Lerp(Color3.fromRGB(255, 255, 255), 0.7)
		else Color3.fromRGB(205, 205, 195)

	for lightSwitch in pairs(state.Switches) do
		if not lightSwitch.Parent then
			state.Switches[lightSwitch] = nil
			continue
		end

		local plate = lightSwitch:FindFirstChild("SwitchPlate", true)
		local lever = lightSwitch:FindFirstChild("SwitchLever", true)
		if plate and plate:IsA("BasePart") then
			plate:SetAttribute("IsOn", isOn)
			plate.Color = plateColor
		end

		self:_animateLightSwitch(lever, isOn)
	end
end

function InteractionService:_animateLightSwitch(lever, isOn)
	if not lever or not lever:IsA("BasePart") then
		return
	end

	local targetCFrame = if isOn
		then lever:GetAttribute("SwitchOnCFrame")
		else lever:GetAttribute("SwitchOffCFrame")
	targetCFrame = targetCFrame or lever:GetAttribute("BaseCFrame") or lever.CFrame
	tweenPart(lever, 0.12, {
		CFrame = targetCFrame,
	}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

function InteractionService:_lightSwitchGiant(player)
	local rootPart = getRootPart(player)
	task.spawn(function()
		for index = 1, 3 do
			playSound(rootPart, "rbxasset://sounds/electronicpingshort.wav", 0.75, 0.65 + index * 0.32)
			task.wait(0.13)
		end
	end)

	local snapshot = PlayerScale.Apply(player, 2.25)
	self.discoveryService:Unlock(player, Constants.Discoveries.GiantPlayer.Id)
	self.systemMessageRemote:FireClient(player, "The light switch made you inconveniently tall.")

	task.delay(Constants.EventDuration, function()
		PlayerScale.Restore(snapshot)
	end)
end

function InteractionService:_wireUnderfloorReturn(instance)
	local prompt = getPrompt(instance)

	self:_connectPrompt(prompt, function(player)
		local destinationCFrame = instance:GetAttribute("DestinationCFrame") or CFrame.new(0, 5, 10)
		self.discoveryService:Unlock(player, Constants.Discoveries.EscapedUnderfloor.Id)
		self.systemMessageRemote:FireClient(player, "The room underside sent you back upstairs.")
		teleportPlayer(player, destinationCFrame)
	end)
end

function InteractionService:_wireReferenceBook(bookPart)
	local prompt = getPrompt(bookPart)

	self:_connectPrompt(prompt, function(player)
		local roomId = bookPart:GetAttribute("RoomId") or "TVRoom"
		if self.roomProgressService then
			self.roomProgressService:ShowReferenceBook(player, roomId)
		end
	end)
end

function InteractionService:_getSecretDoorRoot(door)
	if not door then
		return nil
	end

	if door:IsA("BasePart") then
		return door:FindFirstAncestor("TVSecretDoor") or door
	end

	return door
end

function InteractionService:_setSecretDoorState(door, state)
	local root = self:_getSecretDoorRoot(door)
	if not root then
		return
	end

	state = state or {}
	local outlineVisible = state.OutlineVisible == true
	local active = state.Active == true
	local hasKey = state.HasKey == true

	for _, instance in ipairs(getInstanceAndDescendants(root)) do
		if instance:IsA("BasePart") then
			if active then
				local visibleTransparency = instance:GetAttribute("SecretVisibleTransparency")
				local visibleCanCollide = instance:GetAttribute("SecretVisibleCanCollide")
				instance.Transparency = if visibleTransparency ~= nil then visibleTransparency else 0
				instance.CanCollide = if visibleCanCollide ~= nil then visibleCanCollide else true
			elseif outlineVisible and instance:GetAttribute("SecretOutlineVisible") == true then
				local outlineTransparency = instance:GetAttribute("SecretOutlineTransparency")
				local outlineCanCollide = instance:GetAttribute("SecretOutlineCanCollide")
				instance.Transparency = if outlineTransparency ~= nil then outlineTransparency else 0
				instance.CanCollide = if outlineCanCollide ~= nil then outlineCanCollide else false
			else
				instance.Transparency = 1
				instance.CanCollide = false
			end
		elseif instance:IsA("ProximityPrompt") then
			local visibleEnabled = instance:GetAttribute("SecretVisibleEnabled")
			instance.Enabled = active and (visibleEnabled == nil or visibleEnabled == true)
			if active then
				instance.ActionText = if hasKey then "Open" else "Inspect"
				instance.ObjectText = if hasKey then "Library" else "Library - Awaiting Key"
			end
		elseif instance:IsA("SurfaceGui") then
			local visibleEnabled = instance:GetAttribute("SecretVisibleEnabled")
			instance.Enabled = active and (visibleEnabled == nil or visibleEnabled == true)
		elseif instance:IsA("TextLabel") and instance.Name == "SecretDoorText" then
			instance.Text = if hasKey then "LIBRARY\nKEY ACCEPTED" else "LIBRARY\nAWAITING KEY"
		end
	end
end

function InteractionService:_getSecretDoorWorldState(roomId)
	local state = {
		OutlineVisible = false,
		Active = false,
		HasKey = false,
	}

	for _, player in ipairs(Players:GetPlayers()) do
		if self.discoveryService:HasSecretDoorReveal(player, roomId) then
			state.OutlineVisible = true
		end

		if self.discoveryService:IsRoomComplete(player, roomId) then
			state.OutlineVisible = true
			state.Active = true
			if self.discoveryService:HasSecretKey(player, roomId) then
				state.HasKey = true
			end
		end
	end

	return state
end

function InteractionService:_refreshSecretDoorsForPlayer(player)
	if not player or not player.Parent then
		return
	end

	for _, door in ipairs(CollectionService:GetTagged(Constants.Tags.SecretRoomDoor)) do
		local roomId = door:GetAttribute("RoomId") or "TVRoom"
		self:_setSecretDoorState(door, self:_getSecretDoorWorldState(roomId))
	end
end

local function getSecretDoorOpenCFrame(doorPanel)
	local closedCFrame = doorPanel:GetAttribute("SecretClosedCFrame") or doorPanel:GetAttribute("BaseCFrame") or doorPanel.CFrame
	local hingeOffset = -doorPanel.Size.X / 2

	return closedCFrame
		* CFrame.new(hingeOffset, 0, 0)
		* CFrame.Angles(0, math.rad(-96), 0)
		* CFrame.new(-hingeOffset, 0, 0)
end

function InteractionService:_wireSecretRoomDoor(door)
	local prompt = getPrompt(door)
	local roomId = door:GetAttribute("RoomId") or "TVRoom"

	self.secretDoorState[door] = self.secretDoorState[door] or {
		Reacting = false,
	}
	self:_setSecretDoorState(door, self:_getSecretDoorWorldState(roomId))

	self:_connectPrompt(prompt, function(player)
		local state = self.secretDoorState[door]
		if not state or state.Reacting then
			return
		end

		if not self.discoveryService:IsRoomComplete(player, roomId) then
			self.systemMessageRemote:FireClient(player, "The Library outline is visible, but the room is not finished yet.")
			return
		end

		if not self.discoveryService:HasSecretKey(player, roomId) then
			self.systemMessageRemote:FireClient(player, "The Library is awaiting the Library Key. A secret discovery is probably hoarding it.")
			return
		end

		local destinationCFrame = door:GetAttribute("DestinationCFrame")
		if typeof(destinationCFrame) ~= "CFrame" then
			self.systemMessageRemote:FireClient(player, "The Library forgot where it is.")
			return
		end

		state.Reacting = true
		playSound(door, "rbxasset://sounds/button.wav", 0.45, 0.58)
		playSound(door, "rbxasset://sounds/electronicpingshort.wav", 0.38, 1.65)

		if door:IsA("BasePart") then
			local openTween = tweenPart(door, 0.34, {
				CFrame = getSecretDoorOpenCFrame(door),
				Color = Color3.fromRGB(122, 255, 177),
			}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			openTween.Completed:Wait()
		else
			task.wait(0.25)
		end

		teleportPlayer(player, destinationCFrame)
		self.systemMessageRemote:FireClient(player, "The Library opens. Very suspiciously.")

		task.delay(1.2, function()
			if door.Parent and door:IsA("BasePart") then
				tweenPart(door, 0.24, {
					CFrame = door:GetAttribute("SecretClosedCFrame") or door:GetAttribute("BaseCFrame") or door.CFrame,
					Color = door:GetAttribute("BaseColor") or Color3.fromRGB(76, 55, 132),
				}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			end
			state.Reacting = false
		end)
	end)
end

function InteractionService:_wireSecretRoomExit(exitDoor)
	local prompt = getPrompt(exitDoor)

	self:_connectPrompt(prompt, function(player)
		local destinationCFrame = exitDoor:GetAttribute("DestinationCFrame")
		if typeof(destinationCFrame) ~= "CFrame" then
			self.systemMessageRemote:FireClient(player, "The secret exit is having stage fright.")
			return
		end

		teleportPlayer(player, destinationCFrame)
		self.systemMessageRemote:FireClient(player, "Back to the TV room. Act natural.")
	end)
end

function InteractionService:_wireResetRoomButton(button)
	local prompt = getPrompt(button)

	self:_connectPrompt(prompt, function(player)
		playSound(button, "rbxasset://sounds/button.wav", 0.5, 0.75)

		if button:IsA("BasePart") then
			local baseCFrame = button:GetAttribute("BaseCFrame") or button.CFrame
			local downTween = tweenPart(button, 0.1, {
				CFrame = baseCFrame + Vector3.new(0, 0, 0.18),
				Color = Color3.fromRGB(255, 190, 67),
			}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			downTween.Completed:Wait()
			tweenPart(button, 0.16, {
				CFrame = baseCFrame,
				Color = button:GetAttribute("BaseColor") or Color3.fromRGB(255, 221, 84),
			}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end

		self:_clearAllTelevisions()
		for _, state in pairs(self.snackFanState) do
			state.SpinToken = nil
		end
		self:_stopSnackFlightForRoom(player)
		self.eventManager:ResetRoom(player)
		self:_afterRoomReset()
		for _, currentPlayer in ipairs(Players:GetPlayers()) do
			self:_checkExitUnlock(currentPlayer)
			self:_refreshSecretDoorsForPlayer(currentPlayer)
		end
	end)
end

function InteractionService:_afterRoomReset()
	for fridge, state in pairs(self.fridgeState) do
		if fridge and fridge.Parent then
			state.Opened = false
			state.IceSpinToken = nil
			state.Reacting = false
			self:_setFridgeOpenDetails(fridge, false)
		end
	end

	for fan, state in pairs(self.snackFanState) do
		if fan and fan.Parent then
			state.Level = 0
			state.SpinToken = nil
			state.Reacting = false
		end
	end

	for _, state in pairs(self.islandTreasureState) do
		state.Opened = false
		state.Reacting = false
	end

	for _, state in pairs(self.islandShovelState) do
		state.Reacting = false
	end

	for _, state in pairs(self.islandColaState) do
		state.Reacting = false
	end
end

function InteractionService:_wireAppliance(appliance)
	local prompt = getPrompt(appliance)
	local body = appliance:FindFirstChild("ApplianceBody", true)
	local door = appliance:FindFirstChild("ApplianceDoor", true)
	local textLabel = appliance:FindFirstChild("ApplianceText", true)

	self.applianceState[appliance] = self.applianceState[appliance] or {
		Reacting = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.applianceState[appliance]
		if not state or state.Reacting then
			return
		end

		state.Reacting = true
		if prompt then
			prompt.Enabled = false
		end

		self.discoveryService:Unlock(player, Constants.Discoveries.RanAppliance.Id)
		self.systemMessageRemote:FireClient(player, "The tiny appliance is reheating time.")

		for seconds = 3, 1, -1 do
			if textLabel and textLabel:IsA("TextLabel") then
				textLabel.Text = ("00:0%d"):format(seconds)
				textLabel.TextColor3 = seconds % 2 == 0 and Color3.fromRGB(255, 235, 119) or Color3.fromRGB(109, 255, 177)
			end

			if door and door:IsA("BasePart") then
				door.Color = seconds % 2 == 0 and Color3.fromRGB(58, 32, 42) or Color3.fromRGB(32, 45, 47)
			end

			task.wait(0.45)
		end

		if textLabel and textLabel:IsA("TextLabel") then
			textLabel.Text = "DING?"
			textLabel.TextColor3 = Color3.fromRGB(255, 94, 94)
		end

		playSound(door or body, "rbxasset://sounds/electronicpingshort.wav", 0.85, 1.45)

		if body and body:IsA("BasePart") then
			local pulseTween = tweenPart(body, 0.18, {
				Color = Color3.fromRGB(255, 214, 107),
			}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			pulseTween.Completed:Wait()
		end

		local spark = Instance.new("Part")
		spark.Name = "TinyApplianceSpark"
		spark.Anchored = true
		spark.CanCollide = false
		spark.Shape = Enum.PartType.Ball
		spark.Size = Vector3.new(0.8, 0.8, 0.8)
		spark.Color = Color3.fromRGB(109, 255, 177)
		spark.Material = Enum.Material.Neon
		spark.CFrame = (door and door.CFrame or appliance:GetPivot()) + Vector3.new(0, 1.5, -0.2)
		spark.Parent = workspace
		CollectionService:AddTag(spark, Constants.Tags.TemporaryObject)
		Debris:AddItem(spark, 2)

		task.wait(0.7)
		self.resetService.RestoreInstance(appliance)

		if prompt then
			prompt.Enabled = true
		end
		state.Reacting = false
	end)
end

function InteractionService:_wireCouch(couch)
	local prompt = getPrompt(couch)
	local sitTarget = couch:FindFirstChild("CouchSitTarget", true)

	self.couchState[couch] = self.couchState[couch] or {
		GetUpAttempts = 0,
		LabelIndex = 0,
		OccupantUserId = nil,
		RideToken = nil,
	}

	local state = self.couchState[couch]

	if sitTarget and sitTarget:IsA("Seat") and not state.OccupantConnection then
		state.OccupantConnection = sitTarget:GetPropertyChangedSignal("Occupant"):Connect(function()
			if sitTarget.Occupant ~= nil or self.couchRiding[couch] then
				return
			end

			self:_clearCouchPrompt(prompt, state)
		end)
	end

	self:_connectPrompt(prompt, function(player)
		local humanoid = getHumanoid(player)
		if not humanoid or not sitTarget or not sitTarget:IsA("Seat") or self.couchRiding[couch] then
			return
		end

		if sitTarget.Occupant == humanoid or state.OccupantUserId == player.UserId then
			self:_tryLeaveCouch(sitTarget, humanoid, player, prompt, state)
			return
		end

		if sitTarget.Occupant then
			self.systemMessageRemote:FireClient(player, "The couch is currently busy being someone else's problem.")
			return
		end

		self:_sitOnCouch(couch, sitTarget, humanoid, player, prompt, state)
	end)
end

function InteractionService:_sitOnCouch(couch, sitTarget, humanoid, player, prompt, state)
	state.GetUpAttempts = 0
	state.LabelIndex = 0
	state.OccupantUserId = player.UserId
	self:_setCouchPromptSitting(prompt, state)

	local rootPart = getRootPart(player)
	if rootPart then
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
		rootPart.CFrame = sitTarget.CFrame + Vector3.new(0, 1.8, 0)
	end

	sitTarget.CanTouch = true
	sitTarget:Sit(humanoid)

	task.delay(0.2, function()
		if sitTarget.Parent then
			sitTarget.CanTouch = false
		end
	end)

	task.delay(0.1, function()
		if not sitTarget.Parent or sitTarget.Occupant == humanoid then
			return
		end

		sitTarget:Sit(humanoid)
	end)

	self.systemMessageRemote:FireClient(player, "The couch seems comfortable. Too comfortable.")

	local rideToken = {}
	state.RideToken = rideToken

	task.delay(3, function()
		if state.RideToken ~= rideToken then
			return
		end

		if sitTarget.Parent and sitTarget.Occupant == humanoid and not self.couchRiding[couch] then
			self:_rideCouch(couch, sitTarget, player, prompt, state)
		end
	end)
end

function InteractionService:_tryLeaveCouch(sitTarget, humanoid, player, prompt, state)
	state.GetUpAttempts += 1
	self:_setCouchPromptSitting(prompt, state)

	if state.GetUpAttempts >= 3 then
		state.RideToken = nil
		state.OccupantUserId = nil
		humanoid.Sit = false
		self:_clearCouchPrompt(prompt, state)
		self.systemMessageRemote:FireClient(player, "The couch releases you, but makes it weird.")
		return
	end

	local message = COUCH_REFUSAL_MESSAGES[((state.GetUpAttempts - 1) % #COUCH_REFUSAL_MESSAGES) + 1]
	self.systemMessageRemote:FireClient(player, message)
end

function InteractionService:_setCouchPromptSitting(prompt, state)
	if not prompt then
		return
	end

	state.LabelIndex = (state.LabelIndex or 0) + 1
	prompt.ActionText = COUCH_GET_UP_LABELS[((state.LabelIndex - 1) % #COUCH_GET_UP_LABELS) + 1]
	prompt.ObjectText = "Suspicious Couch"
	prompt.Enabled = true
end

function InteractionService:_clearCouchPrompt(prompt, state)
	if state then
		state.GetUpAttempts = 0
		state.LabelIndex = 0
		state.OccupantUserId = nil
		state.RideToken = nil
	end

	if not prompt then
		return
	end

	prompt.ActionText = prompt:GetAttribute("BaseActionText") or "Sit"
	prompt.ObjectText = prompt:GetAttribute("BaseObjectText") or "Suspicious Couch"
	prompt.Enabled = prompt:GetAttribute("BaseEnabled") ~= false
end

function InteractionService:_rideCouch(couch, seat, player, prompt, state)
	self.couchRiding[couch] = true
	if prompt then
		prompt.ActionText = "Hold On"
		prompt.ObjectText = "Regret Couch"
		prompt.Enabled = false
	end

	local direction = couch:GetAttribute("RideDirection") or Vector3.new(1, 0, 0)
	if direction.Magnitude < 0.1 then
		direction = Vector3.new(1, 0, 0)
	end

	local startPivot = couch:GetPivot()
	local targetPivot = startPivot + direction.Unit * 11

	self.discoveryService:Unlock(player, Constants.Discoveries.RodeCouch.Id)
	self.systemMessageRemote:FireClient(player, "The couch has entered traffic.")

	tweenModel(couch, targetPivot, 1.5)
	task.wait(1)
	tweenModel(couch, startPivot, 1.25)

	local humanoid = seat.Occupant
	if humanoid then
		humanoid.Sit = false
	end

	self.resetService.RestoreInstance(couch)
	if seat and seat.Parent then
		seat.CanTouch = false
	end
	if prompt then
		prompt.Enabled = true
	end
	self:_clearCouchPrompt(prompt, state)
	self.couchRiding[couch] = nil
end

function InteractionService:_wireLamp(lamp)
	local prompt = getPrompt(lamp)
	local shade = lamp:FindFirstChild("LampShade", true)
	local light = lamp:FindFirstChild("LampLight", true)

	self.lampState[lamp] = self.lampState[lamp] or {
		ToggleCount = 0,
		Reacting = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.lampState[lamp]
		if not state or state.Reacting or not shade or not light then
			return
		end

		state.ToggleCount += 1
		self:_animateLampChain(lamp)
		playSound(shade, "rbxasset://sounds/button.wav", 0.35, 1.35)
		light.Enabled = not light.Enabled
		shade.Material = light.Enabled and Enum.Material.Neon or Enum.Material.SmoothPlastic
		shade.Color = light.Enabled and Color3.fromRGB(255, 245, 151) or Color3.fromRGB(255, 231, 125)

		if state.ToggleCount >= 5 then
			state.ToggleCount = 0
			self:_lampSecret(lamp, shade, light, player, state)
		end
	end)
end

function InteractionService:_animateLampChain(lamp)
	local parts = {}

	for _, descendant in ipairs(lamp:GetDescendants()) do
		if descendant:IsA("BasePart") and (descendant.Name == "LampPullHandle" or descendant.Name == "LampChainBead") then
			table.insert(parts, descendant)
		end
	end

	for _, part in ipairs(parts) do
		task.spawn(function()
			local baseCFrame = part:GetAttribute("BaseCFrame") or part.CFrame
			local downTween = tweenPart(part, 0.08, {
				CFrame = baseCFrame + Vector3.new(0, -0.36, 0),
			}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			downTween.Completed:Wait()

			if part.Parent then
				tweenPart(part, 0.16, {
					CFrame = baseCFrame,
				}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			end
		end)
	end
end

function InteractionService:_lampSecret(lamp, shade, light, player, state)
	state.Reacting = true
	self.discoveryService:Unlock(player, Constants.Discoveries.AnnoyedLamp.Id)
	self.systemMessageRemote:FireClient(player, "The lamp has opinions now.")

	local originalSize = shade.Size
	local originalCFrame = shade.CFrame
	local originalBrightness = light.Brightness
	local originalRange = light.Range
	local oldLighting = {
		Ambient = Lighting.Ambient,
		Brightness = Lighting.Brightness,
	}

	light.Enabled = true
	light.Brightness = 8
	light.Range = 35
	playSound(shade, "rbxasset://sounds/electronicpingshort.wav", 0.75, 0.72)
	tweenPart(shade, 0.35, {
		Size = originalSize * 1.6,
		CFrame = originalCFrame + Vector3.new(0, 0.35, 0),
	}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	for index = 1, 6 do
		Lighting.Brightness = index % 2 == 0 and 1.5 or 5
		Lighting.Ambient = index % 2 == 0 and Color3.fromRGB(180, 220, 255) or Color3.fromRGB(255, 170, 90)
		if index == 3 then
			playSound(shade, "rbxasset://sounds/snap.wav", 0.95, 0.88)
		end
		task.wait(0.16)
	end

	playSound(shade, "rbxasset://sounds/electronicpingshort.wav", 0.45, 0.45)
	self.systemMessageRemote:FireClient(player, "The lamp sizzles like it has learned a lesson.")
	task.wait(1)
	Lighting.Ambient = oldLighting.Ambient
	Lighting.Brightness = oldLighting.Brightness
	light.Brightness = originalBrightness
	light.Range = originalRange

	local restoreTween = tweenPart(shade, 0.35, {
		Size = originalSize,
		CFrame = originalCFrame,
	}, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	restoreTween.Completed:Wait()

	self.resetService.RestoreInstance(lamp)
	state.Reacting = false
end

function InteractionService:_wireSquishy(squishy)
	local prompt = getPrompt(squishy)

	self.squishyState[squishy] = self.squishyState[squishy] or {
		SqueezeCountByUserId = {},
		Reacting = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.squishyState[squishy]
		if not state or state.Reacting then
			return
		end

		state.Reacting = true
		if prompt then
			prompt.Enabled = false
		end

		state.SqueezeCountByUserId[player.UserId] = (state.SqueezeCountByUserId[player.UserId] or 0) + 1
		self:_squishOnce(squishy)

		if state.SqueezeCountByUserId[player.UserId] >= 10 then
			state.SqueezeCountByUserId[player.UserId] = 0
			self:_squishySecret(squishy, player)
		end

		if prompt then
			prompt.Enabled = true
		end
		state.Reacting = false
	end)
end

function InteractionService:_squishOnce(squishy)
	local originalSize = squishy:GetAttribute("BaseSize") or squishy.Size
	local originalCFrame = squishy:GetAttribute("BaseCFrame") or squishy.CFrame
	local squishedSize = Vector3.new(originalSize.X * 1.25, math.max(0.35, originalSize.Y * 0.35), originalSize.Z * 1.25)
	local yOffset = -(originalSize.Y - squishedSize.Y) / 2

	local downTween = tweenPart(squishy, 0.12, {
		Size = squishedSize,
		CFrame = originalCFrame + Vector3.new(0, yOffset, 0),
	}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	downTween.Completed:Wait()

	local upTween = tweenPart(squishy, 0.2, {
		Size = originalSize,
		CFrame = originalCFrame,
	}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	upTween.Completed:Wait()
end

function InteractionService:_squishySecret(squishy, player)
	self.discoveryService:Unlock(player, Constants.Discoveries.OverSquished.Id)
	self.systemMessageRemote:FireClient(player, "The squishy has achieved bigness.")

	local originalSize = squishy:GetAttribute("BaseSize") or squishy.Size
	local originalCFrame = squishy:GetAttribute("BaseCFrame") or squishy.CFrame
	local hugeSize = originalSize * 3.2
	local yOffset = (hugeSize.Y - originalSize.Y) / 2

	local growTween = tweenPart(squishy, 0.45, {
		Size = hugeSize,
		CFrame = originalCFrame + Vector3.new(0, yOffset, 0),
	}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	growTween.Completed:Wait()

	task.wait(3)
	self.resetService.RestoreInstance(squishy)
end

function InteractionService:_wireTelevision(tv)
	local prompt = getPrompt(tv)
	local screen = tv:FindFirstChild("TVScreen", true)
	local textLabel = tv:FindFirstChild("TVText", true)

	self.tvState[tv] = self.tvState[tv] or {
		PressCount = 0,
		Reacting = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.tvState[tv]
		if not state or state.Reacting or not screen or not textLabel then
			return
		end

		state.PressCount += 1
		self:_cycleTelevision(screen, textLabel, state.PressCount)

		if state.PressCount >= 4 then
			state.PressCount = 0
			self:_televisionSecret(tv, screen, textLabel, player, state)
		end
	end)
end

function InteractionService:_cycleTelevision(screen, textLabel, pressCount)
	local staticMessages = {
		"STATIC",
		"CHANNEL 0",
		"PLEASE STOP",
	}

	local channelIndex = ((pressCount - 1) % #staticMessages) + 1
	textLabel.Text = staticMessages[channelIndex]
	screen.Color = Color3.fromRGB(40 + pressCount * 20, 55, 80 + pressCount * 25)

	local tv = screen:FindFirstAncestorOfClass("Model")
	if not tv then
		return
	end

	self:_clearTelevisionSounds(tv)

	if channelIndex == 1 then
		self:_playTelevisionLoop(screen, "TVStaticSound", TV_SOUND_IDS.Static, 0.28, 7.5)
	elseif channelIndex == 2 then
		self:_playTelevisionLoop(screen, "TVTestTone", TV_SOUND_IDS.TestTone, 0.2, 0.38)
	else
		self:_startTelevisionWarning(tv, screen)
	end
end

function InteractionService:_televisionSecret(tv, screen, textLabel, player, state)
	state.Reacting = true
	self:_clearTelevisionSounds(tv)
	self.discoveryService:Unlock(player, Constants.Discoveries.AngeredTelevision.Id)
	self.systemMessageRemote:FireClient(player, "The television noticed you.")

	textLabel.Text = "STOP PRESSING BUTTONS."
	textLabel.TextColor3 = Color3.fromRGB(255, 60, 70)
	screen.Color = Color3.fromRGB(255, 255, 255)
	task.wait(0.15)
	screen.Color = Color3.fromRGB(40, 10, 18)
	self:_spawnTelevisionEye(tv, screen, player)
	self:_startTelevisionWarning(tv, screen)
	task.wait(30)

	self.resetService.RestoreInstance(tv)
	state.Reacting = false
end

function InteractionService:_clearTelevisionSounds(tv)
	local state = self.tvState[tv]
	if state then
		state.WarningToken = {}
	end

	for _, descendant in ipairs(tv:GetDescendants()) do
		if descendant:IsA("Sound") and descendant.Name:match("^TV") then
			descendant:Destroy()
		end
	end
end

function InteractionService:_playTelevisionLoop(parent, name, soundId, volume, playbackSpeed)
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = soundId
	sound.Volume = volume
	sound.PlaybackSpeed = playbackSpeed
	sound.Looped = true
	sound.RollOffMaxDistance = 55
	sound.Parent = parent
	CollectionService:AddTag(sound, Constants.Tags.TemporaryObject)
	sound:Play()
	return sound
end

function InteractionService:_clearAllTelevisions()
	for _, tv in ipairs(CollectionService:GetTagged(Constants.Tags.Television)) do
		self:_clearTelevisionSounds(tv)
		local state = self.tvState[tv]
		if state then
			state.Reacting = false
		end
	end
end

function InteractionService:_startTelevisionWarning(tv, screen)
	local state = self.tvState[tv]
	if not state then
		return
	end

	local token = {}
	state.WarningToken = token

	task.spawn(function()
		local warnings = {
			"TV advisory: stop pressing buttons.",
			"Your television strongly recommends doing literally anything else.",
			"Final-ish warning: the button is making the TV emotionally available.",
		}
		local index = 0

		while tv.Parent and state.WarningToken == token do
			index += 1
			local warning = warnings[((index - 1) % #warnings) + 1]
			self.systemMessageRemote:FireAllClients(warning)
			playSound(screen, TV_SOUND_IDS.Warning, 0.45, 0.7 + (index % 2) * 0.45)
			task.wait(1.35)
		end
	end)
end

function InteractionService:_spawnTelevisionEye(tv, screen, player)
	local existingEye = tv:FindFirstChild("WatchingEye")
	if existingEye then
		existingEye:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = "WatchingEye"
	model.Parent = tv
	CollectionService:AddTag(model, Constants.Tags.TemporaryObject)

	local eye = Instance.new("Part")
	eye.Name = "EyeWhite"
	eye.Anchored = true
	eye.CanCollide = false
	eye.Shape = Enum.PartType.Ball
	eye.Size = Vector3.new(2.6, 2.6, 0.9)
	eye.Color = Color3.fromRGB(255, 255, 245)
	eye.Material = Enum.Material.Neon
	eye.Parent = model
	CollectionService:AddTag(eye, Constants.Tags.TemporaryObject)

	local pupil = Instance.new("Part")
	pupil.Name = "EyePupil"
	pupil.Anchored = true
	pupil.CanCollide = false
	pupil.Shape = Enum.PartType.Ball
	pupil.Size = Vector3.new(0.7, 0.7, 0.18)
	pupil.Color = Color3.fromRGB(12, 14, 18)
	pupil.Material = Enum.Material.SmoothPlastic
	pupil.Parent = model
	CollectionService:AddTag(pupil, Constants.Tags.TemporaryObject)

	local origin = screen.Position + Vector3.new(0, 0, 0.45)
	local startedAt = os.clock()

	task.spawn(function()
		while model.Parent and os.clock() - startedAt < 30 do
			local rootPart = getRootPart(player)
			local targetPosition = rootPart and rootPart.Position or origin + Vector3.new(0, 0, 8)
			local direction = targetPosition - origin
			if direction.Magnitude < 0.1 then
				direction = Vector3.new(0, 0, 1)
			end

			direction = direction.Unit
			eye.CFrame = CFrame.new(origin, origin + direction)
			pupil.CFrame = CFrame.new(origin + direction * 0.5, origin + direction)
			task.wait(0.08)
		end

		if model.Parent then
			model:Destroy()
		end

		if tv.Parent then
			self:_clearTelevisionSounds(tv)
		end
	end)
end

function InteractionService:_persistResetBaseline(root)
	if not root then
		return
	end

	local descendants = root:GetDescendants()
	table.insert(descendants, root)

	for _, instance in ipairs(descendants) do
		self.resetService.MarkBaseline(instance)
	end
end

function InteractionService:_checkExitUnlock(player)
	if self.exitUnlocked or not player then
		return
	end

	if not self.discoveryService:CanEnterHall(player) then
		return
	end

	self.exitUnlocked = true

	for _, door in ipairs(CollectionService:GetTagged(Constants.Tags.ExitDoor)) do
		self:_unlockExitDoor(door)
	end

	self.systemMessageRemote:FireAllClients("The hallway is unlocked. The entrance has changed its mind early.")
end

function InteractionService:_wireExitDoor(door)
	if self.exitUnlocked then
		self:_unlockExitDoor(door)
	end

	local prompt = getPrompt(door)
	self:_connectPrompt(prompt, function(player)
		if not self.exitUnlocked then
			self:_checkExitUnlock(player)
		end

		if not self.exitUnlocked then
			self.systemMessageRemote:FireClient(player, self.discoveryService:GetHallUnlockRequirementText(player))
			return
		end

		teleportPlayer(player, door:GetAttribute("DestinationCFrame"))
		self.systemMessageRemote:FireClient(player, "The hallway smells like choices.")
	end)
end

function InteractionService:_unlockExitDoor(door)
	if not door or not door:IsA("BasePart") then
		return
	end

	door.CanCollide = false
	door.Transparency = 0.48
	door.Color = Color3.fromRGB(61, 217, 132)
	door.Material = Enum.Material.Neon

	local prompt = getPrompt(door)
	if prompt then
		prompt.ActionText = "Exit"
		prompt.ObjectText = "Hallway"
		prompt.Enabled = true
	end

	local textLabel = door:FindFirstChild("DoorText", true)
	if textLabel and textLabel:IsA("TextLabel") then
		textLabel.Text = "EXIT"
		textLabel.TextColor3 = Color3.fromRGB(18, 45, 26)
		textLabel.BackgroundColor3 = Color3.fromRGB(122, 255, 177)
	end

	self:_persistResetBaseline(door)
end

function InteractionService:_wireHallDoor(door)
	local prompt = getPrompt(door)

	self:_connectPrompt(prompt, function(player)
		local lockedMessage = door:GetAttribute("LockedMessage")
		if lockedMessage then
			self.systemMessageRemote:FireClient(player, lockedMessage)
			return
		end

		local roomId = door:GetAttribute("RoomId")
		if roomId and not self.discoveryService:IsRoomUnlocked(player, roomId) then
			self.systemMessageRemote:FireClient(player, self:_getRoomDoorRequirementText(player, roomId))
			return
		end

		local destinationCFrame = door:GetAttribute("DestinationCFrame")
		if typeof(destinationCFrame) ~= "CFrame" then
			self.systemMessageRemote:FireClient(player, "This door forgot where it goes.")
			return
		end

		teleportPlayer(player, destinationCFrame)
	end)
end

function InteractionService:_getRoomDoorRequirementText(player, roomId)
	local requiredRoomId, requiredCount = Constants.GetRoomUnlockRequirement(roomId)
	local targetRoom = Constants.GetRoom(roomId)
	local requiredRoom = requiredRoomId and Constants.GetRoom(requiredRoomId)

	if not targetRoom or not requiredRoom or not requiredCount then
		return "That room is not ready yet."
	end

	local currentCount = self.discoveryService:GetRoomDiscoveryCount(player, requiredRoomId)
	return ("The %s door wants %d %s discoveries first. You have %d."):format(
		targetRoom.Name,
		requiredCount,
		requiredRoom.Name,
		currentCount
	)
end

function InteractionService:_getPlayersInRoom(roomId)
	local playersInRoom = {}
	local room = Constants.GetRoom(roomId)
	if not room then
		return playersInRoom
	end

	for _, player in ipairs(Players:GetPlayers()) do
		local rootPart = getRootPart(player)
		if rootPart and positionInZone(rootPart.Position, room.Zone) then
			table.insert(playersInRoom, player)
		end
	end

	return playersInRoom
end

function InteractionService:_nextSnackButtonActivity(state)
	if not state.ActivityBag or #state.ActivityBag == 0 then
		state.ActivityBag = table.clone(SNACK_BUTTON_ACTIVITIES)
		for index = #state.ActivityBag, 2, -1 do
			local swapIndex = self.snackButtonRandom:NextInteger(1, index)
			state.ActivityBag[index], state.ActivityBag[swapIndex] = state.ActivityBag[swapIndex], state.ActivityBag[index]
		end
	end

	return table.remove(state.ActivityBag)
end

function InteractionService:_triggerSnackFlight(triggeringPlayer)
	local targets = self:_getPlayersInRoom("SnackLab")
	if #targets == 0 and triggeringPlayer then
		targets = { triggeringPlayer }
	end

	for _, player in ipairs(targets) do
		local rootPart = getRootPart(player)
		if rootPart then
			rootPart.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity + Vector3.new(0, SNACK_FLIGHT_INITIAL_BOOST, 0)
		end

		self.snackEffectRemote:FireClient(player, {
			Action = "Flight",
			Duration = SNACK_FLIGHT_DURATION,
			CeilingY = SNACK_FLIGHT_CEILING_Y,
		})
	end

	self.systemMessageRemote:FireAllClients("Snack Lab flight mode is live. Space goes up, Shift or Ctrl comes down.")
end

function InteractionService:_applySlowMotion(player, duration)
	local humanoid = getHumanoid(player)
	if not humanoid then
		return
	end

	if humanoid:GetAttribute("SnackBaseWalkSpeed") == nil then
		humanoid:SetAttribute("SnackBaseWalkSpeed", humanoid.WalkSpeed)
		humanoid:SetAttribute("SnackBaseJumpPower", humanoid.JumpPower)
		humanoid:SetAttribute("SnackBaseJumpHeight", humanoid.JumpHeight)
	end

	local token = {}
	self.slowMotionTokensByHumanoid[humanoid] = token
	humanoid.WalkSpeed = math.max(5, (humanoid:GetAttribute("SnackBaseWalkSpeed") or 16) * 0.38)

	if humanoid.UseJumpPower then
		humanoid.JumpPower = math.max(18, (humanoid:GetAttribute("SnackBaseJumpPower") or 50) * 0.45)
	else
		humanoid.JumpHeight = math.max(2.2, (humanoid:GetAttribute("SnackBaseJumpHeight") or 7.2) * 0.45)
	end

	task.delay(duration, function()
		if self.slowMotionTokensByHumanoid[humanoid] ~= token or not humanoid.Parent then
			return
		end

		humanoid.WalkSpeed = humanoid:GetAttribute("SnackBaseWalkSpeed") or 16
		if humanoid.UseJumpPower then
			humanoid.JumpPower = humanoid:GetAttribute("SnackBaseJumpPower") or 50
		else
			humanoid.JumpHeight = humanoid:GetAttribute("SnackBaseJumpHeight") or 7.2
		end
		self.slowMotionTokensByHumanoid[humanoid] = nil
	end)
end

function InteractionService:_triggerSnackSlowMotion(triggeringPlayer)
	local targets = self:_getPlayersInRoom("SnackLab")
	if #targets == 0 and triggeringPlayer then
		targets = { triggeringPlayer }
	end

	for _, player in ipairs(targets) do
		self:_applySlowMotion(player, SNACK_SLOW_MOTION_DURATION)
	end

	self.systemMessageRemote:FireAllClients("Snack Lab slow motion is on. The room is chewing carefully.")
end

function InteractionService:_triggerSnackRackRattle()
	local packs = CollectionService:GetTagged(Constants.Tags.SnackPack)
	for index, pack in ipairs(packs) do
		if pack:IsA("BasePart") then
			local baseCFrame = pack:GetAttribute("BaseCFrame") or pack.CFrame
			task.delay((index % 5) * 0.035, function()
				if not pack.Parent then
					return
				end

				playSound(pack, "rbxasset://sounds/button.wav", 0.22, 1.4 + (index % 4) * 0.18)
				local shakeTween = tweenPart(pack, 0.08, {
					CFrame = baseCFrame * CFrame.Angles(0, 0, math.rad((index % 2 == 0 and 1 or -1) * 8)),
				}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				shakeTween.Completed:Wait()

				if pack.Parent then
					tweenPart(pack, 0.12, {
						CFrame = baseCFrame,
					}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				end
			end)
		end
	end

	self.systemMessageRemote:FireAllClients("The snack shelf tries to applaud with packaging.")
end

function InteractionService:_triggerSnackButtonActivity(player, button, state)
	local activity = self:_nextSnackButtonActivity(state)

	if activity == "flight" then
		self:_triggerSnackFlight(player)
	elseif activity == "slow_motion" then
		self:_triggerSnackSlowMotion(player)
	elseif activity == "rack_rattle" then
		self:_triggerSnackRackRattle()
	else
		self:_cycleRoomMood("SnackLab")
	end

	if button and button:IsA("BasePart") then
		playSound(button, "rbxasset://sounds/electronicpingshort.wav", 0.45, 1.1)
	end
end

function InteractionService:_stopSnackFlightForRoom(triggeringPlayer)
	local targets = self:_getPlayersInRoom("SnackLab")
	if #targets == 0 and triggeringPlayer then
		targets = { triggeringPlayer }
	end

	for _, player in ipairs(targets) do
		self.snackEffectRemote:FireClient(player, {
			Action = "StopFlight",
		})
	end
end

function InteractionService:_startSnackFanSpin(fan, state)
	local hub = fan:FindFirstChild("FanHub", true)
	if not hub or not hub:IsA("BasePart") then
		return
	end

	local bladeRecords = {}
	local centerCFrame = hub:GetAttribute("BaseCFrame") or hub.CFrame
	for _, descendant in ipairs(fan:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name == "FanBlade" then
			table.insert(bladeRecords, {
				Part = descendant,
				Offset = centerCFrame:ToObjectSpace(descendant:GetAttribute("BaseCFrame") or descendant.CFrame),
			})
		end
	end

	if #bladeRecords == 0 then
		return
	end

	local token = {}
	state.SpinToken = token

	task.spawn(function()
		local angle = 0
		while fan.Parent and state.SpinToken == token do
			local speed = state.Level >= 2 and 52 or 16
			angle += math.rad(speed)

			for _, record in ipairs(bladeRecords) do
				if record.Part.Parent then
					record.Part.CFrame = centerCFrame * CFrame.Angles(0, angle, 0) * record.Offset
				end
			end

			task.wait(state.Level >= 2 and 0.03 or 0.08)
		end
	end)
end

function InteractionService:_getSnackWindDirection(position)
	local snackRoom = Constants.GetRoom("SnackLab")
	local zone = snackRoom and snackRoom.Zone
	local center = zone and (zone.Min + zone.Max) * 0.5 or Vector3.new(48, 0, 44)
	local direction = Vector3.new(position.X - center.X, 0, position.Z - center.Z)

	if direction.Magnitude < 1 then
		return Vector3.new(1, 0, 0)
	end

	return direction.Unit
end

function InteractionService:_pushSnackPlayersToWalls(level)
	for _, player in ipairs(self:_getPlayersInRoom("SnackLab")) do
		local rootPart = getRootPart(player)
		if rootPart then
			local direction = self:_getSnackWindDirection(rootPart.Position)
			rootPart.AssemblyLinearVelocity = direction * (level >= 3 and 128 or 96) + Vector3.new(0, 12, 0)
			rootPart.AssemblyAngularVelocity += Vector3.new(0, 3, 0)
		end
	end
end

function InteractionService:_pushLooseFruitToWalls(level)
	local pushedParts = {}

	for _, looseFruit in ipairs(CollectionService:GetTagged(Constants.Tags.LooseFruit)) do
		local part = nil
		if looseFruit:IsA("BasePart") then
			part = looseFruit
		elseif looseFruit:IsA("Model") then
			part = looseFruit.PrimaryPart or looseFruit:FindFirstChildWhichIsA("BasePart", true)
		end

		if part and part.Parent and not pushedParts[part] then
			pushedParts[part] = true
			part.Anchored = false
			part.CanCollide = true
			local direction = self:_getSnackWindDirection(part.Position)
			part.AssemblyLinearVelocity = direction * (level >= 3 and 120 or 86) + Vector3.new(0, 18, 0)
			part.AssemblyAngularVelocity = Vector3.new(12 + level * 4, -18, 9)
		end
	end
end

function InteractionService:_triggerSnackSuperWind(button, level)
	playSound(button, "rbxasset://sounds/electronicpingshort.wav", 0.62, level >= 3 and 1.8 or 1.35)
	self.systemMessageRemote:FireAllClients("The Gravity Apology Fan has escalated to snack weather.")

	for gust = 1, SNACK_SUPER_WIND_GUSTS do
		task.delay((gust - 1) * 0.36, function()
			self:_pushSnackPlayersToWalls(level)
			self:_pushLooseFruitToWalls(level)
		end)
	end
end

function InteractionService:_wireSnackCeilingFan(button)
	local prompt = getPrompt(button)
	local fan = button:FindFirstAncestor("SnackCeilingFan") or button

	self.snackFanState[fan] = self.snackFanState[fan] or {
		Level = 0,
		Reacting = false,
		SpinToken = nil,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.snackFanState[fan]
		if not state or state.Reacting then
			return
		end

		state.Reacting = true
		state.Level = math.min((state.Level or 0) + 1, 3)
		self:_stopSnackFlightForRoom(player)
		self:_startSnackFanSpin(fan, state)

		if button:IsA("BasePart") then
			local baseCFrame = button:GetAttribute("BaseCFrame") or button.CFrame
			tweenPart(button, 0.08, {
				CFrame = baseCFrame + Vector3.new(0, -0.16, 0),
				Color = Color3.fromRGB(255, 236, 104),
			})
			task.delay(0.12, function()
				if button.Parent then
					tweenPart(button, 0.16, {
						CFrame = baseCFrame,
						Color = button:GetAttribute("BaseColor") or Color3.fromRGB(93, 217, 255),
					}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				end
			end)
		end

		if state.Level == 1 then
			prompt.ActionText = "Gust"
			playSound(button, "rbxasset://sounds/button.wav", 0.5, 0.95)
			self.systemMessageRemote:FireClient(player, "Flight canceled. The ceiling fan is now quietly making decisions.")
		else
			prompt.ActionText = "More Wind"
			self:_triggerSnackSuperWind(button, state.Level)
		end

		task.wait(0.25)
		state.Reacting = false
	end)
end

function InteractionService:_wireSnackButton(button)
	local prompt = getPrompt(button)

	self.snackButtonState[button] = self.snackButtonState[button] or {
		Reacting = false,
		ActivityBag = {},
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.snackButtonState[button]
		if not state or state.Reacting then
			return
		end

		state.Reacting = true
		self.discoveryService:Unlock(player, Constants.Discoveries.PressedSnackButton.Id)
		self:_triggerSnackButtonActivity(player, button, state)

		local originalColor = button.Color
		local baseCFrame = button:GetAttribute("BaseCFrame") or button.CFrame
		local downTween = tweenPart(button, 0.12, {
			Color = Color3.fromRGB(255, 90, 80),
			CFrame = baseCFrame + Vector3.new(0, -0.22, 0),
		})
		downTween.Completed:Wait()

		task.wait(0.35)
		local upTween = tweenPart(button, 0.18, {
			Color = originalColor,
			CFrame = baseCFrame,
		})
		upTween.Completed:Wait()

		state.Reacting = false
	end)
end

function InteractionService:_setFridgeOpenDetails(fridge, opened)
	local iceCube = fridge:FindFirstChild("ColdIdeaIceCube", true)
	local pizzaModel = fridge:FindFirstChild("FridgePizza", true)
	local colaModel = fridge:FindFirstChild("FridgeBloxyCola", true)
	local pizza = fridge:FindFirstChild("PizzaSlice", true)
	local cola = fridge:FindFirstChild("BloxyColaCan", true)
	local secretButton = fridge:FindFirstChild("SecretFridgeButton", true)

	setFridgeContentVisible(iceCube, opened)
	setFridgeContentVisible(pizzaModel, opened)
	setFridgeContentVisible(colaModel, opened)
	setPromptEnabled(pizza, opened)
	setPromptEnabled(cola, opened)

	if secretButton and secretButton:IsA("BasePart") then
		secretButton.Transparency = opened and 0 or 1
		secretButton.CanCollide = opened
		setPromptEnabled(secretButton, opened)
		setTextLabelText(secretButton, "SecretFridgeButtonText", opened and "SECRET\nFRIDGE\nBUTTON" or "")
		setSurfaceGuiEnabled(secretButton, "SecretFridgeButtonText", opened)
	end
end

function InteractionService:_wireSnackFridge(fridgeTarget)
	local fridge = fridgeTarget
	if fridgeTarget:IsA("BasePart") then
		fridge = fridgeTarget:FindFirstAncestor("Fridge") or fridgeTarget.Parent or fridgeTarget
	end

	local door = if fridgeTarget:IsA("BasePart") and fridgeTarget.Name == "FridgeDoor"
		then fridgeTarget
		else fridge:FindFirstChild("FridgeDoor", true)
	local prompt = door and getPrompt(door) or getPrompt(fridgeTarget)
	local iceCube = fridge:FindFirstChild("ColdIdeaIceCube", true)

	self.fridgeState[fridge] = self.fridgeState[fridge] or {
		Reacting = false,
		Opened = false,
		IceSpinToken = nil,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.fridgeState[fridge]
		if not state or state.Reacting or not door then
			return
		end

		state.Reacting = true
		state.Opened = not state.Opened
		self.discoveryService:Unlock(player, Constants.Discoveries.OpenedFridge.Id)

		if state.Opened then
			self.systemMessageRemote:FireClient(player, "The fridge contains one cold idea.")
			door.CanCollide = false
			tweenPart(door, 0.35, {
				CFrame = getFridgeDoorOpenCFrame(door),
				Color = Color3.fromRGB(172, 242, 255),
			}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			prompt.ActionText = "Close"
			self:_setFridgeOpenDetails(fridge, true)

			if iceCube and iceCube:IsA("BasePart") then
				local token = {}
				state.IceSpinToken = token
				local baseCFrame = iceCube:GetAttribute("BaseCFrame") or iceCube.CFrame

				task.spawn(function()
					for index = 1, 18 do
						if state.IceSpinToken ~= token or not iceCube.Parent then
							return
						end

						local floatOffset = Vector3.new(0, math.sin(index * 0.8) * 0.22, 0)
						local spinTween = tweenPart(iceCube, 0.22, {
							CFrame = (baseCFrame + floatOffset) * CFrame.Angles(math.rad(index * 22), math.rad(index * 35), math.rad(index * 18)),
							Transparency = 0.12,
						}, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
						spinTween.Completed:Wait()
					end
				end)
			end
		else
			state.IceSpinToken = nil
			self.resetService.RestoreInstance(fridge)
			self:_setFridgeOpenDetails(fridge, false)
			door.CanCollide = door:GetAttribute("BaseCanCollide") ~= false
			prompt.ActionText = "Open"
		end

		task.wait(0.4)
		state.Reacting = false
	end)
end

function InteractionService:_playBloxyColaSound(parent)
	playSound(parent, "rbxasset://sounds/button.wav", 0.55, 1.25)
	task.delay(0.12, function()
		playSound(parent, "rbxasset://sounds/electronicpingshort.wav", 0.55, 1.9)
	end)
	task.delay(0.3, function()
		playSound(parent, "rbxasset://sounds/snap.wav", 0.35, 1.45)
	end)
end

function InteractionService:_wireFridgePizza(pizza)
	local prompt = getPrompt(pizza)

	self:_connectPrompt(prompt, function(player)
		self.discoveryService:Unlock(player, Constants.Discoveries.FridgePizza.Id)
		playSound(pizza, "rbxasset://sounds/snap.wav", 0.45, 0.62)
		self.systemMessageRemote:FireClient(player, "The cold pizza has been waiting with professional patience.")
	end)
end

function InteractionService:_wireFridgeBloxyCola(cola)
	local prompt = getPrompt(cola)

	self:_connectPrompt(prompt, function(player)
		self.discoveryService:Unlock(player, Constants.Discoveries.FridgeBloxyCola.Id)
		self:_playBloxyColaSound(cola)
		self.systemMessageRemote:FireClient(player, "The fridge Bloxy Cola opens with suspicious confidence.")
	end)
end

function InteractionService:_wireSecretFridgeButton(button)
	local prompt = getPrompt(button)

	self.secretFridgeButtonState[button] = self.secretFridgeButtonState[button] or {
		Reacting = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.secretFridgeButtonState[button]
		if not state or state.Reacting then
			return
		end

		state.Reacting = true
		self.discoveryService:Unlock(player, Constants.Discoveries.SecretFridgeButton.Id)
		playSound(button, "rbxasset://sounds/button.wav", 0.55, 0.75)
		playSound(button, "rbxasset://sounds/electronicpingshort.wav", 0.45, 1.6)

		if button:IsA("BasePart") then
			local baseColor = button:GetAttribute("BaseColor") or button.Color
			local pulseTween = tweenPart(button, 0.12, {
				Color = Color3.fromRGB(255, 241, 137),
			}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			pulseTween.Completed:Wait()
			tweenPart(button, 0.18, {
				Color = baseColor,
			}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		end

		self.systemMessageRemote:FireClient(player, "The back of the fridge door says TOO LATE, but now it has committed to being a button.")
		task.wait(0.25)
		state.Reacting = false
	end)
end

function InteractionService:_wireSnackToaster(toaster)
	local prompt = getPrompt(toaster)
	local slot = toaster:FindFirstChild("ToasterSlot", true)

	self.toasterState[toaster] = self.toasterState[toaster] or {
		Reacting = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.toasterState[toaster]
		if not state or state.Reacting then
			return
		end

		state.Reacting = true
		self.discoveryService:Unlock(player, Constants.Discoveries.SuspiciousToast.Id)
		self.systemMessageRemote:FireClient(player, "That toast is achieving escape velocity.")

		local toastModel = Instance.new("Model")
		toastModel.Name = "SuspiciousToast"
		toastModel.Parent = workspace
		CollectionService:AddTag(toastModel, Constants.Tags.TemporaryObject)

		local toast = Instance.new("Part")
		toast.Name = "ToastSlice"
		toast.Anchored = false
		toast.Size = Vector3.new(2.2, 1.55, 0.26)
		toast.Color = Color3.fromRGB(241, 190, 102)
		toast.Material = Enum.Material.SmoothPlastic
		toast.CFrame = slot and slot.CFrame + Vector3.new(0, 1.45, 0) or toaster:GetPivot() + Vector3.new(0, 5, 0)
		toast.Parent = toastModel
		toastModel.PrimaryPart = toast

		local crustData = {
			{ Name = "TopCrust", Size = Vector3.new(2.25, 0.24, 0.3), Offset = Vector3.new(0, 0.68, 0) },
			{ Name = "LeftCrust", Size = Vector3.new(0.22, 1.42, 0.3), Offset = Vector3.new(-1.05, 0, 0) },
			{ Name = "RightCrust", Size = Vector3.new(0.22, 1.42, 0.3), Offset = Vector3.new(1.05, 0, 0) },
		}

		for _, data in ipairs(crustData) do
			local crust = Instance.new("Part")
			crust.Name = data.Name
			crust.Anchored = false
			crust.Size = data.Size
			crust.Color = Color3.fromRGB(153, 92, 45)
			crust.Material = Enum.Material.SmoothPlastic
			crust.CFrame = toast.CFrame * CFrame.new(data.Offset.X, data.Offset.Y, data.Offset.Z)
			crust.Parent = toastModel

			local weld = Instance.new("WeldConstraint")
			weld.Part0 = toast
			weld.Part1 = crust
			weld.Parent = crust
		end

		CollectionService:AddTag(toast, Constants.Tags.TemporaryObject)
		toast.AssemblyLinearVelocity = Vector3.new(0, 72, 0)
		toast.AssemblyAngularVelocity = Vector3.new(8, 2, 12)
		Debris:AddItem(toastModel, 6)

		task.wait(0.45)
		state.Reacting = false
	end)
end

function InteractionService:_wireSnackSink(sink)
	local prompt = getPrompt(sink)
	local faucet = sink:FindFirstChild("FaucetSpout", true) or sink:FindFirstChild("FaucetPost", true)
	local launchPart = sink:FindFirstChild("SinkWaterRest", true) or sink:FindFirstChild("SinkBasinDark", true)

	self.sinkState[sink] = self.sinkState[sink] or {
		CountByUserId = {},
		Reacting = false,
		GeyserActiveUntil = 0,
		LaunchDebounceByCharacter = {},
	}

	local state = self.sinkState[sink]
	if launchPart and launchPart:IsA("BasePart") and not state.TouchConnection then
		state.TouchConnection = launchPart.Touched:Connect(function(hit)
			if os.clock() > (state.GeyserActiveUntil or 0) then
				return
			end

			local character = hit:FindFirstAncestorOfClass("Model")
			if not character or state.LaunchDebounceByCharacter[character] then
				return
			end

			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			local player = Players:GetPlayerFromCharacter(character)
			if not humanoid or humanoid.Health <= 0 or not rootPart or not player then
				return
			end

			state.LaunchDebounceByCharacter[character] = true
			rootPart.AssemblyLinearVelocity = Vector3.new(0, 92, 0) + rootPart.CFrame.LookVector * 16
			playSound(launchPart, "rbxasset://sounds/electronicpingshort.wav", 0.55, 1.35)
			self.systemMessageRemote:FireClient(player, "The sink launches you because geyser mode has no workplace safety plan.")

			task.delay(1.2, function()
				state.LaunchDebounceByCharacter[character] = nil
			end)
		end)
	end

	self:_connectPrompt(prompt, function(player)
		if not state or state.Reacting then
			return
		end

		state.CountByUserId[player.UserId] = (state.CountByUserId[player.UserId] or 0) + 1

		if state.CountByUserId[player.UserId] < 3 then
			self.systemMessageRemote:FireClient(player, "The sink gurgles politely.")
			return
		end

		state.CountByUserId[player.UserId] = 0
		state.Reacting = true
		state.GeyserActiveUntil = os.clock() + 6.5
		self.discoveryService:Unlock(player, Constants.Discoveries.AngrySink.Id)
		self.systemMessageRemote:FireClient(player, "The sink has entered geyser mode.")

		for index = 1, 5 do
			local water = Instance.new("Part")
			water.Name = "SnackSinkWater"
			water.Anchored = true
			water.CanCollide = false
			water.Size = Vector3.new(0.55 + index * 0.18, 3 + index * 0.65, 0.55 + index * 0.18)
			water.Color = Color3.fromRGB(75, 190, 255)
			water.Material = Enum.Material.Neon
			water.Transparency = 0.18
			water.CFrame = (faucet and faucet.CFrame or sink:GetPivot()) + Vector3.new(0, 1.2 + index * 0.5, 0)
			water.Parent = workspace
			CollectionService:AddTag(water, Constants.Tags.TemporaryObject)
			Debris:AddItem(water, 6.5)
			task.wait(0.12)
		end

		task.wait(0.6)
		state.Reacting = false
	end)
end

function InteractionService:_wireSnackMixer(mixer)
	local prompt = getPrompt(mixer)
	local bowl = mixer:FindFirstChild("MixerBowl", true)
	local beaterLeft = mixer:FindFirstChild("BeaterLeft", true)
	local beaterRight = mixer:FindFirstChild("BeaterRight", true)

	local function collectBladeRecords(rootPart, side)
		if not rootPart or not rootPart:IsA("BasePart") then
			return {}
		end

		local rootBaseCFrame = rootPart:GetAttribute("BaseCFrame") or rootPart.CFrame
		local records = {}

		for _, descendant in ipairs(mixer:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant:GetAttribute("MixerBladeSide") == side then
				table.insert(records, {
					Part = descendant,
					Offset = rootBaseCFrame:ToObjectSpace(descendant:GetAttribute("BaseCFrame") or descendant.CFrame),
				})
			end
		end

		return records
	end

	local leftBladeRecords = collectBladeRecords(beaterLeft, "Left")
	local rightBladeRecords = collectBladeRecords(beaterRight, "Right")

	local function rotateBladeRecords(rootPart, records, angle)
		if not rootPart or not rootPart:IsA("BasePart") then
			return
		end

		local rootBaseCFrame = rootPart:GetAttribute("BaseCFrame") or rootPart.CFrame
		local rotationCFrame = rootBaseCFrame * CFrame.Angles(0, angle, 0)

		for _, record in ipairs(records) do
			if record.Part.Parent then
				record.Part.CFrame = rotationCFrame * record.Offset
			end
		end
	end

	self.mixerState[mixer] = self.mixerState[mixer] or {
		Reacting = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.mixerState[mixer]
		if not state or state.Reacting or not bowl then
			return
		end

		state.Reacting = true
		self.discoveryService:Unlock(player, Constants.Discoveries.MixedCloud.Id)
		self.systemMessageRemote:FireClient(player, "The mixer invented weather.")

		local originalColor = bowl.Color
		bowl.Material = Enum.Material.Neon
		bowl.Color = Color3.fromRGB(190, 255, 235)

		for index = 1, 7 do
			rotateBladeRecords(beaterLeft, leftBladeRecords, math.rad(index * 65))
			rotateBladeRecords(beaterRight, rightBladeRecords, math.rad(-index * 65))

			local cloud = Instance.new("Part")
			cloud.Name = "MixerCloud"
			cloud.Anchored = true
			cloud.CanCollide = false
			cloud.Shape = Enum.PartType.Ball
			cloud.Size = Vector3.new(1.5, 1.5, 1.5) * (0.75 + index * 0.1)
			cloud.Color = Color3.fromRGB(238, 245, 255)
			cloud.Material = Enum.Material.Neon
			cloud.Transparency = 0.18
			cloud.CFrame = bowl.CFrame + Vector3.new(math.sin(index) * 1.8, 1.5 + index * 0.45, math.cos(index) * 1.8)
			cloud.Parent = workspace
			CollectionService:AddTag(cloud, Constants.Tags.TemporaryObject)
			Debris:AddItem(cloud, 3)
			task.wait(0.12)
		end

		task.wait(1)
		self.resetService.RestoreInstance(mixer)
		bowl.Material = Enum.Material.Glass
		bowl.Color = originalColor
		state.Reacting = false
	end)
end

function InteractionService:_wireSnackRack(rack)
	local prompt = getPrompt(rack)

	self.snackRackState[rack] = self.snackRackState[rack] or {
		Reacting = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.snackRackState[rack]
		if not state or state.Reacting then
			return
		end

		state.Reacting = true
		self.discoveryService:Unlock(player, Constants.Discoveries.SnackRack.Id)
		self.systemMessageRemote:FireClient(player, "The snack rack audited your snack intentions.")

		local packs = {}
		for _, descendant in ipairs(rack:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant:GetAttribute("IsSnackPack") then
				table.insert(packs, descendant)
			end
		end

		for index, pack in ipairs(packs) do
			local baseCFrame = pack:GetAttribute("BaseCFrame") or pack.CFrame
			local offset = Vector3.new(0, 0.15 + (index % 3) * 0.08, 0.22)
			tweenPart(pack, 0.12, {
				CFrame = baseCFrame + offset,
				Color = Color3.fromRGB(255, 255, 255),
			}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

			task.delay(0.2, function()
				if pack.Parent then
					self.resetService.RestoreInstance(pack)
				end
			end)
		end

		task.wait(0.6)
		state.Reacting = false
	end)
end

function InteractionService:_getSnackPackCount()
	local count = 0
	for _, pack in ipairs(CollectionService:GetTagged(Constants.Tags.SnackPack)) do
		if pack:IsA("BasePart") then
			count += 1
		end
	end

	return count
end

function InteractionService:_playSnackPackSound(pack, snackName)
	local profile = SNACK_SOUND_PROFILES[snackName] or SNACK_SOUND_PROFILES.MYSTERY
	local baseColor = pack:GetAttribute("BaseColor") or pack.Color

	for _, soundData in ipairs(profile.Sounds) do
		task.delay(soundData.Delay or 0, function()
			if pack.Parent then
				playSound(pack, soundData.Id, soundData.Volume, soundData.Speed)
			end
		end)
	end

	local baseCFrame = pack:GetAttribute("BaseCFrame") or pack.CFrame
	local flashTween = tweenPart(pack, 0.1, {
		CFrame = baseCFrame + pack.CFrame.LookVector * 0.28,
		Color = profile.Color or Color3.fromRGB(255, 255, 255),
	}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	flashTween.Completed:Wait()

	if pack.Parent then
		tweenPart(pack, 0.18, {
			CFrame = baseCFrame,
			Color = baseColor,
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end

	return profile.Message
end

function InteractionService:_wireSnackPack(pack)
	local prompt = getPrompt(pack)

	self:_connectPrompt(prompt, function(player)
		if not pack:IsA("BasePart") then
			return
		end

		local snackName = pack:GetAttribute("SnackName") or pack.Name
		local snackId = pack:GetAttribute("SnackId") or pack.Name
		local message = self:_playSnackPackSound(pack, snackName)

		local state = self.snackPackStateByUserId[player.UserId]
		if not state then
			state = {
				ClickedBySnackId = {},
			}
			self.snackPackStateByUserId[player.UserId] = state
		end

		local wasNew = state.ClickedBySnackId[snackId] ~= true
		state.ClickedBySnackId[snackId] = true

		if wasNew then
			self.discoveryService:Unlock(player, Constants.Discoveries.HeardSnackSound.Id)

			local clickedCount = countDictionary(state.ClickedBySnackId)
			local totalCount = self:_getSnackPackCount()
			if totalCount > 0 and clickedCount >= totalCount then
				self.discoveryService:Unlock(player, Constants.Discoveries.AllSnackSounds.Id)
				self.systemMessageRemote:FireClient(player, "Every snack has now made its case.")
				return
			end
		end

		self.systemMessageRemote:FireClient(player, message)
	end)
end

function InteractionService:_wireFruitBowl(fruitBowl)
	local prompt = getPrompt(fruitBowl)
	local bowl = fruitBowl:FindFirstChild("Bowl", true)

	self.fruitBowlState[fruitBowl] = self.fruitBowlState[fruitBowl] or {
		Reacting = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.fruitBowlState[fruitBowl]
		if not state or state.Reacting then
			return
		end

		state.Reacting = true
		self.discoveryService:Unlock(player, Constants.Discoveries.LivingFruit.Id)
		self.systemMessageRemote:FireClient(player, "The fruit bowl has become aggressively generous.")

		local fruitTemplates = {}
		for _, child in ipairs(fruitBowl:GetChildren()) do
			if child:IsA("Model") and child:GetAttribute("IsFruitModel") then
				local template = child:Clone()
				template.Parent = nil
				table.insert(fruitTemplates, template)
			end
		end

		if bowl and bowl:IsA("BasePart") then
			playSound(bowl, "rbxasset://sounds/snap.wav", 0.6, 1.25)
			local baseCFrame = bowl:GetAttribute("BaseCFrame") or bowl.CFrame
			tweenPart(bowl, 0.18, {
				CFrame = baseCFrame * CFrame.Angles(math.rad(24), 0, math.rad(-30)) + Vector3.new(0, 0.25, 0),
				Color = Color3.fromRGB(255, 196, 73),
			}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			task.delay(1.2, function()
				if bowl.Parent then
					self.resetService.RestoreInstance(bowl)
				end
			end)
		end

		local random = Random.new()
		local originCFrame = bowl and bowl:IsA("BasePart") and bowl.CFrame or fruitBowl:GetPivot()
		local snackRoom = Constants.GetRoom("SnackLab")
		local zone = snackRoom and snackRoom.Zone

		for wave = 1, 6 do
			for _, template in ipairs(fruitTemplates) do
				local clone = template:Clone()
				clone.Name = template.Name .. "Spilled"
				clone.Parent = workspace:FindFirstChild("InteractiveObjects") or workspace
				CollectionService:AddTag(clone, Constants.Tags.TemporaryObject)
				CollectionService:AddTag(clone, Constants.Tags.LooseFruit)

				local primary = clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart", true)
				if primary then
					clone.PrimaryPart = primary
					CollectionService:AddTag(primary, Constants.Tags.LooseFruit)
				end

				clone:PivotTo(
					originCFrame
						* CFrame.new(random:NextNumber(-1.4, 1.4), random:NextNumber(0.7, 1.8), random:NextNumber(-1.4, 1.4))
						* CFrame.Angles(random:NextNumber(-math.pi, math.pi), random:NextNumber(-math.pi, math.pi), random:NextNumber(-math.pi, math.pi))
				)

				for _, descendant in ipairs(clone:GetDescendants()) do
					if descendant:IsA("BasePart") then
						local baseTransparency = descendant:GetAttribute("BaseTransparency")
						descendant.Transparency = if baseTransparency ~= nil then baseTransparency else 0
						descendant.Anchored = false
						descendant.CanCollide = true
						descendant.Massless = false
						CollectionService:AddTag(descendant, Constants.Tags.TemporaryObject)
					end
				end

				if primary then
					local horizontal = nil
					if zone then
						local target = Vector3.new(
							random:NextNumber(zone.Min.X + 4, zone.Max.X - 4),
							primary.Position.Y,
							random:NextNumber(zone.Min.Z + 4, zone.Max.Z - 4)
						)
						horizontal = Vector3.new(target.X - primary.Position.X, 0, target.Z - primary.Position.Z)
					end

					if not horizontal or horizontal.Magnitude < 1 then
						local angle = random:NextNumber(0, math.pi * 2)
						horizontal = Vector3.new(math.cos(angle), 0, math.sin(angle))
					end

					primary.AssemblyLinearVelocity = horizontal.Unit * random:NextNumber(76, 118)
						+ Vector3.new(0, random:NextNumber(32, 54), 0)
					primary.AssemblyAngularVelocity = Vector3.new(
						random:NextNumber(-22, 22),
						random:NextNumber(-22, 22),
						random:NextNumber(-22, 22)
					)
				end
			end

			task.wait(0.08)
		end

		for _, template in ipairs(fruitTemplates) do
			template:Destroy()
		end

		task.wait(0.7)
		state.Reacting = false
	end)
end

function InteractionService:_wireIslandWarningSign(sign, discoveryId, message)
	local prompt = getPrompt(sign)

	self:_connectPrompt(prompt, function(player)
		self.discoveryService:Unlock(player, discoveryId)
		playSound(sign, "rbxasset://sounds/button.wav", 0.35, 0.82)
		self.systemMessageRemote:FireClient(player, message)
	end)
end

function InteractionService:_getIslandExitRequiredCount()
	local room = Constants.GetRoom("Island")
	if not room or not room.DiscoveryOrder then
		return 1
	end

	return #room.DiscoveryOrder
end

function InteractionService:_spawnIslandShark(exitGate, player)
	local rootPart = getRootPart(player)
	local origin = exitGate:IsA("BasePart") and exitGate.Position or Constants.GetRoomSpawnCFrame("Island").Position
	local sharkModel = Instance.new("Model")
	sharkModel.Name = "IslandExitShark"
	sharkModel.Parent = workspace
	CollectionService:AddTag(sharkModel, Constants.Tags.TemporaryObject)

	local function makeSharkPart(name, className, size, cframe, color)
		local part = Instance.new(className or "Part")
		part.Name = name
		part.Anchored = true
		part.CanCollide = false
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.TopSurface = Enum.SurfaceType.Smooth
		part.Size = size
		part.CFrame = cframe
		part.Color = color
		part.Material = Enum.Material.SmoothPlastic
		part.Parent = sharkModel
		return part
	end

	local baseCFrame = CFrame.new(origin + Vector3.new(0, -2.2, 4.2), origin)
	local body = makeSharkPart("SharkBody", "Part", Vector3.new(6.2, 1.5, 2.2), baseCFrame, Color3.fromRGB(89, 103, 116))
	body.Shape = Enum.PartType.Ball
	makeSharkPart("SharkFin", "WedgePart", Vector3.new(1.8, 2.2, 1.4), baseCFrame * CFrame.new(0, 1.15, 0), Color3.fromRGB(55, 67, 78))
	makeSharkPart("SharkSnout", "WedgePart", Vector3.new(1.6, 1.1, 1.9), baseCFrame * CFrame.new(0, 0, -2.75), Color3.fromRGB(104, 121, 134))
	local eye = makeSharkPart("SharkEye", "Part", Vector3.new(0.34, 0.34, 0.34), baseCFrame * CFrame.new(-0.86, 0.32, -2.0), Color3.fromRGB(255, 255, 245))
	eye.Shape = Enum.PartType.Ball

	playSound(exitGate, "rbxasset://sounds/snap.wav", 0.8, 0.72)
	playSound(exitGate, "rbxasset://sounds/electronicpingshort.wav", 0.55, 0.45)

	for _, part in ipairs(sharkModel:GetChildren()) do
		if part:IsA("BasePart") then
			tweenPart(part, 0.18, {
				CFrame = part.CFrame + Vector3.new(0, 2.7, 0),
			}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end
	end

	if rootPart then
		rootPart.AssemblyLinearVelocity = Vector3.new(0, 42, 74)
		task.delay(0.28, function()
			if rootPart.Parent then
				local destination = Constants.GetRoomSpawnCFrame("Island")
				rootPart.CFrame = destination
				rootPart.AssemblyLinearVelocity = Vector3.new(0, 28, 34)
			end
		end)
	end

	Debris:AddItem(sharkModel, 3.2)
end

function InteractionService:_wireIslandExit(exitGate)
	local prompt = getPrompt(exitGate)

	local function attemptLeave(player)
		if not player or not player.Parent then
			return
		end

		local requiredCount = self:_getIslandExitRequiredCount()
		local currentCount = self.discoveryService:GetRoomDiscoveryCount(player, "Island")

		if currentCount < requiredCount then
			local now = os.clock()
			if now - (self.islandExitBounceAtByUserId[player.UserId] or 0) < 0.8 then
				return
			end

			self.islandExitBounceAtByUserId[player.UserId] = now
			local warningCount = (self.islandExitWarningsByUserId[player.UserId] or 0) + 1
			self.islandExitWarningsByUserId[player.UserId] = warningCount

			if warningCount < 3 then
				local remainingWarnings = 3 - warningCount
				self.systemMessageRemote:FireClient(
					player,
					("Warning %d/3: something large is objecting to early checkout. Find %d island discoveries first. You have %d."):format(
						warningCount,
						requiredCount,
						currentCount
					)
				)
				if remainingWarnings == 1 then
					playSound(exitGate, "rbxasset://sounds/electronicpingshort.wav", 0.55, 0.45)
				else
					playSound(exitGate, "rbxasset://sounds/button.wav", 0.45, 0.6)
				end
			else
				self.islandExitWarningsByUserId[player.UserId] = 0
				self.discoveryService:Unlock(player, Constants.Discoveries.SharkBounce.Id)
				self:_spawnIslandShark(exitGate, player)
				self.systemMessageRemote:FireClient(player, "Third warning: the exit shark has filed a physical complaint.")
			end
			return
		end

		self.islandExitWarningsByUserId[player.UserId] = nil
		local destinationCFrame = exitGate:GetAttribute("DestinationCFrame") or Constants.Hallway.SpawnCFrame
		teleportPlayer(player, destinationCFrame)
		self.systemMessageRemote:FireClient(player, "The island lets you return to the hallway.")
	end

	self:_connectPrompt(prompt, attemptLeave)

	if exitGate:IsA("BasePart") and not self.islandExitTouchConnections[exitGate] then
		self.islandExitTouchConnections[exitGate] = exitGate.Touched:Connect(function(hit)
			local character = hit:FindFirstAncestorOfClass("Model")
			local player = character and Players:GetPlayerFromCharacter(character)
			if player then
				attemptLeave(player)
			end
		end)
	end
end

function InteractionService:_getIslandTreasureModel()
	for _, treasurePart in ipairs(CollectionService:GetTagged(Constants.Tags.IslandTreasure)) do
		if treasurePart and treasurePart.Parent then
			return treasurePart:FindFirstAncestor("IslandTreasureBox") or treasurePart.Parent
		end
	end

	return nil
end

function InteractionService:_setIslandTreasureLayerVisible(treasure, layerName, visible)
	if not treasure then
		return
	end

	for _, instance in ipairs(getInstanceAndDescendants(treasure)) do
		if instance:IsA("BasePart") and instance:GetAttribute("TreasureLayer") == layerName then
			instance.Transparency = visible and 0 or 1
			instance.CanCollide = visible and layerName == "Chest"
		elseif instance:IsA("SurfaceGui")
			and instance.Parent
			and instance.Parent:IsA("BasePart")
			and instance.Parent:GetAttribute("TreasureLayer") == layerName
		then
			instance.Enabled = visible
		end
	end
end

function InteractionService:_revealIslandTreasure()
	local treasure = self:_getIslandTreasureModel()
	if not treasure then
		return nil
	end

	self:_setIslandTreasureLayerVisible(treasure, "Chest", true)
	local base = treasure:FindFirstChild("TreasureChestBase", true)
	if base then
		setPromptEnabled(base, true)
	end

	return treasure
end

function InteractionService:_wireIslandShovel(shovel)
	local prompt = getPrompt(shovel)

	self.islandShovelState[shovel] = self.islandShovelState[shovel] or {
		Reacting = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.islandShovelState[shovel]
		if not state or state.Reacting then
			return
		end

		state.Reacting = true
		self.discoveryService:Unlock(player, Constants.Discoveries.DugTreasure.Id)
		playSound(shovel, "rbxasset://sounds/snap.wav", 0.45, 0.58)

		if shovel:IsA("BasePart") then
			local baseCFrame = shovel:GetAttribute("BaseCFrame") or shovel.CFrame
			local digTween = tweenPart(shovel, 0.16, {
				CFrame = baseCFrame * CFrame.Angles(math.rad(0), 0, math.rad(-20)),
			}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			digTween.Completed:Wait()
			tweenPart(shovel, 0.18, {
				CFrame = baseCFrame,
			}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end

		local treasure = self:_revealIslandTreasure()
		if treasure then
			self.systemMessageRemote:FireClient(player, "The shovel found a treasure box in the sand.")
		else
			self.systemMessageRemote:FireClient(player, "The shovel found a treasure box, but the box forgot to exist.")
		end

		task.wait(0.2)
		state.Reacting = false
	end)
end

function InteractionService:_wireIslandTreasure(treasurePart)
	local prompt = getPrompt(treasurePart)

	self.islandTreasureState[treasurePart] = self.islandTreasureState[treasurePart] or {
		Reacting = false,
		Opened = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.islandTreasureState[treasurePart]
		if not state or state.Reacting then
			return
		end

		state.Reacting = true
		state.Opened = true
		self.discoveryService:Unlock(player, Constants.Discoveries.OpenedTreasure.Id)
		playSound(treasurePart, "rbxasset://sounds/button.wav", 0.5, 0.72)

		local treasure = treasurePart:FindFirstAncestor("IslandTreasureBox") or treasurePart.Parent
		local lid = treasure and treasure:FindFirstChild("TreasureChestLid", true)
		if lid and lid:IsA("BasePart") then
			local baseCFrame = lid:GetAttribute("BaseCFrame") or lid.CFrame
			tweenPart(lid, 0.3, {
				CFrame = baseCFrame * CFrame.new(0, 1.25, 1.35) * CFrame.Angles(math.rad(-72), 0, 0),
				Color = Color3.fromRGB(158, 92, 47),
			}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			lid.CanCollide = false
		end

		self:_setIslandTreasureLayerVisible(treasure, "Cola", true)
		local colaCan = treasure and treasure:FindFirstChild("IslandBloxyColaCan", true)
		if colaCan then
			setPromptEnabled(colaCan, true)
		end

		self.systemMessageRemote:FireClient(player, "The treasure box contains a Bloxy Cola. Classic.")
		task.wait(0.25)
		state.Reacting = false
	end)
end

function InteractionService:_wireIslandBloxyCola(cola)
	local prompt = getPrompt(cola)

	self.islandColaState[cola] = self.islandColaState[cola] or {
		Reacting = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.islandColaState[cola]
		if not state or state.Reacting then
			return
		end

		state.Reacting = true
		self.discoveryService:Unlock(player, Constants.Discoveries.IslandBloxyCola.Id)
		self:_playBloxyColaSound(cola)

		if cola:IsA("BasePart") then
			local baseCFrame = cola:GetAttribute("BaseCFrame") or cola.CFrame
			local popTween = tweenPart(cola, 0.16, {
				CFrame = baseCFrame + Vector3.new(0, 0.7, 0),
			}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			popTween.Completed:Wait()
			tweenPart(cola, 0.2, {
				CFrame = baseCFrame,
			}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		end

		self.systemMessageRemote:FireClient(player, "The island Bloxy Cola makes the correct soda noise.")
		task.wait(0.25)
		state.Reacting = false
	end)
end

return InteractionService
