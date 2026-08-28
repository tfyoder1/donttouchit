local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local RemoteService = require(script.Parent:WaitForChild("RemoteService"))
local PlayerScale = require(script.Parent:WaitForChild("PlayerScale"))
local LowGravityEvent = require(script.Parent:WaitForChild("Events"):WaitForChild("LowGravity"))

local RoomProgressService = {}
RoomProgressService.__index = RoomProgressService

local STORE_PRICE_KEYS = {
	HintPackRobux = true,
	ClueRobux = true,
	RevealRobux = true,
	ClueHintCost = true,
	RevealClueCost = true,
	SecretKeyClueCost = true,
	TeleportKeyClueCost = true,
	TeleportKeyRobux = true,
	DuckFounderRobux = true,
	VictoryBrickRobux = true,
}
local FALL_RECOVERY_Y = -160
local FALL_RECOVERY_COOLDOWN_SECONDS = 1.5
local TELEPORT_LANDING_LIFT = Vector3.new(0, 2.6, 0)
local TOP_DOWN_ARENA_MUSIC_ID = "rbxassetid://1846912254"
local TOP_DOWN_ARENA_MUSIC_NAME = "TopDownArenaMusic"
local TOP_DOWN_ARENA_MUSIC_VOLUME = 0.5
local TOP_DOWN_ARENA_MUSIC_FADE_SECONDS = 1.5
local TOP_DOWN_ARENA_MUSIC_MIN_PLAYERS = 2
local FLASHLIGHT_ATTRIBUTE = "DontTouchItFlashlight"
local FLASHLIGHT_OWNED_ATTRIBUTE = "DontTouchItHasFlashlight"
local SIGNAL_BAND_ATTRIBUTE = "DontTouchItSignalBandEquipped"
local SIGNAL_BAND_NAME = "DontTouchItSignalBand"
local CAVE_FLASHLIGHT_REMINDER_POSITION = Vector3.new(-76, 0, 45)
local CAVE_FLASHLIGHT_REMINDER_RADIUS = 16
local CAVE_ENTRANCE_LOCK_RETURN_X = -74
local CAVE_ENTRANCE_LOCK_RETURN_CFRAME = CFrame.new(Vector3.new(-86, 3, 45), Vector3.new(-102, 3, 45))

local function playSpatialSound(parent, soundId, volume, playbackSpeed)
	if not parent or not parent.Parent or typeof(soundId) ~= "string" or soundId == "" then
		return
	end

	local sound = Instance.new("Sound")
	sound.Name = "TemporarySound"
	sound.SoundId = soundId
	sound.Volume = volume or 0.65
	sound.PlaybackSpeed = playbackSpeed or 1
	sound.RollOffMaxDistance = 45
	sound.Parent = parent
	sound:Play()
	task.delay(3, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

local function closeContainmentExitDoors()
	local roomId = Constants.Prologue.ContainmentRoomId or "TVRoom"
	for _, door in ipairs(CollectionService:GetTagged(Constants.Tags.ExitDoor)) do
		if door:IsA("BasePart") and door:GetAttribute("RoomId") == roomId then
			door.CanCollide = true
			door.CanQuery = true
			door.Transparency = 0
			door.Color = door:GetAttribute("BaseColor") or Color3.fromRGB(72, 102, 119)
			door.Material = door:GetAttribute("BaseMaterial") or Enum.Material.SmoothPlastic
			playSpatialSound(
				door,
				Constants.AudioAssets.Prologue.LockdownDoorEchoId or "rbxasset://sounds/snap.wav",
				0.65,
				0.42
			)
		end
	end
end

local function getRootPart(player)
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function playerHasFlashlight(player)
	if not player or not player.Parent then
		return false
	end

	if player:GetAttribute(FLASHLIGHT_OWNED_ATTRIBUTE) == true then
		return true
	end

	for _, container in ipairs({ player.Character, player:FindFirstChildOfClass("Backpack") }) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Tool") and child:GetAttribute(FLASHLIGHT_ATTRIBUTE) == true then
					return true
				end
			end
		end
	end

	return false
end

local function clearSignalBandForFreshRun(player)
	player:SetAttribute(SIGNAL_BAND_ATTRIBUTE, false)

	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if playerGui then
		playerGui:SetAttribute(SIGNAL_BAND_ATTRIBUTE, false)
	end

	local character = player.Character
	if not character then
		return
	end

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant.Name == SIGNAL_BAND_NAME then
			descendant:Destroy()
		end
	end
end

local function teleportPlayer(player, destinationCFrame)
	local rootPart = getRootPart(player)
	if not rootPart and player and player.Parent then
		player.CharacterAdded:Wait()
		task.wait(0.1)
		rootPart = getRootPart(player)
	end

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

local function getContinueDestination(destinationId)
	if typeof(destinationId) ~= "string" then
		return nil
	end

	return Constants.GetRoom(destinationId)
		or (Constants.GetNamedPlace and Constants.GetNamedPlace(destinationId))
end

local function getContinueDestinationName(destinationId)
	local destination = getContinueDestination(destinationId)
	return destination and destination.Name or "TV Room"
end

local function getContinueDestinationCFrame(destinationId)
	if Constants.GetRoom(destinationId) then
		return Constants.GetRoomSpawnCFrame(destinationId)
	end

	if Constants.GetNamedPlace and Constants.GetNamedPlace(destinationId) then
		return Constants.GetNamedPlaceCFrame(destinationId)
	end

	return Constants.GetRoomSpawnCFrame("TVRoom")
end

local function getTopDownArenaMusic()
	local existing = SoundService:FindFirstChild(TOP_DOWN_ARENA_MUSIC_NAME)
	if existing and existing:IsA("Sound") then
		existing.SoundId = TOP_DOWN_ARENA_MUSIC_ID
		existing.Looped = true
		return existing
	end

	local sound = Instance.new("Sound")
	sound.Name = TOP_DOWN_ARENA_MUSIC_NAME
	sound.SoundId = TOP_DOWN_ARENA_MUSIC_ID
	sound.Volume = 0
	sound.Looped = true
	sound.Parent = SoundService
	return sound
end

local function fadeSoundVolume(sound, targetVolume)
	local tween = TweenService:Create(
		sound,
		TweenInfo.new(TOP_DOWN_ARENA_MUSIC_FADE_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Volume = targetVolume }
	)
	tween:Play()
	return tween
end

function RoomProgressService.new(discoveryService)
	local self = setmetatable({}, RoomProgressService)
	self.discoveryService = discoveryService
	self.referenceBookRemote = RemoteService.GetRemote(Constants.Remotes.ReferenceBook)
	self.hintPackRemote = RemoteService.GetRemote(Constants.Remotes.HintPackRequest)
	self.sessionStartRemote = RemoteService.GetRemote(Constants.Remotes.SessionStart)
	self.systemMessageRemote = RemoteService.GetRemote(Constants.Remotes.SystemMessage)
	self.roomStatusRemote = RemoteService.GetRemote(Constants.Remotes.RoomStatus)
	self.sparkleRemote = RemoteService.GetRemote(Constants.Remotes.SparkleHint)
	self.prologueRemote = RemoteService.GetRemote(Constants.Remotes.Prologue)
	self.transformCameraRemote = RemoteService.GetRemote(Constants.Remotes.TransformCamera)
	self.movementAuthorityService = nil
	self.stateByUserId = {}
	self.pendingHintPurchaseByUserId = {}
	self.storePriceOverrides = {}
	self.topDownArenaMusic = nil
	self.topDownArenaMusicActive = false
	return self
end

function RoomProgressService:SetMovementAuthorityService(movementAuthorityService)
	self.movementAuthorityService = movementAuthorityService
end

function RoomProgressService:_teleportPlayer(player, destinationCFrame, reason)
	if self.movementAuthorityService and self.movementAuthorityService.TeleportPlayer then
		local success = self.movementAuthorityService:TeleportPlayer(player, destinationCFrame, reason)
		if success then
			self:RememberSafeSpawn(player, destinationCFrame)
		end
		return success
	end

	teleportPlayer(player, destinationCFrame)
	self:RememberSafeSpawn(player, destinationCFrame)
	return true
end

function RoomProgressService:RememberSafeSpawn(player, destinationCFrame)
	if not player or not player.Parent or typeof(destinationCFrame) ~= "CFrame" then
		return false
	end

	local state = self:_getState(player)
	state.LastSafeSpawnCFrame = destinationCFrame
	return true
end

function RoomProgressService:_inferContinueDestinationId(destinationCFrame)
	if typeof(destinationCFrame) ~= "CFrame" then
		return nil
	end

	local position = destinationCFrame.Position
	for _, roomId in ipairs(Constants.RoomDetectionOrder or Constants.DiscoveryRoomOrder or Constants.RoomOrder) do
		local room = Constants.GetRoom(roomId)
		if room and positionInZone(position, room.Zone) then
			return roomId
		end
	end

	if Constants.GetNamedPlace and Constants.GetNamedPlace("Hallway") and positionInZone(position, Constants.Hallway.Zone) then
		return "Hallway"
	end

	return nil
end

function RoomProgressService:RememberContinueDestination(player, destinationId, destinationCFrame, shouldSave)
	if not player or not player.Parent or not self.discoveryService or self:IsUntouchedProloguePending(player) then
		return false
	end

	local continueId = if getContinueDestination(destinationId) then destinationId else self:_inferContinueDestinationId(destinationCFrame)
	if not continueId then
		return false
	end

	return self.discoveryService:SetContinueRoomId(player, continueId, shouldSave)
end

function RoomProgressService:_getRecoveryCFrame(player, state)
	if state and typeof(state.LastSafeSpawnCFrame) == "CFrame" then
		return state.LastSafeSpawnCFrame
	end

	local roomId = self:GetRoomForPlayer(player)
	if roomId and Constants.GetRoom(roomId) then
		return Constants.GetRoomSpawnCFrame(roomId)
	end

	return Constants.GetRoomSpawnCFrame(Constants.Prologue.StartRoomId or "CaveEntrance")
end

function RoomProgressService:Initialize()
	local function setupPlayer(player)
		self:_getState(player)

		player.CharacterAdded:Connect(function()
			task.delay(0.8, function()
				if player.Parent then
					self:_sendStartOptions(player)
				end
			end)
		end)

		task.delay(1, function()
			if player.Parent then
				self:_sendStartOptions(player)
			end
		end)
	end

	Players.PlayerAdded:Connect(setupPlayer)

	Players.PlayerRemoving:Connect(function(player)
		self.stateByUserId[player.UserId] = nil
		self.pendingHintPurchaseByUserId[player.UserId] = nil
	end)

	self.sessionStartRemote.OnServerEvent:Connect(function(player, payload)
		self:_handleSessionStart(player, payload)
	end)

	self.hintPackRemote.OnServerEvent:Connect(function(player, payload)
		self:_handleHintRequest(player, payload)
	end)

	self:_installReceiptHandler()

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	task.spawn(function()
		while true do
			self:_tick(os.clock())
			task.wait(1)
		end
	end)
end

function RoomProgressService:_getState(player)
	local state = self.stateByUserId[player.UserId]

	if not state then
		local now = os.clock()
		state = {
			CurrentRoomId = nil,
			TimerStartedAt = now,
			PlayStartedAt = now,
			LastRoomTickAt = nil,
			LastSafeSpawnCFrame = nil,
			LastFallRecoveryAt = 0,
			OutsideCaveAudioStopped = false,
			RoomPlaySecondsByRoomId = {},
			RoomPlayRewardsByRoomId = {},
			SparkleStateByRoomId = {},
			StartOptionsSent = false,
			StartChoiceHandled = false,
			UntouchedPrologueActive = false,
			UntouchedPrologueTriggered = false,
			UntouchedPrologueContained = false,
			CaveFlashlightReminderShown = false,
			LastInteractionAt = now,
			LastContainmentReturnAt = 0,
			LastContainmentRumbleAt = 0,
			TwoMinuteAwarded = {},
			BonusAwarded = {},
		}
		self.stateByUserId[player.UserId] = state
	end

	return state
end

function RoomProgressService:_hasAnyProgress(player)
	if not player or not player.Parent then
		return false
	end

	local discoveryCount = self.discoveryService:GetDiscoveryCount(player)
	local hintCount = self.discoveryService:GetHintCount(player)
	local clueCount = self.discoveryService:GetClueCount(player)
	return discoveryCount > 0 or hintCount > 0 or clueCount > 0
end

function RoomProgressService:IsUntouchedPrologueActive(player)
	if not player or not player.Parent then
		return false
	end

	local state = self:_getState(player)
	return state.UntouchedPrologueActive == true and state.UntouchedPrologueTriggered ~= true
end

function RoomProgressService:IsUntouchedProloguePending(player)
	if not player or not player.Parent then
		return false
	end

	local state = self:_getState(player)
	return state.UntouchedPrologueActive == true or state.UntouchedPrologueTriggered == true
end

function RoomProgressService:IsStartupOrPrologueRestricted(player)
	if not player or not player.Parent then
		return true
	end

	local state = self:_getState(player)
	if state.StartChoiceHandled ~= true then
		return true
	end

	if self:IsUntouchedProloguePending(player) then
		return true
	end

	return state.UntouchedPrologueContained == true and player:GetAttribute(SIGNAL_BAND_ATTRIBUTE) ~= true
end

function RoomProgressService:IsFirstContainmentDrainActive(player)
	if not player or not player.Parent then
		return false
	end

	local state = self:_getState(player)
	if state.UntouchedPrologueContained ~= true or player:GetAttribute(SIGNAL_BAND_ATTRIBUTE) == true then
		return false
	end

	return self:GetRoomForPlayer(player) == (Constants.Prologue.ContainmentRoomId or "TVRoom")
end

function RoomProgressService:StopOutsideCaveAudioForPlayer(player)
	if not player or not player.Parent then
		return false
	end

	local state = self:_getState(player)
	if state.OutsideCaveAudioStopped then
		return false
	end

	state.OutsideCaveAudioStopped = true
	self.prologueRemote:FireClient(player, {
		Action = "StopOutsideCaveAudio",
	})
	return true
end

function RoomProgressService:GetRoomForPlayer(player)
	local rootPart = getRootPart(player)
	if not rootPart then
		return nil
	end

	for _, roomId in ipairs(Constants.RoomDetectionOrder or Constants.DiscoveryRoomOrder or Constants.RoomOrder) do
		local room = Constants.GetRoom(roomId)
		if room and positionInZone(rootPart.Position, room.Zone) then
			return roomId
		end
	end

	return nil
end

function RoomProgressService:GetAreaForPlayer(player)
	local rootPart = getRootPart(player)
	if not rootPart then
		return nil
	end

	if positionInZone(rootPart.Position, Constants.Hallway.Zone) then
		return Constants.Hallway.Id
	end

	return self:GetRoomForPlayer(player)
end

function RoomProgressService:RecordInteraction(player)
	if not player or not player.Parent then
		return
	end

	local state = self:_getState(player)
	local now = os.clock()
	state.TimerStartedAt = now
	state.LastInteractionAt = now
end

function RoomProgressService:_beginUntouchedPrologue(player)
	local state = self:_getState(player)
	local startRoomId = Constants.Prologue.StartRoomId or "CaveEntrance"
	local startCFrame = Constants.GetRoomSpawnCFrame(startRoomId)
	local now = os.clock()

	state.StartChoiceHandled = true
	state.UntouchedPrologueActive = true
	state.UntouchedPrologueTriggered = false
	state.UntouchedPrologueContained = false
	state.OutsideCaveAudioStopped = false
	state.CurrentRoomId = nil
	state.TimerStartedAt = now
	state.LastInteractionAt = now
	state.LastContainmentRumbleAt = 0
	state.LastRoomTickAt = nil
	state.LastSafeSpawnCFrame = startCFrame
	state.CaveFlashlightReminderShown = false

	clearSignalBandForFreshRun(player)
	self:_teleportPlayer(player, startCFrame, "UntouchedPrologueStart")
	self.prologueRemote:FireClient(player, {
		Action = "Begin",
		FlashlightRange = Constants.Prologue.FlashlightRange,
		InspectRange = Constants.Prologue.InspectRange,
		InspectIntervalSeconds = Constants.Prologue.InspectIntervalSeconds,
		DarkLighting = Constants.Prologue.DarkLighting,
		Message = "You wake up under the trees. The cave ahead should not have electric lights.",
	})
	self.systemMessageRemote:FireClient(player, "You wake up in the forest. Find the flashlight before going inside.")
end

function RoomProgressService:TryTriggerUntouchedPrologue(player, sourceInstance, isSafeNavigation)
	if not player or not player.Parent then
		return false
	end

	local state = self:_getState(player)
	if state.UntouchedPrologueTriggered then
		return false
	end

	if not state.UntouchedPrologueActive then
		return false
	end

	if isSafeNavigation then
		return false
	end

	state.UntouchedPrologueTriggered = true
	state.TimerStartedAt = os.clock()

	local objectName = "something"
	if sourceInstance and sourceInstance.Parent then
		local prompt = if sourceInstance:IsA("ProximityPrompt") then sourceInstance else sourceInstance:FindFirstChildOfClass("ProximityPrompt")
		if prompt and prompt.ObjectText ~= "" then
			objectName = prompt.ObjectText
		elseif sourceInstance.Name ~= "" then
			objectName = sourceInstance.Name
		end
	end

	self.prologueRemote:FireClient(player, {
		Action = "Lockdown",
		ObjectName = objectName,
		Mode = "StartupB",
		SpinUpSeconds = Constants.Prologue.LightSpinUpSeconds or 30,
		Message = "Something under the floor wakes up.",
	})
	self.systemMessageRemote:FireClient(player, "The bunker locks down around you. Somewhere deeper, old systems begin to answer.")

	return false
end

function RoomProgressService:_completeUntouchedPrologueContainment(player)
	if not player or not player.Parent then
		return false
	end

	local state = self:_getState(player)
	if state.UntouchedPrologueContained or not self:IsUntouchedProloguePending(player) then
		return false
	end

	state.UntouchedPrologueContained = true
	state.UntouchedPrologueActive = false
	state.UntouchedPrologueTriggered = false
	state.TimerStartedAt = os.clock()
	state.LastInteractionAt = state.TimerStartedAt
	state.LastContainmentRumbleAt = state.TimerStartedAt
	state.LastRoomTickAt = nil
	closeContainmentExitDoors()

	self.prologueRemote:FireClient(player, {
		Action = "Contained",
		Mode = "StartupB",
		SpinUpSeconds = Constants.Prologue.LightSpinUpSeconds or 30,
		Message = "The TV room answers slowly.",
	})
	self.systemMessageRemote:FireClient(player, "The TV room boots one system at a time. The bunker sounds underfed.")
	return true
end

function RoomProgressService:_maybePlayContainmentIdleRumble(player, state, now)
	local lastInteractionAt = state.LastInteractionAt or state.TimerStartedAt or now
	local minGapAfterInteraction = Constants.Prologue.ContainmentIdleRumbleMinGapAfterInteractionSeconds or 7
	if now - lastInteractionAt < minGapAfterInteraction then
		return
	end

	local lastRumbleAt = state.LastContainmentRumbleAt or 0
	local waitSeconds = if lastRumbleAt > 0
		then Constants.Prologue.ContainmentIdleRumbleIntervalSeconds or 14
		else Constants.Prologue.ContainmentIdleRumbleDelaySeconds or 10
	local anchor = if lastRumbleAt > 0 then lastRumbleAt else state.TimerStartedAt or now
	if now - anchor < waitSeconds then
		return
	end

	state.LastContainmentRumbleAt = now
	self.prologueRemote:FireClient(player, {
		Action = "HungryRumble",
		Duration = Constants.Prologue.ContainmentIdleRumbleDuration or 1.35,
		Intensity = Constants.Prologue.ContainmentIdleRumbleIntensity or 0.16,
	})
end

function RoomProgressService:StartFreshDevSession(player)
	if not player or not player.Parent then
		return false
	end

	local state = self:_getState(player)
	local now = os.clock()
	state.CurrentRoomId = nil
	state.TimerStartedAt = now
	state.PlayStartedAt = now
	state.LastRoomTickAt = nil
	state.RoomPlaySecondsByRoomId = {}
	state.RoomPlayRewardsByRoomId = {}
	state.SparkleStateByRoomId = {}
	state.StartOptionsSent = true
	state.StartChoiceHandled = true
	state.UntouchedPrologueActive = false
	state.UntouchedPrologueTriggered = false
	state.TwoMinuteAwarded = {}
	state.BonusAwarded = {}

	self:_beginUntouchedPrologue(player)
	return true
end

function RoomProgressService:GetStorePrices()
	return {
		HintPackSize = Constants.NoTouch.HintPackSize,
		HintPackRobux = self.storePriceOverrides.HintPackRobux or Constants.NoTouch.HintPackRobux or 0,
		HintPackProductId = Constants.NoTouch.HintPackProductId or 0,
		ClueRobux = self.storePriceOverrides.ClueRobux or Constants.NoTouch.ClueRobux or 0,
		ClueProductId = Constants.NoTouch.ClueProductId or Constants.NoTouch.PaidHintProductId or 0,
		ClueHintCost = self.storePriceOverrides.ClueHintCost or Constants.NoTouch.ClueHintCost or 5,
		RevealRobux = self.storePriceOverrides.RevealRobux or Constants.NoTouch.RevealRobux or Constants.NoTouch.FullRevealRobux or 0,
		RevealProductId = Constants.NoTouch.RevealProductId or Constants.NoTouch.FullRevealProductId or 0,
		RevealClueCost = self.storePriceOverrides.RevealClueCost or Constants.NoTouch.RevealClueCost or 3,
		SecretKeyClueCost = self.storePriceOverrides.SecretKeyClueCost or Constants.NoTouch.SecretKeyClueCost or Constants.NoTouch.RevealClueCost or 3,
		TeleportKeyClueCost = self.storePriceOverrides.TeleportKeyClueCost or Constants.NoTouch.TeleportKeyClueCost or Constants.NoTouch.RevealClueCost or 3,
		TeleportKeyRobux = self.storePriceOverrides.TeleportKeyRobux or Constants.NoTouch.TeleportKeyRobux or 5,
		DuckFounderRobux = self.storePriceOverrides.DuckFounderRobux or Constants.NoTouch.DuckFounderRobux or 80000,
		DuckFounderProductId = Constants.NoTouch.DuckFounderProductId or 0,
		VictoryBrickRobux = self.storePriceOverrides.VictoryBrickRobux or Constants.NoTouch.VictoryBrickRobux or 8000,
		VictoryBrickProductId = Constants.NoTouch.VictoryBrickProductId or 0,
	}
end

function RoomProgressService:GetStorePrice(key)
	return self:GetStorePrices()[key]
end

function RoomProgressService:AdjustStorePrice(key, delta)
	if not STORE_PRICE_KEYS[key] then
		return false
	end

	local amount = math.floor(tonumber(delta) or 0)
	if amount == 0 then
		return false
	end

	local current = self:GetStorePrice(key) or 0
	self.storePriceOverrides[key] = math.clamp(current + amount, 0, 1000000000)
	return true
end

function RoomProgressService:ResetStorePrices()
	self.storePriceOverrides = {}
end

function RoomProgressService:ShowReferenceBook(player, roomId, extra)
	if not Constants.GetRoom(roomId) then
		roomId = self:GetRoomForPlayer(player) or "TVRoom"
	end

	local snapshot = self.discoveryService:GetRoomSnapshot(player, roomId)
	if not snapshot then
		self.systemMessageRemote:FireClient(player, "Room menu could not find a valid room record.")
		return
	end

	local storePrices = self:GetStorePrices()
	snapshot.StorePrices = storePrices
	snapshot.ClueHintCost = storePrices.ClueHintCost
	snapshot.RevealClueCost = storePrices.RevealClueCost
	if snapshot.SecretDoor then
		snapshot.SecretDoor.KeyClueCost = storePrices.SecretKeyClueCost
	end

	if extra then
		for key, value in pairs(extra) do
			snapshot[key] = value
		end
	end

	self.referenceBookRemote:FireClient(player, snapshot)
end

function RoomProgressService:_buildUnlockedTeleportRooms(player)
	local rooms = {}
	local observationPlaces = {}

	for _, roomId in ipairs(Constants.DiscoveryRoomOrder or Constants.RoomOrder) do
		if self.discoveryService:IsRoomUnlocked(player, roomId) then
			local room = Constants.GetRoom(roomId)
			if room then
				table.insert(rooms, {
					RoomId = roomId,
					Name = room.Name,
				})
			end
		end
	end

	for _, place in pairs(Constants.NamedPlaces or {}) do
		if place.TeleportGroup == "Observation" then
			local requirement = place.RequiresDiscoveryId
			if not requirement or self.discoveryService:HasDiscovery(player, requirement) then
				table.insert(observationPlaces, {
					RoomId = place.Id,
					Name = place.Name,
					IsNamedPlace = true,
					TeleportGroup = place.TeleportGroup,
				})
			end
		end
	end
	table.sort(observationPlaces, function(left, right)
		return (left.Name or left.RoomId or "") < (right.Name or right.RoomId or "")
	end)
	for _, place in ipairs(observationPlaces) do
		table.insert(rooms, place)
	end

	return rooms
end

function RoomProgressService:_getFieldControl(effectId)
	if typeof(effectId) ~= "string" then
		return nil
	end

	for _, fieldControl in ipairs(Constants.FieldControls or {}) do
		if fieldControl.Id == effectId then
			return fieldControl
		end
	end

	return nil
end

function RoomProgressService:_isFieldControlUnlocked(player, fieldControl)
	if typeof(fieldControl) ~= "table" then
		return false
	end

	local requirement = fieldControl.RequiresDiscoveryId
	if not requirement then
		return true
	end

	return self.discoveryService:HasDiscovery(player, requirement)
end

function RoomProgressService:_buildUnlockedFieldControls(player)
	local controls = {}

	for _, fieldControl in ipairs(Constants.FieldControls or {}) do
		if self:_isFieldControlUnlocked(player, fieldControl) then
			local control = {}
			for key, value in pairs(fieldControl) do
				control[key] = value
			end
			table.insert(controls, control)
		end
	end

	return controls
end

function RoomProgressService:ShowStore(player, roomId)
	self:ShowReferenceBook(player, roomId, {
		Mode = "Store",
		StatusText = "Time, restraint, and secret work earn rewards here. Purchases only rush what play can still earn.",
		StorePrices = self:GetStorePrices(),
	})
end

function RoomProgressService:ShowTeleportMenu(player, roomId)
	if not self.discoveryService:HasTeleportKey(player) then
		self.systemMessageRemote:FireClient(player, "The controls notice you do not have the Teleport Key yet.")
		return
	end

	self:ShowReferenceBook(player, roomId, {
		Mode = "Teleport",
		StatusText = "Teleport Key active. Pick any opened room or learned coordinate.",
		TeleportRooms = self:_buildUnlockedTeleportRooms(player),
	})
end

function RoomProgressService:ShowFieldControls(player, roomId)
	self:ShowReferenceBook(player, roomId, {
		Mode = "Field",
		StatusText = "Temporary field adjustments. Discoveries and rewards still follow the room rules.",
		FieldControls = self:_buildUnlockedFieldControls(player),
	})
end

function RoomProgressService:_sendStartOptions(player)
	local state = self:_getState(player)
	if state.StartOptionsSent then
		return
	end

	if not self.discoveryService:IsLoaded(player) then
		task.delay(0.5, function()
			if player.Parent then
				self:_sendStartOptions(player)
			end
		end)
		return
	end

	state.StartOptionsSent = true

	local resumeRoomId = self.discoveryService:GetContinueRoomId(player)
	local resumeRoomName = getContinueDestinationName(resumeRoomId)
	local discoveryCount = self.discoveryService:GetDiscoveryCount(player)
	local hintCount = self.discoveryService:GetHintCount(player)
	local clueCount = self.discoveryService:GetClueCount(player)
	local savedProgress = self.discoveryService.GetSavedProgressSummary
		and self.discoveryService:GetSavedProgressSummary(player)
		or nil
	local hasProgress = discoveryCount > 0 or hintCount > 0 or clueCount > 0 or resumeRoomId ~= Constants.RoomOrder[1]
	local unlockedRooms = {}

	for _, roomId in ipairs(Constants.DiscoveryRoomOrder or Constants.RoomOrder) do
		if self.discoveryService:IsRoomUnlocked(player, roomId) then
			local room = Constants.GetRoom(roomId)
			if room then
				table.insert(unlockedRooms, {
					RoomId = roomId,
					Name = room.Name,
					IsResumeRoom = roomId == resumeRoomId,
				})
			end
		end
	end

	self.sessionStartRemote:FireClient(player, {
		Action = "Show",
		HasProgress = hasProgress,
		FreshStartRoomName = "Forest Cave",
		ResumeRoomId = resumeRoomId,
		ResumeRoomName = resumeRoomName,
		UnlockedRooms = unlockedRooms,
		DiscoveryCount = discoveryCount,
		TotalDiscoveries = Constants.TotalDiscoveries,
		Hints = hintCount,
		Clues = clueCount,
		BuildVersion = Constants.BuildVersion,
		IntroText = Constants.GameIntro,
		SavedProgress = savedProgress,
	})
end

function RoomProgressService:_handleSessionStart(player, payload)
	if typeof(payload) ~= "table" then
		return
	end

	local action = payload.Action
	if action == "RequestOptions" then
		local state = self:_getState(player)
		if state.StartChoiceHandled then
			return
		end

		state.StartOptionsSent = false
		self:_sendStartOptions(player)
		return
	end

	local roomId = Constants.Prologue.StartRoomId or "CaveEntrance"
	local message = "Starting from the forest. The cave lights are waiting."

	if action == "Resume" then
		if not self:_hasAnyProgress(player) then
			self:_beginUntouchedPrologue(player)
			return
		end

		roomId = self.discoveryService:GetContinueRoomId(player)
		message = ("Returning to %s. Try to look innocent."):format(getContinueDestinationName(roomId))
	elseif action == "Room" then
		local requestedRoomId = payload.RoomId
		if typeof(requestedRoomId) ~= "string" or not Constants.GetRoom(requestedRoomId) then
			return
		end

		if not self.discoveryService:IsRoomUnlocked(player, requestedRoomId) then
			self.systemMessageRemote:FireClient(player, "That room is still locked. The start screen refuses to pretend otherwise.")
			local state = self:_getState(player)
			state.StartOptionsSent = false
			self:_sendStartOptions(player)
			return
		end

		roomId = requestedRoomId
		local room = Constants.GetRoom(roomId)
		message = ("Starting in %s. Please continue not touching things there."):format(room and room.Name or "the room")
	elseif action == "Restart" then
		if self.discoveryService.StartFreshRunSession then
			self.discoveryService:StartFreshRunSession(player)
		end
		self:_beginUntouchedPrologue(player)
		self.systemMessageRemote:FireClient(player, "Fresh run started. Your prior progress is still on file, which is not suspicious at all.")
		return
	else
		return
	end

	local state = self:_getState(player)
	state.StartChoiceHandled = true
	state.UntouchedPrologueActive = false
	state.UntouchedPrologueTriggered = false
	state.UntouchedPrologueContained = false
	state.TimerStartedAt = os.clock()

	local destinationCFrame = getContinueDestinationCFrame(roomId)
	if self:_teleportPlayer(player, destinationCFrame, "SessionStart") then
		self:RememberContinueDestination(player, roomId, destinationCFrame, true)
	end
	self.systemMessageRemote:FireClient(player, message)
end

function RoomProgressService:_getTopDownArenaPlayerCount()
	local playerCount = 0

	for _, player in ipairs(Players:GetPlayers()) do
		if self:GetRoomForPlayer(player) == "TopDownArena" then
			playerCount += 1
		end
	end

	return playerCount
end

function RoomProgressService:_updateTopDownArenaMusic()
	local shouldPlayMusic = self:_getTopDownArenaPlayerCount() >= TOP_DOWN_ARENA_MUSIC_MIN_PLAYERS

	if shouldPlayMusic and not self.topDownArenaMusic then
		self.topDownArenaMusic = getTopDownArenaMusic()
	end

	if shouldPlayMusic and self.topDownArenaMusic and not self.topDownArenaMusicActive then
		self.topDownArenaMusicActive = true
		if not self.topDownArenaMusic.IsPlaying then
			self.topDownArenaMusic:Play()
		end
		fadeSoundVolume(self.topDownArenaMusic, TOP_DOWN_ARENA_MUSIC_VOLUME)
	elseif not shouldPlayMusic and self.topDownArenaMusic and self.topDownArenaMusicActive then
		self.topDownArenaMusicActive = false
		local sound = self.topDownArenaMusic
		fadeSoundVolume(sound, 0)
		task.delay(TOP_DOWN_ARENA_MUSIC_FADE_SECONDS, function()
			if sound.Parent and not self.topDownArenaMusicActive and sound.Volume <= 0.001 then
				sound:Stop()
			end
		end)
	end
end

function RoomProgressService:_tick(now)
	local spaceStationOccupied = false

	for _, player in ipairs(Players:GetPlayers()) do
		self:_tickPlayer(player, now)
		if self:GetRoomForPlayer(player) == "SpaceStation" then
			spaceStationOccupied = true
		end
	end

	if spaceStationOccupied then
		workspace.Gravity = Constants.SpaceStationGravity or 24
	elseif workspace.Gravity == (Constants.SpaceStationGravity or 24) then
		workspace.Gravity = Constants.NormalGravity
	end

	self:_updateTopDownArenaMusic()
end

function RoomProgressService:_tickPlayer(player, now)
	local roomId = self:GetRoomForPlayer(player)
	local state = self:_getState(player)
	local rootPart = getRootPart(player)

	if rootPart and rootPart.Position.Y < FALL_RECOVERY_Y then
		if now - (state.LastFallRecoveryAt or 0) >= FALL_RECOVERY_COOLDOWN_SECONDS then
			state.LastFallRecoveryAt = now
			self:_teleportPlayer(player, self:_getRecoveryCFrame(player, state), "FallRecovery")
			self.systemMessageRemote:FireClient(player, "The floor lost track of you. Returning to the last stable spot.")
		end
		return
	end

	local inHallway = rootPart and positionInZone(rootPart.Position, Constants.Hallway.Zone)
	if inHallway then
		state.LastSafeSpawnCFrame = Constants.Hallway.SpawnCFrame
		if state.CurrentRoomId == "CaveEntrance" or self:IsUntouchedProloguePending(player) then
			self:StopOutsideCaveAudioForPlayer(player)
		end
	end

	if rootPart
		and self:IsUntouchedProloguePending(player)
		and state.UntouchedPrologueTriggered == true
		and player:GetAttribute(SIGNAL_BAND_ATTRIBUTE) ~= true
		and roomId == "CaveEntrance"
		and not inHallway
		and rootPart.Position.X > CAVE_ENTRANCE_LOCK_RETURN_X
	then
		if now - (state.LastCaveLockReturnAt or 0) >= 1.5 then
			state.LastCaveLockReturnAt = now
			self:_teleportPlayer(player, CAVE_ENTRANCE_LOCK_RETURN_CFRAME, "CaveEntranceLockedReturn")
			self.systemMessageRemote:FireClient(player, "The cave entrance has locked behind you. The only way forward is deeper.")
		end
		return
	end

	if state.UntouchedPrologueContained == true and player:GetAttribute(SIGNAL_BAND_ATTRIBUTE) ~= true then
		local containmentRoomId = Constants.Prologue.ContainmentRoomId or "TVRoom"
		if roomId ~= containmentRoomId then
			if now - (state.LastContainmentReturnAt or 0) >= 1.5 then
				state.LastContainmentReturnAt = now
				closeContainmentExitDoors()
				self:_teleportPlayer(player, Constants.GetRoomSpawnCFrame(containmentRoomId), "ContainmentReturn")
				self.systemMessageRemote:FireClient(player, "The TV room door locks behind you. The room is not finished yet.")
			end
			return
		end
		closeContainmentExitDoors()
		self:_maybePlayContainmentIdleRumble(player, state, now)
	end

	if rootPart
		and self:IsUntouchedProloguePending(player)
		and not state.CaveFlashlightReminderShown
		and not playerHasFlashlight(player)
	then
		local flatPosition = Vector3.new(rootPart.Position.X, 0, rootPart.Position.Z)
		if (flatPosition - CAVE_FLASHLIGHT_REMINDER_POSITION).Magnitude <= CAVE_FLASHLIGHT_REMINDER_RADIUS then
			state.CaveFlashlightReminderShown = true
			self.systemMessageRemote:FireClient(player, "I should have picked up that flashlight at the entrance.")
		end
	end

	if not roomId then
		state.CurrentRoomId = nil
		state.TimerStartedAt = now
		state.LastRoomTickAt = nil
		self:_sendRoomStatus(player, now)
		return
	end

	if state.CurrentRoomId ~= roomId then
		state.CurrentRoomId = roomId
		state.TimerStartedAt = now
		state.LastRoomTickAt = now
		state.LastSafeSpawnCFrame = Constants.GetRoomSpawnCFrame(roomId)
		state.SparkleStateByRoomId[roomId] = {
			NextSparkleAt = now + Constants.Sparkle.FirstDelaySeconds,
		}

		if self:IsUntouchedProloguePending(player) and roomId == (Constants.Prologue.ContainmentRoomId or "TVRoom") then
			self:_completeUntouchedPrologueContainment(player)
		elseif self:IsUntouchedProloguePending(player) then
			-- In the opening forest/cave walk, looking around is still a clean record.
		elseif roomId == "CaveEntrance" then
			self.discoveryService:Unlock(player, Constants.Discoveries.CaveEntered.Id)
		elseif roomId == "Island" then
			self.discoveryService:Unlock(player, Constants.Discoveries.ReachedIsland.Id)
		elseif roomId == "TopDownArena" then
			self.discoveryService:Unlock(player, Constants.Discoveries.TopDownEntered.Id)
		elseif roomId == "TreetopZipline" then
			self.discoveryService:Unlock(player, Constants.Discoveries.TreetopZiplineEntered.Id)
		elseif roomId == "SpaceStation" then
			self.discoveryService:Unlock(player, Constants.Discoveries.SpaceStationEntered.Id)
		elseif roomId == "Void" then
			self.discoveryService:Unlock(player, Constants.Discoveries.VoidEntered.Id)
		elseif roomId == "Infirmary" then
			self.discoveryService:Unlock(player, Constants.Discoveries.InfirmaryEntered.Id)
		elseif roomId == "Gym" then
			self.discoveryService:Unlock(player, Constants.Discoveries.GymEntered.Id)
		end
		if not self:IsUntouchedProloguePending(player) then
			self.discoveryService:SetContinueRoomId(player, roomId, true)
		end
	else
		local delta = math.max(0, now - (state.LastRoomTickAt or now))
		if not self:IsUntouchedProloguePending(player) then
			state.RoomPlaySecondsByRoomId[roomId] = (state.RoomPlaySecondsByRoomId[roomId] or 0) + delta
		end
		state.LastRoomTickAt = now
	end

	local room = Constants.GetRoom(roomId)
	if not room then
		self:_sendRoomStatus(player, now)
		return
	end

	if self:IsUntouchedProloguePending(player) then
		self:_sendRoomStatus(player, now)
		return
	end

	local elapsed = now - state.TimerStartedAt
	local totalPlay = state.RoomPlaySecondsByRoomId[roomId] or 0
	self:_tickRoomPlayRewards(player, roomId, totalPlay, state)
	self:_sendRoomStatus(player, now)
	self:_updateNoTouchWorldClocks(roomId, elapsed, totalPlay)

	if room.NoTouchDiscoveryId
		and elapsed >= Constants.NoTouch.AccomplishmentSeconds
		and not state.TwoMinuteAwarded[roomId]
	then
		state.TwoMinuteAwarded[roomId] = true
		self.discoveryService:Unlock(player, room.NoTouchDiscoveryId)
		self.systemMessageRemote:FireClient(player, "Well done, you didn't touch anything for a while!")
	end

	if elapsed >= Constants.NoTouch.BonusSeconds and not state.BonusAwarded[roomId] then
		state.BonusAwarded[roomId] = true
		self.discoveryService:GrantHints(player, Constants.NoTouch.BonusHintCount)
		self.systemMessageRemote:FireClient(player, "Super bonus: 10 free hints for impressive restraint.")
	end

	self:_tickSparkle(player, roomId, now, state)
end

function RoomProgressService:_sendRoomStatus(player, now)
	local areaId = self:GetAreaForPlayer(player)

	if areaId == Constants.Hallway.Id then
		self.roomStatusRemote:FireClient(player, {
			Type = "Hallway",
			Name = Constants.Hallway.Name,
			UnlockedRooms = self.discoveryService:GetUnlockedRoomCount(player),
			TotalRooms = Constants.Hallway.TotalRoomCount,
		})
		return
	end

	if areaId then
		local snapshot = self.discoveryService:GetRoomSnapshot(player, areaId)
		if snapshot then
			local state = self:_getState(player)
			local elapsed = 0
			if state.CurrentRoomId == areaId then
				elapsed = math.max(0, (now or os.clock()) - state.TimerStartedAt)
			end

			self.roomStatusRemote:FireClient(player, {
				Type = "Room",
				RoomId = snapshot.RoomId,
				RoomName = snapshot.RoomName,
				Count = snapshot.Count,
				Total = snapshot.Total,
				NoTouchElapsed = elapsed,
				NoTouchTarget = Constants.NoTouch.AccomplishmentSeconds,
				TotalPlaySeconds = state.RoomPlaySecondsByRoomId[areaId] or 0,
			})
			return
		end
	end

	self.roomStatusRemote:FireClient(player, {
		Type = "None",
	})
end

function RoomProgressService:GetTrackedPlaySeconds(player)
	if not player or not player.Parent then
		return 0
	end

	local state = self:_getState(player)
	local total = 0

	for _, seconds in pairs(state.RoomPlaySecondsByRoomId or {}) do
		if typeof(seconds) == "number" then
			total += math.max(0, seconds)
		end
	end

	if state.CurrentRoomId and not self:IsUntouchedProloguePending(player) then
		local lastTickAt = state.LastRoomTickAt or state.TimerStartedAt
		if typeof(lastTickAt) == "number" then
			total += math.max(0, os.clock() - lastTickAt)
		end
	end

	return math.floor(total)
end

function RoomProgressService:_tickRoomPlayRewards(player, roomId, totalPlay, state)
	local earnedCount = math.floor(totalPlay / Constants.RoomPlay.HintIntervalSeconds)
	local awardedCount = state.RoomPlayRewardsByRoomId[roomId] or 0

	if earnedCount <= awardedCount then
		return
	end

	local rewardCount = earnedCount - awardedCount
	local hintTotal = rewardCount * Constants.RoomPlay.HintsPerInterval
	state.RoomPlayRewardsByRoomId[roomId] = earnedCount
	self.discoveryService:GrantHints(player, hintTotal)

	local room = Constants.GetRoom(roomId)
	self.systemMessageRemote:FireClient(
		player,
		("Room time bonus: %d free hint%s for staying in %s."):format(
			hintTotal,
			hintTotal == 1 and "" or "s",
			room and room.Name or "the room"
		)
	)
end

function RoomProgressService:_updateNoTouchWorldClocks(roomId, elapsed, totalPlay)
	local text = ("Still %.1f / %.1fm\nRoom %.1fm"):format(
		elapsed / 60,
		Constants.NoTouch.AccomplishmentSeconds / 60,
		totalPlay / 60
	)

	for _, clock in ipairs(CollectionService:GetTagged(Constants.Tags.NoTouchClock)) do
		if clock:GetAttribute("RoomId") == roomId then
			local label = clock:FindFirstChild("ClockText", true)
			if label and label:IsA("TextLabel") then
				label.Text = text
			end
		end
	end
end

function RoomProgressService:_tickSparkle(player, roomId, now, state)
	local sparkleState = state.SparkleStateByRoomId[roomId]
	if not sparkleState then
		sparkleState = {
			NextSparkleAt = now + Constants.Sparkle.FirstDelaySeconds,
		}
		state.SparkleStateByRoomId[roomId] = sparkleState
	end

	if now < sparkleState.NextSparkleAt then
		return
	end

	sparkleState.NextSparkleAt = now + Constants.Sparkle.IntervalSeconds

	local _, targetTag = self.discoveryService:GetNextPendingHighlight(player, roomId)
	if not targetTag then
		return
	end

	local target = self:_findHighlightTarget(targetTag)
	if not target then
		return
	end

	self.sparkleRemote:FireClient(player, {
		Target = target,
		Duration = Constants.Sparkle.DurationSeconds,
	})
end

function RoomProgressService:_findHighlightTarget(targetTag)
	for _, instance in ipairs(CollectionService:GetTagged(targetTag)) do
		if instance and instance.Parent then
			return instance
		end
	end

	return nil
end

function RoomProgressService:_handleHintRequest(player, payload)
	if typeof(payload) ~= "table" then
		return
	end

	local action = payload.Action
	local roomId = payload.RoomId

	if action == "OpenRoomMenu" then
		local mode = payload.Mode
		self.systemMessageRemote:FireClient(player, ("Opening %s controls."):format(tostring(mode or "room")))
		if mode == "Store" then
			self:ShowStore(player, roomId)
		elseif mode == "Teleport" then
			self:ShowTeleportMenu(player, roomId)
		elseif mode == "Field" then
			self:ShowFieldControls(player, roomId)
		else
			self:ShowReferenceBook(player, roomId)
		end
	elseif action == "BuyPack" then
		self:_requestHintPack(player, roomId)
	elseif action == "FreeHint" then
		local hintText, errorText = self.discoveryService:GetFreeHint(player, roomId)
		self:_showHintResult(player, roomId, hintText, errorText)
	elseif action == "BuyClue" then
		self:_requestCluePurchase(player, roomId)
	elseif action == "Clue" or action == "PaidHint" or action == "UseHint" then
		self:_requestClue(player, roomId)
	elseif action == "BuyReveal" then
		self:_requestDiscoveryRevealPurchase(player, roomId)
	elseif action == "Reveal" or action == "FullReveal" then
		self:_requestDiscoveryReveal(player, roomId)
	elseif action == "RevealSecretDoor" then
		self:_requestSecretDoorReveal(player, roomId)
	elseif action == "BuySecretKey" then
		self:_requestSecretKey(player, roomId)
	elseif action == "BuyTeleportKey" then
		self:_requestTeleportKey(player, roomId)
	elseif action == "TeleportRoom" then
		self:_requestTeleportRoom(player, roomId, payload.TargetRoomId)
	elseif action == "FieldEffect" then
		self:_requestFieldEffect(player, roomId, payload.EffectId)
	end
end

function RoomProgressService:_runLowGravityFromField(player)
	if workspace.Gravity <= 50 then
		self.systemMessageRemote:FireClient(player, "The field is already light enough to make furniture suspicious.")
		return
	end

	task.spawn(function()
		local ok, errorMessage = pcall(function()
			LowGravityEvent.Run({
				DiscoveryService = self.discoveryService,
				Players = Players:GetPlayers(),
				BroadcastMessage = function(text)
					self.systemMessageRemote:FireAllClients(text)
				end,
			})
		end)

		if not ok then
			warn("[RoomProgressService] Field low gravity failed:", errorMessage)
			if player.Parent then
				self.systemMessageRemote:FireClient(player, "The field control tries to lower gravity, then thinks better of it.")
			end
		end
	end)
end

function RoomProgressService:_applyPlayerScaleField(player, scale, discoveryId, label, message)
	local snapshot = PlayerScale.ApplyTemporary(player, scale, Constants.SizeTransformDuration or Constants.EventDuration)
	if not snapshot then
		self.systemMessageRemote:FireClient(player, "The field control hums, but your character refuses to recalibrate.")
		return
	end

	if self.transformCameraRemote then
		self.transformCameraRemote:FireClient(player, {
			Action = "SizeTransform",
			Scale = scale,
			Duration = Constants.SizeTransformCameraDuration or 3,
			Label = label,
		})
	end

	if self.discoveryService and discoveryId then
		self.discoveryService:Unlock(player, discoveryId)
	end

	self.systemMessageRemote:FireClient(player, message)
end

function RoomProgressService:_requestFieldEffect(player, roomId, effectId)
	local fieldControl = self:_getFieldControl(effectId)
	if not fieldControl then
		self.systemMessageRemote:FireClient(player, "That field setting is not wired yet.")
		return
	end

	if not self:_isFieldControlUnlocked(player, fieldControl) then
		self.systemMessageRemote:FireClient(player, "That field capability has not been unlocked yet.")
		return
	end

	if effectId == "LowGravity" then
		self:_runLowGravityFromField(player)
	elseif effectId == "FloorGone" then
		if self.eventManager then
			local triggered = self.eventManager:TriggerById(player, "floor_gone")
			if not triggered then
				self.systemMessageRemote:FireClient(player, "The floor control tries to comply, but the room is busy.")
			end
		else
			self.systemMessageRemote:FireClient(player, "The floor control is not connected to anything sensible yet.")
		end
	elseif effectId == "TinyPlayer" then
		self:_applyPlayerScaleField(
			player,
			0.45,
			Constants.Discoveries.TinyPlayers.Id,
			"Tiny mode",
			"Field control engaged: travel-size. RESET can end it early."
		)
	elseif effectId == "GiantPlayer" then
		self:_applyPlayerScaleField(
			player,
			2.25,
			Constants.Discoveries.GiantPlayer.Id,
			"Giant mode",
			"Field control engaged: problem-size. RESET can end it early."
		)
	else
		self.systemMessageRemote:FireClient(player, "That field setting is not wired yet.")
	end
end

function RoomProgressService:_showHintResult(player, roomId, hintText, errorText)
	local messageText = hintText or errorText or "No hint available."

	self:ShowReferenceBook(player, roomId, {
		HintText = hintText,
		StatusText = errorText,
	})
	self.systemMessageRemote:FireClient(player, messageText)
end

function RoomProgressService:_promptHintProduct(player, roomId, productId, action)
	self.pendingHintPurchaseByUserId[player.UserId] = {
		Action = action,
		RoomId = roomId,
		ProductId = productId,
	}

	local ok = pcall(function()
		MarketplaceService:PromptProductPurchase(player, productId)
	end)

	if not ok then
		self.pendingHintPurchaseByUserId[player.UserId] = nil
		self.systemMessageRemote:FireClient(player, "That hint purchase is not ready in this test build.")
	end
end

function RoomProgressService:_requestClue(player, roomId)
	local productId = Constants.NoTouch.ClueProductId
	if not productId or productId <= 0 then
		productId = Constants.NoTouch.PaidHintProductId
	end

	if productId and productId > 0 then
		self:_promptHintProduct(player, roomId, productId, "Clue")
		return
	end

	local hintText, errorText = self.discoveryService:UseClue(player, roomId, self:GetStorePrice("ClueHintCost"))
	self:_showHintResult(player, roomId, hintText, errorText)
end

function RoomProgressService:_requestCluePurchase(player, roomId)
	local productId = Constants.NoTouch.ClueProductId
	if not productId or productId <= 0 then
		productId = Constants.NoTouch.PaidHintProductId
	end

	if productId and productId > 0 then
		self:_promptHintProduct(player, roomId, productId, "Clue")
		return
	end

	local hintText, errorText = self.discoveryService:UseClue(player, roomId, 0, true)
	self:_showHintResult(
		player,
		roomId,
		hintText,
		errorText or "Prototype clue purchase added. Currently free; no Robux charged."
	)
end

function RoomProgressService:_requestDiscoveryReveal(player, roomId)
	local productId = Constants.NoTouch.RevealProductId
	if not productId or productId <= 0 then
		productId = Constants.NoTouch.FullRevealProductId
	end

	if productId and productId > 0 then
		self:_promptHintProduct(player, roomId, productId, "Reveal")
		return
	end

	local revealText, targetTag, errorText = self.discoveryService:UseLocationReveal(player, roomId, self:GetStorePrice("RevealClueCost"))
	self:_showHintResult(player, roomId, revealText, errorText)

	if revealText and targetTag then
		local target = self:_findHighlightTarget(targetTag)
		if target then
			self.sparkleRemote:FireClient(player, {
				Target = target,
				Duration = math.max(Constants.Sparkle.DurationSeconds, 8),
			})
		end
	end
end

function RoomProgressService:_requestDiscoveryRevealPurchase(player, roomId)
	local productId = Constants.NoTouch.RevealProductId
	if not productId or productId <= 0 then
		productId = Constants.NoTouch.FullRevealProductId
	end

	if productId and productId > 0 then
		self:_promptHintProduct(player, roomId, productId, "Reveal")
		return
	end

	local revealText, targetTag, errorText = self.discoveryService:UseLocationReveal(player, roomId, 0, true)
	self:_showHintResult(
		player,
		roomId,
		revealText,
		errorText or "Prototype reveal purchase added. Currently free; no Robux charged."
	)

	if revealText and targetTag then
		local target = self:_findHighlightTarget(targetTag)
		if target then
			self.sparkleRemote:FireClient(player, {
				Target = target,
				Duration = math.max(Constants.Sparkle.DurationSeconds, 8),
			})
		end
	end
end

function RoomProgressService:_requestHintPack(player, roomId)
	local productId = Constants.NoTouch.HintPackProductId

	if productId and productId > 0 then
		local ok = pcall(function()
			MarketplaceService:PromptProductPurchase(player, productId)
		end)

		if not ok then
			self.systemMessageRemote:FireClient(player, "Hint purchase is not ready in this test build.")
		end
		return
	end

	local packSize = self:GetStorePrice("HintPackSize") or Constants.NoTouch.HintPackSize or 10
	self.discoveryService:GrantHints(player, packSize)
	self:ShowReferenceBook(player, roomId, {
		Mode = "Store",
		StatusText = ("Prototype hint pack added: %d hints. Currently free; no Robux charged."):format(packSize),
	})
	self.systemMessageRemote:FireClient(player, ("Prototype hint pack added: %d hints. Currently free; no Robux charged."):format(packSize))
end

function RoomProgressService:_requestSecretDoorReveal(player, roomId)
	local config = Constants.SecretDoors and Constants.SecretDoors[roomId]
	if not config then
		self:_showHintResult(player, roomId, nil, "This room does not have a secret door yet.")
		return
	end

	if self.discoveryService:CanSeeSecretDoor(player, roomId) then
		self:_showHintResult(player, roomId, nil, "The Library outline is already visible. Finish the room, then bring the key.")
		return
	end

	local productId = config.RevealProductId
	if productId and productId > 0 then
		self:_promptHintProduct(player, roomId, productId, "SecretDoorReveal")
		return
	end

	local cost = math.max(0, config.RevealHintCost or 0)
	local ok, errorText = self.discoveryService:SpendHints(player, cost)
	if not ok then
		self:_showHintResult(
			player,
			roomId,
			nil,
			("Library outline reveal needs %d hints, or you can complete the room normally for free."):format(cost)
		)
		return
	end

	self.discoveryService:RevealSecretDoor(player, roomId, "Library outline revealed early. Finish the room to activate it.")
	self:ShowReferenceBook(player, roomId, {
		StatusText = ("Library outline revealed for %d hints. Finish the room, then bring the Library Key."):format(cost),
	})
end

function RoomProgressService:_requestSecretKey(player, roomId)
	local config = Constants.SecretDoors and Constants.SecretDoors[roomId]
	if not config then
		self:_showHintResult(player, roomId, nil, "This room does not have a Library key yet.")
		return
	end

	if self.discoveryService:HasSecretKey(player, roomId) then
		self:_showHintResult(player, roomId, nil, "You already have the Library Key.")
		return
	end

	if not self.discoveryService:IsRoomComplete(player, roomId) then
		self:_showHintResult(player, roomId, nil, "Finish the room before rushing the Library Key.")
		return
	end

	local cost = math.max(0, self:GetStorePrice("SecretKeyClueCost") or Constants.NoTouch.SecretKeyClueCost or Constants.NoTouch.RevealClueCost or 3)
	local ok = self.discoveryService:SpendClues(player, cost)
	if not ok then
		self:_showHintResult(player, roomId, nil, ("Library Key rush needs %d clues."):format(cost))
		return
	end

	self.discoveryService:GrantSecretKey(player, roomId, "Library Key purchased for one reveal's worth of clues.")
	self:ShowReferenceBook(player, roomId, {
		StatusText = ("Library Key purchased for %d clues."):format(cost),
	})
end

function RoomProgressService:_requestTeleportKey(player, roomId)
	if self.discoveryService:HasTeleportKey(player) then
		self:_showHintResult(player, roomId, nil, "You already have the Teleport Key.")
		return
	end

	if not self.discoveryService:IsRoomUnlocked(player, "Library") then
		self:_showHintResult(player, roomId, nil, "Teleport Key rush unlocks after you open the Library.")
		return
	end

	local cost = math.max(0, self:GetStorePrice("TeleportKeyClueCost") or Constants.NoTouch.TeleportKeyClueCost or 3)
	local ok = self.discoveryService:SpendClues(player, cost)
	if not ok then
		self:_showHintResult(player, roomId, nil, ("Teleport Key rush needs %d clues."):format(cost))
		return
	end

	self.discoveryService:GrantTeleportKey(player, "Teleport Key purchased. Controls can now jump to opened rooms.")
	self:ShowReferenceBook(player, roomId, {
		Mode = "Store",
		StatusText = ("Teleport Key purchased for %d clues."):format(cost),
	})
end

function RoomProgressService:_requestTeleportRoom(player, sourceRoomId, targetRoomId)
	if typeof(targetRoomId) ~= "string" then
		self:_showHintResult(player, sourceRoomId, nil, "That teleport destination does not exist.")
		return
	end

	if not self.discoveryService:HasTeleportKey(player) then
		self:_showHintResult(player, sourceRoomId, nil, "The Teleport Key is still missing from your inventory.")
		return
	end

	local room = Constants.GetRoom(targetRoomId)
	if room then
		if not self.discoveryService:IsRoomUnlocked(player, targetRoomId) then
			self:_showHintResult(player, sourceRoomId, nil, "Teleport only accepts rooms you have already opened.")
			return
		end

		local destinationCFrame = Constants.GetRoomSpawnCFrame(targetRoomId)
		if self:_teleportPlayer(player, destinationCFrame, "TeleportKey") then
			self:RememberContinueDestination(player, targetRoomId, destinationCFrame, true)
			self.systemMessageRemote:FireClient(player, ("Teleport Key moved you to %s."):format(room.Name or "the room"))
		end
		return
	end

	local place = Constants.GetNamedPlace and Constants.GetNamedPlace(targetRoomId)
	if place then
		local requirement = place.RequiresDiscoveryId
		if requirement and not self.discoveryService:HasDiscovery(player, requirement) then
			self:_showHintResult(player, sourceRoomId, nil, "Those coordinates have not been learned yet.")
			return
		end

		local destinationCFrame = Constants.GetNamedPlaceCFrame(targetRoomId)
		if self:_teleportPlayer(player, destinationCFrame, "TeleportKey") then
			self:RememberContinueDestination(player, targetRoomId, destinationCFrame, true)
			self.systemMessageRemote:FireClient(player, ("Teleport Key moved you to %s."):format(place.Name or "the coordinates"))
		end
		return
	end

	self:_showHintResult(player, sourceRoomId, nil, "That teleport destination does not exist.")
end

function RoomProgressService:_installReceiptHandler()
	local hintPackProductId = Constants.NoTouch.HintPackProductId
	local paidHintProductId = Constants.NoTouch.ClueProductId
	if not paidHintProductId or paidHintProductId <= 0 then
		paidHintProductId = Constants.NoTouch.PaidHintProductId
	end
	local fullRevealProductId = Constants.NoTouch.RevealProductId
	if not fullRevealProductId or fullRevealProductId <= 0 then
		fullRevealProductId = Constants.NoTouch.FullRevealProductId
	end
	local secretDoorProductById = {}

	for roomId, config in pairs(Constants.SecretDoors or {}) do
		local productId = config.RevealProductId
		if productId and productId > 0 then
			secretDoorProductById[productId] = roomId
		end
	end

	if (not hintPackProductId or hintPackProductId <= 0)
		and (not paidHintProductId or paidHintProductId <= 0)
		and (not fullRevealProductId or fullRevealProductId <= 0)
		and next(secretDoorProductById) == nil
	then
		return
	end

	local previousProcessReceipt = MarketplaceService.ProcessReceipt

	MarketplaceService.ProcessReceipt = function(receiptInfo)
		if receiptInfo.ProductId == hintPackProductId then
			local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
			if not player then
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end

			local packSize = self:GetStorePrice("HintPackSize") or Constants.NoTouch.HintPackSize or 10
			self.discoveryService:GrantHints(player, packSize)
			self.systemMessageRemote:FireClient(player, ("Hint pack added: %d hints."):format(packSize))
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		if receiptInfo.ProductId == paidHintProductId or receiptInfo.ProductId == fullRevealProductId then
			local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
			if not player then
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end

			local pending = self.pendingHintPurchaseByUserId[player.UserId]
			self.pendingHintPurchaseByUserId[player.UserId] = nil

			if not pending or pending.ProductId ~= receiptInfo.ProductId then
				self.systemMessageRemote:FireClient(player, "Hint purchase completed, but the room log lost its place.")
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end

			local hintText = nil
			local errorText = nil
			if pending.Action == "Reveal" or pending.Action == "FullReveal" then
				local targetTag = nil
				hintText, targetTag, errorText = self.discoveryService:UseLocationReveal(player, pending.RoomId, 0, true)
				if hintText and targetTag then
					local target = self:_findHighlightTarget(targetTag)
					if target then
						self.sparkleRemote:FireClient(player, {
							Target = target,
							Duration = math.max(Constants.Sparkle.DurationSeconds, 8),
						})
					end
				end
			else
				hintText, errorText = self.discoveryService:UseClue(player, pending.RoomId, 0, true)
			end

			self:_showHintResult(player, pending.RoomId, hintText, errorText)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		local secretDoorRoomId = secretDoorProductById[receiptInfo.ProductId]
		if secretDoorRoomId then
			local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
			if not player then
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end

			self.discoveryService:RevealSecretDoor(player, secretDoorRoomId, "Library outline revealed early. Finish the room to activate it.")
			self:ShowReferenceBook(player, secretDoorRoomId, {
				StatusText = "Library outline revealed. Finish the room, then bring the Library Key.",
			})
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		if previousProcessReceipt then
			return previousProcessReceipt(receiptInfo)
		end

		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

return RoomProgressService
