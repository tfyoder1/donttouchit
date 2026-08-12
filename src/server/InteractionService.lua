local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
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

local BOWLING_COSMIC_COLORS = {
	Color3.fromRGB(119, 255, 203),
	Color3.fromRGB(255, 88, 128),
	Color3.fromRGB(150, 112, 255),
	Color3.fromRGB(255, 232, 92),
	Color3.fromRGB(93, 217, 255),
}

local BOWLING_ADS = {
	{
		Text = "BLOXY COLA\nOPEN ONE IN THE SNACK LAB",
		Background = Color3.fromRGB(218, 40, 47),
		TextColor = Color3.fromRGB(255, 246, 220),
	},
	{
		Text = "BLOXY ZIPLINE\nTREES TODAY, ISLAND TOMORROW",
		Background = Color3.fromRGB(47, 146, 101),
		TextColor = Color3.fromRGB(230, 255, 224),
	},
	{
		Text = "BLOXY ISLAND\nSUN, SAND, AND BAD IDEAS",
		Background = Color3.fromRGB(255, 205, 89),
		TextColor = Color3.fromRGB(45, 61, 83),
	},
	{
		Text = "BLOXY BOWLING\nTHREE LANES, MANY EXCUSES",
		Background = Color3.fromRGB(93, 217, 255),
		TextColor = Color3.fromRGB(18, 24, 36),
	},
	{
		Text = "BLOXY SHOES\nRENTAL CONFIDENCE INCLUDED",
		Background = Color3.fromRGB(150, 112, 255),
		TextColor = Color3.fromRGB(255, 246, 220),
	},
}

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

local function getMaterialByName(materialName)
	for _, material in ipairs(Enum.Material:GetEnumItems()) do
		if material.Name == materialName then
			return material
		end
	end

	return nil
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
	self.islandWarningReadStateByUserId = {}
	self.islandShovelState = {}
	self.islandTreasureState = {}
	self.islandColaState = {}
	self.islandCoconutState = {}
	self.islandCoconutTreeState = {}
	self.islandScrapWoodState = {}
	self.islandWoodCountByUserId = {}
	self.islandFireRingState = {}
	self.islandSkyBlockState = {}
	self.islandSpaceLadderState = {}
	self.spaceStationState = {}
	self.secretDoorState = {}
	self.libraryLampState = {}
	self.libraryGlobeState = {}
	self.libraryLadderState = {}
	self.libraryLoftDoorState = {}
	self.libraryBookcaseState = {}
	self.bowlingLaneState = {}
	self.bowlingLaneCounts = {
		[1] = 0,
		[2] = 0,
		[3] = 0,
	}
	self.bowlingCosmicActive = false
	self.bowlingCosmicToken = nil
	self.bowlingAdToken = nil
	self.treetopZiplineStateByUserId = {}
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

	Players.PlayerRemoving:Connect(function(player)
		self.islandExitBounceAtByUserId[player.UserId] = nil
		self.islandExitWarningsByUserId[player.UserId] = nil
		self.islandWarningReadStateByUserId[player.UserId] = nil
		self.islandWoodCountByUserId[player.UserId] = nil
		self.treetopZiplineStateByUserId[player.UserId] = nil
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
		self:_wireIslandWarningSign(instance, Constants.Discoveries.ReadSharkWarning.Id, "The shark sign feels less like advice and more like a countdown. Watch out for land sharks!")
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

	self:_connectTagged(Constants.Tags.IslandCoconut, function(instance)
		self:_wireIslandCoconut(instance)
	end)

	self:_connectTagged(Constants.Tags.IslandCoconutTree, function(instance)
		self:_wireIslandCoconutTree(instance)
	end)

	self:_connectTagged(Constants.Tags.IslandScrapWood, function(instance)
		self:_wireIslandScrapWood(instance)
	end)

	self:_connectTagged(Constants.Tags.IslandFireRing, function(instance)
		self:_wireIslandFireRing(instance)
	end)

	self:_connectTagged(Constants.Tags.IslandHiddenSkyBlock, function(instance)
		self:_wireIslandHiddenSkyBlock(instance)
	end)

	self:_connectTagged(Constants.Tags.IslandSpaceLadder, function(instance)
		self:_wireIslandSpaceLadder(instance)
	end)

	self:_connectTagged(Constants.Tags.LibraryBook, function(instance)
		self:_wireDiscoveryPrompt(instance, Constants.Discoveries.LibraryForbiddenBook.Id, "The forbidden book sighs and immediately regrets being readable.")
	end)

	self:_connectTagged(Constants.Tags.LibraryShelf, function(instance)
		self:_wireDiscoveryPrompt(instance, Constants.Discoveries.LibraryShushedShelf.Id, "The shelf shushes you before you even make noise.")
	end)

	self:_connectTagged(Constants.Tags.LibraryLamp, function(instance)
		self:_wireLibraryLamp(instance)
	end)

	self:_connectTagged(Constants.Tags.LibraryGlobe, function(instance)
		self:_wireLibraryGlobe(instance)
	end)

	self:_connectTagged(Constants.Tags.LibraryCatalog, function(instance)
		self:_wireDiscoveryPrompt(instance, Constants.Discoveries.LibraryCatalog.Id, "The card catalog files you under Possibly Problem.")
	end)

	self:_connectTagged(Constants.Tags.LibraryLadder, function(instance)
		self:_wireLibraryLadder(instance)
	end)

	self:_connectTagged(Constants.Tags.LibraryLoftDoor, function(instance)
		self:_wireLibraryLoftDoor(instance)
	end)

	self:_connectTagged(Constants.Tags.LibraryTopShelfKey, function(instance)
		self:_wireLibraryBowlingKey(instance)
	end)

	self:_connectTagged(Constants.Tags.LibraryBookcaseDoor, function(instance)
		self:_wireLibraryBookcaseDoor(instance)
	end)

	self:_connectTagged(Constants.Tags.BowlingLaneButton, function(instance)
		self:_wireBowlingLaneButton(instance)
	end)

	self:_connectTagged(Constants.Tags.BowlingCosmicSwitch, function(instance)
		self:_wireBowlingCosmicSwitch(instance)
	end)

	self:_connectTagged(Constants.Tags.BowlingDiscoBall, function(instance)
		self:_wireDiscoveryPrompt(instance, Constants.Discoveries.BowlingDiscoBall.Id, "The disco ball refuses to explain the score.")
	end)

	self:_connectTagged(Constants.Tags.BowlingMaintenanceDoor, function(instance)
		self:_wireBowlingMaintenanceDoor(instance)
	end)

	self:_connectTagged(Constants.Tags.BowlingResetLever, function(instance)
		self:_wireBowlingResetLever(instance)
	end)

	self:_connectTagged(Constants.Tags.BowlingShoeRack, function(instance)
		self:_wireDiscoveryPrompt(instance, Constants.Discoveries.BowlingShoes.Id, "The shoe rack confirms the shoes are optional but judgment is not.")
	end)

	self:_connectTagged(Constants.Tags.BowlingScoreboard, function(instance)
		self:_wireDiscoveryPrompt(instance, Constants.Discoveries.BowlingScoreboard.Id, "The scoreboard is keeping score emotionally.")
	end)

	self:_connectTagged(Constants.Tags.BowlingGutter, function(instance)
		self:_wireDiscoveryPrompt(instance, Constants.Discoveries.BowlingGutter.Id, "The gutter says it is not failure, it is alternative bowling.")
	end)

	self:_connectTagged(Constants.Tags.BowlingBallReturn, function(instance)
		self:_wireBowlingBallReturn(instance)
	end)

	self:_connectTagged(Constants.Tags.TreetopZipline, function(instance)
		self:_wireTreetopZipline(instance)
	end)

	self:_connectTagged(Constants.Tags.SpaceStationAirlock, function(instance)
		self:_wireDiscoveryPrompt(instance, Constants.Discoveries.SpaceStationAirlock.Id, "The airlock confirms that outside is still extremely outside.")
	end)

	self:_connectTagged(Constants.Tags.SpaceStationGravityDial, function(instance)
		self:_wireSpaceStationGravityDial(instance)
	end)

	self:_connectTagged(Constants.Tags.SpaceStationObservationWindow, function(instance)
		self:_wireSpaceStationObservationWindow(instance)
	end)

	self:_connectTagged(Constants.Tags.SpaceStationCommsPanel, function(instance)
		self:_wireDiscoveryPrompt(instance, Constants.Discoveries.SpaceStationCommsPanel.Id, "Mission Control receives: 'Do not touch anything.' They mark it urgent.")
	end)

	self:_connectTagged(Constants.Tags.SpaceStationFoodPrinter, function(instance)
		self:_wireSpaceStationFoodPrinter(instance)
	end)

	self:_connectTagged(Constants.Tags.SpaceStationSuit, function(instance)
		self:_wireDiscoveryPrompt(instance, Constants.Discoveries.SpaceStationSuit.Id, "The space suit fits anyone willing to ignore the return policy.")
	end)

	self:_connectTagged(Constants.Tags.SpaceStationStarMap, function(instance)
		self:_wireSpaceStationStarMap(instance)
	end)

	self:_connectTagged(Constants.Tags.SpaceStationPlantPod, function(instance)
		self:_wireSpaceStationPlantPod(instance)
	end)

	self:_connectTagged(Constants.Tags.SpaceStationMeteorButton, function(instance)
		self:_wireSpaceStationMeteorButton(instance)
	end)

	self:_connectTagged(Constants.Tags.SpaceStationEscapePod, function(instance)
		self:_wireSpaceStationEscapePod(instance)
	end)

	self:_updateBowlingScoreboards()
	self:_startBowlingAdRotation()

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

function InteractionService:_wireDiscoveryPrompt(instance, discoveryId, message)
	local prompt = getPrompt(instance)

	self:_connectPrompt(prompt, function(player)
		self.discoveryService:Unlock(player, discoveryId)
		playSound(instance, "rbxasset://sounds/button.wav", 0.35, 0.9)
		if message then
			self.systemMessageRemote:FireClient(player, message)
		end
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
	local unlocked = state.Unlocked == true
	local canOpen = hasKey or unlocked

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
				instance.ActionText = if canOpen then "Open" else "Inspect"
				instance.ObjectText = if canOpen then "Library" else "Library - Awaiting Key"
			end
		elseif instance:IsA("SurfaceGui") then
			local visibleEnabled = instance:GetAttribute("SecretVisibleEnabled")
			instance.Enabled = active and (visibleEnabled == nil or visibleEnabled == true)
		elseif instance:IsA("TextLabel") and instance.Name == "SecretDoorText" then
			instance.Text = if unlocked then "LIBRARY\nUNLOCKED" elseif hasKey then "LIBRARY\nKEY ACCEPTED" else "LIBRARY\nAWAITING KEY"
		end
	end
end

function InteractionService:_getSecretDoorWorldState(roomId)
	local state = {
		OutlineVisible = false,
		Active = false,
		HasKey = false,
		Unlocked = false,
	}

	for _, player in ipairs(Players:GetPlayers()) do
		local secretConfig = Constants.SecretDoors and Constants.SecretDoors[roomId]
		if secretConfig and secretConfig.EntryDiscoveryId and self.discoveryService:HasDiscovery(player, secretConfig.EntryDiscoveryId) then
			state.OutlineVisible = true
			state.Active = true
			state.Unlocked = true
		end

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

		local secretConfig = Constants.SecretDoors and Constants.SecretDoors[roomId]
		local alreadyUnlocked = secretConfig
			and secretConfig.EntryDiscoveryId
			and self.discoveryService:HasDiscovery(player, secretConfig.EntryDiscoveryId)
		local hasKey = self.discoveryService:HasSecretKey(player, roomId)

		if not alreadyUnlocked and not hasKey then
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
		self.discoveryService:Unlock(player, Constants.Discoveries.LibraryEntered.Id)
		if hasKey then
			self.discoveryService:ConsumeSecretKey(player, roomId, "The Library Key unlocks the door and politely retires.")
		end
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
		local destinationName = exitDoor:GetAttribute("DestinationName") or "the TV Room"
		self.systemMessageRemote:FireClient(player, ("Back to %s. Act natural."):format(destinationName))
	end)
end

function InteractionService:_wireLibraryLamp(lamp)
	local prompt = getPrompt(lamp)
	local light = lamp:FindFirstChild("LibraryLampLight", true)

	self.libraryLampState[lamp] = self.libraryLampState[lamp] or {
		On = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.libraryLampState[lamp]
		state.On = not state.On
		self.discoveryService:Unlock(player, Constants.Discoveries.LibraryLamp.Id)

		if light and light:IsA("PointLight") then
			light.Brightness = state.On and 4.2 or 0
		end

		if lamp:IsA("BasePart") then
			lamp.Material = state.On and Enum.Material.Neon or Enum.Material.Metal
			tweenPart(lamp, 0.16, {
				Color = state.On and Color3.fromRGB(255, 239, 157) or (lamp:GetAttribute("BaseColor") or Color3.fromRGB(255, 214, 102)),
			}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		end

		playSound(lamp, "rbxasset://sounds/electronicpingshort.wav", 0.35, state.On and 1.4 or 0.75)
		self.systemMessageRemote:FireClient(player, state.On and "The reading lamp found dramatic purpose." or "The reading lamp returns to quiet judgment.")
	end)
end

function InteractionService:_wireLibraryGlobe(globe)
	local prompt = getPrompt(globe)

	self.libraryGlobeState[globe] = self.libraryGlobeState[globe] or {
		Reacting = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.libraryGlobeState[globe]
		if not state or state.Reacting or not globe:IsA("BasePart") then
			return
		end

		state.Reacting = true
		self.discoveryService:Unlock(player, Constants.Discoveries.LibraryGlobe.Id)
		self.systemMessageRemote:FireClient(player, "The globe spins and briefly recommends a different continent.")
		playSound(globe, "rbxasset://sounds/button.wav", 0.34, 1.25)

		local baseCFrame = globe:GetAttribute("BaseCFrame") or globe.CFrame
		for step = 1, 14 do
			if not globe.Parent then
				break
			end

			globe.CFrame = baseCFrame * CFrame.Angles(0, math.rad(step * 42), 0)
			task.wait(0.035)
		end

		if globe.Parent then
			tweenPart(globe, 0.18, {
				CFrame = baseCFrame,
			}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		end
		state.Reacting = false
	end)
end

function InteractionService:_wireLibraryLadder(ladder)
	local prompt = getPrompt(ladder)

	self.libraryLadderState[ladder] = self.libraryLadderState[ladder] or {
		Moved = false,
		Reacting = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.libraryLadderState[ladder]
		if not state or state.Reacting or not ladder:IsA("BasePart") then
			return
		end

		state.Reacting = true
		self.discoveryService:Unlock(player, Constants.Discoveries.LibraryLadder.Id)
		playSound(ladder, "rbxasset://sounds/button.wav", 0.42, 0.68)

		local baseCFrame = ladder:GetAttribute("BaseCFrame") or ladder.CFrame
		state.Moved = not state.Moved
		local targetCFrame = state.Moved and (baseCFrame + Vector3.new(2.6, 0, -1.1)) or baseCFrame
		tweenPart(ladder, 0.35, {
			CFrame = targetCFrame,
			Color = state.Moved and Color3.fromRGB(219, 154, 82) or (ladder:GetAttribute("BaseColor") or ladder.Color),
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		self.systemMessageRemote:FireClient(player, "The rolling library ladder glides toward the suspicious top shelf.")
		task.wait(0.25)
		state.Reacting = false
	end)
end

function InteractionService:_wireLibraryLoftDoor(door)
	local prompt = getPrompt(door)

	self.libraryLoftDoorState[door] = self.libraryLoftDoorState[door] or {
		Reacting = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.libraryLoftDoorState[door]
		if not state or state.Reacting then
			return
		end

		if not self.discoveryService:HasDiscovery(player, Constants.Discoveries.LibraryLadder.Id) then
			self.systemMessageRemote:FireClient(player, "The loft door is visible, but the Library expects ladder etiquette first.")
			playSound(door, "rbxasset://sounds/snap.wav", 0.35, 0.6)
			return
		end

		state.Reacting = true
		self.discoveryService:Unlock(player, Constants.Discoveries.LibraryLoft.Id)
		playSound(door, "rbxasset://sounds/electronicpingshort.wav", 0.42, 1.35)
		self.systemMessageRemote:FireClient(player, "The loft door opens onto a very selective reading nook above the Library.")

		local destination = door:GetAttribute("DestinationCFrame") or CFrame.new(-14, 17.6, -45)
		teleportPlayer(player, destination)
		task.wait(0.25)
		state.Reacting = false
	end)
end

function InteractionService:_wireLibraryBowlingKey(key)
	local prompt = getPrompt(key)

	self:_connectPrompt(prompt, function(player)
		if not self.discoveryService:HasDiscovery(player, Constants.Discoveries.LibraryLadder.Id) then
			self.systemMessageRemote:FireClient(player, "The Bowling Key is too high. The rolling ladder is the Library-approved shortcut.")
			playSound(key, "rbxasset://sounds/snap.wav", 0.35, 0.5)
			return
		end

		local unlocked = self.discoveryService:Unlock(player, Constants.Discoveries.LibraryBowlingKey.Id)
		if unlocked then
			self.systemMessageRemote:FireClient(player, "Bowling Key found. The bookcase suddenly looks guilty.")
		else
			self.systemMessageRemote:FireClient(player, "You already found the Bowling Key.")
		end

		playSound(key, "rbxasset://sounds/electronicpingshort.wav", 0.5, 1.85)
		for _, partName in ipairs({ "BowlingKeyTopShelf", "BowlingKeyHead" }) do
			local part = key.Parent and key.Parent:FindFirstChild(partName, true)
			if part and part:IsA("BasePart") then
				part.Transparency = 0.55
				part.CanCollide = false
			end
		end
	end)
end

function InteractionService:_wireLibraryBookcaseDoor(door)
	local prompt = getPrompt(door)

	self.libraryBookcaseState[door] = self.libraryBookcaseState[door] or {
		Reacting = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.libraryBookcaseState[door]
		if not state or state.Reacting then
			return
		end

		if not self.discoveryService:HasDiscovery(player, Constants.Discoveries.LibraryBowlingKey.Id) then
			self.systemMessageRemote:FireClient(player, "The bookcase does not swing for strangers. It wants the Bowling Key.")
			playSound(door, "rbxasset://sounds/snap.wav", 0.38, 0.52)
			return
		end

		local destinationCFrame = door:GetAttribute("DestinationCFrame")
		if typeof(destinationCFrame) ~= "CFrame" then
			self.systemMessageRemote:FireClient(player, "The bookcase found a secret, then misplaced the coordinates.")
			return
		end

		state.Reacting = true
		self.discoveryService:Unlock(player, Constants.Discoveries.LibraryBookcaseDoor.Id)
		playSound(door, "rbxasset://sounds/button.wav", 0.48, 0.58)
		playSound(door, "rbxasset://sounds/electronicpingshort.wav", 0.35, 1.55)

		if door:IsA("BasePart") then
			door.CanCollide = false
			local openTween = tweenPart(door, 0.42, {
				CFrame = getSecretDoorOpenCFrame(door),
				Color = Color3.fromRGB(119, 255, 203),
			}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			openTween.Completed:Wait()
		else
			task.wait(0.25)
		end

		teleportPlayer(player, destinationCFrame)
		self.discoveryService:Unlock(player, Constants.Discoveries.BowlingEntered.Id)
		self.systemMessageRemote:FireClient(player, "The bookcase opens into a bowling alley. That is not standard library architecture.")

		task.delay(1.2, function()
			if door.Parent and door:IsA("BasePart") then
				tweenPart(door, 0.26, {
					CFrame = door:GetAttribute("SecretClosedCFrame") or door:GetAttribute("BaseCFrame") or door.CFrame,
					Color = door:GetAttribute("BaseColor") or Color3.fromRGB(76, 48, 34),
				}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				door.CanCollide = true
			end
			state.Reacting = false
		end)
	end)
end

function InteractionService:_spawnBowlingBall(button, laneIndex, laneX, player)
	self:_setBowlingLanePinsAnchored(laneIndex, false)

	local ball = Instance.new("Part")
	ball.Name = "BowlingBall"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(2.15, 2.15, 2.15)
	ball.Color = BOWLING_COSMIC_COLORS[((laneIndex - 1) % #BOWLING_COSMIC_COLORS) + 1]
	ball.Material = self.bowlingCosmicActive and Enum.Material.Neon or Enum.Material.SmoothPlastic
	ball.CanCollide = true
	ball.Anchored = false
	ball.CustomPhysicalProperties = PhysicalProperties.new(4.5, 0.35, 0.35)
	ball:SetAttribute("LaneIndex", laneIndex)
	local ballSpawnZ = button:GetAttribute("BallSpawnZ") or (button.Position.Z - 1.3)
	local ballVelocityZ = button:GetAttribute("BallVelocityZ") or -118
	ball.CFrame = CFrame.new(laneX, 2.05, ballSpawnZ)
	ball.Parent = workspace:FindFirstChild("InteractiveObjects") or workspace
	CollectionService:AddTag(ball, Constants.Tags.TemporaryObject)

	local hitPins = {}
	ball.Touched:Connect(function(hit)
		if not hit or hit == ball or not CollectionService:HasTag(hit, Constants.Tags.BowlingPin) then
			return
		end

		if hit:GetAttribute("LaneIndex") ~= laneIndex then
			return
		end

		if not hitPins[hit] then
			hitPins[hit] = true
			self.discoveryService:Unlock(player, Constants.Discoveries.BowlingPinsHit.Id)
			hit.AssemblyLinearVelocity += Vector3.new((math.random() - 0.5) * 24, 18, -22)
			hit.AssemblyAngularVelocity = Vector3.new(9, 4, 13)
		end
	end)

	ball.AssemblyLinearVelocity = Vector3.new(0, 0, ballVelocityZ)
	ball.AssemblyAngularVelocity = Vector3.new(-28, 0, 0)
	Debris:AddItem(ball, 14)

	return ball
end

function InteractionService:_clearBowlingBalls(laneIndex)
	for _, temporaryObject in ipairs(CollectionService:GetTagged(Constants.Tags.TemporaryObject)) do
		if temporaryObject
			and temporaryObject.Parent
			and temporaryObject.Name == "BowlingBall"
			and (not laneIndex or temporaryObject:GetAttribute("LaneIndex") == laneIndex)
		then
			temporaryObject:Destroy()
		end
	end
end

function InteractionService:_formatBowlingScoreboardText()
	return ("LANE 1: %02d     LANE 2: %02d     LANE 3: %02d\nROLL COUNTER: TOUCHES WE CAN MEASURE"):format(
		self.bowlingLaneCounts[1] or 0,
		self.bowlingLaneCounts[2] or 0,
		self.bowlingLaneCounts[3] or 0
	)
end

function InteractionService:_updateBowlingScoreboards()
	for _, scoreboard in ipairs(CollectionService:GetTagged(Constants.Tags.BowlingScoreboard)) do
		local label = scoreboard:FindFirstChild("ScoreboardText", true)
		if label and label:IsA("TextLabel") then
			label.Text = self:_formatBowlingScoreboardText()
		end
	end
end

function InteractionService:_incrementBowlingLaneCount(laneIndex)
	if typeof(laneIndex) ~= "number" then
		return
	end

	if laneIndex < 1 or laneIndex > 3 then
		return
	end

	self.bowlingLaneCounts[laneIndex] = (self.bowlingLaneCounts[laneIndex] or 0) + 1
	self:_updateBowlingScoreboards()
end

function InteractionService:_updateBowlingAds(step)
	for _, instance in ipairs(workspace:GetDescendants()) do
		if instance:IsA("BasePart") and instance:GetAttribute("BowlingAdScreen") then
			local adOffset = instance:GetAttribute("BowlingAdOffset") or 1
			local ad = BOWLING_ADS[((step + adOffset - 2) % #BOWLING_ADS) + 1]
			local label = instance:FindFirstChild("BowlingAdText", true)
			if label and label:IsA("TextLabel") then
				label.Text = ad.Text
				label.TextColor3 = ad.TextColor
				label.BackgroundColor3 = ad.Background
			end

			instance.Color = ad.Background
			local light = instance:FindFirstChild("BowlingAdLight", true)
			if light and light:IsA("SurfaceLight") then
				light.Color = ad.Background
			end
		end
	end
end

function InteractionService:_startBowlingAdRotation()
	local token = {}
	self.bowlingAdToken = token

	task.spawn(function()
		local step = 0
		while self.bowlingAdToken == token do
			self:_updateBowlingAds(step)
			step += 1
			task.wait(4)
		end
	end)
end

function InteractionService:_countKnockedBowlingPins(laneIndex)
	local knocked = 0

	for _, pin in ipairs(CollectionService:GetTagged(Constants.Tags.BowlingPin)) do
		if pin:IsA("BasePart") and pin:GetAttribute("LaneIndex") == laneIndex then
			local baseCFrame = pin:GetAttribute("BaseCFrame")
			local moved = baseCFrame and (pin.Position - baseCFrame.Position).Magnitude > 0.75
			local pinAxis = pin:GetAttribute("BowlingPinUprightAxis") == "RightVector" and pin.CFrame.RightVector or pin.CFrame.UpVector
			local baseAxis = baseCFrame and (pin:GetAttribute("BowlingPinUprightAxis") == "RightVector" and baseCFrame.RightVector or baseCFrame.UpVector)
			local tipped = baseAxis and math.abs(pinAxis:Dot(baseAxis)) < 0.72
			if moved or tipped then
				knocked += 1
			end
		end
	end

	return knocked
end

function InteractionService:_wireBowlingLaneButton(button)
	local prompt = getPrompt(button)
	local laneIndex = button:GetAttribute("LaneIndex") or 1
	local laneX = button:GetAttribute("LaneX") or button.Position.X

	self.bowlingLaneState[button] = self.bowlingLaneState[button] or {
		Reacting = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.bowlingLaneState[button]
		if not state or state.Reacting then
			return
		end

		state.Reacting = true
		self.discoveryService:Unlock(player, Constants.Discoveries.BowlingFirstBall.Id)
		playSound(button, "rbxasset://sounds/button.wav", 0.55, 0.75)

		if button:IsA("BasePart") then
			local baseCFrame = button:GetAttribute("BaseCFrame") or button.CFrame
			local downTween = tweenPart(button, 0.1, {
				CFrame = baseCFrame + Vector3.new(0, -0.18, 0),
				Color = Color3.fromRGB(255, 232, 92),
			}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			downTween.Completed:Wait()
			tweenPart(button, 0.18, {
				CFrame = baseCFrame,
				Color = button:GetAttribute("BaseColor") or button.Color,
			}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end

		self:_spawnBowlingBall(button, laneIndex, laneX, player)
		self:_incrementBowlingLaneCount(laneIndex)
		self.systemMessageRemote:FireClient(player, ("Lane %d accepts your bowling-related decision."):format(laneIndex))

		task.delay(2.8, function()
			local knocked = self:_countKnockedBowlingPins(laneIndex)
			if knocked >= 8 then
				self.discoveryService:Unlock(player, Constants.Discoveries.BowlingStrike.Id)
				self.systemMessageRemote:FireClient(player, ("Lane %d calls that close enough to a strike: %d pins."):format(laneIndex, knocked))
			elseif knocked > 0 then
				self.systemMessageRemote:FireClient(player, ("Lane %d reports %d pins down. The rest are being stubborn."):format(laneIndex, knocked))
			end
		end)

		task.delay(1.25, function()
			state.Reacting = false
		end)
	end)
end

function InteractionService:_setBowlingCosmicFog(active)
	for _, instance in ipairs(workspace:GetDescendants()) do
		if instance:IsA("ParticleEmitter") and instance:GetAttribute("CosmicFog") then
			instance.Enabled = active
		end
	end
end

function InteractionService:_updateBowlingLaserBeams(step, active)
	for _, instance in ipairs(workspace:GetDescendants()) do
		if instance:IsA("BasePart") and instance:GetAttribute("CosmicLaser") then
			if not active then
				instance.Transparency = instance:GetAttribute("BaseTransparency") or 1
				instance.CFrame = instance:GetAttribute("BaseCFrame") or instance.CFrame
				continue
			end

			local laserIndex = instance:GetAttribute("LaserIndex") or 1
			local laserLength = instance:GetAttribute("LaserLength") or instance.Size.Z
			local originCFrame = instance:GetAttribute("LaserOriginCFrame") or CFrame.new(instance.Position)
			local angleOffset = instance:GetAttribute("LaserAngleOffset") or 0
			local pitchDegrees = instance:GetAttribute("LaserPitchDegrees") or -5
			local color = BOWLING_COSMIC_COLORS[((step + laserIndex - 2) % #BOWLING_COSMIC_COLORS) + 1]

			instance.Material = Enum.Material.Neon
			instance.Color = color
			instance.Transparency = laserIndex % 2 == 0 and 0.34 or 0.22
			instance.CFrame = originCFrame
				* CFrame.Angles(0, math.rad(angleOffset + step * 18), 0)
				* CFrame.Angles(math.rad(pitchDegrees), 0, 0)
				* CFrame.new(0, 0, -laserLength / 2)
		end
	end
end

function InteractionService:_setBowlingCosmic(active, source)
	self.bowlingCosmicActive = active
	local token = {}
	self.bowlingCosmicToken = token

	if active then
		Lighting.Brightness = 1.1
		Lighting.ClockTime = 0
		Lighting.Ambient = Color3.fromRGB(44, 18, 80)
		Lighting.OutdoorAmbient = Color3.fromRGB(15, 8, 38)
	else
		self.resetService.RestoreLighting()
	end

	for _, instance in ipairs(workspace:GetDescendants()) do
		if instance:IsA("BasePart") and instance:GetAttribute("CosmicSurface") then
			if active then
				instance.Material = Enum.Material.Neon
				instance.Color = BOWLING_COSMIC_COLORS[((math.floor(math.abs(instance.Position.X)) % #BOWLING_COSMIC_COLORS) + 1)]
			else
				local baseColor = instance:GetAttribute("BaseColor")
				local baseMaterial = getMaterialByName(instance:GetAttribute("BaseMaterial"))
				if baseColor then
					instance.Color = baseColor
				end
				if baseMaterial then
					instance.Material = baseMaterial
				end
			end
		end
	end

	self:_setBowlingCosmicFog(active)
	self:_updateBowlingLaserBeams(0, active)

	for _, disco in ipairs(CollectionService:GetTagged(Constants.Tags.BowlingDiscoBall)) do
		if disco:IsA("BasePart") then
			if active then
				disco.Material = Enum.Material.Neon
				disco.Color = Color3.fromRGB(192, 222, 255)
			else
				local baseColor = disco:GetAttribute("BaseColor")
				local baseMaterial = getMaterialByName(disco:GetAttribute("BaseMaterial"))
				if baseColor then
					disco.Color = baseColor
				end
				if baseMaterial then
					disco.Material = baseMaterial
				end
			end
		end

		local light = disco:FindFirstChild("DiscoLight", true)
		if light and light:IsA("PointLight") then
			light.Brightness = active and 5.6 or 0
			light.Color = BOWLING_COSMIC_COLORS[1]
		end
	end

	if not active then
		return
	end

	task.spawn(function()
		local step = 0
		while self.bowlingCosmicActive and self.bowlingCosmicToken == token do
			step += 1
			local color = BOWLING_COSMIC_COLORS[((step - 1) % #BOWLING_COSMIC_COLORS) + 1]

			for _, instance in ipairs(workspace:GetDescendants()) do
				if instance:IsA("BasePart") and instance:GetAttribute("CosmicSurface") then
					instance.Color = BOWLING_COSMIC_COLORS[((step + math.floor(math.abs(instance.Position.X))) % #BOWLING_COSMIC_COLORS) + 1]
				end
			end

			for _, disco in ipairs(CollectionService:GetTagged(Constants.Tags.BowlingDiscoBall)) do
				if disco:IsA("BasePart") then
					disco.CFrame = (disco:GetAttribute("BaseCFrame") or disco.CFrame) * CFrame.Angles(0, math.rad(step * 22), 0)
				end

				local light = disco:FindFirstChild("DiscoLight", true)
				if light and light:IsA("PointLight") then
					light.Color = color
				end
			end

			self:_updateBowlingLaserBeams(step, true)

			task.wait(0.28)
		end
	end)

	if source then
		playSound(source, "rbxasset://sounds/electronicpingshort.wav", 0.5, 1.9)
	end
end

function InteractionService:_wireBowlingCosmicSwitch(switch)
	local prompt = getPrompt(switch)

	self:_connectPrompt(prompt, function(player)
		self.discoveryService:Unlock(player, Constants.Discoveries.BowlingCosmic.Id)
		self:_setBowlingCosmic(not self.bowlingCosmicActive, switch)
		if prompt then
			prompt.ActionText = self.bowlingCosmicActive and "Normalize" or "Cosmic"
		end

		self.systemMessageRemote:FireClient(
			player,
			self.bowlingCosmicActive and "Cosmic Bowling is on. The floor is taking lighting personally." or "Cosmic Bowling is off. The alley returns to regular questionable bowling."
		)
	end)
end

function InteractionService:_wireBowlingMaintenanceDoor(door)
	local prompt = getPrompt(door)

	self:_connectPrompt(prompt, function(player)
		local rootPart = getRootPart(player)
		local destinationCFrame = door:GetAttribute("DestinationCFrame")

		if rootPart and door:IsA("BasePart") and rootPart.Position.Z < door.Position.Z then
			destinationCFrame = CFrame.new(door.Position + Vector3.new(0, -1.25, 5.6))
		else
			self.discoveryService:Unlock(player, Constants.Discoveries.BowlingMaintenance.Id)
		end

		if typeof(destinationCFrame) ~= "CFrame" then
			self.systemMessageRemote:FireClient(player, "The maintenance door has misplaced its maintenance.")
			return
		end

		playSound(door, "rbxasset://sounds/button.wav", 0.42, 0.65)
		teleportPlayer(player, destinationCFrame)
		self.systemMessageRemote:FireClient(player, "The pin machinery allows a supervised maintenance detour.")
	end)
end

function InteractionService:_getBowlingPinParts(pin)
	if not pin or not pin.Parent then
		return {}
	end

	local model = pin:FindFirstAncestorWhichIsA("Model")
	if model and model:GetAttribute("BowlingPinModel") then
		local parts = {}
		for _, instance in ipairs(model:GetDescendants()) do
			if instance:IsA("BasePart") then
				table.insert(parts, instance)
			end
		end
		return parts
	end

	return { pin }
end

function InteractionService:_resetBowlingPin(pin)
	local parts = self:_getBowlingPinParts(pin)
	for _, part in ipairs(parts) do
		if part.Parent then
			local baseCFrame = part:GetAttribute("BaseCFrame")
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
			part.Anchored = true
			if baseCFrame then
				part.CFrame = baseCFrame
			end
		end
	end

	task.delay(0.16, function()
		for _, part in ipairs(parts) do
			if part.Parent then
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
				local baseAnchored = part:GetAttribute("BaseAnchored")
				part.Anchored = baseAnchored == true
			end
		end
	end)
end

function InteractionService:_setBowlingLanePinsAnchored(laneIndex, anchored)
	for _, pin in ipairs(CollectionService:GetTagged(Constants.Tags.BowlingPin)) do
		if pin:IsA("BasePart") and pin.Parent and pin:GetAttribute("LaneIndex") == laneIndex then
			for _, part in ipairs(self:_getBowlingPinParts(pin)) do
				if part.Parent then
					part.AssemblyLinearVelocity = Vector3.zero
					part.AssemblyAngularVelocity = Vector3.zero
					part.Anchored = anchored
				end
			end
		end
	end
end

function InteractionService:_resetBowlingPins(laneIndex)
	self:_clearBowlingBalls(laneIndex)

	for _, pin in ipairs(CollectionService:GetTagged(Constants.Tags.BowlingPin)) do
		if pin:IsA("BasePart") and pin.Parent and (not laneIndex or pin:GetAttribute("LaneIndex") == laneIndex) then
			self:_resetBowlingPin(pin)
		end
	end
end

function InteractionService:_wireBowlingResetLever(lever)
	local prompt = getPrompt(lever)

	self:_connectPrompt(prompt, function(player)
		self.discoveryService:Unlock(player, Constants.Discoveries.BowlingResetLever.Id)
		local laneIndex = lever:GetAttribute("LaneIndex")
		self:_resetBowlingPins(laneIndex)
		playSound(lever, "rbxasset://sounds/button.wav", 0.5, 0.58)

		if lever:IsA("BasePart") then
			local baseCFrame = lever:GetAttribute("BaseCFrame") or lever.CFrame
			local pullTween = tweenPart(lever, 0.14, {
				CFrame = baseCFrame * CFrame.Angles(0, 0, math.rad(-38)),
				Color = Color3.fromRGB(255, 236, 104),
			}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			pullTween.Completed:Wait()
			tweenPart(lever, 0.18, {
				CFrame = baseCFrame,
				Color = lever:GetAttribute("BaseColor") or lever.Color,
			}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end

		if laneIndex then
			self.systemMessageRemote:FireClient(player, ("Lane %d pinsetter resets the pins with suspicious accuracy."):format(laneIndex))
		else
			self.systemMessageRemote:FireClient(player, "The pinsetter resets the pins and quietly refuses overtime.")
		end
	end)
end

function InteractionService:_wireBowlingBallReturn(ballReturn)
	local prompt = getPrompt(ballReturn)
	local laneIndex = ballReturn:GetAttribute("LaneIndex")

	self:_connectPrompt(prompt, function(player)
		self.discoveryService:Unlock(player, Constants.Discoveries.BowlingBallReturn.Id)
		self:_clearBowlingBalls(laneIndex)
		playSound(ballReturn, "rbxasset://sounds/button.wav", 0.45, 0.72)
		task.delay(0.1, function()
			playSound(ballReturn, "rbxasset://sounds/electronicpingshort.wav", 0.35, 1.45)
		end)

		if laneIndex then
			self.systemMessageRemote:FireClient(player, ("Lane %d ball return politely removes the evidence."):format(laneIndex))
		else
			self.systemMessageRemote:FireClient(player, "The ball return hums like it knows where the missing balls went.")
		end
	end)
end

function InteractionService:_wireTreetopZipline(zipline)
	local prompt = getPrompt(zipline)

	self:_connectPrompt(prompt, function(player)
		if self.treetopZiplineStateByUserId[player.UserId] then
			return
		end

		local rootPart = getRootPart(player)
		if not rootPart then
			return
		end

		self.treetopZiplineStateByUserId[player.UserId] = true
		self.discoveryService:Unlock(player, Constants.Discoveries.ReachedIsland.Id)
		self.systemMessageRemote:FireClient(player, "The zipline accepts your island-bound paperwork.")
		playSound(zipline, "rbxasset://sounds/electronicpingshort.wav", 0.55, 1.35)

		local humanoid = getHumanoid(player)
		local previousAutoRotate = humanoid and humanoid.AutoRotate
		local previousAnchored = rootPart.Anchored
		local startCFrame = zipline:GetAttribute("StartCFrame")
		local endCFrame = zipline:GetAttribute("EndCFrame")
		local startPosition = (typeof(startCFrame) == "CFrame" and startCFrame.Position) or rootPart.Position
		local endPosition = (typeof(endCFrame) == "CFrame" and endCFrame.Position) or Constants.GetRoomSpawnCFrame("Island").Position
		local finalCFrame = typeof(endCFrame) == "CFrame" and endCFrame or Constants.GetRoomSpawnCFrame("Island")

		if humanoid then
			humanoid.AutoRotate = false
		end
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
		rootPart.Anchored = true

		for step = 0, 66 do
			if not player.Parent or not rootPart.Parent then
				break
			end

			local alpha = step / 66
			local eased = 1 - (1 - alpha) * (1 - alpha)
			local arc = math.sin(math.pi * alpha) * 5
			local position = startPosition:Lerp(endPosition, eased) + Vector3.new(0, arc, 0)
			rootPart.CFrame = CFrame.new(position, endPosition)
			task.wait(1 / 30)
		end

		if rootPart.Parent then
			rootPart.Anchored = previousAnchored
			rootPart.AssemblyLinearVelocity = Vector3.zero
			rootPart.AssemblyAngularVelocity = Vector3.zero
			teleportPlayer(player, finalCFrame)
		end

		if humanoid and humanoid.Parent then
			humanoid.AutoRotate = previousAutoRotate
		end

		self.systemMessageRemote:FireClient(player, "The island receives you with unnecessary confidence.")
		task.delay(1.2, function()
			self.treetopZiplineStateByUserId[player.UserId] = nil
		end)
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

		self:ResetRoomForPlayer(player)
	end)
end

function InteractionService:ResetRoomForPlayer(player)
	self:_clearAllTelevisions()
	for _, state in pairs(self.snackFanState) do
		state.SpinToken = nil
	end
	self:_stopSnackFlightForRoom(player)
	self.eventManager:ResetRoom(player)
	self:AfterRoomReset()
end

function InteractionService:_afterRoomReset()
	self.bowlingCosmicActive = false
	self.bowlingCosmicToken = {}
	self:_setBowlingCosmicFog(false)
	self:_updateBowlingLaserBeams(0, false)

	for _, state in pairs(self.libraryLampState) do
		state.On = false
	end

	for _, state in pairs(self.libraryGlobeState) do
		state.Reacting = false
	end

	for _, state in pairs(self.libraryLadderState) do
		state.Moved = false
		state.Reacting = false
	end

	for _, state in pairs(self.libraryLoftDoorState) do
		state.Reacting = false
	end

	for _, state in pairs(self.libraryBookcaseState) do
		state.Reacting = false
	end

	for _, state in pairs(self.bowlingLaneState) do
		state.Reacting = false
	end
	for laneIndex = 1, 3 do
		self.bowlingLaneCounts[laneIndex] = 0
	end
	self:_updateBowlingScoreboards()
	self:_resetBowlingPins()

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

	self.islandWoodCountByUserId = {}
	for _, state in pairs(self.islandCoconutState) do
		state.Reacting = false
		state.CrabStarted = false
		state.SeagullsStarted = false
	end

	for _, state in pairs(self.islandCoconutTreeState) do
		state.Reacting = false
		state.Dropped = false
	end

	for _, state in pairs(self.islandScrapWoodState) do
		state.Collected = false
		state.Reacting = false
	end

	for fireRing, state in pairs(self.islandFireRingState) do
		state.Deposited = 0
		state.Burning = false
		state.Smoking = false
		state.Token = nil
		if fireRing and fireRing.Parent then
			self:_setIslandFireEmitters(fireRing, false, false)
			self:_setIslandFireWoodVisible(fireRing, 0)
			local prompt = getPrompt(fireRing)
			if prompt then
				prompt.ActionText = "Add Wood"
				prompt.ObjectText = "Rock Ring"
			end
		end
	end

	for block, state in pairs(self.islandSkyBlockState) do
		state.Revealed = false
		state.Reacting = false
		if block and block.Parent then
			self:_setIslandSkyBlockVisible(block, false)
		end
	end

	for ladder, state in pairs(self.islandSpaceLadderState) do
		state.Grown = false
		state.Growing = false
		state.TransportingByUserId = {}
		if ladder and ladder.Parent then
			self:_setIslandSpaceLadderVisible(ladder, false)
		end
	end

	for _, state in pairs(self.spaceStationState) do
		state.Reacting = false
	end
end

function InteractionService:RefreshProgressDrivenWorld()
	for _, currentPlayer in ipairs(Players:GetPlayers()) do
		self:_checkExitUnlock(currentPlayer)
		self:_refreshSecretDoorsForPlayer(currentPlayer)
	end
end

function InteractionService:AfterRoomReset()
	self:_afterRoomReset()
	self:RefreshProgressDrivenWorld()
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

	self.systemMessageRemote:FireAllClients("Snack Lab flight mode is live. Keyboard: Space climbs, Shift/Ctrl descends. Xbox: A climbs, B or X descends. iOS: tap UP/DOWN; thumbstick steers.")
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
	local interiorDetails = fridge:FindFirstChild("FridgeInteriorDetails", true)
	local iceCube = fridge:FindFirstChild("ColdIdeaIceCube", true)
	local pizzaModel = fridge:FindFirstChild("FridgePizza", true)
	local colaModel = fridge:FindFirstChild("FridgeBloxyCola", true)
	local pizza = fridge:FindFirstChild("PizzaSlice", true)
	local cola = fridge:FindFirstChild("BloxyColaCan", true)
	local secretButton = fridge:FindFirstChild("SecretFridgeButton", true)

	setFridgeContentVisible(interiorDetails, opened)
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
		local userState = self.islandWarningReadStateByUserId[player.UserId]
		if not userState then
			userState = {}
			self.islandWarningReadStateByUserId[player.UserId] = userState
		end

		local readCount = (userState[discoveryId] or 0) + 1
		userState[discoveryId] = readCount

		if discoveryId == Constants.Discoveries.ReadSharkWarning.Id and readCount >= 3 then
			userState[discoveryId] = 0
			self:_spawnIslandSharkFin(sign)
			self.systemMessageRemote:FireClient(player, "The shark warning proves it has supporting evidence.")
		elseif discoveryId == Constants.Discoveries.ReadJellyfishWarning.Id and readCount >= 3 then
			userState[discoveryId] = 0
			self:_spawnIslandJellyfishBalloon(sign)
			self.systemMessageRemote:FireClient(player, "The jellyfish warning floats into the minutes.")
		else
			self.systemMessageRemote:FireClient(player, ("%s (%d/3)"):format(message, readCount))
		end
	end)
end

function InteractionService:_spawnIslandSharkFin(source)
	local sourcePosition = source:IsA("BasePart") and source.Position or Constants.GetRoomSpawnCFrame("Island").Position
	local origin = Vector3.new(24, 0.22, math.clamp(sourcePosition.Z - 1.5, 137, 148))
	local finModel = Instance.new("Model")
	finModel.Name = "IslandSharkFinWarning"
	finModel.Parent = workspace
	CollectionService:AddTag(finModel, Constants.Tags.TemporaryObject)

	local function makeFinPart(name, size, cframe, color, material, className)
		local part = Instance.new(className or "Part")
		part.Name = name
		part.Anchored = true
		part.CanCollide = false
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.TopSurface = Enum.SurfaceType.Smooth
		part.Size = size
		part.CFrame = cframe
		part.Color = color
		part.Material = material or Enum.Material.SmoothPlastic
		part.Parent = finModel
		return part
	end

	local travel = Vector3.new(-20, 0, 14)
	local startCFrame = CFrame.new(origin + Vector3.new(5, 0, -8), origin + Vector3.new(-13, 0, 8))
	local fin = makeFinPart("WarningFin", Vector3.new(2.4, 3.6, 0.75), startCFrame * CFrame.Angles(0, 0, math.rad(-8)), Color3.fromRGB(47, 61, 73), Enum.Material.SmoothPlastic, "WedgePart")
	local wakeA = makeFinPart("WakeA", Vector3.new(4.6, 0.16, 0.5), startCFrame * CFrame.new(-1.8, -1.0, 0.55), Color3.fromRGB(180, 242, 255), Enum.Material.Neon)
	local wakeB = makeFinPart("WakeB", Vector3.new(4.6, 0.16, 0.5), startCFrame * CFrame.new(-1.8, -1.0, -0.55), Color3.fromRGB(180, 242, 255), Enum.Material.Neon)
	wakeA.Transparency = 0.2
	wakeB.Transparency = 0.2

	playSound(source, "rbxasset://sounds/electronicpingshort.wav", 0.5, 0.36)
	for _, part in ipairs(finModel:GetChildren()) do
		if part:IsA("BasePart") then
			tweenPart(part, 3.4, {
				CFrame = part.CFrame + travel,
			}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		end
	end
	task.delay(2.65, function()
		if fin.Parent then
			tweenPart(fin, 0.45, { Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			tweenPart(wakeA, 0.45, { Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			tweenPart(wakeB, 0.45, { Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		end
	end)
	Debris:AddItem(finModel, 4)
end

function InteractionService:_spawnIslandJellyfishBalloon(source)
	local sourcePosition = source:IsA("BasePart") and source.Position or Constants.GetRoomSpawnCFrame("Island").Position
	local startZ = math.clamp(sourcePosition.Z + 2, 142, 164)
	local start = Vector3.new(29, 12.5, startZ + 8)
	local finish = Vector3.new(-29, 9.5, startZ)
	local jellyModel = Instance.new("Model")
	jellyModel.Name = "IslandJellyfishBalloon"
	jellyModel.Parent = workspace
	CollectionService:AddTag(jellyModel, Constants.Tags.TemporaryObject)

	local function makeJellyPart(name, size, cframe, color, material, shape)
		local part = Instance.new("Part")
		part.Name = name
		part.Anchored = true
		part.CanCollide = false
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.TopSurface = Enum.SurfaceType.Smooth
		part.Size = size
		part.CFrame = cframe
		part.Color = color
		part.Material = material or Enum.Material.SmoothPlastic
		if shape then
			part.Shape = shape
		end
		part.Parent = jellyModel
		return part
	end

	local baseCFrame = CFrame.new(start, finish)
	local animatedParts = {}

	local function track(part, offset, kind, index, segment)
		table.insert(animatedParts, {
			Part = part,
			Offset = offset,
			Kind = kind,
			Index = index or 0,
			Segment = segment or 0,
		})
	end

	local bell = makeJellyPart("JellyfishBell", Vector3.new(3.1, 1.72, 3.1), baseCFrame, Color3.fromRGB(255, 142, 216), Enum.Material.Glass, Enum.PartType.Ball)
	bell.Transparency = 0.22
	track(bell, Vector3.new(0, 0.35, 0), "bell")

	local underside = makeJellyPart("JellyfishGlowBelly", Vector3.new(2.2, 0.36, 2.2), baseCFrame * CFrame.new(0, -0.55, 0), Color3.fromRGB(255, 205, 240), Enum.Material.Neon, Enum.PartType.Ball)
	underside.Transparency = 0.35
	track(underside, Vector3.new(0, -0.55, 0), "bell")

	local glow = Instance.new("PointLight")
	glow.Name = "JellyfishGlow"
	glow.Brightness = 2
	glow.Color = Color3.fromRGB(255, 142, 216)
	glow.Range = 14
	glow.Parent = bell

	local trail = Instance.new("ParticleEmitter")
	trail.Name = "JellyfishMistTrail"
	trail.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	trail.Rate = 18
	trail.Lifetime = NumberRange.new(0.45, 0.9)
	trail.Speed = NumberRange.new(0.45, 1.25)
	trail.SpreadAngle = Vector2.new(20, 20)
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 205, 240), Color3.fromRGB(137, 225, 255))
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.18),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Parent = bell

	for tentacleIndex = 1, 8 do
		local angle = (tentacleIndex - 1) * math.pi * 2 / 8
		local rootX = math.cos(angle) * 0.34
		local rootZ = math.sin(angle) * 0.34

		for segment = 1, 3 do
			local length = 0.86 + segment * 0.2 + (tentacleIndex % 2) * 0.12
			local offset = Vector3.new(rootX, -0.92 - segment * 0.62, rootZ)
			local tentacle = makeJellyPart(
				("JellyfishTentacle%d_%d"):format(tentacleIndex, segment),
				Vector3.new(0.13, length, 0.13),
				baseCFrame * CFrame.new(offset),
				Color3.fromRGB(255, 205, 240),
				Enum.Material.Neon
			)
			tentacle.Transparency = 0.08 + segment * 0.05
			track(tentacle, offset, "tentacle", tentacleIndex, segment)
		end
	end

	playSound(source, "rbxasset://sounds/electronicpingshort.wav", 0.45, 1.65)

	task.spawn(function()
		local startedAt = os.clock()
		local duration = 5.2
		while jellyModel.Parent do
			local elapsed = os.clock() - startedAt
			local alpha = math.clamp(elapsed / duration, 0, 1)
			local easedAlpha = 0.5 - math.cos(alpha * math.pi) * 0.5
			local position = start:Lerp(finish, easedAlpha)
			local bob = math.sin(elapsed * 4.2) * 0.22
			local base = CFrame.new(position + Vector3.new(0, bob, 0), position + (finish - start))
				* CFrame.Angles(0, 0, math.sin(elapsed * 2.1) * 0.08)

			for _, item in ipairs(animatedParts) do
				local part = item.Part
				if part and part.Parent then
					local sway = math.sin(elapsed * (4.1 + item.Segment * 0.55) + item.Index * 0.8) * (0.1 + item.Segment * 0.1)
					local sideSway = math.cos(elapsed * 3.2 + item.Index * 0.7) * (0.05 + item.Segment * 0.04)
					local offset = item.Offset + Vector3.new(sway, 0, sideSway)
					local partCFrame = base * CFrame.new(offset)
					if item.Kind == "tentacle" then
						partCFrame = partCFrame
							* CFrame.Angles(math.sin(elapsed * 4 + item.Index) * 0.22, 0, math.cos(elapsed * 3.4 + item.Segment) * 0.2)
					end
					part.CFrame = partCFrame
				end
			end

			if alpha >= 1 then
				break
			end

			RunService.Heartbeat:Wait()
		end
	end)

	task.delay(4.2, function()
		if trail.Parent then
			trail.Enabled = false
		end
		for _, part in ipairs(jellyModel:GetChildren()) do
			if part:IsA("BasePart") then
				tweenPart(part, 0.65, { Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end
		end
	end)
	Debris:AddItem(jellyModel, 6)
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
	local sharkModel = Instance.new("Model")
	sharkModel.Name = "IslandExitSharkAttack"
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

	local attackPoint = Vector3.new(20, 2.0, 142.5)
	local targetCFrame = CFrame.new(attackPoint, Vector3.new(0, 2.0, 150)) * CFrame.Angles(0, math.rad(90), 0)
	local baseCFrame = targetCFrame * CFrame.new(0, -4.8, 11)
	local body = makeSharkPart("SharkBody", "Part", Vector3.new(4.1, 3.2, 11.5), baseCFrame, Color3.fromRGB(89, 103, 116))
	body.Shape = Enum.PartType.Ball
	makeSharkPart("SharkFin", "WedgePart", Vector3.new(2.6, 3.6, 1.6), baseCFrame * CFrame.new(0, 2.2, 0.55), Color3.fromRGB(55, 67, 78))
	makeSharkPart("SharkTail", "WedgePart", Vector3.new(4.2, 3.4, 1.5), baseCFrame * CFrame.new(0, 0.05, 5.5) * CFrame.Angles(0, math.rad(180), 0), Color3.fromRGB(55, 67, 78))
	makeSharkPart("SharkSnout", "WedgePart", Vector3.new(4.6, 2.1, 3.2), baseCFrame * CFrame.new(0, 0.1, -4.4), Color3.fromRGB(104, 121, 134))
	local upperMouth = makeSharkPart("SharkUpperMouth", "WedgePart", Vector3.new(5.1, 1.05, 2.7), baseCFrame * CFrame.new(0, -0.35, -5.8) * CFrame.Angles(math.rad(180), 0, 0), Color3.fromRGB(41, 42, 47))
	local lowerMouth = makeSharkPart("SharkLowerMouth", "WedgePart", Vector3.new(5.1, 0.85, 2.4), baseCFrame * CFrame.new(0, -1.25, -5.58), Color3.fromRGB(33, 34, 39))
	local gum = makeSharkPart("SharkMouthGlow", "Part", Vector3.new(4.6, 0.12, 1.85), baseCFrame * CFrame.new(0, -0.95, -6.2), Color3.fromRGB(190, 41, 56))
	gum.Material = Enum.Material.Neon

	for sideIndex, sideX in ipairs({ -1.85, -1.25, -0.65, 0, 0.65, 1.25, 1.85 }) do
		local topTooth = makeSharkPart("TopTooth" .. sideIndex, "WedgePart", Vector3.new(0.34, 0.9, 0.34), baseCFrame * CFrame.new(sideX, -0.82, -6.9) * CFrame.Angles(math.rad(180), 0, 0), Color3.fromRGB(255, 255, 239))
		local bottomTooth = makeSharkPart("BottomTooth" .. sideIndex, "WedgePart", Vector3.new(0.34, 0.72, 0.34), baseCFrame * CFrame.new(sideX, -1.08, -6.55), Color3.fromRGB(255, 255, 239))
		topTooth.Material = Enum.Material.SmoothPlastic
		bottomTooth.Material = Enum.Material.SmoothPlastic
	end

	local leftEye = makeSharkPart("SharkLeftEye", "Part", Vector3.new(0.48, 0.48, 0.48), baseCFrame * CFrame.new(-1.75, 0.72, -3.95), Color3.fromRGB(255, 255, 245))
	local rightEye = makeSharkPart("SharkRightEye", "Part", Vector3.new(0.48, 0.48, 0.48), baseCFrame * CFrame.new(1.75, 0.72, -3.95), Color3.fromRGB(255, 255, 245))
	leftEye.Shape = Enum.PartType.Ball
	rightEye.Shape = Enum.PartType.Ball
	local leftPupil = makeSharkPart("LeftPupil", "Part", Vector3.new(0.18, 0.18, 0.18), baseCFrame * CFrame.new(-1.75, 0.75, -4.24), Color3.fromRGB(6, 8, 12))
	local rightPupil = makeSharkPart("RightPupil", "Part", Vector3.new(0.18, 0.18, 0.18), baseCFrame * CFrame.new(1.75, 0.75, -4.24), Color3.fromRGB(6, 8, 12))
	leftPupil.Shape = Enum.PartType.Ball
	rightPupil.Shape = Enum.PartType.Ball
	local wake = makeSharkPart("SharkWake", "Part", Vector3.new(5.8, 0.18, 14), baseCFrame * CFrame.new(0, -1.7, 1.8), Color3.fromRGB(175, 240, 255))
	wake.Material = Enum.Material.Neon
	wake.Transparency = 0.35

	playSound(exitGate, "rbxasset://sounds/snap.wav", 0.8, 0.72)
	playSound(exitGate, "rbxasset://sounds/electronicpingshort.wav", 0.75, 0.32)

	for _, part in ipairs(sharkModel:GetChildren()) do
		if part:IsA("BasePart") then
			tweenPart(part, 0.34, {
				CFrame = targetCFrame * baseCFrame:ToObjectSpace(part.CFrame),
			}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end
	end

	task.delay(0.38, function()
		if upperMouth.Parent and lowerMouth.Parent then
			tweenPart(upperMouth, 0.16, { CFrame = upperMouth.CFrame * CFrame.Angles(math.rad(-15), 0, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			tweenPart(lowerMouth, 0.16, { CFrame = lowerMouth.CFrame * CFrame.Angles(math.rad(13), 0, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			playSound(exitGate, "rbxasset://sounds/snap.wav", 0.95, 0.48)
		end
	end)

	if rootPart then
		local destination = CFrame.new(Vector3.new(0, 3, 154), Vector3.new(0, 3, 166))
		local pushDirection = (destination.Position - rootPart.Position)
		if pushDirection.Magnitude < 1 then
			pushDirection = Vector3.new(0, 0, 1)
		else
			pushDirection = pushDirection.Unit
		end
		rootPart.AssemblyLinearVelocity = pushDirection * 88 + Vector3.new(0, 38, 0)
		task.delay(0.28, function()
			if rootPart.Parent then
				rootPart.CFrame = destination
				rootPart.AssemblyLinearVelocity = Vector3.new(0, 18, 0)
			end
		end)
	end

	task.delay(1.6, function()
		for _, part in ipairs(sharkModel:GetChildren()) do
			if part:IsA("BasePart") then
				tweenPart(part, 0.65, { Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end
		end
	end)
	Debris:AddItem(sharkModel, 2.6)
end

function InteractionService:_wireIslandExit(exitGate)
	local prompt = getPrompt(exitGate)
	local exitMode = exitGate:GetAttribute("ExitMode") or "Ocean"

	local function returnToHallway(player)
		if not player or not player.Parent then
			return
		end

		self.islandExitWarningsByUserId[player.UserId] = nil
		local destinationCFrame = exitGate:GetAttribute("DestinationCFrame") or Constants.Hallway.SpawnCFrame
		teleportPlayer(player, destinationCFrame)
		self.systemMessageRemote:FireClient(player, "The island lets you return to the hallway.")
	end

	local function attemptOceanExit(player)
		if not player or not player.Parent then
			return
		end

		local now = os.clock()
		if now - (self.islandExitBounceAtByUserId[player.UserId] or 0) < 0.8 then
			return
		end

		self.islandExitBounceAtByUserId[player.UserId] = now
		local warningCount = (self.islandExitWarningsByUserId[player.UserId] or 0) + 1
		self.islandExitWarningsByUserId[player.UserId] = warningCount
		local requiredCount = self:_getIslandExitRequiredCount()
		local currentCount = self.discoveryService:GetRoomDiscoveryCount(player, "Island")

		if warningCount < 3 then
			local remainingWarnings = 3 - warningCount
			self.systemMessageRemote:FireClient(
				player,
				("Ocean warning %d/3: swim lessons are not included. Island discoveries: %d / %d."):format(
					warningCount,
					currentCount,
					requiredCount
				)
			)
			if remainingWarnings == 1 then
				playSound(exitGate, "rbxasset://sounds/electronicpingshort.wav", 0.55, 0.45)
			else
				playSound(exitGate, "rbxasset://sounds/button.wav", 0.45, 0.6)
			end
			return
		end

		self.islandExitWarningsByUserId[player.UserId] = 0
		self.discoveryService:Unlock(player, Constants.Discoveries.SharkBounce.Id)
		self:_spawnIslandShark(exitGate, player)
		self.systemMessageRemote:FireClient(player, "Third ocean warning: the land shark disagrees with your travel plan.")
	end

	if exitMode == "Door" then
		self:_connectPrompt(prompt, returnToHallway)
		return
	end

	if exitGate:IsA("BasePart") and not self.islandExitTouchConnections[exitGate] then
		self.islandExitTouchConnections[exitGate] = exitGate.Touched:Connect(function(hit)
			local character = hit:FindFirstAncestorOfClass("Model")
			local player = character and Players:GetPlayerFromCharacter(character)
			if player then
				attemptOceanExit(player)
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
			local shovelModel = shovel:FindFirstAncestor("IslandShovel")
			local shovelParts = {}
			local basePivot = shovelModel and shovelModel:GetPivot() or shovel.CFrame

			if shovelModel then
				for _, descendant in ipairs(shovelModel:GetDescendants()) do
					if descendant:IsA("BasePart") then
						table.insert(shovelParts, descendant)
					end
				end
			else
				table.insert(shovelParts, shovel)
			end

			local digTween = nil
			local targetPivot = basePivot * CFrame.Angles(0, 0, math.rad(-20))
			for _, part in ipairs(shovelParts) do
				local baseCFrame = part:GetAttribute("BaseCFrame") or part.CFrame
				digTween = tweenPart(part, 0.16, {
					CFrame = targetPivot * basePivot:ToObjectSpace(baseCFrame),
				}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			end

			if digTween then
				digTween.Completed:Wait()
			end

			for _, part in ipairs(shovelParts) do
				tweenPart(part, 0.18, {
					CFrame = part:GetAttribute("BaseCFrame") or part.CFrame,
				}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			end
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

function InteractionService:_getCoconutParts(coconut)
	if not coconut or not coconut.Parent then
		return {}
	end

	local parts = {}
	local prefix = coconut.Name
	for _, instance in ipairs(coconut.Parent:GetChildren()) do
		if instance:IsA("BasePart") and (instance == coconut or instance.Name:sub(1, #prefix) == prefix) then
			table.insert(parts, instance)
		end
	end

	return parts
end

function InteractionService:_setCoconutVisible(coconut, visible)
	for _, part in ipairs(self:_getCoconutParts(coconut)) do
		part.Transparency = visible and 0 or 1
		part.CanCollide = visible and part == coconut
	end

	setPromptEnabled(coconut, visible)
end

function InteractionService:_findIslandCoconutById(coconutId)
	for _, coconut in ipairs(CollectionService:GetTagged(Constants.Tags.IslandCoconut)) do
		if coconut:IsA("BasePart") and coconut:GetAttribute("CoconutId") == coconutId then
			return coconut
		end
	end

	return nil
end

function InteractionService:_spawnIslandCoconutCrab(coconut)
	local start = coconut.Position + Vector3.new(0, -0.16, 0)
	local targetCoconut = self:_findIslandCoconutById("quiet_coconut") or self:_findIslandCoconutById("dropped_palm_coconut")
	local finish = targetCoconut and targetCoconut.Position + Vector3.new(0, -0.2, 0) or (start + Vector3.new(4.5, 0, 0.6))
	local crab = Instance.new("Model")
	crab.Name = "IslandCoconutCrab"
	crab.Parent = workspace
	CollectionService:AddTag(crab, Constants.Tags.TemporaryObject)

	local function makeCrabPart(name, size, cframe, color, material, shape)
		local part = Instance.new("Part")
		part.Name = name
		part.Anchored = true
		part.CanCollide = false
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.TopSurface = Enum.SurfaceType.Smooth
		part.Size = size
		part.CFrame = cframe
		part.Color = color
		part.Material = material or Enum.Material.SmoothPlastic
		if shape then
			part.Shape = shape
		end
		part.Parent = crab
		return part
	end

	local direction = finish - start
	if direction.Magnitude < 1 then
		direction = Vector3.new(1, 0, 0)
	end

	local baseCFrame = CFrame.new(start + Vector3.new(0, 0.24, 0), start + direction)
	local body = makeCrabPart("CrabBody", Vector3.new(1.35, 0.48, 0.96), baseCFrame, Color3.fromRGB(181, 82, 41), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	body:SetAttribute("CrabOffset", body.CFrame)
	crab.PrimaryPart = body
	makeCrabPart("CrabFrontShell", Vector3.new(0.64, 0.32, 0.72), baseCFrame * CFrame.new(0.48, 0.02, 0), Color3.fromRGB(220, 104, 52), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	makeCrabPart("CrabLeftClaw", Vector3.new(0.46, 0.3, 0.58), baseCFrame * CFrame.new(0.88, 0.04, -0.48) * CFrame.Angles(0, math.rad(16), math.rad(18)), Color3.fromRGB(225, 105, 50), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	makeCrabPart("CrabRightClaw", Vector3.new(0.46, 0.3, 0.58), baseCFrame * CFrame.new(0.88, 0.04, 0.48) * CFrame.Angles(0, math.rad(-16), math.rad(-18)), Color3.fromRGB(225, 105, 50), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	makeCrabPart("CrabLeftEyeStem", Vector3.new(0.08, 0.28, 0.08), baseCFrame * CFrame.new(0.35, 0.34, -0.22), Color3.fromRGB(120, 48, 28), Enum.Material.SmoothPlastic)
	makeCrabPart("CrabRightEyeStem", Vector3.new(0.08, 0.28, 0.08), baseCFrame * CFrame.new(0.35, 0.34, 0.22), Color3.fromRGB(120, 48, 28), Enum.Material.SmoothPlastic)
	makeCrabPart("CrabLeftEye", Vector3.new(0.17, 0.17, 0.17), baseCFrame * CFrame.new(0.35, 0.52, -0.22), Color3.fromRGB(12, 12, 14), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	makeCrabPart("CrabRightEye", Vector3.new(0.17, 0.17, 0.17), baseCFrame * CFrame.new(0.35, 0.52, 0.22), Color3.fromRGB(12, 12, 14), Enum.Material.SmoothPlastic, Enum.PartType.Ball)

	for sideIndex, sideZ in ipairs({ -0.46, -0.25, 0.25, 0.46 }) do
		local side = sideZ < 0 and -1 or 1
		local leg = makeCrabPart(
			"CrabLeg" .. sideIndex,
			Vector3.new(0.72, 0.12, 0.12),
			baseCFrame * CFrame.new(-0.12, -0.1, sideZ) * CFrame.Angles(0, 0, math.rad(20 * side)),
			Color3.fromRGB(194, 86, 42),
			Enum.Material.SmoothPlastic
		)
		leg:SetAttribute("LegSide", side)
	end

	playSound(coconut, "rbxasset://sounds/snap.wav", 0.42, 1.35)
	if coconut:IsA("BasePart") then
		local base = coconut:GetAttribute("BaseCFrame") or coconut.CFrame
		tweenPart(coconut, 0.14, {
			CFrame = base + Vector3.new(0, 0.65, 0),
		}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		task.delay(0.36, function()
			if coconut.Parent then
				tweenPart(coconut, 0.16, { CFrame = base }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end
			end)
		end

	task.spawn(function()
		for step = 1, 4 do
			if not crab.Parent then
				return
			end

			local alpha = step / 4
			local stepPosition = start:Lerp(finish, alpha) + Vector3.new(0, math.sin(step * math.pi) * 0.18, math.sin(step * 1.3) * 0.35)
			local nextPosition = start:Lerp(finish, math.min(1, alpha + 0.16))
			local stepCFrame = CFrame.new(stepPosition + Vector3.new(0, 0.24, 0), nextPosition + Vector3.new(0, 0.24, 0))
			for _, part in ipairs(crab:GetChildren()) do
				if part:IsA("BasePart") and part:GetAttribute("LegSide") then
					local legSide = part:GetAttribute("LegSide")
					tweenPart(part, 0.12, {
						CFrame = part.CFrame * CFrame.Angles(0, 0, math.rad(18 * legSide * ((step % 2 == 0) and 1 or -1))),
					}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
				end
			end
			tweenModel(crab, stepCFrame, 0.24)
		end

		if targetCoconut and targetCoconut.Parent then
			local targetBase = targetCoconut:GetAttribute("BaseCFrame") or targetCoconut.CFrame
			tweenPart(targetCoconut, 0.14, {
				CFrame = targetBase + Vector3.new(0, 0.48, 0),
			}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			task.delay(0.28, function()
				if targetCoconut.Parent then
					tweenPart(targetCoconut, 0.16, { CFrame = targetBase }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				end
			end)
		end

		for _, part in ipairs(crab:GetChildren()) do
			if part:IsA("BasePart") then
				tweenPart(part, 0.42, { Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end
		end
	end)
	Debris:AddItem(crab, 3.2)
end

function InteractionService:_spawnIslandSeagulls(source)
	local sourcePosition = source:IsA("BasePart") and source.Position or Constants.GetRoomSpawnCFrame("Island").Position
	local flock = Instance.new("Model")
	flock.Name = "IslandSeagullFlock"
	flock.Parent = workspace
	CollectionService:AddTag(flock, Constants.Tags.TemporaryObject)

	local function makeGullPart(name, size, cframe, color, material, shape)
		local part = Instance.new("Part")
		part.Name = name
		part.Anchored = true
		part.CanCollide = false
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.TopSurface = Enum.SurfaceType.Smooth
		part.Size = size
		part.CFrame = cframe
		part.Color = color
		part.Material = material or Enum.Material.SmoothPlastic
		if shape then
			part.Shape = shape
		end
		part.Parent = flock
		return part
	end

	playSound(source, "rbxasset://sounds/electronicpingshort.wav", 0.4, 2.15)
	playSound(source, "rbxasset://sounds/electronicpingshort.wav", 0.32, 1.75)

	for gullIndex = 1, 4 do
		local start = sourcePosition + Vector3.new(-31 - gullIndex * 2.2, 14 + gullIndex * 0.55, -3 + gullIndex * 1.7)
		local finish = sourcePosition + Vector3.new(32, 17 + math.sin(gullIndex) * 1.2, -8 + gullIndex * 1.15)
		local baseCFrame = CFrame.new(start, finish)
		local body = makeGullPart("SeagullBody" .. gullIndex, Vector3.new(1.0, 0.32, 0.42), baseCFrame, Color3.fromRGB(245, 246, 238), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		local leftWing = makeGullPart("SeagullLeftWing" .. gullIndex, Vector3.new(1.15, 0.12, 0.42), baseCFrame * CFrame.new(-0.58, 0.02, 0) * CFrame.Angles(0, 0, math.rad(18)), Color3.fromRGB(235, 238, 232), Enum.Material.SmoothPlastic)
		local rightWing = makeGullPart("SeagullRightWing" .. gullIndex, Vector3.new(1.15, 0.12, 0.42), baseCFrame * CFrame.new(0.58, 0.02, 0) * CFrame.Angles(0, 0, math.rad(-18)), Color3.fromRGB(235, 238, 232), Enum.Material.SmoothPlastic)
		local beak = makeGullPart("SeagullBeak" .. gullIndex, Vector3.new(0.32, 0.14, 0.14), baseCFrame * CFrame.new(0, 0, -0.42), Color3.fromRGB(255, 204, 65), Enum.Material.SmoothPlastic)

		task.delay((gullIndex - 1) * 0.18, function()
			for _, part in ipairs({ body, leftWing, rightWing, beak }) do
				if part and part.Parent then
					local offset = baseCFrame:ToObjectSpace(part.CFrame)
					tweenPart(part, 4.2, {
						CFrame = CFrame.new(finish, finish + (finish - start)) * offset,
					}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
				end
			end
		end)
	end

	task.delay(4.4, function()
		for _, part in ipairs(flock:GetChildren()) do
			if part:IsA("BasePart") then
				tweenPart(part, 0.55, { Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end
		end
	end)
	Debris:AddItem(flock, 5.3)
end

function InteractionService:_wireIslandCoconut(coconut)
	local prompt = getPrompt(coconut)

	self.islandCoconutState[coconut] = self.islandCoconutState[coconut] or {
		Reacting = false,
		CrabStarted = false,
		SeagullsStarted = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.islandCoconutState[coconut]
		if not state or state.Reacting then
			return
		end

		state.Reacting = true
		if coconut:GetAttribute("StartsCrab") and not state.CrabStarted then
			state.CrabStarted = true
			self.discoveryService:Unlock(player, Constants.Discoveries.IslandCoconutCrab.Id)
			self:_spawnIslandCoconutCrab(coconut)
			self.systemMessageRemote:FireClient(player, "The coconut was occupied. Briefly.")
		elseif coconut:GetAttribute("StartsSeagulls") and not state.SeagullsStarted then
			state.SeagullsStarted = true
			self.discoveryService:Unlock(player, Constants.Discoveries.IslandSeagulls.Id)
			self:_spawnIslandSeagulls(coconut)
			self.systemMessageRemote:FireClient(player, "The coconut was empty, so the sky filled in the paperwork.")
		else
			playSound(coconut, "rbxasset://sounds/button.wav", 0.28, 0.62)
			self.systemMessageRemote:FireClient(player, "The coconut sounds hollow, which is exactly what a coconut would say.")
		end

		task.wait(0.2)
		state.Reacting = false
	end)
end

function InteractionService:_wireIslandCoconutTree(treePart)
	local prompt = getPrompt(treePart)

	self.islandCoconutTreeState[treePart] = self.islandCoconutTreeState[treePart] or {
		Reacting = false,
		Dropped = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.islandCoconutTreeState[treePart]
		if not state or state.Reacting then
			return
		end

		if state.Dropped then
			self.systemMessageRemote:FireClient(player, "The palm tree has already contributed one coconut to science.")
			return
		end

		state.Reacting = true
		state.Dropped = true
		local dropId = treePart:GetAttribute("DropCoconutId")
		local droppedCoconut = dropId and self:_findIslandCoconutById(dropId)

		for _, part in ipairs(treePart.Parent and treePart.Parent:GetDescendants() or {}) do
			if part:IsA("BasePart") and part:GetAttribute("DropsWithCoconutId") == dropId then
				tweenPart(part, 0.28, {
					Transparency = 1,
					CFrame = part.CFrame + Vector3.new(0, -2.2, 0),
				}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				part.CanCollide = false
			end
		end

		if droppedCoconut then
			self:_setCoconutVisible(droppedCoconut, true)
			for _, coconutPart in ipairs(self:_getCoconutParts(droppedCoconut)) do
				local base = coconutPart:GetAttribute("BaseCFrame") or coconutPart.CFrame
				coconutPart.CFrame = base + Vector3.new(0, 3.2, 0)
				tweenPart(coconutPart, 0.36, { CFrame = base }, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
			end
		end

		self.discoveryService:Unlock(player, Constants.Discoveries.IslandDroppedCoconut.Id)
		playSound(treePart, "rbxasset://sounds/snap.wav", 0.46, 0.74)
		self.systemMessageRemote:FireClient(player, "A coconut drops with the confidence of gravity.")
		task.wait(0.24)
		state.Reacting = false
	end)
end

function InteractionService:_setIslandSkyBlockVisible(block, visible)
	if not block or not block.Parent then
		return
	end

	block.Transparency = visible and 0 or 1
	block.CanCollide = true
	setPromptEnabled(block, visible)
	for _, instance in ipairs(block:GetDescendants()) do
		if instance:IsA("SurfaceGui") then
			instance.Enabled = visible
		end
	end
end

function InteractionService:_findIslandSpaceLadder(blockId)
	for _, ladder in ipairs(CollectionService:GetTagged(Constants.Tags.IslandSpaceLadder)) do
		if ladder:IsA("BasePart") and ladder:GetAttribute("SpaceBlockId") == blockId then
			return ladder
		end
	end

	return nil
end

function InteractionService:_setIslandSpaceLadderVisible(ladder, visible)
	if not ladder or not ladder.Parent then
		return
	end

	if visible then
		ladder.Transparency = 0.08
		ladder.CanCollide = true
		setPromptEnabled(ladder, true)
		return
	end

	local baseSize = ladder:GetAttribute("BaseSize")
	local baseCFrame = ladder:GetAttribute("BaseCFrame")
	if baseSize then
		ladder.Size = baseSize
	end
	if baseCFrame then
		ladder.CFrame = baseCFrame
	end
	ladder.Transparency = 1
	ladder.CanCollide = false
	setPromptEnabled(ladder, false)
end

function InteractionService:_growIslandSpaceLadder(block)
	local blockId = block:GetAttribute("SpaceBlockId")
	local ladder = self:_findIslandSpaceLadder(blockId)
	if not ladder then
		return
	end

	self.islandSpaceLadderState[ladder] = self.islandSpaceLadderState[ladder] or {
		Grown = false,
		Growing = false,
		TransportingByUserId = {},
	}
	local state = self.islandSpaceLadderState[ladder]
	if state.Grown or state.Growing then
		return
	end

	state.Growing = true
	ladder.Transparency = 0.08
	ladder.CanCollide = true
	setPromptEnabled(ladder, false)
	playSound(ladder, "rbxasset://sounds/electronicpingshort.wav", 0.55, 1.6)

	local fullSize = ladder:GetAttribute("FullSize")
	local fullCFrame = ladder:GetAttribute("FullCFrame")
	if fullSize and fullCFrame then
		tweenPart(ladder, 0.82, {
			Size = fullSize,
			CFrame = fullCFrame,
		}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end

	task.delay(0.9, function()
		if not ladder.Parent then
			return
		end
		state.Growing = false
		state.Grown = true
		setPromptEnabled(ladder, true)
	end)
end

function InteractionService:_wireIslandHiddenSkyBlock(block)
	self.islandSkyBlockState[block] = self.islandSkyBlockState[block] or {
		Revealed = false,
		Reacting = false,
	}

	self:_connectPrompt(getPrompt(block), function(player)
		self.systemMessageRemote:FireClient(player, "The block says BONK BLOCK, which feels more like a confession than a label.")
	end)

	if self.islandSkyBlockState[block].TouchConnected then
		return
	end

	self.islandSkyBlockState[block].TouchConnected = true
	block.Touched:Connect(function(hit)
		local state = self.islandSkyBlockState[block]
		if not state or state.Revealed or state.Reacting then
			return
		end

		local character = hit and hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		local rootPart = player and getRootPart(player)
		if not player or not rootPart then
			return
		end

		if rootPart.Position.Y > block.Position.Y - 0.45 then
			return
		end

		state.Reacting = true
		state.Revealed = true
		self:_setIslandSkyBlockVisible(block, true)
		self:_growIslandSpaceLadder(block)
		playSound(block, "rbxasset://sounds/snap.wav", 0.65, 0.72)
		self.systemMessageRemote:FireClient(player, "BONK. The palm tree reveals a very unlicensed route upward.")
		task.delay(0.5, function()
			state.Reacting = false
		end)
	end)
end

function InteractionService:_wireIslandSpaceLadder(ladder)
	self.islandSpaceLadderState[ladder] = self.islandSpaceLadderState[ladder] or {
		Grown = false,
		Growing = false,
		TransportingByUserId = {},
	}

	self:_connectPrompt(getPrompt(ladder), function(player)
		local state = self.islandSpaceLadderState[ladder]
		if not state or not state.Grown then
			self.systemMessageRemote:FireClient(player, "The ladder is still deciding how tall it wants to be.")
			return
		end

		if state.TransportingByUserId[player.UserId] then
			return
		end

		state.TransportingByUserId[player.UserId] = true
		self.discoveryService:Unlock(player, Constants.Discoveries.SpaceStationEntered.Id)
		playSound(ladder, "rbxasset://sounds/electronicpingshort.wav", 0.65, 2.0)
		self.systemMessageRemote:FireClient(player, "The ladder takes the scenic route directly to orbit.")
		task.delay(0.25, function()
			if player.Parent then
				teleportPlayer(player, Constants.GetRoomSpawnCFrame("SpaceStation"))
			end
			task.delay(1, function()
				state.TransportingByUserId[player.UserId] = nil
			end)
		end)
	end)
end

function InteractionService:_wireIslandScrapWood(wood)
	local prompt = getPrompt(wood)

	self.islandScrapWoodState[wood] = self.islandScrapWoodState[wood] or {
		Reacting = false,
		Collected = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.islandScrapWoodState[wood]
		if not state or state.Reacting or state.Collected then
			return
		end

		state.Reacting = true
		state.Collected = true
		self.islandWoodCountByUserId[player.UserId] = (self.islandWoodCountByUserId[player.UserId] or 0) + 1
		self.discoveryService:Unlock(player, Constants.Discoveries.IslandDriftwood.Id)
		playSound(wood, "rbxasset://sounds/button.wav", 0.33, 0.78)
		if wood:IsA("BasePart") then
			tweenPart(wood, 0.18, {
				Transparency = 1,
				CFrame = wood.CFrame + Vector3.new(0, 0.45, 0),
			}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			wood.CanCollide = false
		end
		setPromptEnabled(wood, false)
		self.systemMessageRemote:FireClient(player, ("Scrap wood collected: %d. The fire ring looks interested."):format(self.islandWoodCountByUserId[player.UserId]))
		task.wait(0.15)
		state.Reacting = false
	end)
end

function InteractionService:_getIslandFireRingModel(fireRingPart)
	return fireRingPart and (fireRingPart:FindFirstAncestor("IslandFireRing") or fireRingPart.Parent)
end

function InteractionService:_setIslandFireWoodVisible(fireRingPart, depositedCount)
	local fireRing = self:_getIslandFireRingModel(fireRingPart)
	if not fireRing then
		return
	end

	for _, instance in ipairs(fireRing:GetDescendants()) do
		if instance:IsA("BasePart") and instance:GetAttribute("FirewoodIndex") then
			local index = instance:GetAttribute("FirewoodIndex")
			instance.Transparency = index <= depositedCount and 0 or 1
			instance.CanCollide = false
		end
	end
end

function InteractionService:_setIslandFireEmitters(fireRingPart, fireActive, smokeActive)
	local fireRing = self:_getIslandFireRingModel(fireRingPart)
	if not fireRing then
		return
	end

	for _, instance in ipairs(fireRing:GetDescendants()) do
		if instance:IsA("ParticleEmitter") and instance:GetAttribute("IslandFireEmitter") then
			if instance.Name:find("Smoke", 1, true) then
				instance.Enabled = smokeActive
			else
				instance.Enabled = fireActive
			end
		end
	end
end

function InteractionService:_startIslandCampfire(fireRingPart, player)
	local state = self.islandFireRingState[fireRingPart]
	if not state or state.Burning or state.Smoking then
		return
	end

	state.Burning = true
	state.Smoking = true
	state.Token = {}
	local token = state.Token
	local prompt = getPrompt(fireRingPart)
	if prompt then
		prompt.ActionText = "Warming"
		prompt.ObjectText = "Campfire"
	end

	self:_setIslandFireEmitters(fireRingPart, true, true)
	self.discoveryService:Unlock(player, Constants.Discoveries.IslandCampfire.Id)
	playSound(fireRingPart, "rbxasset://sounds/electronicpingshort.wav", 0.45, 0.48)
	self.systemMessageRemote:FireClient(player, "The island campfire decides to be dramatically useful.")

	task.delay(18, function()
		if state.Token ~= token then
			return
		end

		state.Burning = false
		self:_setIslandFireEmitters(fireRingPart, false, true)
		if prompt then
			prompt.ActionText = "Smoking"
		end
		self.systemMessageRemote:FireAllClients("The campfire goes out, but keeps smoking like it has notes.")

		task.delay(30, function()
			if state.Token ~= token then
				return
			end

			state.Smoking = false
			self:_setIslandFireEmitters(fireRingPart, false, false)
			if prompt then
				prompt.ActionText = "Relight"
				prompt.ObjectText = "Wood-Filled Ring"
			end
		end)
	end)
end

function InteractionService:_wireIslandFireRing(fireRingPart)
	local prompt = getPrompt(fireRingPart)

	self.islandFireRingState[fireRingPart] = self.islandFireRingState[fireRingPart] or {
		Deposited = 0,
		Burning = false,
		Smoking = false,
		Token = nil,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.islandFireRingState[fireRingPart]
		if not state then
			return
		end

		local requiredWood = 3
		if state.Deposited < requiredWood then
			local heldWood = self.islandWoodCountByUserId[player.UserId] or 0
			if heldWood <= 0 then
				self.systemMessageRemote:FireClient(player, ("The rock ring wants %d pieces of driftwood. You are carrying none."):format(requiredWood - state.Deposited))
				return
			end

			self.islandWoodCountByUserId[player.UserId] = heldWood - 1
			state.Deposited += 1
			self:_setIslandFireWoodVisible(fireRingPart, state.Deposited)
			playSound(fireRingPart, "rbxasset://sounds/button.wav", 0.35, 0.68)
			if prompt then
				prompt.ActionText = state.Deposited >= requiredWood and "Light" or "Add Wood"
				prompt.ObjectText = state.Deposited >= requiredWood and "Wood-Filled Ring" or "Rock Ring"
			end
			self.systemMessageRemote:FireClient(player, ("Driftwood added: %d / %d."):format(state.Deposited, requiredWood))
			return
		end

		if state.Burning then
			self.systemMessageRemote:FireClient(player, "The campfire is already doing fire things.")
			return
		end

		if state.Smoking then
			self.systemMessageRemote:FireClient(player, "The campfire is out, but still smoking for a bit.")
			return
		end

		self:_startIslandCampfire(fireRingPart, player)
	end)
end

function InteractionService:_getSpaceStationState(instance)
	self.spaceStationState[instance] = self.spaceStationState[instance] or {
		Reacting = false,
		Count = 0,
	}
	return self.spaceStationState[instance]
end

function InteractionService:_wireSpaceStationGravityDial(dial)
	local prompt = getPrompt(dial)

	self:_connectPrompt(prompt, function(player)
		local state = self:_getSpaceStationState(dial)
		if state.Reacting then
			return
		end

		state.Reacting = true
		state.Count += 1
		self.discoveryService:Unlock(player, Constants.Discoveries.SpaceStationGravityDial.Id)
		playSound(dial, "rbxasset://sounds/electronicpingshort.wav", 0.48, 0.85 + state.Count * 0.18)
		local baseCFrame = dial:GetAttribute("BaseCFrame") or dial.CFrame
		tweenPart(dial, 0.22, {
			CFrame = baseCFrame * CFrame.Angles(0, 0, math.rad(105 + state.Count * 30)),
		}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		self.systemMessageRemote:FireClient(player, "Gravity politely updates its resume, then changes nothing important.")
		task.delay(0.3, function()
			state.Reacting = false
		end)
	end)
end

function InteractionService:_wireSpaceStationObservationWindow(window)
	local prompt = getPrompt(window)

	self:_connectPrompt(prompt, function(player)
		local state = self:_getSpaceStationState(window)
		if state.Reacting then
			return
		end

		state.Reacting = true
		state.Count += 1
		self.discoveryService:Unlock(player, Constants.Discoveries.SpaceStationObservationWindow.Id)
		playSound(window, "rbxasset://sounds/electronicpingshort.wav", 0.42, 0.55)

		local starField = Instance.new("Model")
		starField.Name = "SpaceStationParallaxStarField"
		starField.Parent = workspace
		CollectionService:AddTag(starField, Constants.Tags.TemporaryObject)

		local random = Random.new(math.floor(os.clock() * 1000) % 100000)
		local animatedStars = {}
		for layerIndex = 1, 3 do
			for starIndex = 1, 14 do
				local star = Instance.new("Part")
				star.Name = ("SpaceParallaxStar%d_%d"):format(layerIndex, starIndex)
				star.Anchored = true
				star.CanCollide = false
				star.BottomSurface = Enum.SurfaceType.Smooth
				star.TopSurface = Enum.SurfaceType.Smooth
				star.Shape = Enum.PartType.Ball
				star.Size = Vector3.new(0.12 + layerIndex * 0.04, 0.12 + layerIndex * 0.04, 0.12 + layerIndex * 0.04)
				star.Color = layerIndex == 1 and Color3.fromRGB(158, 210, 255) or Color3.fromRGB(235, 246, 255)
				star.Material = Enum.Material.Neon
				star.Parent = starField

				local baseCFrame = window.CFrame
					* CFrame.new(
						random:NextNumber(-8.4, 8.4),
						random:NextNumber(-3.0, 3.0),
						-0.75 - layerIndex * 0.9
					)
				star.CFrame = baseCFrame
				table.insert(animatedStars, {
					Part = star,
					BaseCFrame = baseCFrame,
					Layer = layerIndex,
					Phase = random:NextNumber(0, math.pi * 2),
				})
			end
		end

		task.spawn(function()
			local startedAt = os.clock()
			local duration = 6.4
			while starField.Parent do
				local elapsed = os.clock() - startedAt
				local alpha = math.clamp(elapsed / duration, 0, 1)
				for _, item in ipairs(animatedStars) do
					if item.Part and item.Part.Parent then
						local layerSpeed = 0.25 + item.Layer * 0.22
						item.Part.CFrame = item.BaseCFrame
							* CFrame.new(
								math.sin(elapsed * layerSpeed + item.Phase) * item.Layer * 0.55,
								math.cos(elapsed * (layerSpeed + 0.12) + item.Phase) * item.Layer * 0.24,
								-alpha * item.Layer * 0.75
							)
					end
				end

				if alpha >= 1 then
					break
				end
				RunService.Heartbeat:Wait()
			end
		end)

		task.delay(5.4, function()
			for _, part in ipairs(starField:GetChildren()) do
				if part:IsA("BasePart") then
					tweenPart(part, 0.55, { Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				end
			end
		end)

		Debris:AddItem(starField, 6.8)
		self.systemMessageRemote:FireClient(player, "Space drifts past the window in layers. It is showing off correctly now.")
		task.delay(0.55, function()
			state.Reacting = false
		end)
	end)
end

function InteractionService:_wireSpaceStationFoodPrinter(printer)
	local prompt = getPrompt(printer)

	self:_connectPrompt(prompt, function(player)
		local state = self:_getSpaceStationState(printer)
		if state.Reacting then
			return
		end

		state.Reacting = true
		self.discoveryService:Unlock(player, Constants.Discoveries.SpaceStationFoodPrinter.Id)
		playSound(printer, "rbxasset://sounds/button.wav", 0.45, 1.55)
		for _, part in ipairs(printer.Parent and printer.Parent:GetChildren() or {}) do
			if part:IsA("BasePart") and part:GetAttribute("FoodOutput") == true then
				local baseCFrame = part:GetAttribute("BaseCFrame") or part.CFrame
				local lift = 0.32
				if part.Name:find("Drumstick", 1, true) then
					lift = 0.62
				elseif part.Name:find("Tube", 1, true) then
					lift = 0.46
				end

				tweenPart(part, 0.18, {
					CFrame = baseCFrame + Vector3.new(0, lift, -0.22),
				}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				task.delay(0.42, function()
					if part.Parent then
						tweenPart(part, 0.2, { CFrame = baseCFrame }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
					end
				end)
			end
		end
		self.systemMessageRemote:FireClient(player, "The food printer produces a tray with a suspiciously recognizable drumstick.")
		task.delay(0.35, function()
			state.Reacting = false
		end)
	end)
end

function InteractionService:_wireSpaceStationStarMap(starMap)
	local prompt = getPrompt(starMap)

	self:_connectPrompt(prompt, function(player)
		local state = self:_getSpaceStationState(starMap)
		if state.Reacting then
			return
		end

		state.Reacting = true
		state.Count += 1
		self.discoveryService:Unlock(player, Constants.Discoveries.SpaceStationStarMap.Id)
		playSound(starMap, "rbxasset://sounds/electronicpingshort.wav", 0.42, 1.35)
		for _, dot in ipairs(starMap.Parent and starMap.Parent:GetChildren() or {}) do
			if dot:IsA("BasePart") and dot.Name:find("StarMapDot", 1, true) then
				local baseCFrame = dot:GetAttribute("BaseCFrame") or dot.CFrame
				local seed = state.Count + #dot.Name
				local offset = Vector3.new(math.sin(seed) * 0.55, math.cos(seed * 0.8) * 0.42, math.sin(seed * 0.5) * 0.55)
				tweenPart(dot, 0.22, { CFrame = baseCFrame + offset }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
				task.delay(0.42, function()
					if dot.Parent then
						tweenPart(dot, 0.28, { CFrame = baseCFrame }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
					end
				end)
			elseif dot:IsA("BasePart") and dot.Name:find("StarMapRing", 1, true) then
				local baseCFrame = dot:GetAttribute("BaseCFrame") or dot.CFrame
				tweenPart(dot, 0.3, {
					CFrame = baseCFrame * CFrame.Angles(0, math.rad(22 + state.Count * 7), 0),
				}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			end
		end
		self.systemMessageRemote:FireClient(player, "The floating star map rearranges itself into an argument with astronomy.")
		task.delay(0.5, function()
			state.Reacting = false
		end)
	end)
end

function InteractionService:_wireSpaceStationPlantPod(plantPod)
	local prompt = getPrompt(plantPod)

	self:_connectPrompt(prompt, function(player)
		local state = self:_getSpaceStationState(plantPod)
		if state.Reacting then
			return
		end

		state.Reacting = true
		self.discoveryService:Unlock(player, Constants.Discoveries.SpaceStationPlantPod.Id)
		playSound(plantPod, "rbxasset://sounds/button.wav", 0.32, 1.85)
		local leaf = plantPod.Parent and plantPod.Parent:FindFirstChild("SpacePlantLeaf")
		if leaf and leaf:IsA("BasePart") then
			local baseSize = leaf:GetAttribute("BaseSize") or leaf.Size
			tweenPart(leaf, 0.28, { Size = baseSize + Vector3.new(0.45, 0.08, 0.24) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			task.delay(0.55, function()
				if leaf.Parent then
					tweenPart(leaf, 0.24, { Size = baseSize }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				end
			end)
		end
		self.systemMessageRemote:FireClient(player, "The space plant appreciates hydration and refuses to elaborate.")
		task.delay(0.45, function()
			state.Reacting = false
		end)
	end)
end

function InteractionService:_spawnSpaceMeteor(source)
	local sourcePosition = source:IsA("BasePart") and source.Position or Constants.GetRoomSpawnCFrame("SpaceStation").Position
	local meteor = Instance.new("Model")
	meteor.Name = "SpaceStationMeteor"
	meteor.Parent = workspace
	CollectionService:AddTag(meteor, Constants.Tags.TemporaryObject)

	local rock = Instance.new("Part")
	rock.Name = "MeteorRock"
	rock.Anchored = true
	rock.CanCollide = false
	rock.BottomSurface = Enum.SurfaceType.Smooth
	rock.TopSurface = Enum.SurfaceType.Smooth
	rock.Shape = Enum.PartType.Ball
	rock.Size = Vector3.new(1.7, 1.7, 1.7)
	rock.Color = Color3.fromRGB(112, 92, 79)
	rock.Material = Enum.Material.Slate
	rock.CFrame = CFrame.new(sourcePosition + Vector3.new(-20, 8, -18))
	rock.Parent = meteor

	local flame = Instance.new("ParticleEmitter")
	flame.Name = "MeteorTrail"
	flame.Texture = "rbxasset://textures/particles/fire_main.dds"
	flame.Rate = 45
	flame.Lifetime = NumberRange.new(0.25, 0.55)
	flame.Speed = NumberRange.new(0.4, 1.2)
	flame.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.4),
		NumberSequenceKeypoint.new(1, 0.15),
	})
	flame.Color = ColorSequence.new(Color3.fromRGB(255, 221, 92), Color3.fromRGB(255, 82, 42))
	flame.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	flame.Parent = rock

	tweenPart(rock, 2.2, {
		CFrame = CFrame.new(sourcePosition + Vector3.new(20, 4, -18)),
	}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	task.delay(2.0, function()
		if rock.Parent then
			tweenPart(rock, 0.35, { Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			flame.Enabled = false
		end
	end)
	Debris:AddItem(meteor, 2.8)
end

function InteractionService:_wireSpaceStationMeteorButton(button)
	local prompt = getPrompt(button)

	self:_connectPrompt(prompt, function(player)
		local state = self:_getSpaceStationState(button)
		if state.Reacting then
			return
		end

		state.Reacting = true
		self.discoveryService:Unlock(player, Constants.Discoveries.SpaceStationMeteorButton.Id)
		playSound(button, "rbxasset://sounds/snap.wav", 0.55, 0.52)
		self:_spawnSpaceMeteor(button)
		local baseCFrame = button:GetAttribute("BaseCFrame") or button.CFrame
		tweenPart(button, 0.08, { CFrame = baseCFrame + Vector3.new(0, -0.22, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		task.delay(0.12, function()
			if button.Parent then
				tweenPart(button, 0.16, { CFrame = baseCFrame }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			end
		end)
		self.systemMessageRemote:FireClient(player, "Meteor requested. The window asks why this button exists.")
		task.delay(0.55, function()
			state.Reacting = false
		end)
	end)
end

function InteractionService:_wireSpaceStationEscapePod(pod)
	local prompt = getPrompt(pod)

	self:_connectPrompt(prompt, function(player)
		local state = self:_getSpaceStationState(pod)
		if state.Reacting then
			return
		end

		state.Reacting = true
		self.discoveryService:Unlock(player, Constants.Discoveries.SpaceStationEscapePod.Id)
		playSound(pod, "rbxasset://sounds/electronicpingshort.wav", 0.5, 0.58)
		local baseCFrame = pod:GetAttribute("BaseCFrame") or pod.CFrame
		tweenPart(pod, 0.1, { CFrame = baseCFrame * CFrame.Angles(0, 0, math.rad(2)) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		task.delay(0.12, function()
			if pod.Parent then
				tweenPart(pod, 0.12, { CFrame = baseCFrame * CFrame.Angles(0, 0, math.rad(-2)) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			end
		end)
		task.delay(0.28, function()
			if pod.Parent then
				tweenPart(pod, 0.18, { CFrame = baseCFrame }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			end
		end)
		self.systemMessageRemote:FireClient(player, "The escape pod runs a test and chooses dramatic standby.")
		task.delay(0.45, function()
			state.Reacting = false
		end)
	end)
end

return InteractionService
