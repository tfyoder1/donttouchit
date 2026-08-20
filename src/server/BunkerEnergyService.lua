local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local RemoteService = require(script.Parent:WaitForChild("RemoteService"))

local BunkerEnergyService = {}
BunkerEnergyService.__index = BunkerEnergyService

local DIM_COLOR = Color3.fromRGB(4, 7, 10)
local SIGNAL_BAND_ATTRIBUTE = "DontTouchItSignalBandEquipped"
local SIGNAL_BAND_NAME = "DontTouchItSignalBand"

local EXCLUDED_ANCESTOR_NAMES = {
	IslandRoom = true,
	SpaceStationRoom = true,
}

local EXCLUDED_LIGHT_NAMES = {
	CaveAlarmPointLight = true,
	CaveBulbLight = true,
	ColdIdeaLight = true,
	DiscoLight = true,
	FridgeInteriorLight = true,
	IslandCampfireLight = true,
	IslandSunLight = true,
	LampLight = true,
	LibraryLampLight = true,
}

local function hasExcludedAncestor(instance)
	local current = instance
	while current and current ~= workspace do
		if current:GetAttribute("BunkerEnergyIgnored") or EXCLUDED_ANCESTOR_NAMES[current.Name] then
			return true
		end
		if CollectionService:HasTag(current, Constants.Tags.TemporaryObject) then
			return true
		end
		current = current.Parent
	end

	return false
end

local function getBaseColor(part)
	return part:GetAttribute("BunkerEnergyBaseColor") or part:GetAttribute("BaseColor") or part.Color
end

local function getBaseTransparency(part)
	local transparency = part:GetAttribute("BunkerEnergyBaseTransparency")
	if transparency ~= nil then
		return transparency
	end

	transparency = part:GetAttribute("BaseTransparency")
	if transparency ~= nil then
		return transparency
	end

	return part.Transparency
end

local function isLight(instance)
	return instance:IsA("PointLight") or instance:IsA("SpotLight") or instance:IsA("SurfaceLight")
end

local function getRootPart(player)
	local character = player and player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(player)
	local character = player and player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function getPlayerGui(player)
	return player and player:FindFirstChildOfClass("PlayerGui")
end

local function setSignalBandAttribute(player)
	player:SetAttribute(SIGNAL_BAND_ATTRIBUTE, true)

	local playerGui = getPlayerGui(player)
	if playerGui then
		playerGui:SetAttribute(SIGNAL_BAND_ATTRIBUTE, true)
	end
end

local function findSignalBandArm(character)
	return character:FindFirstChild("LeftLowerArm")
		or character:FindFirstChild("Left Arm")
		or character:FindFirstChild("RightLowerArm")
		or character:FindFirstChild("Right Arm")
end

local function equipSignalBand(player)
	setSignalBandAttribute(player)

	local character = player.Character
	if not character or character:FindFirstChild(SIGNAL_BAND_NAME, true) then
		return
	end

	local arm = findSignalBandArm(character)
	if not arm or not arm:IsA("BasePart") then
		return
	end

	local band = Instance.new("Part")
	band.Name = SIGNAL_BAND_NAME
	band.Shape = Enum.PartType.Cylinder
	band.Size = Vector3.new(0.62, 0.24, 0.62)
	band.Color = Color3.fromRGB(18, 23, 29)
	band.Material = Enum.Material.Metal
	band.CanCollide = false
	band.CanQuery = false
	band.CanTouch = false
	band.Massless = true
	band.CFrame = arm.CFrame * CFrame.new(0, -arm.Size.Y * 0.18, 0)
	band.Parent = character

	local bandWeld = Instance.new("WeldConstraint")
	bandWeld.Name = "SignalBandWeld"
	bandWeld.Part0 = arm
	bandWeld.Part1 = band
	bandWeld.Parent = band

	local readout = Instance.new("Part")
	readout.Name = "SignalBandReadout"
	readout.Size = Vector3.new(0.09, 0.18, 0.34)
	readout.Color = Color3.fromRGB(119, 255, 203)
	readout.Material = Enum.Material.Neon
	readout.CanCollide = false
	readout.CanQuery = false
	readout.CanTouch = false
	readout.Massless = true
	readout.CFrame = band.CFrame * CFrame.new(0, 0, -0.34)
	readout.Parent = band

	local readoutWeld = Instance.new("WeldConstraint")
	readoutWeld.Name = "SignalBandReadoutWeld"
	readoutWeld.Part0 = band
	readoutWeld.Part1 = readout
	readoutWeld.Parent = readout
end

function BunkerEnergyService.new(discoveryService, movementAuthorityService)
	local self = setmetatable({}, BunkerEnergyService)
	self.discoveryService = discoveryService
	self.movementAuthorityService = movementAuthorityService
	self.systemMessageRemote = RemoteService.GetRemote(Constants.Remotes.SystemMessage)
	self.recoveryRemote = RemoteService.GetRemote(Constants.Remotes.NourishmentRecovery)
	self.neonParts = {}
	self.staticLights = {}
	self.fruitReliefUntilByUserId = {}
	self.feedRepeatByUserId = {}
	self.lastFeedSummaryByUserId = {}
	self.playerActivityByUserId = {}
	self.playerEnergyByUserId = {}
	self.recoveryPoseByUserId = {}
	self.worldPowerCharge = (Constants.BunkerEnergy.WorldPowerChargeCapacity or 28)
		* (Constants.BunkerEnergy.InitialWorldPowerCharge or 0.9)
	self.lastPowerChargeUpdatedAt = os.clock()
	self.lastVisualPower = nil
	self.visualApplyQueued = false
	return self
end

function BunkerEnergyService:Initialize()
	self:_captureVisualTargets()
	self:_applyAll()

	if self.discoveryService and self.discoveryService.DiscoveryUnlocked then
		self.discoveryService.DiscoveryUnlocked:Connect(function(player)
			self:_addFeedValue(player, Constants.BunkerEnergy.DiscoveryFeed or 0.75, "Discovery", "Discovery")
			self:_addPlayerActivity(player, Constants.BunkerEnergy.PlayerActivityPerDiscovery or 0.18)
			self:_changePlayerEnergy(player, -(Constants.BunkerEnergy.DiscoveryEnergyCost or 0.014))
			self:_queueApplyAll()
			self:_applyPlayerEnergy(player, self:_calculateWorldPower())
		end)
	end

	local function setupPlayer(player)
		player.CharacterAdded:Connect(function()
			task.delay(0.2, function()
				if not player.Parent then
					return
				end

				local state = self.playerEnergyByUserId[player.UserId]
				if state and state.Recovering then
					self:_placePlayerOnRecoveryBed(player)
				else
					player:SetAttribute("DontTouchItRecoveryActive", false)
					self:_setRecoveryAnchored(player, false)
				end
				if player:GetAttribute(SIGNAL_BAND_ATTRIBUTE) == true then
					equipSignalBand(player)
				end
				self:_applyPlayerEnergy(player, self:_calculateWorldPower())
			end)
		end)

		task.delay(1.25, function()
			if player.Parent then
				self:_queueApplyAll()
				self:_applyPlayerEnergy(player, self:_calculateWorldPower())
			end
		end)
	end

	Players.PlayerAdded:Connect(setupPlayer)

	Players.PlayerRemoving:Connect(function(player)
		self.fruitReliefUntilByUserId[player.UserId] = nil
		self.feedRepeatByUserId[player.UserId] = nil
		self.lastFeedSummaryByUserId[player.UserId] = nil
		self.playerActivityByUserId[player.UserId] = nil
		self.playerEnergyByUserId[player.UserId] = nil
		self.recoveryPoseByUserId[player.UserId] = nil
		task.delay(0.5, function()
			self:_queueApplyAll()
		end)
	end)

	task.spawn(function()
		local interval = Constants.BunkerEnergy.UpdateIntervalSeconds or 4
		while true do
			task.wait(interval)
			self:_applyAll()
		end
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end
end

function BunkerEnergyService:_captureVisualTargets()
	table.clear(self.neonParts)
	table.clear(self.staticLights)

	for _, instance in ipairs(workspace:GetDescendants()) do
		if instance:IsA("BasePart") then
			if instance.Material == Enum.Material.Neon and not hasExcludedAncestor(instance) then
				instance:SetAttribute("BunkerEnergyBaseColor", getBaseColor(instance))
				instance:SetAttribute("BunkerEnergyBaseTransparency", getBaseTransparency(instance))
				table.insert(self.neonParts, instance)
			end
		elseif isLight(instance) then
			local baseBrightness = instance:GetAttribute("BaseBrightness") or instance.Brightness
			if baseBrightness > 0
				and not EXCLUDED_LIGHT_NAMES[instance.Name]
				and not hasExcludedAncestor(instance)
			then
				instance:SetAttribute("BunkerEnergyBaseBrightness", baseBrightness)
				instance:SetAttribute("BunkerEnergyBaseRange", instance:GetAttribute("BaseRange") or instance.Range)
				table.insert(self.staticLights, instance)
			end
		end
	end
end

function BunkerEnergyService:_queueApplyAll()
	if self.visualApplyQueued then
		return
	end

	self.visualApplyQueued = true
	task.delay(0.15, function()
		self.visualApplyQueued = false
		self:_applyAll()
	end)
end

function BunkerEnergyService:_decayWorldPowerCharge(now)
	now = now or os.clock()
	local decaySeconds = math.max(1, Constants.BunkerEnergy.WorldPowerDecaySeconds or 420)
	local elapsed = math.max(0, now - (self.lastPowerChargeUpdatedAt or now))
	if elapsed > 0 then
		self.worldPowerCharge = math.max(0, (self.worldPowerCharge or 0) * math.exp(-elapsed / decaySeconds))
		self.lastPowerChargeUpdatedAt = now
	end

	return self.worldPowerCharge or 0
end

function BunkerEnergyService:_addWorldPower(amount)
	local capacity = math.max(1, Constants.BunkerEnergy.WorldPowerChargeCapacity or 28)
	local charge = self:_decayWorldPowerCharge()
	self.worldPowerCharge = math.clamp(charge + math.max(0, tonumber(amount) or 0), 0, capacity)
	self.lastPowerChargeUpdatedAt = os.clock()
	return self.worldPowerCharge
end

function BunkerEnergyService:_getFeedEfficiencyMultiplier(worldPower)
	worldPower = math.clamp(tonumber(worldPower) or self:_calculateWorldPower(), 0, 1)

	if worldPower <= (Constants.BunkerEnergy.BunkerCriticalThreshold or 0.25) then
		return Constants.BunkerEnergy.CriticalFeedMultiplier or 1.5
	end

	if worldPower <= (Constants.BunkerEnergy.BunkerHungryThreshold or 0.49) then
		return Constants.BunkerEnergy.HungryFeedMultiplier or 1.25
	end

	return 1
end

function BunkerEnergyService:_getRepeatFeedMultiplier(player, actionKey, now)
	if not player or not player.Parent or actionKey == nil or actionKey == "" then
		return 1, 0
	end

	now = now or os.clock()
	local userRepeats = self.feedRepeatByUserId[player.UserId]
	if not userRepeats then
		userRepeats = {}
		self.feedRepeatByUserId[player.UserId] = userRepeats
	end

	local resetSeconds = math.max(1, Constants.BunkerEnergy.RepeatResetSeconds or 120)
	local decay = math.clamp(Constants.BunkerEnergy.RepeatFeedDecay or 0.1, 0, 0.95)
	local record = userRepeats[actionKey]
	local repeatCount = 0

	if record and now - (record.UpdatedAt or 0) <= resetSeconds then
		repeatCount = math.max(0, math.floor(tonumber(record.Count) or 0)) + 1
	end

	userRepeats[actionKey] = {
		Count = repeatCount,
		UpdatedAt = now,
	}

	return (1 - decay) ^ repeatCount, repeatCount
end

function BunkerEnergyService:_addFeedValue(player, feedValue, source, actionKey, options)
	feedValue = math.max(0, tonumber(feedValue) or 0)
	if feedValue <= 0 then
		return 0
	end

	options = options or {}
	local now = os.clock()
	local repeatMultiplier = 1
	local repeatCount = 0
	if options.IgnoreRepetition ~= true then
		repeatMultiplier, repeatCount = self:_getRepeatFeedMultiplier(player, actionKey or source, now)
	end

	local worldPower = self:_calculateWorldPower(now)
	local hungerMultiplier = self:_getFeedEfficiencyMultiplier(worldPower)
	local conversion = math.max(0, Constants.BunkerEnergy.FeedPowerConversion or 0.08)
	local convertedPower = feedValue * repeatMultiplier * hungerMultiplier * conversion

	self.lastFeedSummaryByUserId[player and player.UserId or 0] = {
		Source = source or "Unknown",
		ActionKey = actionKey or source or "Unknown",
		FeedValue = feedValue,
		ConvertedPower = convertedPower,
		RepeatCount = repeatCount,
		RepeatMultiplier = repeatMultiplier,
		HungerMultiplier = hungerMultiplier,
		UpdatedAt = now,
	}

	self:_addWorldPower(convertedPower)
	return convertedPower
end

function BunkerEnergyService:_calculateProgressLoad(player)
	local total = math.max(1, Constants.TotalDiscoveries or 1)

	if player then
		local count = self.discoveryService and self.discoveryService:GetDiscoveryCount(player) or 0
		return math.clamp(count / total, 0, 1)
	end

	local highestProgress = 0

	for _, player in ipairs(Players:GetPlayers()) do
		if not self.discoveryService or not self.discoveryService.IsLoaded or self.discoveryService:IsLoaded(player) then
			local count = self.discoveryService and self.discoveryService:GetDiscoveryCount(player) or 0
			highestProgress = math.max(highestProgress, count / total)
		end
	end

	return math.clamp(highestProgress, 0, 1)
end

function BunkerEnergyService:_calculateWorldPower(now)
	local capacity = math.max(1, Constants.BunkerEnergy.WorldPowerChargeCapacity or 28)
	local charge = self:_decayWorldPowerCharge(now)
	local rawPower = math.clamp(charge / capacity, 0, 1)
	local shapedPower = rawPower ^ (Constants.BunkerEnergy.WorldPowerExponent or 0.68)
	local minimum = Constants.BunkerEnergy.MinimumVisualPower or 0.18

	return math.clamp(minimum + (1 - minimum) * shapedPower, minimum, 1)
end

function BunkerEnergyService:_calculateBunkerHunger(worldPower, player)
	local minimum = Constants.BunkerEnergy.MinimumVisualPower or 0.18
	local normalized = math.clamp((worldPower - minimum) / math.max(0.05, 1 - minimum), 0, 1)
	local underfed = 1 - normalized
	local progressLoad = self:_calculateProgressLoad(player)
	local underfedHunger = (underfed ^ (Constants.BunkerEnergy.BunkerHungerExponent or 1.2))
		* (Constants.BunkerEnergy.BunkerHungerUnderfedWeight or 0.78)
	local progressHunger = (progressLoad ^ 1.08)
		* (Constants.BunkerEnergy.BunkerHungerProgressWeight or 0.58)
		* (0.35 + underfed * 0.65)
	return math.clamp(underfedHunger + progressHunger, 0, 1)
end

function BunkerEnergyService:_getPlayerEnergyState(player, now)
	if not player or not player.Parent then
		return nil
	end

	now = now or os.clock()
	local state = self.playerEnergyByUserId[player.UserId]
	if not state then
		state = {
			Energy = Constants.BunkerEnergy.InitialPlayerEnergy or 1,
			UpdatedAt = now,
			LastPosition = nil,
			LastLowWarningAt = 0,
			LastEnticementAt = 0,
			CriticalSince = nil,
			Recovering = false,
			RecoveryCount = 0,
		}
		self.playerEnergyByUserId[player.UserId] = state
	end

	return state
end

function BunkerEnergyService:_setPlayerEnergyAttributes(player, energy, hunger, drainRate)
	if not player or not player.Parent then
		return
	end

	player:SetAttribute("DontTouchItPlayerEnergy", energy)
	player:SetAttribute("DontTouchItBunkerHunger", hunger or 0)
	player:SetAttribute("DontTouchItBunkerDrainRate", drainRate or 0)

	local playerGui = getPlayerGui(player)
	if playerGui then
		playerGui:SetAttribute("DontTouchItPlayerEnergy", energy)
		playerGui:SetAttribute("DontTouchItBunkerHunger", hunger or 0)
		playerGui:SetAttribute("DontTouchItBunkerDrainRate", drainRate or 0)
	end
end

function BunkerEnergyService:_maybeWarnLowEnergy(player, state)
	if not player or not player.Parent or not state then
		return
	end

	local threshold = Constants.BunkerEnergy.LowEnergyWarningThreshold or 0.24
	if (state.Energy or 1) > threshold then
		return
	end

	local now = os.clock()
	local cooldown = Constants.BunkerEnergy.LowEnergyWarningCooldownSeconds or 36
	if now - (state.LastLowWarningAt or 0) < cooldown then
		return
	end

	state.LastLowWarningAt = now
	self.systemMessageRemote:FireClient(player, "Energy is low. Pocketed fruit or loose matter can help; nearby lights may react.")
end

function BunkerEnergyService:_maybeEnticeInactivePlayer(player, state, hunger, now)
	if not player or not player.Parent or not state then
		return
	end

	local threshold = Constants.BunkerEnergy.InactivityEnticementHungerThreshold or 0.64
	if (hunger or 0) < threshold then
		return
	end

	local cooldown = Constants.BunkerEnergy.InactivityEnticementCooldownSeconds or 85
	if now - (state.LastEnticementAt or 0) < cooldown then
		return
	end

	local activity = self:_getDecayedPlayerActivity(player, now)
	if activity > 0.06 then
		return
	end

	state.LastEnticementAt = now
	local messages = {
		"A nearby indicator blinks once, then pretends it did not.",
		"Something in the wall clicks softly, almost like a polite suggestion.",
		"A dark control light wakes for a moment, then settles back down.",
	}
	local index = math.floor(now) % #messages + 1
	self.systemMessageRemote:FireClient(player, messages[index])
end

function BunkerEnergyService:_setRecoveryAnchored(player, anchored)
	local rootPart = getRootPart(player)
	if rootPart then
		rootPart.Anchored = anchored == true
		if anchored then
			rootPart.AssemblyLinearVelocity = Vector3.zero
			rootPart.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

function BunkerEnergyService:_getRecoveryBed()
	for _, instance in ipairs(CollectionService:GetTagged(Constants.Tags.InfirmaryRecoveryBed)) do
		if instance:IsA("BasePart") and instance:IsDescendantOf(workspace) then
			return instance
		end
	end

	return nil
end

function BunkerEnergyService:_getRecoveryBedCFrames()
	local bed = self:_getRecoveryBed()
	if bed then
		local lieCFrame = bed.CFrame * CFrame.new(0, 1.55, 0) * CFrame.Angles(0, 0, math.rad(90))
		local standPosition = (bed.CFrame * CFrame.new(-6.8, 3.05, 0)).Position
		local lookTarget = Vector3.new(bed.Position.X, standPosition.Y, bed.Position.Z)
		local standCFrame = CFrame.new(standPosition, lookTarget)
		return lieCFrame, standCFrame
	end

	local fallback = Constants.GetRoomSpawnCFrame("Infirmary") + Vector3.new(0, 2.6, 0)
	return fallback, fallback
end

function BunkerEnergyService:_placePlayerOnRecoveryBed(player)
	local rootPart = getRootPart(player)
	if not rootPart then
		return false
	end

	local humanoid = getHumanoid(player)
	if humanoid then
		if not self.recoveryPoseByUserId[player.UserId] then
			self.recoveryPoseByUserId[player.UserId] = {
				AutoRotate = humanoid.AutoRotate,
				PlatformStand = humanoid.PlatformStand,
			}
		end
		humanoid.AutoRotate = false
		humanoid.PlatformStand = true
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	end

	local lieCFrame = self:_getRecoveryBedCFrames()
	rootPart.Anchored = true
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
	rootPart.CFrame = lieCFrame
	return true
end

function BunkerEnergyService:_standPlayerFromRecoveryBed(player)
	local rootPart = getRootPart(player)
	if not rootPart then
		return false
	end

	local _, standCFrame = self:_getRecoveryBedCFrames()
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
	rootPart.CFrame = standCFrame

	local humanoid = getHumanoid(player)
	if humanoid then
		local savedPose = self.recoveryPoseByUserId[player.UserId]
		humanoid.PlatformStand = if savedPose and savedPose.PlatformStand ~= nil then savedPose.PlatformStand else false
		humanoid.AutoRotate = if savedPose and savedPose.AutoRotate ~= nil then savedPose.AutoRotate else true
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end

	self.recoveryPoseByUserId[player.UserId] = nil
	return true
end

function BunkerEnergyService:_teleportToInfirmary(player)
	if self:_placePlayerOnRecoveryBed(player) then
		return true
	end

	local destination = Constants.GetRoomSpawnCFrame("Infirmary")
	if self.movementAuthorityService and self.movementAuthorityService.TeleportPlayer then
		return self.movementAuthorityService:TeleportPlayer(player, destination, "NourishmentRecovery")
	end

	local rootPart = getRootPart(player)
	if rootPart then
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
		rootPart.CFrame = destination + Vector3.new(0, 2.6, 0)
		return true
	end

	return false
end

function BunkerEnergyService:_beginPassOut(player, state, reason)
	if not player or not player.Parent or not state or state.Recovering then
		return false
	end

	state.Recovering = true
	state.CriticalSince = nil
	state.RecoveryCount = (state.RecoveryCount or 0) + 1
	local firstRecovery = state.RecoveryCount == 1
	player:SetAttribute("DontTouchItRecoveryActive", true)

	local fadeOut = Constants.BunkerEnergy.RecoveryFadeOutSeconds or 2.1
	local black = Constants.BunkerEnergy.RecoveryBlackSeconds or 2
	local fadeIn = Constants.BunkerEnergy.RecoveryFadeInSeconds or 2.2
	if not firstRecovery then
		fadeOut *= 0.72
		fadeIn *= 0.75
	end
	black = math.max(2, black)
	local recoveryMessage = if firstRecovery then "Emergency nourishment authorized." else "Condition stabilized."
	self.recoveryRemote:FireClient(player, {
		Action = "PassOut",
		Reason = tostring(reason or "CriticalEnergy"),
		FadeOutSeconds = fadeOut,
		BlackSeconds = black,
		FadeInSeconds = fadeIn,
		Message = recoveryMessage,
		FirstRecovery = firstRecovery,
		BeepSoundId = Constants.BunkerEnergy.RecoveryBeepSoundId,
		BeepVolume = Constants.BunkerEnergy.RecoveryBeepVolume,
	})

	self:_setRecoveryAnchored(player, true)
	task.delay(math.max(0.35, fadeOut + 0.18), function()
		if not player.Parent then
			return
		end

		self:_teleportToInfirmary(player)
		state.Energy = Constants.BunkerEnergy.RecoveryEnergyBaseline or 0.46
		state.UpdatedAt = os.clock()
		state.LastPosition = nil
		state.LastLowWarningAt = 0
		state.LastEnticementAt = os.clock()
		self:_setPlayerEnergyAttributes(player, state.Energy, self:_calculateBunkerHunger(self:_calculateWorldPower(), player), 0)
		self:_applyPlayerEnergy(player, self:_calculateWorldPower())

		if firstRecovery then
			equipSignalBand(player)
			self.systemMessageRemote:FireClient(
				player,
				"Emergency nourishment authorized. Signal Band fitted: monitor your energy and the information it decides to show you."
			)
		else
			self.systemMessageRemote:FireClient(player, "Condition stabilized.")
		end
	end)

	task.delay(math.max(1, fadeOut + black + fadeIn + 0.5), function()
		if not player.Parent then
			return
		end
		state.Recovering = false
		player:SetAttribute("DontTouchItRecoveryActive", false)
		self:_standPlayerFromRecoveryBed(player)
		self:_setRecoveryAnchored(player, false)
		self:_applyPlayerEnergy(player, self:_calculateWorldPower())
	end)

	return true
end

function BunkerEnergyService:_changePlayerEnergy(player, delta, options)
	local state = self:_getPlayerEnergyState(player)
	if not state then
		return 0
	end

	state.Energy = math.clamp((state.Energy or 1) + (tonumber(delta) or 0), 0, 1)
	state.UpdatedAt = os.clock()
	if state.Energy > (Constants.BunkerEnergy.PassOutThreshold or 0.025) then
		state.CriticalSince = nil
	end
	self:_setPlayerEnergyAttributes(
		player,
		state.Energy,
		options and options.Hunger or player:GetAttribute("DontTouchItBunkerHunger") or 0,
		options and options.DrainRate or player:GetAttribute("DontTouchItBunkerDrainRate") or 0
	)
	if not (options and options.SuppressLowWarning) then
		self:_maybeWarnLowEnergy(player, state)
	end

	return state.Energy
end

function BunkerEnergyService:_updatePlayerEnergyDrain(player, worldPower, now)
	local state = self:_getPlayerEnergyState(player, now)
	if not state then
		return 1
	end

	local elapsed = math.clamp(now - (state.UpdatedAt or now), 0, (Constants.BunkerEnergy.UpdateIntervalSeconds or 4) * 2.5)
	local rootPart = getRootPart(player)
	local distance = 0
	if rootPart then
		local lastPosition = state.LastPosition
		if typeof(lastPosition) == "Vector3" then
			local delta = rootPart.Position - lastPosition
			distance = math.min(
				Vector3.new(delta.X, 0, delta.Z).Magnitude,
				Constants.BunkerEnergy.MaxTrackedWalkDistancePerUpdate or 80
			)
		end
		state.LastPosition = rootPart.Position
	end

	local hunger = self:_calculateBunkerHunger(worldPower, player)
	local drainThreshold = Constants.BunkerEnergy.BunkerPlayerDrainHungerThreshold or 0.34
	local drainPressure = math.clamp((hunger - drainThreshold) / math.max(0.05, 1 - drainThreshold), 0, 1)
	local passiveDrain = (Constants.BunkerEnergy.PassiveDrainPerSecond or 0.00018) * elapsed
	local bunkerDrain = (Constants.BunkerEnergy.BunkerDrainPerSecond or 0.00072) * drainPressure * elapsed
	local walkingDrain = distance
		* (Constants.BunkerEnergy.WalkingDrainPerStud or 0.000018)
		* (1 + drainPressure * (Constants.BunkerEnergy.WalkingDrainHungerMultiplier or 0.7))
	local totalDrain = passiveDrain + bunkerDrain + walkingDrain

	if totalDrain > 0 then
		state.Energy = math.clamp((state.Energy or 1) - totalDrain, 0, 1)
	end
	state.UpdatedAt = now

	local drainRate = if elapsed > 0 then totalDrain / elapsed else 0
	self:_setPlayerEnergyAttributes(player, state.Energy, hunger, drainRate)
	self:_maybeWarnLowEnergy(player, state)
	self:_maybeEnticeInactivePlayer(player, state, hunger, now)
	if not state.Recovering then
		local passOutThreshold = Constants.BunkerEnergy.PassOutThreshold or 0.025
		if (state.Energy or 1) <= passOutThreshold then
			state.CriticalSince = state.CriticalSince or now
			if now - state.CriticalSince >= (Constants.BunkerEnergy.PassOutCriticalSeconds or 8) then
				self:_beginPassOut(player, state, "CriticalEnergy")
			end
		else
			state.CriticalSince = nil
		end
	end
	return state.Energy
end

function BunkerEnergyService:_applyVisualPower(power)
	for index = #self.neonParts, 1, -1 do
		local part = self.neonParts[index]
		if not part or not part.Parent then
			table.remove(self.neonParts, index)
		else
			local baseColor = getBaseColor(part)
			local baseTransparency = getBaseTransparency(part)
			local dimBlend = (Constants.BunkerEnergy.NeonDimBlend or 0.72) * (1 - power)
			local transparencyLift = (Constants.BunkerEnergy.NeonExtraTransparency or 0.22) * (1 - power)

			part.Color = baseColor:Lerp(DIM_COLOR, dimBlend)
			part.Transparency = if baseTransparency >= 0.98
				then 1
				else math.clamp(baseTransparency + (1 - baseTransparency) * transparencyLift, 0, 0.94)
		end
	end

	for index = #self.staticLights, 1, -1 do
		local light = self.staticLights[index]
		if not light or not light.Parent then
			table.remove(self.staticLights, index)
		else
			local baseBrightness = light:GetAttribute("BunkerEnergyBaseBrightness") or light:GetAttribute("BaseBrightness") or light.Brightness
			local baseRange = light:GetAttribute("BunkerEnergyBaseRange") or light:GetAttribute("BaseRange") or light.Range
			if light.Enabled and light.Brightness > 0.03 and baseBrightness > 0 then
				local minimumLight = Constants.BunkerEnergy.LightMinimumPower or 0.26
				local multiplier = minimumLight + (1 - minimumLight) * power
				light.Brightness = baseBrightness * multiplier
				light.Range = baseRange * (0.78 + 0.22 * power)
			end
		end
	end

	self.lastVisualPower = power
end

function BunkerEnergyService:_applyPowerMeters(power)
	local hunger = self:_calculateBunkerHunger(power)
	local percent = math.floor(math.clamp(power, 0, 1) * 100 + 0.5)
	local hungerPercent = math.floor(math.clamp(hunger, 0, 1) * 100 + 0.5)
		local stateText = "QUIET"
		local fillColor = Color3.fromRGB(119, 255, 203)
		local statusText = "STANDBY FIELD"

		if hunger >= 0.82 then
			stateText = "IRREGULAR"
			fillColor = Color3.fromRGB(255, 88, 128)
			statusText = "MATTER SIGNAL UNSTABLE"
		elseif hunger >= 0.58 then
			stateText = "STRAY SIGNAL"
			fillColor = Color3.fromRGB(255, 163, 92)
			statusText = "ROOM GRID SEEKING LOCK"
		elseif hunger >= 0.32 then
			stateText = "LISTENING"
			fillColor = Color3.fromRGB(255, 232, 92)
			statusText = "FIELD DRAW ACCEPTABLE"
	end

	for _, meter in ipairs(CollectionService:GetTagged(Constants.Tags.BunkerPowerMeter)) do
		if meter and meter.Parent then
			local root = meter
			local readout = root:FindFirstChild("BunkerPowerMeterReadout", true)
			local state = root:FindFirstChild("BunkerPowerMeterState", true)
			local status = root:FindFirstChild("BunkerPowerMeterStatus", true)
			local fill = root:FindFirstChild("BunkerPowerMeterFillFrame", true)
			local glow = root:FindFirstChild("BunkerPowerMeterGlow", true)

			if readout and readout:IsA("TextLabel") then
				readout.Text = ("POWER %d%%"):format(percent)
				readout.TextColor3 = fillColor
			end
			if state and state:IsA("TextLabel") then
				state.Text = ("DRAW: %s %d%%"):format(stateText, hungerPercent)
				state.TextColor3 = fillColor
			end
			if status and status:IsA("TextLabel") then
				status.Text = statusText
			end
			if fill and fill:IsA("Frame") then
				fill.Size = UDim2.fromScale(math.clamp(power, 0.04, 1), 1)
				fill.BackgroundColor3 = fillColor
			end
			if glow and isLight(glow) then
				glow.Color = fillColor
				glow.Brightness = 0.45 + math.clamp(power, 0, 1) * 1.35
			end
		end
	end
end

function BunkerEnergyService:_getDecayedPlayerActivity(player, now)
	if not player then
		return 0
	end

	local entry = self.playerActivityByUserId[player.UserId]
	if not entry then
		return 0
	end

	now = now or os.clock()
	local decaySeconds = math.max(1, Constants.BunkerEnergy.PlayerActivityDecaySeconds or 210)
	local elapsed = math.max(0, now - (entry.UpdatedAt or now))
	local decayed = math.clamp((entry.Power or 0) * math.exp(-elapsed / decaySeconds), 0, 1)

	entry.Power = decayed
	entry.UpdatedAt = now

	if decayed <= 0.002 then
		self.playerActivityByUserId[player.UserId] = nil
		return 0
	end

	return decayed
end

function BunkerEnergyService:_addPlayerActivity(player, amount)
	if not player or not player.Parent then
		return 0
	end

	local now = os.clock()
	local current = self:_getDecayedPlayerActivity(player, now)
	local entry = self.playerActivityByUserId[player.UserId]
	if not entry then
		entry = {
			Power = current,
			UpdatedAt = now,
		}
		self.playerActivityByUserId[player.UserId] = entry
	end

	entry.Power = math.clamp(current + math.max(0, amount or 0), 0, 1)
	entry.UpdatedAt = now
	return entry.Power
end

function BunkerEnergyService:_calculatePlayerPerception(player, worldPower)
	local total = math.max(1, Constants.TotalDiscoveries or 1)
	local count = self.discoveryService and self.discoveryService:GetDiscoveryCount(player) or 0
	local progress = math.clamp(count / total, 0, 1)
	local activity = self:_getDecayedPlayerActivity(player)
	local progressBonus = (Constants.BunkerEnergy.PersonalProgressLightBonus or 0.16) * (progress ^ 0.85)
	local activityBonus = (Constants.BunkerEnergy.MaxPersonalLightBonus or 0.34) * (activity ^ 0.72)
	local personalBonus = math.clamp(progressBonus + activityBonus, 0, Constants.BunkerEnergy.MaxPersonalLightBonus or 0.34)
	local personalPower = math.clamp(worldPower + personalBonus, worldPower, 1)
	local personalGlow = math.clamp(personalBonus / math.max(0.05, Constants.BunkerEnergy.MaxPersonalLightBonus or 0.34), 0, 1)

	return personalPower, personalGlow
end

function BunkerEnergyService:_applyPlayerEnergy(player, worldPower)
	if not player or not player.Parent or not self.movementAuthorityService then
		return
	end

	local energyState = self:_getPlayerEnergyState(player)
	local energy = energyState and energyState.Energy or 1
	local total = math.max(1, Constants.TotalDiscoveries or 1)
	local count = self.discoveryService and self.discoveryService:GetDiscoveryCount(player) or 0
	local progress = math.clamp(count / total, 0, 1)
	local maxPenalty = Constants.BunkerEnergy.MaxSpeedPenalty or 0.16
	local fatigue = maxPenalty * ((1 - energy) ^ 0.85)
	local progressFatigue = (Constants.BunkerEnergy.ProgressSpeedPenalty or 0.035) * (progress ^ 1.2)
	local relief = 0
	local now = os.clock()
	local reliefUntil = self.fruitReliefUntilByUserId[player.UserId] or 0

	if reliefUntil > now then
		local duration = Constants.BunkerEnergy.FruitRecoverySeconds or 150
		local remaining = math.clamp((reliefUntil - now) / math.max(1, duration), 0, 1)
		relief = (Constants.BunkerEnergy.FruitSpeedRelief or 0.11) * (remaining ^ 0.65)
	end

	local minimumScale = Constants.BunkerEnergy.MinimumSpeedScale or 0.84
	local speedScale = math.clamp(1 - fatigue - progressFatigue + relief, minimumScale, 1)
	local personalPower, personalGlow = self:_calculatePlayerPerception(player, worldPower)
	self.movementAuthorityService:SetBunkerEnergy(player, speedScale, worldPower, personalPower, personalGlow)
end

function BunkerEnergyService:_applyAll()
	local now = os.clock()
	local power = self:_calculateWorldPower()
	self:_applyVisualPower(power)
	self:_applyPowerMeters(power)

	for _, player in ipairs(Players:GetPlayers()) do
		self:_updatePlayerEnergyDrain(player, power, now)
		self:_applyPlayerEnergy(player, power)
	end
end

function BunkerEnergyService:GetWorldPower()
	return self:_calculateWorldPower()
end

function BunkerEnergyService:GetSubsystemPower()
	local power = self:_calculateWorldPower()
	local minimum = Constants.BunkerEnergy.MinimumVisualPower or 0.18
	return math.clamp((power - minimum) / math.max(0.05, 1 - minimum), 0, 1)
end

function BunkerEnergyService:GetBunkerHunger(player)
	return self:_calculateBunkerHunger(self:_calculateWorldPower(), player)
end

function BunkerEnergyService:GetDevState(player)
	local state = self:_getPlayerEnergyState(player)
	local worldPower = self:_calculateWorldPower()
	return {
		PlayerEnergy = state and state.Energy or 1,
		WorldPower = worldPower,
		BunkerHunger = self:_calculateBunkerHunger(worldPower, player),
		FeedEfficiencyMultiplier = self:_getFeedEfficiencyMultiplier(worldPower),
		LastFeed = player and self.lastFeedSummaryByUserId[player.UserId] or nil,
		Recovering = state and state.Recovering == true or false,
		RecoveryCount = state and state.RecoveryCount or 0,
	}
end

function BunkerEnergyService:SetPlayerEnergyForDev(player, energy)
	if not player or not player.Parent then
		return false
	end

	local state = self:_getPlayerEnergyState(player)
	if not state then
		return false
	end

	state.Energy = math.clamp(tonumber(energy) or state.Energy or 1, 0, 1)
	state.UpdatedAt = os.clock()
	state.CriticalSince = nil
	local wasRecovering = state.Recovering == true
	state.Recovering = false
	player:SetAttribute("DontTouchItRecoveryActive", false)
	if wasRecovering then
		self:_standPlayerFromRecoveryBed(player)
	end
	self:_setRecoveryAnchored(player, false)
	self:_setPlayerEnergyAttributes(player, state.Energy, self:_calculateBunkerHunger(self:_calculateWorldPower(), player), 0)
	self:_applyPlayerEnergy(player, self:_calculateWorldPower())
	return true
end

function BunkerEnergyService:SetWorldPowerForDev(power)
	local capacity = math.max(1, Constants.BunkerEnergy.WorldPowerChargeCapacity or 28)
	local targetPower = math.clamp(tonumber(power) or 0, 0, 1)
	local minimum = Constants.BunkerEnergy.MinimumVisualPower or 0.18
	local exponent = math.max(0.001, Constants.BunkerEnergy.WorldPowerExponent or 0.68)
	local normalized = 0

	if targetPower > minimum then
		normalized = math.clamp((targetPower - minimum) / math.max(0.001, 1 - minimum), 0, 1) ^ (1 / exponent)
	end

	self.worldPowerCharge = capacity * normalized
	self.lastPowerChargeUpdatedAt = os.clock()
	self.visualApplyQueued = false
	self:_applyAll()
	return true
end

function BunkerEnergyService:TriggerPassOutForDev(player)
	local state = self:_getPlayerEnergyState(player)
	if not state then
		return false
	end

	state.Energy = 0
	state.CriticalSince = os.clock()
	self:_setPlayerEnergyAttributes(player, state.Energy, self:_calculateBunkerHunger(self:_calculateWorldPower(), player), 0)
	return self:_beginPassOut(player, state, "DevPassOut")
end

function BunkerEnergyService:RestoreHealthyStateForDev(player)
	if not self:SetPlayerEnergyForDev(player, 1) then
		return false
	end

	self:_addPlayerActivity(player, 0.5)
	self:_addWorldPower(3.5)
	self:_queueApplyAll()
	return true
end

function BunkerEnergyService:SimulateProlongedInactivityForDev(player)
	if player and player.Parent then
		self.playerActivityByUserId[player.UserId] = {
			Power = 0,
			UpdatedAt = os.clock() - math.max(240, Constants.BunkerEnergy.PlayerActivityDecaySeconds or 210),
		}
	end

	self:SetWorldPowerForDev(0.04)
	return true
end

function BunkerEnergyService:RecordInteraction(player)
	if not player or not player.Parent then
		return
	end

	self:_addFeedValue(player, Constants.BunkerEnergy.BaseActionFeed or 0.25, "Action", "Interaction")
	self:_addPlayerActivity(player, Constants.BunkerEnergy.PlayerActivityPerInteraction or 0.095)
	self:_changePlayerEnergy(player, -(Constants.BunkerEnergy.PlayerActionEnergyCost or 0.005))
	self:_queueApplyAll()
	self:_applyPlayerEnergy(player, self:_calculateWorldPower())
end

function BunkerEnergyService:RecordTrainingActivity(player, chargeAmount, playerEnergyCost)
	if not player or not player.Parent then
		return
	end

	self:_addFeedValue(player, chargeAmount or Constants.BunkerEnergy.BaseActionFeed or 0.25, "Training", "Training")
	self:_addPlayerActivity(player, Constants.BunkerEnergy.PlayerActivityPerInteraction or 0.095)
	self:_changePlayerEnergy(player, -(playerEnergyCost or 0.003), {
		SuppressLowWarning = true,
	})
	self:_queueApplyAll()
	self:_applyPlayerEnergy(player, self:_calculateWorldPower())
end

function BunkerEnergyService:RecordFruitEaten(player, restoreAmount)
	if not player or not player.Parent then
		return
	end

	local now = os.clock()
	local duration = Constants.BunkerEnergy.FruitRecoverySeconds or 150
	self.fruitReliefUntilByUserId[player.UserId] = math.max(self.fruitReliefUntilByUserId[player.UserId] or 0, now) + duration
	self:_addFeedValue(player, Constants.BunkerEnergy.FruitConsumedBunkerFeed or 5, "FoodEaten", "FoodEaten", {
		IgnoreRepetition = true,
	})
	self:_addPlayerActivity(player, Constants.BunkerEnergy.PlayerActivityPerFruit or 0.16)
	self:_changePlayerEnergy(player, restoreAmount or Constants.BunkerEnergy.FruitEnergyRestore or 0.32, {
		SuppressLowWarning = true,
	})
	self:_queueApplyAll()
	self:_applyPlayerEnergy(player, self:_calculateWorldPower())
end

function BunkerEnergyService:RecordEnergyItemUsed(player, kind, restoreAmount)
	if not player or not player.Parent then
		return
	end

	local amount = restoreAmount
	if amount == nil then
		if kind == "Popcorn" then
			amount = Constants.BunkerEnergy.PopcornEnergyRestore or 0.12
		elseif kind == "Cola" then
			amount = Constants.BunkerEnergy.ColaEnergyRestore or 0.24
		elseif kind == "Matter" then
			amount = Constants.BunkerEnergy.MatterEnergyRestore or 0.18
		else
			amount = Constants.BunkerEnergy.FruitEnergyRestore or 0.32
		end
	end

	local baseline = math.max(0.01, Constants.BunkerEnergy.FruitEnergyRestore or 0.32)
	self:_addFeedValue(player, (Constants.BunkerEnergy.FruitConsumedBunkerFeed or 5) * math.clamp(amount / baseline, 0.25, 1.1), "EnergyItemUsed", kind or "EnergyItem", {
		IgnoreRepetition = true,
	})
	self:_addPlayerActivity(player, Constants.BunkerEnergy.PlayerActivityPerFruit or 0.16)
	self:_changePlayerEnergy(player, amount, {
		SuppressLowWarning = true,
	})
	self:_queueApplyAll()
	self:_applyPlayerEnergy(player, self:_calculateWorldPower())
end

function BunkerEnergyService:_countPocketEnergyItems(player)
	local count = 0
	local function countContainer(container)
		if not container then
			return
		end

		for _, item in ipairs(container:GetChildren()) do
			if item:IsA("Tool")
				and (item:GetAttribute("DontTouchItEnergyReserve") == true or item:GetAttribute("DontTouchItPocketItem") == true)
			then
				count += 1
			end
		end
	end

	countContainer(player:FindFirstChildOfClass("Backpack"))
	countContainer(player.Character)
	return count
end

function BunkerEnergyService:_getEnergyReserveStackLimit()
	return math.max(1, Constants.BunkerEnergy.EnergyReserveStackLimit or 10)
end

function BunkerEnergyService:_getStackableTool(player, attributeName, kindAttributeName, kind, stackLimit)
	local function findInContainer(container)
		if not container then
			return nil
		end

		for _, item in ipairs(container:GetChildren()) do
			if item:IsA("Tool")
				and item:GetAttribute(attributeName) == true
				and item:GetAttribute(kindAttributeName) == kind
			then
				local stackCount = math.max(1, math.floor(tonumber(item:GetAttribute("PocketStackCount") or item:GetAttribute("EnergyReserveStackCount")) or 1))
				if stackCount < stackLimit then
					return item, stackCount
				end
			end
		end

		return nil
	end

	local backpackTool, backpackCount = findInContainer(player:FindFirstChildOfClass("Backpack"))
	if backpackTool then
		return backpackTool, backpackCount
	end

	return findInContainer(player.Character)
end

function BunkerEnergyService:_getEnergyReserveBaseName(options, kind)
	return options.Name or if kind == "Matter" then "Pocketed Matter" elseif kind == "Popcorn" then "Pocketed Popcorn" else "Pocketed Fruit"
end

function BunkerEnergyService:_updateStackedToolName(tool, baseAttributeName, stackAttributeName)
	if not tool then
		return
	end

	local baseName = tool:GetAttribute(baseAttributeName) or tool.Name
	local stackCount = math.max(1, math.floor(tonumber(tool:GetAttribute(stackAttributeName)) or 1))
	tool.Name = if stackCount > 1 then ("%s x%d"):format(baseName, stackCount) else baseName
end

function BunkerEnergyService:_updateEnergyReserveToolName(tool)
	self:_updateStackedToolName(tool, "EnergyReserveBaseName", "EnergyReserveStackCount")
end

function BunkerEnergyService:_updatePocketItemToolName(tool)
	self:_updateStackedToolName(tool, "PocketItemBaseName", "PocketStackCount")
end

function BunkerEnergyService:_getEquippedInventoryTool(player)
	local character = player and player.Character
	if not character then
		return nil
	end

	for _, item in ipairs(character:GetChildren()) do
		if item:IsA("Tool")
			and item.Enabled ~= false
			and (item:GetAttribute("DontTouchItEnergyReserve") == true or item:GetAttribute("DontTouchItPocketItem") == true)
		then
			return item
		end
	end

	return nil
end

function BunkerEnergyService:_getToolHandleSnapshot(tool)
	local handle = tool and tool:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		return {}
	end

	return {
		Color = handle.Color,
		Material = handle.Material,
		Size = handle.Size,
		Shape = handle.Shape,
	}
end

function BunkerEnergyService:_consumeOneFromStackedTool(tool, stackAttributeName, kind)
	local stackCount = math.max(1, math.floor(tonumber(tool:GetAttribute(stackAttributeName)) or 1)) - 1
	if stackCount <= 0 then
		tool.Enabled = false
		Debris:AddItem(tool, 0.1)
		return
	end

	tool:SetAttribute(stackAttributeName, stackCount)
	if kind == "EnergyReserve" then
		self:_updateEnergyReserveToolName(tool)
	else
		self:_updatePocketItemToolName(tool)
	end
end

function BunkerEnergyService:_findStackableEnergyReserveTool(player, kind)
	local stackLimit = self:_getEnergyReserveStackLimit()
	return self:_getStackableTool(player, "DontTouchItEnergyReserve", "EnergyReserveKind", kind, stackLimit)
end

function BunkerEnergyService:_buildEnergyReserveToolVisual(tool, options)
	local kind = options.Kind or "Fruit"
	local color = options.Color or if kind == "Matter" then Color3.fromRGB(119, 255, 203) else Color3.fromRGB(255, 134, 35)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Anchored = false
	handle.CanCollide = false
	handle.Massless = true
	handle.Material = if kind == "Matter" then Enum.Material.Neon else Enum.Material.SmoothPlastic
	handle.Color = color
	handle.Size = if kind == "Popcorn" then Vector3.new(0.55, 0.46, 0.55) else Vector3.new(0.82, 0.82, 0.82)
	handle.Shape = Enum.PartType.Ball
	handle.Parent = tool

	if kind ~= "Popcorn" then
		local cap = Instance.new("Part")
		cap.Name = "ReserveCap"
		cap.Anchored = false
		cap.CanCollide = false
		cap.Massless = true
		cap.Material = Enum.Material.SmoothPlastic
		cap.Color = if kind == "Matter" then Color3.fromRGB(236, 246, 255) else Color3.fromRGB(72, 96, 46)
		cap.Size = Vector3.new(0.18, 0.34, 0.18)
		cap.CFrame = handle.CFrame * CFrame.new(0, 0.48, 0)
		cap.Parent = tool

		local weld = Instance.new("WeldConstraint")
		weld.Name = "ReserveCapWeld"
		weld.Part0 = handle
		weld.Part1 = cap
		weld.Parent = cap
	end

	tool.Grip = CFrame.new(0, -0.2, 0)
end

function BunkerEnergyService:_buildPocketItemToolVisual(tool, options)
	local kind = options.Kind or "Item"
	local color = options.Color or if kind == "IslandRock" then Color3.fromRGB(112, 113, 111) else Color3.fromRGB(129, 82, 45)
	local defaultMaterial = if kind == "IslandRock" then Enum.Material.Slate else Enum.Material.Wood
	local defaultSize = if kind == "IslandRock" then Vector3.new(0.85, 0.72, 0.85) else Vector3.new(0.48, 0.42, 1.8)
	local defaultShape = if kind == "IslandRock" then Enum.PartType.Ball else Enum.PartType.Block

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Anchored = false
	handle.CanCollide = false
	handle.Massless = true
	handle.Material = options.Material or defaultMaterial
	handle.Color = color
	handle.Size = options.Size or defaultSize
	handle.Shape = options.Shape or defaultShape
	handle.Parent = tool

	if kind == "IslandWood" then
		for index, xOffset in ipairs({ -0.42, 0.42 }) do
			local band = Instance.new("Part")
			band.Name = "WoodBand" .. index
			band.Anchored = false
			band.CanCollide = false
			band.Massless = true
			band.Material = Enum.Material.SmoothPlastic
			band.Color = Color3.fromRGB(84, 54, 34)
			band.Size = Vector3.new(0.08, 0.48, 0.52)
			band.CFrame = handle.CFrame * CFrame.new(xOffset, 0, 0)
			band.Parent = tool

			local weld = Instance.new("WeldConstraint")
			weld.Name = "WoodBandWeld" .. index
			weld.Part0 = handle
			weld.Part1 = band
			weld.Parent = band
		end
	end

	tool.Grip = if kind == "IslandWood" then CFrame.new(0, -0.2, 0) * CFrame.Angles(0, math.rad(90), 0) else CFrame.new(0, -0.2, 0)
end

function BunkerEnergyService:GetPocketItemSlotCount(player)
	if not player or not player.Parent then
		return 0
	end

	return self:_countPocketEnergyItems(player)
end

function BunkerEnergyService:DropOneEquippedInventoryItem(player)
	if not player or not player.Parent then
		return false, nil, "No player found for that inventory action."
	end

	local tool = self:_getEquippedInventoryTool(player)
	if not tool then
		return false, nil, "Hold a pocket item before dropping it."
	end

	local visual = self:_getToolHandleSnapshot(tool)
	if tool:GetAttribute("DontTouchItPocketItem") == true then
		local kind = tool:GetAttribute("PocketItemKind") or "Item"
		local baseName = tool:GetAttribute("PocketItemBaseName") or tool.Name
		local itemData = {
			InventoryType = "PocketItem",
			Kind = kind,
			Name = baseName,
			ToolTip = tool.ToolTip,
			Color = visual.Color,
			Material = visual.Material,
			Size = visual.Size,
			Shape = visual.Shape,
			StackLimit = math.max(1, math.floor(tonumber(tool:GetAttribute("PocketStackLimit")) or Constants.BunkerEnergy.EnergyReserveStackLimit or 10)),
		}

		self:_consumeOneFromStackedTool(tool, "PocketStackCount", "PocketItem")
		return true, itemData
	end

	if tool:GetAttribute("DontTouchItEnergyReserve") == true then
		local kind = tool:GetAttribute("EnergyReserveKind") or "Fruit"
		local baseName = tool:GetAttribute("EnergyReserveBaseName") or self:_getEnergyReserveBaseName({}, kind)
		local itemData = {
			InventoryType = "EnergyReserve",
			Kind = kind,
			Name = baseName,
			ToolTip = tool.ToolTip,
			Color = visual.Color,
			Material = visual.Material,
			Size = visual.Size,
			Shape = visual.Shape,
			RestoreAmount = tonumber(tool:GetAttribute("EnergyRestoreAmount")) or Constants.BunkerEnergy.FruitEnergyRestore or 0.32,
		}

		self:_consumeOneFromStackedTool(tool, "EnergyReserveStackCount", "EnergyReserve")
		return true, itemData
	end

	return false, nil, "That item refuses to leave your hand."
end

function BunkerEnergyService:GrantPocketItemTool(player, options)
	if not player or not player.Parent then
		return false, "No player found for that pocket."
	end

	options = options or {}
	local backpack = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack", 2)
	if not backpack then
		return false, "Your backpack is missing. The room denies involvement."
	end

	local kind = options.Kind or "Item"
	local baseName = options.Name or if kind == "IslandRock" then "Beach Rock" elseif kind == "IslandWood" then "Driftwood" else "Pocketed Item"
	local stackLimit = math.max(1, options.StackLimit or Constants.BunkerEnergy.EnergyReserveStackLimit or 10)
	local existingTool, currentStack = self:_getStackableTool(player, "DontTouchItPocketItem", "PocketItemKind", kind, stackLimit)
	if existingTool then
		local nextStack = math.clamp((currentStack or 1) + 1, 1, stackLimit)
		existingTool:SetAttribute("PocketStackCount", nextStack)
		existingTool:SetAttribute("PocketStackLimit", stackLimit)
		existingTool:SetAttribute("PocketItemBaseName", existingTool:GetAttribute("PocketItemBaseName") or baseName)
		self:_updatePocketItemToolName(existingTool)
		return true, options.GrantMessage or ("%s stacked to x%d."):format(baseName, nextStack)
	end

	local maxItems = Constants.BunkerEnergy.MaxPocketEnergyItems or 5
	if self:_countPocketEnergyItems(player) >= maxItems then
		return false, ("Your pockets are full. You can only carry %d stacked pocket items."):format(maxItems)
	end

	local tool = Instance.new("Tool")
	tool.Name = baseName
	tool.ToolTip = options.ToolTip or "A suspiciously useful thing you picked up."
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool:SetAttribute("DontTouchItPocketItem", true)
	tool:SetAttribute("PocketItemKind", kind)
	tool:SetAttribute("PocketItemBaseName", baseName)
	tool:SetAttribute("PocketStackCount", 1)
	tool:SetAttribute("PocketStackLimit", stackLimit)
	self:_buildPocketItemToolVisual(tool, options)
	self:_updatePocketItemToolName(tool)
	tool.Parent = backpack
	return true, options.GrantMessage or ("%s pocketed."):format(baseName)
end

function BunkerEnergyService:GetPocketItemCount(player, kind)
	if not player or not player.Parent then
		return 0
	end

	local total = 0
	local function countContainer(container)
		if not container then
			return
		end

		for _, item in ipairs(container:GetChildren()) do
			if item:IsA("Tool")
				and item:GetAttribute("DontTouchItPocketItem") == true
				and item:GetAttribute("PocketItemKind") == kind
			then
				total += math.max(1, math.floor(tonumber(item:GetAttribute("PocketStackCount")) or 1))
			end
		end
	end

	countContainer(player:FindFirstChildOfClass("Backpack"))
	countContainer(player.Character)
	return total
end

function BunkerEnergyService:ConsumePocketItem(player, kind, amount)
	if not player or not player.Parent then
		return false
	end

	local remaining = math.max(1, math.floor(tonumber(amount) or 1))
	local function consumeContainer(container)
		if not container then
			return
		end

		for _, item in ipairs(container:GetChildren()) do
			if remaining <= 0 then
				return
			end

			if item:IsA("Tool")
				and item:GetAttribute("DontTouchItPocketItem") == true
				and item:GetAttribute("PocketItemKind") == kind
			then
				local stackCount = math.max(1, math.floor(tonumber(item:GetAttribute("PocketStackCount")) or 1))
				local used = math.min(stackCount, remaining)
				stackCount -= used
				remaining -= used

				if stackCount <= 0 then
					item.Enabled = false
					Debris:AddItem(item, 0.1)
				else
					item:SetAttribute("PocketStackCount", stackCount)
					self:_updatePocketItemToolName(item)
				end
			end
		end
	end

	consumeContainer(player.Character)
	consumeContainer(player:FindFirstChildOfClass("Backpack"))
	return remaining <= 0
end

function BunkerEnergyService:GrantEnergyReserveTool(player, options)
	if not player or not player.Parent then
		return false, "No player found for that pocket."
	end

	options = options or {}
	local backpack = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack", 2)
	if not backpack then
		return false, "Your backpack is missing. The room denies involvement."
	end

	local kind = options.Kind or "Fruit"
	local baseName = self:_getEnergyReserveBaseName(options, kind)
	local stackLimit = self:_getEnergyReserveStackLimit()
	local existingTool, currentStack = self:_findStackableEnergyReserveTool(player, kind)
	if existingTool then
		local nextStack = math.clamp((currentStack or 1) + 1, 1, stackLimit)
		existingTool:SetAttribute("EnergyReserveStackCount", nextStack)
		existingTool:SetAttribute("EnergyReserveStackLimit", stackLimit)
		existingTool:SetAttribute("EnergyRestoreAmount", options.RestoreAmount or existingTool:GetAttribute("EnergyRestoreAmount") or Constants.BunkerEnergy.FruitEnergyRestore or 0.32)
		existingTool:SetAttribute("EnergyReserveBaseName", existingTool:GetAttribute("EnergyReserveBaseName") or baseName)
		self:_updateEnergyReserveToolName(existingTool)
		return true, options.GrantMessage or ("%s stacked to x%d."):format(baseName, nextStack)
	end

	local maxItems = Constants.BunkerEnergy.MaxPocketEnergyItems or 5
	if self:_countPocketEnergyItems(player) >= maxItems then
		return false, ("Your pockets can only hold %d stacked pocket items."):format(maxItems)
	end

	local tool = Instance.new("Tool")
	tool.Name = baseName
	tool.ToolTip = options.ToolTip or "Use to steady your energy when the signal starts to drag."
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool:SetAttribute("DontTouchItEnergyReserve", true)
	tool:SetAttribute("EnergyReserveKind", kind)
	tool:SetAttribute("EnergyReserveBaseName", baseName)
	tool:SetAttribute("EnergyReserveStackCount", 1)
	tool:SetAttribute("EnergyReserveStackLimit", stackLimit)
	tool:SetAttribute("EnergyRestoreAmount", options.RestoreAmount or Constants.BunkerEnergy.FruitEnergyRestore or 0.32)
	self:_buildEnergyReserveToolVisual(tool, options)
	self:_updateEnergyReserveToolName(tool)
	tool.Activated:Connect(function()
		if tool:GetAttribute("EnergyReserveUsed") == true then
			return
		end

		local stackCount = math.max(1, math.floor(tonumber(tool:GetAttribute("EnergyReserveStackCount")) or 1))
		local restore = tonumber(tool:GetAttribute("EnergyRestoreAmount")) or Constants.BunkerEnergy.FruitEnergyRestore or 0.32
		self:RecordEnergyItemUsed(player, tool:GetAttribute("EnergyReserveKind") or kind, restore)
		self.systemMessageRemote:FireClient(player, options.UseMessage or "Energy returns for a moment. Nearby lights react to the transaction.")

		stackCount -= 1
		if stackCount <= 0 then
			tool:SetAttribute("EnergyReserveUsed", true)
			tool.Enabled = false
			Debris:AddItem(tool, 0.1)
			return
		end

		tool:SetAttribute("EnergyReserveStackCount", stackCount)
		self:_updateEnergyReserveToolName(tool)
		tool.Enabled = true
	end)
	tool.Parent = backpack
	return true, options.GrantMessage or "Pocketed for later. Try not to think about why it is still warm."
end

function BunkerEnergyService:RecordMatterReclaimed(partCount)
	local amount = math.max(0, tonumber(partCount) or 1) * (Constants.BunkerEnergy.MatterReclaimPowerPerPart or 0.018)
	self:_addWorldPower(amount)
	self:_queueApplyAll()
end

return BunkerEnergyService
