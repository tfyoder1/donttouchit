local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local RemoteService = require(script.Parent:WaitForChild("RemoteService"))

local DiscoveryService = {}
DiscoveryService.__index = DiscoveryService

function DiscoveryService.new()
	local self = setmetatable({}, DiscoveryService)
	self.discoveryByUserId = {}
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

return DiscoveryService
