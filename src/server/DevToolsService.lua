local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local EventRegistry = require(script.Parent:WaitForChild("EventRegistry"))
local RemoteService = require(script.Parent:WaitForChild("RemoteService"))

local DevToolsService = {}
DevToolsService.__index = DevToolsService

local TELEPORT_LANDING_LIFT = Vector3.new(0, 2.6, 0)

local PRESETS = {
	"Fresh",
	"Midway",
	"Completed",
}

local ACTION_CAPABILITY = {
	JumpToRoom = { "DEV_ROOM_TESTING", "DEV_FULL", "TEST_ROOM_TELEPORT" },
	SetRoomPreset = { "DEV_ROOM_TESTING", "DEV_FULL", "TEST_ROOM_STATE" },
	CompleteCurrentRoom = { "DEV_ROOM_TESTING", "DEV_FULL", "TEST_ROOM_STATE" },
	ResetCurrentRoom = { "DEV_ROOM_TESTING", "DEV_FULL", "TEST_ROOM_STATE" },
	FreshStart = { "DEV_FULL" },
	TriggerSpecificEvent = { "DEV_FULL" },
	TriggerRandomEvent = { "DEV_FULL" },
	TeleportSecretArea = { "DEV_FULL", "DEV_SURVEILLANCE" },
	UnlockAllSession = { "DEV_FULL" },
	RestoreNormalProgress = { "DEV_FULL" },
	SetMovement = { "DEV_FULL" },
	SetNourishment = { "DEV_BUNKER_ENERGY", "DEV_FULL" },
	SetBunkerPower = { "DEV_BUNKER_ENERGY", "DEV_FULL" },
	TriggerPassOut = { "DEV_BUNKER_ENERGY", "DEV_FULL" },
	TeleportInfirmary = { "DEV_BUNKER_ENERGY", "DEV_FULL" },
	RestoreHealthyState = { "DEV_BUNKER_ENERGY", "DEV_FULL" },
	SimulateInactivity = { "DEV_BUNKER_ENERGY", "DEV_FULL" },
	ResetInfirmaryState = { "DEV_BUNKER_ENERGY", "DEV_FULL" },
	SetDiscovery = { "DEV_ROOM_TESTING", "DEV_FULL" },
	AdjustStorePrice = { "DEV_ECONOMY_TESTING", "DEV_FULL" },
	ResetStorePrices = { "DEV_ECONOMY_TESTING", "DEV_FULL" },
	RefreshUserManagement = { "ROLE_MANAGEMENT", "MOD_VIEW_HISTORY", "MOD_WARN_PLAYER", "MOD_BAN_24H" },
	SelectManagedUser = { "ROLE_MANAGEMENT", "MOD_VIEW_HISTORY", "MOD_WARN_PLAYER", "MOD_BAN_24H" },
	LookupManagedUser = { "ROLE_MANAGEMENT", "MOD_VIEW_HISTORY", "MOD_WARN_PLAYER", "MOD_BAN_24H" },
	SetManagedUserRole = { "ROLE_MANAGEMENT" },
	SetManagedUserTestAccess = { "TEST_BUILD_ACCESS_MANAGEMENT" },
	WarnManagedUser = { "MOD_WARN_PLAYER" },
	BanManagedUser24h = { "MOD_BAN_24H" },
	RemoveManagedUserBan = { "MOD_REMOVE_BAN" },
	ViewManagedUserHistory = { "MOD_VIEW_HISTORY" },
}

local NO_PROGRESS_LOAD_REQUIRED = {
	Refresh = true,
	SetMovement = true,
	RefreshUserManagement = true,
	SelectManagedUser = true,
	LookupManagedUser = true,
	SetManagedUserRole = true,
	SetManagedUserTestAccess = true,
	WarnManagedUser = true,
	BanManagedUser24h = true,
	RemoveManagedUserBan = true,
	ViewManagedUserHistory = true,
}

local SECRET_AREAS = {
	{
		Id = "Hallway",
		Name = "Main Hallway",
		CFrame = Constants.GetNamedPlaceCFrame("Hallway"),
	},
	{
		Id = "SubLevel1",
		Name = "TV Sub Level 1",
		CFrame = CFrame.new(-16.5, -6.8, 12.5),
	},
	{
		Id = "SubLevel2",
		Name = "TV Sub Level 2",
		CFrame = CFrame.new(0, -15, 5.5),
	},
	{
		Id = "VictoryWalkway",
		Name = "Victory Walkway",
		CFrame = Constants.GetNamedPlaceCFrame("VictoryWalkway"),
	},
	{
		Id = "Library",
		Name = "Library",
		CFrame = Constants.GetRoomSpawnCFrame("Library"),
	},
	{
		Id = "BowlingAlley",
		Name = "Bowling Alley",
		CFrame = Constants.GetRoomSpawnCFrame("BowlingAlley"),
	},
	{
		Id = "Maintenance",
		Name = "Maintenance Room",
		CFrame = CFrame.new(-14, 3, -175),
	},
	{
		Id = "SpaceStation",
		Name = "Space Station",
		CFrame = Constants.GetRoomSpawnCFrame("SpaceStation"),
	},
}

local observationSecretAreas = {}
for _, place in pairs(Constants.NamedPlaces or {}) do
	if place.TeleportGroup == "Observation" then
		table.insert(observationSecretAreas, {
			Id = place.Id,
			Name = place.Name,
			CFrame = place.SpawnCFrame,
		})
	end
end
table.sort(observationSecretAreas, function(left, right)
	return (left.Name or left.Id or "") < (right.Name or right.Id or "")
end)
for _, area in ipairs(observationSecretAreas) do
	table.insert(SECRET_AREAS, area)
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
	return true
end

local function listContains(items, value)
	for _, item in ipairs(items) do
		if item == value then
			return true
		end
	end

	return false
end

function DevToolsService.new(
	discoveryService,
	roomProgressService,
	eventManager,
	resetService,
	interactionService,
	movementAuthorityService,
	bunkerEnergyService,
	permissionService,
	moderationService
)
	local self = setmetatable({}, DevToolsService)
	self.discoveryService = discoveryService
	self.roomProgressService = roomProgressService
	self.eventManager = eventManager
	self.resetService = resetService
	self.interactionService = interactionService
	self.movementAuthorityService = movementAuthorityService
	self.bunkerEnergyService = bunkerEnergyService
	self.permissionService = permissionService
	self.moderationService = moderationService
	self.remote = RemoteService.GetRemote(Constants.Remotes.DevTools)
	self.systemMessageRemote = RemoteService.GetRemote(Constants.Remotes.SystemMessage)
	self.eventIds = {}
	self.movementStateByUserId = {}

	for _, eventDefinition in ipairs(EventRegistry) do
		if eventDefinition.Id then
			self.eventIds[eventDefinition.Id] = true
		end
	end

	return self
end

function DevToolsService:_teleportPlayer(player, destinationCFrame, reason)
	if self.movementAuthorityService and self.movementAuthorityService.TeleportPlayer then
		return self.movementAuthorityService:TeleportPlayer(player, destinationCFrame, reason)
	end

	return teleportPlayer(player, destinationCFrame)
end

function DevToolsService:Initialize()
	self.remote.OnServerEvent:Connect(function(player, payload)
		self:_handleRequest(player, payload)
	end)

	Players.PlayerAdded:Connect(function(player)
		task.delay(1, function()
			if player.Parent and self:IsAuthorized(player) then
				self:_sendState(player, "Auth")
			end
			self:_broadcastUserManagement()
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self.movementStateByUserId[player.UserId] = nil
		self:_broadcastUserManagement()
	end)

	if self.permissionService and self.permissionService.Changed then
		self.permissionService.Changed:Connect(function()
			self:_broadcastUserManagement()
			for _, player in ipairs(Players:GetPlayers()) do
				if self:IsAuthorized(player) then
					self:_sendState(player, "State")
				else
					self.remote:FireClient(player, {
						Type = "AuthorizationRevoked",
					})
				end
			end
		end)
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if self:IsAuthorized(player) then
			self:_sendState(player, "Auth")
		end
	end
end

function DevToolsService:IsAuthorized(player)
	return self.permissionService ~= nil and self.permissionService:CanUseDevTools(player.UserId)
end

function DevToolsService:_sendMessage(player, text)
	if player and player.Parent then
		self.systemMessageRemote:FireClient(player, text)
	end
end

function DevToolsService:_getCurrentRoomId(player)
	local roomId = self.roomProgressService and self.roomProgressService:GetRoomForPlayer(player)
	if roomId and Constants.GetRoom(roomId) then
		return roomId
	end

	return Constants.RoomOrder[1]
end

function DevToolsService:_hasCapability(player, capability)
	return self.permissionService ~= nil and self.permissionService:HasPermission(player.UserId, capability)
end

function DevToolsService:_hasAnyCapability(player, capabilities)
	for _, capability in ipairs(capabilities or {}) do
		if self:_hasCapability(player, capability) then
			return true
		end
	end
	return false
end

function DevToolsService:_getAdminCapabilities(player)
	if not self.permissionService then
		return {}
	end
	return self.permissionService:GetCapabilities(player.UserId)
end

function DevToolsService:_isTesterRoomAllowed(player, roomId, presetName)
	local room = Constants.GetRoom(roomId)
	if not room or room.TesterAccessible ~= true then
		return false
	end
	if presetName then
		return listContains(room.TesterStatePresets or {}, presetName)
	end
	return true
end

function DevToolsService:_canUseRoomTesting(player, roomId, presetName)
	if self:_hasCapability(player, "DEV_ROOM_TESTING") or self:_hasCapability(player, "DEV_FULL") then
		return true
	end
	if self:_hasAnyCapability(player, { "TEST_ROOM_TELEPORT", "TEST_ROOM_STATE" }) then
		return self:_isTesterRoomAllowed(player, roomId, presetName)
	end
	return false
end

function DevToolsService:_getRoomOptions(player)
	local rooms = {}
	local isDeveloper = player and self:_hasAnyCapability(player, { "DEV_FULL", "DEV_ROOM_TESTING" })

	for _, roomId in ipairs(Constants.DiscoveryRoomOrder or Constants.RoomOrder) do
		local room = Constants.GetRoom(roomId)
		if room and (isDeveloper or room.TesterAccessible == true) then
			table.insert(rooms, {
				Id = roomId,
				Name = room.Name,
				TesterAccessible = room.TesterAccessible == true,
			})
		end
	end

	return rooms
end

function DevToolsService:_getEventOptions()
	local events = {}

	for _, eventDefinition in ipairs(EventRegistry) do
		table.insert(events, {
			Id = eventDefinition.Id,
			Name = eventDefinition.Name or eventDefinition.Id,
		})
	end

	return events
end

function DevToolsService:_getSecretAreaOptions()
	return self:_getSecretAreaOptionsForPlayer(nil)
end

function DevToolsService:_getSecretAreaOptionsForPlayer(player)
	if player and not self:_hasAnyCapability(player, { "DEV_FULL", "DEV_SURVEILLANCE" }) then
		return {}
	end

	local areas = {}

	for _, area in ipairs(SECRET_AREAS) do
		table.insert(areas, {
			Id = area.Id,
			Name = area.Name,
		})
	end

	return areas
end

function DevToolsService:_getAreaById(areaId)
	for _, area in ipairs(SECRET_AREAS) do
		if area.Id == areaId then
			return area
		end
	end

	return nil
end

function DevToolsService:_getLivePlayerSummaries()
	local summaries = {}
	for _, livePlayer in ipairs(Players:GetPlayers()) do
		local summary = self.permissionService and self.permissionService:GetUserAdminSummary(livePlayer.UserId) or nil
		if summary then
			if self.moderationService then
				summary.Moderation = self.moderationService:GetSummary(livePlayer.UserId)
			end
			table.insert(summaries, summary)
		end
	end
	table.sort(summaries, function(left, right)
		return string.lower(left.Username or "") < string.lower(right.Username or "")
	end)
	return summaries
end

function DevToolsService:_getManagedUserSummary(userId, includeHistory)
	userId = tonumber(userId)
	if not userId or not self.permissionService then
		return nil
	end
	local summary = self.permissionService:GetUserAdminSummary(userId)
	if summary and self.moderationService then
		summary.Moderation = self.moderationService:GetSummary(userId)
		if includeHistory then
			summary.ModerationHistory = self.moderationService:GetHistory(userId)
		end
	end
	return summary
end

function DevToolsService:_getUserManagementState(player, selectedUserId, includeHistory)
	if not self.permissionService or not self:_hasAnyCapability(player, {
		"ROLE_MANAGEMENT",
		"TEST_BUILD_ACCESS_MANAGEMENT",
		"MOD_WARN_PLAYER",
		"MOD_BAN_24H",
		"MOD_VIEW_HISTORY",
		"MOD_REMOVE_BAN",
	}) then
		return nil
	end

	return {
		LivePlayers = self:_getLivePlayerSummaries(),
		SelectedUser = selectedUserId and self:_getManagedUserSummary(selectedUserId, includeHistory) or nil,
		Reasons = Constants.ModerationReasons,
		ReasonOrder = Constants.ModerationReasonOrder,
		RoleOrder = Constants.AdminRoleOrder,
	}
end

function DevToolsService:_broadcastUserManagement()
	for _, player in ipairs(Players:GetPlayers()) do
		if self:IsAuthorized(player) then
			self.remote:FireClient(player, {
				Type = "UserManagement",
				UserManagement = self:_getUserManagementState(player),
			})
		end
	end
end

function DevToolsService:_sendState(player, stateType, roomId)
	if not self:IsAuthorized(player) then
		return
	end

	if not self.discoveryService:IsLoaded(player) then
		task.delay(0.5, function()
			if player.Parent then
				self:_sendState(player, stateType, roomId)
			end
		end)
		return
	end

	local currentRoomId = roomId or self:_getCurrentRoomId(player)
	local movementState = self.movementStateByUserId[player.UserId] or {}

	self.remote:FireClient(player, {
		Type = stateType or "State",
		Authorized = true,
		Role = self.permissionService and self.permissionService:GetRole(player.UserId) or "Player",
		Capabilities = self:_getAdminCapabilities(player),
		DevSessionActive = self.discoveryService:IsDevOverrideActive(player),
		CurrentRoomId = currentRoomId,
		Rooms = self:_getRoomOptions(player),
		Events = self:_getEventOptions(),
		SecretAreas = self:_getSecretAreaOptionsForPlayer(player),
		Presets = PRESETS,
		Movement = {
			Fly = movementState.Fly == true,
			Noclip = movementState.Noclip == true,
		},
		Energy = self.bunkerEnergyService and self.bunkerEnergyService:GetDevState(player) or nil,
		StorePrices = self.roomProgressService and self.roomProgressService:GetStorePrices() or Constants.NoTouch,
		RoomSnapshot = self.discoveryService:GetRoomSnapshot(player, currentRoomId),
		UserManagement = self:_getUserManagementState(player),
	})
end

function DevToolsService:_refreshWorldState()
	if self.interactionService and self.interactionService.RefreshProgressDrivenWorld then
		self.interactionService:RefreshProgressDrivenWorld()
	end
end

function DevToolsService:_resetRoom(player)
	if self.interactionService and self.interactionService.ResetRoomForPlayer then
		self.interactionService:ResetRoomForPlayer(player)
	else
		self.resetService.RestoreAll()
		if self.eventManager then
			self.eventManager.active = false
		end
		self:_refreshWorldState()
	end
	self:_sendMessage(player, "Dev reset restored the generated room state.")
end

function DevToolsService:_applyRoomPreset(player, roomId, presetName)
	if not Constants.GetRoom(roomId) or not listContains(PRESETS, presetName) then
		return false
	end

	self.discoveryService:EnableDevOverride(player)
	self:_resetRoom(player)
	local discoveryIds = self.discoveryService:GetDevPresetDiscoveryIds(roomId, presetName)
	local ok = self.discoveryService:SetDevRoomDiscoveries(player, roomId, discoveryIds)
	self:_refreshWorldState()

	if ok then
		local room = Constants.GetRoom(roomId)
		self:_sendMessage(player, ("Dev preset: %s is now %s for this session."):format(room.Name, presetName))
	end

	return ok
end

function DevToolsService:_setMovementState(player, payload)
	local state = self.movementStateByUserId[player.UserId] or {
		Fly = false,
		Noclip = false,
	}

	if typeof(payload.Fly) == "boolean" then
		state.Fly = payload.Fly
	end

	if typeof(payload.Noclip) == "boolean" then
		state.Noclip = payload.Noclip
	end

	self.movementStateByUserId[player.UserId] = state
	if self.movementAuthorityService and self.movementAuthorityService.SetDevMovement then
		self.movementAuthorityService:SetDevMovement(player, state)
	end

	self.remote:FireClient(player, {
		Type = "MovementState",
		Fly = state.Fly,
		Noclip = state.Noclip,
	})
end

function DevToolsService:_setDiscoveryCompletion(player, payload)
	local roomId = payload.RoomId
	local discoveryId = payload.DiscoveryId
	local completed = payload.Completed == true

	if typeof(roomId) ~= "string" or typeof(discoveryId) ~= "string" then
		return false
	end

	local ok = self.discoveryService:SetDevDiscoveryCompletion(player, roomId, discoveryId, completed)
	self:_refreshWorldState()
	return ok
end

function DevToolsService:_isActionAllowed(player, action)
	local capabilities = ACTION_CAPABILITY[action]
	if not capabilities then
		return true
	end
	return self:_hasAnyCapability(player, capabilities)
end

function DevToolsService:_sendUserManagementState(player, selectedUserId, includeHistory, message)
	self.remote:FireClient(player, {
		Type = "UserManagement",
		UserMessage = message,
		UserManagement = self:_getUserManagementState(player, selectedUserId, includeHistory),
	})
end

function DevToolsService:_resolveUsername(username)
	username = tostring(username or ""):gsub("[%c\r\n\t]", ""):match("^%s*(.-)%s*$") or ""
	if username == "" or #username > 32 then
		return nil, "Enter a valid Roblox username."
	end

	local ok, userId = pcall(function()
		return Players:GetUserIdFromNameAsync(username)
	end)
	if not ok or typeof(userId) ~= "number" then
		return nil, "Username lookup failed or no such user exists."
	end
	return userId, nil
end

function DevToolsService:_handleUserManagementRequest(player, payload)
	local action = payload.Action
	local targetUserId = tonumber(payload.TargetUserId or payload.UserId)
	local includeHistory = action == "ViewManagedUserHistory"

	if action == "RefreshUserManagement" then
		self:_sendUserManagementState(player, nil, false, nil)
	elseif action == "SelectManagedUser" then
		if not targetUserId then
			self:_sendUserManagementState(player, nil, false, "Invalid selected UserId.")
			return true
		end
		self:_sendUserManagementState(player, targetUserId, false, nil)
	elseif action == "LookupManagedUser" then
		local userId, err = self:_resolveUsername(payload.Username)
		if not userId then
			self:_sendUserManagementState(player, nil, false, err)
			return true
		end
		self:_sendUserManagementState(player, userId, false, "Player lookup complete.")
	elseif action == "SetManagedUserRole" then
		local ok, message = self.permissionService:SetRole(player.UserId, targetUserId, payload.Role)
		self:_sendUserManagementState(player, targetUserId, false, ok and "Role updated." or message)
	elseif action == "SetManagedUserTestAccess" then
		local ok, message = self.permissionService:SetTestBuildAccess(player.UserId, targetUserId, payload.Enabled == true)
		self:_sendUserManagementState(player, targetUserId, false, ok and "Test access updated." or message)
	elseif action == "WarnManagedUser" then
		local ok, message = self.moderationService:IssueWarning(player.UserId, targetUserId, payload.ReasonCode, payload.ReasonText)
		self:_sendUserManagementState(player, targetUserId, true, message or (ok and "Warning issued." or "Warning failed."))
	elseif action == "BanManagedUser24h" then
		local ok, message = self.moderationService:Ban24Hours(player.UserId, targetUserId, payload.ReasonCode, payload.ReasonText)
		self:_sendUserManagementState(player, targetUserId, true, message or (ok and "24-hour ban issued." or "Ban failed."))
	elseif action == "RemoveManagedUserBan" then
		local ok, message = self.moderationService:RemoveActiveBan(player.UserId, targetUserId, payload.ReasonText)
		self:_sendUserManagementState(player, targetUserId, true, message or (ok and "Ban removed." or "Unban failed."))
	elseif action == "ViewManagedUserHistory" then
		self:_sendUserManagementState(player, targetUserId, true, nil)
	else
		return false
	end

	self:_broadcastUserManagement()
	return true
end

function DevToolsService:_handleAuthorizedRequest(player, payload)
	local action = payload.Action
	local roomId = payload.RoomId

	if not self:_isActionAllowed(player, action) then
		self:_sendMessage(player, "You do not have permission for that dev action.")
		self:_sendState(player, "State", roomId)
		return
	end

	if self:_handleUserManagementRequest(player, payload) then
		return
	end

	if not NO_PROGRESS_LOAD_REQUIRED[action] and not self.discoveryService:IsLoaded(player) then
		self:_sendMessage(player, "Dev tools are waiting for saved progress to load.")
		self:_sendState(player, "State", roomId)
		return
	end

	if action == "Refresh" then
		self:_sendState(player, "State", roomId)
	elseif action == "JumpToRoom" then
		local room = Constants.GetRoom(roomId)
		if not room then
			return
		end
		if not self:_canUseRoomTesting(player, roomId) then
			self:_sendMessage(player, "That room is not approved for your test access.")
			self:_sendState(player, "State", self:_getCurrentRoomId(player))
			return
		end
		self.discoveryService:EnableDevOverride(player)
		self:_teleportPlayer(player, Constants.GetRoomSpawnCFrame(roomId), "DevJumpToRoom")
		self:_sendMessage(player, ("Dev jump: %s. Progress is session-only."):format(room.Name))
		task.delay(0.15, function()
			if player.Parent then
				self:_sendState(player, "State", roomId)
			end
		end)
	elseif action == "SetRoomPreset" then
		local presetName = payload.Preset
		if typeof(roomId) == "string" and typeof(presetName) == "string" then
			if not self:_canUseRoomTesting(player, roomId, presetName) then
				self:_sendMessage(player, "That room preset is not approved for your test access.")
				self:_sendState(player, "State", self:_getCurrentRoomId(player))
				return
			end
			self:_applyRoomPreset(player, roomId, presetName)
			self:_sendState(player, "State", roomId)
		end
	elseif action == "CompleteCurrentRoom" then
		local currentRoomId = self:_getCurrentRoomId(player)
		if not self:_canUseRoomTesting(player, currentRoomId, "Completed") then
			self:_sendMessage(player, "Completed preset is not approved for this test room.")
			self:_sendState(player, "State", currentRoomId)
			return
		end
		self:_applyRoomPreset(player, currentRoomId, "Completed")
		self:_sendState(player, "State", currentRoomId)
	elseif action == "ResetCurrentRoom" then
		local currentRoomId = self:_getCurrentRoomId(player)
		if not self:_canUseRoomTesting(player, currentRoomId, "Fresh") then
			self:_sendMessage(player, "Reset is not approved for this test room.")
			self:_sendState(player, "State", currentRoomId)
			return
		end
		self:_resetRoom(player)
		self:_sendState(player, "State", currentRoomId)
	elseif action == "FreshStart" then
		self.discoveryService:StartFreshDevSession(player)
		self:_resetRoom(player)
		if self.roomProgressService and self.roomProgressService.StartFreshDevSession then
			self.roomProgressService:StartFreshDevSession(player)
		end
		self:_refreshWorldState()
		self:_sendMessage(player, "Dev fresh start: all discoveries and inventory are clear for this session only.")
		self:_sendState(player, "State", Constants.Prologue.StartRoomId or "CaveEntrance")
	elseif action == "TriggerSpecificEvent" then
		local eventId = payload.EventId
		if typeof(eventId) == "string" and self.eventIds[eventId] then
			self.discoveryService:EnableDevOverride(player)
			self.eventManager:TriggerById(player, eventId)
			self:_sendState(player, "State", self:_getCurrentRoomId(player))
		end
	elseif action == "TriggerRandomEvent" then
		self.discoveryService:EnableDevOverride(player)
		self.eventManager:TriggerRandom(player)
		self:_sendState(player, "State", self:_getCurrentRoomId(player))
	elseif action == "TeleportSecretArea" then
		local area = self:_getAreaById(payload.AreaId)
		if area then
			self.discoveryService:EnableDevOverride(player)
			self:_teleportPlayer(player, area.CFrame, "DevSecretArea")
			self:_sendMessage(player, ("Dev teleport: %s."):format(area.Name))
			task.delay(0.15, function()
				if player.Parent then
					self:_sendState(player, "State")
				end
			end)
		end
	elseif action == "UnlockAllSession" then
		self.discoveryService:UnlockAllDiscoveriesForDevSession(player)
		self:_refreshWorldState()
		self:_sendMessage(player, "Dev session now has every discovery, key, and reveal.")
		self:_sendState(player, "State", self:_getCurrentRoomId(player))
	elseif action == "RestoreNormalProgress" then
		self.discoveryService:RestoreNormalProgressState(player)
		self:_resetRoom(player)
		self:_refreshWorldState()
		self:_sendMessage(player, "Dev session cleared. Your real saved progress is back.")
		self:_sendState(player, "State", self:_getCurrentRoomId(player))
	elseif action == "SetMovement" then
		self:_setMovementState(player, payload)
		self:_sendState(player, "State", self:_getCurrentRoomId(player))
	elseif action == "SetNourishment" then
		if self.bunkerEnergyService and self.bunkerEnergyService:SetPlayerEnergyForDev(player, payload.Value) then
			self:_sendMessage(player, "Dev nourishment level set for this session.")
			self:_sendState(player, "State", self:_getCurrentRoomId(player))
		end
	elseif action == "SetBunkerPower" then
		if self.bunkerEnergyService and self.bunkerEnergyService:SetWorldPowerForDev(payload.Value) then
			self:_sendMessage(player, "Dev bunker power level set for this server session.")
			self:_sendState(player, "State", self:_getCurrentRoomId(player))
		end
	elseif action == "TriggerPassOut" then
		if self.bunkerEnergyService and self.bunkerEnergyService:TriggerPassOutForDev(player) then
			self:_sendMessage(player, "Dev recovery sequence triggered.")
			self:_sendState(player, "State", "Infirmary")
		end
	elseif action == "TeleportInfirmary" then
		self.discoveryService:EnableDevOverride(player)
		self:_teleportPlayer(player, Constants.GetRoomSpawnCFrame("Infirmary"), "DevInfirmary")
		self:_sendMessage(player, "Dev teleport: Infirmary.")
		task.delay(0.15, function()
			if player.Parent then
				self:_sendState(player, "State", "Infirmary")
			end
		end)
	elseif action == "RestoreHealthyState" then
		if self.bunkerEnergyService and self.bunkerEnergyService:RestoreHealthyStateForDev(player) then
			self:_sendMessage(player, "Dev healthy state restored.")
			self:_sendState(player, "State", self:_getCurrentRoomId(player))
		end
	elseif action == "SimulateInactivity" then
		if self.bunkerEnergyService and self.bunkerEnergyService:SimulateProlongedInactivityForDev(player) then
			self:_sendMessage(player, "Dev inactivity simulated. Watch lights and signal response.")
			self:_sendState(player, "State", self:_getCurrentRoomId(player))
		end
	elseif action == "ResetInfirmaryState" then
		if self.bunkerEnergyService and self.bunkerEnergyService:RestoreHealthyStateForDev(player) then
			self:_resetRoom(player)
			self:_sendMessage(player, "Dev infirmary/recovery state reset.")
			self:_sendState(player, "State", self:_getCurrentRoomId(player))
		end
	elseif action == "SetDiscovery" then
		if self:_setDiscoveryCompletion(player, payload) then
			self:_sendState(player, "State", payload.RoomId)
		end
	elseif action == "AdjustStorePrice" then
		local key = payload.Key
		local delta = payload.Delta
		if self.roomProgressService and typeof(key) == "string" and self.roomProgressService:AdjustStorePrice(key, delta) then
			self:_sendMessage(player, "Dev store price updated for this server session.")
			self:_sendState(player, "State", self:_getCurrentRoomId(player))
		end
	elseif action == "ResetStorePrices" then
		if self.roomProgressService then
			self.roomProgressService:ResetStorePrices()
			self:_sendMessage(player, "Dev store prices reset to defaults.")
			self:_sendState(player, "State", self:_getCurrentRoomId(player))
		end
	end
end

function DevToolsService:_handleRequest(player, payload)
	if typeof(payload) ~= "table" or not player then
		return
	end

	if payload.Action == "Handshake" then
		if self:IsAuthorized(player) then
			self:_sendState(player, "Auth")
		end
		return
	end

	if not self:IsAuthorized(player) then
		warn(("[DON'T TOUCH IT] Unauthorized dev tool request from %s (%d)."):format(player.Name, player.UserId))
		return
	end

	self:_handleAuthorizedRequest(player, payload)
end

return DevToolsService
