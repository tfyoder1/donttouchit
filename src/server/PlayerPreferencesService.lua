local DataStoreService = game:GetService("DataStoreService")

local PlayerPreferencesService = {}
PlayerPreferencesService.__index = PlayerPreferencesService

local DEFAULT_SCHEMA_VERSION = 1

local function dataKey(playerOrUserId)
	local userId = if typeof(playerOrUserId) == "Instance" then playerOrUserId.UserId else tonumber(playerOrUserId)
	return ("preferences_%d"):format(userId or 0)
end

local function shallowCopy(source)
	local copy = {}
	if typeof(source) == "table" then
		for key, value in pairs(source) do
			copy[key] = value
		end
	end
	return copy
end

local function sanitizePreferenceRecord(record)
	if typeof(record) ~= "table" then
		return {
			SchemaVersion = DEFAULT_SCHEMA_VERSION,
			Layout = {},
			UiOptions = {},
			DevLayout = {},
			Cosmetics = {},
			Storage = {},
		}
	end

	return {
		SchemaVersion = tonumber(record.SchemaVersion) or DEFAULT_SCHEMA_VERSION,
		Layout = typeof(record.Layout) == "table" and record.Layout or {},
		UiOptions = typeof(record.UiOptions) == "table" and record.UiOptions or {},
		DevLayout = typeof(record.DevLayout) == "table" and record.DevLayout or {},
		Cosmetics = typeof(record.Cosmetics) == "table" and record.Cosmetics or {},
		Storage = typeof(record.Storage) == "table" and record.Storage or {},
	}
end

function PlayerPreferencesService.new(constants)
	return setmetatable({
		constants = constants,
		store = nil,
		cacheByUserId = {},
	}, PlayerPreferencesService)
end

function PlayerPreferencesService:Initialize()
	local dataStoreName = self.constants
		and self.constants.DataStore
		and (self.constants.DataStore.PlayerPreferencesName or self.constants.DataStore.UiLayoutName)
		or "DontTouchItPlayerPreferences_v1"

	local ok, store = pcall(function()
		return DataStoreService:GetDataStore(dataStoreName)
	end)
	if ok then
		self.store = store
	else
		warn(("[DON'T TOUCH IT] Player preferences DataStore unavailable: %s"):format(tostring(store)))
	end
end

function PlayerPreferencesService:Load(player)
	local cached = self.cacheByUserId[player.UserId]
	if cached then
		return cached
	end

	local record = nil
	if self.store then
		local ok, data = pcall(function()
			return self.store:GetAsync(dataKey(player))
		end)
		if ok then
			record = data
		else
			warn(("[DON'T TOUCH IT] Player preferences load failed for %d: %s"):format(player.UserId, tostring(data)))
		end
	end

	record = sanitizePreferenceRecord(record)
	self.cacheByUserId[player.UserId] = record
	return record
end

function PlayerPreferencesService:Save(player)
	local record = sanitizePreferenceRecord(self.cacheByUserId[player.UserId])
	self.cacheByUserId[player.UserId] = record

	if not self.store then
		return false
	end

	local ok, err = pcall(function()
		self.store:SetAsync(dataKey(player), record)
	end)
	if not ok then
		warn(("[DON'T TOUCH IT] Player preferences save failed for %d: %s"):format(player.UserId, tostring(err)))
		return false
	end
	return true
end

function PlayerPreferencesService:GetBucket(player, bucketName)
	local record = self:Load(player)
	local bucket = record[bucketName]
	if typeof(bucket) ~= "table" then
		bucket = {}
		record[bucketName] = bucket
	end
	return bucket
end

function PlayerPreferencesService:MergeBucket(player, bucketName, incoming)
	local record = self:Load(player)
	local bucket = shallowCopy(record[bucketName])
	for key, value in pairs(incoming or {}) do
		bucket[key] = value
	end
	record[bucketName] = bucket
	self.cacheByUserId[player.UserId] = record
	self:Save(player)
	return bucket
end

function PlayerPreferencesService:ReplaceBucket(player, bucketName, replacement)
	local record = self:Load(player)
	record[bucketName] = shallowCopy(replacement)
	self.cacheByUserId[player.UserId] = record
	self:Save(player)
	return record[bucketName]
end

return PlayerPreferencesService
