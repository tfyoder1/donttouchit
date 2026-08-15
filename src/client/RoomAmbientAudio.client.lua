local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local prologueRemote = remotes:WaitForChild(Constants.Remotes.Prologue)

local roomAmbienceConfig = Constants.AudioAssets and Constants.AudioAssets.RoomAmbience
if not roomAmbienceConfig then
	return
end

local SOUND_NAME = "DontTouchItRoomAmbience"
local CHECK_INTERVAL_SECONDS = 0.25
local CONTAINMENT_ROOM_ID = (Constants.Prologue and Constants.Prologue.ContainmentRoomId) or "TVRoom"

local character = nil
local rootPart = nil
local activeSound = nil
local activeRoomId = nil
local fadeTween = nil
local fadeToken = 0
local checkAccumulator = 0
local containmentIntroState = nil

local existingSound = SoundService:FindFirstChild(SOUND_NAME)
if existingSound and existingSound:IsA("Sound") then
	existingSound:Destroy()
end

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

local function positionInZone(position, zone)
	if not position or not zone or not zone.Min or not zone.Max then
		return false
	end

	return position.X >= zone.Min.X
		and position.X <= zone.Max.X
		and position.Y >= zone.Min.Y
		and position.Y <= zone.Max.Y
		and position.Z >= zone.Min.Z
		and position.Z <= zone.Max.Z
end

local function getRoomIdForPosition(position)
	for _, roomId in ipairs(Constants.RoomDetectionOrder or Constants.DiscoveryRoomOrder or Constants.RoomOrder or {}) do
		local room = Constants.GetRoom(roomId)
		if room and positionInZone(position, room.Zone) then
			return roomId
		end
	end

	return nil
end

local function getRoomConfig(roomId)
	local config = roomId and roomAmbienceConfig[roomId]
	if typeof(config) ~= "table" then
		return nil, nil
	end

	local soundId = normalizeSoundId(config.SoundId)
	if not soundId then
		return nil, nil
	end

	return config, soundId
end

local function getContainmentIntroConfig(roomId)
	local roomConfig = roomId and roomAmbienceConfig[roomId]
	if typeof(roomConfig) ~= "table" then
		return nil, nil
	end

	local config = roomConfig.ContainmentIntro
	if typeof(config) ~= "table" then
		return nil, nil
	end

	local soundId = normalizeSoundId(config.SoundId)
	if not soundId then
		return nil, nil
	end

	return config, soundId
end

local function consumeContainmentIntro()
	containmentIntroState = nil
end

local function getActiveRoomConfig(roomId)
	if containmentIntroState then
		if roomId ~= containmentIntroState.RoomId then
			if containmentIntroState.HasReachedRoom then
				consumeContainmentIntro()
			elseif os.clock() > containmentIntroState.ExpiresAt then
				consumeContainmentIntro()
			end
		else
			containmentIntroState.HasReachedRoom = true
			local config, soundId = getContainmentIntroConfig(roomId)
			if config then
				if os.clock() < containmentIntroState.ReadyAt then
					return nil, nil, true
				end

				return config, soundId, false
			end

			consumeContainmentIntro()
		end
	end

	local config, soundId = getRoomConfig(roomId)
	return config, soundId, false
end

local function isStartOverlayVisible()
	local uiGui = playerGui:FindFirstChild("DontTouchItUI")
	if not uiGui then
		return false
	end

	if uiGui:GetAttribute("GameplayHudSuppressed") == true then
		return true
	end

	local overlay = uiGui:FindFirstChild("StartChoiceOverlay", true)
	return overlay and overlay:IsA("GuiObject") and overlay.Visible == true
end

local function shouldSuppressAmbience()
	return playerGui:GetAttribute("DontTouchItPrologueActive") == true or isStartOverlayVisible()
end

local function fadeSound(sound, targetVolume, fadeSeconds, destroyWhenDone)
	fadeToken += 1
	local token = fadeToken

	if fadeTween then
		fadeTween:Cancel()
		fadeTween = nil
	end

	if not sound or not sound.Parent then
		return
	end

	fadeSeconds = math.max(0, tonumber(fadeSeconds) or 0)
	if fadeSeconds <= 0 then
		sound.Volume = targetVolume
		if destroyWhenDone then
			sound:Stop()
			sound:Destroy()
		end
		return
	end

	local tween = TweenService:Create(
		sound,
		TweenInfo.new(fadeSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Volume = targetVolume }
	)
	fadeTween = tween
	tween.Completed:Connect(function()
		if token ~= fadeToken then
			return
		end

		if fadeTween == tween then
			fadeTween = nil
		end

		if destroyWhenDone and sound.Parent then
			sound:Stop()
			sound:Destroy()
		end
	end)
	tween:Play()
end

local function stopAmbience(fadeSeconds)
	if not activeSound then
		return
	end

	local sound = activeSound
	local config = roomAmbienceConfig[activeRoomId] or {}
	activeSound = nil
	activeRoomId = nil
	fadeSound(sound, 0, fadeSeconds or config.FadeSeconds or 1.5, true)
end

local function startAmbience(roomId, config, soundId)
	local volume = math.clamp(tonumber(config.Volume) or 0.08, 0, 1)
	local fadeSeconds = math.max(0, tonumber(config.FadeSeconds) or 1.5)

	if activeSound and activeSound.Parent and activeRoomId == roomId and activeSound.SoundId == soundId then
		if not activeSound.IsPlaying then
			activeSound:Play()
		end
		if math.abs(activeSound.Volume - volume) > 0.005 then
			fadeSound(activeSound, volume, fadeSeconds, false)
		end
		return
	end

	if activeSound then
		stopAmbience(fadeSeconds)
	end

	local oldSound = SoundService:FindFirstChild(SOUND_NAME)
	if oldSound and oldSound:IsA("Sound") then
		oldSound:Destroy()
	end

	local sound = Instance.new("Sound")
	sound.Name = SOUND_NAME
	sound.SoundId = soundId
	sound.Volume = 0
	sound.Looped = true
	sound.Parent = SoundService

	activeSound = sound
	activeRoomId = roomId
	sound:Play()
	fadeSound(sound, volume, fadeSeconds, false)
end

local function updateAmbience()
	if not rootPart or shouldSuppressAmbience() then
		stopAmbience()
		return
	end

	local roomId = getRoomIdForPosition(rootPart.Position)
	local config, soundId, waitingForContainmentIntro = getActiveRoomConfig(roomId)
	if waitingForContainmentIntro then
		stopAmbience()
		return
	end

	if config then
		startAmbience(roomId, config, soundId)
	else
		stopAmbience()
	end
end

local function setCharacter(nextCharacter)
	character = nextCharacter
	rootPart = nil

	if not character then
		stopAmbience(0.35)
		return
	end

	rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		rootPart = character:WaitForChild("HumanoidRootPart", 8)
	end
end

local function scheduleContainmentIntro(payload)
	local config = getContainmentIntroConfig(CONTAINMENT_ROOM_ID)
	if not config then
		return
	end

	local spinUpSeconds = math.max(
		0,
		tonumber(payload.SpinUpSeconds) or (Constants.Prologue and Constants.Prologue.LightSpinUpSeconds) or 30
	)
	local bufferSeconds = math.max(0, tonumber(config.StartDelayBufferSeconds) or 0)
	local readyAt = os.clock() + spinUpSeconds + bufferSeconds
	containmentIntroState = {
		RoomId = CONTAINMENT_ROOM_ID,
		ReadyAt = readyAt,
		ExpiresAt = readyAt + 10,
	}

	stopAmbience(config.FadeSeconds or 0.35)
	updateAmbience()
end

prologueRemote.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end

	if payload.Action == "Contained" then
		scheduleContainmentIntro(payload)
	end
end)

player.CharacterAdded:Connect(function(nextCharacter)
	setCharacter(nextCharacter)
	updateAmbience()
end)

player.CharacterRemoving:Connect(function()
	setCharacter(nil)
end)

if player.Character then
	setCharacter(player.Character)
end

RunService.Heartbeat:Connect(function(deltaTime)
	checkAccumulator += deltaTime
	if checkAccumulator < CHECK_INTERVAL_SECONDS then
		return
	end

	checkAccumulator = 0
	updateAmbience()
end)
