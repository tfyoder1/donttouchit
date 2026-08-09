local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local EventRegistry = require(script.Parent:WaitForChild("EventRegistry"))
local RemoteService = require(script.Parent:WaitForChild("RemoteService"))

local EventManager = {}
EventManager.__index = EventManager

function EventManager.new(discoveryService, resetService, roomReferences)
	local self = setmetatable({}, EventManager)
	self.discoveryService = discoveryService
	self.resetService = resetService
	self.roomReferences = roomReferences
	self.random = Random.new()
	self.active = false
	self.systemMessageRemote = RemoteService.GetRemote(Constants.Remotes.SystemMessage)
	return self
end

function EventManager:IsActive()
	return self.active
end

function EventManager:_sendMessage(player, text)
	if player and player.Parent then
		self.systemMessageRemote:FireClient(player, text)
	end
end

function EventManager:_broadcastMessage(text)
	self.systemMessageRemote:FireAllClients(text)
end

function EventManager:_chooseEvent()
	local totalWeight = 0
	for _, eventDefinition in ipairs(EventRegistry) do
		totalWeight += eventDefinition.Weight or 1
	end

	local roll = self.random:NextNumber(0, totalWeight)
	local runningWeight = 0

	for _, eventDefinition in ipairs(EventRegistry) do
		runningWeight += eventDefinition.Weight or 1
		if roll <= runningWeight then
			return eventDefinition
		end
	end

	return EventRegistry[#EventRegistry]
end

function EventManager:_buildContext(triggeringPlayer, eventDefinition)
	return {
		TriggeringPlayer = triggeringPlayer,
		Players = Players:GetPlayers(),
		Event = eventDefinition,
		RoomReferences = self.roomReferences,
		DiscoveryService = self.discoveryService,
		ResetService = self.resetService,
		SendMessage = function(player, text)
			self:_sendMessage(player, text)
		end,
		BroadcastMessage = function(text)
			self:_broadcastMessage(text)
		end,
	}
end

function EventManager:TriggerRandom(triggeringPlayer)
	if self.active then
		self:_sendMessage(triggeringPlayer, "The button is busy making a questionable decision.")
		return false
	end

	self.active = true
	self.discoveryService:Unlock(triggeringPlayer, Constants.Discoveries.PressedButton.Id)

	task.spawn(function()
		local eventDefinition = self:_chooseEvent()
		local context = self:_buildContext(triggeringPlayer, eventDefinition)

		self:_broadcastMessage(eventDefinition.StartMessage or "Something is happening.")

		local ok, errorMessage = pcall(function()
			eventDefinition.Run(context)
		end)

		if not ok then
			warn(("[DON'T TOUCH IT] Event '%s' failed: %s"):format(eventDefinition.Id, tostring(errorMessage)))
			self:_broadcastMessage("The room coughed. Resetting...")
		end

		self.resetService.RestoreAll()
		task.wait(Constants.EventCooldown)
		self.active = false
	end)

	return true
end

return EventManager

