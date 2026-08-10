local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local RemoteService = require(script.Parent:WaitForChild("RemoteService"))

local DiscoveryService = {}
DiscoveryService.__index = DiscoveryService

local DEFAULT_ROOM_ID = Constants.RoomOrder[1]

local function getDataKey(player)
	return ("player_%d"):format(player.UserId)
end

local function buildDiscoveryList(foundById)
	local discoveries = {}

	for discoveryId, unlocked in pairs(foundById or {}) do
		if unlocked and Constants.GetDiscovery(discoveryId) then
			table.insert(discoveries, discoveryId)
		end
	end

	table.sort(discoveries)
	return discoveries
end

function DiscoveryService.new()
	local self = setmetatable({}, DiscoveryService)
	self.discoveryByUserId = {}
	self.hintsByUserId = {}
	self.lastUnlockedRoomByUserId = {}
	self.hasSavedDataByUserId = {}
	self.loadedByUserId = {}
	self.saveQueuedByUserId = {}
	self.saveWarningShownByUserId = {}
	self.dataStore = nil
	self.remote = RemoteService.GetRemote(Constants.Remotes.DiscoveryUpdate)
	self.systemMessageRemote = RemoteService.GetRemote(Constants.Remotes.SystemMessage)
	self._unlockedEvent = Instance.new("BindableEvent")
	self.DiscoveryUnlocked = self._unlockedEvent.Event

	local ok, dataStore = pcall(function()
		return DataStoreService:GetDataStore(Constants.DataStore.Name)
	end)
	if ok then
		self.dataStore = dataStore
	else
		warn(("[DON'T TOUCH IT] Progress DataStore unavailable: %s"):format(tostring(dataStore)))
	end

	return self
end

function DiscoveryService:Initialize()
	Players.PlayerAdded:Connect(function(player)
		self:_loadPlayer(player)
		self:_sendSnapshot(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:_savePlayer(player)
		self.discoveryByUserId[player.UserId] = nil
		self.hintsByUserId[player.UserId] = nil
		self.lastUnlockedRoomByUserId[player.UserId] = nil
		self.hasSavedDataByUserId[player.UserId] = nil
		self.loadedByUserId[player.UserId] = nil
		self.saveQueuedByUserId[player.UserId] = nil
		self.saveWarningShownByUserId[player.UserId] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		self:_loadPlayer(player)
		self:_sendSnapshot(player)
	end

	task.spawn(function()
		while true do
			task.wait(Constants.DataStore.AutosaveSeconds)
			for _, player in ipairs(Players:GetPlayers()) do
				self:_savePlayer(player)
			end
		end
	end)

	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			self:_savePlayer(player)
		end
	end)
end

function DiscoveryService:_ensurePlayer(player)
	if not self.discoveryByUserId[player.UserId] then
		self.discoveryByUserId[player.UserId] = {}
	end

	if not self.hintsByUserId[player.UserId] then
		self.hintsByUserId[player.UserId] = 0
	end

	if not self.lastUnlockedRoomByUserId[player.UserId] then
		self.lastUnlockedRoomByUserId[player.UserId] = DEFAULT_ROOM_ID
	end

	if self.hasSavedDataByUserId[player.UserId] == nil then
		self.hasSavedDataByUserId[player.UserId] = false
	end

	if self.loadedByUserId[player.UserId] == nil then
		self.loadedByUserId[player.UserId] = false
	end
end

function DiscoveryService:_warnSaveIssue(player)
	if not player or not player.Parent or self.saveWarningShownByUserId[player.UserId] then
		return
	end

	self.saveWarningShownByUserId[player.UserId] = true
	self.systemMessageRemote:FireClient(
		player,
		"Progress saving is unavailable in this session. In Studio, publish the game and enable API Services to test saves."
	)
end

function DiscoveryService:_loadPlayer(player)
	self.discoveryByUserId[player.UserId] = {}
	self.hintsByUserId[player.UserId] = 0
	self.lastUnlockedRoomByUserId[player.UserId] = DEFAULT_ROOM_ID
	self.hasSavedDataByUserId[player.UserId] = false
	self.loadedByUserId[player.UserId] = false

	if not self.dataStore then
		self.loadedByUserId[player.UserId] = true
		return
	end

	local ok, data = pcall(function()
		return self.dataStore:GetAsync(getDataKey(player))
	end)

	if not ok then
		warn(("[DON'T TOUCH IT] Could not load progress for %s: %s"):format(player.Name, tostring(data)))
		self.loadedByUserId[player.UserId] = true
		self:_warnSaveIssue(player)
		return
	end

	if typeof(data) ~= "table" then
		self.loadedByUserId[player.UserId] = true
		return
	end

	self.hasSavedDataByUserId[player.UserId] = true

	if typeof(data.Discoveries) == "table" then
		for _, discoveryId in ipairs(data.Discoveries) do
			if Constants.GetDiscovery(discoveryId) then
				self.discoveryByUserId[player.UserId][discoveryId] = true
			end
		end
	end

	if typeof(data.Hints) == "number" then
		self.hintsByUserId[player.UserId] = math.max(0, math.floor(data.Hints))
	end

	if typeof(data.LastUnlockedRoomId) == "string" and Constants.GetRoom(data.LastUnlockedRoomId) then
		self.lastUnlockedRoomByUserId[player.UserId] = data.LastUnlockedRoomId
	end

	self:_refreshLastUnlockedRoom(player, false)
	self.loadedByUserId[player.UserId] = true
end

function DiscoveryService:IsLoaded(player)
	return player ~= nil and self.loadedByUserId[player.UserId] == true
end

function DiscoveryService:_buildSaveData(player)
	self:_ensurePlayer(player)

	return {
		Version = 1,
		Discoveries = buildDiscoveryList(self.discoveryByUserId[player.UserId]),
		Hints = self.hintsByUserId[player.UserId] or 0,
		LastUnlockedRoomId = self:GetLastUnlockedRoomId(player),
	}
end

function DiscoveryService:_savePlayer(player)
	if not player or not self.dataStore or not self.discoveryByUserId[player.UserId] then
		self:_warnSaveIssue(player)
		return false
	end

	local data = self:_buildSaveData(player)
	local ok = false
	local errorMessage = nil

	for attempt = 1, Constants.DataStore.RetryCount do
		ok, errorMessage = pcall(function()
			self.dataStore:SetAsync(getDataKey(player), data)
		end)

		if ok then
			self.hasSavedDataByUserId[player.UserId] = true
			return true
		end

		task.wait(0.4 * attempt)
	end

	if not ok then
		warn(("[DON'T TOUCH IT] Could not save progress for %s: %s"):format(player.Name, tostring(errorMessage)))
		self:_warnSaveIssue(player)
	end

	return false
end

function DiscoveryService:_queueSave(player)
	if not player or not player.Parent or not self.dataStore then
		return
	end

	if self.saveQueuedByUserId[player.UserId] then
		return
	end

	self.saveQueuedByUserId[player.UserId] = true
	task.delay(0.25, function()
		self.saveQueuedByUserId[player.UserId] = nil
		if player.Parent then
			self:_savePlayer(player)
		end
	end)
end

function DiscoveryService:_countForPlayer(player, discoveryOrder)
	self:_ensurePlayer(player)

	local count = 0
	for _, discoveryId in ipairs(discoveryOrder or Constants.DiscoveryOrder) do
		if self.discoveryByUserId[player.UserId][discoveryId] then
			count += 1
		end
	end

	return count
end

function DiscoveryService:GetDiscoveryCount(player, discoveryOrder)
	return self:_countForPlayer(player, discoveryOrder)
end

function DiscoveryService:GetRoomDiscoveryCount(player, roomId)
	local room = Constants.GetRoom(roomId)
	if not room then
		return 0
	end

	return self:_countForPlayer(player, room.DiscoveryOrder)
end

function DiscoveryService:_buildRoomSummaries(player)
	local summaries = {}

	for _, roomId in ipairs(Constants.RoomOrder) do
		local room = Constants.GetRoom(roomId)
		if room then
			table.insert(summaries, {
				RoomId = roomId,
				Name = room.Name,
				Count = self:_countForPlayer(player, room.DiscoveryOrder),
				Total = #room.DiscoveryOrder,
			})
		end
	end

	return summaries
end

function DiscoveryService:HasAll(player, discoveryOrder)
	self:_ensurePlayer(player)

	for _, discoveryId in ipairs(discoveryOrder) do
		if not self.discoveryByUserId[player.UserId][discoveryId] then
			return false
		end
	end

	return true
end

function DiscoveryService:IsRoomUnlocked(player, roomId)
	if roomId == DEFAULT_ROOM_ID then
		return true
	end

	local requiredRoomId, requiredCount = Constants.GetRoomUnlockRequirement(roomId)
	if not requiredRoomId or not requiredCount then
		return false
	end

	return self:GetRoomDiscoveryCount(player, requiredRoomId) >= requiredCount
end

function DiscoveryService:CanEnterHall(player)
	return self:IsRoomUnlocked(player, "SnackLab")
end

function DiscoveryService:GetHallUnlockRequirementText(player)
	local requiredRoomId, requiredCount = Constants.GetRoomUnlockRequirement("SnackLab")
	local room = Constants.GetRoom(requiredRoomId)
	local currentCount = self:GetRoomDiscoveryCount(player, requiredRoomId)

	if not room or not requiredCount then
		return "The hallway is not ready yet."
	end

	return ("The hallway wants %d %s discoveries first. You have %d."):format(requiredCount, room.Name, currentCount)
end

function DiscoveryService:GetUnlockedRoomCount(player)
	local count = 0

	for _, roomId in ipairs(Constants.RoomOrder) do
		if self:IsRoomUnlocked(player, roomId) then
			count += 1
		end
	end

	return count
end

function DiscoveryService:_refreshLastUnlockedRoom(player, shouldSave)
	self:_ensurePlayer(player)

	local lastUnlockedRoomId = DEFAULT_ROOM_ID
	for _, roomId in ipairs(Constants.RoomOrder) do
		if self:IsRoomUnlocked(player, roomId) then
			lastUnlockedRoomId = roomId
		end
	end

	if self.lastUnlockedRoomByUserId[player.UserId] == lastUnlockedRoomId then
		return false
	end

	self.lastUnlockedRoomByUserId[player.UserId] = lastUnlockedRoomId
	if shouldSave then
		self:_queueSave(player)
	end

	return true
end

function DiscoveryService:GetLastUnlockedRoomId(player)
	self:_refreshLastUnlockedRoom(player, false)
	return self.lastUnlockedRoomByUserId[player.UserId] or DEFAULT_ROOM_ID
end

function DiscoveryService:GetNextPendingHighlight(player, roomId)
	if not player or not player.Parent then
		return nil
	end

	self:_ensurePlayer(player)

	local room = Constants.GetRoom(roomId)
	if not room then
		return nil
	end

	local foundById = self.discoveryByUserId[player.UserId]
	for _, discoveryId in ipairs(room.DiscoveryOrder) do
		local targetTag = Constants.DiscoveryHighlightTargets[discoveryId]
		if targetTag and not foundById[discoveryId] then
			return discoveryId, targetTag
		end
	end

	return nil
end

function DiscoveryService:_sendSnapshot(player)
	local lastUnlockedRoomId = self:GetLastUnlockedRoomId(player)
	local lastUnlockedRoom = Constants.GetRoom(lastUnlockedRoomId)

	self.remote:FireClient(player, {
		Type = "Snapshot",
		Count = self:_countForPlayer(player),
		Total = Constants.TotalDiscoveries,
		Rooms = self:_buildRoomSummaries(player),
		Hints = self:GetHintCount(player),
		HasSavedData = self.hasSavedDataByUserId[player.UserId] == true,
		LastUnlockedRoomId = lastUnlockedRoomId,
		LastUnlockedRoomName = lastUnlockedRoom and lastUnlockedRoom.Name or "TV Room",
	})
end

function DiscoveryService:Unlock(player, discoveryId)
	if not player or not player.Parent then
		return false
	end

	local discovery = Constants.GetDiscovery(discoveryId)
	if not discovery then
		warn(("Unknown discovery id: %s"):format(tostring(discoveryId)))
		return false
	end

	self:_ensurePlayer(player)

	if self.discoveryByUserId[player.UserId][discoveryId] then
		return false
	end

	self.discoveryByUserId[player.UserId][discoveryId] = true
	self:_refreshLastUnlockedRoom(player, false)

	local lastUnlockedRoomId = self:GetLastUnlockedRoomId(player)
	local lastUnlockedRoom = Constants.GetRoom(lastUnlockedRoomId)

	self.remote:FireClient(player, {
		Type = "Unlocked",
		Id = discovery.Id,
		Name = discovery.Name,
		Count = self:_countForPlayer(player),
		Total = Constants.TotalDiscoveries,
		Rooms = self:_buildRoomSummaries(player),
		Hints = self:GetHintCount(player),
		HasSavedData = true,
		LastUnlockedRoomId = lastUnlockedRoomId,
		LastUnlockedRoomName = lastUnlockedRoom and lastUnlockedRoom.Name or "TV Room",
	})

	self._unlockedEvent:Fire(player, discovery.Id)
	self:_queueSave(player)

	return true
end

function DiscoveryService:UnlockForPlayers(players, discoveryId)
	for _, player in ipairs(players) do
		self:Unlock(player, discoveryId)
	end
end

function DiscoveryService:UnlockForAll(discoveryId)
	self:UnlockForPlayers(Players:GetPlayers(), discoveryId)
end

function DiscoveryService:GetHintCount(player)
	if not player then
		return 0
	end

	self:_ensurePlayer(player)
	return self.hintsByUserId[player.UserId] or 0
end

function DiscoveryService:GrantHints(player, count)
	if not player or not player.Parent then
		return 0
	end

	self:_ensurePlayer(player)
	self.hintsByUserId[player.UserId] += math.max(0, count or 0)
	self:_sendSnapshot(player)
	self:_queueSave(player)
	return self.hintsByUserId[player.UserId]
end

function DiscoveryService:GetRoomSnapshot(player, roomId)
	if not player or not player.Parent then
		return nil
	end

	self:_ensurePlayer(player)

	local room = Constants.GetRoom(roomId) or Constants.GetRoom(Constants.RoomOrder[1])
	if not room then
		return nil
	end

	local discoveries = {}
	local foundById = self.discoveryByUserId[player.UserId]

	for _, discoveryId in ipairs(room.DiscoveryOrder) do
		local discovery = Constants.GetDiscovery(discoveryId)
		if discovery then
			local unlocked = foundById[discoveryId] == true
			table.insert(discoveries, {
				Id = discovery.Id,
				Name = unlocked and discovery.Name or "???",
				Unlocked = unlocked,
			})
		end
	end

	return {
		Type = "RoomSnapshot",
		RoomId = room.Id,
		RoomName = room.Name,
		Count = self:_countForPlayer(player, room.DiscoveryOrder),
		Total = #room.DiscoveryOrder,
		Hints = self:GetHintCount(player),
		Discoveries = discoveries,
		Rooms = self:_buildRoomSummaries(player),
	}
end

function DiscoveryService:_getNextDiscovery(player, roomId)
	if not player or not player.Parent then
		return nil, "No player."
	end

	self:_ensurePlayer(player)

	local room = Constants.GetRoom(roomId)
	if not room then
		return nil, "That book page is missing."
	end

	local foundById = self.discoveryByUserId[player.UserId]

	for _, discoveryId in ipairs(room.DiscoveryOrder) do
		if not foundById[discoveryId] then
			return Constants.GetDiscovery(discoveryId), nil
		end
	end

	return nil, "Everything in this room is already found."
end

function DiscoveryService:GetFreeHint(player, roomId)
	local nextDiscovery, errorText = self:_getNextDiscovery(player, roomId)
	if not nextDiscovery then
		return nil, errorText
	end

	local targetTag = Constants.DiscoveryHighlightTargets[nextDiscovery.Id]
	local targetText = "one object in this room"

	if targetTag == Constants.Tags.MainButton or targetTag == Constants.Tags.SnackButton then
		targetText = "the center button"
	elseif targetTag == Constants.Tags.FloorSection then
		targetText = "the floor"
	elseif targetTag == Constants.Tags.ReferenceBook then
		targetText = "the room log"
	elseif targetTag then
		targetText = "one suspicious object"
	end

	return ("Free clue: %s still has something left to give."):format(targetText), nil
end

function DiscoveryService:GetPaidHintText(player, roomId)
	local nextDiscovery, errorText = self:_getNextDiscovery(player, roomId)
	if not nextDiscovery then
		return nil, errorText
	end

	return nextDiscovery.Hint or "Try one of the untouched objects in this room.", nil
end

function DiscoveryService:GetFullRevealText(player, roomId)
	local nextDiscovery, errorText = self:_getNextDiscovery(player, roomId)
	if not nextDiscovery then
		return nil, errorText
	end

	local hint = nextDiscovery.Hint or "Try one of the untouched objects in this room."
	return ("Full reveal: %s. %s"):format(nextDiscovery.Name, hint), nil
end

function DiscoveryService:UseHint(player, roomId)
	if not player or not player.Parent then
		return nil, "No player."
	end

	self:_ensurePlayer(player)

	if self.hintsByUserId[player.UserId] <= 0 then
		return nil, "No hints left."
	end

	local hintText, errorText = self:GetPaidHintText(player, roomId)
	if not hintText then
		return nil, errorText
	end

	self.hintsByUserId[player.UserId] -= 1
	self:_sendSnapshot(player)
	self:_queueSave(player)

	return hintText, nil
end

function DiscoveryService:UseFullReveal(player, roomId, cost)
	if not player or not player.Parent then
		return nil, "No player."
	end

	self:_ensurePlayer(player)

	local revealCost = math.max(0, cost or Constants.NoTouch.FullRevealHintCost or 3)
	if self.hintsByUserId[player.UserId] < revealCost then
		return nil, ("Full reveal needs %d hints."):format(revealCost)
	end

	local revealText, errorText = self:GetFullRevealText(player, roomId)
	if not revealText then
		return nil, errorText
	end

	self.hintsByUserId[player.UserId] -= revealCost
	self:_sendSnapshot(player)
	self:_queueSave(player)

	return revealText, nil
end

return DiscoveryService
