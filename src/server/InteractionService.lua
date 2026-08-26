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

local SIGNAL_BAND_ATTRIBUTE = "DontTouchItSignalBandEquipped"

local ROOM_UNLOCK_NOTICES = {
	SnackLab = {
		SoundId = Constants.AudioAssets.Prologue.LockdownDoorEchoId,
		Message = "Somewhere in the hallway, a door opens with a tired metal sigh.",
	},
	TopDownArena = {
		SoundId = Constants.AudioAssets.Prologue.LockdownDoorEchoId,
		Message = "Somewhere beyond the bunks, the training door unlocks.",
	},
}

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

local CAVE_LIGHT_COLORS = {
	Color3.fromRGB(255, 224, 145),
	Color3.fromRGB(255, 92, 124),
	Color3.fromRGB(119, 255, 203),
	Color3.fromRGB(150, 112, 255),
	Color3.fromRGB(255, 232, 92),
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

local televisionAudio = Constants.AudioAssets and Constants.AudioAssets.Television
local TV_SOUND_IDS = {
	Static = (televisionAudio and televisionAudio.StaticId) or "rbxasset://sounds/electronicpingshort.wav",
	TestTone = (televisionAudio and televisionAudio.TestToneId) or "rbxasset://sounds/electronicpingshort.wav",
	Warning = (televisionAudio and televisionAudio.PleaseStopId) or "rbxasset://sounds/snap.wav",
}
local TV_EYE_DURATION = 10
local TV_EYE_FADE_DURATION = 2.25
local bowlingAudio = Constants.AudioAssets and Constants.AudioAssets.Bowling
local BOWLING_COSMIC_ACTIVE_ATTRIBUTE = (bowlingAudio and bowlingAudio.CosmicActiveAttribute)
	or "DontTouchItBowlingCosmicActive"
local BOWLING_COSMIC_MUSIC_ATTRIBUTE = (bowlingAudio and bowlingAudio.CosmicMusicAttribute)
	or "DontTouchItBowlingCosmicMusicId"
local BOWLING_COSMIC_MUSIC_IDS = (bowlingAudio and bowlingAudio.CosmicMusicIds) or {
	"rbxassetid://9038367768",
	"rbxassetid://87335378694883",
	"rbxassetid://137370718943178",
	"rbxassetid://140712674948564",
}
local BOWLING_STRIKE_SOUND_IDS = (bowlingAudio and bowlingAudio.StrikeSoundIds) or {
	"rbxassetid://4692687595",
	"rbxassetid://128237818020429",
}
local BOWLING_STRIKE_SOUND_VOLUME = (bowlingAudio and bowlingAudio.StrikeVolume) or 0.72
local bunkerEnergyAudio = Constants.AudioAssets and Constants.AudioAssets.BunkerEnergy
local BUNKER_SHUTDOWN_SOUND_ID = (bunkerEnergyAudio and bunkerEnergyAudio.ShutdownSoundId) or "rbxassetid://1842440874"
local BUNKER_SHUTDOWN_SOUND_VOLUME = (bunkerEnergyAudio and bunkerEnergyAudio.ShutdownSoundVolume) or 0.58
local inventoryAudio = Constants.AudioAssets and Constants.AudioAssets.Inventory
local ROCK_DROP_SOUND_IDS = (inventoryAudio and inventoryAudio.RockDropSoundIds) or {
	"rbxassetid://9125869797",
	"rbxassetid://9118587698",
}
local ROCK_DROP_VOLUME = (inventoryAudio and inventoryAudio.RockDropVolume) or 0.62
local CONTROL_PANEL_SOUND_ID = if Constants.AudioAssets and Constants.AudioAssets.Interface
	then Constants.AudioAssets.Interface.ControlPanelInteractionId
	else "rbxassetid://112555741154994"

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
local SNACK_MIXER_WEATHER_DURATION = 35
local SECURITY_CAMERA_DURATION = 45
local TOP_DOWN_THROW_COOLDOWN = 0.75
local TOP_DOWN_BALLOON_LIFETIME = 5.5
local TOP_DOWN_RING_SCORE_RADIUS = 15
local TOP_DOWN_MAX_LOADED_BALLOONS = 20
local TOP_DOWN_DEFAULT_LOAD_COUNT = 20
local TOP_DOWN_REFILL_LOAD_COUNT = 20
local TOP_DOWN_THROW_DISTANCE = 58
local TOP_DOWN_STILL_THROW_SPREAD = 1.6
local TOP_DOWN_MOVING_THROW_SPREAD = 4.0
local TOP_DOWN_SPREAD_SPEED = 16
local TOP_DOWN_THROW_ACTION = "Throw"
local TOP_DOWN_WATER_BALLOON_KIND = "TopDownWaterBalloon"
local TOP_DOWN_WATER_BALLOON_NAME = "Water Balloon"
local TOP_DOWN_WATER_BALLOON_COLOR = Color3.fromRGB(93, 217, 255)
local TOP_DOWN_WATER_BALLOON_SIZE = Vector3.new(0.82, 0.82, 0.82)
local TOP_DOWN_READY_DELAY_SECONDS = 3
local TOP_DOWN_COUNTDOWN_SECONDS = 3
local TOP_DOWN_DEFAULT_ROUND_SECONDS = 120
local TOP_DOWN_ROUND_LENGTH_OPTIONS = {
	[60] = true,
	[120] = true,
	[300] = true,
}
local TOP_DOWN_TEAM_LABELS = {
	North = "NORTH",
	South = "SOUTH",
}
local TELEPORT_LANDING_LIFT = Vector3.new(0, 2.6, 0)
local BUNKER_RECLAIM_MESSAGE_COOLDOWN = 24
local OBJECT_RAIN_SORT_COOLDOWN = 3.5
local OBJECT_RAIN_SORT_UPPER_Y = Constants.Room.FloorY - 3.5
local INVENTORY_DROP_COOLDOWN = 0.45
local INVENTORY_DROP_DISTANCE = 5.2
local INVENTORY_DROP_RAY_HEIGHT = 7.5
local INVENTORY_DROP_RAY_DEPTH = 22
local INVENTORY_DROP_DECAY_DELAY = 7
local INVENTORY_DROP_DECAY_DURATION = 18
local INVENTORY_DROP_ABSORB_DELAY = 34
local INVENTORY_DROP_ABSORB_DURATION = 3.2
local SECURITY_WEIGHT_DROP_MARGIN = 2.2

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
		Text = "VISIT THE SNACK LAB\nFRIDGE IDEAS SERVED COLD",
		Background = Color3.fromRGB(91, 188, 124),
		TextColor = Color3.fromRGB(245, 255, 235),
	},
	{
		Text = "BLOXY TOAST\nBUTTERED ON PURPOSE",
		Background = Color3.fromRGB(255, 178, 87),
		TextColor = Color3.fromRGB(55, 31, 17),
	},
	{
		Text = "BLOXY ZIPLINE\nTREES TODAY, ISLAND TOMORROW",
		Background = Color3.fromRGB(47, 146, 101),
		TextColor = Color3.fromRGB(230, 255, 224),
	},
	{
		Text = "BLOXY ISLAND\nSUN, SAND, AND GOOD TIMES",
		Background = Color3.fromRGB(255, 205, 89),
		TextColor = Color3.fromRGB(45, 61, 83),
	},
	{
		Text = "THE LIBRARY\nQUIETLY HIDING BOWLING KEYS",
		Background = Color3.fromRGB(116, 75, 45),
		TextColor = Color3.fromRGB(255, 235, 149),
	},
	{
		Text = "BLOXY BOWLING\nTHREE LANES, MANY EXCUSES",
		Background = Color3.fromRGB(93, 217, 255),
		TextColor = Color3.fromRGB(18, 24, 36),
	},
	{
		Text = "COSMIC BOWLING\nNOW WITH FLOOR CONFIDENCE",
		Background = Color3.fromRGB(42, 18, 80),
		TextColor = Color3.fromRGB(119, 255, 203),
	},
	{
		Text = "BLOXY SHOES\nRENTAL CONFIDENCE INCLUDED",
		Background = Color3.fromRGB(150, 112, 255),
		TextColor = Color3.fromRGB(255, 246, 220),
	},
	{
		Text = "TV ROOM\nDO NOT PRESS THE OBVIOUS BUTTON",
		Background = Color3.fromRGB(255, 226, 102),
		TextColor = Color3.fromRGB(36, 27, 42),
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

local function getPlayerFromHit(hit)
	if not hit then
		return nil
	end

	local character = hit:FindFirstAncestorOfClass("Model")
	if not character or not character:FindFirstChildOfClass("Humanoid") then
		return nil
	end

	return Players:GetPlayerFromCharacter(character)
end

local function teleportPlayer(player, destinationCFrame)
	local rootPart = getRootPart(player)
	if not rootPart or typeof(destinationCFrame) ~= "CFrame" then
		return
	end

	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
	rootPart.CFrame = destinationCFrame + TELEPORT_LANDING_LIFT
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

local function isControlPanelInteraction(instance)
	local current = instance
	while current do
		if current:GetAttribute("StrictPromptTargets") == true then
			return true
		end
		current = current.Parent
	end

	return false
end

local function playControlPanelSound(parent, volume, playbackSpeed)
	playSound(parent, CONTROL_PANEL_SOUND_ID, volume or 0.48, playbackSpeed or 1)
end

local function chooseRandomAudioId(soundIds, random, previousSoundId)
	if typeof(soundIds) ~= "table" or #soundIds <= 0 then
		return nil
	end

	if #soundIds == 1 then
		return soundIds[1]
	end

	random = random or Random.new()
	for _ = 1, 5 do
		local candidate = soundIds[random:NextInteger(1, #soundIds)]
		if candidate ~= previousSoundId then
			return candidate
		end
	end

	return soundIds[random:NextInteger(1, #soundIds)]
end

local function playLoopedSpatialSound(parent, name, soundId, options)
	if not parent or not parent.Parent or not soundId then
		return nil
	end
	options = options or {}

	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Sound") then
		if not existing.IsPlaying then
			existing:Play()
		end
		return existing
	end

	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = soundId
	sound.Volume = options.Volume or 0.5
	sound.PlaybackSpeed = options.PlaybackSpeed or 1
	sound.Looped = true
	sound.RollOffMode = options.RollOffMode or Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = options.RollOffMinDistance or 8
	sound.RollOffMaxDistance = options.RollOffMaxDistance or 45
	sound.Parent = parent
	sound:Play()
	return sound
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

function InteractionService.new(eventManager, discoveryService, resetService, roomProgressService, movementAuthorityService, bunkerEnergyService, victoryBrickService)
	local self = setmetatable({}, InteractionService)
	self.eventManager = eventManager
	self.discoveryService = discoveryService
	self.resetService = resetService
	self.roomProgressService = roomProgressService
	self.movementAuthorityService = movementAuthorityService
	self.bunkerEnergyService = bunkerEnergyService
	self.victoryBrickService = victoryBrickService
	self.systemMessageRemote = RemoteService.GetRemote(Constants.Remotes.SystemMessage)
	self.snackEffectRemote = RemoteService.GetRemote(Constants.Remotes.SnackEffect)
	self.voidEffectRemote = RemoteService.GetRemote(Constants.Remotes.VoidEffect)
	self.securityCameraRemote = RemoteService.GetRemote(Constants.Remotes.SecurityCamera)
	self.topDownArenaRemote = RemoteService.GetRemote(Constants.Remotes.TopDownArena)
	self.transformCameraRemote = RemoteService.GetRemote(Constants.Remotes.TransformCamera)
	self.inventoryActionRemote = RemoteService.GetRemote(Constants.Remotes.InventoryAction)
	self.victoryBrickReadRemote = RemoteService.GetRemote(Constants.Remotes.VictoryBrickRead)
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
	self.snackPopcornState = {}
	self.snackPackStateByUserId = {}
	self.slowMotionTokensByHumanoid = {}
	self.windStormTokensByHumanoid = {}
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
	self.islandRockState = {}
	self.islandWoodCountByUserId = {}
	self.islandRockCountByUserId = {}
	self.islandFireRingState = {}
	self.islandSkyBlockState = {}
	self.islandSpaceLadderState = {}
	self.islandResourceRandom = Random.new()
	self.islandResourceLoopStarted = false
	self.spaceStationState = {}
	self.teleportCooldownByUserId = {}
	self.secretDoorState = {}
	self.libraryLampState = {}
	self.libraryGlobeState = {}
	self.libraryLadderState = {}
	self.libraryLoftDoorState = {}
	self.libraryBookcaseState = {}
	self.libraryBookStormState = {}
	self.bowlingLaneState = {}
	self.bowlingLaneCounts = {
		[1] = 0,
		[2] = 0,
		[3] = 0,
	}
	self.bowlingCosmicActive = false
	self.bowlingCosmicToken = nil
	self.bowlingAudioRandom = Random.new()
	self.lastBowlingCosmicMusicId = nil
	self.lastBowlingStrikeSoundId = nil
	self.inventoryAudioRandom = Random.new()
	self.lastRockDropSoundId = nil
	self.bowlingAdToken = nil
	self.bowlingMaintenanceMotionConnection = nil
	self.treetopZiplineStateByUserId = {}
	self.voidGravityTokensByUserId = {}
	self.voidChillTokensByHumanoid = {}
	self.caveLightState = {}
	self.caveEntranceSealed = false
	self.caveAlarmActive = false
	self.caveHallDoorLockedByUserId = {}
	self.securityCameraSessionByUserId = {}
	self.securityPressurePlateState = {
		Badge = false,
		Weight = false,
		Unlocked = false,
	}
	self.sleepingAlarmStateByUserId = {}
	self.sleepingLockerCheckedByUserId = {}
	self.sleepingMattressBounceAtByHumanoid = {}
	self.topDownScoresByUserId = {}
	self.topDownThrowsByUserId = {}
	self.topDownLastThrowByUserId = {}
	self.topDownLoadedBalloonsByUserId = {}
	self.topDownBucketTouchAtByUserId = {}
	self.topDownPracticeTargetState = {}
	self.topDownThrowRandom = Random.new()
	self.topDownCameraMode = "Overhead"
	self.topDownTeamByUserId = {}
	self.topDownTeamScores = {
		North = 0,
		South = 0,
	}
	self.topDownRoundState = {
		Status = "Waiting",
		RoundSeconds = TOP_DOWN_DEFAULT_ROUND_SECONDS,
		CountdownToken = 0,
		RoundToken = 0,
		ArmingEndsAt = nil,
		CountdownEndsAt = nil,
		EndsAt = nil,
		LastResult = nil,
	}
	self.inventoryDropAtByUserId = {}
	self.bunkerReclaimMessageAtByKey = {}
	self.roomUnlockNoticeByUserId = {}
	self.objectRainSortLastAt = 0
	self.objectRainSortRandom = Random.new()
	return self
end

function InteractionService:_teleportPlayer(player, destinationCFrame, reason)
	if self.movementAuthorityService and self.movementAuthorityService.TeleportPlayer then
		local success = self.movementAuthorityService:TeleportPlayer(player, destinationCFrame, reason)
		if success and self.roomProgressService then
			if self.roomProgressService.RememberSafeSpawn then
				self.roomProgressService:RememberSafeSpawn(player, destinationCFrame)
			end
			if self.roomProgressService.RememberContinueDestination then
				self.roomProgressService:RememberContinueDestination(player, nil, destinationCFrame, true)
			end
		end
		return success
	end

	teleportPlayer(player, destinationCFrame)
	if self.roomProgressService then
		if self.roomProgressService.RememberSafeSpawn then
			self.roomProgressService:RememberSafeSpawn(player, destinationCFrame)
		end
		if self.roomProgressService.RememberContinueDestination then
			self.roomProgressService:RememberContinueDestination(player, nil, destinationCFrame, true)
		end
	end
	return true
end

function InteractionService:_applyImpulse(player, velocity, reason)
	if self.movementAuthorityService and self.movementAuthorityService.ApplyImpulse then
		return self.movementAuthorityService:ApplyImpulse(player, velocity, reason)
	end

	local rootPart = getRootPart(player)
	if not rootPart then
		return false
	end

	rootPart.AssemblyLinearVelocity = velocity
	return true
end

function InteractionService:_addImpulse(player, velocity, reason)
	if self.movementAuthorityService and self.movementAuthorityService.AddImpulse then
		return self.movementAuthorityService:AddImpulse(player, velocity, reason)
	end

	local rootPart = getRootPart(player)
	if not rootPart then
		return false
	end

	rootPart.AssemblyLinearVelocity += velocity
	return true
end

function InteractionService:_beginScriptedMotion(player, reason)
	if self.movementAuthorityService and self.movementAuthorityService.BeginScriptedMotion then
		return self.movementAuthorityService:BeginScriptedMotion(player, reason)
	end

	return false
end

function InteractionService:_endScriptedMotion(player)
	if self.movementAuthorityService and self.movementAuthorityService.EndScriptedMotion then
		return self.movementAuthorityService:EndScriptedMotion(player)
	end

	return false
end

function InteractionService:Initialize()
	if self.discoveryService.DiscoveryUnlocked then
		self.discoveryService.DiscoveryUnlocked:Connect(function(player)
			self:_checkExitUnlock(player)
			self:_refreshSecretDoorsForPlayer(player)
			self:_checkRoomUnlockNotices(player)
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
				self:_snapshotRoomUnlockNotices(player)
				self:_refreshSecretDoorsForPlayer(player)
				if self.discoveryService:HasDiscovery(player, Constants.Discoveries.VoidFreezeRay.Id) then
					self:_grantFreezeRay(player)
				end
				if self.discoveryService:HasDiscovery(player, Constants.Discoveries.SecurityBunkerEnergy.Id) then
					player:SetAttribute(SIGNAL_BAND_ATTRIBUTE, true)
					player:SetAttribute("DontTouchItBunkerEnergyMonitorUnlocked", true)
					local playerGui = player:FindFirstChildOfClass("PlayerGui")
					if playerGui then
						playerGui:SetAttribute(SIGNAL_BAND_ATTRIBUTE, true)
						playerGui:SetAttribute("DontTouchItBunkerEnergyMonitorUnlocked", true)
					end
				end
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self.islandExitBounceAtByUserId[player.UserId] = nil
		self.islandExitWarningsByUserId[player.UserId] = nil
		self.islandWarningReadStateByUserId[player.UserId] = nil
		self.islandWoodCountByUserId[player.UserId] = nil
		self.islandRockCountByUserId[player.UserId] = nil
		self.treetopZiplineStateByUserId[player.UserId] = nil
		self.voidGravityTokensByUserId[player.UserId] = nil
		self.caveHallDoorLockedByUserId[player.UserId] = nil
		self.securityCameraSessionByUserId[player.UserId] = nil
		self.sleepingAlarmStateByUserId[player.UserId] = nil
		self.sleepingLockerCheckedByUserId[player.UserId] = nil
		self.topDownScoresByUserId[player.UserId] = nil
		self.topDownThrowsByUserId[player.UserId] = nil
		self.topDownLastThrowByUserId[player.UserId] = nil
		self.topDownLoadedBalloonsByUserId[player.UserId] = nil
		self.topDownBucketTouchAtByUserId[player.UserId] = nil
		self.topDownTeamByUserId[player.UserId] = nil
		self.inventoryDropAtByUserId[player.UserId] = nil
		self.roomUnlockNoticeByUserId[player.UserId] = nil
		task.defer(function()
			self:_updateTopDownScoreboards()
			self:_updateTopDownReadyStations()
		end)
	end)

	self.securityCameraRemote.OnServerEvent:Connect(function(player, payload)
		self:_handleSecurityCameraRemote(player, payload)
	end)

	self.topDownArenaRemote.OnServerEvent:Connect(function(player, payload)
		self:_handleTopDownArenaRemote(player, payload)
	end)

	self.inventoryActionRemote.OnServerEvent:Connect(function(player, payload)
		self:_handleInventoryActionRemote(player, payload)
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

	self:_connectTagged(Constants.Tags.TVSecretBook, function(instance)
		self:_wireTVSecretBook(instance)
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

	self:_connectTagged(Constants.Tags.StoreButton, function(instance)
		self:_wireStoreButton(instance)
	end)

	self:_connectTagged(Constants.Tags.TeleportButton, function(instance)
		self:_wireTeleportButton(instance)
	end)

	self:_connectTagged(Constants.Tags.FieldButton, function(instance)
		self:_wireFieldButton(instance)
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

	self:_connectTagged(Constants.Tags.SnackDonut, function(instance)
		self:_wireDiscoveryPrompt(instance, Constants.Discoveries.SnackDonut.Id, "The wall donut has been inspected. It remains too large to dunk responsibly.")
	end)

	self:_connectTagged(Constants.Tags.SnackPopcornMachine, function(instance)
		self:_wireSnackPopcornMachine(instance)
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

	self:_connectTagged(Constants.Tags.IslandRock, function(instance)
		self:_wireIslandRock(instance)
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

	self:_connectTagged(Constants.Tags.LibraryBookStorm, function(instance)
		self:_wireLibraryBookStorm(instance)
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

	self:_connectTagged(Constants.Tags.LibraryTeleportKey, function(instance)
		self:_wireLibraryTeleportKey(instance)
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

	self:_connectTagged(Constants.Tags.VoidReverseConsole, function(instance)
		self:_wireVoidReverseConsole(instance)
	end)

	self:_connectTagged(Constants.Tags.VoidGravityOrb, function(instance)
		self:_wireVoidGravityOrb(instance)
	end)

	self:_connectTagged(Constants.Tags.VoidEchoButton, function(instance)
		self:_wireVoidEchoButton(instance)
	end)

	self:_connectTagged(Constants.Tags.VoidFreezeRay, function(instance)
		self:_wireVoidFreezeRay(instance)
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

	self:_connectTagged(Constants.Tags.CaveLight, function(instance)
		self:_wireCaveLight(instance)
	end)

	self:_connectTagged(Constants.Tags.CaveExitKey, function(instance)
		self:_wireCaveExitKey(instance)
	end)

	self:_connectTagged(Constants.Tags.CaveKeyDoor, function(instance)
		self:_wireCaveKeyDoor(instance)
	end)

	self:_connectTagged(Constants.Tags.LowerTunnelBlastDoor, function(instance)
		self:_wireDiscoveryPrompt(instance, Constants.Discoveries.LowerTunnelBlastDoor.Id, "The blast doors look important, expensive, and deeply uninterested in opening yet.")
	end)

	self:_connectTagged(Constants.Tags.ContributorDuckStand, function(instance)
		self:_wireContributorDuckStand(instance)
	end)

	self:_connectTagged(Constants.Tags.VictoryBrickStand, function(instance)
		self:_wireVictoryBrickStand(instance)
	end)

	self:_connectTagged(Constants.Tags.VictoryBrick, function(instance)
		self:_wireVictoryBrick(instance)
	end)

	self:_connectTagged(Constants.Tags.SecurityMonitor, function(instance)
		self:_wireSecurityMonitor(instance)
	end)

	self:_connectTagged(Constants.Tags.SecurityConsole, function(instance)
		self:_wireSecurityConsole(instance)
	end)

	self:_connectTagged(Constants.Tags.SecurityRedPhone, function(instance)
		self:_wireSecurityRedPhone(instance)
	end)

	self:_connectTagged(Constants.Tags.SecurityTapeDeck, function(instance)
		self:_wireSecurityTapeDeck(instance)
	end)

	self:_connectTagged(Constants.Tags.BunkerPowerMeter, function(instance)
		self:_wireBunkerPowerMeter(instance)
	end)

	self:_connectTagged(Constants.Tags.SecurityPressurePlate, function(instance)
		self:_wireSecurityPressurePlate(instance)
	end)
	self:_connectTagged(Constants.Tags.ObservationMirror, function(instance)
		self:_wireObservationMirror(instance)
	end)

	self:_connectTagged(Constants.Tags.SleepingBunk, function(instance)
		self:_wireSleepingBunk(instance)
	end)

	self:_connectTagged(Constants.Tags.SleepingMattress, function(instance)
		self:_wireSleepingMattress(instance)
	end)

	self:_connectTagged(Constants.Tags.SleepingAlarmClock, function(instance)
		self:_wireSleepingAlarmClock(instance)
	end)

	self:_connectTagged(Constants.Tags.SleepingLocker, function(instance)
		self:_wireSleepingLocker(instance)
	end)

	self:_connectTagged(Constants.Tags.SleepingDreamButton, function(instance)
		self:_wireSleepingDreamButton(instance)
	end)

	self:_connectTagged(Constants.Tags.SleepingBlanketFort, function(instance)
		self:_wireSleepingBlanketFort(instance)
	end)

	self:_connectTagged(Constants.Tags.SleepingPillowPile, function(instance)
		self:_wireSleepingPillowPile(instance)
	end)

	self:_connectTagged(Constants.Tags.SleepingIdBadge, function(instance)
		self:_wireSleepingIdBadge(instance)
	end)

	self:_connectTagged(Constants.Tags.InfirmaryRecoveryBed, function(instance)
		self:_wireInfirmaryRecoveryBed(instance)
	end)

	self:_connectTagged(Constants.Tags.InfirmaryMonitor, function(instance)
		self:_wireInfirmaryMonitor(instance)
	end)

	self:_connectTagged(Constants.Tags.InfirmaryCabinet, function(instance)
		self:_wireInfirmaryCabinet(instance)
	end)

	self:_connectTagged(Constants.Tags.InfirmaryNourishment, function(instance)
		self:_wireInfirmaryNourishment(instance)
	end)

	self:_connectTagged(Constants.Tags.GymTreadmill, function(instance)
		self:_wireGymTreadmill(instance)
	end)

	self:_connectTagged(Constants.Tags.GymBike, function(instance)
		self:_wireGymBike(instance)
	end)

	self:_connectTagged(Constants.Tags.GymWeights, function(instance)
		self:_wireGymWeights(instance)
	end)

	self:_connectTagged(Constants.Tags.GymWaterStation, function(instance)
		self:_wireGymWaterStation(instance)
	end)

	self:_connectTagged(Constants.Tags.TopDownCameraConsole, function(instance)
		self:_wireTopDownCameraConsole(instance)
	end)

	self:_connectTagged(Constants.Tags.TopDownWaterBalloonBucket, function(instance)
		self:_wireTopDownWaterBalloonBucket(instance)
	end)

	self:_connectTagged(Constants.Tags.TopDownTargetRing, function(instance)
		self:_wireTopDownTargetRing(instance)
	end)

	self:_connectTagged(Constants.Tags.TopDownSplashTarget, function(instance)
		self:_wireTopDownSplashTarget(instance)
	end)

	self:_connectTagged(Constants.Tags.TopDownScoreboard, function(instance)
		self:_wireTopDownScoreboard(instance)
	end)

	self:_connectTagged(Constants.Tags.TopDownReadyButton, function(instance)
		self:_wireTopDownReadyButton(instance)
	end)

	self:_connectTagged(Constants.Tags.TopDownRoundButton, function(instance)
		self:_wireTopDownRoundButton(instance)
	end)

	self:_updateBowlingScoreboards()
	self:_updateTopDownScoreboards()
	self:_updateTopDownReadyStations()
	self:_startBowlingAdRotation()
	self:_startBowlingMaintenanceMotion()
	self:_startCaveAmbientSounds()
	self:_startVoidAmbientMotion()
	self:_startIslandAmbientResources()
	self:_startTopDownPracticeTargetMotion()

	for _, player in ipairs(Players:GetPlayers()) do
		self:_checkExitUnlock(player)
		self:_refreshSecretDoorsForPlayer(player)
		if self.discoveryService:HasDiscovery(player, Constants.Discoveries.VoidFreezeRay.Id) then
			self:_grantFreezeRay(player)
		end
	end
end

function InteractionService:_connectTagged(tagName, wireCallback)
	for _, instance in ipairs(CollectionService:GetTagged(tagName)) do
		wireCallback(instance)
	end

	CollectionService:GetInstanceAddedSignal(tagName):Connect(wireCallback)
end

function InteractionService:_connectPrompt(prompt, callback, options)
	if not prompt or self.connectedPrompts[prompt] then
		return
	end

	self.connectedPrompts[prompt] = true
	prompt.Triggered:Connect(function(player)
		local roomId = nil
		local prologueSafeNavigation = options and options.PrologueSafeNavigation == true
		local doNotRecordInteraction = options and options.DoNotRecordInteraction == true
		if self.roomProgressService then
			if self.roomProgressService.TryTriggerUntouchedPrologue
				and self.roomProgressService:TryTriggerUntouchedPrologue(player, prompt, prologueSafeNavigation)
			then
				return
			end

			local shouldRecordInteraction = not doNotRecordInteraction
				and not (prologueSafeNavigation and self.roomProgressService:IsUntouchedPrologueActive(player))
			if shouldRecordInteraction then
				self.roomProgressService:RecordInteraction(player)
				if self.bunkerEnergyService then
					self.bunkerEnergyService:RecordInteraction(player)
				end
			end
			if self.roomProgressService.GetRoomForPlayer then
				roomId = self.roomProgressService:GetRoomForPlayer(player)
			end
		end

		callback(player)

		if roomId == "CaveEntrance" and not prologueSafeNavigation and self:_setCaveEntranceSealed() then
			local soundParent = prompt.Parent or workspace
			playSound(soundParent, "rbxasset://sounds/snap.wav", 0.75, 0.38)
			task.delay(0.08, function()
				if soundParent.Parent then
					playSound(soundParent, "rbxasset://sounds/button.wav", 0.55, 0.42)
				end
			end)
			self.systemMessageRemote:FireClient(player, "The cave entrance rumbles shut behind you. Someone absolutely noticed.")
		end
	end)
end

function InteractionService:_canUseTeleport(player)
	if not player or not player.Parent then
		return false
	end

	local now = os.clock()
	if now - (self.teleportCooldownByUserId[player.UserId] or 0) < 1.15 then
		return false
	end

	self.teleportCooldownByUserId[player.UserId] = now
	return true
end

function InteractionService:_getBunkerSubsystemPower()
	if self.bunkerEnergyService and self.bunkerEnergyService.GetSubsystemPower then
		return self.bunkerEnergyService:GetSubsystemPower()
	end

	return 1
end

function InteractionService:_getBunkerPowerState()
	local power = self:_getBunkerSubsystemPower()
	local minimum = Constants.BunkerEnergy.SubsystemMinimumPower or 0.14
	local weak = Constants.BunkerEnergy.SubsystemWeakPower or 0.38
	local full = Constants.BunkerEnergy.SubsystemFullPower or 0.72

	if power <= minimum then
		return "Offline", power
	elseif power <= weak then
		return "Flicker", power
	elseif power <= full then
		return "Weak", power
	end

	return "Ready", power
end

function InteractionService:_bunkerSputter(part, message)
	if part then
		playSound(part, BUNKER_SHUTDOWN_SOUND_ID, BUNKER_SHUTDOWN_SOUND_VOLUME, 1)
	end

	if message then
		self.systemMessageRemote:FireAllClients(message)
	end
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

function InteractionService:_broadcastBunkerReclaimMessage(key, message)
	if not message then
		return
	end

	local now = os.clock()
	local messageKey = key or "default"
	if now - (self.bunkerReclaimMessageAtByKey[messageKey] or 0) < BUNKER_RECLAIM_MESSAGE_COOLDOWN then
		return
	end

	self.bunkerReclaimMessageAtByKey[messageKey] = now
	self.systemMessageRemote:FireAllClients(message)
end

function InteractionService:_scheduleBunkerReclaim(root, options)
	if not root then
		return
	end

	options = options or {}
	local delaySeconds = options.Delay or 90
	local duration = options.Duration or 1.35
	local sinkDistance = options.SinkDistance or 2.6
	local driftDistance = options.DriftDistance or 0.42
	local decayDuration = options.DecayDuration or Constants.MatterConversion.DecayDurationSeconds or 14
	local decayMinimumDelay = Constants.MatterConversion.DecayMinimumDelaySeconds or 8
	local decayDelay = if options.DecayDelay ~= nil
		then options.DecayDelay
		else delaySeconds - (options.DecayLeadSeconds or Constants.MatterConversion.DecayLeadSeconds or 22)

	if options.SkipDecay ~= true and delaySeconds >= decayMinimumDelay and decayDuration > 0 then
		task.delay(math.max(0, decayDelay), function()
			if not root or not root.Parent then
				return
			end

			local parts = {}
			for _, instance in ipairs(getInstanceAndDescendants(root)) do
				if instance:IsA("BasePart") and instance.Parent then
					table.insert(parts, instance)
				end
			end

			if #parts == 0 then
				return
			end

			self:_broadcastBunkerReclaimMessage(
				(options.Key or "matter") .. "_decay",
				options.DecayMessage or "Released matter loses its color. Somewhere under the floor, machinery gets patient."
			)

			for _, part in ipairs(parts) do
				if part.Parent and part:GetAttribute("BunkerMatterDecayStarted") ~= true then
					part:SetAttribute("BunkerMatterDecayStarted", true)
					part:SetAttribute("MatterConversionOriginalColor", part.Color)
					tweenPart(part, decayDuration, {
						Color = options.DecayColor or Constants.MatterConversion.DecayColor or Color3.fromRGB(42, 43, 42),
					}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
				end
			end
		end)
	end

	task.delay(delaySeconds, function()
		if not root or not root.Parent then
			return
		end

		local parts = {}
		for _, instance in ipairs(getInstanceAndDescendants(root)) do
			if instance:IsA("ProximityPrompt") then
				instance.Enabled = false
			elseif instance:IsA("BasePart") then
				table.insert(parts, instance)
			end
		end

		if #parts == 0 then
			root:Destroy()
			return
		end

		self:_broadcastBunkerReclaimMessage(options.Key, options.Message)
		if self.bunkerEnergyService then
			self.bunkerEnergyService:RecordMatterReclaimed(options.PowerPartCount or #parts)
		end

		for index, part in ipairs(parts) do
			if part.Parent then
				part.Anchored = true
				part.CanCollide = false
				part.CanTouch = false
				part.CanQuery = false

				local drift = Vector3.new(
					math.sin(index * 2.37) * driftDistance,
					-sinkDistance,
					math.cos(index * 1.91) * driftDistance
				)
				local targetSize = Vector3.new(
					math.max(0.05, part.Size.X * 0.28),
					math.max(0.05, part.Size.Y * 0.28),
					math.max(0.05, part.Size.Z * 0.28)
				)

				tweenPart(part, duration, {
					CFrame = part.CFrame + drift,
					Size = targetSize,
					Transparency = 1,
				}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end
		end

		task.delay(duration + 0.15, function()
			if root and root.Parent then
				root:Destroy()
			end
		end)
	end)
end

function InteractionService:_getActiveObjectRainParts()
	local parts = {}
	for _, part in ipairs(CollectionService:GetTagged(Constants.Tags.ObjectRainObject)) do
		if part:IsA("BasePart") and part.Parent then
			table.insert(parts, part)
		end
	end

	return parts
end

function InteractionService:_openObjectRainSortingSlots()
	local openedCount = 0

	for _, floor in ipairs(CollectionService:GetTagged(Constants.Tags.FloorSection)) do
		if floor:IsA("BasePart") then
			if floor.CanCollide then
				openedCount += 1
			end
			floor.Transparency = 1
			floor.CanCollide = false
		end
	end

	return openedCount
end

function InteractionService:_shakeObjectRainDownstairs(parts)
	local random = self.objectRainSortRandom or Random.new()
	local shakenCount = 0

	for _, part in ipairs(parts) do
		if part:IsA("BasePart") and part.Parent then
			shakenCount += 1
			part.Anchored = false
			part.CanCollide = true

			if part.Position.Y > OBJECT_RAIN_SORT_UPPER_Y then
				local towardCenter = Vector3.new(-part.Position.X, 0, -part.Position.Z)
				if towardCenter.Magnitude > 0.1 then
					towardCenter = towardCenter.Unit * random:NextNumber(5, 13)
				end

				part.AssemblyLinearVelocity = Vector3.new(
					random:NextNumber(-22, 22),
					random:NextNumber(-84, -62),
					random:NextNumber(-22, 22)
				) + towardCenter
			else
				part.AssemblyLinearVelocity += Vector3.new(
					random:NextNumber(-28, 28),
					random:NextNumber(-8, 2),
					random:NextNumber(-28, 28)
				)
			end

			part.AssemblyAngularVelocity = Vector3.new(
				random:NextNumber(-18, 18),
				random:NextNumber(-22, 22),
				random:NextNumber(-18, 18)
			)
		end
	end

	return shakenCount
end

function InteractionService:_serviceActiveObjectRain()
	local rainParts = self:_getActiveObjectRainParts()
	if #rainParts == 0 then
		return false
	end

	local now = os.clock()
	local shouldMessage = now - self.objectRainSortLastAt >= OBJECT_RAIN_SORT_COOLDOWN
	if shouldMessage then
		self.objectRainSortLastAt = now
	end

	self:_openObjectRainSortingSlots()
	local shakenCount = self:_shakeObjectRainDownstairs(rainParts)

	if shouldMessage then
		if shakenCount > 0 then
			self.systemMessageRemote:FireAllClients("The floor opens its sorting slots. Something below hums like it recognizes the mess.")
		else
			self.systemMessageRemote:FireAllClients("The floor opens its sorting slots, but the room has already misplaced the evidence.")
		end
	end

	return true
end

function InteractionService:_attachEnergyReservePrompt(primary, itemRoot, options)
	if not primary or not primary:IsA("BasePart") then
		return
	end

	options = options or {}
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = options.PromptName or "PocketEnergyReservePrompt"
	prompt.ActionText = options.ActionText or "Pocket"
	prompt.ObjectText = options.ObjectText or "Loose Matter"
	prompt.HoldDuration = options.HoldDuration or 0.18
	prompt.RequiresLineOfSight = false
	prompt.ClickablePrompt = true
	prompt.MaxActivationDistance = options.MaxActivationDistance or 9
	prompt.KeyboardKeyCode = options.KeyboardKeyCode or Enum.KeyCode.F
	prompt.GamepadKeyCode = options.GamepadKeyCode or Enum.KeyCode.ButtonY
	prompt.Parent = primary

	self:_connectPrompt(prompt, function(player)
		if not primary.Parent then
			return
		end

		if not self.bunkerEnergyService or not self.bunkerEnergyService.GrantEnergyReserveTool then
			self.systemMessageRemote:FireClient(player, "This loose matter refuses to fit in a pocket yet.")
			return
		end

		local ok, message = self.bunkerEnergyService:GrantEnergyReserveTool(player, {
			Kind = options.Kind or "Matter",
			Name = options.Name or "Pocketed Matter",
				ToolTip = options.ToolTip or "Use to steady your energy when the signal starts to drag.",
			RestoreAmount = options.RestoreAmount,
			Color = options.Color or primary.Color,
			GrantMessage = options.GrantMessage,
			UseMessage = options.UseMessage,
		})
		if not ok then
			self.systemMessageRemote:FireClient(player, message or "Your pockets are out of arguments.")
			return
		end

		prompt.Enabled = false
		setPromptEnabled(itemRoot or primary, false)
		playSound(primary, "rbxasset://sounds/snap.wav", 0.42, 1.08)
		self.systemMessageRemote:FireClient(player, message or "Pocketed for later. It pulses once like it understood.")
		self:_scheduleBunkerReclaim(itemRoot or primary, {
			Delay = 0.12,
			Key = options.ReclaimKey or "pocket_energy",
			Message = options.ReclaimMessage or "A pocket-sized bit of loose matter leaves almost no crumbs for the floor.",
			SinkDistance = options.SinkDistance or 1.3,
			Duration = options.ReclaimDuration or 0.65,
			SkipDecay = true,
		})
	end)
end

function InteractionService:_attachLooseFruitEatPrompt(primary, fruitRoot)
	if not primary or not primary:IsA("BasePart") then
		return
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "LooseFruitEatPrompt"
	prompt.ActionText = "Eat"
	prompt.ObjectText = "Loose Fruit - Eat / Pocket"
	prompt.HoldDuration = 0.12
	prompt.RequiresLineOfSight = false
	prompt.ClickablePrompt = true
	prompt.MaxActivationDistance = 9
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.Parent = primary

	self:_connectPrompt(prompt, function(player)
		if not primary.Parent then
			return
		end

		prompt.Enabled = false
		setPromptEnabled(fruitRoot or primary, false)
		if self.bunkerEnergyService then
			self.bunkerEnergyService:RecordFruitEaten(player)
		end

		playSound(primary, "rbxasset://sounds/snap.wav", 0.48, 1.18)
		self.systemMessageRemote:FireClient(player, "The fruit helps. Nearby lights react to the leftovers.")
		self:_scheduleBunkerReclaim(fruitRoot or primary, {
			Delay = 0.18,
			Key = "fruit_eaten",
			Message = "A piece of fruit disappears into the room before anyone can file a snack report.",
			SinkDistance = 1.7,
			Duration = 0.8,
		})
	end)

	self:_attachEnergyReservePrompt(primary, fruitRoot, {
		PromptName = "LooseFruitPocketPrompt",
		ActionText = "Pocket",
		ObjectText = "Loose Fruit - Eat / Pocket",
		Kind = "Fruit",
		Name = "Pocketed Fruit",
		RestoreAmount = Constants.BunkerEnergy.FruitEnergyRestore or 0.32,
		Color = primary.Color,
		GrantMessage = "Fruit pocketed for later. The room signal stays politely neutral.",
		UseMessage = "The fruit helps your energy. Nearby lights react to the transaction.",
		ReclaimKey = "fruit_pocketed",
		ReclaimMessage = "The Snack Lab quietly absorbs the fruit-shaped gap left behind.",
	})
end

function InteractionService:_getDroppedInventoryItemSize(itemData)
	local kind = itemData and itemData.Kind or "Item"
	local size = itemData and itemData.Size
	if typeof(size) == "Vector3" then
		return size
	end

	if kind == "IslandRock" then
		return Vector3.new(0.9, 0.74, 0.9)
	elseif kind == "IslandWood" then
		return Vector3.new(0.52, 0.42, 1.9)
	elseif kind == "Popcorn" then
		return Vector3.new(0.55, 0.46, 0.55)
	end

	return Vector3.new(0.82, 0.82, 0.82)
end

function InteractionService:_getInventoryDropCFrame(player, itemData)
	local rootPart = getRootPart(player)
	if not rootPart then
		return nil
	end

	local forward = rootPart.CFrame.LookVector
	local flatForward = Vector3.new(forward.X, 0, forward.Z)
	if flatForward.Magnitude < 0.05 then
		flatForward = Vector3.new(0, 0, -1)
	else
		flatForward = flatForward.Unit
	end

	local size = self:_getDroppedInventoryItemSize(itemData)
	local rayOrigin = rootPart.Position + flatForward * INVENTORY_DROP_DISTANCE + Vector3.new(0, INVENTORY_DROP_RAY_HEIGHT, 0)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }
	params.IgnoreWater = false

	local result = workspace:Raycast(rayOrigin, Vector3.new(0, -INVENTORY_DROP_RAY_DEPTH, 0), params)
	local position = if result then result.Position + Vector3.new(0, size.Y / 2 + 0.04, 0) else rootPart.Position + flatForward * INVENTORY_DROP_DISTANCE + Vector3.new(0, size.Y / 2, 0)
	return CFrame.lookAt(position, position + flatForward)
end

function InteractionService:_refreshDroppedInventoryCounts(player, kind)
	if not player then
		return
	end

	if kind == "IslandRock" then
		self.islandRockCountByUserId[player.UserId] = self:_getPocketItemCount(player, "IslandRock", self.islandRockCountByUserId)
	elseif kind == "IslandWood" then
		self.islandWoodCountByUserId[player.UserId] = self:_getPocketItemCount(player, "IslandWood", self.islandWoodCountByUserId)
	end
end

function InteractionService:_claimDroppedInventoryRoot(root)
	if not root or not root.Parent or root:GetAttribute("DroppedInventoryClaimed") == true then
		return false
	end

	root:SetAttribute("DroppedInventoryClaimed", true)
	return true
end

function InteractionService:_releaseDroppedInventoryRoot(root)
	if root and root.Parent then
		root:SetAttribute("DroppedInventoryClaimed", false)
	end
end

function InteractionService:_fadeAndDestroyDroppedInventory(root)
	if not root or not root.Parent then
		return
	end

	setPromptEnabled(root, false)
	for _, instance in ipairs(getInstanceAndDescendants(root)) do
		if instance:IsA("BasePart") then
			instance.CanCollide = false
			instance.CanTouch = false
			tweenPart(instance, 0.18, {
				Transparency = 1,
				CFrame = instance.CFrame + Vector3.new(0, 0.24, 0),
			}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		end
	end
	Debris:AddItem(root, 0.24)
end

function InteractionService:_scheduleDroppedInventoryAbsorb(root, itemData)
	if not root or not root.Parent or root:GetAttribute("DroppedInventoryAbsorbScheduled") == true then
		return
	end

	root:SetAttribute("DroppedInventoryAbsorbScheduled", true)
	task.delay(math.max(0, INVENTORY_DROP_ABSORB_DELAY - 0.05), function()
		if root and root.Parent then
			root:SetAttribute("DroppedInventoryClaimed", true)
		end
	end)

	self:_scheduleBunkerReclaim(root, {
		Delay = INVENTORY_DROP_ABSORB_DELAY,
		Duration = INVENTORY_DROP_ABSORB_DURATION,
		SinkDistance = 2.4,
		DriftDistance = 0.24,
		DecayDelay = INVENTORY_DROP_DECAY_DELAY,
		DecayDuration = INVENTORY_DROP_DECAY_DURATION,
		Key = "dropped_inventory",
		DecayMessage = "Dropped supplies go dull at the edges. The bunker has noticed loose inventory.",
		Message = ("%s sinks into the bunker before it can become a storage policy."):format(
			(itemData and itemData.Name) or "A dropped item"
		),
		PowerPartCount = 1,
	})
end

function InteractionService:_createDroppedInventoryPart(itemData, cframe)
	local kind = itemData and itemData.Kind or "Item"
	local inventoryType = itemData and itemData.InventoryType or "PocketItem"
	local material = itemData and itemData.Material
	if not material then
		material = if kind == "IslandRock" then Enum.Material.Slate elseif kind == "IslandWood" then Enum.Material.Wood else Enum.Material.SmoothPlastic
	end
	local color = itemData and itemData.Color
	if not color then
		color = if kind == "IslandRock" then Color3.fromRGB(112, 113, 111) elseif kind == "IslandWood" then Color3.fromRGB(129, 82, 45) elseif kind == "Matter" then Color3.fromRGB(119, 255, 203) else Color3.fromRGB(255, 134, 35)
	end
	local shape = itemData and itemData.Shape
	if not shape then
		shape = if kind == "IslandRock" or inventoryType == "EnergyReserve" then Enum.PartType.Ball else Enum.PartType.Block
	end

	local part = Instance.new("Part")
	part.Name = ("Dropped%s"):format(kind)
	part.Anchored = true
	part.CanCollide = inventoryType == "PocketItem" and kind ~= TOP_DOWN_WATER_BALLOON_KIND
	part.CanTouch = false
	part.CanQuery = true
	part.Material = material
	part.Color = color
	part.Size = self:_getDroppedInventoryItemSize(itemData)
	part.Shape = shape
	part.CFrame = cframe
	part.Parent = workspace
	part:SetAttribute("DroppedInventoryItem", true)
	part:SetAttribute("DroppedInventoryKind", kind)
	CollectionService:AddTag(part, Constants.Tags.TemporaryObject)

	if inventoryType == "EnergyReserve" and kind ~= "Popcorn" then
		local cap = Instance.new("Part")
		cap.Name = "DroppedReserveCap"
		cap.Anchored = true
		cap.CanCollide = false
		cap.CanTouch = false
		cap.CanQuery = false
		cap.Material = Enum.Material.SmoothPlastic
		cap.Color = if kind == "Matter" then Color3.fromRGB(236, 246, 255) else Color3.fromRGB(72, 96, 46)
		cap.Size = Vector3.new(0.18, 0.34, 0.18)
		cap.CFrame = part.CFrame * CFrame.new(0, part.Size.Y / 2 + 0.16, 0)
		cap.Parent = part
	end

	return part
end

function InteractionService:_playRockDropSound(parent)
	local soundId = chooseRandomAudioId(ROCK_DROP_SOUND_IDS, self.inventoryAudioRandom, self.lastRockDropSoundId)
	if not soundId then
		return
	end

	self.lastRockDropSoundId = soundId
	playSound(parent, soundId, ROCK_DROP_VOLUME, 1)
end

function InteractionService:_attachDroppedPocketItemPrompt(primary, itemData)
	if not primary or not primary:IsA("BasePart") then
		return
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "DroppedPocketItemPrompt"
	prompt.ActionText = "Pick Up"
	prompt.ObjectText = itemData.Name or "Dropped Item"
	prompt.HoldDuration = 0.12
	prompt.RequiresLineOfSight = false
	prompt.ClickablePrompt = true
	prompt.MaxActivationDistance = 9
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonY
	prompt.Parent = primary

	self:_connectPrompt(prompt, function(player)
		if not self:_claimDroppedInventoryRoot(primary) then
			return
		end

		local ok, message = self:_grantPocketItem(player, {
			Kind = itemData.Kind or "Item",
			Name = itemData.Name,
			ToolTip = itemData.ToolTip,
			Color = itemData.Color or primary.Color,
			Material = itemData.Material,
			Size = itemData.Size,
			Shape = itemData.Shape,
			StackLimit = itemData.StackLimit,
			GrantMessage = ("%s picked up."):format(itemData.Name or "Item"),
		})
		if not ok then
			self:_releaseDroppedInventoryRoot(primary)
			self.systemMessageRemote:FireClient(player, message or "Your pockets are full.")
			return
		end

		self:_refreshDroppedInventoryCounts(player, itemData.Kind)
		if itemData.Kind == TOP_DOWN_WATER_BALLOON_KIND then
			self:_fireTopDownAmmo(player)
		end
		playSound(primary, "rbxasset://sounds/button.wav", 0.32, 0.86)
		self.systemMessageRemote:FireClient(player, message or ("%s picked up."):format(itemData.Name or "Item"))
		self:_fadeAndDestroyDroppedInventory(primary)
	end)
end

function InteractionService:_attachDroppedEnergyPrompts(primary, itemData)
	if not primary or not primary:IsA("BasePart") then
		return
	end

	local kind = itemData.Kind or "Fruit"
	local useAction = if kind == "Fruit" then "Eat" else "Use"
	local objectText = ("%s - %s / Pocket"):format(itemData.Name or "Energy Item", useAction)

	local usePrompt = Instance.new("ProximityPrompt")
	usePrompt.Name = "DroppedEnergyUsePrompt"
	usePrompt.ActionText = useAction
	usePrompt.ObjectText = objectText
	usePrompt.HoldDuration = 0.12
	usePrompt.RequiresLineOfSight = false
	usePrompt.ClickablePrompt = true
	usePrompt.MaxActivationDistance = 9
	usePrompt.KeyboardKeyCode = Enum.KeyCode.E
	usePrompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	usePrompt.Parent = primary

	self:_connectPrompt(usePrompt, function(player)
		if not self:_claimDroppedInventoryRoot(primary) then
			return
		end

		if self.bunkerEnergyService then
			if kind == "Fruit" and self.bunkerEnergyService.RecordFruitEaten then
				self.bunkerEnergyService:RecordFruitEaten(player, itemData.RestoreAmount)
			elseif self.bunkerEnergyService.RecordEnergyItemUsed then
				self.bunkerEnergyService:RecordEnergyItemUsed(player, kind, itemData.RestoreAmount)
			end
		end

		playSound(primary, "rbxasset://sounds/snap.wav", 0.45, 1.1)
		self.systemMessageRemote:FireClient(player, if kind == "Fruit" then "The fruit helps. Nearby lights react to the leftovers." else "Energy returns for a moment. Nearby lights react to the transaction.")
		self:_fadeAndDestroyDroppedInventory(primary)
	end)

	local pocketPrompt = Instance.new("ProximityPrompt")
	pocketPrompt.Name = "DroppedEnergyPocketPrompt"
	pocketPrompt.ActionText = "Pocket"
	pocketPrompt.ObjectText = objectText
	pocketPrompt.HoldDuration = 0.18
	pocketPrompt.RequiresLineOfSight = false
	pocketPrompt.ClickablePrompt = true
	pocketPrompt.MaxActivationDistance = 9
	pocketPrompt.KeyboardKeyCode = Enum.KeyCode.F
	pocketPrompt.GamepadKeyCode = Enum.KeyCode.ButtonY
	pocketPrompt.Parent = primary

	self:_connectPrompt(pocketPrompt, function(player)
		if not self:_claimDroppedInventoryRoot(primary) then
			return
		end

		if not self.bunkerEnergyService or not self.bunkerEnergyService.GrantEnergyReserveTool then
			self:_releaseDroppedInventoryRoot(primary)
			self.systemMessageRemote:FireClient(player, "This item refuses to fit in a pocket yet.")
			return
		end

		local ok, message = self.bunkerEnergyService:GrantEnergyReserveTool(player, {
			Kind = kind,
			Name = itemData.Name,
			ToolTip = itemData.ToolTip,
			RestoreAmount = itemData.RestoreAmount,
			Color = itemData.Color or primary.Color,
			GrantMessage = ("%s pocketed."):format(itemData.Name or "Energy item"),
			UseMessage = if kind == "Fruit" then "The fruit helps your energy. Nearby lights react to the transaction." else nil,
		})
		if not ok then
			self:_releaseDroppedInventoryRoot(primary)
			self.systemMessageRemote:FireClient(player, message or "Your pockets are out of room.")
			return
		end

		playSound(primary, "rbxasset://sounds/button.wav", 0.32, 0.95)
		self.systemMessageRemote:FireClient(player, message or ("%s pocketed."):format(itemData.Name or "Energy item"))
		self:_fadeAndDestroyDroppedInventory(primary)
	end)
end

function InteractionService:_spawnDroppedInventoryItem(player, itemData, cframe)
	if not cframe then
		return false
	end

	local part = self:_createDroppedInventoryPart(itemData, cframe)
	if itemData.InventoryType == "EnergyReserve" then
		self:_attachDroppedEnergyPrompts(part, itemData)
	else
		self:_attachDroppedPocketItemPrompt(part, itemData)
	end

	if itemData.Kind == "IslandRock" then
		self:_playRockDropSound(part)
	else
		playSound(part, "rbxasset://sounds/button.wav", 0.25, 0.72)
	end
	self:_scheduleDroppedInventoryAbsorb(part, itemData)
	self.systemMessageRemote:FireClient(player, ("%s dropped."):format(itemData.Name or "Item"))
	return true
end

function InteractionService:_findSecurityWeightPlateForDrop(player, dropCFrame)
	if self.securityPressurePlateState.Weight or not dropCFrame then
		return nil
	end

	local candidatePositions = { dropCFrame.Position }
	local rootPart = getRootPart(player)
	if rootPart then
		table.insert(candidatePositions, rootPart.Position)
	end

	for _, plate in ipairs(CollectionService:GetTagged(Constants.Tags.SecurityPressurePlate)) do
		if plate:IsA("BasePart") and (plate:GetAttribute("PlateIndex") or 0) == 2 then
			for _, position in ipairs(candidatePositions) do
				local relative = plate.CFrame:PointToObjectSpace(position)
				local insideX = math.abs(relative.X) <= plate.Size.X / 2 + SECURITY_WEIGHT_DROP_MARGIN
				local insideZ = math.abs(relative.Z) <= plate.Size.Z / 2 + SECURITY_WEIGHT_DROP_MARGIN
				if insideX and insideZ and math.abs(relative.Y) <= 7 then
					return plate
				end
			end
		end
	end

	return nil
end

function InteractionService:_placeDroppedRockOnSecurityPlate(player, itemData, plate)
	if not plate or not plate:IsA("BasePart") then
		return false
	end

	local baseCFrame = plate:GetAttribute("BaseCFrame") or plate.CFrame
	local size = self:_getDroppedInventoryItemSize(itemData)
	local rock = self:_createDroppedInventoryPart(itemData, baseCFrame * CFrame.new(0, plate.Size.Y / 2 + size.Y / 2 + 0.05, 0))
	rock.Name = "SecurityWeightBeachRock"
	rock.CanCollide = true
	rock:SetAttribute("SecurityWeightRock", true)

	self.securityPressurePlateState.Weight = true
	tweenPart(plate, 0.12, {
		Color = Color3.fromRGB(119, 255, 203),
		CFrame = baseCFrame * CFrame.new(0, -0.08, 0),
	})
	self:_playRockDropSound(rock)

	if self.securityPressurePlateState.Badge then
		self:_setSecurityControlsPowered(true, plate)
		self.systemMessageRemote:FireClient(player, "The beach rock settles on the weight plate. Security controls power up.")
	else
		self.systemMessageRemote:FireClient(player, "The beach rock settles on the weight plate. The badge plate is still waiting.")
	end

	return true
end

function InteractionService:_handleInventoryActionRemote(player, payload)
	if typeof(payload) ~= "table" or payload.Action ~= "DropEquipped" then
		return
	end

	local now = os.clock()
	local lastDropAt = self.inventoryDropAtByUserId[player.UserId] or 0
	if now - lastDropAt < INVENTORY_DROP_COOLDOWN then
		return
	end
	self.inventoryDropAtByUserId[player.UserId] = now

	if not getRootPart(player) then
		return
	end

	if not self.bunkerEnergyService or not self.bunkerEnergyService.DropOneEquippedInventoryItem then
		self.systemMessageRemote:FireClient(player, "Inventory drops are not available right now.")
		return
	end

	local ok, itemData, message = self.bunkerEnergyService:DropOneEquippedInventoryItem(player)
	if not ok or not itemData then
		self.systemMessageRemote:FireClient(player, message or "Hold a pocket item before dropping it.")
		return
	end

	self:_refreshDroppedInventoryCounts(player, itemData.Kind)
	if itemData.Kind == TOP_DOWN_WATER_BALLOON_KIND then
		self:_fireTopDownAmmo(player)
	end
	local dropCFrame = self:_getInventoryDropCFrame(player, itemData)
	if itemData.Kind == "IslandRock" then
		local plate = self:_findSecurityWeightPlateForDrop(player, dropCFrame)
		if plate and self:_placeDroppedRockOnSecurityPlate(player, itemData, plate) then
			self:_refreshDroppedInventoryCounts(player, itemData.Kind)
			return
		end
	end

	self:_spawnDroppedInventoryItem(player, itemData, dropCFrame)
end

function InteractionService:_wireLibraryBookStorm(book)
	local prompt = getPrompt(book)
	self.libraryBookStormState[book] = self.libraryBookStormState[book] or {
		Reacting = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.libraryBookStormState[book]
		if not state or state.Reacting or not book:IsA("BasePart") then
			return
		end

		state.Reacting = true
		self.discoveryService:Unlock(player, Constants.Discoveries.LibraryBookStorm.Id)
		playSound(book, "rbxasset://sounds/snap.wav", 0.65, 0.72)
		task.delay(0.12, function()
			if book.Parent then
				playSound(book, "rbxasset://sounds/button.wav", 0.45, 0.5)
			end
		end)

		local origin = book.CFrame
		for index = 1, 46 do
			task.delay((index - 1) * 0.015, function()
				if not book.Parent then
					return
				end

				local looseBook = Instance.new("Part")
				looseBook.Name = "LibraryFlyingBook"
				looseBook.Anchored = false
				looseBook.CanCollide = true
				looseBook.Material = Enum.Material.SmoothPlastic
				looseBook.Color = Color3.fromRGB(70 + (index * 29) % 160, 42 + (index * 17) % 130, 70 + (index * 41) % 140)
				looseBook.Size = Vector3.new(0.55 + (index % 3) * 0.08, 0.16, 1.15 + (index % 4) * 0.12)
				looseBook.CFrame = origin
					* CFrame.new(((index % 9) - 4) * 0.35, 0.35 + (index % 5) * 0.16, -0.8 - (index % 4) * 0.18)
					* CFrame.Angles(math.rad(index * 17), math.rad(index * 23), math.rad(index * 31))
				looseBook.CustomPhysicalProperties = PhysicalProperties.new(0.45, 0.55, 0.35, 1, 1)
				looseBook.Parent = workspace
				CollectionService:AddTag(looseBook, Constants.Tags.TemporaryObject)

				looseBook.AssemblyLinearVelocity = Vector3.new(
					((index % 7) - 3) * 4.5,
					18 + (index % 6) * 2.2,
					10 + (index % 8) * 2.4
				)
					looseBook.AssemblyAngularVelocity = Vector3.new(index % 5, 7 + index % 4, index % 6) * 2.5
					self:_scheduleBunkerReclaim(looseBook, {
						Delay = 118 + (index % 12) * 2,
						Key = "library_books",
						Message = "The Library shelves stop asking. A few loose books slide toward seams in the floor.",
						SinkDistance = 2.2,
					})
					Debris:AddItem(looseBook, 160)
				end)
			end

		if book.Parent then
			tweenPart(book, 0.18, {
				Color = Color3.fromRGB(119, 255, 203),
			})
		end
		self.systemMessageRemote:FireClient(player, "The Library shelves unload several strong opinions at once.")
		task.delay(2.6, function()
			state.Reacting = false
		end)
	end)
end

function InteractionService:_stopSecurityCamera(player, message)
	self.securityCameraSessionByUserId[player.UserId] = nil
	self.securityCameraRemote:FireClient(player, {
		Action = "Stop",
		Message = message,
	})
end

function InteractionService:_handleSecurityCameraRemote(player, payload)
	if typeof(payload) ~= "table" then
		return
	end

	local action = payload.Action
	if action == "Stop" then
		self:_stopSecurityCamera(player)
		return
	end

	if action ~= "HiddenButton" then
		return
	end

	local session = self.securityCameraSessionByUserId[player.UserId]
	if not session or os.clock() > session.ExpiresAt then
		self.securityCameraSessionByUserId[player.UserId] = nil
		return
	end

	self.discoveryService:Unlock(player, Constants.Discoveries.SecurityScreenButton.Id)
	self.systemMessageRemote:FireClient(player, "The screen-only button admits it was watching you too.")
	self:_stopSecurityCamera(player, "Button acknowledged. Returning your regular eyeballs.")
end

function InteractionService:_wireSecurityMonitor(monitor)
	local prompt = getPrompt(monitor)

	self:_connectPrompt(prompt, function(player)
		local cameraCFrame = monitor:GetAttribute("CameraCFrame")
		if typeof(cameraCFrame) ~= "CFrame" then
			self.systemMessageRemote:FireClient(player, "This monitor only shows a very suspicious blank screen.")
			return
		end

		self.discoveryService:Unlock(player, Constants.Discoveries.SecurityMonitorWall.Id)
		self.discoveryService:Unlock(player, Constants.Discoveries.SecurityCameraView.Id)
		self.securityCameraSessionByUserId[player.UserId] = {
			ExpiresAt = os.clock() + SECURITY_CAMERA_DURATION,
		}

		if monitor:IsA("BasePart") then
			tweenPart(monitor, 0.18, {
				Color = Color3.fromRGB(255, 88, 128),
			})
		end
		playSound(monitor, "rbxasset://sounds/electronicpingshort.wav", 0.65, 1.35)
		self.securityCameraRemote:FireClient(player, {
			Action = "Start",
			CameraCFrame = cameraCFrame,
			CameraLabel = monitor:GetAttribute("CameraLabel") or "CAM 23 - SECURITY ROOM",
			Duration = SECURITY_CAMERA_DURATION,
		})
		self.systemMessageRemote:FireClient(player, "The monitor changes viewpoint. You appear on the screen with excellent timing.")
	end)
end

function InteractionService:_wireSecurityConsole(console)
	local prompt = getPrompt(console)

	self:_connectPrompt(prompt, function(player)
		self.discoveryService:Unlock(player, Constants.Discoveries.SecurityMonitorWall.Id)
		self.discoveryService:Unlock(player, Constants.Discoveries.SecurityBunkerEnergy.Id)
		setBunkerEnergyMonitorUnlocked(player)
		self:_updateSecurityCaseStudyPanels(player)
		playSound(console, "rbxasset://sounds/button.wav", 0.5, 0.8)
		if console:IsA("BasePart") then
			tweenPart(console, 0.18, {
				Color = Color3.fromRGB(119, 255, 203),
			})
			task.delay(0.65, function()
				if console.Parent then
					tweenPart(console, 0.3, {
						Color = console:GetAttribute("BaseColor") or Color3.fromRGB(30, 39, 50),
					})
				end
			end)
		end
		self.systemMessageRemote:FireClient(player, "Subject Case Study Alpha loaded. The Signal Band now mirrors bunker status; Security records observation without feeding the bunker.")
	end)
end

function InteractionService:_wireSecurityRedPhone(phone)
	local prompt = getPrompt(phone)

	self:_connectPrompt(prompt, function(player)
		self.discoveryService:Unlock(player, Constants.Discoveries.SecurityRedPhone.Id)
		for ring = 1, 3 do
			task.delay((ring - 1) * 0.22, function()
				playSound(phone, "rbxasset://sounds/electronicpingshort.wav", 0.45, 0.72 + ring * 0.08)
			end)
		end
		if phone:IsA("BasePart") then
			local baseCFrame = phone:GetAttribute("BaseCFrame") or phone.CFrame
			tweenPart(phone, 0.12, {
				CFrame = baseCFrame * CFrame.Angles(0, 0, math.rad(8)),
			})
			task.delay(0.22, function()
				if phone.Parent then
					tweenPart(phone, 0.18, {
						CFrame = baseCFrame,
					})
				end
			end)
		end
		self.systemMessageRemote:FireClient(player, "The red phone rings once, then decides that was enough responsibility.")
	end)
end

function InteractionService:_wireSecurityTapeDeck(tapeDeck)
	local prompt = getPrompt(tapeDeck)

	self:_connectPrompt(prompt, function(player)
		self.discoveryService:Unlock(player, Constants.Discoveries.SecurityTapeDeck.Id)
		playSound(tapeDeck, "rbxasset://sounds/button.wav", 0.5, 0.48)
		playSound(tapeDeck, "rbxasset://sounds/electronicpingshort.wav", 0.38, 0.62)
		setTextLabelText(tapeDeck, "SecurityTapeText", "TAPE 01\nSUBJECT TOUCHED\nTHE TAPE DECK")
		self.systemMessageRemote:FireClient(player, "The tape deck updates the evidence with troubling efficiency.")
	end)
end

local function setBunkerEnergyMonitorUnlocked(player)
	player:SetAttribute(SIGNAL_BAND_ATTRIBUTE, true)
	player:SetAttribute("DontTouchItBunkerEnergyMonitorUnlocked", true)

	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if playerGui then
		playerGui:SetAttribute(SIGNAL_BAND_ATTRIBUTE, true)
		playerGui:SetAttribute("DontTouchItBunkerEnergyMonitorUnlocked", true)
	end
end

function InteractionService:_buildSecurityCaseStudyText(player)
	local order = Constants.RoomDiscoveryOrder.SecurityRoom or {}
	local found = if self.discoveryService then self.discoveryService:GetDiscoveryCount(player, order) else 0
	local total = #order
	local rows = {
		"SUBJECT CASE STUDY ALPHA",
		("%s PROGRESS: %d/%d"):format(string.upper(player.Name), found, total),
		"SECURITY CONTRIBUTION: 0%",
		"OBSERVATION: ACTIVE",
	}

	for _, discoveryId in ipairs(order) do
		local discovery = Constants.GetDiscovery(discoveryId)
		local discovered = self.discoveryService and self.discoveryService:HasDiscovery(player, discoveryId)
		local state = if discovered then "FOUND" else "CLUE"
		table.insert(rows, ("%s - %s"):format(state, discovery and discovery.Name or discoveryId))
	end

	return table.concat(rows, "\n")
end

function InteractionService:_updateSecurityCaseStudyPanels(player)
	local text = self:_buildSecurityCaseStudyText(player)
	for _, instance in ipairs(workspace:GetDescendants()) do
		if instance.Name == "SecurityCaseStudyAlphaPanel" then
			setTextLabelText(instance, "SecurityCaseStudyText", text)
		end
	end
end

local function formatBunkerDrawText(hunger)
	if hunger >= 0.66 then
		return "irregular"
	elseif hunger >= 0.33 then
		return "active"
	end

	return "quiet"
end

function InteractionService:_wireBunkerPowerMeter(meter)
	local prompt = getPrompt(meter)

	self:_connectPrompt(prompt, function(player)
		if self.discoveryService then
			self.discoveryService:Unlock(player, Constants.Discoveries.SecurityBunkerEnergy.Id)
		end

		setBunkerEnergyMonitorUnlocked(player)
		self:_updateSecurityCaseStudyPanels(player)

		local power = math.clamp(tonumber(player:GetAttribute("DontTouchItBunkerPower")) or 0, 0, 1)
		local hunger = math.clamp(tonumber(player:GetAttribute("DontTouchItBunkerHunger")) or 0, 0, 1)
		self.systemMessageRemote:FireClient(
			player,
			("Signal Band bunker status unlocked. Power %d%%, draw %s. Security notes this knowledge does not contribute energy."):format(
				math.floor(power * 100 + 0.5),
				formatBunkerDrawText(hunger)
			)
		)
	end)
end

function InteractionService:_wireObservationMirror(mirror)
	local prompt = getPrompt(mirror)

	self:_connectPrompt(prompt, function(player)
		local label = mirror:GetAttribute("ObservationLabel") or "OBS-??-01"
		local placeId = mirror:GetAttribute("ObservationPlaceId")
		self.discoveryService:Unlock(player, Constants.Discoveries.SecurityObservationMirror.Id)
		playSound(mirror, "rbxasset://sounds/electronicpingshort.wav", 0.42, 0.62)
		if mirror:IsA("BasePart") then
			tweenPart(mirror, 0.18, {
				Color = Color3.fromRGB(119, 255, 203),
				Transparency = 0.28,
			})
			task.delay(0.85, function()
				if mirror.Parent then
					tweenPart(mirror, 0.45, {
						Color = mirror:GetAttribute("BaseColor") or Color3.fromRGB(128, 176, 190),
						Transparency = mirror:GetAttribute("BaseTransparency") or 0.42,
					})
				end
			end)
		end
		self.systemMessageRemote:FireClient(
			player,
			("The glass reflects a coordinate: %s. The Teleport Key may know what to do with observation rooms now."):format(label)
		)
		if placeId then
			player:SetAttribute("DontTouchItLastObservationCoordinate", placeId)
		end
	end)
end

function InteractionService:_setSecurityControlsPowered(powered, source)
	self.securityPressurePlateState.Unlocked = powered == true

	for _, console in ipairs(CollectionService:GetTagged(Constants.Tags.SecurityConsole)) do
		if console:IsA("BasePart") then
			tweenPart(console, 0.22, {
				Color = powered and Color3.fromRGB(119, 255, 203) or (console:GetAttribute("BaseColor") or Color3.fromRGB(30, 39, 50)),
			})
		end
	end

	if powered and source then
		playSound(source, "rbxasset://sounds/electronicpingshort.wav", 0.55, 1.4)
	end
end

function InteractionService:_wireSecurityPressurePlate(plate)
	if not plate:IsA("BasePart") then
		return
	end

	plate.Touched:Connect(function(hit)
		if self.securityPressurePlateState.Unlocked then
			return
		end

		local character = hit and hit.Parent
		if not character then
			return
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local player = humanoid and Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end

		local plateIndex = plate:GetAttribute("PlateIndex") or 0
		if plateIndex == 1 then
			if not self.discoveryService:HasDiscovery(player, Constants.Discoveries.SleepingIdBadge.Id) then
				self.systemMessageRemote:FireClient(player, "The badge plate wants an ID badge from Sleeping Quarters.")
				playSound(plate, "rbxasset://sounds/snap.wav", 0.32, 0.56)
				return
			end
			self.securityPressurePlateState.Badge = true
		elseif plateIndex == 2 then
			local otherSecurityPlayerPresent = false
			if self.roomProgressService then
				for _, otherPlayer in ipairs(Players:GetPlayers()) do
					if otherPlayer ~= player and self.roomProgressService:GetRoomForPlayer(otherPlayer) == "SecurityRoom" then
						otherSecurityPlayerPresent = true
						break
					end
				end
			end
			local heldRocks = self:_getPocketItemCount(player, "IslandRock", self.islandRockCountByUserId)
			if heldRocks <= 0 and not otherSecurityPlayerPresent then
				self.systemMessageRemote:FireClient(player, "The weight plate wants either a helpful teammate or a beach rock.")
				playSound(plate, "rbxasset://sounds/snap.wav", 0.32, 0.6)
				return
			end
			if not self.securityPressurePlateState.Weight
				and not otherSecurityPlayerPresent
				and self:_consumePocketItem(player, "IslandRock", self.islandRockCountByUserId)
			then
				self.systemMessageRemote:FireClient(player, "The beach rock sits on the plate with official-looking confidence.")
			end
			self.securityPressurePlateState.Weight = true
		end

		tweenPart(plate, 0.12, {
			Color = Color3.fromRGB(119, 255, 203),
			CFrame = (plate:GetAttribute("BaseCFrame") or plate.CFrame) * CFrame.new(0, -0.08, 0),
		})

		if self.securityPressurePlateState.Badge and self.securityPressurePlateState.Weight then
			self:_setSecurityControlsPowered(true, plate)
			self.systemMessageRemote:FireClient(player, "Security controls power up. The room is now officially overprepared.")
		end
	end)
end

function InteractionService:_wireSleepingBunk(bunk)
	local prompt = getPrompt(bunk)

	self:_connectPrompt(prompt, function(player)
		self.discoveryService:Unlock(player, Constants.Discoveries.SleepingCountedBunks.Id)
		playSound(bunk, "rbxasset://sounds/button.wav", 0.35, 0.6)
		local total = bunk:GetAttribute("BunkTotal") or 100
		self.systemMessageRemote:FireClient(player, ("You count %d bunks. That seems like at least several."):format(total))
	end)
end

function InteractionService:_wireSleepingMattress(mattress)
	if not mattress or not mattress:IsA("BasePart") then
		return
	end

	mattress.Touched:Connect(function(hit)
		local character = hit and hit:FindFirstAncestorOfClass("Model")
		if not character then
			return
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoid or not rootPart then
			return
		end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end

		local room = Constants.GetRoom("SleepingQuarters")
		if not room or not positionInZone(rootPart.Position, room.Zone) then
			return
		end

		local now = os.clock()
		if now - (self.sleepingMattressBounceAtByHumanoid[humanoid] or 0) < 0.72 then
			return
		end
		self.sleepingMattressBounceAtByHumanoid[humanoid] = now

		local velocity = rootPart.AssemblyLinearVelocity
		if velocity.Y > 34 then
			return
		end

		rootPart.AssemblyLinearVelocity = Vector3.new(velocity.X, 58, velocity.Z)
		playSound(mattress, "rbxasset://sounds/button.wav", 0.14, 1.7)
	end)
end

function InteractionService:_wireSleepingAlarmClock(clock)
	local prompt = getPrompt(clock)

	self:_connectPrompt(prompt, function(player)
		self.discoveryService:Unlock(player, Constants.Discoveries.SleepingAlarmClock.Id)
		local count = (self.sleepingAlarmStateByUserId[player.UserId] or 0) + 1
		self.sleepingAlarmStateByUserId[player.UserId] = count

		local colors = {
			Color3.fromRGB(255, 202, 103),
			Color3.fromRGB(255, 88, 128),
			Color3.fromRGB(119, 255, 203),
			Color3.fromRGB(150, 112, 255),
		}
		if clock:IsA("BasePart") then
			tweenPart(clock, 0.16, {
				Color = colors[((count - 1) % #colors) + 1],
			})
		end
		setTextLabelText(clock, "SleepingAlarmClockText", if count % 2 == 0 then "12:00\nSTILL" else "12:00\nNOPE")
		playSound(clock, "rbxasset://sounds/electronicpingshort.wav", 0.55, 1.15 + (count % 3) * 0.22)
		self.systemMessageRemote:FireClient(player, "The alarm clock snoozes you back with suspicious patience.")
	end)
end

local function findSleepingLockerHandle(locker, lockerIndex)
	local root = locker and locker.Parent
	if not root then
		return nil
	end

	for _, instance in ipairs(root:GetChildren()) do
		if instance:IsA("BasePart")
			and instance:GetAttribute("SleepingLockerHandle") == true
			and math.floor(tonumber(instance:GetAttribute("LockerIndex")) or 0) == lockerIndex
		then
			return instance
		end
	end

	return nil
end

local function tweenSleepingLockerOpenState(locker, open)
	if not locker or not locker:IsA("BasePart") then
		return
	end

	local closedCFrame = locker:GetAttribute("SleepingLockerClosedCFrame")
	local openCFrame = locker:GetAttribute("SleepingLockerOpenCFrame")
	local targetCFrame = if open and typeof(openCFrame) == "CFrame" then openCFrame else closedCFrame
	if typeof(targetCFrame) ~= "CFrame" then
		targetCFrame = locker.CFrame
	end

	local closedColor = locker:GetAttribute("SleepingLockerClosedColor")
	local openColor = locker:GetAttribute("SleepingLockerOpenColor")
	local targetColor = if open and typeof(openColor) == "Color3" then openColor else closedColor
	if typeof(targetColor) ~= "Color3" then
		targetColor = locker.Color
	end

	tweenPart(locker, 0.22, {
		CFrame = targetCFrame,
		Color = targetColor,
	}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local lockerIndex = math.floor(tonumber(locker:GetAttribute("LockerIndex")) or 0)
	local handle = findSleepingLockerHandle(locker, lockerIndex)
	local handleOffset = handle and handle:GetAttribute("SleepingLockerHandleOffset")
	if handle and handle:IsA("BasePart") and typeof(handleOffset) == "CFrame" then
		tweenPart(handle, 0.22, {
			CFrame = targetCFrame * handleOffset,
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end
end

function InteractionService:_wireSleepingLocker(locker)
	local prompt = getPrompt(locker)

	self:_connectPrompt(prompt, function(player)
		local lockerKind = locker:GetAttribute("LockerKind")
		if lockerKind == "CleaningSupplies" then
			self.discoveryService:Unlock(player, Constants.Discoveries.SleepingLocker.Id)
			playSound(locker, "rbxasset://sounds/snap.wav", 0.5, 0.75)
			setTextLabelText(locker, "SleepingLockerText", "MOP\nBROOM\nBUCKET")
			local root = locker:FindFirstAncestor("SleepingCleaningSuppliesLocker") or locker.Parent
			for _, instance in ipairs(getInstanceAndDescendants(root)) do
				if instance:IsA("BasePart") and instance:GetAttribute("SleepingCleaningContent") == true then
					instance.Transparency = 0
				end
			end
			if locker:IsA("BasePart") then
				tweenPart(locker, 0.18, {
					Color = Color3.fromRGB(119, 255, 203),
				})
			end
			self.systemMessageRemote:FireClient(player, "The cleaning locker opens: mop, broom, and bucket. Suspiciously practical.")
			return
		end

		if lockerKind ~= "Bunk" then
			return
		end

		local lockerIndex = math.floor(tonumber(locker:GetAttribute("LockerIndex")) or 0)
		if lockerIndex <= 0 then
			return
		end

		local isOpen = locker:GetAttribute("SleepingLockerOpen") == true
		local closedCFrame = locker:GetAttribute("SleepingLockerClosedCFrame")
		if isOpen and typeof(closedCFrame) == "CFrame" and (locker.CFrame.Position - closedCFrame.Position).Magnitude < 0.05 then
			isOpen = false
			locker:SetAttribute("SleepingLockerOpen", false)
		end

		local shouldOpen = not isOpen
		locker:SetAttribute("SleepingLockerOpen", shouldOpen)
		if prompt then
			prompt.ActionText = if shouldOpen then "Close" else "Open"
		end

		playSound(locker, "rbxasset://sounds/button.wav", 0.28, if shouldOpen then 0.78 + (lockerIndex % 5) * 0.08 else 0.58)
		tweenSleepingLockerOpenState(locker, shouldOpen)
		setTextLabelText(locker, "SleepingBunkLockerText", if shouldOpen then ("OPEN\n#%02d"):format(lockerIndex) else ("CHEST\n#%02d"):format(lockerIndex))

		if not shouldOpen then
			if locker:GetAttribute("HasIdBadge") == true then
				local badge = locker.Parent and locker.Parent:FindFirstChild("SleepingIdBadge", true)
				if badge and badge:IsA("BasePart") then
					badge.Transparency = 1
					setPromptEnabled(badge, false)
					setSurfaceGuiEnabled(badge, "SleepingIdBadgeText", false)
				end
			end
			self.systemMessageRemote:FireClient(player, ("Bunk locker %02d clicks closed."):format(lockerIndex))
			return
		end

		local checked = self.sleepingLockerCheckedByUserId[player.UserId]
		if not checked then
			checked = {}
			self.sleepingLockerCheckedByUserId[player.UserId] = checked
		end

		local wasNew = checked[lockerIndex] ~= true
		checked[lockerIndex] = true
		local checkedCount = countDictionary(checked)
		local total = math.max(1, math.floor(tonumber(locker:GetAttribute("LockerTotal")) or 100))

		if locker:GetAttribute("HasIdBadge") == true then
			local alreadyHasBadge = self.discoveryService:HasDiscovery(player, Constants.Discoveries.SleepingIdBadge.Id)
			local badge = locker.Parent and locker.Parent:FindFirstChild("SleepingIdBadge", true)
			if badge and badge:IsA("BasePart") and not alreadyHasBadge then
				badge.Transparency = 0
				badge.CanCollide = false
				setPromptEnabled(badge, true)
				setSurfaceGuiEnabled(badge, "SleepingIdBadgeText", true)
				self.systemMessageRemote:FireClient(player, "This last locker contains an ID Badge. That feels important.")
			elseif wasNew then
				self.systemMessageRemote:FireClient(player, ("Bunk locker checked: %d / %d."):format(checkedCount, total))
			else
				self.systemMessageRemote:FireClient(player, ("Bunk locker %02d is still aggressively empty."):format(lockerIndex))
			end
		elseif wasNew then
			self.systemMessageRemote:FireClient(player, ("Bunk locker checked: %d / %d."):format(checkedCount, total))
		else
			self.systemMessageRemote:FireClient(player, ("Bunk locker %02d is still aggressively empty."):format(lockerIndex))
		end

		if checkedCount >= total then
			self.discoveryService:Unlock(player, Constants.Discoveries.SleepingAllLockers.Id)
			self.systemMessageRemote:FireClient(player, "Every bunk locker has been checked. The room has no remaining privacy.")
		end
	end)
end

function InteractionService:_spawnSleepingDreamBubble(source, index)
	if not source or not source.Parent then
		return
	end

	local bubble = Instance.new("Part")
	bubble.Name = "SleepingDreamBubble"
	bubble.Anchored = true
	bubble.CanCollide = false
	bubble.Shape = Enum.PartType.Ball
	bubble.Material = Enum.Material.Neon
	bubble.Color = BOWLING_COSMIC_COLORS[((index - 1) % #BOWLING_COSMIC_COLORS) + 1]
	bubble.Size = Vector3.new(0.65, 0.65, 0.65)
	bubble.CFrame = source.CFrame * CFrame.new(math.cos(index) * 2.4, 0.5 + index * 0.18, math.sin(index) * 2.4)
	bubble.Parent = workspace
	Debris:AddItem(bubble, 2.4)

	tweenPart(bubble, 2.2, {
		Transparency = 1,
		Size = Vector3.new(2.8, 2.8, 2.8),
		CFrame = bubble.CFrame * CFrame.new(0, 5.5, 0),
	}, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
end

function InteractionService:_wireSleepingDreamButton(button)
	local prompt = getPrompt(button)

	self:_connectPrompt(prompt, function(player)
		self.discoveryService:Unlock(player, Constants.Discoveries.SleepingDreamButton.Id)
		playSound(button, "rbxasset://sounds/electronicpingshort.wav", 0.6, 0.44)
		for index = 1, 8 do
			task.delay(index * 0.08, function()
				self:_spawnSleepingDreamBubble(button, index)
			end)
		end
		self.systemMessageRemote:FireClient(player, "The dream button releases several official-looking bubbles.")
	end)
end

function InteractionService:_wireSleepingBlanketFort(fort)
	local prompt = getPrompt(fort)

	self:_connectPrompt(prompt, function(player)
		self.discoveryService:Unlock(player, Constants.Discoveries.SleepingBlanketFort.Id)
		playSound(fort, "rbxasset://sounds/button.wav", 0.35, 0.54)
		setTextLabelText(fort, "BlanketFortText", "FORT\nAPPROVED\nPROBABLY")
		self.systemMessageRemote:FireClient(player, "The blanket fort upgrades itself from suspicious to almost official.")
	end)
end

function InteractionService:_wireSleepingPillowPile(pillow)
	local prompt = getPrompt(pillow)

	self:_connectPrompt(prompt, function(player)
		self.discoveryService:Unlock(player, Constants.Discoveries.SleepingPillowPile.Id)
		playSound(pillow, "rbxasset://sounds/button.wav", 0.4, 1.8)

		if pillow:IsA("BasePart") then
			for puffIndex = 1, 6 do
				local puff = Instance.new("Part")
				puff.Name = "SleepingPillowPuff"
				puff.Anchored = true
				puff.CanCollide = false
				puff.Shape = Enum.PartType.Ball
				puff.Material = Enum.Material.SmoothPlastic
				puff.Color = Color3.fromRGB(245, 248, 255)
				puff.Transparency = 0.28
				puff.Size = Vector3.new(0.45, 0.25, 0.45)
				puff.CFrame = pillow.CFrame * CFrame.new(math.cos(puffIndex) * 0.7, 0.4, math.sin(puffIndex) * 0.7)
				puff.Parent = workspace
				Debris:AddItem(puff, 1.25)
				tweenPart(puff, 1.1, {
					Transparency = 1,
					Size = Vector3.new(1.5, 0.8, 1.5),
					CFrame = puff.CFrame * CFrame.new(math.cos(puffIndex) * 2.2, 1.8, math.sin(puffIndex) * 2.2),
				}, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			end
		end
		self.systemMessageRemote:FireClient(player, "The pillow pile releases a soft complaint.")
	end)
end

function InteractionService:_wireSleepingIdBadge(badge)
	local prompt = getPrompt(badge)

	self:_connectPrompt(prompt, function(player)
		local unlocked = self.discoveryService:Unlock(player, Constants.Discoveries.SleepingIdBadge.Id)
		if self.discoveryService.SyncInventoryTools then
			self.discoveryService:SyncInventoryTools(player)
		end
		if unlocked then
			self.systemMessageRemote:FireClient(player, "ID Badge found. Security plates and one stubborn cave door now have fewer excuses.")
		else
			self.systemMessageRemote:FireClient(player, "You already have the ID Badge clearance.")
		end

		playSound(badge, "rbxasset://sounds/electronicpingshort.wav", 0.45, 1.65)
		if badge:IsA("BasePart") then
			tweenPart(badge, 0.18, {
				Transparency = 1,
				Color = Color3.fromRGB(119, 255, 203),
			})
			badge.CanCollide = false
			setPromptEnabled(badge, false)
			setSurfaceGuiEnabled(badge, "SleepingIdBadgeText", false)
		end
	end)
end

function InteractionService:_wireInfirmaryRecoveryBed(bed)
	local prompt = getPrompt(bed)

	self:_connectPrompt(prompt, function(player)
		self.discoveryService:Unlock(player, Constants.Discoveries.InfirmaryRecoveryBed.Id)
		playSound(bed, "rbxasset://sounds/button.wav", 0.22, 0.62)
		self.systemMessageRemote:FireClient(player, "The recovery bed is already warm. That feels thoughtful, which is not necessarily better.")
	end)
end

function InteractionService:_wireInfirmaryMonitor(monitor)
	local prompt = getPrompt(monitor)

	self:_connectPrompt(prompt, function(player)
		self.discoveryService:Unlock(player, Constants.Discoveries.InfirmaryMonitor.Id)
		setTextLabelText(monitor, "InfirmaryMonitorText", "STATUS\nFUNCTIONAL\nFOR NOW")
		playSound(monitor, "rbxasset://sounds/electronicpingshort.wav", 0.45, 1.35)
		self.systemMessageRemote:FireClient(player, "The monitor reports your condition with the confidence of something that has practiced.")
	end)
end

function InteractionService:_wireInfirmaryCabinet(cabinet)
	local prompt = getPrompt(cabinet)

	self:_connectPrompt(prompt, function(player)
		self.discoveryService:Unlock(player, Constants.Discoveries.InfirmaryCabinet.Id)
		setTextLabelText(cabinet, "InfirmaryCabinetText", "SUPPLIES\nRESTOCKED\n?")
		if cabinet:IsA("BasePart") then
			tweenPart(cabinet, 0.16, {
				Color = Color3.fromRGB(119, 255, 203),
			})
			task.delay(0.45, function()
				if cabinet.Parent then
					tweenPart(cabinet, 0.28, {
						Color = cabinet:GetAttribute("BaseColor") or Color3.fromRGB(215, 226, 229),
					})
				end
			end)
		end
		playSound(cabinet, "rbxasset://sounds/snap.wav", 0.38, 0.78)
		self.systemMessageRemote:FireClient(player, "The cabinet opens onto supplies arranged too neatly for an abandoned place.")
	end)
end

function InteractionService:_wireInfirmaryNourishment(tray)
	local prompt = getPrompt(tray)

	self:_connectPrompt(prompt, function(player)
		self.discoveryService:Unlock(player, Constants.Discoveries.InfirmaryNourishment.Id)
		if self.bunkerEnergyService and self.bunkerEnergyService.RecordEnergyItemUsed then
			self.bunkerEnergyService:RecordEnergyItemUsed(player, "Matter", 0.26)
		end
		playSound(tray, "rbxasset://sounds/snap.wav", 0.32, 1.08)
		self.systemMessageRemote:FireClient(player, "The tray steadies you. The nearby readout brightens like it expected that.")
	end)
end

function InteractionService:_wireGymTreadmill(treadmill)
	local prompt = getPrompt(treadmill)

	self:_connectPrompt(prompt, function(player)
		self.discoveryService:Unlock(player, Constants.Discoveries.GymTreadmill.Id)
		if self.bunkerEnergyService and self.bunkerEnergyService.RecordTrainingActivity then
			self.bunkerEnergyService:RecordTrainingActivity(player, 0.75, 0.006)
		end
		local belt = treadmill.Parent and treadmill.Parent:FindFirstChild("TreadmillBelt")
		if belt and belt:IsA("BasePart") then
			tweenPart(belt, 0.12, {
				Color = Color3.fromRGB(46, 66, 78),
			})
			task.delay(0.45, function()
				if belt.Parent then
					tweenPart(belt, 0.3, {
						Color = Color3.fromRGB(12, 16, 18),
					})
				end
			end)
		end
		playSound(treadmill, "rbxasset://sounds/electronicpingshort.wav", 0.42, 0.9)
		self.systemMessageRemote:FireClient(player, "The treadmill logs one very official almost-step.")
	end)
end

function InteractionService:_wireGymBike(bikeSeat)
	local prompt = getPrompt(bikeSeat)

	self:_connectPrompt(prompt, function(player)
		self.discoveryService:Unlock(player, Constants.Discoveries.GymBike.Id)
		if self.bunkerEnergyService and self.bunkerEnergyService.RecordTrainingActivity then
			self.bunkerEnergyService:RecordTrainingActivity(player, 0.68, 0.005)
		end
		playSound(bikeSeat, "rbxasset://sounds/button.wav", 0.28, 1.45)
		self.systemMessageRemote:FireClient(player, "The stationary bike goes nowhere with alarming purpose.")
	end)
end

function InteractionService:_wireGymWeights(rack)
	local prompt = getPrompt(rack)

	self:_connectPrompt(prompt, function(player)
		self.discoveryService:Unlock(player, Constants.Discoveries.GymWeights.Id)
		if self.bunkerEnergyService and self.bunkerEnergyService.RecordTrainingActivity then
			self.bunkerEnergyService:RecordTrainingActivity(player, 0.82, 0.007)
		end
		playSound(rack, "rbxasset://sounds/button.wav", 0.35, 0.72)
		self.systemMessageRemote:FireClient(player, "The weight rack approves a measurable amount of effort.")
	end)
end

function InteractionService:_wireGymWaterStation(station)
	local prompt = getPrompt(station)

	self:_connectPrompt(prompt, function(player)
		self.discoveryService:Unlock(player, Constants.Discoveries.GymWaterStation.Id)
		if self.bunkerEnergyService and self.bunkerEnergyService.RecordEnergyItemUsed then
			self.bunkerEnergyService:RecordEnergyItemUsed(player, "Water", 0.16)
		end
		playSound(station, "rbxasset://sounds/snap.wav", 0.26, 1.24)
		self.systemMessageRemote:FireClient(player, "The water is cool, clean, and slightly too available.")
	end)
end

local function formatTopDownSeconds(seconds)
	seconds = math.max(0, math.ceil(tonumber(seconds) or 0))
	return ("%d:%02d"):format(math.floor(seconds / 60), seconds % 60)
end

local function formatTopDownRoundOption(seconds)
	return ("%d MIN"):format(math.max(1, math.floor((tonumber(seconds) or TOP_DOWN_DEFAULT_ROUND_SECONDS) / 60)))
end

function InteractionService:_getTopDownPlayerTeam(player)
	if not player then
		return nil
	end

	local team = self.topDownTeamByUserId[player.UserId]
	if TOP_DOWN_TEAM_LABELS[team] then
		return team
	end

	return nil
end

function InteractionService:_getTopDownTeamCounts()
	local counts = {
		North = 0,
		South = 0,
	}

	for userId, team in pairs(self.topDownTeamByUserId) do
		if TOP_DOWN_TEAM_LABELS[team] then
			local player = Players:GetPlayerByUserId(userId)
			if player and self:_isPlayerInTopDownArena(player) then
				counts[team] += 1
			else
				self.topDownTeamByUserId[userId] = nil
				if player then
					player:SetAttribute("TopDownArenaTeam", nil)
				end
			end
		else
			self.topDownTeamByUserId[userId] = nil
		end
	end

	return counts
end

function InteractionService:_hasTopDownReadyMatch()
	local counts = self:_getTopDownTeamCounts()
	return counts.North > 0 and counts.South > 0, counts
end

function InteractionService:_isTopDownRoundActive()
	local state = self.topDownRoundState
	return state
		and state.Status == "Active"
		and state.EndsAt ~= nil
		and os.clock() < state.EndsAt
end

function InteractionService:_isTopDownSoloPracticeAllowed(player)
	if not self:_isPlayerInTopDownArena(player) then
		return false
	end

	local playersInArena = self:_getPlayersInRoom("TopDownArena")
	return #playersInArena <= 1
end

function InteractionService:_broadcastTopDownArenaMessage(message)
	for _, player in ipairs(self:_getPlayersInRoom("TopDownArena")) do
		self.systemMessageRemote:FireClient(player, message)
	end
end

function InteractionService:_resetTopDownRoundScores()
	table.clear(self.topDownScoresByUserId)
	self.topDownTeamScores.North = 0
	self.topDownTeamScores.South = 0
end

function InteractionService:_clearTopDownTeams()
	for userId in pairs(self.topDownTeamByUserId) do
		self.topDownTeamByUserId[userId] = nil
		local player = Players:GetPlayerByUserId(userId)
		if player then
			player:SetAttribute("TopDownArenaTeam", nil)
		end
	end
end

function InteractionService:_refreshTopDownRoundDisplays()
	self:_updateTopDownScoreboards()
	self:_updateTopDownReadyStations()
end

function InteractionService:_updateTopDownReadyStations()
	local counts = self:_getTopDownTeamCounts()
	for _, button in ipairs(CollectionService:GetTagged(Constants.Tags.TopDownReadyButton)) do
		local team = button:GetAttribute("TopDownTeamId")
		local label = TOP_DOWN_TEAM_LABELS[team] or "SIDE"
		local count = counts[team] or 0
		setTextLabelText(button, "TopDownReadyStatusText", ("%s\nREADY %d"):format(label, count))
	end

	local selectedSeconds = self.topDownRoundState.RoundSeconds or TOP_DOWN_DEFAULT_ROUND_SECONDS
	for _, button in ipairs(CollectionService:GetTagged(Constants.Tags.TopDownRoundButton)) do
		local seconds = math.floor(tonumber(button:GetAttribute("RoundSeconds")) or TOP_DOWN_DEFAULT_ROUND_SECONDS)
		local label = formatTopDownRoundOption(seconds)
		if seconds == selectedSeconds then
			label ..= "\nSELECTED"
		end
		setTextLabelText(button, "TopDownRoundOptionText", label)
	end
end

function InteractionService:_formatTopDownScoreboardText()
	local state = self.topDownRoundState
	local status = state.Status or "Waiting"
	local now = os.clock()
	local statusLine = "READY UP"

	if status == "Arming" then
		statusLine = ("COUNTDOWN IN %ds"):format(math.max(0, math.ceil((state.ArmingEndsAt or now) - now)))
	elseif status == "Countdown" then
		statusLine = ("STARTS IN %d"):format(math.max(0, math.ceil((state.CountdownEndsAt or now) - now)))
	elseif status == "Active" then
		statusLine = "TIME " .. formatTopDownSeconds((state.EndsAt or now) - now)
	elseif status == "Ended" then
		statusLine = state.LastResult or "ROUND OVER"
	end

	local counts = self:_getTopDownTeamCounts()
	local northScore = self.topDownTeamScores.North or 0
	local southScore = self.topDownTeamScores.South or 0

	return table.concat({
		"ARENA ROUND",
		statusLine,
		("NORTH %d  SOUTH %d"):format(northScore, southScore),
		("READY N%d  S%d"):format(counts.North, counts.South),
		"ROUND " .. formatTopDownSeconds(state.RoundSeconds or TOP_DOWN_DEFAULT_ROUND_SECONDS),
	}, "\n")
end

function InteractionService:_updateTopDownScoreboards()
	for _, scoreboard in ipairs(CollectionService:GetTagged(Constants.Tags.TopDownScoreboard)) do
		local label = scoreboard:FindFirstChild("TopDownScoreText", true)
		if label and label:IsA("TextLabel") then
			label.Text = self:_formatTopDownScoreboardText()
		end
	end
end

function InteractionService:_incrementTopDownScore(player, amount)
	if not player then
		return
	end

	local scoreAmount = amount or 1
	self.topDownScoresByUserId[player.UserId] = (self.topDownScoresByUserId[player.UserId] or 0) + scoreAmount
	local team = self:_getTopDownPlayerTeam(player)
	if self:_isTopDownRoundActive() and team then
		self.topDownTeamScores[team] = (self.topDownTeamScores[team] or 0) + scoreAmount
	end
	self:_updateTopDownScoreboards()
end

function InteractionService:_setTopDownWaitingState()
	local state = self.topDownRoundState
	state.Status = "Waiting"
	state.ArmingEndsAt = nil
	state.CountdownEndsAt = nil
	state.EndsAt = nil
	state.CountdownToken += 1
	self:_refreshTopDownRoundDisplays()
end

function InteractionService:_startTopDownRound(countdownToken)
	local state = self.topDownRoundState
	if countdownToken and countdownToken ~= state.CountdownToken then
		return
	end

	local hasMatch = self:_hasTopDownReadyMatch()
	if not hasMatch then
		self:_setTopDownWaitingState()
		return
	end

	self:_resetTopDownRoundScores()
	state.Status = "Active"
	state.ArmingEndsAt = nil
	state.CountdownEndsAt = nil
	state.EndsAt = os.clock() + math.max(60, state.RoundSeconds or TOP_DOWN_DEFAULT_ROUND_SECONDS)
	state.LastResult = nil
	state.RoundToken += 1
	local roundToken = state.RoundToken

	self:_broadcastTopDownArenaMessage(("Arena round started. Time: %s."):format(formatTopDownSeconds(state.RoundSeconds)))
	self:_refreshTopDownRoundDisplays()

	task.spawn(function()
		while state.Status == "Active" and state.RoundToken == roundToken do
			if os.clock() >= (state.EndsAt or 0) then
				break
			end
			self:_updateTopDownScoreboards()
			task.wait(1)
		end

		if state.Status == "Active" and state.RoundToken == roundToken then
			self:_finishTopDownRound(roundToken)
		end
	end)
end

function InteractionService:_scheduleTopDownCountdown(message)
	local state = self.topDownRoundState
	if state.Status == "Active" then
		return false
	end

	local hasMatch = self:_hasTopDownReadyMatch()
	if not hasMatch then
		state.Status = "Waiting"
		state.ArmingEndsAt = nil
		state.CountdownEndsAt = nil
		state.LastResult = nil
		state.CountdownToken += 1
		self:_refreshTopDownRoundDisplays()
		return false
	end

	state.Status = "Arming"
	state.ArmingEndsAt = os.clock() + TOP_DOWN_READY_DELAY_SECONDS
	state.CountdownEndsAt = nil
	state.EndsAt = nil
	state.LastResult = nil
	state.CountdownToken += 1
	local token = state.CountdownToken

	self:_broadcastTopDownArenaMessage(message or "Both sides are ready. Countdown starts in 3 seconds.")
	self:_refreshTopDownRoundDisplays()

	task.spawn(function()
		while state.Status == "Arming" and state.CountdownToken == token do
			if os.clock() >= (state.ArmingEndsAt or 0) then
				break
			end
			self:_refreshTopDownRoundDisplays()
			task.wait(0.5)
		end

		if state.Status ~= "Arming" or state.CountdownToken ~= token then
			return
		end

		local stillReady = self:_hasTopDownReadyMatch()
		if not stillReady then
			self:_setTopDownWaitingState()
			return
		end

		state.Status = "Countdown"
		state.CountdownEndsAt = os.clock() + TOP_DOWN_COUNTDOWN_SECONDS
		self:_broadcastTopDownArenaMessage("Arena countdown: 3.")
		self:_refreshTopDownRoundDisplays()

		while state.Status == "Countdown" and state.CountdownToken == token do
			if os.clock() >= (state.CountdownEndsAt or 0) then
				break
			end
			self:_refreshTopDownRoundDisplays()
			task.wait(0.5)
		end

		if state.Status ~= "Countdown" or state.CountdownToken ~= token then
			return
		end

		self:_startTopDownRound(token)
	end)

	return true
end

function InteractionService:_finishTopDownRound(roundToken)
	local state = self.topDownRoundState
	if roundToken and roundToken ~= state.RoundToken then
		return
	end

	state.Status = "Ended"
	state.ArmingEndsAt = nil
	state.CountdownEndsAt = nil
	state.EndsAt = nil
	state.CountdownToken += 1

	local northScore = self.topDownTeamScores.North or 0
	local southScore = self.topDownTeamScores.South or 0
	if northScore > southScore then
		state.LastResult = "NORTH WINS"
	elseif southScore > northScore then
		state.LastResult = "SOUTH WINS"
	else
		state.LastResult = "ROUND TIE"
	end

	self:_broadcastTopDownArenaMessage(("Round over. %s. North %d, South %d. Ready up for another round."):format(state.LastResult, northScore, southScore))
	self:_clearTopDownTeams()
	self:_refreshTopDownRoundDisplays()
end

function InteractionService:_setTopDownPlayerTeam(player, team)
	if not self:_isPlayerInTopDownArena(player) then
		self.systemMessageRemote:FireClient(player, "Step into the arena before choosing a side.")
		return
	end

	if self:_isTopDownRoundActive() then
		self.systemMessageRemote:FireClient(player, "A round is already running. Spectate this one or wait for the next ready-up.")
		return
	end

	if not TOP_DOWN_TEAM_LABELS[team] then
		return
	end

	self.topDownTeamByUserId[player.UserId] = team
	player:SetAttribute("TopDownArenaTeam", team)
	self.topDownRoundState.LastResult = nil
	self.systemMessageRemote:FireClient(player, ("You joined %s. Spectators cannot pick up or throw balloons."):format(TOP_DOWN_TEAM_LABELS[team]))
	self:_recordTopDownTraining(player, 0.25, 0.001)
	self:_scheduleTopDownCountdown(("Both sides ready check updated. Round countdown starts 3 seconds after the last side selection."))
	self:_refreshTopDownRoundDisplays()
end

function InteractionService:_setTopDownRoundSeconds(player, seconds)
	seconds = math.floor(tonumber(seconds) or TOP_DOWN_DEFAULT_ROUND_SECONDS)
	if not TOP_DOWN_ROUND_LENGTH_OPTIONS[seconds] then
		return
	end

	if self:_isTopDownRoundActive() then
		self.systemMessageRemote:FireClient(player, "Round length is locked while the arena round is running.")
		return
	end

	self.topDownRoundState.RoundSeconds = seconds
	self.topDownRoundState.LastResult = nil
	self.systemMessageRemote:FireClient(player, ("Arena round length set to %s."):format(formatTopDownSeconds(seconds)))
	self:_recordTopDownTraining(player, 0.18, 0.001)
	self:_scheduleTopDownCountdown("Round length updated. Countdown waits for the last side selection.")
	self:_refreshTopDownRoundDisplays()
end

function InteractionService:_canTopDownPlayerUseBalloons(player, sendMessage)
	local team = self:_getTopDownPlayerTeam(player)
	if not team then
		if self:_isTopDownSoloPracticeAllowed(player) then
			return true
		end

		if sendMessage then
			self.systemMessageRemote:FireClient(player, "Choose a side at a ready station before using water balloons. Spectators can watch or leave.")
		end
		return false
	end

	if not self:_isTopDownRoundActive() then
		if sendMessage then
			self.systemMessageRemote:FireClient(player, "Water balloons unlock when the arena round starts.")
		end
		return false
	end

	return true
end

function InteractionService:_canTopDownPlayerLoadBalloons(player, sendMessage)
	local team = self:_getTopDownPlayerTeam(player)
	if not team then
		if self:_isTopDownSoloPracticeAllowed(player) then
			return true
		end

		if sendMessage then
			self.systemMessageRemote:FireClient(player, "Choose a side at a ready station before loading water balloons. Spectators can watch or leave.")
		end
		return false
	end

	return true
end

function InteractionService:_startTopDownPracticeTargetMotion()
	task.spawn(function()
		while true do
			for _, target in ipairs(CollectionService:GetTagged(Constants.Tags.TopDownSplashTarget)) do
				if target:IsA("BasePart") then
					local startCFrame = target:GetAttribute("TrackStartCFrame") or target:GetAttribute("BaseCFrame") or target.CFrame
					local endCFrame = target:GetAttribute("TrackEndCFrame") or (startCFrame * CFrame.new(40, 0, 0))
					local state = self.topDownPracticeTargetState[target]
					if not state then
						state = {
							Direction = 1,
						}
						self.topDownPracticeTargetState[target] = state
					end

					local goal = if state.Direction == 1 then endCFrame else startCFrame
					tweenPart(target, 4.2, { CFrame = goal }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
					state.Direction *= -1
				end
			end
			task.wait(4.25)
		end
	end)
end

function InteractionService:_findTopDownTargetPlayer(thrower)
	local throwerRoot = getRootPart(thrower)
	local bestPlayer = nil
	local bestDistance = math.huge

	for _, candidate in ipairs(self:_getPlayersInRoom("TopDownArena")) do
		if candidate ~= thrower then
			local rootPart = getRootPart(candidate)
			if rootPart and throwerRoot then
				local distance = (rootPart.Position - throwerRoot.Position).Magnitude
				if distance < bestDistance then
					bestDistance = distance
					bestPlayer = candidate
				end
			end
		end
	end

	return bestPlayer
end

function InteractionService:_getTopDownPracticeTarget()
	for _, target in ipairs(CollectionService:GetTagged(Constants.Tags.TopDownSplashTarget)) do
		if target:IsA("BasePart") and target.Parent then
			return target
		end
	end

	return nil
end

function InteractionService:_getTopDownRing()
	for _, ring in ipairs(CollectionService:GetTagged(Constants.Tags.TopDownTargetRing)) do
		if ring:IsA("BasePart") and ring.Parent then
			return ring
		end
	end

	return nil
end

function InteractionService:_isPlayerInTopDownArena(player)
	local rootPart = getRootPart(player)
	local room = Constants.GetRoom("TopDownArena")
	return rootPart ~= nil and room ~= nil and positionInZone(rootPart.Position, room.Zone)
end

function InteractionService:_getTopDownWaterBalloonCapacity()
	return TOP_DOWN_MAX_LOADED_BALLOONS
end

function InteractionService:_getTopDownWaterBalloonCount(player)
	local count = self:_getPocketItemCount(player, TOP_DOWN_WATER_BALLOON_KIND, self.topDownLoadedBalloonsByUserId)
	if player then
		self.topDownLoadedBalloonsByUserId[player.UserId] = count
	end
	return count
end

function InteractionService:_getTopDownAvailableWaterBalloonSlots(player)
	local capacity = self:_getTopDownWaterBalloonCapacity()
	local loaded = self:_getTopDownWaterBalloonCount(player)
	if loaded >= capacity then
		return 0
	end

	if loaded > 0 then
		return capacity - loaded
	end

	if self.bunkerEnergyService and self.bunkerEnergyService.GetPocketItemSlotCount then
		local maxItems = Constants.BunkerEnergy.MaxPocketEnergyItems or 5
		if self.bunkerEnergyService:GetPocketItemSlotCount(player) >= maxItems then
			return 0
		end
	end

	return capacity
end

function InteractionService:_grantTopDownWaterBalloon(player)
	return self:_grantPocketItem(player, {
		Kind = TOP_DOWN_WATER_BALLOON_KIND,
		Name = TOP_DOWN_WATER_BALLOON_NAME,
		ToolTip = "Use the arena aim and throw controls to splash a target.",
		Color = TOP_DOWN_WATER_BALLOON_COLOR,
		Material = Enum.Material.SmoothPlastic,
		Size = TOP_DOWN_WATER_BALLOON_SIZE,
		Shape = Enum.PartType.Ball,
		StackLimit = TOP_DOWN_MAX_LOADED_BALLOONS,
		GrantMessage = "Water balloon added to inventory.",
	})
end

function InteractionService:_fireTopDownAmmo(player, message)
	if not player or not player.Parent then
		return
	end

	local count = self:_getTopDownWaterBalloonCount(player)
	self.topDownArenaRemote:FireClient(player, {
		Action = "Ammo",
		Count = count,
		Max = self:_getTopDownWaterBalloonCapacity(),
		Message = message,
	})
end

function InteractionService:_recordTopDownTraining(player, chargeAmount, energyCost)
	if self.bunkerEnergyService and self.bunkerEnergyService.RecordTrainingActivity then
		self.bunkerEnergyService:RecordTrainingActivity(player, chargeAmount or 0.55, energyCost or 0.003)
	end
end

function InteractionService:_broadcastTopDownCameraMode(message)
	local mode = self.topDownCameraMode or "Overhead"
	for _, player in ipairs(self:_getPlayersInRoom("TopDownArena")) do
		self.topDownArenaRemote:FireClient(player, {
			Action = "CameraMode",
			Mode = mode,
			Message = message,
		})
	end
end

function InteractionService:_flatTopDownDirection(player, direction)
	local rootPart = getRootPart(player)
	local fallback = rootPart and rootPart.CFrame.LookVector or Vector3.new(0, 0, -1)

	if typeof(direction) ~= "Vector3" then
		direction = fallback
	end

	local flat = Vector3.new(direction.X, 0, direction.Z)
	if flat.Magnitude < 0.1 then
		flat = Vector3.new(fallback.X, 0, fallback.Z)
	end

	if flat.Magnitude < 0.1 then
		return Vector3.new(0, 0, -1)
	end

	return flat.Unit
end

function InteractionService:_getTopDownFullAimDirection(player, direction)
	local rootPart = getRootPart(player)
	local fallback = rootPart and rootPart.CFrame.LookVector or Vector3.new(0, 0, -1)

	if typeof(direction) ~= "Vector3" or direction.Magnitude < 0.1 then
		direction = fallback
	end

	if direction.Magnitude < 0.1 then
		return Vector3.new(0, 0, -1)
	end

	return direction.Unit
end

function InteractionService:_getTopDownThrowSpreadRadius(player)
	local humanoid = getHumanoid(player)
	local rootPart = getRootPart(player)
	local moveMagnitude = humanoid and humanoid.MoveDirection.Magnitude or 0
	local horizontalSpeed = 0
	if rootPart then
		local velocity = rootPart.AssemblyLinearVelocity
		horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	end

	local moveAlpha = math.clamp(math.max(moveMagnitude, horizontalSpeed / TOP_DOWN_SPREAD_SPEED), 0, 1)
	return TOP_DOWN_STILL_THROW_SPREAD + (TOP_DOWN_MOVING_THROW_SPREAD - TOP_DOWN_STILL_THROW_SPREAD) * moveAlpha
end

function InteractionService:_applyTopDownThrowSpread(player, targetPosition)
	if typeof(targetPosition) ~= "Vector3" then
		return targetPosition
	end

	local radius = self:_getTopDownThrowSpreadRadius(player)
	if radius <= 0 then
		return targetPosition
	end

	local random = self.topDownThrowRandom
	if not random then
		random = Random.new()
		self.topDownThrowRandom = random
	end

	local angle = random:NextNumber(0, math.pi * 2)
	local distance = radius * math.sqrt(random:NextNumber())
	return targetPosition + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
end

function InteractionService:_makeTopDownSplash(position, color)
	local splashModel = Instance.new("Model")
	splashModel.Name = "TopDownWaterSplash"
	splashModel.Parent = workspace

	for index = 1, 9 do
		local angle = math.rad(index * 40)
		local droplet = Instance.new("Part")
		droplet.Name = "SplashDrop" .. index
		droplet.Anchored = true
		droplet.CanCollide = false
		droplet.CastShadow = false
		droplet.Shape = Enum.PartType.Ball
		droplet.Size = Vector3.new(0.42, 0.42, 0.42)
		droplet.Color = color or Color3.fromRGB(93, 217, 255)
		droplet.Material = Enum.Material.Neon
		droplet.CFrame = CFrame.new(position + Vector3.new(math.cos(angle) * 0.4, 0.8, math.sin(angle) * 0.4))
		droplet.Parent = splashModel
		tweenPart(droplet, 0.45, {
			CFrame = droplet.CFrame + Vector3.new(math.cos(angle) * 2.8, 1.2, math.sin(angle) * 2.8),
			Transparency = 1,
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end

	Debris:AddItem(splashModel, 1.1)
end

function InteractionService:_spawnTopDownWaterBalloon(player, sourcePart, targetPosition, mode, targetPlayer, startPosition, aimDirection, throwStyle, chargeDuration)
	local rootPart = getRootPart(player)
	if not rootPart then
		return
	end

	if not sourcePart or not sourcePart:IsA("BasePart") then
		sourcePart = rootPart
	end

	startPosition = startPosition or (sourcePart.Position + Vector3.new(0, 2.6, 0))
	local balloon = Instance.new("Part")
	balloon.Name = "TopDownWaterBalloonProjectile"
	balloon.Shape = Enum.PartType.Ball
	balloon.Size = Vector3.new(1.05, 1.05, 1.05)
	balloon.Color = Color3.fromRGB(93, 217, 255)
	balloon.Material = Enum.Material.SmoothPlastic
	balloon.CanCollide = false
	balloon.CFrame = CFrame.new(startPosition)
	balloon.Parent = workspace
	CollectionService:AddTag(balloon, Constants.Tags.TemporaryObject)

	local trailAttachment0 = Instance.new("Attachment")
	trailAttachment0.Name = "BalloonTrail0"
	trailAttachment0.Position = Vector3.new(0, 0.36, 0)
	trailAttachment0.Parent = balloon
	local trailAttachment1 = Instance.new("Attachment")
	trailAttachment1.Name = "BalloonTrail1"
	trailAttachment1.Position = Vector3.new(0, -0.36, 0)
	trailAttachment1.Parent = balloon
	local trail = Instance.new("Trail")
	trail.Name = "TopDownBalloonTrail"
	trail.Attachment0 = trailAttachment0
	trail.Attachment1 = trailAttachment1
	trail.Color = ColorSequence.new(Color3.fromRGB(119, 255, 203), Color3.fromRGB(93, 217, 255))
	trail.Lifetime = 0.24
	trail.Transparency = NumberSequence.new(0.15, 1)
	trail.Parent = balloon

	local target = targetPosition or (rootPart.Position + rootPart.CFrame.LookVector * 32)
	throwStyle = if throwStyle == "Direct" then "Direct" else "Lob"
	local chargeAlpha = math.clamp((tonumber(chargeDuration) or 0) / 1.25, 0, 1)
	local pitch = 0
	if typeof(aimDirection) == "Vector3" and aimDirection.Magnitude > 0.1 then
		pitch = math.clamp(aimDirection.Unit.Y, -0.65, 0.85)
	end
	local horizontalDistance = (Vector3.new(target.X, 0, target.Z) - Vector3.new(startPosition.X, 0, startPosition.Z)).Magnitude
	local distance = (target - startPosition).Magnitude
	local flightTime
	if throwStyle == "Direct" then
		flightTime = math.clamp(math.max(horizontalDistance, distance * 0.72) / 88, 0.36, 1.18)
		flightTime = math.clamp(flightTime + math.max(pitch, 0) * 0.18 + math.min(pitch, 0) * 0.08, 0.34, 1.28)
	else
		flightTime = math.clamp(math.max(horizontalDistance, distance * 0.65) / 58, 0.85, 2.15)
		flightTime = math.clamp(
			flightTime + math.max(pitch, 0) * 0.7 + math.min(pitch, 0) * 0.24 + chargeAlpha * 0.35,
			0.65,
			2.85
		)
	end
	local velocity = (target - startPosition) / flightTime + Vector3.new(0, 0.5 * workspace.Gravity * flightTime, 0)
	balloon.AssemblyLinearVelocity = velocity
	balloon.AssemblyAngularVelocity = Vector3.new(8, 14, 2)

	playSound(sourcePart, "rbxasset://sounds/button.wav", 0.36, 1.35)

	local touched = false
	local connection
	connection = balloon.Touched:Connect(function(hit)
		if touched or not hit then
			return
		end

		local character = player.Character
		if character and hit:IsDescendantOf(character) then
			return
		end

		local hitPlayer = getPlayerFromHit(hit)
		if hitPlayer and hitPlayer ~= player then
			local throwerTeam = self:_getTopDownPlayerTeam(player)
			local hitTeam = self:_getTopDownPlayerTeam(hitPlayer)
			if not self:_isTopDownRoundActive() or not throwerTeam or not hitTeam or hitTeam == throwerTeam then
				return
			end

			touched = true
			if connection then
				connection:Disconnect()
			end
			self.discoveryService:Unlock(player, Constants.Discoveries.TopDownPlayerSplash.Id)
			self:_incrementTopDownScore(player, 2)
			self:_makeTopDownSplash(balloon.Position, Color3.fromRGB(119, 255, 203))
			playSound(balloon, "rbxasset://sounds/snap.wav", 0.55, 1.3)
			self.systemMessageRemote:FireClient(player, ("Direct splash on %s. The scoreboard noticed."):format(hitPlayer.DisplayName))
			self.systemMessageRemote:FireClient(hitPlayer, ("%s introduced you to a water balloon."):format(player.DisplayName))
			balloon:Destroy()
			return
		end

		if CollectionService:HasTag(hit, Constants.Tags.TopDownSplashTarget) or (mode == "Splash" and targetPlayer == nil and hit.Name == "TopDownPracticeTarget") then
			if not self:_isTopDownSoloPracticeAllowed(player)
				and (not self:_isTopDownRoundActive() or not self:_getTopDownPlayerTeam(player))
			then
				return
			end

			touched = true
			if connection then
				connection:Disconnect()
			end
			self.discoveryService:Unlock(player, Constants.Discoveries.TopDownPlayerSplash.Id)
			self:_incrementTopDownScore(player, 2)
			self:_makeTopDownSplash(balloon.Position, Color3.fromRGB(255, 142, 191))
			playSound(balloon, "rbxasset://sounds/snap.wav", 0.55, 1.2)
			self.systemMessageRemote:FireClient(player, "Practice target splashed. Technically, it had it coming.")
			balloon:Destroy()
		end
	end)

	task.delay(math.max(0.55, flightTime), function()
		if not balloon.Parent or touched then
			return
		end

		local ring = self:_getTopDownRing()
		local ringPosition = ring and (ring:GetAttribute("TargetPosition") or ring.Position) or target
		local scoreRadius = ring and (ring:GetAttribute("ScoreRadius") or TOP_DOWN_RING_SCORE_RADIUS) or TOP_DOWN_RING_SCORE_RADIUS
		local flatDistance = (Vector3.new(balloon.Position.X, 0, balloon.Position.Z) - Vector3.new(ringPosition.X, 0, ringPosition.Z)).Magnitude
		local canScorePractice = self:_isTopDownSoloPracticeAllowed(player)
			or (self:_isTopDownRoundActive() and self:_getTopDownPlayerTeam(player) ~= nil)
		if canScorePractice and (mode == "Ring" or flatDistance <= scoreRadius) then
			if flatDistance <= scoreRadius then
				self.discoveryService:Unlock(player, Constants.Discoveries.TopDownRingScore.Id)
				self:_incrementTopDownScore(player, 1)
				self.systemMessageRemote:FireClient(player, ("Splash ring score: +1. Accuracy %.0f studs from suspicious."):format(flatDistance))
				self:_makeTopDownSplash(balloon.Position, Color3.fromRGB(93, 217, 255))
			else
				self.systemMessageRemote:FireClient(player, "The balloon lands near the ring. The ring declines the paperwork.")
			end
		end
	end)

	Debris:AddItem(balloon, TOP_DOWN_BALLOON_LIFETIME)
end

function InteractionService:_loadTopDownWaterBalloons(player, bucket)
	if not self:_isPlayerInTopDownArena(player) then
		self.systemMessageRemote:FireClient(player, "The bucket waits for you to actually be in the arena.")
		return
	end

	if not self:_canTopDownPlayerLoadBalloons(player, true) then
		self:_fireTopDownAmmo(player)
		return
	end

	local availableSlots = self:_getTopDownAvailableWaterBalloonSlots(player)
	if availableSlots <= 0 then
		local message = "Inventory full. Drop an item before picking up water balloons."
		self:_fireTopDownAmmo(player, message)
		self.systemMessageRemote:FireClient(player, message)
		return
	end

	local loadCount = if bucket:GetAttribute("IsRefillBucket") then TOP_DOWN_REFILL_LOAD_COUNT else TOP_DOWN_DEFAULT_LOAD_COUNT
	local grantCount = math.min(loadCount, availableSlots)
	local granted = 0
	local failureMessage = nil
	for _ = 1, grantCount do
		local ok, message = self:_grantTopDownWaterBalloon(player)
		if not ok then
			failureMessage = message
			break
		end
		granted += 1
	end

	if granted <= 0 then
		local message = failureMessage or "Inventory full. Drop an item before picking up water balloons."
		self:_fireTopDownAmmo(player, message)
		self.systemMessageRemote:FireClient(player, message)
		return
	end

	local newCount = self:_getTopDownWaterBalloonCount(player)

	if bucket:GetAttribute("IsRefillBucket") then
		self.discoveryService:Unlock(player, Constants.Discoveries.TopDownBucketRefill.Id)
	end

	playSound(bucket, "rbxasset://sounds/electronicpingshort.wav", 0.32, 1.55)
	local message = ("Picked up %d water balloon%s. Inventory balloons: %d / %d. Aim, then throw."):format(
		granted,
		if granted == 1 then "" else "s",
		newCount,
		self:_getTopDownWaterBalloonCapacity()
	)
	self.systemMessageRemote:FireClient(player, message)
	self:_fireTopDownAmmo(player, message)
end

function InteractionService:_getValidatedTopDownAimTarget(player, direction, targetPosition)
	if not self:_isPlayerInTopDownArena(player) then
		return nil
	end

	local rootPart = getRootPart(player)
	if not rootPart then
		return nil
	end

	local aimDirection = self:_flatTopDownDirection(player, direction)
	if typeof(targetPosition) == "Vector3" then
		local room = Constants.GetRoom("TopDownArena")
		local horizontalOffset = Vector3.new(targetPosition.X - rootPart.Position.X, 0, targetPosition.Z - rootPart.Position.Z)
		local distance = horizontalOffset.Magnitude
		if room
			and positionInZone(targetPosition, room.Zone)
			and distance >= 8
			and distance <= TOP_DOWN_THROW_DISTANCE + 18
		then
			return Vector3.new(targetPosition.X, math.max(rootPart.Position.Y + 0.4, targetPosition.Y), targetPosition.Z)
		end
	end

	return rootPart.Position + aimDirection * TOP_DOWN_THROW_DISTANCE
end

function InteractionService:_throwLoadedTopDownBalloon(player, direction, targetPosition, throwStyle, chargeDuration)
	if not self:_isPlayerInTopDownArena(player) then
		return
	end

	if not self:_canTopDownPlayerUseBalloons(player, true) then
		self:_fireTopDownAmmo(player)
		return
	end

	local now = os.clock()
	if now - (self.topDownLastThrowByUserId[player.UserId] or 0) < TOP_DOWN_THROW_COOLDOWN then
		return
	end

	local loaded = self:_getTopDownWaterBalloonCount(player)
	if loaded <= 0 then
		self:_fireTopDownAmmo(player, "Load water balloons at a bucket first.")
		self.systemMessageRemote:FireClient(player, "No balloons loaded. The throw button produces a very confident shrug.")
		return
	end

	local rootPart = getRootPart(player)
	if not rootPart then
		return
	end

	local fullAimDirection = self:_getTopDownFullAimDirection(player, direction)
	local aimDirection = self:_flatTopDownDirection(player, fullAimDirection)
	if not self:_consumePocketItem(player, TOP_DOWN_WATER_BALLOON_KIND, self.topDownLoadedBalloonsByUserId) then
		self:_fireTopDownAmmo(player, "Load water balloons at a bucket first.")
		self.systemMessageRemote:FireClient(player, "The balloon disappeared from inventory before the throw.")
		return
	end
	self.topDownLastThrowByUserId[player.UserId] = now
	self.topDownThrowsByUserId[player.UserId] = (self.topDownThrowsByUserId[player.UserId] or 0) + 1
	self.discoveryService:Unlock(player, Constants.Discoveries.TopDownWaterBalloon.Id)

	local startPosition = rootPart.Position + Vector3.new(0, 2.35, 0) + aimDirection * 2.6
	local validatedTarget = self:_getValidatedTopDownAimTarget(player, fullAimDirection, targetPosition)
	validatedTarget = self:_applyTopDownThrowSpread(player, validatedTarget)
	self:_recordTopDownTraining(player, 0.72, 0.004)
	self:_spawnTopDownWaterBalloon(player, rootPart, validatedTarget, "Aim", nil, startPosition, fullAimDirection, throwStyle, chargeDuration)
	self:_fireTopDownAmmo(player)
end

function InteractionService:_handleTopDownArenaRemote(player, payload)
	if typeof(payload) ~= "table" then
		return
	end

	if payload.Action == TOP_DOWN_THROW_ACTION then
		self:_throwLoadedTopDownBalloon(player, payload.Direction, payload.TargetPosition, payload.ThrowStyle, payload.Charge)
	end
end

function InteractionService:_wireTopDownCameraConsole(console)
	local prompt = getPrompt(console)

	self:_connectPrompt(prompt, function(player)
		local modes = { "Overhead", "FPV", "Normal" }
		local currentIndex = table.find(modes, self.topDownCameraMode) or 1
		self.topDownCameraMode = modes[(currentIndex % #modes) + 1]
		setTextLabelText(console, "TopDownCameraConsoleText", ("CAMERA\n%s"):format(string.upper(self.topDownCameraMode)))
		self.discoveryService:Unlock(player, Constants.Discoveries.TopDownCamera.Id)
		self:_recordTopDownTraining(player, 0.45, 0.002)
		playSound(console, "rbxasset://sounds/electronicpingshort.wav", 0.42, 1.1)
		local message = ("Training camera mode: %s."):format(self.topDownCameraMode)
		self:_broadcastTopDownCameraMode(message)
		self.systemMessageRemote:FireClient(player, message)
	end)
end

function InteractionService:_wireTopDownReadyButton(button)
	local prompt = getPrompt(button)

	self:_connectPrompt(prompt, function(player)
		self:_setTopDownPlayerTeam(player, button:GetAttribute("TopDownTeamId"))
	end)

	self:_updateTopDownReadyStations()
end

function InteractionService:_wireTopDownRoundButton(button)
	local prompt = getPrompt(button)

	self:_connectPrompt(prompt, function(player)
		self:_setTopDownRoundSeconds(player, button:GetAttribute("RoundSeconds"))
	end)

	self:_updateTopDownReadyStations()
end

function InteractionService:_wireTopDownWaterBalloonBucket(bucket)
	local prompt = getPrompt(bucket)

	self:_connectPrompt(prompt, function(player)
		self:_recordTopDownTraining(player, 0.35, 0.002)
		self:_loadTopDownWaterBalloons(player, bucket)
	end)

	if bucket:GetAttribute("AutoReloadTouchedWired") then
		return
	end

	bucket:SetAttribute("AutoReloadTouchedWired", true)
	bucket.Touched:Connect(function(hit)
		local player = getPlayerFromHit(hit)
		if not player or not self:_isPlayerInTopDownArena(player) then
			return
		end

		local lastByBucket = self.topDownBucketTouchAtByUserId[player.UserId]
		if not lastByBucket then
			lastByBucket = {}
			self.topDownBucketTouchAtByUserId[player.UserId] = lastByBucket
		end

		local now = os.clock()
		if now - (lastByBucket[bucket] or 0) < 1.15 then
			return
		end

		if not self:_canTopDownPlayerLoadBalloons(player, false)
			or self:_getTopDownAvailableWaterBalloonSlots(player) <= 0
		then
			return
		end

		lastByBucket[bucket] = now
		self:_recordTopDownTraining(player, 0.28, 0.0015)
		self:_loadTopDownWaterBalloons(player, bucket)
	end)
end

function InteractionService:_wireTopDownTargetRing(ring)
	local prompt = getPrompt(ring)

	self:_connectPrompt(prompt, function(player)
		self.discoveryService:Unlock(player, Constants.Discoveries.TopDownRingScore.Id)
		playSound(ring, "rbxasset://sounds/electronicpingshort.wav", 0.3, 1.6)
		self.systemMessageRemote:FireClient(player, "The ring prefers balloons from above, but appreciates the inspection.")
	end)
end

function InteractionService:_wireTopDownSplashTarget(target)
	local prompt = getPrompt(target)

	self:_connectPrompt(prompt, function(player)
		self.discoveryService:Unlock(player, Constants.Discoveries.TopDownPlayerSplash.Id)
		playSound(target, "rbxasset://sounds/button.wav", 0.26, 0.75)
		self.systemMessageRemote:FireClient(player, "The practice target moves just enough to be annoying.")
	end)
end

function InteractionService:_wireTopDownScoreboard(scoreboard)
	local prompt = getPrompt(scoreboard)

	self:_connectPrompt(prompt, function(player)
		self.discoveryService:Unlock(player, Constants.Discoveries.TopDownScoreboard.Id)
		self:_updateTopDownScoreboards()
		playSound(scoreboard, "rbxasset://sounds/electronicpingshort.wav", 0.3, 0.9)
		self.systemMessageRemote:FireClient(player, "The scoreboard confirms every splash is official enough.")
	end)
end

function InteractionService:_setCaveEntranceSealed()
	if self.caveEntranceSealed then
		return false
	end

	self.caveEntranceSealed = true
	for _, seal in ipairs(CollectionService:GetTagged(Constants.Tags.CaveEntranceSeal)) do
		for _, instance in ipairs(getInstanceAndDescendants(seal)) do
			if instance:IsA("BasePart") then
				local closedTransparency = instance:GetAttribute("ClosedTransparency")
				local closedCanCollide = instance:GetAttribute("ClosedCanCollide")
				local closedCanQuery = instance:GetAttribute("ClosedCanQuery")
				local closedCanTouch = instance:GetAttribute("ClosedCanTouch")
				instance.Transparency = if closedTransparency ~= nil then closedTransparency else 0
				instance.CanCollide = closedCanCollide == true
				instance.CanQuery = closedCanQuery ~= false
				instance.CanTouch = closedCanTouch == true
			end
		end
		self:_persistResetBaseline(seal)
	end

	for _, reveal in ipairs(CollectionService:GetTagged(Constants.Tags.CaveLockdownReveal)) do
		for _, instance in ipairs(getInstanceAndDescendants(reveal)) do
			if instance:IsA("BasePart") then
				local closedTransparency = instance:GetAttribute("ClosedTransparency")
				local closedCanCollide = instance:GetAttribute("ClosedCanCollide")
				instance.Transparency = if closedTransparency ~= nil then closedTransparency else 0
				instance.CanCollide = closedCanCollide == true
			elseif instance:IsA("SurfaceGui") or instance:IsA("BillboardGui") then
				instance.Enabled = true
			end
		end
		self:_persistResetBaseline(reveal)
	end

	for _, door in ipairs(CollectionService:GetTagged(Constants.Tags.CaveKeyDoor)) do
		local prompt = getPrompt(door)
		if prompt then
			prompt.ActionText = prompt:GetAttribute("LockedActionText") or prompt.ActionText
			prompt.ObjectText = prompt:GetAttribute("LockedObjectText") or prompt.ObjectText
		end

		local label = door:FindFirstChild("CaveKeyDoorText", true)
		if label and label:IsA("TextLabel") then
			local lockedText = label:GetAttribute("LockedText")
			local lockedTextColor = label:GetAttribute("LockedTextColor3")
			local lockedBackgroundColor = label:GetAttribute("LockedBackgroundColor3")
			if typeof(lockedText) == "string" then
				label.Text = lockedText
			end
			if typeof(lockedTextColor) == "Color3" then
				label.TextColor3 = lockedTextColor
			end
			if typeof(lockedBackgroundColor) == "Color3" then
				label.BackgroundColor3 = lockedBackgroundColor
			end
		end

		self:_persistResetBaseline(door)
	end

	return true
end

function InteractionService:_openCaveEntranceForNewPlayers()
	for _, seal in ipairs(CollectionService:GetTagged(Constants.Tags.CaveEntranceSeal)) do
		for _, instance in ipairs(getInstanceAndDescendants(seal)) do
			if instance:IsA("BasePart") then
				instance.Transparency = instance:GetAttribute("BaseTransparency") or 1
				instance.CanCollide = instance:GetAttribute("BaseCanCollide") == true
				instance.CanQuery = instance:GetAttribute("BaseCanQuery") == true
				instance.CanTouch = instance:GetAttribute("BaseCanTouch") == true
			end
		end
		self:_persistResetBaseline(seal)
	end
end

function InteractionService:_cycleCaveLight(light)
	local colorIndex = ((light:GetAttribute("CaveLightColorIndex") or 1) % #CAVE_LIGHT_COLORS) + 1
	local color = CAVE_LIGHT_COLORS[colorIndex]
	light:SetAttribute("CaveLightColorIndex", colorIndex)

	if light:IsA("BasePart") then
		tweenPart(light, 0.18, {
			Color = color,
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end

	for _, descendant in ipairs(light:GetDescendants()) do
		if descendant:IsA("PointLight") then
			descendant.Color = color
			descendant.Brightness = math.max(descendant.Brightness, 2.1)
		end
	end
end

function InteractionService:_wireCaveLight(light)
	local prompt = getPrompt(light)

	self:_connectPrompt(prompt, function(player)
		self:_cycleCaveLight(light)

		local lightIndex = light:GetAttribute("CaveLightIndex") or 0
		if lightIndex == 1 then
			local alreadyFound = self.discoveryService:HasDiscovery(player, Constants.Discoveries.CaveFirstLight.Id)
			self.discoveryService:Unlock(player, Constants.Discoveries.CaveFirstLight.Id)
			local isPrologueOpen =
				self.roomProgressService and self.roomProgressService:IsUntouchedPrologueActive(player)
			if not isPrologueOpen then
				self:_setCaveEntranceSealed()
			end
			playSound(light, "rbxasset://sounds/snap.wav", 0.75, 0.38)
			task.delay(0.08, function()
				if light.Parent then
					playSound(light, "rbxasset://sounds/button.wav", 0.55, 0.42)
				end
			end)
			self.systemMessageRemote:FireClient(
				player,
				if alreadyFound
					then "The first cave light changes color again. The cave remains committed to being closed."
					else "Oops. You touched something. But it was just 1 thing. Hopefully nobody notices."
			)
			return
		end

		playSound(light, "rbxasset://sounds/electronicpingshort.wav", 0.45, 1.25)
		self.discoveryService:Unlock(player, Constants.Discoveries.CaveChangedLights.Id)
		self.systemMessageRemote:FireClient(player, "The cave light changes color. This feels like exactly the sort of thing the sign mentioned.")
	end)
end

function InteractionService:_triggerCaveAlarm(source)
	if self.caveAlarmActive then
		return
	end

	self.caveAlarmActive = true
	task.spawn(function()
		local alarms = CollectionService:GetTagged(Constants.Tags.CaveAlarmLight)
		for pulse = 1, 12 do
			local color = if pulse % 2 == 0 then Color3.fromRGB(255, 38, 58) else Color3.fromRGB(72, 156, 255)
			for _, alarm in ipairs(alarms) do
				if alarm:IsA("BasePart") then
					alarm.Transparency = 0.08
					alarm.Material = Enum.Material.Neon
					alarm.Color = color
					alarm.CFrame *= CFrame.Angles(0, math.rad(38), 0)
					for _, descendant in ipairs(alarm:GetDescendants()) do
						if descendant:IsA("PointLight") then
							descendant.Enabled = true
							descendant.Brightness = if pulse % 2 == 0 then 6 else 3.5
							descendant.Color = color
						end
					end
				end
			end

			playSound(source, "rbxasset://sounds/electronicpingshort.wav", 1.15, if pulse % 2 == 0 then 0.55 else 0.75)
			task.wait(0.24)
		end

		for _, alarm in ipairs(alarms) do
			if alarm:IsA("BasePart") then
				alarm.Transparency = 0.34
				alarm.Color = Color3.fromRGB(255, 128, 72)
				for _, descendant in ipairs(alarm:GetDescendants()) do
					if descendant:IsA("PointLight") then
						descendant.Enabled = true
						descendant.Brightness = 1.7
						descendant.Color = Color3.fromRGB(255, 170, 92)
					end
				end
			end
		end

		for _, caveLight in ipairs(CollectionService:GetTagged(Constants.Tags.CaveLight)) do
			if caveLight:IsA("BasePart") then
				caveLight.Color = Color3.fromRGB(255, 200, 118)
				for _, descendant in ipairs(caveLight:GetDescendants()) do
					if descendant:IsA("PointLight") then
						descendant.Enabled = true
						descendant.Brightness = math.max(descendant.Brightness, 2.4)
						descendant.Color = caveLight.Color
					end
				end
			end
		end

		self.caveAlarmActive = false
	end)
end

function InteractionService:_wireCaveExitKey(keyPart)
	local prompt = getPrompt(keyPart)

	self:_connectPrompt(prompt, function(player)
		if self.discoveryService:HasDiscovery(player, Constants.Discoveries.CaveExitKey.Id) then
			self.systemMessageRemote:FireClient(player, "You already took the exit key. It is doing key things now.")
			return
		end

		self.discoveryService:Unlock(player, Constants.Discoveries.CaveExitKey.Id)
		self:_triggerCaveAlarm(keyPart)
		playSound(keyPart, "rbxasset://sounds/button.wav", 0.8, 0.75)
		self.systemMessageRemote:FireClient(player, "The exit key is yours. The cave responds with a very mature alarm system.")
	end)
end

function InteractionService:_wireCaveKeyDoor(door)
	if door:GetAttribute("WalkthroughToHallway") == true then
		local touchDebounceByUserId = {}
		if door:IsA("BasePart") then
			door.Touched:Connect(function(hit)
				local player = getPlayerFromHit(hit)
				if not player then
					return
				end

				local now = os.clock()
				if touchDebounceByUserId[player.UserId] and now - touchDebounceByUserId[player.UserId] < 1.5 then
					return
				end
				touchDebounceByUserId[player.UserId] = now

				local destinationCFrame = door:GetAttribute("DestinationCFrame")
				if typeof(destinationCFrame) ~= "CFrame" or not self:_canUseTeleport(player) then
					return
				end

				self.caveHallDoorLockedByUserId[player.UserId] = true
				self:_openCaveEntranceForNewPlayers()
				if self:_teleportPlayer(player, destinationCFrame, "CaveWalkthroughDoor") then
					local travelSoundId = door:GetAttribute("TravelSoundId")
					if typeof(travelSoundId) == "string" and travelSoundId ~= "" then
						playSound(getRootPart(player) or door, travelSoundId, 0.65, 0.42)
					end
					self.systemMessageRemote:FireClient(player, "The doorway locks behind you.")
				end
			end)
		end
		return
	end

	local prompt = getPrompt(door)

	self:_connectPrompt(prompt, function(player)
		local isPrologueOpen =
			self.roomProgressService and self.roomProgressService:IsUntouchedPrologueActive(player)
		if not self.discoveryService:HasDiscovery(player, Constants.Discoveries.CaveExitKey.Id) then
			if isPrologueOpen or not self.caveEntranceSealed then
				local destinationCFrame = door:GetAttribute("DestinationCFrame")
				if typeof(destinationCFrame) == "CFrame" and self:_canUseTeleport(player) then
					playSound(door, "rbxasset://sounds/button.wav", 0.45, 0.48)
					self:_teleportPlayer(player, destinationCFrame, "UntouchedPrologueCaveDoor")
					self.systemMessageRemote:FireClient(player, "The huge door opens without asking for the key. That is not comforting.")
				end
				return
			end

			playSound(door, "rbxasset://sounds/snap.wav", 0.5, 0.45)
			self.systemMessageRemote:FireClient(player, "The door has the same key shape, and it is waiting for the actual key.")
			return
		end

		local destinationCFrame = door:GetAttribute("DestinationCFrame")
		if typeof(destinationCFrame) ~= "CFrame" then
			self.systemMessageRemote:FireClient(player, "The cave door forgot where the hallway is.")
			return
		end

		if not self:_canUseTeleport(player) then
			return
		end

		self.discoveryService:Unlock(player, Constants.Discoveries.CaveOpenedDoor.Id)
		playSound(door, "rbxasset://sounds/button.wav", 0.75, 0.62)
		if door:IsA("BasePart") then
			tweenPart(door, 0.24, {
				Color = Color3.fromRGB(119, 255, 203),
				Transparency = 0.32,
			}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		end

		task.delay(0.18, function()
			self.caveHallDoorLockedByUserId[player.UserId] = true
			self:_openCaveEntranceForNewPlayers()
			self:_teleportPlayer(player, destinationCFrame, "CaveKeyDoor")
			self.systemMessageRemote:FireClient(player, "The cave door opens into the hallway. Only the TV Room looks ready to admit anything.")
		end)
	end, {
		PrologueSafeNavigation = true,
	})
end

function InteractionService:_wireMainButton(button)
	local prompt = getPrompt(button)

	self:_connectPrompt(prompt, function(player)
		local servicedRain = self:_serviceActiveObjectRain()
		local accepted = false
		local eventManagerActive = self.eventManager and self.eventManager.IsActive and self.eventManager:IsActive()
		if not (servicedRain and eventManagerActive) then
			accepted = self.eventManager:TriggerRandom(player)
		end

			if (accepted or servicedRain) and button:IsA("BasePart") then
				if accepted then
					self:_cycleRoomMood("TVRoom")
				end
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
	local visualParts = {}
	local visualGroup = button:GetAttribute("ButtonVisualGroup")

	if visualGroup and button.Parent then
		for _, child in ipairs(button.Parent:GetChildren()) do
			if child:IsA("BasePart") and child:GetAttribute("ButtonVisualGroup") == visualGroup then
				table.insert(visualParts, child)
			end
		end
	else
		table.insert(visualParts, button)
		local shine = button.Parent and button.Parent:FindFirstChild("BigRedButtonShine")
		if shine and shine:IsA("BasePart") then
			table.insert(visualParts, shine)
		end
	end

	if #visualParts == 0 then
		return
	end

	local visualRoot = button.Parent
	local basePivot = if visualRoot and visualRoot:IsA("Model") then visualRoot:GetPivot() else nil
	local baseCFrames = {}
	local localCFrames = {}
	for _, part in ipairs(visualParts) do
		baseCFrames[part] = part.CFrame
		if basePivot then
			localCFrames[part] = basePivot:ToObjectSpace(part.CFrame)
		end
	end

	local baseColor = button:GetAttribute("BaseColor") or button.Color

	playSound(button, "rbxasset://sounds/button.wav", 0.45, 0.9)

	local motion = Instance.new("Vector3Value")
	motion.Value = Vector3.zero
	local motionConnection = motion:GetPropertyChangedSignal("Value"):Connect(function()
		local currentPivot = if basePivot and visualRoot and visualRoot.Parent then visualRoot:GetPivot() else nil
		for _, part in ipairs(visualParts) do
			if part.Parent then
				local baseCFrame = if currentPivot and localCFrames[part]
					then currentPivot * localCFrames[part]
					else baseCFrames[part]
				part.CFrame = baseCFrame + motion.Value
			end
		end
	end)

	local downTween = TweenService:Create(
		motion,
		TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Value = Vector3.new(0, -0.24, 0) }
	)
	tweenPart(button, 0.1, {
		Color = Color3.fromRGB(165, 12, 23),
	}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	downTween:Play()
	downTween.Completed:Wait()

	local upTween = TweenService:Create(
		motion,
		TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Value = Vector3.zero }
	)
	tweenPart(button, 0.18, {
		Color = baseColor,
	}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	upTween:Play()
	upTween.Completed:Wait()

	motionConnection:Disconnect()
	motion:Destroy()
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
			local highlightMode = state.OnCycle % 2 == 1
			local color = if highlightMode
				then SWITCH_ON_COLORS[((state.OnCycle - 1) % #SWITCH_ON_COLORS) + 1]
				else Color3.fromRGB(255, 224, 145)
			Lighting.Brightness = 2.2
			Lighting.ClockTime = highlightMode and 17 or 14
			Lighting.Ambient = color
			Lighting.OutdoorAmbient = if highlightMode
				then color:Lerp(Color3.fromRGB(255, 255, 255), 0.22)
				else Color3.fromRGB(190, 190, 180)
			self:_syncLightSwitches(true)

			if isControlPanelInteraction(lightSwitch) then
				playControlPanelSound(plate or lever or lightSwitch, 0.5, 1.05)
			else
				playSound(plate or lever or lightSwitch, "rbxasset://sounds/electronicpingshort.wav", 0.55, 1.1)
			end
			if highlightMode then
				self.systemMessageRemote:FireClient(player, "The room lights come back in thumbnail mode.")
			else
				self.systemMessageRemote:FireClient(player, "The room lights return to normal. Normal is a strong word.")
			end

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

			if isControlPanelInteraction(lightSwitch) then
				playControlPanelSound(plate or lever or lightSwitch, 0.46, 0.95)
			else
				playSound(plate or lever or lightSwitch, "rbxasset://sounds/button.wav", 0.45, 0.82)
			end
			self.systemMessageRemote:FireClient(player, "The room goes suspiciously dark.")
		end

		task.wait(0.15)
		state.Reacting = false
	end)
end

function InteractionService:_syncLightSwitches(isOn)
	local state = self.lightSwitchState
	local colorIndex = math.max(1, state.OnCycle)
	local highlightMode = colorIndex % 2 == 1
	local onColor = if highlightMode
		then SWITCH_ON_COLORS[((colorIndex - 1) % #SWITCH_ON_COLORS) + 1]
		else Color3.fromRGB(255, 224, 145)
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

	PlayerScale.ApplyTemporary(player, 2.25, Constants.SizeTransformDuration or Constants.EventDuration)
	self.discoveryService:Unlock(player, Constants.Discoveries.GiantPlayer.Id)
	self.systemMessageRemote:FireClient(player, "The light switch made you inconveniently tall.")
	self.transformCameraRemote:FireClient(player, {
		Action = "SizeTransform",
		Scale = 2.25,
		Duration = Constants.SizeTransformCameraDuration or 3,
		Label = "Giant mode",
	})
end

function InteractionService:_wireUnderfloorReturn(instance)
	local prompt = getPrompt(instance)

	self:_connectPrompt(prompt, function(player)
		local destinationCFrame = instance:GetAttribute("DestinationCFrame") or CFrame.new(0, 5, 10)
		self.discoveryService:Unlock(player, Constants.Discoveries.EscapedUnderfloor.Id)
		self.systemMessageRemote:FireClient(player, "The room underside sent you back upstairs.")
		self:_teleportPlayer(player, destinationCFrame, "UnderfloorReturn")
	end)
end

function InteractionService:_wireReferenceBook(bookPart)
	local prompt = getPrompt(bookPart)

	self:_connectPrompt(prompt, function(player)
		playControlPanelSound(bookPart, 0.42, 1.02)
		local roomId = bookPart:GetAttribute("RoomId") or "TVRoom"
		self.systemMessageRemote:FireClient(player, ("Opening %s room log."):format(roomId))
		if self.roomProgressService then
			self.roomProgressService:ShowReferenceBook(player, roomId)
		end
	end)
end

function InteractionService:_wireStoreButton(button)
	local prompt = getPrompt(button)

	self:_connectPrompt(prompt, function(player)
		playControlPanelSound(button, 0.46, 1)
		local roomId = button:GetAttribute("RoomId") or (self.roomProgressService and self.roomProgressService:GetRoomForPlayer(player)) or "TVRoom"
		self.systemMessageRemote:FireClient(player, ("Opening %s rewards."):format(roomId))
		if self.roomProgressService then
			self.roomProgressService:ShowStore(player, roomId)
		end
	end)
end

function InteractionService:_wireTeleportButton(button)
	local prompt = getPrompt(button)

	self:_connectPrompt(prompt, function(player)
		playControlPanelSound(button, 0.46, 1)
		local roomId = button:GetAttribute("RoomId") or (self.roomProgressService and self.roomProgressService:GetRoomForPlayer(player)) or "TVRoom"
		self.systemMessageRemote:FireClient(player, ("Opening %s teleport controls."):format(roomId))
		if not self.discoveryService:HasTeleportKey(player) then
			self.systemMessageRemote:FireClient(player, "The Teleport control blinks: key required.")
			playSound(button, "rbxasset://sounds/snap.wav", 0.32, 0.7)
			return
		end

		if self.roomProgressService then
			self.roomProgressService:ShowTeleportMenu(player, roomId)
		end
	end)
end

function InteractionService:_wireFieldButton(button)
	local prompt = getPrompt(button)

	self:_connectPrompt(prompt, function(player)
		playControlPanelSound(button, 0.48, 0.96)
		local roomId = button:GetAttribute("RoomId") or (self.roomProgressService and self.roomProgressService:GetRoomForPlayer(player)) or "TVRoom"
		self.systemMessageRemote:FireClient(player, ("Opening %s field controls."):format(roomId))
		if self.roomProgressService then
			self.roomProgressService:ShowFieldControls(player, roomId)
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

		if self.discoveryService:HasSecretKey(player, roomId) then
			state.OutlineVisible = true
			state.Active = true
			state.HasKey = true
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

		local secretConfig = Constants.SecretDoors and Constants.SecretDoors[roomId]
		local alreadyUnlocked = secretConfig
			and secretConfig.EntryDiscoveryId
			and self.discoveryService:HasDiscovery(player, secretConfig.EntryDiscoveryId)
		local hasKey = self.discoveryService:HasSecretKey(player, roomId)
		local roomComplete = self.discoveryService:IsRoomComplete(player, roomId)

		if not alreadyUnlocked and not hasKey then
			if roomComplete then
				self.systemMessageRemote:FireClient(player, "The Library is awaiting the Library Key. A secret discovery is probably hoarding it.")
			else
				self.systemMessageRemote:FireClient(player, "The Library outline is visible, but it still wants the Library Key.")
			end
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

		self:_teleportPlayer(player, destinationCFrame, "SecretRoomDoor")
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
		local isPrologueOpen =
			self.roomProgressService and self.roomProgressService:IsUntouchedPrologueActive(player)
		local destinationCFrame = exitDoor:GetAttribute("DestinationCFrame")
		if typeof(destinationCFrame) ~= "CFrame" then
			self.systemMessageRemote:FireClient(player, "The secret exit is having stage fright.")
			return
		end

		self:_teleportPlayer(player, destinationCFrame, "SecretRoomExit")
		local unlockDiscoveryId = exitDoor:GetAttribute("UnlockDiscoveryId")
		if typeof(unlockDiscoveryId) == "string" and not isPrologueOpen then
			self.discoveryService:Unlock(player, unlockDiscoveryId)
		end
		local destinationName = exitDoor:GetAttribute("DestinationName") or "the TV Room"
		local travelMessage = exitDoor:GetAttribute("TravelMessage")
		self.systemMessageRemote:FireClient(player, typeof(travelMessage) == "string" and travelMessage or ("Back to %s. Act natural."):format(destinationName))
	end, {
		PrologueSafeNavigation = true,
	})
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
		local center = baseCFrame.Position
		local visualParts = {}
		local visualGroup = globe:GetAttribute("LibraryGlobeVisualGroup")
		if visualGroup and globe.Parent then
			for _, child in ipairs(globe.Parent:GetChildren()) do
				if child:IsA("BasePart") and child:GetAttribute("LibraryGlobeVisualGroup") == visualGroup then
					table.insert(visualParts, child)
				end
			end
		end
		if #visualParts == 0 then
			table.insert(visualParts, globe)
		end

		local baseCFrames = {}
		for _, part in ipairs(visualParts) do
			baseCFrames[part] = part:GetAttribute("BaseCFrame") or part.CFrame
		end

		for step = 1, 24 do
			if not globe.Parent then
				break
			end

			local rotation = CFrame.new(center) * CFrame.Angles(0, math.rad(step * 36), 0) * CFrame.new(-center)
			for _, part in ipairs(visualParts) do
				if part.Parent then
					part.CFrame = rotation * baseCFrames[part]
				end
			end
			task.wait(0.035)
		end

		if globe.Parent then
			for _, part in ipairs(visualParts) do
				if part.Parent then
					tweenPart(part, 0.18, {
						CFrame = baseCFrames[part],
					}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				end
			end
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
		local visual = ladder:FindFirstChild("LibraryRollingLadderVisual")
		local visualBasePivot = nil
		if visual and visual:IsA("Model") then
			visualBasePivot = visual:GetAttribute("BasePivot") or visual:GetPivot()
			if visual:GetAttribute("BasePivot") == nil then
				visual:SetAttribute("BasePivot", visualBasePivot)
			end
		end
		state.Moved = not state.Moved
		local targetCFrame = state.Moved and (baseCFrame + Vector3.new(2.6, 0, -1.1)) or baseCFrame
		tweenPart(ladder, 0.35, {
			CFrame = targetCFrame,
			Color = state.Moved and Color3.fromRGB(219, 154, 82) or (ladder:GetAttribute("BaseColor") or ladder.Color),
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		if visual and visual:IsA("Model") and visualBasePivot then
			local visualRelativeCFrame = baseCFrame:ToObjectSpace(visualBasePivot)
			task.spawn(function()
				tweenModel(visual, targetCFrame * visualRelativeCFrame, 0.35)
			end)
		end

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
		self:_teleportPlayer(player, destination, "LibraryLoftDoor")
		task.wait(0.25)
		state.Reacting = false
	end)
end

function InteractionService:_wireLibraryTeleportKey(key)
	local prompt = getPrompt(key)

	self:_connectPrompt(prompt, function(player)
		if not self.discoveryService:HasDiscovery(player, Constants.Discoveries.LibraryLoft.Id) then
			self.systemMessageRemote:FireClient(player, "The Teleport Key hums from the loft. The Library wants you to reach the room properly first.")
			playSound(key, "rbxasset://sounds/snap.wav", 0.35, 0.55)
			return
		end

		local unlocked = self.discoveryService:Unlock(player, Constants.Discoveries.LibraryTeleportKey.Id)
		local granted = self.discoveryService:GrantTeleportKey(player, "Teleport Key added. Room controls can now jump to opened rooms.")
		if not unlocked and not granted then
			self.systemMessageRemote:FireClient(player, "You already have the Teleport Key.")
		end

		playSound(key, "rbxasset://sounds/electronicpingshort.wav", 0.5, 1.9)
		local root = key.Parent
		if root then
			for _, instance in ipairs(getInstanceAndDescendants(root)) do
				if instance:IsA("BasePart") and string.sub(instance.Name, 1, #"LibraryTeleportKey") == "LibraryTeleportKey" then
					instance.Transparency = 0.62
					instance.CanCollide = false
				end
			end
		end
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

		self:_teleportPlayer(player, destinationCFrame, "LibraryBookcaseDoor")
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
	local subsystemPower = self:_getBunkerSubsystemPower()

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
	local ballVelocityZ = (button:GetAttribute("BallVelocityZ") or -118) * math.clamp(0.42 + subsystemPower * 0.58, 0.42, 1)
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

	ball.AssemblyLinearVelocity = Vector3.new((math.random() - 0.5) * (1 - subsystemPower) * 16, 0, ballVelocityZ)
	ball.AssemblyAngularVelocity = Vector3.new(-28 * math.clamp(0.5 + subsystemPower * 0.5, 0.5, 1), 0, 0)
	self:_scheduleBunkerReclaim(ball, {
		Delay = 13.5,
		Key = "bowling_balls",
		Message = "An abandoned bowling ball rolls half an inch, then the lane quietly reclaims it.",
		SinkDistance = 1.4,
		Duration = 0.95,
	})
	Debris:AddItem(ball, 18)

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

function InteractionService:_formatBowlingAdScoreText()
	return ("LANE SCORES\n1: %02d   2: %02d   3: %02d"):format(
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
	if self.bowlingAdStep and self.bowlingAdStep % 3 == 2 then
		self:_updateBowlingAds(self.bowlingAdStep)
	end
end

function InteractionService:_updateBowlingAds(step)
	self.bowlingAdStep = step
	local showScores = step % 3 == 2
	local adStep = math.floor(step / 3) * 2 + (step % 3)
	local powerState, power = self:_getBunkerPowerState()

	for _, instance in ipairs(workspace:GetDescendants()) do
		if instance:IsA("BasePart") and instance:GetAttribute("BowlingAdScreen") then
			local ad
			local adOffset = instance:GetAttribute("BowlingAdOffset") or 1
			local screenFlicker = powerState == "Offline"
				or (powerState == "Flicker" and ((step + adOffset) % 3 == 0))
				or (powerState == "Weak" and ((step + adOffset) % 8 == 0))
			if screenFlicker then
				ad = {
					Text = if powerState == "Offline" then "SIGNAL STARVED\nTOUCH INPUT REQUESTED" else "LOW POWER\nPLEASE KEEP BOWLING",
					Background = Color3.fromRGB(8, 10, 14),
					TextColor = Color3.fromRGB(255, 132, 140),
				}
			elseif showScores then
				ad = {
					Text = self:_formatBowlingAdScoreText(),
					Background = Color3.fromRGB(18, 24, 36),
					TextColor = Color3.fromRGB(119, 255, 203),
				}
			else
				ad = BOWLING_ADS[((adStep + adOffset - 1) % #BOWLING_ADS) + 1]
			end

			local label = instance:FindFirstChild("BowlingAdText", true)
			if label and label:IsA("TextLabel") then
				label.Text = ad.Text
				label.TextColor3 = ad.TextColor
				label.BackgroundColor3 = ad.Background
			end

			instance.Color = ad.Background:Lerp(Color3.fromRGB(3, 4, 8), math.clamp((1 - power) * 0.38, 0, 0.38))
			local light = instance:FindFirstChild("BowlingAdLight", true)
			if light and light:IsA("SurfaceLight") then
				light.Color = ad.Background
				light.Brightness = if screenFlicker then 0.05 else 0.28 + power * 1.22
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

function InteractionService:_startBowlingMaintenanceMotion()
	if self.bowlingMaintenanceMotionConnection then
		self.bowlingMaintenanceMotionConnection:Disconnect()
	end

	local startedAt = os.clock()
	self.bowlingMaintenanceMotionConnection = RunService.Heartbeat:Connect(function()
		local elapsed = os.clock() - startedAt
		local belt = workspace:FindFirstChild("MaintenanceConveyor", true)
		local beltCFrame = if belt and belt:IsA("BasePart") then belt.CFrame else nil
		local beltLength = if belt and belt:IsA("BasePart") then math.max(8, belt.Size.X) else 15.8
		local beltStart = -beltLength / 2 - 2.8
		local beltTravel = beltLength + 5.6
		local subsystemPower = self:_getBunkerSubsystemPower()
		local beltSpeed = 0.32 + 1.93 * (subsystemPower ^ 0.85)

		for _, mover in ipairs(CollectionService:GetTagged(Constants.Tags.BowlingMaintenanceMover)) do
			if not mover.Parent then
				continue
			end

			local kind = mover:GetAttribute("MaintenanceMotionKind") or "Ball"
			local index = mover:GetAttribute("MaintenanceMotionIndex") or 1
			local laneOffset = if kind == "Pin" then 0.55 else -0.42
			local spacing = 2.18
			local phase = (elapsed * beltSpeed + index * spacing) % beltTravel
			local x = beltStart + phase
			local skipCycle = math.floor((elapsed * beltSpeed + index * spacing) / beltTravel)
			local lowPowerSkip = subsystemPower < 0.32 and ((skipCycle + index) % 3 == 0)
			local hiddenPass = ((skipCycle + index * 3) % 7) == 0 or lowPowerSkip
			local edgeFade = math.clamp(math.min(phase, beltTravel - phase) / 1.35, 0, 1)
			local yLift = if kind == "Pin" then 1.17 else 0.96
			local beltOffset = Vector3.new(x, yLift, laneOffset)
			local beltRotation = if kind == "Pin"
				then CFrame.Angles(0, math.rad(90), math.rad(math.sin(elapsed * 4 + index) * 0.025))
				else CFrame.Angles(math.rad(elapsed * 80 + index * 31), math.rad(elapsed * 22), math.rad(elapsed * 38))

			if mover:IsA("Model") then
				local basePivot = mover:GetAttribute("MaintenanceBasePivot")
				if typeof(basePivot) ~= "CFrame" then
					basePivot = mover:GetPivot()
					mover:SetAttribute("MaintenanceBasePivot", basePivot)
				end
				local targetCFrame = if beltCFrame then beltCFrame * CFrame.new(beltOffset) * beltRotation else basePivot * CFrame.new(beltOffset) * beltRotation
				mover:PivotTo(targetCFrame)
				for _, descendant in ipairs(mover:GetDescendants()) do
					if descendant:IsA("BasePart") then
						local baseTransparency = descendant:GetAttribute("BaseTransparency")
						local visibleTransparency = if baseTransparency ~= nil then baseTransparency else 0
						descendant.Transparency = if hiddenPass then 1 else visibleTransparency + (1 - visibleTransparency) * (1 - edgeFade)
					end
				end
			elseif mover:IsA("BasePart") then
				local baseCFrame = mover:GetAttribute("MaintenanceBaseCFrame") or mover:GetAttribute("BaseCFrame")
				if typeof(baseCFrame) ~= "CFrame" then
					baseCFrame = mover.CFrame
					mover:SetAttribute("MaintenanceBaseCFrame", baseCFrame)
				end
				mover.CFrame = if beltCFrame then beltCFrame * CFrame.new(beltOffset) * beltRotation else baseCFrame * CFrame.new(beltOffset) * beltRotation
				local baseTransparency = mover:GetAttribute("BaseTransparency")
				local visibleTransparency = if baseTransparency ~= nil then baseTransparency else 0
				mover.Transparency = if hiddenPass then 1 else visibleTransparency + (1 - visibleTransparency) * (1 - edgeFade)
			end
		end
	end)
end

function InteractionService:_getBowlingLaneSoundSource(laneIndex, fallback)
	for _, pin in ipairs(CollectionService:GetTagged(Constants.Tags.BowlingPin)) do
		if pin:IsA("BasePart") and pin:GetAttribute("LaneIndex") == laneIndex then
			return pin
		end
	end

	return fallback
end

function InteractionService:_playBowlingStrikeSound(laneIndex, fallback)
	local soundId = chooseRandomAudioId(BOWLING_STRIKE_SOUND_IDS, self.bowlingAudioRandom, self.lastBowlingStrikeSoundId)
	if not soundId then
		return
	end

	self.lastBowlingStrikeSoundId = soundId
	playSound(self:_getBowlingLaneSoundSource(laneIndex, fallback), soundId, BOWLING_STRIKE_SOUND_VOLUME, 1)
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
		local powerState, power = self:_getBunkerPowerState()
		if powerState == "Offline" then
			self:_bunkerSputter(button, "The lane button clicks, but the room grid does not have enough charge to roll anything yet.")
			task.delay(0.9, function()
				state.Reacting = false
			end)
			return
		end

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
		if powerState == "Flicker" or powerState == "Weak" then
			self.systemMessageRemote:FireClient(player, ("Lane %d coughs up a low-power roll. The room grid likes the effort."):format(laneIndex))
		else
			self.systemMessageRemote:FireClient(player, ("Lane %d accepts your bowling-related decision."):format(laneIndex))
		end

		task.delay(2.8, function()
			local knocked = self:_countKnockedBowlingPins(laneIndex)
			if knocked >= 8 then
				self.discoveryService:Unlock(player, Constants.Discoveries.BowlingStrike.Id)
				self:_playBowlingStrikeSound(laneIndex, button)
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
	local subsystemPower = self:_getBunkerSubsystemPower()
	local cosmicScale = math.clamp((subsystemPower - (Constants.BunkerEnergy.CosmicMinimumPower or 0.2)) / math.max(0.05, 1 - (Constants.BunkerEnergy.CosmicMinimumPower or 0.2)), 0, 1)

	if active then
		local musicId = chooseRandomAudioId(BOWLING_COSMIC_MUSIC_IDS, self.bowlingAudioRandom, self.lastBowlingCosmicMusicId)
		self.lastBowlingCosmicMusicId = musicId or self.lastBowlingCosmicMusicId
		workspace:SetAttribute(BOWLING_COSMIC_MUSIC_ATTRIBUTE, musicId)
		workspace:SetAttribute(BOWLING_COSMIC_ACTIVE_ATTRIBUTE, true)
		Lighting.Brightness = 0.45 + cosmicScale * 0.65
		Lighting.ClockTime = 0
		Lighting.Ambient = Color3.fromRGB(44, 18, 80):Lerp(Color3.fromRGB(6, 4, 12), 1 - cosmicScale)
		Lighting.OutdoorAmbient = Color3.fromRGB(15, 8, 38)
	else
		workspace:SetAttribute(BOWLING_COSMIC_ACTIVE_ATTRIBUTE, false)
		workspace:SetAttribute(BOWLING_COSMIC_MUSIC_ATTRIBUTE, nil)
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
			light.Brightness = active and (0.35 + cosmicScale * 5.25) or 0
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
			local livePower = self:_getBunkerSubsystemPower()
			local flickering = livePower < (Constants.BunkerEnergy.CosmicWeakPower or 0.5)
			local pulseOn = not flickering or (step % 4 ~= 0 and (livePower > 0.24 or step % 7 ~= 0))
			local pulseScale = if pulseOn then math.clamp(0.22 + livePower * 0.78, 0.12, 1) else 0.04

			for _, instance in ipairs(workspace:GetDescendants()) do
				if instance:IsA("BasePart") and instance:GetAttribute("CosmicSurface") then
					instance.Color = BOWLING_COSMIC_COLORS[((step + math.floor(math.abs(instance.Position.X))) % #BOWLING_COSMIC_COLORS) + 1]
					instance.Transparency = if pulseOn then instance:GetAttribute("BaseTransparency") or 0 else 0.48
				end
			end

			for _, disco in ipairs(CollectionService:GetTagged(Constants.Tags.BowlingDiscoBall)) do
				if disco:IsA("BasePart") then
					disco.CFrame = (disco:GetAttribute("BaseCFrame") or disco.CFrame) * CFrame.Angles(0, math.rad(step * 22), 0)
				end

				local light = disco:FindFirstChild("DiscoLight", true)
				if light and light:IsA("PointLight") then
					light.Color = color
					light.Brightness = 0.2 + pulseScale * 5.4
				end
			end

			self:_setBowlingCosmicFog(pulseOn and livePower > 0.28)
			self:_updateBowlingLaserBeams(step, pulseOn and livePower > 0.2)

			task.wait(if flickering then 0.34 + (1 - livePower) * 0.26 else 0.28)
		end
	end)

	if source then
		playSound(source, "rbxasset://sounds/electronicpingshort.wav", 0.5, 1.9)
	end
end

function InteractionService:_startCaveAmbientSounds()
	if self.caveAmbientSoundsStarted then
		return
	end

	self.caveAmbientSoundsStarted = true
	local prologueAudio = Constants.AudioAssets and Constants.AudioAssets.Prologue
	if not prologueAudio then
		return
	end

	local outsideSource = workspace:FindFirstChild("OutsideCaveSoundSource", true)
	if outsideSource then
		playLoopedSpatialSound(outsideSource, "OutsideCaveLoop", prologueAudio.OutsideCaveAmbienceId, {
			Volume = 0.48,
			RollOffMinDistance = 8,
			RollOffMaxDistance = 38,
			RollOffMode = Enum.RollOffMode.InverseTapered,
		})
	end

	local insideSource = workspace:FindFirstChild("InsideCaveSoundSource", true)
	if insideSource then
		playLoopedSpatialSound(insideSource, "InsideCaveLoop", prologueAudio.InsideCaveAmbienceId, {
			Volume = 0.34,
			RollOffMinDistance = 10,
			RollOffMaxDistance = 64,
			RollOffMode = Enum.RollOffMode.InverseTapered,
		})
	end
end

function InteractionService:_wireBowlingCosmicSwitch(switch)
	local prompt = getPrompt(switch)

	self:_connectPrompt(prompt, function(player)
		self.discoveryService:Unlock(player, Constants.Discoveries.BowlingCosmic.Id)
		local powerState, power = self:_getBunkerPowerState()
		if not self.bowlingCosmicActive and power < (Constants.BunkerEnergy.CosmicMinimumPower or 0.2) then
			self:_bunkerSputter(switch, "The disco ball tries once, then remembers the room grid is undercharged.")
			if prompt then
				prompt.ActionText = "Cosmic"
			end
			return
		end

		self:_setBowlingCosmic(not self.bowlingCosmicActive, switch)
		if prompt then
			prompt.ActionText = self.bowlingCosmicActive and "Normalize" or "Cosmic"
		end

		self.systemMessageRemote:FireClient(
			player,
			self.bowlingCosmicActive
				and (powerState == "Weak" or powerState == "Flicker")
					and "Cosmic Bowling sputters awake. The room grid is doing its best with crumbs."
				or self.bowlingCosmicActive
					and "Cosmic Bowling is on. The floor is taking lighting personally."
				or "Cosmic Bowling is off. The alley returns to regular questionable bowling."
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
		self:_teleportPlayer(player, destinationCFrame, "BowlingMaintenanceDoor")
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
		local powerState = self:_getBunkerPowerState()
		if powerState == "Offline" then
			self:_bunkerSputter(lever, "The pinsetter clicks twice and gives up. The room grid needs activity before it can tidy the lane.")
			return
		end

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

		if powerState == "Flicker" then
			self.systemMessageRemote:FireClient(player, ("Lane %d pinsetter stutters, then barely resets."):format(laneIndex or 0))
		elseif laneIndex then
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
		local powerState = self:_getBunkerPowerState()
		if powerState == "Offline" then
			self:_bunkerSputter(ballReturn, "The lane reset button glows weakly. It needs a few more terrible decisions to wake up.")
			return
		end

		self:_resetBowlingPins(laneIndex)
		self:_incrementBowlingLaneCount(laneIndex)
		playSound(ballReturn, "rbxasset://sounds/button.wav", 0.45, 0.72)
		task.delay(0.1, function()
			playSound(ballReturn, "rbxasset://sounds/electronicpingshort.wav", 0.35, 1.45)
		end)

		if ballReturn:IsA("BasePart") then
			local baseCFrame = ballReturn:GetAttribute("BaseCFrame") or ballReturn.CFrame
			local baseColor = ballReturn:GetAttribute("BaseColor") or ballReturn.Color
			local pressTween = tweenPart(ballReturn, 0.1, {
				CFrame = baseCFrame + Vector3.new(0, -0.08, 0),
				Color = Color3.fromRGB(255, 214, 96),
			}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			pressTween.Completed:Wait()
			tweenPart(ballReturn, 0.18, {
				CFrame = baseCFrame,
				Color = baseColor,
			}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end

		if powerState == "Flicker" then
			self.systemMessageRemote:FireClient(player, ("Lane %d resets with a tired mechanical sigh."):format(laneIndex or 0))
		elseif laneIndex then
			self.systemMessageRemote:FireClient(player, ("Lane %d resets the ball and pins. The scoreboard counts the paperwork."):format(laneIndex))
		else
			self.systemMessageRemote:FireClient(player, "The lane resets the balls, pins, and most of its dignity.")
		end
	end)
end

function InteractionService:_spawnZiplineRideSpark(position, lookPosition, index)
	local direction = lookPosition - position
	if direction.Magnitude < 0.05 then
		direction = Vector3.new(0, 0, 1)
	else
		direction = direction.Unit
	end

	local side = direction:Cross(Vector3.yAxis)
	if side.Magnitude < 0.05 then
		side = Vector3.xAxis
	else
		side = side.Unit
	end

	local color = BOWLING_COSMIC_COLORS[((index - 1) % #BOWLING_COSMIC_COLORS) + 1]
	local spark = Instance.new("Part")
	spark.Name = "ZiplineRideSpark"
	spark.Anchored = true
	spark.CanCollide = false
	spark.CastShadow = false
	spark.Material = Enum.Material.Neon
	spark.Color = color
	spark.Transparency = 0.12
	spark.Size = Vector3.new(0.16, 0.16, 3.6)
	spark.CFrame = CFrame.lookAt(
		position + side * (((index % 5) - 2) * 0.85) + Vector3.new(0, ((index % 4) - 1.5) * 0.45, 0),
		position + direction
	)
	spark.Parent = workspace
	CollectionService:AddTag(spark, Constants.Tags.TemporaryObject)
	tweenPart(spark, 0.42, {
		CFrame = spark.CFrame + direction * 8,
		Transparency = 1,
	}, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	Debris:AddItem(spark, 0.7)
end

function InteractionService:_startVoidAmbientMotion()
	if self.voidAmbientMotionStarted then
		return
	end

	self.voidAmbientMotionStarted = true
	local movingParts = {}
	local room = workspace:FindFirstChild("Room")
	if not room then
		return
	end

	for _, instance in ipairs(room:GetDescendants()) do
		if instance:IsA("BasePart") and (instance:GetAttribute("VoidDriftDot") == true or instance.Name:find("VoidMotionRing")) then
			table.insert(movingParts, {
				Part = instance,
				BaseCFrame = instance:GetAttribute("BaseCFrame") or instance.CFrame,
				Phase = #movingParts * 0.47,
				IsDot = instance:GetAttribute("VoidDriftDot") == true,
			})
		end
	end

	task.spawn(function()
		while self.voidAmbientMotionStarted do
			local now = os.clock()
			for _, record in ipairs(movingParts) do
				local part = record.Part
				if part.Parent then
					if record.IsDot then
						part.CFrame = record.BaseCFrame
							* CFrame.new(
								math.sin(now * 0.9 + record.Phase) * 1.2,
								math.cos(now * 0.72 + record.Phase) * 0.8,
								math.sin(now * 0.55 + record.Phase) * 1.0
							)
					else
						part.CFrame = record.BaseCFrame * CFrame.Angles(0, 0, math.sin(now * 0.42 + record.Phase) * 0.22)
					end
				end
			end
			task.wait(0.08)
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
		local awardsIsland = zipline:GetAttribute("AwardsIsland") ~= false
		local awardsVoid = zipline:GetAttribute("AwardsVoid") == true
		self.systemMessageRemote:FireClient(player, zipline:GetAttribute("RideMessage") or "The zipline accepts your island-bound paperwork.")
		playSound(zipline, "rbxasset://sounds/electronicpingshort.wav", 0.55, 1.35)

		local humanoid = getHumanoid(player)
		local previousAutoRotate = humanoid and humanoid.AutoRotate
		local previousAnchored = rootPart.Anchored
		local startCFrame = zipline:GetAttribute("StartCFrame")
		local endCFrame = zipline:GetAttribute("EndCFrame")
		local startPosition = (typeof(startCFrame) == "CFrame" and startCFrame.Position) or rootPart.Position
		local endPosition = (typeof(endCFrame) == "CFrame" and endCFrame.Position) or Constants.GetRoomSpawnCFrame("Island").Position
		local finalCFrame = typeof(endCFrame) == "CFrame" and endCFrame or Constants.GetRoomSpawnCFrame("Island")
		local pathPoints = {}
		local pathPointCount = zipline:GetAttribute("PathPointCount")
		if typeof(pathPointCount) == "number" then
			for index = 1, pathPointCount do
				local point = zipline:GetAttribute("PathPoint" .. index)
				if typeof(point) == "Vector3" then
					table.insert(pathPoints, point)
				end
			end
		end

		if #pathPoints < 2 then
			pathPoints = { startPosition, endPosition }
		end

		local pathDistance = 0
		for index = 1, #pathPoints - 1 do
			pathDistance += (pathPoints[index + 1] - pathPoints[index]).Magnitude
		end
		local stepCount = math.clamp(math.floor(pathDistance / 2.2), 150, 330)
		local rideDuration = stepCount / 30

		local function getPathPosition(alpha)
			alpha = math.clamp(alpha, 0, 1)
			local segmentCount = #pathPoints - 1
			if segmentCount <= 0 then
				return endPosition
			end

			local scaled = alpha * segmentCount
			local index = math.clamp(math.floor(scaled) + 1, 1, segmentCount)
			local segmentAlpha = scaled - (index - 1)
			local smoothAlpha = segmentAlpha * segmentAlpha * (3 - 2 * segmentAlpha)
			return pathPoints[index]:Lerp(pathPoints[index + 1], smoothAlpha)
		end

		if humanoid then
			humanoid.AutoRotate = false
		end
		self:_beginScriptedMotion(player, "TreetopZipline")
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
		rootPart.Anchored = true

		local warpEmitter = Instance.new("ParticleEmitter")
		warpEmitter.Name = "ZiplineTimeWarpTrail"
		warpEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		warpEmitter.Color = ColorSequence.new(Color3.fromRGB(119, 255, 203), Color3.fromRGB(150, 112, 255))
		warpEmitter.LightEmission = 0.7
		warpEmitter.Rate = 80
		warpEmitter.Lifetime = NumberRange.new(0.35, 0.8)
		warpEmitter.Speed = NumberRange.new(1.5, 6)
		warpEmitter.SpreadAngle = Vector2.new(180, 180)
		warpEmitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.55),
			NumberSequenceKeypoint.new(0.55, 1.8),
			NumberSequenceKeypoint.new(1, 0.1),
		})
		warpEmitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.05),
			NumberSequenceKeypoint.new(0.65, 0.28),
			NumberSequenceKeypoint.new(1, 1),
		})
		warpEmitter.Parent = rootPart
		Debris:AddItem(warpEmitter, rideDuration + 2)

		local warpLight = Instance.new("PointLight")
		warpLight.Name = "ZiplineTimeWarpLight"
		warpLight.Color = Color3.fromRGB(119, 255, 203)
		warpLight.Brightness = 2.6
		warpLight.Range = 16
		warpLight.Parent = rootPart
		Debris:AddItem(warpLight, rideDuration + 2)

		for step = 0, stepCount do
			if not player.Parent or not rootPart.Parent then
				break
			end

			local alpha = step / stepCount
			local position = getPathPosition(alpha)
			local lookPosition = getPathPosition(math.min(1, alpha + 0.018))
			if (lookPosition - position).Magnitude < 0.05 then
				lookPosition = endPosition
			end

			local roll = math.sin(alpha * math.pi * 10) * 0.3
			local warpPulse = math.sin(alpha * math.pi * 16)
			if warpLight then
				warpLight.Brightness = 2.1 + math.max(0, warpPulse) * 2.2
				warpLight.Color = Color3.fromRGB(
					90 + math.floor(math.max(0, warpPulse) * 90),
					220,
					255 - math.floor(math.max(0, warpPulse) * 70)
				)
			end

			rootPart.CFrame = CFrame.new(position, lookPosition) * CFrame.Angles(0, 0, roll)
			if step % 5 == 0 then
				self:_spawnZiplineRideSpark(position, lookPosition, step + 1)
			end
			task.wait(1 / 30)
		end

		if warpEmitter then
			warpEmitter.Enabled = false
		end
		if warpLight then
			warpLight.Enabled = false
		end

		if rootPart.Parent then
			rootPart.Anchored = previousAnchored
			rootPart.AssemblyLinearVelocity = Vector3.zero
			rootPart.AssemblyAngularVelocity = Vector3.zero
			self:_teleportPlayer(player, finalCFrame, "TreetopZipline")
		end
		self:_endScriptedMotion(player)

		if awardsVoid then
			self.discoveryService:Unlock(player, Constants.Discoveries.VoidEntered.Id)
		end
		if awardsIsland then
			self.discoveryService:Unlock(player, Constants.Discoveries.ReachedIsland.Id)
		end

		if humanoid and humanoid.Parent then
			humanoid.AutoRotate = previousAutoRotate
		end

		self.systemMessageRemote:FireClient(player, zipline:GetAttribute("ArrivalMessage") or "The island receives you with unnecessary confidence.")
		task.delay(1.2, function()
			self.treetopZiplineStateByUserId[player.UserId] = nil
		end)
	end)
end

function InteractionService:_wireVoidReverseConsole(console)
	local prompt = getPrompt(console)

	self:_connectPrompt(prompt, function(player)
		self.discoveryService:Unlock(player, Constants.Discoveries.VoidReverseControls.Id)
		self.voidEffectRemote:FireClient(player, {
			Action = "ReverseControls",
			Duration = 12,
		})
		playSound(console, "rbxasset://sounds/electronicpingshort.wav", 0.5, 0.42)
		self.systemMessageRemote:FireClient(player, "The Void reverses your controls for a few seconds. It insists this is navigation.")

		if console:IsA("BasePart") then
			local baseColor = console:GetAttribute("BaseColor") or console.Color
			tweenPart(console, 0.16, {
				Color = Color3.fromRGB(119, 255, 203),
			}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			task.delay(0.28, function()
				if console.Parent then
					tweenPart(console, 0.22, {
						Color = baseColor,
					}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				end
			end)
		end
	end)
end

function InteractionService:_wireVoidGravityOrb(orb)
	local prompt = getPrompt(orb)

	self:_connectPrompt(prompt, function(player)
		local rootPart = getRootPart(player)
		if not rootPart then
			return
		end

		self.discoveryService:Unlock(player, Constants.Discoveries.VoidGravityFlip.Id)
		playSound(orb, "rbxasset://sounds/electronicpingshort.wav", 0.58, 1.95)
		self.systemMessageRemote:FireClient(player, "The Void flips gravity. The ceiling has been promoted.")

		local token = {}
		self.voidGravityTokensByUserId[player.UserId] = token
		local attachment = Instance.new("Attachment")
		attachment.Name = "VoidGravityAttachment"
		attachment.Parent = rootPart

		local force = Instance.new("VectorForce")
		force.Name = "VoidGravityFlipForce"
		force.Attachment0 = attachment
		force.RelativeTo = Enum.ActuatorRelativeTo.World
		force.Force = Vector3.new(0, rootPart.AssemblyMass * workspace.Gravity * 2.15, 0)
		force.Parent = rootPart

		self:_addImpulse(player, Vector3.new(0, 76, 0), "VoidGravityFlip")
		Debris:AddItem(force, 7)
		Debris:AddItem(attachment, 7)

		if orb:IsA("BasePart") then
			local baseCFrame = orb:GetAttribute("BaseCFrame") or orb.CFrame
			tweenPart(orb, 0.28, {
				CFrame = baseCFrame * CFrame.Angles(math.rad(180), 0, math.rad(180)),
				Color = Color3.fromRGB(255, 88, 128),
			}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			task.delay(0.5, function()
				if orb.Parent then
					tweenPart(orb, 0.36, {
						CFrame = baseCFrame,
						Color = orb:GetAttribute("BaseColor") or Color3.fromRGB(119, 255, 203),
					}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				end
			end)
		end

		task.delay(7, function()
			if self.voidGravityTokensByUserId[player.UserId] == token then
				self.voidGravityTokensByUserId[player.UserId] = nil
			end
		end)
	end)
end

function InteractionService:_spawnVoidEchoPulse(origin, index)
	local pulse = Instance.new("Part")
	pulse.Name = "VoidEchoPulse"
	pulse.Anchored = true
	pulse.CanCollide = false
	pulse.CastShadow = false
	pulse.Shape = Enum.PartType.Ball
	pulse.Size = Vector3.new(1, 1, 1)
	pulse.CFrame = CFrame.new(origin)
	pulse.Material = Enum.Material.Neon
	pulse.Color = BOWLING_COSMIC_COLORS[((index - 1) % #BOWLING_COSMIC_COLORS) + 1]
	pulse.Transparency = 0.45
	pulse.Parent = workspace
	CollectionService:AddTag(pulse, Constants.Tags.TemporaryObject)
	tweenPart(pulse, 1.15, {
		Size = Vector3.new(14 + index * 5, 14 + index * 5, 14 + index * 5),
		Transparency = 1,
	}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	Debris:AddItem(pulse, 1.35)
end

function InteractionService:_wireVoidEchoButton(button)
	local prompt = getPrompt(button)

	self:_connectPrompt(prompt, function(player)
		self.discoveryService:Unlock(player, Constants.Discoveries.VoidEcho.Id)
		playSound(button, "rbxasset://sounds/button.wav", 0.45, 0.65)
		task.delay(0.16, function()
			playSound(button, "rbxasset://sounds/electronicpingshort.wav", 0.45, 0.36)
		end)
		self.systemMessageRemote:FireClient(player, "The Void answers from every direction except the useful one.")

		local origin = button:IsA("BasePart") and button.Position or Constants.GetRoomSpawnCFrame("Void").Position
		for index = 1, 5 do
			task.delay((index - 1) * 0.18, function()
				self:_spawnVoidEchoPulse(origin, index)
			end)
		end
	end)
end

function InteractionService:_hasFreezeRay(player)
	local function containerHasTool(container)
		if not container then
			return false
		end

		for _, item in ipairs(container:GetChildren()) do
			if item:IsA("Tool") and item:GetAttribute("VoidFreezeRay") == true then
				return true
			end
		end

		return false
	end

	return containerHasTool(player:FindFirstChildOfClass("Backpack")) or containerHasTool(player.Character)
end

function InteractionService:_spawnFreezeBeam(origin, targetPosition)
	local midpoint = (origin + targetPosition) / 2
	local distance = (targetPosition - origin).Magnitude
	if distance < 0.1 then
		return
	end

	local beam = Instance.new("Part")
	beam.Name = "VoidFreezeBeam"
	beam.Anchored = true
	beam.CanCollide = false
	beam.CastShadow = false
	beam.Material = Enum.Material.Neon
	beam.Color = Color3.fromRGB(152, 238, 255)
	beam.Transparency = 0.1
	beam.Size = Vector3.new(0.18, 0.18, distance)
	beam.CFrame = CFrame.new(midpoint, targetPosition)
	beam.Parent = workspace
	CollectionService:AddTag(beam, Constants.Tags.TemporaryObject)
	tweenPart(beam, 0.28, {
		Transparency = 1,
		Size = Vector3.new(0.42, 0.42, distance),
	}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	Debris:AddItem(beam, 0.42)
end

function InteractionService:_chillPlayer(targetPlayer)
	local humanoid = getHumanoid(targetPlayer)
	local rootPart = getRootPart(targetPlayer)
	if not humanoid or not rootPart then
		return
	end

	local token = {}
	self.voidChillTokensByHumanoid[humanoid] = token
	local baseWalkSpeed = humanoid.WalkSpeed
	local baseJumpPower = humanoid.JumpPower
	local baseJumpHeight = humanoid.JumpHeight
	humanoid.WalkSpeed = math.max(6, baseWalkSpeed * 0.55)
	if humanoid.UseJumpPower then
		humanoid.JumpPower = math.max(18, baseJumpPower * 0.62)
	else
		humanoid.JumpHeight = math.max(2.5, baseJumpHeight * 0.62)
	end
	rootPart.AssemblyLinearVelocity *= 0.35

	task.delay(1.7, function()
		if self.voidChillTokensByHumanoid[humanoid] ~= token or not humanoid.Parent then
			return
		end

		humanoid.WalkSpeed = baseWalkSpeed
		if humanoid.UseJumpPower then
			humanoid.JumpPower = baseJumpPower
		else
			humanoid.JumpHeight = baseJumpHeight
		end
		self.voidChillTokensByHumanoid[humanoid] = nil
	end)
end

function InteractionService:_freezeRayPart(part)
	if not part or not part.Parent or not part:IsA("BasePart") then
		return false
	end

	local canFreezeStatic = CollectionService:HasTag(part, Constants.Tags.TemporaryObject)
		or CollectionService:HasTag(part, Constants.Tags.ObjectRainObject)
		or CollectionService:HasTag(part, Constants.Tags.LooseFruit)
		or CollectionService:HasTag(part, Constants.Tags.BowlingPin)

	if part.Anchored and not canFreezeStatic then
		return false
	end

	local baseAnchored = part.Anchored
	local baseColor = part.Color
	local baseMaterial = part.Material
	local baseTransparency = part.Transparency
	part.Anchored = true
	part.Material = Enum.Material.Ice
	part.Color = Color3.fromRGB(185, 245, 255)
	part.Transparency = math.min(0.35, baseTransparency + 0.12)

	task.delay(4, function()
		if not part.Parent then
			return
		end

		part.Anchored = baseAnchored
		part.Material = baseMaterial
		part.Color = baseColor
		part.Transparency = baseTransparency
	end)

	return true
end

function InteractionService:_fireFreezeRay(player)
	local rootPart = getRootPart(player)
	if not rootPart then
		return
	end

	local origin = rootPart.Position + Vector3.new(0, 1.15, 0)
	local direction = rootPart.CFrame.LookVector * 60
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { player.Character }

	local result = workspace:Raycast(origin, direction, raycastParams)
	local targetPosition = result and result.Position or (origin + direction)
	self:_spawnFreezeBeam(origin, targetPosition)
	playSound(rootPart, "rbxasset://sounds/electronicpingshort.wav", 0.35, 2.2)

	if not result or not result.Instance then
		self.systemMessageRemote:FireClient(player, "The freeze ray cools several inches of empty air.")
		return
	end

	local hit = result.Instance
	local character = hit:FindFirstAncestorOfClass("Model")
	local targetPlayer = character and Players:GetPlayerFromCharacter(character)
	if targetPlayer and targetPlayer ~= player then
		self:_chillPlayer(targetPlayer)
		self.systemMessageRemote:FireClient(player, ("The freeze ray politely chills %s for a moment."):format(targetPlayer.DisplayName or targetPlayer.Name))
		return
	end

	if self:_freezeRayPart(hit) then
		self.systemMessageRemote:FireClient(player, "The freeze ray freezes one object just long enough to be irresponsible.")
	else
		self.systemMessageRemote:FireClient(player, "The freeze ray refuses to freeze important architecture. Good boundary.")
	end
end

function InteractionService:_buildFreezeRayToolVisual(tool)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Anchored = false
	handle.CanCollide = false
	handle.Massless = true
	handle.Material = Enum.Material.Metal
	handle.Color = Color3.fromRGB(18, 52, 112)
	handle.Size = Vector3.new(0.52, 1.35, 0.52)
	handle.CFrame = CFrame.new()
	handle.Parent = tool

	local function addPiece(name, size, offset, color, material, shape)
		local part = Instance.new("Part")
		part.Name = name
		part.Anchored = false
		part.CanCollide = false
		part.Massless = true
		part.Material = material or Enum.Material.Metal
		part.Color = color
		part.Size = size
		part.CFrame = handle.CFrame * offset
		if shape then
			part.Shape = shape
		end
		part.Parent = tool

		local weld = Instance.new("WeldConstraint")
		weld.Name = name .. "Weld"
		weld.Part0 = handle
		weld.Part1 = part
		weld.Parent = part
		return part
	end

	addPiece("FreezeRayBody", Vector3.new(1.05, 0.8, 1.36), CFrame.new(0, 0.78, -0.55), Color3.fromRGB(36, 116, 210), Enum.Material.Metal)
	addPiece("FreezeRayRearOrb", Vector3.new(0.82, 0.82, 0.82), CFrame.new(0, 0.83, 0.3), Color3.fromRGB(84, 219, 255), Enum.Material.Glass, Enum.PartType.Ball)
	addPiece("FreezeRayBarrel", Vector3.new(0.38, 1.9, 0.38), CFrame.new(0, 0.8, -1.55) * CFrame.Angles(math.rad(90), 0, 0), Color3.fromRGB(72, 189, 255), Enum.Material.Neon, Enum.PartType.Cylinder)
	addPiece("FreezeRayMuzzle", Vector3.new(0.7, 0.26, 0.7), CFrame.new(0, 0.8, -2.55) * CFrame.Angles(math.rad(90), 0, 0), Color3.fromRGB(216, 249, 255), Enum.Material.Metal, Enum.PartType.Cylinder)
	addPiece("FreezeRayMuzzleGlow", Vector3.new(0.48, 0.48, 0.48), CFrame.new(0, 0.8, -2.72), Color3.fromRGB(210, 255, 255), Enum.Material.Neon, Enum.PartType.Ball)
	addPiece("FreezeRayTopFin", Vector3.new(0.18, 0.58, 0.82), CFrame.new(0, 1.42, -0.32) * CFrame.Angles(math.rad(-18), 0, 0), Color3.fromRGB(98, 204, 255), Enum.Material.Neon)
	addPiece("FreezeRayTrigger", Vector3.new(0.18, 0.42, 0.22), CFrame.new(0, 0.02, -0.42) * CFrame.Angles(math.rad(-18), 0, 0), Color3.fromRGB(7, 18, 42), Enum.Material.Metal)
	addPiece("FreezeRayPommel", Vector3.new(0.72, 0.22, 0.58), CFrame.new(0, -0.78, 0.12), Color3.fromRGB(10, 30, 66), Enum.Material.Metal)

	tool.Grip = CFrame.new(0, -0.18, 0.16) * CFrame.Angles(math.rad(-12), 0, 0)
end

function InteractionService:_grantFreezeRay(player)
	if self:_hasFreezeRay(player) then
		return
	end

	local backpack = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack", 2)
	if not backpack then
		return
	end

	local tool = Instance.new("Tool")
	tool.Name = "Void Freeze Ray"
	tool.ToolTip = "Briefly chills players and freezes loose objects."
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool:SetAttribute("VoidFreezeRay", true)
	self:_buildFreezeRayToolVisual(tool)
	tool.Activated:Connect(function()
		if player.Parent then
			self:_fireFreezeRay(player)
		end
	end)
	tool.Parent = backpack
end

function InteractionService:_wireVoidFreezeRay(ray)
	local prompt = getPrompt(ray)

	self:_connectPrompt(prompt, function(player)
		self.discoveryService:Unlock(player, Constants.Discoveries.VoidFreezeRay.Id)
		self:_grantFreezeRay(player)
		playSound(ray, "rbxasset://sounds/electronicpingshort.wav", 0.55, 1.7)
		self.systemMessageRemote:FireClient(player, "Void prize unlocked: Freeze Ray. It freezes objects and only mildly inconveniences players.")
	end)
end

function InteractionService:_wireResetRoomButton(button)
	local prompt = getPrompt(button)

	self:_connectPrompt(prompt, function(player)
		playControlPanelSound(button, 0.5, 0.92)

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

function InteractionService:_restoreSnackWindStorms()
	for humanoid in pairs(self.windStormTokensByHumanoid) do
		if humanoid and humanoid.Parent then
			humanoid.WalkSpeed = humanoid:GetAttribute("SnackWindBaseWalkSpeed") or 16
			if humanoid.UseJumpPower then
				humanoid.JumpPower = humanoid:GetAttribute("SnackWindBaseJumpPower") or 50
			else
				humanoid.JumpHeight = humanoid:GetAttribute("SnackWindBaseJumpHeight") or 7.2
			end
		end
		self.windStormTokensByHumanoid[humanoid] = nil
	end
end

function InteractionService:ResetRoomForPlayer(player)
	self:_clearAllTelevisions()
	for _, state in pairs(self.snackFanState) do
		state.SpinToken = nil
	end
	self:_stopSnackFlightForRoom(player)
	self:_restoreSnackWindStorms()
	self.eventManager:ResetRoom(player)
	self:AfterRoomReset()
end

function InteractionService:_afterRoomReset()
	self.bowlingCosmicActive = false
	self.bowlingCosmicToken = {}
	workspace:SetAttribute(BOWLING_COSMIC_ACTIVE_ATTRIBUTE, false)
	workspace:SetAttribute(BOWLING_COSMIC_MUSIC_ATTRIBUTE, nil)
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
		state.BurnEndsAt = 0
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
		self.systemMessageRemote:FireClient(player, "The microwave is reheating time.")

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
		spark.Name = "MicrowaveSpark"
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
		self:_teleportPlayer(player, sitTarget.CFrame + Vector3.new(0, 1.8, 0), "CouchSit")
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
		self:_playTelevisionLoop(screen, "TVStaticSound", TV_SOUND_IDS.Static, 0.28, 1)
	elseif channelIndex == 2 then
		self:_playTelevisionLoop(screen, "TVTestTone", TV_SOUND_IDS.TestTone, 0.2, 1)
	else
		self:_startTelevisionWarning(tv, screen)
	end
end

function InteractionService:_televisionSecret(tv, screen, textLabel, player, state)
	state.Reacting = true
	self:_clearTelevisionSounds(tv)
	self.discoveryService:Unlock(player, Constants.Discoveries.AngeredTelevision.Id)

	textLabel.Text = ""
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 245)
	screen.Color = Color3.fromRGB(255, 255, 255)
	task.wait(0.15)
	screen.Color = Color3.fromRGB(6, 7, 9)
	self:_spawnTelevisionEye(tv, screen, player, TV_EYE_DURATION)
	task.wait(TV_EYE_DURATION)

	self:_clearTelevisionSounds(tv)
	self.resetService.RestoreInstance(tv)
	state.Reacting = false
end

function InteractionService:_wireTVSecretBook(bookPart)
	local prompt = getPrompt(bookPart)
	local roomId = bookPart:GetAttribute("RoomId") or "TVRoom"
	local pulled = false

	self:_connectPrompt(prompt, function(player)
		playControlPanelSound(bookPart, 0.44, 0.82)
		playSound(bookPart, "rbxasset://sounds/electronicpingshort.wav", 0.38, 1.4)
		task.delay(0.16, function()
			if bookPart and bookPart.Parent then
				playSound(bookPart, "rbxasset://sounds/impact_water.mp3", 0.24, 0.55)
			end
		end)

		if not pulled and bookPart:IsA("BasePart") then
			pulled = true
			local baseCFrame = bookPart:GetAttribute("BaseCFrame") or bookPart.CFrame
			tweenPart(bookPart, 0.2, {
				CFrame = baseCFrame * CFrame.new(0, 0, -0.42),
			}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		end

		if self.discoveryService.RevealSecretDoor then
			self.discoveryService:RevealSecretDoor(player, roomId, "A shelf clicks. The Library outline stops pretending.")
		end

		local granted = self.discoveryService:GrantSecretKey(player, roomId, "Library Key added to inventory.")
		if not granted then
			self.systemMessageRemote:FireClient(player, "The strange book has already given up its Library Key.")
		end

		self:_refreshSecretDoorsForPlayer(player)
	end)
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

function InteractionService:_spawnTelevisionEye(tv, screen, player, duration)
	local existingEye = tv:FindFirstChild("WatchingEye")
	if existingEye then
		existingEye:Destroy()
	end

	duration = duration or TV_EYE_DURATION
	local fadeDuration = math.min(TV_EYE_FADE_DURATION, duration)

	local model = Instance.new("Model")
	model.Name = "WatchingEye"
	model.Parent = tv
	CollectionService:AddTag(model, Constants.Tags.TemporaryObject)

	local eye = Instance.new("Part")
	eye.Name = "EyeWhite"
	eye.Anchored = true
	eye.CanCollide = false
	eye.CanQuery = false
	eye.CanTouch = false
	eye.CastShadow = false
	eye.Shape = Enum.PartType.Ball
	eye.Size = Vector3.new(3.45, 3.45, 0.12)
	eye.Color = Color3.fromRGB(255, 255, 245)
	eye.Material = Enum.Material.Neon
	eye.Parent = model
	CollectionService:AddTag(eye, Constants.Tags.TemporaryObject)

	local pupil = Instance.new("Part")
	pupil.Name = "EyePupil"
	pupil.Anchored = true
	pupil.CanCollide = false
	pupil.CanQuery = false
	pupil.CanTouch = false
	pupil.CastShadow = false
	pupil.Shape = Enum.PartType.Ball
	pupil.Size = Vector3.new(0.86, 0.86, 0.08)
	pupil.Color = Color3.fromRGB(12, 14, 18)
	pupil.Material = Enum.Material.SmoothPlastic
	pupil.Parent = model
	CollectionService:AddTag(pupil, Constants.Tags.TemporaryObject)

	local eyeCFrame = screen.CFrame * CFrame.new(0, 0, screen.Size.Z / 2 + 0.08)
	local maxPupilOffset = 1.08
	local startedAt = os.clock()

	task.spawn(function()
		while model.Parent do
			local elapsed = os.clock() - startedAt
			if elapsed >= duration then
				break
			end

			local rootPart = getRootPart(player)
			local targetPosition = if rootPart then rootPart.Position + Vector3.new(0, 1.35, 0) else eyeCFrame.Position
			local targetLocal = screen.CFrame:PointToObjectSpace(targetPosition)
			local targetDistance = math.max(math.abs(targetLocal.Z), 6)
			local pupilOffset = Vector2.new(
				math.clamp((targetLocal.X / targetDistance) * 1.9, -maxPupilOffset, maxPupilOffset),
				math.clamp((targetLocal.Y / targetDistance) * 1.9, -maxPupilOffset, maxPupilOffset)
			)
			if pupilOffset.Magnitude > maxPupilOffset then
				pupilOffset = pupilOffset.Unit * maxPupilOffset
			end

			local fadeStart = duration - fadeDuration
			local fadeAlpha = if elapsed > fadeStart then math.clamp((elapsed - fadeStart) / fadeDuration, 0, 1) else 0
			eye.Transparency = fadeAlpha
			pupil.Transparency = fadeAlpha
			eye.CFrame = eyeCFrame
			pupil.CFrame = eyeCFrame * CFrame.new(pupilOffset.X, pupilOffset.Y, 0.08)
			task.wait(0.08)
		end

		if model.Parent then
			model:Destroy()
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
		local isPrologueOpen =
			self.roomProgressService and self.roomProgressService:IsUntouchedPrologueActive(player)
		if isPrologueOpen and door:GetAttribute("LockedDuringPrologue") == true then
			self.systemMessageRemote:FireClient(player, door:GetAttribute("PrologueLockedMessage") or "That door is not awake yet.")
			return
		end

		if not self.exitUnlocked and not isPrologueOpen then
			self:_checkExitUnlock(player)
		end

		if not self.exitUnlocked and not isPrologueOpen then
			self.systemMessageRemote:FireClient(player, self.discoveryService:GetHallUnlockRequirementText(player))
			return
		end

		self:_teleportPlayer(player, door:GetAttribute("DestinationCFrame"), "ExitDoor")
		self.systemMessageRemote:FireClient(player, "The hallway smells like choices.")
	end, {
		PrologueSafeNavigation = true,
	})
end

function InteractionService:_unlockExitDoor(door)
	if not door or not door:IsA("BasePart") then
		return
	end

	if door:GetAttribute("InvisiblePassage") == true then
		door.CanCollide = false
		door.CanQuery = false
		door.CanTouch = false
		door.Transparency = 1
		local prompt = getPrompt(door)
		if prompt then
			prompt.Enabled = false
		end

		local textLabel = door:FindFirstChild("DoorText", true)
		if textLabel and textLabel:IsA("TextLabel") then
			textLabel.Text = ""
		end

		self:_persistResetBaseline(door)
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
		local isPrologueOpen =
			self.roomProgressService and self.roomProgressService:IsUntouchedPrologueActive(player)
		if isPrologueOpen and door:GetAttribute("LockedDuringPrologue") == true then
			self.systemMessageRemote:FireClient(player, door:GetAttribute("PrologueLockedMessage") or "That door is not awake yet.")
			return
		end

		local lockedMessage = door:GetAttribute("LockedMessage")
		if lockedMessage and not isPrologueOpen then
			self.systemMessageRemote:FireClient(player, lockedMessage)
			return
		end

			local roomId = door:GetAttribute("RoomId")
			if roomId and not isPrologueOpen and not self.discoveryService:IsRoomUnlocked(player, roomId) then
				self.systemMessageRemote:FireClient(player, self:_getRoomDoorRequirementText(player, roomId))
				return
			end

			local endGameComplete = false
			if door:GetAttribute("RequiresEndGameCompletion") == true and not isPrologueOpen then
				endGameComplete = self.discoveryService:GetDiscoveryCount(player) >= (Constants.TotalDiscoveries or 1)
					and not self.discoveryService:IsDevOverrideActive(player)
				if not endGameComplete then
					self.systemMessageRemote:FireClient(player, door:GetAttribute("EndGameLockedMessage") or "That door is waiting for the end.")
					playSound(door, "rbxasset://sounds/snap.wav", 0.45, 0.42)
					return
				end
			end

			if door:GetAttribute("OneWayTrapAfterHallwayEntry")
				and not isPrologueOpen
				and not endGameComplete
				and self.caveHallDoorLockedByUserId[player.UserId]
			then
				self.systemMessageRemote:FireClient(player, door:GetAttribute("OneWayLockedMessage") or "The entryway locked behind you.")
				playSound(door, "rbxasset://sounds/snap.wav", 0.45, 0.42)
				return
			end

			if door:GetAttribute("RequiresIdBadgeAfterUse")
				and not isPrologueOpen
				and self.caveHallDoorLockedByUserId[player.UserId]
				and not self.discoveryService:HasDiscovery(player, Constants.Discoveries.SleepingIdBadge.Id)
			then
				self.systemMessageRemote:FireClient(player, "The cave door locked itself again. It now wants an ID Badge from Sleeping Quarters.")
				playSound(door, "rbxasset://sounds/snap.wav", 0.45, 0.42)
				return
			end

			local destinationCFrame = door:GetAttribute("DestinationCFrame")
		if typeof(destinationCFrame) ~= "CFrame" then
			self.systemMessageRemote:FireClient(player, "This door forgot where it goes.")
			return
		end

		if not self:_canUseTeleport(player) then
			return
		end

		self:_teleportPlayer(player, destinationCFrame, "HallDoor")
		local travelSoundId = door:GetAttribute("TravelSoundId")
		if typeof(travelSoundId) == "string" and travelSoundId ~= "" then
			playSound(door, travelSoundId, 0.65, 0.42)
		end

		local unlockDiscoveryId = door:GetAttribute("UnlockDiscoveryId")
			if typeof(unlockDiscoveryId) == "string" and not isPrologueOpen then
				self.discoveryService:Unlock(player, unlockDiscoveryId)
			end

			if door:GetAttribute("RequiresIdBadgeAfterUse") and not isPrologueOpen then
				self.caveHallDoorLockedByUserId[player.UserId] = true
			end

			local travelMessage = door:GetAttribute("TravelMessage")
		if typeof(travelMessage) == "string" then
			self.systemMessageRemote:FireClient(player, travelMessage)
		end
	end, {
		PrologueSafeNavigation = true,
	})
end

function InteractionService:_snapshotRoomUnlockNotices(player)
	if not player or not player.Parent then
		return
	end

	local state = {}
	for roomId in pairs(ROOM_UNLOCK_NOTICES) do
		state[roomId] = self.discoveryService:IsRoomUnlocked(player, roomId) == true
	end
	self.roomUnlockNoticeByUserId[player.UserId] = state
end

function InteractionService:_findRoomDoor(roomId)
	for _, door in ipairs(CollectionService:GetTagged(Constants.Tags.HallDoor)) do
		if door:GetAttribute("RoomId") == roomId then
			return door
		end
	end

	return nil
end

function InteractionService:_checkRoomUnlockNotices(player)
	if not player or not player.Parent then
		return
	end

	local state = self.roomUnlockNoticeByUserId[player.UserId]
	if not state then
		state = {}
		self.roomUnlockNoticeByUserId[player.UserId] = state
	end

	for roomId, notice in pairs(ROOM_UNLOCK_NOTICES) do
		if not state[roomId] and self.discoveryService:IsRoomUnlocked(player, roomId) then
			state[roomId] = true
			if typeof(notice.Message) == "string" then
				self.systemMessageRemote:FireClient(player, notice.Message)
			end

			local door = self:_findRoomDoor(roomId)
			if typeof(notice.SoundId) == "string" then
				playSound(door or workspace, notice.SoundId, 0.65, 0.42)
			end
		end
	end
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
		if self.movementAuthorityService and self.movementAuthorityService.SetSnackFlight then
			self.movementAuthorityService:SetSnackFlight(player, true, {
				Duration = SNACK_FLIGHT_DURATION,
				CeilingY = SNACK_FLIGHT_CEILING_Y,
			})
		end
		self:_addImpulse(player, Vector3.new(0, SNACK_FLIGHT_INITIAL_BOOST, 0), "SnackFlight")

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
		if self.movementAuthorityService and self.movementAuthorityService.SetSnackFlight then
			self.movementAuthorityService:SetSnackFlight(player, false)
		end
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
			local horizontalForce = 68 + level * 28
			local lift = 7 + level * 6
			self:_applyImpulse(player, direction * horizontalForce + Vector3.new(0, lift, 0), "SnackWind")
			rootPart.AssemblyAngularVelocity += Vector3.new(0, 2 + level, 0)
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

function InteractionService:_applySnackWindStormToPlayer(player, level, duration)
	local humanoid = getHumanoid(player)
	local rootPart = getRootPart(player)
	if not humanoid or not rootPart then
		return
	end

	if humanoid:GetAttribute("SnackWindBaseWalkSpeed") == nil then
		humanoid:SetAttribute("SnackWindBaseWalkSpeed", humanoid.WalkSpeed)
		humanoid:SetAttribute("SnackWindBaseJumpPower", humanoid.JumpPower)
		humanoid:SetAttribute("SnackWindBaseJumpHeight", humanoid.JumpHeight)
	end

	local token = {}
	self.windStormTokensByHumanoid[humanoid] = token
	local walkFactor = math.clamp(1 - level * 0.18, 0.38, 0.82)
	local jumpFactor = math.clamp(1 - level * 0.14, 0.45, 0.86)
	humanoid.WalkSpeed = math.max(5, (humanoid:GetAttribute("SnackWindBaseWalkSpeed") or 16) * walkFactor)

	if humanoid.UseJumpPower then
		humanoid.JumpPower = math.max(18, (humanoid:GetAttribute("SnackWindBaseJumpPower") or 50) * jumpFactor)
	else
		humanoid.JumpHeight = math.max(2.6, (humanoid:GetAttribute("SnackWindBaseJumpHeight") or 7.2) * jumpFactor)
	end

	task.spawn(function()
		local endAt = os.clock() + duration
		while os.clock() < endAt and humanoid.Parent and self.windStormTokensByHumanoid[humanoid] == token do
			local currentRoot = getRootPart(player)
			if currentRoot then
				local direction = self:_getSnackWindDirection(currentRoot.Position)
				self:_addImpulse(player, direction * (5 + level * 4) + Vector3.new(0, 2 + level * 0.9, 0), "SnackWindStorm")
			end
			task.wait(0.28)
		end
	end)

	task.delay(duration, function()
		if self.windStormTokensByHumanoid[humanoid] ~= token or not humanoid.Parent then
			return
		end

		humanoid.WalkSpeed = humanoid:GetAttribute("SnackWindBaseWalkSpeed") or 16
		if humanoid.UseJumpPower then
			humanoid.JumpPower = humanoid:GetAttribute("SnackWindBaseJumpPower") or 50
		else
			humanoid.JumpHeight = humanoid:GetAttribute("SnackWindBaseJumpHeight") or 7.2
		end
		self.windStormTokensByHumanoid[humanoid] = nil
	end)
end

function InteractionService:_spawnSnackWindStreak(origin, direction, level, index)
	local cross = direction:Cross(Vector3.yAxis)
	if cross.Magnitude < 0.1 then
		cross = Vector3.xAxis
	else
		cross = cross.Unit
	end

	local streak = Instance.new("Part")
	streak.Name = "SnackWindStreak"
	streak.Anchored = true
	streak.CanCollide = false
	streak.CastShadow = false
	streak.Material = Enum.Material.Neon
	streak.Color = level >= 3 and Color3.fromRGB(214, 255, 255) or Color3.fromRGB(195, 236, 255)
	streak.Transparency = math.max(0.22, 0.5 - level * 0.08)
	streak.Size = Vector3.new(0.08 + level * 0.02, 0.08 + level * 0.02, 5 + level * 1.3)
	streak.CFrame = CFrame.lookAt(origin, origin + direction)
		* CFrame.new(
			cross * ((index % 5 - 2) * (1.4 + level * 0.2))
				+ Vector3.new(0, ((index % 4) - 1.5) * 0.6, 0)
		)
	streak.Parent = workspace
	CollectionService:AddTag(streak, Constants.Tags.TemporaryObject)

	tweenPart(streak, 0.42 + level * 0.04, {
		CFrame = streak.CFrame + direction * (14 + level * 5),
		Transparency = 1,
	}, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	Debris:AddItem(streak, 0.8)
end

function InteractionService:_spawnSnackWindDebris(origin, direction, level, index)
	local debrisPart = Instance.new("Part")
	debrisPart.Name = "SnackWindDebris"
	debrisPart.Anchored = false
	debrisPart.CanCollide = false
	debrisPart.Material = index % 3 == 0 and Enum.Material.Plastic or Enum.Material.Wood
	debrisPart.Color = ({
		Color3.fromRGB(255, 225, 110),
		Color3.fromRGB(255, 134, 96),
		Color3.fromRGB(126, 222, 255),
		Color3.fromRGB(191, 255, 153),
	})[((index - 1) % 4) + 1]
	local scale = 0.35 + level * 0.08 + (index % 3) * 0.04
	debrisPart.Size = Vector3.new(scale * 1.5, scale * 0.16, scale)
	debrisPart.CFrame = CFrame.new(origin + Vector3.new((index % 5 - 2) * 0.7, -1 + (index % 4) * 0.25, (index % 3 - 1) * 0.8))
		* CFrame.Angles(math.rad(index * 21), math.rad(index * 39), math.rad(index * 17))
	debrisPart.Parent = workspace
	CollectionService:AddTag(debrisPart, Constants.Tags.TemporaryObject)
	debrisPart.AssemblyLinearVelocity = direction * (42 + level * 26) + Vector3.new(0, 12 + level * 5, 0)
	debrisPart.AssemblyAngularVelocity = Vector3.new(8 + level * 3, -13 - index, 9 + index)
	Debris:AddItem(debrisPart, 5 + level)
end

function InteractionService:_spawnSnackWindEffects(button, level)
	local fan = button and (button:FindFirstAncestor("SnackCeilingFan") or button)
	local hub = fan and fan:FindFirstChild("FanHub", true)
	local origin = if hub and hub:IsA("BasePart") then hub.Position else button.Position + Vector3.new(0, 3, 0)
	local snackRoom = Constants.GetRoom("SnackLab")
	local zone = snackRoom and snackRoom.Zone
	local center = zone and (zone.Min + zone.Max) * 0.5 or origin
	local direction = Vector3.new(center.X - origin.X, 0, center.Z - origin.Z)
	if direction.Magnitude < 1 then
		direction = Vector3.new(1, 0, 0)
	else
		direction = direction.Unit
	end

	local streakCount = 8 + level * 5
	for index = 1, streakCount do
		task.delay(index * 0.025, function()
			self:_spawnSnackWindStreak(origin, direction, level, index)
		end)
	end

	local debrisCount = level == 1 and 3 or (level == 2 and 6 or 10)
	for index = 1, debrisCount do
		task.delay(index * 0.07, function()
			self:_spawnSnackWindDebris(origin, direction, level, index)
		end)
	end
end

function InteractionService:_triggerSnackSuperWind(button, level)
	playSound(button, "rbxasset://sounds/electronicpingshort.wav", 0.62, level >= 3 and 1.8 or 1.35)
	local stormDuration = 2.6 + level * 1.15
	self.systemMessageRemote:FireAllClients(("The Gravity Apology Fan is now at wind setting %d. Walking is optional research."):format(level))

	for _, player in ipairs(self:_getPlayersInRoom("SnackLab")) do
		self:_applySnackWindStormToPlayer(player, level, stormDuration)
	end

	self:_spawnSnackWindEffects(button, level)

	for gust = 1, SNACK_SUPER_WIND_GUSTS do
		task.delay((gust - 1) * 0.36, function()
			self:_spawnSnackWindEffects(button, level)
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
			self:_spawnSnackWindEffects(button, state.Level)
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

function InteractionService:_recordBloxyColaSip(player)
	if self.bunkerEnergyService and self.bunkerEnergyService.RecordEnergyItemUsed then
		self.bunkerEnergyService:RecordEnergyItemUsed(player, "Cola", Constants.BunkerEnergy.ColaEnergyRestore or 0.24)
	end
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
		self:_recordBloxyColaSip(player)
		self.systemMessageRemote:FireClient(player, "The fridge Bloxy Cola restores a little energy. The room signal brightens like it was your idea.")
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
		self:_attachEnergyReservePrompt(toast, toastModel, {
			PromptName = "ToastPocketPrompt",
			ActionText = "Pocket",
			ObjectText = "Toast",
			Kind = "Toast",
			Name = "Pocketed Toast",
			RestoreAmount = 0.16,
			Color = toast.Color,
			GrantMessage = "Toast pocketed. Warm carbs count as field equipment.",
			UseMessage = "The toast helps a little. Nearby lights react to the crumbs.",
			ReclaimKey = "toast_pocketed",
			ReclaimMessage = "The Snack Lab accepts the missing toast without making eye contact.",
		})
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
			self:_applyImpulse(player, Vector3.new(0, 92, 0) + rootPart.CFrame.LookVector * 16, "SnackSinkGeyser")
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

function InteractionService:_createMixerWeatherCloud(startCFrame)
	local cloudModel = Instance.new("Model")
	cloudModel.Name = "MixerWeatherCloud"
	cloudModel.Parent = workspace
	CollectionService:AddTag(cloudModel, Constants.Tags.TemporaryObject)

	local offsets = {
		Vector3.new(0, 0, 0),
		Vector3.new(-1.35, -0.08, 0.15),
		Vector3.new(1.22, -0.04, 0.05),
		Vector3.new(-0.55, 0.52, -0.45),
		Vector3.new(0.68, 0.43, -0.38),
		Vector3.new(-0.2, 0.3, 0.72),
		Vector3.new(1.85, 0.02, -0.36),
		Vector3.new(-1.92, -0.02, -0.18),
		Vector3.new(0.18, 0.74, 0.28),
	}

	for index, offset in ipairs(offsets) do
		local puff = Instance.new("Part")
		puff.Name = "WeatherCloudPuff"
		puff.Anchored = true
		puff.CanCollide = false
		puff.CastShadow = false
		puff.Shape = Enum.PartType.Ball
		local size = 1.5 + (index % 4) * 0.28
		puff.Size = Vector3.new(size * 1.45, size * 0.85, size)
		puff.Color = index % 3 == 0 and Color3.fromRGB(194, 207, 222) or Color3.fromRGB(236, 245, 255)
		puff.Material = Enum.Material.SmoothPlastic
		puff.Transparency = 0.08
		puff.CFrame = startCFrame * CFrame.new(offset)
		puff.Parent = cloudModel
		CollectionService:AddTag(puff, Constants.Tags.TemporaryObject)

		if index == 1 then
			cloudModel.PrimaryPart = puff
		end
	end

	return cloudModel
end

function InteractionService:_spawnMixerRainDrop(position, index)
	local drop = Instance.new("Part")
	drop.Name = "MixerRainDrop"
	drop.Anchored = false
	drop.CanCollide = false
	drop.CastShadow = false
	drop.Material = Enum.Material.Neon
	drop.Color = index % 4 == 0 and Color3.fromRGB(184, 255, 255) or Color3.fromRGB(88, 190, 255)
	drop.Transparency = 0.08
	drop.Size = Vector3.new(0.09, 0.62 + (index % 3) * 0.12, 0.09)
	drop.CFrame = CFrame.new(position) * CFrame.Angles(math.rad(8), 0, math.rad((index % 2 == 0 and 1 or -1) * 8))
	drop.Parent = workspace
	CollectionService:AddTag(drop, Constants.Tags.TemporaryObject)
	drop.AssemblyLinearVelocity = Vector3.new((index % 5 - 2) * 0.8, -42 - (index % 4) * 5, (index % 3 - 1) * 0.8)
	Debris:AddItem(drop, 1.45)
end

function InteractionService:_startMixerPersonalWeather(player, bowl)
	local rootPart = getRootPart(player)
	local baseCFrame = if rootPart then CFrame.new(rootPart.Position + Vector3.new(0, 7.2, 0)) else bowl.CFrame + Vector3.new(0, 5, 0)
	local cloudModel = self:_createMixerWeatherCloud(baseCFrame)
	Debris:AddItem(cloudModel, SNACK_MIXER_WEATHER_DURATION + 3)

	local rainIndex = 0
	task.spawn(function()
		local startAt = os.clock()
		while cloudModel.Parent and os.clock() - startAt < SNACK_MIXER_WEATHER_DURATION do
			local currentRoot = getRootPart(player)
			local targetPosition
			if currentRoot then
				targetPosition = currentRoot.Position + Vector3.new(0, 7.2, 0)
			else
				targetPosition = bowl.Position + Vector3.new(0, 5, 0)
			end

			local wobble = Vector3.new(
				math.sin(os.clock() * 2.2) * 0.45,
				math.sin(os.clock() * 1.4) * 0.16,
				math.cos(os.clock() * 1.8) * 0.45
			)
			cloudModel:PivotTo(CFrame.new(targetPosition + wobble))

			for dropCount = 1, 6 do
				rainIndex += 1
				local offset = Vector3.new(
					((rainIndex + dropCount) % 7 - 3) * 0.38,
					-1.25,
					((rainIndex + dropCount * 2) % 5 - 2) * 0.42
				)
				self:_spawnMixerRainDrop(targetPosition + offset, rainIndex)
			end

			if rainIndex % 30 == 0 then
				playSound(cloudModel.PrimaryPart or bowl, "rbxasset://sounds/electronicpingshort.wav", 0.18, 0.45)
			end

			task.wait(0.18)
		end

		if cloudModel.Parent then
			for _, descendant in ipairs(cloudModel:GetDescendants()) do
				if descendant:IsA("BasePart") then
					tweenPart(descendant, 1.2, {
						Transparency = 1,
					}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				end
			end
			Debris:AddItem(cloudModel, 1.4)
		end
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
			if index <= 4 then
				local previewPuff = Instance.new("Part")
				previewPuff.Name = "MixerCloudPreview"
				previewPuff.Anchored = true
				previewPuff.CanCollide = false
				previewPuff.CastShadow = false
				previewPuff.Shape = Enum.PartType.Ball
				previewPuff.Size = Vector3.new(1.2, 0.85, 1.2) * (0.85 + index * 0.1)
				previewPuff.Color = Color3.fromRGB(238, 245, 255)
				previewPuff.Material = Enum.Material.SmoothPlastic
				previewPuff.Transparency = 0.1
				previewPuff.CFrame = bowl.CFrame + Vector3.new(math.sin(index) * 1.4, 1.5 + index * 0.24, math.cos(index) * 1.4)
				previewPuff.Parent = workspace
				CollectionService:AddTag(previewPuff, Constants.Tags.TemporaryObject)
				tweenPart(previewPuff, 0.9, {
					CFrame = previewPuff.CFrame + Vector3.new(0, 1.3, 0),
					Transparency = 1,
				}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				Debris:AddItem(previewPuff, 1.1)
			end

			task.wait(0.12)
		end

		self:_startMixerPersonalWeather(player, bowl)
		self.systemMessageRemote:FireClient(player, "The mixer made personal weather. It follows you now.")

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

function InteractionService:_wireSnackPopcornMachine(button)
	local prompt = getPrompt(button)
	local machine = button:FindFirstAncestor("SnackLabPopcornMachine") or button.Parent

	self.snackPopcornState[button] = self.snackPopcornState[button] or {
		Reacting = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.snackPopcornState[button]
		if not state or state.Reacting or not button:IsA("BasePart") then
			return
		end

		state.Reacting = true
		self.discoveryService:Unlock(player, Constants.Discoveries.SnackPopcorn.Id)
		self.systemMessageRemote:FireClient(player, "The popcorn machine makes a persuasive argument for snack weather.")
		playSound(button, "rbxasset://sounds/button.wav", 0.45, 1.3)

		local baseCFrame = button:GetAttribute("BaseCFrame") or button.CFrame
		tweenPart(button, 0.08, {
			CFrame = baseCFrame * CFrame.new(0, -0.08, 0),
			Color = Color3.fromRGB(255, 232, 92),
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		for popIndex = 1, 34 do
			task.delay((popIndex - 1) * 0.025, function()
				if not machine or not machine.Parent then
					return
				end

				local kernel = Instance.new("Part")
				kernel.Name = "SnackPopcornPoppedKernel"
				kernel.Anchored = false
				kernel.CanCollide = true
				kernel.Shape = Enum.PartType.Ball
				kernel.Size = Vector3.new(0.22, 0.18, 0.22) * (1 + (popIndex % 3) * 0.18)
				kernel.Color = Color3.fromRGB(255, 238, 156)
				kernel.Material = Enum.Material.SmoothPlastic
				kernel.CFrame = button.CFrame * CFrame.new(
					math.sin(popIndex) * 0.55,
					2.6 + (popIndex % 6) * 0.08,
					0.7 + math.cos(popIndex * 0.7) * 0.45
				)
				kernel.Parent = workspace
					CollectionService:AddTag(kernel, Constants.Tags.TemporaryObject)
					self:_attachEnergyReservePrompt(kernel, kernel, {
						PromptName = "PopcornPocketPrompt",
						ActionText = "Pocket",
						ObjectText = "Popcorn",
						Kind = "Popcorn",
						Name = "Pocketed Popcorn",
						RestoreAmount = Constants.BunkerEnergy.PopcornEnergyRestore or 0.12,
						Color = kernel.Color,
						GrantMessage = "Pocketed popcorn for later. Emergency cuisine has entered the inventory.",
						UseMessage = "The popcorn helps a little. The floor signal reacts to every crumb.",
						ReclaimKey = "popcorn_pocketed",
						ReclaimMessage = "The Snack Lab absorbs a kernel-sized absence.",
					})
					kernel.AssemblyLinearVelocity = Vector3.new(
						math.sin(popIndex * 1.7) * 8,
						16 + (popIndex % 5) * 2.5,
					math.cos(popIndex * 1.2) * 8
				)
					kernel.AssemblyAngularVelocity = Vector3.new(popIndex % 5, popIndex % 7, popIndex % 3) * 2.3
					self:_scheduleBunkerReclaim(kernel, {
						Delay = 38 + (popIndex % 10) * 1.5,
						Key = "snack_popcorn",
						Message = "Tiny kernels vanish into floor seams that were not there a second ago.",
						SinkDistance = 1.6,
						Duration = 0.8,
					})
					Debris:AddItem(kernel, 70)
				end)
			end

		task.delay(0.45, function()
			if button.Parent then
				tweenPart(button, 0.16, {
					CFrame = baseCFrame,
					Color = Color3.fromRGB(119, 255, 203),
				}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			end
		end)

		task.delay(1.6, function()
			state.Reacting = false
		end)
	end)
end

function InteractionService:_wireContributorDuckStand(stand)
	local prompt = getPrompt(stand)

	self:_connectPrompt(prompt, function(player)
		playSound(stand, "rbxasset://sounds/electronicpingshort.wav", 0.35, 1.15)
		self.systemMessageRemote:FireClient(
			player,
			("Duck Founder naming is staged here at %d R$. Product ID and moderated name entry still need to be configured before charging."):format(Constants.NoTouch.DuckFounderRobux or 80000)
		)
	end)
end

function InteractionService:_wireVictoryBrick(brick)
	local prompt = getPrompt(brick)

	self:_connectPrompt(prompt, function(player)
		local slotIndex = brick:GetAttribute("VictoryBrickSlotIndex")
		local displayName = brick:GetAttribute("VictoryBrickDisplayName")
		local tier = brick:GetAttribute("VictoryBrickTier")
		playSound(brick, "rbxasset://sounds/electronicpingshort.wav", 0.32, 1.18)

		if typeof(displayName) == "string" and displayName ~= "" then
			local isDeluxe = string.lower(tostring(tier or "")) == "deluxe"
			self.victoryBrickReadRemote:FireClient(player, {
				DisplayName = displayName,
				Tier = if isDeluxe then "Deluxe" else "Standard",
				SlotIndex = slotIndex,
				ClaimedAt = brick:GetAttribute("VictoryBrickClaimedAt"),
				UpdatedAt = brick:GetAttribute("VictoryBrickUpdatedAt"),
				DiscoveryCount = brick:GetAttribute("VictoryBrickDiscoveryCount"),
				TotalDiscoveries = brick:GetAttribute("VictoryBrickTotalDiscoveries"),
				TimePlayedSeconds = brick:GetAttribute("VictoryBrickTimePlayedSeconds"),
				BuildVersion = brick:GetAttribute("VictoryBrickBuildVersion"),
				Message = if isDeluxe
					then "This deluxe victory brick was claimed after the bunker was completed."
					else "This victory brick was signed after the bunker was completed.",
			})
			if string.lower(tostring(tier or "")) == "deluxe" then
				self.systemMessageRemote:FireClient(player, ("%s claimed this deluxe victory brick."):format(displayName))
			else
				self.systemMessageRemote:FireClient(player, ("%s completed the bunker and signed this victory brick."):format(displayName))
			end
			return
		end

		if not self.victoryBrickService then
			self.systemMessageRemote:FireClient(player, "Deluxe brick spot choice is not available in this server yet.")
			return
		end

		local ok, message = self.victoryBrickService:PromptDeluxePurchase(player, slotIndex)
		if not message then
			message = if ok then "Deluxe brick spot selected." else "Deluxe brick spot could not be selected."
		end
		self.systemMessageRemote:FireClient(player, message)
	end, {
		PrologueSafeNavigation = true,
		DoNotRecordInteraction = true,
	})
end

function InteractionService:_wireVictoryBrickStand(stand)
	local prompt = getPrompt(stand)

	self:_connectPrompt(prompt, function(player)
		local completionDiscoveryId = Constants.VictoryWalkway and Constants.VictoryWalkway.CompletionDiscoveryId
		local complete = if typeof(completionDiscoveryId) == "string" and completionDiscoveryId ~= ""
			then self.discoveryService:HasDiscovery(player, completionDiscoveryId)
			else self.discoveryService:GetDiscoveryCount(player) >= (Constants.TotalDiscoveries or 1)
		local eligible = complete and not self.discoveryService:IsDevOverrideActive(player)
		playSound(stand, "rbxasset://sounds/button.wav", 0.35, eligible and 1.15 or 0.72)

		if eligible and self.victoryBrickService then
			local ok, message = self.victoryBrickService:SignStandard(player)
			if not message then
				message = if ok then "Victory brick signed." else "Victory brick signing needs a little more progress."
			end
			self.systemMessageRemote:FireClient(player, message)
		elseif eligible then
			self.systemMessageRemote:FireClient(player, "Victory brick eligibility confirmed, but the walkway registry is not available in this server.")
		else
			self.systemMessageRemote:FireClient(player, "Victory bricks unlock after finishing the game on normal progress.")
		end
	end, {
		PrologueSafeNavigation = true,
		DoNotRecordInteraction = true,
	})
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
						self:_attachLooseFruitEatPrompt(primary, clone)
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

					self:_scheduleBunkerReclaim(clone, {
						Delay = 105 + wave * 5 + random:NextNumber(0, 18),
						Key = "snack_fruit",
						Message = "The Snack Lab floor takes a quiet interest in fruit that landed where fruit should not.",
						SinkDistance = 2.4,
					})
					Debris:AddItem(clone, 210)
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
	local sourcePosition = source and source:IsA("BasePart") and source.Position or Vector3.new(
		self.islandResourceRandom:NextNumber(-36, 36),
		0.22,
		self.islandResourceRandom:NextNumber(180, 210)
	)
	local origin = if source
		then Vector3.new(24, 0.22, math.clamp(sourcePosition.Z - 1.5, 137, 148))
		else sourcePosition
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

	local travel = if source then Vector3.new(-20, 0, 14) else Vector3.new(self.islandResourceRandom:NextNumber(-18, 18), 0, self.islandResourceRandom:NextNumber(-18, 2))
	local startCFrame = CFrame.new(origin + Vector3.new(5, 0, -8), origin + travel)
	local fin = makeFinPart("WarningFin", Vector3.new(2.4, 3.6, 0.75), startCFrame * CFrame.Angles(0, 0, math.rad(-8)), Color3.fromRGB(47, 61, 73), Enum.Material.SmoothPlastic, "WedgePart")
	local wakeA = makeFinPart("WakeA", Vector3.new(4.6, 0.16, 0.5), startCFrame * CFrame.new(-1.8, -1.0, 0.55), Color3.fromRGB(180, 242, 255), Enum.Material.Neon)
	local wakeB = makeFinPart("WakeB", Vector3.new(4.6, 0.16, 0.5), startCFrame * CFrame.new(-1.8, -1.0, -0.55), Color3.fromRGB(180, 242, 255), Enum.Material.Neon)
	wakeA.Transparency = 0.2
	wakeB.Transparency = 0.2

	if source then
		playSound(source, "rbxasset://sounds/electronicpingshort.wav", 0.5, 0.36)
	end
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

	local islandCenter = Vector3.new(0, 2.0, 150)
	local attackDirection = rootPart and (rootPart.Position - islandCenter) or Vector3.new(1, 0, -0.25)
	attackDirection = Vector3.new(attackDirection.X, 0, attackDirection.Z)
	if attackDirection.Magnitude < 1 then
		attackDirection = Vector3.new(1, 0, -0.25)
	end
	attackDirection = attackDirection.Unit
	local attackPoint = islandCenter + attackDirection * 28
	local targetCFrame = CFrame.new(attackPoint, islandCenter) * CFrame.Angles(0, math.rad(90), 0)
	local baseCFrame = targetCFrame * CFrame.new(0, -6.2, 14)
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
				tweenPart(part, 0.72, {
					CFrame = targetCFrame * baseCFrame:ToObjectSpace(part.CFrame),
				}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end
	end

		task.delay(0.82, function()
			if upperMouth.Parent and lowerMouth.Parent then
				tweenPart(upperMouth, 0.22, { CFrame = upperMouth.CFrame * CFrame.Angles(math.rad(-18), 0, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				tweenPart(lowerMouth, 0.22, { CFrame = lowerMouth.CFrame * CFrame.Angles(math.rad(16), 0, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
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
		self:_applyImpulse(player, pushDirection * 88 + Vector3.new(0, 38, 0), "IslandSharkAttack")
			task.delay(0.78, function()
				if rootPart.Parent then
					self:_teleportPlayer(player, destination, "IslandSharkAttack")
					self:_applyImpulse(player, Vector3.new(0, 18, 0), "IslandSharkRecovery")
			end
		end)
	end

		task.delay(4.8, function()
			for _, part in ipairs(sharkModel:GetChildren()) do
				if part:IsA("BasePart") then
					tweenPart(part, 0.85, { Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				end
			end
		end)
		Debris:AddItem(sharkModel, 6.2)
end

function InteractionService:_wireIslandExit(exitGate)
	local prompt = getPrompt(exitGate)
	local exitMode = exitGate:GetAttribute("ExitMode") or "Ocean"

	local function returnToHallway(player)
		if not player or not player.Parent then
			return
		end

		if not self:_canUseTeleport(player) then
			return
		end

		self.islandExitWarningsByUserId[player.UserId] = nil
		local destinationCFrame = exitGate:GetAttribute("DestinationCFrame") or Constants.Hallway.SpawnCFrame
		self:_teleportPlayer(player, destinationCFrame, "IslandReturn")
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
		self:_connectPrompt(prompt, returnToHallway, {
			PrologueSafeNavigation = true,
		})
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
		Used = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.islandShovelState[shovel]
		if not state or state.Reacting then
			return
		end
		if state.Used then
			self.systemMessageRemote:FireClient(player, "The shovel has already retired into several smaller shovel opinions.")
			playSound(shovel, "rbxasset://sounds/snap.wav", 0.28, 0.5)
			return
		end

		state.Reacting = true
		state.Used = true
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

			local shovelModel = shovel:IsA("BasePart") and shovel:FindFirstAncestor("IslandShovel")
			if shovelModel then
				setPromptEnabled(shovelModel, false)
				for index, part in ipairs(shovelModel:GetDescendants()) do
					if part:IsA("BasePart") then
						local baseCFrame = part:GetAttribute("BaseCFrame") or part.CFrame
						part.CanCollide = true
						tweenPart(part, 0.42, {
							CFrame = baseCFrame
								* CFrame.new((index % 3 - 1) * 0.55, -0.35 - (index % 2) * 0.08, (index % 4 - 1.5) * 0.4)
								* CFrame.Angles(math.rad(index * 17), math.rad(index * 31), math.rad(index * 13)),
							Color = if part.Material == Enum.Material.Wood then Color3.fromRGB(104, 61, 35) else Color3.fromRGB(154, 160, 164),
						}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
					end
				end
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
		self:_recordBloxyColaSip(player)

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

		self.systemMessageRemote:FireClient(player, "The island Bloxy Cola restores a little energy and makes the correct soda noise.")
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
				self:_teleportPlayer(player, Constants.GetRoomSpawnCFrame("SpaceStation"), "IslandSpaceLadder")
			end
			task.delay(1, function()
				state.TransportingByUserId[player.UserId] = nil
			end)
		end)
		end)
	end

function InteractionService:_isIslandOccupied()
	for _, player in ipairs(Players:GetPlayers()) do
		if self.roomProgressService and self.roomProgressService:GetRoomForPlayer(player) == "Island" then
			return true
		end
	end

	return false
end

function InteractionService:_isPickupVisible(part)
	if not part or not part:IsA("BasePart") then
		return false
	end

	local prompt = getPrompt(part)
	return part.Transparency < 0.95 and (not prompt or prompt.Enabled)
end

function InteractionService:_setIslandPickupVisible(part, visible, cframe)
	if not part or not part:IsA("BasePart") then
		return
	end

	if cframe then
		part.CFrame = cframe
	end
	part.Transparency = visible and 0 or 1
	part.CanCollide = visible
	setPromptEnabled(part, visible)
end

function InteractionService:_getRandomIslandWoodCFrame()
	local points = {
		{ X = -17.2, Z = -7.6 },
		{ X = 18.4, Z = -8.7 },
		{ X = -14.8, Z = 14.8 },
		{ X = 15.5, Z = 13.6 },
		{ X = 1.5, Z = 18.6 },
		{ X = -6.4, Z = -10.2 },
		{ X = 8.6, Z = 19.8 },
	}
	local choice = points[self.islandResourceRandom:NextInteger(1, #points)]
	return CFrame.new(choice.X, 1.0, 150 + choice.Z)
		* CFrame.Angles(0, math.rad(self.islandResourceRandom:NextNumber(0, 360)), math.rad(self.islandResourceRandom:NextNumber(-8, 8)))
end

function InteractionService:_getRandomIslandRockCFrame()
	local points = {
		{ X = -19.0, Z = 4.2 },
		{ X = 18.5, Z = 2.5 },
		{ X = -8.5, Z = 18.7 },
		{ X = 10.8, Z = 17.8 },
		{ X = 3.2, Z = -9.8 },
	}
	local choice = points[self.islandResourceRandom:NextInteger(1, #points)]
	return CFrame.new(choice.X, 1.03, 150 + choice.Z)
		* CFrame.Angles(0, math.rad(self.islandResourceRandom:NextNumber(0, 360)), math.rad(self.islandResourceRandom:NextNumber(-12, 12)))
end

function InteractionService:_respawnIslandWoodIfNeeded()
	local visibleCount = 0
	local candidates = {}

	for _, wood in ipairs(CollectionService:GetTagged(Constants.Tags.IslandScrapWood)) do
		if wood:IsA("BasePart") then
			if self:_isPickupVisible(wood) then
				visibleCount += 1
			else
				table.insert(candidates, wood)
			end
		end
	end

	if visibleCount >= 5 or #candidates == 0 then
		return false
	end

	local wood = candidates[self.islandResourceRandom:NextInteger(1, #candidates)]
	local state = self.islandScrapWoodState[wood]
	if state then
		state.Collected = false
		state.Reacting = false
	end
	self:_setIslandPickupVisible(wood, true, self:_getRandomIslandWoodCFrame())
	return true
end

function InteractionService:_respawnIslandRockIfNeeded()
	local visibleRespawnRock = false
	local candidates = {}

	for _, rock in ipairs(CollectionService:GetTagged(Constants.Tags.IslandRock)) do
		if rock:IsA("BasePart") and rock:GetAttribute("RespawnOnly") == true then
			if self:_isPickupVisible(rock) then
				visibleRespawnRock = true
			else
				table.insert(candidates, rock)
			end
		end
	end

	if visibleRespawnRock or #candidates == 0 then
		return false
	end

	local rock = candidates[self.islandResourceRandom:NextInteger(1, #candidates)]
	local state = self.islandRockState[rock]
	if state then
		state.Collected = false
		state.Reacting = false
	end
	self:_setIslandPickupVisible(rock, true, self:_getRandomIslandRockCFrame())
	return true
end

function InteractionService:_getPocketItemCount(player, kind, fallbackCounts)
	local toolCount = 0
	if self.bunkerEnergyService and self.bunkerEnergyService.GetPocketItemCount then
		toolCount = self.bunkerEnergyService:GetPocketItemCount(player, kind)
	end

	local fallbackCount = 0
	if fallbackCounts and player then
		fallbackCount = fallbackCounts[player.UserId] or 0
	end

	return math.max(toolCount, fallbackCount)
end

function InteractionService:_grantPocketItem(player, options)
	if not self.bunkerEnergyService or not self.bunkerEnergyService.GrantPocketItemTool then
		return false, "Your pockets are not accepting supplies right now."
	end

	return self.bunkerEnergyService:GrantPocketItemTool(player, options)
end

function InteractionService:_consumePocketItem(player, kind, fallbackCounts)
	if self.bunkerEnergyService and self.bunkerEnergyService.ConsumePocketItem then
		if self.bunkerEnergyService:ConsumePocketItem(player, kind, 1) then
			if fallbackCounts and player then
				fallbackCounts[player.UserId] = math.max(0, (fallbackCounts[player.UserId] or 0) - 1)
			end
			return true
		end
	end

	if fallbackCounts and player and (fallbackCounts[player.UserId] or 0) > 0 then
		fallbackCounts[player.UserId] -= 1
		return true
	end

	return false
end

function InteractionService:_spawnIslandResourceWave()
	local wave = Instance.new("Part")
	wave.Name = "IslandRespawnWave"
	wave.Anchored = true
	wave.CanCollide = false
	wave.Material = Enum.Material.Glass
	wave.Color = Color3.fromRGB(122, 220, 255)
	wave.Transparency = 0.44
	wave.Size = Vector3.new(44, 0.08, 5.8)
	wave.CFrame = CFrame.new(0, 1.12, 134)
	wave.Parent = workspace
	CollectionService:AddTag(wave, Constants.Tags.TemporaryObject)

	local wetSand = Instance.new("Part")
	wetSand.Name = "IslandWetSandFade"
	wetSand.Anchored = true
	wetSand.CanCollide = false
	wetSand.Material = Enum.Material.SmoothPlastic
	wetSand.Color = Color3.fromRGB(176, 178, 148)
	wetSand.Transparency = 0.62
	wetSand.Size = Vector3.new(35, 0.05, 23)
	wetSand.CFrame = CFrame.new(0, 1.075, 154)
	wetSand.Parent = workspace
	CollectionService:AddTag(wetSand, Constants.Tags.TemporaryObject)

	tweenPart(wave, 4.2, {
		CFrame = CFrame.new(0, 1.14, 174),
		Transparency = 0.78,
	}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	tweenPart(wetSand, 5.2, {
		Transparency = 1,
	}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	Debris:AddItem(wave, 4.8)
	Debris:AddItem(wetSand, 5.6)

	task.delay(1.2, function()
		self:_respawnIslandWoodIfNeeded()
		self:_respawnIslandRockIfNeeded()
	end)
end

function InteractionService:_startIslandAmbientResources()
	if self.islandResourceLoopStarted then
		return
	end

	self.islandResourceLoopStarted = true
	task.spawn(function()
		while true do
			task.wait(60)
			if self:_isIslandOccupied() then
				self:_spawnIslandResourceWave()
			end
		end
	end)

	task.spawn(function()
		while true do
			task.wait(self.islandResourceRandom:NextNumber(24, 52))
			if self:_isIslandOccupied() then
				self:_spawnIslandSharkFin(nil)
			end
		end
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
		local ok, message = self:_grantPocketItem(player, {
			Kind = "IslandWood",
			Name = "Driftwood",
			ToolTip = "Carry to the island rock ring to feed the fire.",
			Color = wood.Color,
			GrantMessage = "Driftwood pocketed. The fire ring looks ready.",
		})
		if not ok then
			self.systemMessageRemote:FireClient(player, message or "Your pockets are full. The driftwood stays where the tide left it.")
			playSound(wood, "rbxasset://sounds/snap.wav", 0.28, 0.55)
			task.wait(0.15)
			state.Reacting = false
			return
		end

		state.Collected = true
		self.islandWoodCountByUserId[player.UserId] = self:_getPocketItemCount(player, "IslandWood", self.islandWoodCountByUserId)
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
		self.systemMessageRemote:FireClient(player, ("%s Driftwood carried: %d."):format(message or "Driftwood pocketed.", self.islandWoodCountByUserId[player.UserId]))
		task.wait(0.15)
		state.Reacting = false
	end)
end

function InteractionService:_wireIslandRock(rock)
	local prompt = getPrompt(rock)

	self.islandRockState[rock] = self.islandRockState[rock] or {
		Reacting = false,
		Collected = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.islandRockState[rock]
		if not state or state.Reacting or state.Collected then
			return
		end

		state.Reacting = true
		local ok, message = self:_grantPocketItem(player, {
			Kind = "IslandRock",
			Name = "Beach Rock",
			ToolTip = "Useful for pressure plates that want proof of weight.",
			Color = rock.Color,
			GrantMessage = "Beach rock pocketed. Your inventory has chosen responsibility.",
		})
		if not ok then
			self.systemMessageRemote:FireClient(player, message or "Your pockets are full. The rock refuses to become a lifestyle.")
			playSound(rock, "rbxasset://sounds/snap.wav", 0.28, 0.55)
			task.wait(0.15)
			state.Reacting = false
			return
		end

		state.Collected = true
		self.islandRockCountByUserId[player.UserId] = self:_getPocketItemCount(player, "IslandRock", self.islandRockCountByUserId)
		self.discoveryService:Unlock(player, Constants.Discoveries.IslandCollectedRock.Id)
		playSound(rock, "rbxasset://sounds/button.wav", 0.32, 0.68)

		if rock:IsA("BasePart") then
			tweenPart(rock, 0.18, {
				Transparency = 1,
				CFrame = rock.CFrame + Vector3.new(0, 0.42, 0),
			}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			rock.CanCollide = false
		end
		setPromptEnabled(rock, false)
		self.systemMessageRemote:FireClient(player, ("%s Rocks carried: %d."):format(message or "Beach rock pocketed.", self.islandRockCountByUserId[player.UserId]))

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

	local state = self.islandFireRingState[fireRingPart]
	local requiredWood = state and state.RequiredWood or 3
	local deposited = state and state.Deposited or requiredWood
	local intensity = math.clamp(1 + math.max(0, deposited - requiredWood), 1, 3)

	for _, instance in ipairs(fireRing:GetDescendants()) do
		if instance:IsA("ParticleEmitter") and instance:GetAttribute("IslandFireEmitter") then
			if instance.Name:find("Smoke", 1, true) then
				instance.Enabled = smokeActive
				instance.Rate = if fireActive then 9 + intensity * 6 else 7 + intensity * 4
				instance.Speed = NumberRange.new(0.28 + intensity * 0.08, 0.68 + intensity * 0.18)
				instance.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1.2 + intensity * 0.35),
					NumberSequenceKeypoint.new(0.55, 3.8 + intensity * 0.85),
					NumberSequenceKeypoint.new(1, 6.5 + intensity * 1.15),
				})
			elseif instance.Name:find("Glow", 1, true) then
				instance.Enabled = fireActive
				instance.Rate = 12 + intensity * 11
				instance.Speed = NumberRange.new(0.75 + intensity * 0.22, 1.55 + intensity * 0.38)
				instance.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.38 + intensity * 0.18),
					NumberSequenceKeypoint.new(1, 0.08),
				})
			else
				instance.Enabled = fireActive
				instance.Rate = 30 + intensity * 26
				instance.Speed = NumberRange.new(1 + intensity * 0.35, 2.35 + intensity * 0.62)
				instance.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.9 + intensity * 0.38),
					NumberSequenceKeypoint.new(0.45, 1.55 + intensity * 0.58),
					NumberSequenceKeypoint.new(1, 0.18 + intensity * 0.08),
				})
			end
		elseif instance:IsA("PointLight") and instance:GetAttribute("IslandFireLight") then
			instance.Enabled = fireActive or smokeActive
			instance.Brightness = fireActive and (1.6 + intensity * 1.1) or (smokeActive and 0.3 or 0)
			instance.Range = fireActive and (12 + intensity * 5) or (smokeActive and 7 or 0)
		end
	end
end

function InteractionService:_updateIslandFirePrompt(fireRingPart)
	local state = self.islandFireRingState[fireRingPart]
	local prompt = getPrompt(fireRingPart)
	if not state or not prompt then
		return
	end

	local requiredWood = state.RequiredWood or 3
	local maxWood = state.MaxWood or 4
	if state.Deposited < requiredWood then
		prompt.ActionText = "Add Wood"
		prompt.ObjectText = "Rock Ring"
	elseif state.Burning then
		prompt.ActionText = state.Deposited < maxWood and "Feed Fire" or "Roaring"
		prompt.ObjectText = "Campfire"
	elseif state.Smoking then
		prompt.ActionText = "Smoking"
		prompt.ObjectText = "Campfire"
	else
		prompt.ActionText = "Light"
		prompt.ObjectText = "Wood-Filled Ring"
	end
end

function InteractionService:_addIslandFirewood(fireRingPart, player)
	local state = self.islandFireRingState[fireRingPart]
	if not state then
		return false
	end

	local requiredWood = state.RequiredWood or 3
	local maxWood = state.MaxWood or 4
	if state.Deposited >= maxWood then
		self.systemMessageRemote:FireClient(player, "The campfire is fully stocked. More wood would be just showing off.")
		return false
	end

	local heldWood = self:_getPocketItemCount(player, "IslandWood", self.islandWoodCountByUserId)
	if heldWood <= 0 then
		local needed = math.max(1, math.min(requiredWood, maxWood) - state.Deposited)
		self.systemMessageRemote:FireClient(player, ("The rock ring wants %d more piece%s of driftwood. You are carrying none."):format(needed, needed == 1 and "" or "s"))
		return false
	end

	if not self:_consumePocketItem(player, "IslandWood", self.islandWoodCountByUserId) then
		self.systemMessageRemote:FireClient(player, "The rock ring reaches for driftwood, but your pockets come up empty.")
		return false
	end

	self.islandWoodCountByUserId[player.UserId] = self:_getPocketItemCount(player, "IslandWood", self.islandWoodCountByUserId)
	state.Deposited += 1
	self:_setIslandFireWoodVisible(fireRingPart, state.Deposited)
	self:_setIslandFireEmitters(fireRingPart, state.Burning, state.Smoking)
	self:_updateIslandFirePrompt(fireRingPart)
	playSound(fireRingPart, "rbxasset://sounds/button.wav", 0.35, 0.68)

	if state.Burning then
		state.BurnEndsAt = math.max(state.BurnEndsAt or 0, os.clock()) + 12
		self.systemMessageRemote:FireClient(player, ("More driftwood added: %d / %d. The fire gets bigger."):format(state.Deposited, maxWood))
	else
		self.systemMessageRemote:FireClient(player, ("Driftwood added: %d / %d."):format(state.Deposited, requiredWood))
	end

	return true
end

function InteractionService:_startIslandCampfire(fireRingPart, player)
	local state = self.islandFireRingState[fireRingPart]
	if not state or state.Burning or state.Smoking then
		return
	end

	state.Burning = true
	state.Smoking = true
	state.Token = {}
	state.BurnEndsAt = os.clock() + 18 + math.max(0, state.Deposited - (state.RequiredWood or 3)) * 12
	local token = state.Token
	self:_updateIslandFirePrompt(fireRingPart)

	self:_setIslandFireEmitters(fireRingPart, true, true)
	self.discoveryService:Unlock(player, Constants.Discoveries.IslandCampfire.Id)
	playSound(fireRingPart, "rbxasset://sounds/electronicpingshort.wav", 0.45, 0.48)
	self.systemMessageRemote:FireClient(player, "The island campfire decides to be dramatically useful.")

	task.spawn(function()
		while state.Token == token and state.Burning do
			local fireRing = self:_getIslandFireRingModel(fireRingPart)
			if fireRing then
				local requiredWood = state.RequiredWood or 3
				local intensity = math.clamp(1 + math.max(0, state.Deposited - requiredWood), 1, 3)
				local flicker = math.noise(os.clock() * 3.4, state.Deposited, 0) * 0.45
				for _, instance in ipairs(fireRing:GetDescendants()) do
					if instance:IsA("PointLight") and instance:GetAttribute("IslandFireLight") then
						instance.Brightness = math.max(0.25, 1.6 + intensity * 1.1 + flicker)
						instance.Range = 12 + intensity * 5 + math.abs(flicker) * 3
					end
				end
			end

			if os.clock() >= (state.BurnEndsAt or 0) then
				break
			end

			task.wait(0.12)
		end

		if state.Token ~= token or not state.Burning then
			return
		end

		state.Burning = false
		self:_setIslandFireEmitters(fireRingPart, false, true)
		self:_updateIslandFirePrompt(fireRingPart)
		self.systemMessageRemote:FireAllClients("The campfire goes out, but keeps smoking like it has notes.")

		task.delay(30, function()
			if state.Token ~= token then
				return
			end

			state.Smoking = false
			self:_setIslandFireEmitters(fireRingPart, false, false)
			state.BurnEndsAt = 0
			self:_updateIslandFirePrompt(fireRingPart)
		end)
	end)
end

function InteractionService:_wireIslandFireRing(fireRingPart)
	local prompt = getPrompt(fireRingPart)

	self.islandFireRingState[fireRingPart] = self.islandFireRingState[fireRingPart] or {
		Deposited = 0,
		RequiredWood = 3,
		MaxWood = 4,
		Burning = false,
		Smoking = false,
		Token = nil,
		BurnEndsAt = 0,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.islandFireRingState[fireRingPart]
		if not state then
			return
		end

		local requiredWood = state.RequiredWood or 3
		if state.Deposited < requiredWood then
			self:_addIslandFirewood(fireRingPart, player)
			return
		end

		if state.Burning then
			self:_addIslandFirewood(fireRingPart, player)
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
						CFrame = baseCFrame + Vector3.new(0, lift, 0),
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
