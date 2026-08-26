local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local sessionStartRemote = remotes:WaitForChild(Constants.Remotes.SessionStart)

local SELECTED_ROOM_ATTRIBUTE = "DontTouchItStartPreloadRoomId"
local PRELOAD_FOLDER_NAME = "DontTouchItAudioPreloadCache"
local BATCH_SIZE = 4
local BATCH_PAUSE_SECONDS = 0.05

local PRIORITY_INTRO = 10
local PRIORITY_SELECTED_ROOM = 15
local PRIORITY_CAVE = 20
local PRIORITY_RESUME_ROOM = 30

local audioAssets = Constants.AudioAssets or {}
local attemptedSoundIds = {}
local inFlightSoundIds = {}
local queuedBySoundId = {}
local queue = {}
local nextSequence = 0
local isProcessingQueue = false

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

local function appendSoundId(soundIds, soundId)
	local normalizedSoundId = normalizeSoundId(soundId)
	if normalizedSoundId then
		table.insert(soundIds, normalizedSoundId)
	end
end

local function appendSoundIds(soundIds, sourceSoundIds)
	if typeof(sourceSoundIds) ~= "table" then
		return
	end

	for _, soundId in ipairs(sourceSoundIds) do
		appendSoundId(soundIds, soundId)
	end
end

local function getIntroSoundIds()
	local soundIds = {}
	local musicAudio = audioAssets.Music
	local interfaceAudio = audioAssets.Interface

	if musicAudio then
		appendSoundId(soundIds, musicAudio.IntroMusicId)
	end

	if interfaceAudio then
		appendSoundId(soundIds, interfaceAudio.MenuMoveSoundId)
	end

	return soundIds
end

local function appendCaveSoundIds(soundIds)
	local prologueAudio = audioAssets.Prologue
	if prologueAudio then
		appendSoundId(soundIds, prologueAudio.OutsideCaveAmbienceId)
		appendSoundId(soundIds, prologueAudio.InsideCaveAmbienceId)
		appendSoundId(soundIds, prologueAudio.FirstTouchAlarmId)
		appendSoundId(soundIds, prologueAudio.ComputerBootUpId)
		appendSoundId(soundIds, prologueAudio.TVPowerUpId)
		appendSoundId(soundIds, prologueAudio.LockdownId)
		appendSoundId(soundIds, prologueAudio.LockdownDoorEchoId)
		appendSoundIds(soundIds, prologueAudio.DripIds)
		appendSoundIds(soundIds, prologueAudio.CreakIds)
	end

	local footsteps = audioAssets.Footsteps
	if footsteps and footsteps.Rooms then
		appendSoundId(soundIds, footsteps.Rooms.CaveEntrance)
	end
end

local function getCaveSoundIds()
	local soundIds = {}
	appendCaveSoundIds(soundIds)
	return soundIds
end

local function appendTVRoomSoundIds(soundIds)
	local televisionAudio = audioAssets.Television
	if televisionAudio then
		appendSoundId(soundIds, televisionAudio.StaticId)
		appendSoundId(soundIds, televisionAudio.TestToneId)
		appendSoundId(soundIds, televisionAudio.PleaseStopId)
	end

	local secretDoorAudio = audioAssets.SecretDoors
	if secretDoorAudio then
		appendSoundId(soundIds, secretDoorAudio.LibraryRevealSoundId)
	end
end

local function appendLibrarySoundIds(soundIds)
	local secretDoorAudio = audioAssets.SecretDoors
	if secretDoorAudio then
		appendSoundId(soundIds, secretDoorAudio.LibraryRevealSoundId)
	end
end

local function appendBowlingSoundIds(soundIds)
	local bowlingAudio = audioAssets.Bowling
	if not bowlingAudio then
		return
	end

	appendSoundIds(soundIds, bowlingAudio.CosmicMusicIds)
	appendSoundIds(soundIds, bowlingAudio.StrikeSoundIds)
	appendSoundId(soundIds, bowlingAudio.MechanicalIdleSoundId)
end

local function getRoomSoundIds(roomId)
	local soundIds = {}
	if typeof(roomId) ~= "string" or not Constants.GetRoom(roomId) then
		return soundIds
	end

	local roomAmbience = audioAssets.RoomAmbience and audioAssets.RoomAmbience[roomId]
	if typeof(roomAmbience) == "table" then
		appendSoundId(soundIds, roomAmbience.SoundId)

		local containmentIntro = roomAmbience.ContainmentIntro
		if typeof(containmentIntro) == "table" then
			appendSoundId(soundIds, containmentIntro.SoundId)
		end
	end

	local footsteps = audioAssets.Footsteps
	if footsteps and footsteps.Rooms then
		appendSoundId(soundIds, footsteps.Rooms[roomId])
	end

	if roomId == "CaveEntrance" then
		appendCaveSoundIds(soundIds)
	elseif roomId == "TVRoom" then
		appendTVRoomSoundIds(soundIds)
	elseif roomId == "Library" then
		appendLibrarySoundIds(soundIds)
	elseif roomId == "BowlingAlley" then
		appendBowlingSoundIds(soundIds)
	end

	return soundIds
end

local function getPreloadFolder()
	local folder = SoundService:FindFirstChild(PRELOAD_FOLDER_NAME)
	if folder and folder:IsA("Folder") then
		return folder
	end

	folder = Instance.new("Folder")
	folder.Name = PRELOAD_FOLDER_NAME
	folder.Parent = SoundService
	return folder
end

local function preloadInstances(instances)
	if #instances <= 0 then
		return
	end

	local success = pcall(function()
		ContentProvider:PreloadAsync(instances)
	end)
	if success or #instances <= 1 then
		return
	end

	for _, instance in ipairs(instances) do
		pcall(function()
			ContentProvider:PreloadAsync({ instance })
		end)
	end
end

local function createPreloadSounds(jobs)
	local folder = getPreloadFolder()
	local sounds = {}

	for index, job in ipairs(jobs) do
		local sound = Instance.new("Sound")
		sound.Name = ("AudioPreloadSound%02d"):format(index)
		sound.SoundId = job.SoundId
		sound.Volume = 0
		sound.Parent = folder
		table.insert(sounds, sound)
	end

	return sounds
end

local function sortQueue()
	table.sort(queue, function(left, right)
		if left.Priority ~= right.Priority then
			return left.Priority < right.Priority
		end

		return left.Sequence < right.Sequence
	end)
end

local function processQueue()
	if isProcessingQueue then
		return
	end

	isProcessingQueue = true

	while #queue > 0 do
		sortQueue()

		local jobs = {}
		while #jobs < BATCH_SIZE and #queue > 0 do
			local job = table.remove(queue, 1)
			queuedBySoundId[job.SoundId] = nil

			if not attemptedSoundIds[job.SoundId] and not inFlightSoundIds[job.SoundId] then
				inFlightSoundIds[job.SoundId] = true
				table.insert(jobs, job)
			end
		end

		if #jobs > 0 then
			local sounds = createPreloadSounds(jobs)
			preloadInstances(sounds)

			for _, sound in ipairs(sounds) do
				sound:Destroy()
			end

			for _, job in ipairs(jobs) do
				inFlightSoundIds[job.SoundId] = nil
				attemptedSoundIds[job.SoundId] = true
			end
		end

		task.wait(BATCH_PAUSE_SECONDS)
	end

	isProcessingQueue = false

	if #queue > 0 then
		task.defer(processQueue)
	end
end

local function enqueueSoundId(soundId, label, priority)
	local normalizedSoundId = normalizeSoundId(soundId)
	if not normalizedSoundId or attemptedSoundIds[normalizedSoundId] or inFlightSoundIds[normalizedSoundId] then
		return false
	end

	local existingJob = queuedBySoundId[normalizedSoundId]
	if existingJob then
		if priority < existingJob.Priority then
			nextSequence += 1
			existingJob.Priority = priority
			existingJob.Sequence = nextSequence
			existingJob.Label = label
		end
		return false
	end

	nextSequence += 1
	local job = {
		SoundId = normalizedSoundId,
		Label = label,
		Priority = priority,
		Sequence = nextSequence,
	}
	queuedBySoundId[normalizedSoundId] = job
	table.insert(queue, job)
	return true
end

local function enqueueSoundIds(label, soundIds, priority)
	local didQueue = false
	for _, soundId in ipairs(soundIds) do
		didQueue = enqueueSoundId(soundId, label, priority) or didQueue
	end

	if didQueue and not isProcessingQueue then
		task.defer(processQueue)
	end
end

local function enqueueRoom(roomId, priority, label)
	if typeof(roomId) ~= "string" or not Constants.GetRoom(roomId) then
		return
	end

	enqueueSoundIds(label or ("Room:" .. roomId), getRoomSoundIds(roomId), priority)
end

local function enqueueSelectedRoom()
	local selectedRoomId = playerGui:GetAttribute(SELECTED_ROOM_ATTRIBUTE)
	if typeof(selectedRoomId) == "string" then
		enqueueRoom(selectedRoomId, PRIORITY_SELECTED_ROOM, "SelectedStartRoom")
	end
end

sessionStartRemote.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" or payload.Action ~= "Show" then
		return
	end

	enqueueSoundIds("CaveEntrance", getCaveSoundIds(), PRIORITY_CAVE)

	if payload.HasProgress == true and typeof(payload.ResumeRoomId) == "string" then
		enqueueRoom(payload.ResumeRoomId, PRIORITY_RESUME_ROOM, "ResumeRoom")
	end
end)

playerGui:GetAttributeChangedSignal(SELECTED_ROOM_ATTRIBUTE):Connect(enqueueSelectedRoom)

enqueueSoundIds("IntroStart", getIntroSoundIds(), PRIORITY_INTRO)
enqueueSelectedRoom()
