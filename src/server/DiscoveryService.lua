local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local RemoteService = require(script.Parent:WaitForChild("RemoteService"))

local DiscoveryService = {}
DiscoveryService.__index = DiscoveryService

function DiscoveryService.new()
	local self = setmetatable({}, DiscoveryService)
	self.discoveryByUserId = {}
	self.hintsByUserId = {}
	self.remote = RemoteService.GetRemote(Constants.Remotes.DiscoveryUpdate)
	self._unlockedEvent = Instance.new("BindableEvent")
	self.DiscoveryUnlocked = self._unlockedEvent.Event
	return self
end

function DiscoveryService:Initialize()
	Players.PlayerAdded:Connect(function(player)
		self:_ensurePlayer(player)
		self:_sendSnapshot(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self.discoveryByUserId[player.UserId] = nil
		self.hintsByUserId[player.UserId] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		self:_ensurePlayer(player)
		self:_sendSnapshot(player)
	end
end

function DiscoveryService:_ensurePlayer(player)
	if not self.discoveryByUserId[player.UserId] then
		self.discoveryByUserId[player.UserId] = {}
	end

	if not self.hintsByUserId[player.UserId] then
		self.hintsByUserId[player.UserId] = 0
	end
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

function DiscoveryService:_sendSnapshot(player)
	self.remote:FireClient(player, {
		Type = "Snapshot",
		Count = self:_countForPlayer(player),
		Total = Constants.TotalDiscoveries,
		Rooms = self:_buildRoomSummaries(player),
		Hints = self:GetHintCount(player),
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

	self.remote:FireClient(player, {
		Type = "Unlocked",
		Id = discovery.Id,
		Name = discovery.Name,
		Count = self:_countForPlayer(player),
		Total = Constants.TotalDiscoveries,
		Rooms = self:_buildRoomSummaries(player),
		Hints = self:GetHintCount(player),
	})

	self._unlockedEvent:Fire(player, discovery.Id)

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

function DiscoveryService:UseHint(player, roomId)
	if not player or not player.Parent then
		return nil, "No player."
	end

	self:_ensurePlayer(player)

	local room = Constants.GetRoom(roomId)
	if not room then
		return nil, "That book page is missing."
	end

	local foundById = self.discoveryByUserId[player.UserId]
	local nextDiscovery = nil

	for _, discoveryId in ipairs(room.DiscoveryOrder) do
		if not foundById[discoveryId] then
			nextDiscovery = Constants.GetDiscovery(discoveryId)
			break
		end
	end

	if not nextDiscovery then
		return nil, "Everything in this room is already found."
	end

	if self.hintsByUserId[player.UserId] <= 0 then
		return nil, "No hints left."
	end

	self.hintsByUserId[player.UserId] -= 1
	self:_sendSnapshot(player)

	return nextDiscovery.Hint or "Try one of the untouched objects in this room.", nil
end

return DiscoveryService
