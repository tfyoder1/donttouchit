local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local RemoteService = require(script.Parent:WaitForChild("RemoteService"))

local ModerationService = {}
ModerationService.__index = ModerationService

local BAN_24H_SECONDS = 24 * 60 * 60
local MAX_HISTORY_ITEMS = 60
local MAX_REASON_LENGTH = 160

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

local function trimReason(text)
	text = tostring(text or ""):gsub("[%c\r\n\t]", " "):gsub("%s+", " ")
	text = text:match("^%s*(.-)%s*$") or ""
	return string.sub(text, 1, MAX_REASON_LENGTH)
end

local function isReasonCodeValid(reasonCode)
	return Constants.ModerationReasons and Constants.ModerationReasons[reasonCode] ~= nil
end

local function defaultHistory(userId)
	return {
		Version = 1,
		UserId = userId,
		Warnings = {},
		Bans = {},
		Unbans = {},
		UpdatedAt = now(),
	}
end

local function limitList(items)
	if typeof(items) ~= "table" then
		return {}
	end
	while #items > MAX_HISTORY_ITEMS do
		table.remove(items, 1)
	end
	return items
end

local function sanitizeHistory(userId, data)
	local history = defaultHistory(userId)
	if typeof(data) == "table" then
		history.Warnings = limitList(data.Warnings)
		history.Bans = limitList(data.Bans)
		history.Unbans = limitList(data.Unbans)
		history.UpdatedAt = if typeof(data.UpdatedAt) == "number" then data.UpdatedAt else history.UpdatedAt
	end
	return history
end

local function makeRecordId(prefix)
	return ("%s_%010d_%s"):format(prefix, now(), HttpService:GenerateGUID(false))
end

function ModerationService.new(permissionService)
	local self = setmetatable({}, ModerationService)
	self.permissionService = permissionService
	self.systemMessageRemote = RemoteService.GetRemote(Constants.Remotes.SystemMessage)
	self.historyStore = nil
	self.historyByUserId = {}
	self.loadedByUserId = {}

	local ok, store = pcall(function()
		return DataStoreService:GetDataStore(Constants.DataStore.ModerationName or "DontTouchItModeration_v1")
	end)
	if ok then
		self.historyStore = store
	else
		warn(("[DON'T TOUCH IT] Moderation DataStore unavailable: %s"):format(tostring(store)))
	end

	return self
end

function ModerationService:Initialize()
	Players.PlayerAdded:Connect(function(player)
		task.defer(function()
			self:EnforceActiveBan(player)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self.historyByUserId[player.UserId] = nil
		self.loadedByUserId[player.UserId] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.defer(function()
			self:EnforceActiveBan(player)
		end)
	end
end

function ModerationService:_historyKey(userId)
	return ("moderation_%d"):format(userId)
end

function ModerationService:LoadHistory(userId)
	userId = normalizeUserId(userId)
	if not userId then
		return nil
	end
	if self.loadedByUserId[userId] and self.historyByUserId[userId] then
		return self.historyByUserId[userId]
	end

	local data = nil
	if self.historyStore then
		local ok, result = pcall(function()
			return self.historyStore:GetAsync(self:_historyKey(userId))
		end)
		if ok then
			data = result
		else
			warn(("[DON'T TOUCH IT] Could not load moderation history for %d: %s"):format(userId, tostring(result)))
		end
	end

	local history = sanitizeHistory(userId, data)
	self.historyByUserId[userId] = history
	self.loadedByUserId[userId] = true
	return history
end

function ModerationService:_persistHistory(userId, mutate)
	userId = normalizeUserId(userId)
	if not userId or not self.historyStore then
		return false, "Moderation persistence is unavailable."
	end

	local savedHistory = nil
	local ok, err = pcall(function()
		self.historyStore:UpdateAsync(self:_historyKey(userId), function(oldData)
			local history = sanitizeHistory(userId, oldData)
			local changed = mutate(history)
			if changed == nil then
				return nil
			end
			changed.UpdatedAt = now()
			savedHistory = changed
			return changed
		end)
	end)

	if not ok then
		return false, tostring(err)
	end
	if typeof(savedHistory) ~= "table" then
		return false, "No moderation record was saved."
	end

	self.historyByUserId[userId] = savedHistory
	self.loadedByUserId[userId] = true
	return true, nil, savedHistory
end

function ModerationService:_activeBanFromHistory(history)
	local latestActive = nil
	for _, ban in ipairs(history and history.Bans or {}) do
		if typeof(ban) == "table"
			and typeof(ban.ExpirationTime) == "number"
			and now() < ban.ExpirationTime
			and ban.RemovedAt == nil
		then
			if not latestActive or (ban.StartTime or 0) > (latestActive.StartTime or 0) then
				latestActive = ban
			end
		end
	end
	return latestActive
end

function ModerationService:GetActiveBan(userId)
	local history = self:LoadHistory(userId)
	return self:_activeBanFromHistory(history)
end

function ModerationService:GetSummary(userId)
	local history = self:LoadHistory(userId) or defaultHistory(normalizeUserId(userId) or 0)
	local activeBan = self:_activeBanFromHistory(history)
	return {
		WarningCount = #(history.Warnings or {}),
		BanCount = #(history.Bans or {}),
		ActiveBan = activeBan,
		Status = if activeBan then "Banned" else "Normal",
	}
end

function ModerationService:GetHistory(userId)
	local history = self:LoadHistory(userId)
	if not history then
		return nil
	end
	return {
		UserId = history.UserId,
		Warnings = table.clone(history.Warnings or {}),
		Bans = table.clone(history.Bans or {}),
		Unbans = table.clone(history.Unbans or {}),
		UpdatedAt = history.UpdatedAt,
	}
end

function ModerationService:_validateReason(reasonCode, reasonText)
	reasonCode = tostring(reasonCode or "OTHER")
	if not isReasonCodeValid(reasonCode) then
		return nil, nil, "Invalid moderation reason."
	end
	reasonText = trimReason(reasonText)
	if reasonText == "" then
		reasonText = Constants.ModerationReasons[reasonCode] or reasonCode
	end
	if reasonCode == "OTHER" and reasonText == "Other" then
		return nil, nil, "A short reason is required for Other."
	end
	return reasonCode, reasonText, nil
end

function ModerationService:IssueWarning(adminUserId, targetUserId, reasonCode, reasonText)
	adminUserId = normalizeUserId(adminUserId)
	targetUserId = normalizeUserId(targetUserId)
	if not self.permissionService:HasPermission(adminUserId, "MOD_WARN_PLAYER") then
		return false, "You do not have warning permission."
	end
	local canModerate, moderateMessage = self.permissionService:CanModerateTarget(adminUserId, targetUserId)
	if not canModerate then
		return false, moderateMessage
	end
	reasonCode, reasonText, moderateMessage = self:_validateReason(reasonCode, reasonText)
	if not reasonCode then
		return false, moderateMessage
	end

	local record = {
		Id = makeRecordId("warning"),
		TargetUserId = targetUserId,
		ModeratorUserId = adminUserId,
		Timestamp = now(),
		ReasonCode = reasonCode,
		ReasonText = reasonText,
		ServerJobId = game.JobId,
		BuildVersion = Constants.BuildVersion,
	}

	local ok, err = self:_persistHistory(targetUserId, function(history)
		table.insert(history.Warnings, record)
		limitList(history.Warnings)
		return history
	end)
	if not ok then
		return false, err
	end

	self.permissionService:LogAudit(adminUserId, "WarnPlayer", {
		TargetUserId = targetUserId,
		ReasonCode = reasonCode,
		ReasonText = reasonText,
	})

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if targetPlayer then
		self.systemMessageRemote:FireClient(
			targetPlayer,
			("FACILITY NOTICE\nYou have received a warning from the game moderation team.\nReason: %s\nPlease treat other players respectfully."):format(reasonText)
		)
	end

	return true, "Warning issued."
end

function ModerationService:Ban24Hours(adminUserId, targetUserId, reasonCode, reasonText)
	adminUserId = normalizeUserId(adminUserId)
	targetUserId = normalizeUserId(targetUserId)
	if not self.permissionService:HasPermission(adminUserId, "MOD_BAN_24H") then
		return false, "You do not have 24-hour ban permission."
	end
	local canModerate, moderateMessage = self.permissionService:CanModerateTarget(adminUserId, targetUserId)
	if not canModerate then
		return false, moderateMessage
	end
	reasonCode, reasonText, moderateMessage = self:_validateReason(reasonCode, reasonText)
	if not reasonCode then
		return false, moderateMessage
	end

	local startTime = now()
	local ban = {
		Id = makeRecordId("ban24h"),
		TargetUserId = targetUserId,
		ModeratorUserId = adminUserId,
		StartTime = startTime,
		ExpirationTime = startTime + BAN_24H_SECONDS,
		Duration = BAN_24H_SECONDS,
		ReasonCode = reasonCode,
		ReasonText = reasonText,
		ServerJobId = game.JobId,
		BuildVersion = Constants.BuildVersion,
	}

	local ok, err = self:_persistHistory(targetUserId, function(history)
		table.insert(history.Bans, ban)
		limitList(history.Bans)
		return history
	end)
	if not ok then
		return false, err
	end

	self.permissionService:LogAudit(adminUserId, "Ban24Hours", {
		TargetUserId = targetUserId,
		ReasonCode = reasonCode,
		ReasonText = reasonText,
		ExpirationTime = ban.ExpirationTime,
	})

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if targetPlayer then
		self.systemMessageRemote:FireClient(
			targetPlayer,
			("FACILITY NOTICE\nYou are temporarily unable to remain in this experience.\nReason: %s"):format(reasonText)
		)
		task.delay(0.8, function()
			if targetPlayer.Parent then
				targetPlayer:Kick(("You are temporarily unable to enter this experience.\nReason: %s\nTime remaining: approximately 24 hours."):format(reasonText))
			end
		end)
	end

	return true, "24-hour ban saved."
end

function ModerationService:RemoveActiveBan(adminUserId, targetUserId, reasonText)
	adminUserId = normalizeUserId(adminUserId)
	targetUserId = normalizeUserId(targetUserId)
	if not self.permissionService:HasPermission(adminUserId, "MOD_REMOVE_BAN") then
		return false, "You do not have ban removal permission."
	end

	reasonText = trimReason(reasonText)
	local removedRecord = nil
	local ok, err = self:_persistHistory(targetUserId, function(history)
		for index = #history.Bans, 1, -1 do
			local ban = history.Bans[index]
			if typeof(ban) == "table"
				and typeof(ban.ExpirationTime) == "number"
				and now() < ban.ExpirationTime
				and ban.RemovedAt == nil
			then
				ban.RemovedAt = now()
				ban.RemovedByUserId = adminUserId
				ban.RemovalReason = reasonText
				removedRecord = {
					Id = makeRecordId("unban"),
					TargetUserId = targetUserId,
					ModeratorUserId = adminUserId,
					Timestamp = now(),
					OriginalBanId = ban.Id,
					ReasonText = reasonText,
					ServerJobId = game.JobId,
					BuildVersion = Constants.BuildVersion,
				}
				table.insert(history.Unbans, removedRecord)
				limitList(history.Unbans)
				return history
			end
		end
		return nil
	end)
	if not ok then
		return false, err
	end
	if not removedRecord then
		return false, "No active ban found."
	end

	self.permissionService:LogAudit(adminUserId, "RemoveActiveBan", {
		TargetUserId = targetUserId,
		OriginalBanId = removedRecord.OriginalBanId,
		ReasonText = reasonText,
	})
	return true, "Active ban removed."
end

function ModerationService:EnforceActiveBan(player)
	if not player or not player.Parent then
		return false
	end
	local activeBan = self:GetActiveBan(player.UserId)
	if not activeBan then
		return false
	end

	local remaining = math.max(1, activeBan.ExpirationTime - now())
	local hours = math.max(1, math.ceil(remaining / 3600))
	player:Kick(
		("You are temporarily unable to enter this experience.\nReason: %s\nTime remaining: approximately %d hours."):format(
			activeBan.ReasonText or "Temporary experience ban",
			hours
		)
	)
	return true
end

return ModerationService
