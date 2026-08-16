local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local RemoteService = require(script.Parent:WaitForChild("RemoteService"))

local UiLayoutService = {}
UiLayoutService.__index = UiLayoutService

local VALID_KEYS = {
	Action = true,
	Controls = true,
	CrouchSlide = true,
	Drop = true,
	Ping = true,
	Run = true,
}

local function dataKey(player)
	return ("layout_%d"):format(player.UserId)
end

local function sanitizePosition(position)
	if typeof(position) ~= "table" then
		return nil
	end

	local xScale = tonumber(position.XScale) or 0
	local xOffset = tonumber(position.XOffset) or 0
	local yScale = tonumber(position.YScale) or 0
	local yOffset = tonumber(position.YOffset) or 0

	if math.abs(xScale) > 2 or math.abs(yScale) > 2 then
		return nil
	end
	if math.abs(xOffset) > 4000 or math.abs(yOffset) > 4000 then
		return nil
	end

	return {
		XScale = xScale,
		XOffset = math.floor(xOffset + 0.5),
		YScale = yScale,
		YOffset = math.floor(yOffset + 0.5),
	}
end

local function sanitizeLayout(layout)
	if typeof(layout) ~= "table" then
		return {}
	end

	local sanitized = {}
	for key, value in pairs(layout) do
		key = tostring(key)
		if VALID_KEYS[key] then
			local position = sanitizePosition(value)
			if position then
				sanitized[key] = position
			end
		end
	end
	return sanitized
end

function UiLayoutService.new()
	return setmetatable({
		layoutStore = nil,
		remote = nil,
		cacheByUserId = {},
	}, UiLayoutService)
end

function UiLayoutService:Initialize()
	self.remote = RemoteService.GetRemote(Constants.Remotes.UiLayout)

	local ok, store = pcall(function()
		return DataStoreService:GetDataStore(Constants.DataStore.UiLayoutName or "DontTouchItUiLayout_v1")
	end)
	if ok then
		self.layoutStore = store
	else
		warn(("[DON'T TOUCH IT] UI layout DataStore unavailable: %s"):format(tostring(store)))
	end

	self.remote.OnServerEvent:Connect(function(player, payload)
		self:_handleRemote(player, payload)
	end)
end

function UiLayoutService:_load(player)
	local cached = self.cacheByUserId[player.UserId]
	if cached then
		return cached
	end

	local layout = {}
	if self.layoutStore then
		local ok, data = pcall(function()
			return self.layoutStore:GetAsync(dataKey(player))
		end)
		if ok then
			layout = sanitizeLayout(data)
		else
			warn(("[DON'T TOUCH IT] UI layout load failed for %d: %s"):format(player.UserId, tostring(data)))
		end
	end

	self.cacheByUserId[player.UserId] = layout
	return layout
end

function UiLayoutService:_save(player, layout)
	layout = sanitizeLayout(layout)
	self.cacheByUserId[player.UserId] = layout

	if self.layoutStore then
		task.spawn(function()
			local ok, err = pcall(function()
				self.layoutStore:SetAsync(dataKey(player), layout)
			end)
			if not ok then
				warn(("[DON'T TOUCH IT] UI layout save failed for %d: %s"):format(player.UserId, tostring(err)))
			end
		end)
	end

	self.remote:FireClient(player, {
		Action = "Loaded",
		Layout = layout,
	})
end

function UiLayoutService:_handleRemote(player, payload)
	if typeof(payload) ~= "table" then
		return
	end

	if payload.Action == "Request" then
		self.remote:FireClient(player, {
			Action = "Loaded",
			Layout = self:_load(player),
		})
	elseif payload.Action == "Save" then
		self:_save(player, payload.Layout)
	elseif payload.Action == "Reset" then
		self:_save(player, {})
	end
end

return UiLayoutService
