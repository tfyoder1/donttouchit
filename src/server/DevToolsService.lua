local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local DevToolsConfig = require(script.Parent:WaitForChild("DevToolsConfig"))
local EventRegistry = require(script.Parent:WaitForChild("EventRegistry"))
local RemoteService = require(script.Parent:WaitForChild("RemoteService"))

local DevToolsService = {}
DevToolsService.__index = DevToolsService

local PRESETS = {
	"Fresh",
	"Midway",
	"Completed",
}

local SECRET_AREAS = {
	{
		Id = "SubLevel1",
		Name = "TV Sub Level 1",
		CFrame = CFrame.new(-16.5, -6.8, 12.5),
	},
	{
		Id = "SubLevel2",
		Name = "TV Sub Level 2",
		CFrame = CFrame.new(0, -15, 5.5),
	},
	{
		Id = "Library",
		Name = "Library",
		CFrame = Constants.GetRoomSpawnCFrame("Library"),
	},
	{
		Id = "BowlingAlley",
		Name = "Bowling Alley",
		CFrame = Constants.GetRoomSpawnCFrame("BowlingAlley"),
	},
	{
		Id = "Maintenance",
		Name = "Maintenance Room",
		CFrame = CFrame.new(-14, 3, -143),
	},
}

local function getRootPart(player)
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function teleportPlayer(player, destinationCFrame)
	local rootPart = getRootPart(player)
	if not rootPart and player and player.Parent then
		player.CharacterAdded:Wait()
		task.wait(0.1)
		rootPart = getRootPart(player)
	end

	if not rootPart or typeof(destinationCFrame) ~= "CFrame" then
		return false
	end

	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
	rootPart.CFrame = destinationCFrame
	return true
end

local function listContains(items, value)
	for _, item in ipairs(items) do
		if item == value then
			return true
		end
	end

	return false
end

function DevToolsService.new(discoveryService, roomProgressService, eventManager, resetService, interactionService)
	local self = setmetatable({}, DevToolsService)
	self.discoveryService = discoveryService
	self.roomProgressService = roomProgressService
	self.eventManager = eventManager
	self.resetService = resetService
	self.interactionService = interactionService
	self.remote = RemoteService.GetRemote(Constants.Remotes.DevTools)
	self.systemMessageRemote = RemoteService.GetRemote(Constants.Remotes.SystemMessage)
	self.eventIds = {}
	self.movementStateByUserId = {}

	for _, eventDefinition in ipairs(EventRegistry) do
		if eventDefinition.Id then
			self.eventIds[eventDefinition.Id] = true
		end
	end

	return self
end

function DevToolsService:Initialize()
	self.remote.OnServerEvent:Connect(function(player, payload)
		self:_handleRequest(player, payload)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self.movementStateByUserId[player.UserId] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		if self:IsAuthorized(player) then
			self:_sendState(player, "Auth")
		end
	end
end

function DevToolsService:IsAuthorized(player)
	return DevToolsConfig.IsAuthorized(player)
end

function DevToolsService:_sendMessage(player, text)
	if player and player.Parent then
		self.systemMessageRemote:FireClient(player, text)
	end
end

function DevToolsService:_getCurrentRoomId(player)
	local roomId = self.roomProgressService and self.roomProgressService:GetRoomForPlayer(player)
	if roomId and Constants.GetRoom(roomId) then
		return roomId
	end

	return Constants.RoomOrder[1]
end

function DevToolsService:_getRoomOptions()
	local rooms = {}

	for _, roomId in ipairs(Constants.DiscoveryRoomOrder or Constants.RoomOrder) do
		local room = Constants.GetRoom(roomId)
		if room then
			table.insert(rooms, {
				Id = roomId,
				Name = room.Name,
			})
		end
	end

	return rooms
end

function DevToolsService:_getEventOptions()
	local events = {}

	for _, eventDefinition in ipairs(EventRegistry) do
		table.insert(events, {
			Id = eventDefinition.Id,
			Name = eventDefinition.Name or eventDefinition.Id,
		})
	end

	return events
end

function DevToolsService:_getSecretAreaOptions()
	local areas = {}

	for _, area in ipairs(SECRET_AREAS) do
		table.insert(areas, {
			Id = area.Id,
			Name = area.Name,
		})
	end

	return areas
end

function DevToolsService:_getAreaById(areaId)
	for _, area in ipairs(SECRET_AREAS) do
		if area.Id == areaId then
			return area
		end
	end

	return nil
end

function DevToolsService:_sendState(player, stateType, roomId)
	if not self:IsAuthorized(player) then
		return
	end

	if not self.discoveryService:IsLoaded(player) then
		task.delay(0.5, function()
			if player.Parent then
				self:_sendState(player, stateType, roomId)
			end
		end)
		return
	end

	local currentRoomId = roomId or self:_getCurrentRoomId(player)
	local movementState = self.movementStateByUserId[player.UserId] or {}

	self.remote:FireClient(player, {
		Type = stateType or "State",
		Authorized = true,
		DevSessionActive = self.discoveryService:IsDevOverrideActive(player),
		CurrentRoomId = currentRoomId,
		Rooms = self:_getRoomOptions(),
		Events = self:_getEventOptions(),
		SecretAreas = self:_getSecretAreaOptions(),
		Presets = PRESETS,
		Movement = {
			Fly = movementState.Fly == true,
			Noclip = movementState.Noclip == true,
		},
		RoomSnapshot = self.discoveryService:GetRoomSnapshot(player, currentRoomId),
	})
end

function DevToolsService:_refreshWorldState()
	if self.interactionService and self.interactionService.RefreshProgressDrivenWorld then
		self.interactionService:RefreshProgressDrivenWorld()
	end
end

function DevToolsService:_resetRoom(player)
	if self.interactionService and self.interactionService.ResetRoomForPlayer then
		self.interactionService:ResetRoomForPlayer(player)
	else
		self.resetService.RestoreAll()
		if self.eventManager then
			self.eventManager.active = false
		end
		self:_refreshWorldState()
	end
	self:_sendMessage(player, "Dev reset restored the generated room state.")
end

function DevToolsService:_applyRoomPreset(player, roomId, presetName)
	if not Constants.GetRoom(roomId) or not listContains(PRESETS, presetName) then
		return false
	end

	self.discoveryService:EnableDevOverride(player)
	self:_resetRoom(player)
	local discoveryIds = self.discoveryService:GetDevPresetDiscoveryIds(roomId, presetName)
	local ok = self.discoveryService:SetDevRoomDiscoveries(player, roomId, discoveryIds)
	self:_refreshWorldState()

	if ok then
		local room = Constants.GetRoom(roomId)
		self:_sendMessage(player, ("Dev preset: %s is now %s for this session."):format(room.Name, presetName))
	end

	return ok
end

function DevToolsService:_setMovementState(player, payload)
	local state = self.movementStateByUserId[player.UserId] or {
		Fly = false,
		Noclip = false,
	}

	if typeof(payload.Fly) == "boolean" then
		state.Fly = payload.Fly
	end

	if typeof(payload.Noclip) == "boolean" then
		state.Noclip = payload.Noclip
	end

	self.movementStateByUserId[player.UserId] = state
	self.remote:FireClient(player, {
		Type = "MovementState",
		Fly = state.Fly,
		Noclip = state.Noclip,
	})
end

function DevToolsService:_setDiscoveryCompletion(player, payload)
	local roomId = payload.RoomId
	local discoveryId = payload.DiscoveryId
	local completed = payload.Completed == true

	if typeof(roomId) ~= "string" or typeof(discoveryId) ~= "string" then
		return false
	end

	local ok = self.discoveryService:SetDevDiscoveryCompletion(player, roomId, discoveryId, completed)
	self:_refreshWorldState()
	return ok
end

function DevToolsService:_handleAuthorizedRequest(player, payload)
	local action = payload.Action
	local roomId = payload.RoomId

	if action ~= "SetMovement" and not self.discoveryService:IsLoaded(player) then
		self:_sendMessage(player, "Dev tools are waiting for saved progress to load.")
		self:_sendState(player, "State", roomId)
		return
	end

	if action == "Refresh" then
		self:_sendState(player, "State", roomId)
	elseif action == "JumpToRoom" then
		local room = Constants.GetRoom(roomId)
		if not room then
			return
		end
		self.discoveryService:EnableDevOverride(player)
		teleportPlayer(player, Constants.GetRoomSpawnCFrame(roomId))
		self:_sendMessage(player, ("Dev jump: %s. Progress is session-only."):format(room.Name))
		task.delay(0.15, function()
			if player.Parent then
				self:_sendState(player, "State", roomId)
			end
		end)
	elseif action == "SetRoomPreset" then
		local presetName = payload.Preset
		if typeof(roomId) == "string" and typeof(presetName) == "string" then
			self:_applyRoomPreset(player, roomId, presetName)
			self:_sendState(player, "State", roomId)
		end
	elseif action == "CompleteCurrentRoom" then
		local currentRoomId = self:_getCurrentRoomId(player)
		self:_applyRoomPreset(player, currentRoomId, "Completed")
		self:_sendState(player, "State", currentRoomId)
	elseif action == "ResetCurrentRoom" then
		self:_resetRoom(player)
		self:_sendState(player, "State", self:_getCurrentRoomId(player))
	elseif action == "TriggerSpecificEvent" then
		local eventId = payload.EventId
		if typeof(eventId) == "string" and self.eventIds[eventId] then
			self.discoveryService:EnableDevOverride(player)
			self.eventManager:TriggerById(player, eventId)
			self:_sendState(player, "State", self:_getCurrentRoomId(player))
		end
	elseif action == "TriggerRandomEvent" then
		self.discoveryService:EnableDevOverride(player)
		self.eventManager:TriggerRandom(player)
		self:_sendState(player, "State", self:_getCurrentRoomId(player))
	elseif action == "TeleportSecretArea" then
		local area = self:_getAreaById(payload.AreaId)
		if area then
			self.discoveryService:EnableDevOverride(player)
			teleportPlayer(player, area.CFrame)
			self:_sendMessage(player, ("Dev teleport: %s."):format(area.Name))
			task.delay(0.15, function()
				if player.Parent then
					self:_sendState(player, "State")
				end
			end)
		end
	elseif action == "UnlockAllSession" then
		self.discoveryService:UnlockAllDiscoveriesForDevSession(player)
		self:_refreshWorldState()
		self:_sendMessage(player, "Dev session now has every discovery, key, and reveal.")
		self:_sendState(player, "State", self:_getCurrentRoomId(player))
	elseif action == "RestoreNormalProgress" then
		self.discoveryService:RestoreNormalProgressState(player)
		self:_resetRoom(player)
		self:_refreshWorldState()
		self:_sendMessage(player, "Dev session cleared. Your real saved progress is back.")
		self:_sendState(player, "State", self:_getCurrentRoomId(player))
	elseif action == "SetMovement" then
		self:_setMovementState(player, payload)
		self:_sendState(player, "State", self:_getCurrentRoomId(player))
	elseif action == "SetDiscovery" then
		if self:_setDiscoveryCompletion(player, payload) then
			self:_sendState(player, "State", payload.RoomId)
		end
	end
end

function DevToolsService:_handleRequest(player, payload)
	if typeof(payload) ~= "table" or not player then
		return
	end

	if payload.Action == "Handshake" then
		if self:IsAuthorized(player) then
			self:_sendState(player, "Auth")
		end
		return
	end

	if not self:IsAuthorized(player) then
		warn(("[DON'T TOUCH IT] Unauthorized dev tool request from %s (%d)."):format(player.Name, player.UserId))
		return
	end

	self:_handleAuthorizedRequest(player, payload)
end

return DevToolsService
