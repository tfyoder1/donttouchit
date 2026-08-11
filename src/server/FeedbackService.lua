local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local RemoteService = require(script.Parent:WaitForChild("RemoteService"))

local FeedbackService = {}
FeedbackService.__index = FeedbackService

local function buildCategoryLookup()
	local lookup = {}

	for _, category in ipairs(Constants.Feedback.Categories or {}) do
		lookup[category.Id] = category
	end

	return lookup
end

function FeedbackService.new(roomProgressService)
	local self = setmetatable({}, FeedbackService)
	self.roomProgressService = roomProgressService
	self.remote = RemoteService.GetRemote(Constants.Remotes.FeedbackRequest)
	self.feedbackStore = DataStoreService:GetDataStore(Constants.DataStore.FeedbackName or "DontTouchItFeedback_v1")
	self.categoryById = buildCategoryLookup()
	self.lastSubmitAtByUserId = {}
	return self
end

function FeedbackService:Initialize()
	self.remote.OnServerEvent:Connect(function(player, payload)
		self:_handleFeedback(player, payload)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self.lastSubmitAtByUserId[player.UserId] = nil
	end)
end

function FeedbackService:_sendResult(player, success, message)
	self.remote:FireClient(player, {
		Success = success,
		Message = message,
	})
end

function FeedbackService:_handleFeedback(player, payload)
	if typeof(payload) ~= "table" then
		return
	end

	local categoryId = tostring(payload.Category or "")
	local category = self.categoryById[categoryId]
	if not category then
		self:_sendResult(player, false, "That feedback option is not available.")
		return
	end

	local now = os.time()
	local cooldown = Constants.Feedback.CooldownSeconds or 20
	local lastSubmitAt = self.lastSubmitAtByUserId[player.UserId] or 0
	if now - lastSubmitAt < cooldown then
		self:_sendResult(player, false, "Feedback waits a few seconds between sends.")
		return
	end

	self.lastSubmitAtByUserId[player.UserId] = now

	local roomId = nil
	if self.roomProgressService then
		roomId = self.roomProgressService:GetAreaForPlayer(player)
	end
	if not roomId and typeof(payload.RoomId) == "string" and Constants.GetRoom(payload.RoomId) then
		roomId = payload.RoomId
	end
	roomId = roomId or "Unknown"

	local room = Constants.GetRoom(roomId)
	local key = ("feedback_%010d_%d_%s"):format(now, player.UserId, HttpService:GenerateGUID(false))
	local record = {
		Category = category.Id,
		CategoryLabel = category.Label,
		RoomId = roomId,
		RoomName = room and room.Name or roomId,
		BuildVersion = Constants.BuildVersion,
		UserId = player.UserId,
		UserName = player.Name,
		DisplayName = player.DisplayName,
		PlaceId = game.PlaceId,
		JobId = game.JobId,
		SubmittedAtUnix = now,
	}

	local ok, err = pcall(function()
		self.feedbackStore:SetAsync(key, record)
	end)

	if not ok then
		warn(("[DON'T TOUCH IT] Feedback save failed: %s"):format(tostring(err)))
		self:_sendResult(player, false, "Feedback could not be saved right now.")
		return
	end

	self:_sendResult(player, true, "Feedback sent.")
end

return FeedbackService
