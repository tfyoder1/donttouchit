local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local EventRegistry = require(script.Parent:WaitForChild("EventRegistry"))
local RemoteService = require(script.Parent:WaitForChild("RemoteService"))

local EventManager = {}
EventManager.__index = EventManager

local SIGNAL_BAND_ATTRIBUTE = "DontTouchItSignalBandEquipped"
local RED_BUTTON_DISCOVERY_FORCE_INTERVAL = 6
local RED_BUTTON_DISCOVERY_CYCLE = {
	{
		EventId = "object_rain",
		DiscoveryId = Constants.Discoveries.ObjectRain.Id,
	},
	{
		EventId = "fake_event",
		DiscoveryId = Constants.Discoveries.DelayedSurprise.Id,
	},
	{
		EventId = "tiny_players",
		DiscoveryId = Constants.Discoveries.TinyPlayers.Id,
	},
	{
		EventId = "low_gravity",
		DiscoveryId = Constants.Discoveries.LowGravity.Id,
	},
	{
		EventId = "giant_player",
		DiscoveryId = Constants.Discoveries.GiantPlayer.Id,
	},
}

local RED_BUTTON_DISCOVERY_BY_EVENT_ID = {}
for _, entry in ipairs(RED_BUTTON_DISCOVERY_CYCLE) do
	RED_BUTTON_DISCOVERY_BY_EVENT_ID[entry.EventId] = entry
end

function EventManager.new(discoveryService, resetService, roomReferences, roomProgressService, bunkerEnergyService)
	local self = setmetatable({}, EventManager)
	self.discoveryService = discoveryService
	self.resetService = resetService
	self.roomReferences = roomReferences
	self.roomProgressService = roomProgressService
	self.bunkerEnergyService = bunkerEnergyService
	self.random = Random.new()
	self.active = false
	self.buttonPressCount = 0
	self.redButtonDiscoveryStateByUserId = {}
	self.systemMessageRemote = RemoteService.GetRemote(Constants.Remotes.SystemMessage)
	self.localAudioRemote = RemoteService.GetRemote(Constants.Remotes.LocalAudio)
	Players.PlayerRemoving:Connect(function(player)
		self.redButtonDiscoveryStateByUserId[player.UserId] = nil
	end)
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

function EventManager:_playLocalSound(player, soundId, options)
	if not player or not player.Parent or not soundId then
		return
	end

	options = options or {}
	self.localAudioRemote:FireClient(player, {
		Action = "PlaySound",
		SoundId = soundId,
		Volume = options.Volume,
		PlaybackSpeed = options.PlaybackSpeed,
		Lifetime = options.Lifetime,
	})
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

function EventManager:_hasDiscovery(player, discoveryId)
	if not player or not player.Parent or not discoveryId then
		return false
	end

	if not self.discoveryService or not self.discoveryService.HasDiscovery then
		return false
	end

	return self.discoveryService:HasDiscovery(player, discoveryId)
end

function EventManager:_getRedButtonDiscoveryState(player)
	if not player or not player.Parent then
		return nil
	end

	local state = self.redButtonDiscoveryStateByUserId[player.UserId]
	if not state then
		state = {
			NextCycleIndex = 1,
			PressesSinceDiscoveryOutcome = 0,
		}
		self.redButtonDiscoveryStateByUserId[player.UserId] = state
	end

	return state
end

function EventManager:_getNextMissingRedButtonDiscoveryEvent(player, state)
	if not state then
		return nil, nil
	end

	for offset = 0, #RED_BUTTON_DISCOVERY_CYCLE - 1 do
		local index = ((state.NextCycleIndex + offset - 1) % #RED_BUTTON_DISCOVERY_CYCLE) + 1
		local entry = RED_BUTTON_DISCOVERY_CYCLE[index]
		local eligible = entry
			and (entry.EventId ~= "object_rain" or player:GetAttribute(SIGNAL_BAND_ATTRIBUTE) == true)
		if eligible and not self:_hasDiscovery(player, entry.DiscoveryId) then
			local eventDefinition = self:_getEventById(entry.EventId)
			if eventDefinition then
				state.NextCycleIndex = (index % #RED_BUTTON_DISCOVERY_CYCLE) + 1
				return eventDefinition, entry
			end
		end
	end

	return nil, nil
end

function EventManager:_chooseRedButtonEvent(triggeringPlayer)
	local state = self:_getRedButtonDiscoveryState(triggeringPlayer)
	if state and state.PressesSinceDiscoveryOutcome >= RED_BUTTON_DISCOVERY_FORCE_INTERVAL - 1 then
		local eventDefinition, entry = self:_getNextMissingRedButtonDiscoveryEvent(triggeringPlayer, state)
		if eventDefinition then
			return eventDefinition, entry
		end
	end

	local eventDefinition = self:_chooseEvent()
	return eventDefinition, eventDefinition and RED_BUTTON_DISCOVERY_BY_EVENT_ID[eventDefinition.Id] or nil
end

function EventManager:_recordAcceptedRedButtonPress(triggeringPlayer, entry)
	self.buttonPressCount += 1

	local state = self:_getRedButtonDiscoveryState(triggeringPlayer)
	if not state then
		return
	end

	local wasMissingDiscovery = entry and not self:_hasDiscovery(triggeringPlayer, entry.DiscoveryId)
	if wasMissingDiscovery then
		state.PressesSinceDiscoveryOutcome = 0
	else
		state.PressesSinceDiscoveryOutcome += 1
	end
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
		PlayLocalSound = function(player, soundId, options)
			self:_playLocalSound(player, soundId, options)
		end,
		RecordInteraction = function(player)
			if self.roomProgressService then
				self.roomProgressService:RecordInteraction(player)
			end
			if self.bunkerEnergyService then
				self.bunkerEnergyService:RecordInteraction(player)
			end
		end,
		RecordMatterReclaimed = function(partCount)
			if self.bunkerEnergyService then
				self.bunkerEnergyService:RecordMatterReclaimed(partCount)
			end
		end,
		GrantEnergyReserveTool = function(player, options)
			if self.bunkerEnergyService and self.bunkerEnergyService.GrantEnergyReserveTool then
				return self.bunkerEnergyService:GrantEnergyReserveTool(player, options)
			end

			return false, "The bunker has not enabled portable matter yet."
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
			self:_broadcastMessage("The room coughed. The reset button is looking useful.")
		end

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

	local eventDefinition, entry = self:_chooseRedButtonEvent(triggeringPlayer)
	local accepted = self:_startEvent(triggeringPlayer, eventDefinition, true)
	if accepted then
		self:_recordAcceptedRedButtonPress(triggeringPlayer, entry)
	end

	return accepted
end

function EventManager:TriggerById(triggeringPlayer, eventId)
	local eventDefinition = self:_getEventById(eventId)
	return self:_startEvent(triggeringPlayer, eventDefinition, false)
end

function EventManager:ResetRoom(triggeringPlayer)
	self.resetService.RestoreAll()
	self.active = false
	self:_broadcastMessage("Room reset. The evidence has been cleaned up, but the book remembers.")
end

return EventManager
