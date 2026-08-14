local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local RemoteService = require(script.Parent:WaitForChild("RemoteService"))

local MovementAuthorityService = {}
MovementAuthorityService.__index = MovementAuthorityService

local BASE_WALK_SPEED = 16
local SPEED_BOOST_MULTIPLIER = 1.55
local SPEED_BOOST_MIN_SPEED = 24
local CROUCH_MULTIPLIER = 0.58
local CROUCH_MIN_SPEED = 6
local CROUCH_HIP_OFFSET = 1.05
local BUNKER_MIN_SPEED = 8.25
local REQUEST_COOLDOWN = 0.08
local SLIDE_COOLDOWN = 0.85
local SLIDE_DURATION = 0.55
local SLIDE_SPEED = 54
local SLIDE_MIN_HORIZONTAL_SPEED = 16
local SLIDE_MIN_MOVE_DIRECTION = 0.2
local TELEPORT_LANDING_LIFT = Vector3.new(0, 2.6, 0)

local function getCharacter(player)
	return player and player.Character
end

local function getHumanoid(player)
	local character = getCharacter(player)
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function getRootPart(player)
	local character = getCharacter(player)
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function getPlayerGui(player)
	return player and player:FindFirstChildOfClass("PlayerGui")
end

local function getBunkerSpeedScale(state)
	return math.clamp(state.BunkerSpeedScale or 1, 0.65, 1)
end

local function hasHumanoidModifier(state)
	return state.SpeedBoost == true or state.Crouch == true or state.Sliding == true or getBunkerSpeedScale(state) < 0.999
end

local function pcallRootMethod(rootPart, methodName, ...)
	if not rootPart or typeof(rootPart[methodName]) ~= "function" then
		return
	end

	pcall(function(...)
		rootPart[methodName](rootPart, ...)
	end, ...)
end

function MovementAuthorityService.new()
	local self = setmetatable({}, MovementAuthorityService)
	self.remote = RemoteService.GetRemote(Constants.Remotes.MovementAuthority)
	self.stateByUserId = {}
	return self
end

function MovementAuthorityService:Initialize()
	self.remote.OnServerEvent:Connect(function(player, payload)
		self:_handleClientRequest(player, payload)
	end)

	local function setupPlayer(player)
		player.CharacterAdded:Connect(function()
			task.delay(0.15, function()
				if player.Parent then
					self:_reapplyState(player)
				end
			end)
		end)
	end

	Players.PlayerAdded:Connect(setupPlayer)

	Players.PlayerRemoving:Connect(function(player)
		self.stateByUserId[player.UserId] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	task.spawn(function()
		while true do
			for _, player in ipairs(Players:GetPlayers()) do
				self:_enforceOwnedHumanoidState(player)
			end
			task.wait(0.25)
		end
	end)
end

function MovementAuthorityService:_getState(player)
	local state = self.stateByUserId[player.UserId]
	if not state then
		state = {
			SpeedBoost = false,
			Crouch = false,
			DevFly = false,
			DevNoclip = false,
			SnackFlight = false,
			Sliding = false,
			ScriptedMotionCount = 0,
			LastRequestAt = 0,
			LastRequestAtByKey = {},
			LastSlideAt = 0,
			SlideToken = 0,
		}
		self.stateByUserId[player.UserId] = state
	end

	return state
end

function MovementAuthorityService:_captureBaseHumanoidState(player, humanoid)
	local state = self:_getState(player)
	if not state.BaseWalkSpeed then
		state.BaseWalkSpeed = humanoid.WalkSpeed
	end
	if not state.BaseHipHeight then
		state.BaseHipHeight = humanoid.HipHeight
	end
	if not state.BaseCameraOffset then
		state.BaseCameraOffset = humanoid.CameraOffset
	end
end

function MovementAuthorityService:_clearBaseIfIdle(player)
	local state = self:_getState(player)
	if hasHumanoidModifier(state) then
		return
	end

	state.BaseWalkSpeed = nil
	state.BaseHipHeight = nil
	state.BaseCameraOffset = nil
end

function MovementAuthorityService:_applyHumanoidState(player)
	local humanoid = getHumanoid(player)
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local state = self:_getState(player)
	if not hasHumanoidModifier(state) then
		if state.BaseWalkSpeed then
			humanoid.WalkSpeed = state.BaseWalkSpeed
		end
		if state.BaseHipHeight then
			humanoid.HipHeight = state.BaseHipHeight
		end
		if state.BaseCameraOffset then
			humanoid.CameraOffset = state.BaseCameraOffset
		end
		humanoid:SetAttribute("DontTouchItCrouching", false)
		self:_clearBaseIfIdle(player)
		return
	end

	self:_captureBaseHumanoidState(player, humanoid)

	local walkSpeed = math.max(BUNKER_MIN_SPEED, (state.BaseWalkSpeed or BASE_WALK_SPEED) * getBunkerSpeedScale(state))
	if state.SpeedBoost then
		walkSpeed = math.max(SPEED_BOOST_MIN_SPEED, walkSpeed * SPEED_BOOST_MULTIPLIER)
	end
	if state.Crouch and not state.Sliding then
		walkSpeed = math.max(CROUCH_MIN_SPEED, walkSpeed * CROUCH_MULTIPLIER)
	end

	humanoid.WalkSpeed = walkSpeed

	if state.Crouch or state.Sliding then
		humanoid.HipHeight = math.max(0.45, (state.BaseHipHeight or humanoid.HipHeight) - CROUCH_HIP_OFFSET)
		humanoid.CameraOffset = (state.BaseCameraOffset or Vector3.zero) + Vector3.new(0, -CROUCH_HIP_OFFSET, 0)
		humanoid:SetAttribute("DontTouchItCrouching", true)
	else
		if state.BaseHipHeight then
			humanoid.HipHeight = state.BaseHipHeight
		end
		if state.BaseCameraOffset then
			humanoid.CameraOffset = state.BaseCameraOffset
		end
		humanoid:SetAttribute("DontTouchItCrouching", false)
	end
end

function MovementAuthorityService:_enforceOwnedHumanoidState(player)
	local state = self.stateByUserId[player.UserId]
	if not state or not hasHumanoidModifier(state) then
		return
	end

	self:_applyHumanoidState(player)
end

function MovementAuthorityService:_setPlayerGuiAttribute(player, attributeName, value)
	local playerGui = getPlayerGui(player)
	if playerGui then
		playerGui:SetAttribute(attributeName, value)
	end
end

function MovementAuthorityService:_reapplyState(player)
	local state = self.stateByUserId[player.UserId]
	if not state then
		return
	end

	self:_applyHumanoidState(player)
	player:SetAttribute("DontTouchItDevFly", state.DevFly == true)
	player:SetAttribute("DontTouchItDevNoclip", state.DevNoclip == true)
	player:SetAttribute("DontTouchItSnackFlightActive", state.SnackFlight == true)
	player:SetAttribute("DontTouchItSliding", state.Sliding == true)
	player:SetAttribute("DontTouchItBunkerEnergyScale", getBunkerSpeedScale(state))
	player:SetAttribute("DontTouchItBunkerPower", state.BunkerPower or 0)
	player:SetAttribute("DontTouchItBunkerPersonalPower", state.BunkerPersonalPower or state.BunkerPower or 0)
	player:SetAttribute("DontTouchItBunkerPersonalGlow", state.BunkerPersonalGlow or 0)
	if state.PlayerEnergy ~= nil then
		player:SetAttribute("DontTouchItPlayerEnergy", state.PlayerEnergy)
	end
	self:_setPlayerGuiAttribute(player, "DontTouchItSnackFlightActive", state.SnackFlight == true)
	self:_setPlayerGuiAttribute(player, "DontTouchItSliding", state.Sliding == true)
	self:_setPlayerGuiAttribute(player, "DontTouchItBunkerEnergyScale", getBunkerSpeedScale(state))
	self:_setPlayerGuiAttribute(player, "DontTouchItBunkerPower", state.BunkerPower or 0)
	self:_setPlayerGuiAttribute(player, "DontTouchItBunkerPersonalPower", state.BunkerPersonalPower or state.BunkerPower or 0)
	self:_setPlayerGuiAttribute(player, "DontTouchItBunkerPersonalGlow", state.BunkerPersonalGlow or 0)
	if state.PlayerEnergy ~= nil then
		self:_setPlayerGuiAttribute(player, "DontTouchItPlayerEnergy", state.PlayerEnergy)
	end
end

function MovementAuthorityService:_handleClientRequest(player, payload)
	if typeof(payload) ~= "table" or not player or not player.Parent then
		return
	end

	local state = self:_getState(player)
	local action = payload.Action
	local active = payload.Active == true
	local cooldownKey = ("%s:%s"):format(tostring(action), tostring(active))
	local now = os.clock()
	if now - (state.LastRequestAtByKey[cooldownKey] or 0) < REQUEST_COOLDOWN then
		return
	end
	state.LastRequestAtByKey[cooldownKey] = now

	if action == "SpeedBoost" then
		self:SetSpeedBoost(player, active)
	elseif action == "Crouch" then
		self:SetCrouch(player, active)
	elseif action == "Slide" then
		self:Slide(player)
	end
end

function MovementAuthorityService:SetSpeedBoost(player, active)
	if not player or not player.Parent then
		return false
	end

	local state = self:_getState(player)
	state.SpeedBoost = active == true
	self:_applyHumanoidState(player)
	return true
end

function MovementAuthorityService:SetCrouch(player, active)
	if not player or not player.Parent then
		return false
	end

	local state = self:_getState(player)
	if active and state.SnackFlight then
		active = false
	end

	state.Crouch = active == true
	self:_applyHumanoidState(player)
	return true
end

function MovementAuthorityService:Slide(player)
	if not player or not player.Parent then
		return false
	end

	local humanoid = getHumanoid(player)
	local rootPart = getRootPart(player)
	if not humanoid or humanoid.Health <= 0 or not rootPart then
		return false
	end

	local state = self:_getState(player)
	if state.SnackFlight or state.DevFly then
		return false
	end

	local now = os.clock()
	if now - (state.LastSlideAt or 0) < SLIDE_COOLDOWN then
		return false
	end

	local velocity = rootPart.AssemblyLinearVelocity
	local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
	local moveDirection = Vector3.new(humanoid.MoveDirection.X, 0, humanoid.MoveDirection.Z)
	local hasRunIntent = state.SpeedBoost == true or horizontalVelocity.Magnitude >= SLIDE_MIN_HORIZONTAL_SPEED
	if not hasRunIntent or moveDirection.Magnitude < SLIDE_MIN_MOVE_DIRECTION then
		return false
	end

	local slideDirection = moveDirection.Unit
	state.LastSlideAt = now
	state.Sliding = true
	state.Crouch = false
	state.SlideToken = (state.SlideToken or 0) + 1
	local slideToken = state.SlideToken

	player:SetAttribute("DontTouchItSliding", true)
	self:_setPlayerGuiAttribute(player, "DontTouchItSliding", true)
	self:_applyHumanoidState(player)

	rootPart.AssemblyLinearVelocity = slideDirection * SLIDE_SPEED + Vector3.new(0, math.max(velocity.Y, 0), 0)
	player:SetAttribute("DontTouchItLastServerMoveReason", "Slide")

	task.delay(SLIDE_DURATION, function()
		if not player.Parent then
			return
		end
		local latestState = self.stateByUserId[player.UserId]
		if not latestState or latestState.SlideToken ~= slideToken then
			return
		end

		latestState.Sliding = false
		player:SetAttribute("DontTouchItSliding", false)
		self:_setPlayerGuiAttribute(player, "DontTouchItSliding", false)
		self:_applyHumanoidState(player)
	end)

	return true
end

function MovementAuthorityService:SetSnackFlight(player, active, options)
	if not player or not player.Parent then
		return false
	end

	local state = self:_getState(player)
	state.SnackFlight = active == true
	if state.SnackFlight then
		state.Crouch = false
		state.Sliding = false
		state.SnackFlightEndsAt = os.clock() + math.max(0, (options and options.Duration) or 0)
	else
		state.SnackFlightEndsAt = nil
	end

	player:SetAttribute("DontTouchItSnackFlightActive", state.SnackFlight)
	player:SetAttribute("DontTouchItSliding", state.Sliding == true)
	self:_setPlayerGuiAttribute(player, "DontTouchItSnackFlightActive", state.SnackFlight)
	self:_setPlayerGuiAttribute(player, "DontTouchItSliding", state.Sliding == true)
	self:_applyHumanoidState(player)
	return true
end

function MovementAuthorityService:SetBunkerEnergy(player, speedScale, power, personalPower, personalGlow)
	if not player or not player.Parent then
		return false
	end

	local state = self:_getState(player)
	state.BunkerSpeedScale = math.clamp(tonumber(speedScale) or 1, 0.65, 1)
	state.BunkerPower = math.clamp(tonumber(power) or 0, 0, 1)
	state.BunkerPersonalPower = math.clamp(tonumber(personalPower) or state.BunkerPower, 0, 1)
	state.BunkerPersonalGlow = math.clamp(tonumber(personalGlow) or 0, 0, 1)
	state.PlayerEnergy = tonumber(player:GetAttribute("DontTouchItPlayerEnergy")) or state.PlayerEnergy

	player:SetAttribute("DontTouchItBunkerEnergyScale", state.BunkerSpeedScale)
	player:SetAttribute("DontTouchItBunkerPower", state.BunkerPower)
	player:SetAttribute("DontTouchItBunkerPersonalPower", state.BunkerPersonalPower)
	player:SetAttribute("DontTouchItBunkerPersonalGlow", state.BunkerPersonalGlow)
	self:_setPlayerGuiAttribute(player, "DontTouchItBunkerEnergyScale", state.BunkerSpeedScale)
	self:_setPlayerGuiAttribute(player, "DontTouchItBunkerPower", state.BunkerPower)
	self:_setPlayerGuiAttribute(player, "DontTouchItBunkerPersonalPower", state.BunkerPersonalPower)
	self:_setPlayerGuiAttribute(player, "DontTouchItBunkerPersonalGlow", state.BunkerPersonalGlow)
	self:_applyHumanoidState(player)
	return true
end

function MovementAuthorityService:SetDevMovement(player, statePayload)
	if not player or not player.Parent or typeof(statePayload) ~= "table" then
		return false
	end

	local state = self:_getState(player)
	state.DevFly = statePayload.Fly == true
	state.DevNoclip = statePayload.Noclip == true
	player:SetAttribute("DontTouchItDevFly", state.DevFly)
	player:SetAttribute("DontTouchItDevNoclip", state.DevNoclip)
	return true
end

function MovementAuthorityService:TeleportPlayer(player, destinationCFrame, reason)
	local rootPart = getRootPart(player)
	if not rootPart and player and player.Parent then
		player.CharacterAdded:Wait()
		task.wait(0.1)
		rootPart = getRootPart(player)
	end

	if not rootPart or typeof(destinationCFrame) ~= "CFrame" then
		return false
	end

	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
	rootPart.CFrame = destinationCFrame + TELEPORT_LANDING_LIFT
	player:SetAttribute("DontTouchItLastServerMoveReason", tostring(reason or "Teleport"))
	return true
end

function MovementAuthorityService:ApplyImpulse(player, velocity, reason)
	local rootPart = getRootPart(player)
	if not rootPart or typeof(velocity) ~= "Vector3" then
		return false
	end

	rootPart.AssemblyLinearVelocity = velocity
	player:SetAttribute("DontTouchItLastServerMoveReason", tostring(reason or "Impulse"))
	return true
end

function MovementAuthorityService:AddImpulse(player, velocity, reason)
	local rootPart = getRootPart(player)
	if not rootPart or typeof(velocity) ~= "Vector3" then
		return false
	end

	rootPart.AssemblyLinearVelocity += velocity
	player:SetAttribute("DontTouchItLastServerMoveReason", tostring(reason or "Impulse"))
	return true
end

function MovementAuthorityService:BeginScriptedMotion(player, reason)
	local rootPart = getRootPart(player)
	if not rootPart then
		return false
	end

	local state = self:_getState(player)
	state.ScriptedMotionCount = (state.ScriptedMotionCount or 0) + 1
	player:SetAttribute("DontTouchItScriptedMotion", true)
	player:SetAttribute("DontTouchItLastServerMoveReason", tostring(reason or "ScriptedMotion"))
	pcallRootMethod(rootPart, "SetNetworkOwner", nil)
	return true
end

function MovementAuthorityService:EndScriptedMotion(player)
	if not player or not player.Parent then
		return false
	end

	local state = self:_getState(player)
	state.ScriptedMotionCount = math.max(0, (state.ScriptedMotionCount or 0) - 1)
	if state.ScriptedMotionCount == 0 then
		player:SetAttribute("DontTouchItScriptedMotion", false)
		local rootPart = getRootPart(player)
		pcallRootMethod(rootPart, "SetNetworkOwnershipAuto")
	end
	return true
end

return MovementAuthorityService
