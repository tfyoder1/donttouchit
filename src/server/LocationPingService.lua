local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local RemoteService = require(script.Parent:WaitForChild("RemoteService"))

local LocationPingService = {}
LocationPingService.__index = LocationPingService

local REQUEST_COOLDOWN_SECONDS = 1.1
local MAX_PING_DISTANCE = 420
local MAX_LABEL_LENGTH = 42
local MAX_COORDINATE_ABS = 100000

local function getRootPart(player)
	local character = player and player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function isFiniteVector3(value)
	return typeof(value) == "Vector3"
		and value.X == value.X
		and value.Y == value.Y
		and value.Z == value.Z
		and math.abs(value.X) <= MAX_COORDINATE_ABS
		and math.abs(value.Y) <= MAX_COORDINATE_ABS
		and math.abs(value.Z) <= MAX_COORDINATE_ABS
end

local function sanitizeLabel(value)
	if typeof(value) ~= "string" then
		return "here"
	end

	local text = value:gsub("[%c\r\n\t]", " "):gsub("%s+", " ")
	text = text:match("^%s*(.-)%s*$") or ""
	if text == "" then
		return "here"
	end

	if #text > MAX_LABEL_LENGTH then
		text = text:sub(1, MAX_LABEL_LENGTH - 1) .. "."
	end

	return text
end

function LocationPingService.new()
	local self = setmetatable({}, LocationPingService)
	self.remote = RemoteService.GetRemote(Constants.Remotes.LocationPing)
	self.lastRequestAtByUserId = {}
	return self
end

function LocationPingService:Initialize()
	self.remote.OnServerEvent:Connect(function(player, payload)
		self:_handlePingRequest(player, payload)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self.lastRequestAtByUserId[player.UserId] = nil
	end)
end

function LocationPingService:_handlePingRequest(player, payload)
	if not player or not player.Parent or typeof(payload) ~= "table" then
		return
	end

	if payload.Action ~= "Ping" or not isFiniteVector3(payload.Position) then
		return
	end

	local now = os.clock()
	local lastRequestAt = self.lastRequestAtByUserId[player.UserId] or 0
	if now - lastRequestAt < REQUEST_COOLDOWN_SECONDS then
		return
	end

	local rootPart = getRootPart(player)
	if not rootPart then
		return
	end

	local position = payload.Position
	if (position - rootPart.Position).Magnitude > MAX_PING_DISTANCE then
		return
	end

	self.lastRequestAtByUserId[player.UserId] = now
	self.remote:FireAllClients({
		Action = "Show",
		SenderUserId = player.UserId,
		SenderName = player.DisplayName ~= "" and player.DisplayName or player.Name,
		Position = position,
		TargetName = sanitizeLabel(payload.TargetName),
		CreatedAt = now,
	})
end

return LocationPingService
