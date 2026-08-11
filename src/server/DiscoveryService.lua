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

local function buildSecretRoomList(foundByRoomId)
	local rooms = {}

	for roomId, unlocked in pairs(foundByRoomId or {}) do
		if unlocked and Constants.SecretDoors and Constants.SecretDoors[roomId] then
			table.insert(rooms, roomId)
		end
	end

	table.sort(rooms)
	return rooms
end

local function cloneDictionary(source)
	local copy = {}

	for key, value in pairs(source or {}) do
		copy[key] = value
	end

	return copy
end

local function dictionaryFromList(items)
	local dictionary = {}

	for _, item in ipairs(items or {}) do
		dictionary[item] = true
	end

	return dictionary
end

local function buildDiscoveryStateList(foundById)
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
	self.cluesByUserId = {}
	self.cluedDiscoveriesByUserId = {}
	self.revealedDiscoveriesByUserId = {}
	self.secretKeysByUserId = {}
	self.secretDoorRevealsByUserId = {}
	self.lastUnlockedRoomByUserId = {}
	self.devOverrideByUserId = {}
	self.hasSavedDataByUserId = {}
	self.loadedByUserId = {}
	self.saveQueuedByUserId = {}
	self.saveWarningShownByUserId = {}
	self.dataStore = nil
	self.remote = RemoteService.GetRemote(Constants.Remotes.DiscoveryUpdate)
	self.systemMessageRemote = RemoteService.GetRemote(Constants.Remotes.SystemMessage)
	self._unlockedEvent = Instance.new("BindableEvent")
	self.DiscoveryUnlocked = self._unlockedEvent.Event
	self._secretDoorChangedEvent = Instance.new("BindableEvent")
	self.SecretDoorChanged = self._secretDoorChangedEvent.Event

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
		self:_grantRoomCompletionSecretKeys(player)
		self:_syncSecretKeyTools(player)
		self:_sendSnapshot(player)

		player.CharacterAdded:Connect(function()
			task.delay(0.25, function()
				if player.Parent then
					self:_syncSecretKeyTools(player)
				end
			end)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:_savePlayer(player)
		self.discoveryByUserId[player.UserId] = nil
		self.hintsByUserId[player.UserId] = nil
		self.cluesByUserId[player.UserId] = nil
		self.cluedDiscoveriesByUserId[player.UserId] = nil
		self.revealedDiscoveriesByUserId[player.UserId] = nil
		self.secretKeysByUserId[player.UserId] = nil
		self.secretDoorRevealsByUserId[player.UserId] = nil
		self.lastUnlockedRoomByUserId[player.UserId] = nil
		self.devOverrideByUserId[player.UserId] = nil
		self.hasSavedDataByUserId[player.UserId] = nil
		self.loadedByUserId[player.UserId] = nil
		self.saveQueuedByUserId[player.UserId] = nil
		self.saveWarningShownByUserId[player.UserId] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		self:_loadPlayer(player)
		self:_grantRoomCompletionSecretKeys(player)
		self:_syncSecretKeyTools(player)
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

	if not self.cluesByUserId[player.UserId] then
		self.cluesByUserId[player.UserId] = 0
	end

	if not self.cluedDiscoveriesByUserId[player.UserId] then
		self.cluedDiscoveriesByUserId[player.UserId] = {}
	end

	if not self.revealedDiscoveriesByUserId[player.UserId] then
		self.revealedDiscoveriesByUserId[player.UserId] = {}
	end

	if not self.secretKeysByUserId[player.UserId] then
		self.secretKeysByUserId[player.UserId] = {}
	end

	if not self.secretDoorRevealsByUserId[player.UserId] then
		self.secretDoorRevealsByUserId[player.UserId] = {}
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

function DiscoveryService:_captureRuntimeState(player)
	self:_ensurePlayer(player)

	return {
		DiscoveryById = cloneDictionary(self.discoveryByUserId[player.UserId]),
		Hints = self.hintsByUserId[player.UserId] or 0,
		Clues = self.cluesByUserId[player.UserId] or 0,
		CluedDiscoveriesById = cloneDictionary(self.cluedDiscoveriesByUserId[player.UserId]),
		RevealedDiscoveriesById = cloneDictionary(self.revealedDiscoveriesByUserId[player.UserId]),
		SecretKeysByRoomId = cloneDictionary(self.secretKeysByUserId[player.UserId]),
		SecretDoorRevealsByRoomId = cloneDictionary(self.secretDoorRevealsByUserId[player.UserId]),
		LastUnlockedRoomId = self.lastUnlockedRoomByUserId[player.UserId] or DEFAULT_ROOM_ID,
	}
end

function DiscoveryService:_applyRuntimeState(player, state)
	self.discoveryByUserId[player.UserId] = cloneDictionary(state.DiscoveryById)
	self.hintsByUserId[player.UserId] = state.Hints or 0
	self.cluesByUserId[player.UserId] = state.Clues or 0
	self.cluedDiscoveriesByUserId[player.UserId] = cloneDictionary(state.CluedDiscoveriesById)
	self.revealedDiscoveriesByUserId[player.UserId] = cloneDictionary(state.RevealedDiscoveriesById)
	self.secretKeysByUserId[player.UserId] = cloneDictionary(state.SecretKeysByRoomId)
	self.secretDoorRevealsByUserId[player.UserId] = cloneDictionary(state.SecretDoorRevealsByRoomId)
	self.lastUnlockedRoomByUserId[player.UserId] = state.LastUnlockedRoomId or DEFAULT_ROOM_ID
end

function DiscoveryService:IsDevOverrideActive(player)
	return player ~= nil and self.devOverrideByUserId[player.UserId] ~= nil
end

function DiscoveryService:EnableDevOverride(player)
	if not player or not player.Parent then
		return false
	end

	self:_ensurePlayer(player)
	if self.devOverrideByUserId[player.UserId] then
		return true
	end

	local realState = self:_captureRuntimeState(player)
	self.devOverrideByUserId[player.UserId] = {
		RealState = realState,
	}
	self:_applyRuntimeState(player, realState)
	self:_sendSnapshot(player)
	return true
end

function DiscoveryService:RestoreNormalProgressState(player)
	if not player or not player.Parent then
		return false
	end

	local override = self.devOverrideByUserId[player.UserId]
	if not override then
		self:_sendSnapshot(player)
		return false
	end

	self:_applyRuntimeState(player, override.RealState)
	self.devOverrideByUserId[player.UserId] = nil
	self:_syncSecretKeyTools(player)
	self:_sendSnapshot(player)
	self._secretDoorChangedEvent:Fire(player)
	self._unlockedEvent:Fire(player)
	return true
end

function DiscoveryService:_getRoomDiscoverySet(roomId)
	local room = Constants.GetRoom(roomId)
	if not room then
		return nil
	end

	local allowedById = {}
	for _, discoveryId in ipairs(room.DiscoveryOrder or {}) do
		allowedById[discoveryId] = true
	end

	for _, discoveryId in ipairs(Constants.SecretDiscoveryOrderByRoom[roomId] or {}) do
		allowedById[discoveryId] = true
	end

	return allowedById
end

function DiscoveryService:GetDevPresetDiscoveryIds(roomId, presetName)
	local room = Constants.GetRoom(roomId)
	if not room then
		return {}
	end

	local selected = {}
	if presetName == "Fresh" then
		return selected
	end

	local targetCount = #room.DiscoveryOrder
	if presetName == "Midway" then
		targetCount = math.max(1, math.floor(#room.DiscoveryOrder / 2))
	elseif presetName ~= "Completed" then
		return selected
	end

	for index, discoveryId in ipairs(room.DiscoveryOrder) do
		if index > targetCount then
			break
		end
		table.insert(selected, discoveryId)
	end

	return selected
end

function DiscoveryService:_finalizeDevStateChange(player, roomId)
	self:_refreshLastUnlockedRoom(player, false)
	self:_grantRoomCompletionSecretKeys(player)
	self:_syncSecretKeyTools(player)
	self:_sendSnapshot(player)
	self._secretDoorChangedEvent:Fire(player, roomId)
	self._unlockedEvent:Fire(player)
end

function DiscoveryService:SetDevRoomDiscoveries(player, roomId, discoveryIds)
	if not player or not player.Parent or not Constants.GetRoom(roomId) then
		return false
	end

	self:EnableDevOverride(player)
	self:_ensurePlayer(player)

	local selectedById = dictionaryFromList(discoveryIds)
	local foundById = self.discoveryByUserId[player.UserId]
	local cluedById = self.cluedDiscoveriesByUserId[player.UserId]
	local revealedById = self.revealedDiscoveriesByUserId[player.UserId]
	local allowedById = self:_getRoomDiscoverySet(roomId)

	for discoveryId in pairs(allowedById) do
		if selectedById[discoveryId] then
			foundById[discoveryId] = true
		else
			foundById[discoveryId] = nil
			cluedById[discoveryId] = nil
			revealedById[discoveryId] = nil
		end
	end

	if Constants.SecretDoors and Constants.SecretDoors[roomId] and not self:IsRoomComplete(player, roomId) then
		self.secretKeysByUserId[player.UserId][roomId] = nil
		self.secretDoorRevealsByUserId[player.UserId][roomId] = nil
	end

	self:_finalizeDevStateChange(player, roomId)
	return true
end

function DiscoveryService:SetDevDiscoveryCompletion(player, roomId, discoveryId, completed)
	local allowedById = self:_getRoomDiscoverySet(roomId)
	if not player or not player.Parent or not allowedById or not allowedById[discoveryId] then
		return false
	end

	self:EnableDevOverride(player)
	self:_ensurePlayer(player)

	if completed then
		self.discoveryByUserId[player.UserId][discoveryId] = true
	else
		self.discoveryByUserId[player.UserId][discoveryId] = nil
		self.cluedDiscoveriesByUserId[player.UserId][discoveryId] = nil
		self.revealedDiscoveriesByUserId[player.UserId][discoveryId] = nil
	end

	if Constants.SecretDoors and Constants.SecretDoors[roomId] and not self:IsRoomComplete(player, roomId) then
		self.secretKeysByUserId[player.UserId][roomId] = nil
	end

	self:_finalizeDevStateChange(player, roomId)
	return true
end

function DiscoveryService:UnlockAllDiscoveriesForDevSession(player)
	if not player or not player.Parent then
		return false
	end

	self:EnableDevOverride(player)
	self:_ensurePlayer(player)

	for _, discovery in pairs(Constants.Discoveries) do
		self.discoveryByUserId[player.UserId][discovery.Id] = true
	end

	for roomId in pairs(Constants.SecretDoors or {}) do
		self.secretKeysByUserId[player.UserId][roomId] = true
		self.secretDoorRevealsByUserId[player.UserId][roomId] = true
	end

	self:_finalizeDevStateChange(player)
	return true
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
	self.cluesByUserId[player.UserId] = 0
	self.cluedDiscoveriesByUserId[player.UserId] = {}
	self.revealedDiscoveriesByUserId[player.UserId] = {}
	self.secretKeysByUserId[player.UserId] = {}
	self.secretDoorRevealsByUserId[player.UserId] = {}
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

	if typeof(data.Clues) == "number" then
		self.cluesByUserId[player.UserId] = math.max(0, math.floor(data.Clues))
	end

	if typeof(data.Inventory) == "table" then
		if typeof(data.Inventory.Clues) == "number" then
			self.cluesByUserId[player.UserId] = math.max(0, math.floor(data.Inventory.Clues))
		end

		if typeof(data.Inventory.CluedDiscoveries) == "table" then
			for _, discoveryId in ipairs(data.Inventory.CluedDiscoveries) do
				if Constants.GetDiscovery(discoveryId) then
					self.cluedDiscoveriesByUserId[player.UserId][discoveryId] = true
				end
			end
		end

		if typeof(data.Inventory.RevealedDiscoveries) == "table" then
			for _, discoveryId in ipairs(data.Inventory.RevealedDiscoveries) do
				if Constants.GetDiscovery(discoveryId) then
					self.cluedDiscoveriesByUserId[player.UserId][discoveryId] = true
					self.revealedDiscoveriesByUserId[player.UserId][discoveryId] = true
				end
			end
		end

		if typeof(data.Inventory.SecretKeys) == "table" then
			for _, roomId in ipairs(data.Inventory.SecretKeys) do
				if Constants.SecretDoors and Constants.SecretDoors[roomId] then
					self.secretKeysByUserId[player.UserId][roomId] = true
				end
			end
		end

		if typeof(data.Inventory.SecretDoorReveals) == "table" then
			for _, roomId in ipairs(data.Inventory.SecretDoorReveals) do
				if Constants.SecretDoors and Constants.SecretDoors[roomId] then
					self.secretDoorRevealsByUserId[player.UserId][roomId] = true
				end
			end
		end
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
		Clues = self.cluesByUserId[player.UserId] or 0,
		Inventory = {
			Clues = self.cluesByUserId[player.UserId] or 0,
			CluedDiscoveries = buildDiscoveryStateList(self.cluedDiscoveriesByUserId[player.UserId]),
			RevealedDiscoveries = buildDiscoveryStateList(self.revealedDiscoveriesByUserId[player.UserId]),
			SecretKeys = buildSecretRoomList(self.secretKeysByUserId[player.UserId]),
			SecretDoorReveals = buildSecretRoomList(self.secretDoorRevealsByUserId[player.UserId]),
		},
		LastUnlockedRoomId = self:GetLastUnlockedRoomId(player),
	}
end

function DiscoveryService:_savePlayer(player)
	if self:IsDevOverrideActive(player) then
		return false
	end

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

	if self:IsDevOverrideActive(player) then
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

function DiscoveryService:HasDiscovery(player, discoveryId)
	if not player or not player.Parent then
		return false
	end

	self:_ensurePlayer(player)
	return self.discoveryByUserId[player.UserId][discoveryId] == true
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

	for _, roomId in ipairs(Constants.DiscoveryRoomOrder or Constants.RoomOrder) do
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

	local resumeDiscoveryId = Constants.RoomResumeDiscoveries and Constants.RoomResumeDiscoveries[roomId]
	if resumeDiscoveryId then
		return self:HasDiscovery(player, resumeDiscoveryId)
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
	for _, roomId in ipairs(Constants.DiscoveryRoomOrder or Constants.RoomOrder) do
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

function DiscoveryService:IsRoomComplete(player, roomId)
	local room = Constants.GetRoom(roomId)
	if not room then
		return false
	end

	return self:HasAll(player, room.DiscoveryOrder)
end

function DiscoveryService:HasSecretKey(player, roomId)
	if not player or not player.Parent then
		return false
	end

	self:_ensurePlayer(player)
	return self.secretKeysByUserId[player.UserId][roomId] == true
end

function DiscoveryService:_syncSecretKeyTools(player)
	if not player or not player.Parent then
		return
	end

	self:_ensurePlayer(player)
	local backpack = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack", 2)
	if not backpack then
		return
	end

	local function removeDevOnlyKeys(container)
		if not container then
			return
		end

		for _, item in ipairs(container:GetChildren()) do
			local roomId = item:GetAttribute("SecretKeyRoomId")
			if item:IsA("Tool") and typeof(roomId) == "string" and not self.secretKeysByUserId[player.UserId][roomId] then
				item:Destroy()
			end
		end
	end

	removeDevOnlyKeys(backpack)
	removeDevOnlyKeys(player.Character)

	for roomId, config in pairs(Constants.SecretDoors or {}) do
		if self.secretKeysByUserId[player.UserId][roomId] == true then
			local keyName = config.KeyName or "Secret Key"
			local character = player.Character
			local existing = backpack:FindFirstChild(keyName) or (character and character:FindFirstChild(keyName))
			if not existing then
				local keyTool = Instance.new("Tool")
				keyTool.Name = keyName
				keyTool.ToolTip = "Opens one secret door."
				keyTool.RequiresHandle = false
				keyTool.CanBeDropped = false
				keyTool:SetAttribute("SecretKeyRoomId", roomId)
				keyTool.Parent = backpack
			end
		end
	end
end

function DiscoveryService:GrantSecretKey(player, roomId, messageText)
	if not player or not player.Parent or not Constants.SecretDoors or not Constants.SecretDoors[roomId] then
		return false
	end

	self:_ensurePlayer(player)
	if self.secretKeysByUserId[player.UserId][roomId] then
		return false
	end

	self.secretKeysByUserId[player.UserId][roomId] = true
	self:_syncSecretKeyTools(player)
	if messageText then
		self.systemMessageRemote:FireClient(player, messageText)
	end

	self:_sendSnapshot(player)
	self._secretDoorChangedEvent:Fire(player, roomId)
	self:_queueSave(player)
	return true
end

function DiscoveryService:_grantRoomCompletionSecretKeys(player)
	if not player or not player.Parent or not Constants.SecretDoors then
		return
	end

	self:_ensurePlayer(player)

	for roomId, config in pairs(Constants.SecretDoors) do
		if config.AutoGrantOnComplete
			and not self.secretKeysByUserId[player.UserId][roomId]
			and self:IsRoomComplete(player, roomId)
		then
			self:GrantSecretKey(
				player,
				roomId,
				config.AutoGrantMessage or ("%s added to your inventory."):format(config.KeyName or "Secret Key")
			)
		end
	end
end

function DiscoveryService:HasSecretDoorReveal(player, roomId)
	if not player or not player.Parent then
		return false
	end

	self:_ensurePlayer(player)
	return self.secretDoorRevealsByUserId[player.UserId][roomId] == true
end

function DiscoveryService:CanSeeSecretDoor(player, roomId)
	return self:IsRoomComplete(player, roomId) or self:HasSecretDoorReveal(player, roomId)
end

function DiscoveryService:RevealSecretDoor(player, roomId, messageText)
	if not player or not player.Parent or not Constants.SecretDoors or not Constants.SecretDoors[roomId] then
		return false, "That Library door is not configured yet."
	end

	self:_ensurePlayer(player)
	if self.secretDoorRevealsByUserId[player.UserId][roomId] then
		return false, "That Library outline is already visible."
	end

	self.secretDoorRevealsByUserId[player.UserId][roomId] = true
	if messageText then
		self.systemMessageRemote:FireClient(player, messageText)
	end

	self:_sendSnapshot(player)
	self._secretDoorChangedEvent:Fire(player, roomId)
	self:_queueSave(player)
	return true, "Secret door revealed."
end

function DiscoveryService:SpendHints(player, count)
	if not player or not player.Parent then
		return false, "No player."
	end

	local cost = math.max(0, math.floor(count or 0))
	self:_ensurePlayer(player)
	if self.hintsByUserId[player.UserId] < cost then
		return false, ("Needs %d hints."):format(cost)
	end

	self.hintsByUserId[player.UserId] -= cost
	self:_sendSnapshot(player)
	self:_queueSave(player)
	return true, nil
end

function DiscoveryService:GetSecretDoorSnapshot(player, roomId)
	local config = Constants.SecretDoors and Constants.SecretDoors[roomId]
	if not config then
		return nil
	end

	local roomComplete = self:IsRoomComplete(player, roomId)
	local purchasedReveal = self:HasSecretDoorReveal(player, roomId)
	local visible = roomComplete or purchasedReveal
	local hasKey = self:HasSecretKey(player, roomId)

	return {
		Id = config.Id,
		RoomId = roomId,
		Name = config.Name,
		KeyName = config.KeyName,
		Visible = visible,
		Active = roomComplete,
		HasKey = hasKey,
		CanOpen = roomComplete and hasKey,
		RoomComplete = roomComplete,
		PurchasedReveal = purchasedReveal,
		RevealHintCost = config.RevealHintCost or 0,
		RevealRobux = config.RevealRobux or 0,
		RevealProductId = config.RevealProductId or 0,
		KeyClueCost = Constants.NoTouch.SecretKeyClueCost or Constants.NoTouch.RevealClueCost or 3,
	}
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
		Clues = self:GetClueCount(player),
		SecretKeys = buildSecretRoomList(self.secretKeysByUserId[player.UserId]),
		SecretDoorReveals = buildSecretRoomList(self.secretDoorRevealsByUserId[player.UserId]),
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

	local secretConfig = Constants.SecretDiscoveries and Constants.SecretDiscoveries[discoveryId]
	if secretConfig then
		local prizeHints = math.max(0, secretConfig.PrizeHints or 0)
		if prizeHints > 0 then
			self.hintsByUserId[player.UserId] += prizeHints
			self.systemMessageRemote:FireClient(
				player,
				secretConfig.PrizeMessage or ("Secret prize: +%d hints."):format(prizeHints)
			)
		end

		if secretConfig.PrizeSecretKeyRoomId then
			self:GrantSecretKey(player, secretConfig.PrizeSecretKeyRoomId, secretConfig.PrizeSecretKeyMessage)
		end
	end

	self:_grantRoomCompletionSecretKeys(player)

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
		Clues = self:GetClueCount(player),
		SecretKeys = buildSecretRoomList(self.secretKeysByUserId[player.UserId]),
		SecretDoorReveals = buildSecretRoomList(self.secretDoorRevealsByUserId[player.UserId]),
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

function DiscoveryService:GetClueCount(player)
	if not player then
		return 0
	end

	self:_ensurePlayer(player)
	return self.cluesByUserId[player.UserId] or 0
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

function DiscoveryService:GrantClues(player, count)
	if not player or not player.Parent then
		return 0
	end

	self:_ensurePlayer(player)
	self.cluesByUserId[player.UserId] += math.max(0, count or 0)
	self:_sendSnapshot(player)
	self:_queueSave(player)
	return self.cluesByUserId[player.UserId]
end

function DiscoveryService:SpendClues(player, count)
	if not player or not player.Parent then
		return false, "No player."
	end

	local cost = math.max(0, math.floor(count or 0))
	self:_ensurePlayer(player)
	if self.cluesByUserId[player.UserId] < cost then
		return false, ("Needs %d clues."):format(cost)
	end

	self.cluesByUserId[player.UserId] -= cost
	self:_sendSnapshot(player)
	self:_queueSave(player)
	return true, nil
end

function DiscoveryService:GetRoomSnapshot(player, roomId)
	if not player or not player.Parent then
		return nil
	end

	self:_ensurePlayer(player)
	self:_grantRoomCompletionSecretKeys(player)

	local room = Constants.GetRoom(roomId) or Constants.GetRoom(Constants.RoomOrder[1])
	if not room then
		return nil
	end

	local discoveries = {}
	local foundById = self.discoveryByUserId[player.UserId]
	local cluedById = self.cluedDiscoveriesByUserId[player.UserId]
	local revealedById = self.revealedDiscoveriesByUserId[player.UserId]

	for _, discoveryId in ipairs(room.DiscoveryOrder) do
		local discovery = Constants.GetDiscovery(discoveryId)
		if discovery then
			local unlocked = foundById[discoveryId] == true
			local revealed = revealedById[discoveryId] == true
			local clued = revealed or cluedById[discoveryId] == true
			table.insert(discoveries, {
				Id = discovery.Id,
				Name = (unlocked or clued) and discovery.Name or "???",
				Hint = revealed and discovery.Hint or nil,
				Unlocked = unlocked,
				Clued = clued and not unlocked,
				Revealed = revealed and not unlocked,
			})
		end
	end

	local secretCount = 0
	for _, discoveryId in ipairs(Constants.SecretDiscoveryOrderByRoom[room.Id] or {}) do
		local discovery = Constants.GetDiscovery(discoveryId)
		if discovery and foundById[discoveryId] == true then
			secretCount += 1
			table.insert(discoveries, {
				Id = discovery.Id,
				Name = discovery.Name,
				Secret = true,
				Unlocked = true,
			})
		end
	end

	return {
		Type = "RoomSnapshot",
		RoomId = room.Id,
		RoomName = room.Name,
		Count = self:_countForPlayer(player, room.DiscoveryOrder),
		Total = #room.DiscoveryOrder,
		SecretCount = secretCount,
		Hints = self:GetHintCount(player),
		Clues = self:GetClueCount(player),
		ClueHintCost = Constants.NoTouch.ClueHintCost,
		RevealClueCost = Constants.NoTouch.RevealClueCost,
		SecretDoor = self:GetSecretDoorSnapshot(player, room.Id),
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

function DiscoveryService:_getNextUncluedDiscovery(player, roomId)
	if not player or not player.Parent then
		return nil, "No player."
	end

	self:_ensurePlayer(player)

	local room = Constants.GetRoom(roomId)
	if not room then
		return nil, "That book page is missing."
	end

	local foundById = self.discoveryByUserId[player.UserId]
	local cluedById = self.cluedDiscoveriesByUserId[player.UserId]

	for _, discoveryId in ipairs(room.DiscoveryOrder) do
		if not foundById[discoveryId] and not cluedById[discoveryId] then
			return Constants.GetDiscovery(discoveryId), nil
		end
	end

	return nil, "Every remaining discovery in this room already has a clue."
end

function DiscoveryService:_getNextRevealDiscovery(player, roomId)
	if not player or not player.Parent then
		return nil, nil, "No player."
	end

	self:_ensurePlayer(player)

	local room = Constants.GetRoom(roomId)
	if not room then
		return nil, nil, "That book page is missing."
	end

	local foundById = self.discoveryByUserId[player.UserId]
	local revealedById = self.revealedDiscoveriesByUserId[player.UserId]

	for _, discoveryId in ipairs(room.DiscoveryOrder) do
		local targetTag = Constants.DiscoveryHighlightTargets[discoveryId]
		if targetTag and not foundById[discoveryId] and not revealedById[discoveryId] then
			return Constants.GetDiscovery(discoveryId), targetTag, nil
		end
	end

	return nil, nil, "No unrevealed locations are left in this room."
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

	return ("Free hint: %s still has something left to give."):format(targetText), nil
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

function DiscoveryService:UseClue(player, roomId, hintCost, skipCost)
	if not player or not player.Parent then
		return nil, "No player."
	end

	self:_ensurePlayer(player)

	local nextDiscovery, errorText = self:_getNextUncluedDiscovery(player, roomId)
	local pendingDiscovery = nil
	if not nextDiscovery then
		pendingDiscovery = self:_getNextDiscovery(player, roomId)
		if not pendingDiscovery then
			return nil, errorText
		end
	end

	local cost = math.max(0, math.floor(hintCost or Constants.NoTouch.ClueHintCost or 5))
	if not skipCost and self.hintsByUserId[player.UserId] < cost then
		return nil, ("Clue needs %d hints."):format(cost)
	end

	if not skipCost then
		self.hintsByUserId[player.UserId] -= cost
	end

	self.cluesByUserId[player.UserId] += 1
	if nextDiscovery then
		self.cluedDiscoveriesByUserId[player.UserId][nextDiscovery.Id] = true
	end
	self:_sendSnapshot(player)
	self:_queueSave(player)

	if nextDiscovery then
		return ("Clue unlocked: %s is now named in the log. Clues banked: %d."):format(
			nextDiscovery.Name,
			self.cluesByUserId[player.UserId]
		), nil, nextDiscovery
	end

	return ("Clue banked. Every remaining discovery in this room is already named. Clues banked: %d."):format(
		self.cluesByUserId[player.UserId]
	), nil, pendingDiscovery
end

function DiscoveryService:UseLocationReveal(player, roomId, clueCost, skipCost)
	if not player or not player.Parent then
		return nil, nil, "No player."
	end

	self:_ensurePlayer(player)

	local nextDiscovery, targetTag, errorText = self:_getNextRevealDiscovery(player, roomId)
	if not nextDiscovery then
		return nil, nil, errorText
	end

	local cost = math.max(0, math.floor(clueCost or Constants.NoTouch.RevealClueCost or 3))
	if not skipCost and self.cluesByUserId[player.UserId] < cost then
		return nil, nil, ("Reveal needs %d clues."):format(cost)
	end

	if not skipCost then
		self.cluesByUserId[player.UserId] -= cost
	end

	self.cluedDiscoveriesByUserId[player.UserId][nextDiscovery.Id] = true
	self.revealedDiscoveriesByUserId[player.UserId][nextDiscovery.Id] = true
	self:_sendSnapshot(player)
	self:_queueSave(player)

	local hint = nextDiscovery.Hint or "The highlighted object is ready."
	return ("Reveal: %s. %s"):format(nextDiscovery.Name, hint), targetTag, nil, nextDiscovery
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
