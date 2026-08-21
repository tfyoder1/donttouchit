local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local RemoteService = require(script.Parent:WaitForChild("RemoteService"))

local TutorialPreferencesService = {}
TutorialPreferencesService.__index = TutorialPreferencesService

local BUCKET_NAME = "UiOptions"
local TUTORIALS_KEY = "Tutorials"
local MAX_TUTORIAL_ID_LENGTH = 96

local function sanitizeTutorialId(value)
	if typeof(value) ~= "string" then
		return nil
	end

	local tutorialId = string.sub(value, 1, MAX_TUTORIAL_ID_LENGTH)
	tutorialId = string.gsub(tutorialId, "[^%w%._%-:/]", "_")
	if tutorialId == "" then
		return nil
	end

	return tutorialId
end

local function sanitizeCompleted(completed)
	local sanitized = {}
	if typeof(completed) ~= "table" then
		return sanitized
	end

	for key, value in pairs(completed) do
		local tutorialId = sanitizeTutorialId(key)
		if tutorialId and value == true then
			sanitized[tutorialId] = true
		end
	end

	return sanitized
end

local function sanitizeBucket(bucket)
	local completed = {}
	local enabled = true
	if typeof(bucket) == "table" then
		enabled = bucket.Enabled ~= false
		completed = sanitizeCompleted(bucket.Completed)
	end

	return {
		Enabled = enabled,
		Completed = completed,
	}
end

local function copyCompleted(completed)
	local copy = {}
	for key, value in pairs(completed or {}) do
		if value == true then
			copy[key] = true
		end
	end
	return copy
end

function TutorialPreferencesService.new()
	return setmetatable({
		preferencesService = nil,
		remote = nil,
	}, TutorialPreferencesService)
end

function TutorialPreferencesService:Initialize(preferencesService)
	self.preferencesService = preferencesService
	self.remote = RemoteService.GetRemote(Constants.Remotes.TutorialPreferences)

	self.remote.OnServerEvent:Connect(function(player, payload)
		self:_handleRemote(player, payload)
	end)
end

function TutorialPreferencesService:_load(player)
	if not self.preferencesService then
		return sanitizeBucket(nil)
	end

	local uiOptions = self.preferencesService:GetBucket(player, BUCKET_NAME)
	return sanitizeBucket(uiOptions[TUTORIALS_KEY])
end

function TutorialPreferencesService:_save(player, state)
	local sanitized = sanitizeBucket(state)
	if self.preferencesService then
		self.preferencesService:MergeBucket(player, BUCKET_NAME, {
			[TUTORIALS_KEY] = sanitized,
		})
	end
	return sanitized
end

function TutorialPreferencesService:_sendLoaded(player)
	local state = self:_load(player)
	self.remote:FireClient(player, {
		Action = "Loaded",
		TutorialsEnabled = state.Enabled,
		Completed = copyCompleted(state.Completed),
	})
end

function TutorialPreferencesService:_setEnabled(player, enabled)
	local state = self:_load(player)
	state.Enabled = enabled == true
	state = self:_save(player, state)
	self.remote:FireClient(player, {
		Action = "Loaded",
		TutorialsEnabled = state.Enabled,
		Completed = copyCompleted(state.Completed),
	})
end

function TutorialPreferencesService:_complete(player, tutorialId)
	tutorialId = sanitizeTutorialId(tutorialId)
	if not tutorialId then
		return
	end

	local state = self:_load(player)
	state.Completed[tutorialId] = true
	state = self:_save(player, state)
	self.remote:FireClient(player, {
		Action = "Completed",
		TutorialId = tutorialId,
		TutorialsEnabled = state.Enabled,
		Completed = copyCompleted(state.Completed),
	})
end

function TutorialPreferencesService:_handleRemote(player, payload)
	if typeof(payload) ~= "table" then
		return
	end

	if payload.Action == "Request" then
		self:_sendLoaded(player)
	elseif payload.Action == "SetEnabled" then
		self:_setEnabled(player, payload.Enabled == true)
	elseif payload.Action == "Complete" then
		self:_complete(player, payload.TutorialId)
	end
end

return TutorialPreferencesService
