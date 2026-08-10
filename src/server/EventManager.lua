local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local EventRegistry = require(script.Parent:WaitForChild("EventRegistry"))
local RemoteService = require(script.Parent:WaitForChild("RemoteService"))

local EventManager = {}
EventManager.__index = EventManager

local OBJECT_RAIN_BUTTON_INTERVAL = 8

function EventManager.new(discoveryService, resetService, roomReferences)
	local self = setmetatable({}, EventManager)
	self.discoveryService = discoveryService
	self.resetService = resetService
	self.roomReferences = roomReferences
	self.random = Random.new()
	self.active = false
	self.buttonPressCount = 0
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
		local weight = eventDefinition.Weight or 1
		if weight > 0 then
			totalWeight += weight
		end
	end

	if totalWeight <= 0 then
		return nil
	end

	local roll = self.random:NextNumber(0, totalWeight)
	local runningWeight = 0

	for _, eventDefinition in ipairs(EventRegistry) do
		local weight = eventDefinition.Weight or 1
		if weight > 0 then
			runningWeight += weight
			if roll <= runningWeight then
				return eventDefinition
			end
		end
	end

	return nil
end

function EventManager:_getEventById(eventId)
	for _, eventDefinition in ipairs(EventRegistry) do
		if eventDefinition.Id == eventId then
			return eventDefinition
		end
	end

	return nil
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

function EventManager:_startEvent(triggeringPlayer, eventDefinition, unlockButtonDiscovery)
	if self.active then
		self:_sendMessage(triggeringPlayer, "The room is busy making a questionable decision.")
		return false
	end

	if not eventDefinition then
		self:_sendMessage(triggeringPlayer, "Nothing happened. Even the room seems surprised.")
		return false
	end

	self.active = true
	if unlockButtonDiscovery then
		self.discoveryService:Unlock(triggeringPlayer, Constants.Discoveries.PressedButton.Id)
	end

	task.spawn(function()
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

function EventManager:TriggerRandom(triggeringPlayer)
	if self.active then
		self:_sendMessage(triggeringPlayer, "The room is busy making a questionable decision.")
		return false
	end

	self.buttonPressCount += 1

	local eventDefinition = nil
	if self.buttonPressCount % OBJECT_RAIN_BUTTON_INTERVAL == 0 then
		eventDefinition = self:_getEventById("object_rain")
	end

	eventDefinition = eventDefinition or self:_chooseEvent()
	return self:_startEvent(triggeringPlayer, eventDefinition, true)
end

function EventManager:TriggerById(triggeringPlayer, eventId)
	local eventDefinition = self:_getEventById(eventId)
	return self:_startEvent(triggeringPlayer, eventDefinition, false)
end

return EventManager
