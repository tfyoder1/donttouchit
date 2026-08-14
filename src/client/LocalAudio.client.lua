local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local localAudioRemote = remotes:WaitForChild(Constants.Remotes.LocalAudio)
local playerGui = player:WaitForChild("PlayerGui")

local function normalizeSoundId(soundId)
	if typeof(soundId) == "number" then
		return "rbxassetid://" .. tostring(soundId)
	end

	if typeof(soundId) ~= "string" or soundId == "" then
		return nil
	end

	if string.match(soundId, "^%d+$") then
		return "rbxassetid://" .. soundId
	end

	return soundId
end

local function playSound(payload)
	if typeof(payload) ~= "table" then
		return
	end

	local soundId = normalizeSoundId(payload.SoundId)
	if not soundId then
		return
	end

	local sound = Instance.new("Sound")
	sound.Name = payload.Name or "DontTouchItLocalAudio"
	sound.SoundId = soundId
	sound.Volume = math.clamp(tonumber(payload.Volume) or 0.5, 0, 1)
	sound.PlaybackSpeed = math.clamp(tonumber(payload.PlaybackSpeed) or 1, 0.1, 4)
	sound.Parent = playerGui or SoundService
	sound:Play()

	Debris:AddItem(sound, math.max(0.2, tonumber(payload.Lifetime) or 3))
end

localAudioRemote.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" or payload.Action ~= "PlaySound" then
		return
	end

	playSound(payload)
end)
