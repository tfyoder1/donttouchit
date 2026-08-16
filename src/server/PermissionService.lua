local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local DevToolsConfig = require(script.Parent:WaitForChild("DevToolsConfig"))

local PermissionService = {}
PermissionService.__index = PermissionService

local ROLE_PLAYER = "Player"
local ROLE_OWNER = "Owner"
local ROLE_DEVELOPER = "Developer"
local ROLE_TESTER = "Tester"
local ROLE_FOUNDER = "Founder"

local ROLE_SET = {
	[ROLE_OWNER] = true,
	[ROLE_DEVELOPER] = true,
	[ROLE_TESTER] = true,
	[ROLE_FOUNDER] = true,
	[ROLE_PLAYER] = true,
}

local ROOT_OWNER_LOCK_MESSAGE = "Root owner access is configured server-side and cannot be removed in-game."

local function now()
	return os.time()
end

local function normalizeUserId(userId)
	local numeric = tonumber(userId)
	if not numeric then
		return nil
	end

	numeric = math.floor(numeric)
	if numeric <= 0 then
		return nil
	end

	return numeric
end

local function cloneDictionary(source)
	local copy = {}
	for key, value in pairs(source or {}) do
		copy[key] = value
	end
	return copy
end

local function sanitizeRole(role)
	role = tostring(role or ROLE_PLAYER)
	if ROLE_SET[role] then
		return role
	end
	return ROLE_PLAYER
end

local function buildAuditKey(action)
	return ("audit_%010d_%s_%s"):format(now(), tostring(action or "Action"), HttpService:GenerateGUID(false))
end

function PermissionService.new()
	local self = setmetatable({}, PermissionService)
	self.roleStore = nil
	self.auditStore = nil
	self.recordByUserId = {}
	self.loadedByUserId = {}
	self._changedEvent = Instance.new("BindableEvent")
	self.Changed = self._changedEvent.Event

	local okRole, roleStore = pcall(function()
		return DataStoreService:GetDataStore(Constants.DataStore.AdminRolesName or "DontTouchItAdminRoles_v1")
	end)
	if okRole then
		self.roleStore = roleStore
	else
		warn(("[DON'T TOUCH IT] Admin role DataStore unavailable: %s"):format(tostring(roleStore)))
	end

	local okAudit, auditStore = pcall(function()
		return DataStoreService:GetDataStore(Constants.DataStore.AdminAuditName or "DontTouchItAdminAudit_v1")
	end)
	if okAudit then
		self.auditStore = auditStore
	else
		warn(("[DON'T TOUCH IT] Admin audit DataStore unavailable: %s"):format(tostring(auditStore)))
	end

	return self
end

function PermissionService:Initialize()
	Players.PlayerAdded:Connect(function(player)
		self:LoadUser(player.UserId)
		self:ApplyPlayerAttributes(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self.recordByUserId[player.UserId] = nil
		self.loadedByUserId[player.UserId] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		self:LoadUser(player.UserId)
		self:ApplyPlayerAttributes(player)
	end
end

function PermissionService:IsRootOwner(userId)
	userId = normalizeUserId(userId)
	return userId ~= nil and DevToolsConfig.OwnerUserIds[userId] == true
end

function PermissionService:_defaultRecord(userId)
	return {
		UserId = userId,
		Role = ROLE_PLAYER,
		TestBuildAccess = false,
		UpdatedAt = now(),
	}
end

function PermissionService:_sanitizeRecord(userId, data)
	local record = self:_defaultRecord(userId)
	if typeof(data) == "table" then
		record.Role = sanitizeRole(data.Role)
		record.TestBuildAccess = data.TestBuildAccess == true
		record.GrantedBy = normalizeUserId(data.GrantedBy)
		record.GrantedAt = if typeof(data.GrantedAt) == "number" then data.GrantedAt else nil
		record.TestAccessUpdatedBy = normalizeUserId(data.TestAccessUpdatedBy)
		record.TestAccessUpdatedAt = if typeof(data.TestAccessUpdatedAt) == "number" then data.TestAccessUpdatedAt else nil
		record.UpdatedAt = if typeof(data.UpdatedAt) == "number" then data.UpdatedAt else record.UpdatedAt
	end

	if self:IsRootOwner(userId) then
		record.Role = ROLE_OWNER
		record.TestBuildAccess = true
	elseif DevToolsConfig.AllowedUserIds[userId] == true and record.Role == ROLE_PLAYER then
		record.Role = ROLE_DEVELOPER
		record.TestBuildAccess = true
	end

	return record
end

function PermissionService:_persistRecord(userId, mutate)
	userId = normalizeUserId(userId)
	if not userId or not self.roleStore then
		return false, "Role persistence is unavailable."
	end

	local savedRecord = nil
	local ok, err = pcall(function()
		self.roleStore:UpdateAsync(("user_%d"):format(userId), function(oldData)
			local record = self:_sanitizeRecord(userId, oldData)
			local changedRecord, message = mutate(record)
			if changedRecord == nil then
				savedRecord = record
				return nil
			end
			if message then
				savedRecord = message
			else
				savedRecord = changedRecord
			end
			return changedRecord
		end)
	end)

	if not ok then
		return false, tostring(err)
	end
	if typeof(savedRecord) ~= "table" then
		return false, tostring(savedRecord or "No record was saved.")
	end

	self.recordByUserId[userId] = self:_sanitizeRecord(userId, savedRecord)
	self.loadedByUserId[userId] = true
	self:_applyOnlinePlayerAttributes(userId)
	self._changedEvent:Fire(userId)
	return true, nil, self.recordByUserId[userId]
end

function PermissionService:LoadUser(userId)
	userId = normalizeUserId(userId)
	if not userId then
		return nil
	end

	if self.loadedByUserId[userId] and self.recordByUserId[userId] then
		return self.recordByUserId[userId]
	end

	local data = nil
	if self.roleStore then
		local ok, result = pcall(function()
			return self.roleStore:GetAsync(("user_%d"):format(userId))
		end)
		if ok then
			data = result
		else
			warn(("[DON'T TOUCH IT] Could not load admin role for %d: %s"):format(userId, tostring(result)))
		end
	end

	local record = self:_sanitizeRecord(userId, data)
	self.recordByUserId[userId] = record
	self.loadedByUserId[userId] = true
	return record
end

function PermissionService:GetRole(userId)
	local record = self:LoadUser(userId)
	return record and record.Role or ROLE_PLAYER
end

function PermissionService:GetRecord(userId)
	userId = normalizeUserId(userId)
	if not userId then
		return nil
	end
	return table.clone(self:LoadUser(userId) or self:_defaultRecord(userId))
end

function PermissionService:GetCapabilities(userId)
	local record = self:LoadUser(userId)
	local capabilities = {}
	if not record then
		return capabilities
	end

	local role = record.Role
	if role == ROLE_OWNER then
		for _, capability in ipairs(Constants.AdminCapabilityOrder or {}) do
			capabilities[capability] = true
		end
	elseif role == ROLE_DEVELOPER then
		for _, capability in ipairs(Constants.DeveloperDefaultCapabilities or {}) do
			capabilities[capability] = true
		end
	elseif role == ROLE_TESTER then
		capabilities.FOUNDER_RECOGNITION = false
		if record.TestBuildAccess == true then
			for _, capability in ipairs(Constants.TesterDefaultCapabilities or {}) do
				capabilities[capability] = true
			end
		end
	elseif role == ROLE_FOUNDER then
		capabilities.FOUNDER_RECOGNITION = true
	end

	for capability, enabled in pairs(DevToolsConfig.DeveloperCapabilityOverrides or {}) do
		if role == ROLE_DEVELOPER then
			capabilities[capability] = enabled == true
		end
	end

	return capabilities
end

function PermissionService:HasPermission(userId, capability)
	userId = normalizeUserId(userId)
	if not userId or typeof(capability) ~= "string" then
		return false
	end
	if self:IsRootOwner(userId) then
		return true
	end
	return self:GetCapabilities(userId)[capability] == true
end

function PermissionService:CanUseDevTools(userId)
	return self:HasPermission(userId, "DEV_FULL")
		or self:HasPermission(userId, "DEV_ROOM_TESTING")
		or self:HasPermission(userId, "TEST_ROOM_TELEPORT")
		or self:HasPermission(userId, "TEST_ROOM_STATE")
		or self:HasPermission(userId, "ROLE_MANAGEMENT")
		or self:HasPermission(userId, "MOD_VIEW_HISTORY")
end

function PermissionService:CanAccessTestBuild(userId)
	return self:HasPermission(userId, "TEST_BUILD_ACCESS")
end

function PermissionService:CanManageTarget(adminUserId, targetUserId, requestedRole)
	adminUserId = normalizeUserId(adminUserId)
	targetUserId = normalizeUserId(targetUserId)
	if not adminUserId or not targetUserId then
		return false, "Invalid UserId."
	end
	if not self:HasPermission(adminUserId, "ROLE_MANAGEMENT") then
		return false, "You do not have role management permission."
	end
	if self:IsRootOwner(targetUserId) and requestedRole ~= ROLE_OWNER then
		return false, ROOT_OWNER_LOCK_MESSAGE
	end
	if requestedRole == ROLE_OWNER and not self:IsRootOwner(adminUserId) then
		return false, "Only a root owner can grant persistent Owner role."
	end
	if self:GetRole(targetUserId) == ROLE_OWNER and not self:IsRootOwner(adminUserId) then
		return false, "Only a root owner can modify Owner records."
	end
	return true, nil
end

function PermissionService:CanModerateTarget(adminUserId, targetUserId)
	adminUserId = normalizeUserId(adminUserId)
	targetUserId = normalizeUserId(targetUserId)
	if not adminUserId or not targetUserId then
		return false, "Invalid UserId."
	end
	if self:IsRootOwner(targetUserId) then
		return false, "Root owners cannot be moderated through the in-game menu."
	end
	if self:GetRole(targetUserId) == ROLE_OWNER and not self:IsRootOwner(adminUserId) then
		return false, "Only a root owner can moderate an Owner record."
	end
	return true, nil
end

function PermissionService:SetRole(adminUserId, targetUserId, role)
	targetUserId = normalizeUserId(targetUserId)
	role = sanitizeRole(role)
	local allowed, message = self:CanManageTarget(adminUserId, targetUserId, role)
	if not allowed then
		return false, message
	end

	local changedAt = now()
	local ok, err, record = self:_persistRecord(targetUserId, function(oldRecord)
		oldRecord.Role = role
		oldRecord.GrantedBy = normalizeUserId(adminUserId)
		oldRecord.GrantedAt = changedAt
		oldRecord.UpdatedAt = changedAt
		if role == ROLE_TESTER and oldRecord.TestBuildAccess == nil then
			oldRecord.TestBuildAccess = true
		elseif role ~= ROLE_TESTER and role ~= ROLE_OWNER then
			oldRecord.TestBuildAccess = false
		end
		if role == ROLE_OWNER then
			oldRecord.TestBuildAccess = true
		end
		return oldRecord
	end)

	if ok then
		self:LogAudit(adminUserId, "SetRole", {
			TargetUserId = targetUserId,
			Role = role,
		})
	end
	return ok, err, record
end

function PermissionService:SetTestBuildAccess(adminUserId, targetUserId, enabled)
	targetUserId = normalizeUserId(targetUserId)
	local allowed, message = self:CanManageTarget(adminUserId, targetUserId, self:GetRole(targetUserId))
	if not allowed then
		return false, message
	end
	if not self:HasPermission(adminUserId, "TEST_BUILD_ACCESS_MANAGEMENT") then
		return false, "You do not have test access management permission."
	end

	local changedAt = now()
	local ok, err, record = self:_persistRecord(targetUserId, function(oldRecord)
		oldRecord.TestBuildAccess = enabled == true
		oldRecord.TestAccessUpdatedBy = normalizeUserId(adminUserId)
		oldRecord.TestAccessUpdatedAt = changedAt
		oldRecord.UpdatedAt = changedAt
		return oldRecord
	end)

	if ok then
		self:LogAudit(adminUserId, "SetTestBuildAccess", {
			TargetUserId = targetUserId,
			Enabled = enabled == true,
		})
	end
	return ok, err, record
end

function PermissionService:LogAudit(adminUserId, action, details)
	if not self.auditStore then
		return false
	end

	local record = {
		Action = tostring(action or "Unknown"),
		ActorUserId = normalizeUserId(adminUserId),
		Details = details or {},
		Timestamp = now(),
		ServerJobId = game.JobId,
		PlaceId = game.PlaceId,
		BuildVersion = Constants.BuildVersion,
	}

	local ok, err = pcall(function()
		self.auditStore:SetAsync(buildAuditKey(action), record)
	end)
	if not ok then
		warn(("[DON'T TOUCH IT] Admin audit save failed: %s"):format(tostring(err)))
	end
	return ok
end

function PermissionService:_applyOnlinePlayerAttributes(userId)
	local player = Players:GetPlayerByUserId(userId)
	if player then
		self:ApplyPlayerAttributes(player)
	end
end

function PermissionService:ApplyPlayerAttributes(player)
	if not player then
		return
	end
	local record = self:LoadUser(player.UserId)
	local capabilities = self:GetCapabilities(player.UserId)
	player:SetAttribute("DontTouchItRole", record.Role)
	player:SetAttribute("DontTouchItTestBuildAccess", record.TestBuildAccess == true)
	player:SetAttribute("DontTouchItCanUseDevTools", self:CanUseDevTools(player.UserId))
	player:SetAttribute("DontTouchItCanAccessTestBuild", self:CanAccessTestBuild(player.UserId))
	player:SetAttribute("DontTouchItIsFounder", capabilities.FOUNDER_RECOGNITION == true)

	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if playerGui then
		playerGui:SetAttribute("DontTouchItRole", record.Role)
		playerGui:SetAttribute("DontTouchItTestBuildAccess", record.TestBuildAccess == true)
		playerGui:SetAttribute("DontTouchItCanUseDevTools", self:CanUseDevTools(player.UserId))
	end
end

function PermissionService:GetUserAdminSummary(userId)
	userId = normalizeUserId(userId)
	if not userId then
		return nil
	end

	local record = self:GetRecord(userId)
	local onlinePlayer = Players:GetPlayerByUserId(userId)
	local username = onlinePlayer and onlinePlayer.Name or nil
	local displayName = onlinePlayer and onlinePlayer.DisplayName or nil
	if not username then
		local ok, result = pcall(function()
			return Players:GetNameFromUserIdAsync(userId)
		end)
		if ok then
			username = result
		end
	end
	username = username or ("User%d"):format(userId)
	displayName = displayName or username

	return {
		UserId = userId,
		Username = username,
		DisplayName = displayName,
		Online = onlinePlayer ~= nil,
		Role = record.Role,
		TestBuildAccess = record.TestBuildAccess == true,
		IsRootOwner = self:IsRootOwner(userId),
		Capabilities = cloneDictionary(self:GetCapabilities(userId)),
	}
end

return PermissionService
