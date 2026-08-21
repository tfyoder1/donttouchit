local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local prologueRemote = remotes:WaitForChild(Constants.Remotes.Prologue)
local playerGui = player:WaitForChild("PlayerGui")

local active = false
local lockedDown = false
local ambientToken = 0
local inspectAccumulator = 0
local flashlightPart = nil
local renderConnection = nil
local lightingBaseline = nil
local lightBaseline = {}
local outsideAmbienceSound = nil
local outsideCaveOneShots = {}
local outsideCaveAudioDone = false
local firstTouchAlarmSound = nil
local heldFlashlightModel = nil
local beamPart = nil
local spotPart = nil
local characterConnection = nil
local lastInspectPosition = nil
local lastInspectLookVector = nil
local lastInspectSampleAt = 0
local lastInspectSignature = nil
local lastInspectCandidateIndex = 1

local FLASHLIGHT_LIGHT_COLOR = Color3.fromRGB(255, 226, 170)
local FLASHLIGHT_BEAM_COLOR = Color3.fromRGB(255, 211, 128)
local FLASHLIGHT_SPOT_COLOR = Color3.fromRGB(255, 218, 138)
local FLASHLIGHT_LENS_COLOR = Color3.fromRGB(255, 225, 142)
local FLASHLIGHT_OWNED_ATTRIBUTE = "DontTouchItHasFlashlight"

local gui = Instance.new("ScreenGui")
gui.Name = "DontTouchItPrologue"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = playerGui

local description = Instance.new("TextLabel")
description.Name = "FlashlightDescription"
description.AnchorPoint = Vector2.new(0.5, 1)
description.BackgroundColor3 = Color3.fromRGB(6, 8, 12)
description.BackgroundTransparency = 0.22
description.BorderSizePixel = 0
description.Font = Enum.Font.GothamSemibold
description.Position = UDim2.new(0.5, 0, 1, -96)
description.Size = UDim2.new(0.78, 0, 0, 36)
description.Text = ""
description.TextColor3 = Color3.fromRGB(224, 236, 245)
description.TextScaled = true
description.TextWrapped = true
description.Visible = false
description.ZIndex = 40
description.Parent = gui

local descriptionCorner = Instance.new("UICorner")
descriptionCorner.CornerRadius = UDim.new(0, 8)
descriptionCorner.Parent = description

local countdown = Instance.new("TextLabel")
countdown.Name = "ContainmentCountdown"
countdown.AnchorPoint = Vector2.new(0.5, 0.5)
countdown.BackgroundColor3 = Color3.fromRGB(8, 10, 14)
countdown.BackgroundTransparency = 0.16
countdown.BorderSizePixel = 0
countdown.Font = Enum.Font.GothamBlack
countdown.Position = UDim2.fromScale(0.5, 0.5)
countdown.Size = UDim2.new(0.86, 0, 0, 116)
countdown.Text = ""
countdown.TextColor3 = Color3.fromRGB(255, 242, 181)
countdown.TextScaled = true
countdown.TextWrapped = true
countdown.Visible = false
countdown.ZIndex = 42
countdown.Parent = gui

local countdownCorner = Instance.new("UICorner")
countdownCorner.CornerRadius = UDim.new(0, 10)
countdownCorner.Parent = countdown

local flash = Instance.new("Frame")
flash.Name = "ContainmentWhiteFlash"
flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.Size = UDim2.fromScale(1, 1)
flash.ZIndex = 45
flash.Parent = gui

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

local function playLocalSound(soundId, volume, playbackSpeed, lifetime)
	soundId = normalizeSoundId(soundId)
	if not soundId then
		return nil
	end

	local sound = Instance.new("Sound")
	sound.Name = "PrologueSound"
	sound.SoundId = soundId
	sound.Volume = volume or 0.45
	sound.PlaybackSpeed = playbackSpeed or 1
	sound.Parent = gui
	sound:Play()
	Debris:AddItem(sound, lifetime or 3)
	return sound
end

local function trackOutsideCaveSound(sound)
	if not sound then
		return nil
	end

	outsideCaveOneShots[sound] = true
	local endedConnection
	endedConnection = sound.Ended:Connect(function()
		outsideCaveOneShots[sound] = nil
		if endedConnection then
			endedConnection:Disconnect()
		end
	end)
	return sound
end

local function clearFirstTouchAlarm()
	if firstTouchAlarmSound then
		firstTouchAlarmSound:Stop()
		firstTouchAlarmSound:Destroy()
		firstTouchAlarmSound = nil
	end
end

local function startFirstTouchAlarm(soundId)
	soundId = normalizeSoundId(soundId)
	if not soundId then
		return nil
	end

	clearFirstTouchAlarm()

	local sound = Instance.new("Sound")
	sound.Name = "PrologueFirstTouchAlarm"
	sound.SoundId = soundId
	sound.Volume = 0.86
	sound.PlaybackSpeed = 1
	sound.Looped = true
	sound.Parent = gui
	sound:Play()
	firstTouchAlarmSound = sound
	return sound
end

local function finishFirstTouchAudio(bootSoundId)
	local alarm = firstTouchAlarmSound
	firstTouchAlarmSound = nil
	local bootDelay = 0.05

	if alarm and alarm.Parent then
		local fadeSeconds = 0.85
		bootDelay = fadeSeconds
		TweenService:Create(
			alarm,
			TweenInfo.new(fadeSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Volume = 0 }
		):Play()
		Debris:AddItem(alarm, fadeSeconds + 0.25)
	end

	task.delay(bootDelay, function()
		playLocalSound(bootSoundId, 0.72, 1, 5)
	end)
end

local function getListenerCFrame()
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if rootPart and rootPart:IsA("BasePart") then
		return rootPart.CFrame
	end

	local camera = workspace.CurrentCamera
	if camera then
		return camera.CFrame
	end

	return CFrame.new()
end

local function playSpatialLocalSound(soundId, worldPosition, volume, playbackSpeed, lifetime, rollOffMaxDistance)
	soundId = normalizeSoundId(soundId)
	if not soundId then
		return nil
	end

	local emitter = Instance.new("Part")
	emitter.Name = "PrologueLockEchoEmitter"
	emitter.Anchored = true
	emitter.CanCollide = false
	emitter.CanQuery = false
	emitter.CanTouch = false
	emitter.Transparency = 1
	emitter.Size = Vector3.new(0.25, 0.25, 0.25)
	emitter.CFrame = CFrame.new(worldPosition)
	emitter.Parent = workspace

	local sound = Instance.new("Sound")
	sound.Name = "PrologueDoorLockEcho"
	sound.SoundId = soundId
	sound.Volume = volume or 0.65
	sound.PlaybackSpeed = playbackSpeed or 1
	sound.RollOffMinDistance = 8
	sound.RollOffMaxDistance = rollOffMaxDistance or 120
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.Parent = emitter
	sound:Play()

	Debris:AddItem(emitter, lifetime or 6)
	return sound
end

local function playDoorLockEchoes(soundId)
	soundId = normalizeSoundId(soundId)
	if not soundId then
		return
	end

	local listenerCFrame = getListenerCFrame()
	local origin = listenerCFrame.Position
	local rightVector = listenerCFrame.RightVector
	local forwardVector = listenerCFrame.LookVector
	local upVector = Vector3.new(0, 1, 0)
	local echoes = {
		{ Right = -10, Forward = -14, Up = 0.5, Delay = 0, Volume = 0.86, Speed = 0.96, MaxDistance = 80 },
		{ Right = 22, Forward = 16, Up = 1.5, Delay = 0.16, Volume = 0.7, Speed = 1.03, MaxDistance = 95 },
		{ Right = -34, Forward = 30, Up = 2.2, Delay = 0.34, Volume = 0.58, Speed = 0.9, MaxDistance = 120 },
		{ Right = 46, Forward = -24, Up = 0.8, Delay = 0.55, Volume = 0.46, Speed = 1.08, MaxDistance = 145 },
		{ Right = -8, Forward = 64, Up = 3, Delay = 0.78, Volume = 0.38, Speed = 0.98, MaxDistance = 165 },
	}

	for _, echo in ipairs(echoes) do
		task.delay(echo.Delay, function()
			local position = origin
				+ rightVector * echo.Right
				+ forwardVector * echo.Forward
				+ upVector * echo.Up
			playSpatialLocalSound(soundId, position, echo.Volume, echo.Speed, 6, echo.MaxDistance)
		end)
	end
end

local function playDoorLockEchoesAfter(lockdownSound, soundId)
	local played = false
	local function triggerEchoes()
		if played then
			return
		end

		played = true
		playDoorLockEchoes(soundId)
	end

	if lockdownSound then
		local endedConnection
		endedConnection = lockdownSound.Ended:Connect(function()
			if endedConnection then
				endedConnection:Disconnect()
			end
			triggerEchoes()
		end)

		task.delay(5.8, function()
			if not played and (not lockdownSound.Parent or lockdownSound.TimeLength <= 0) then
				triggerEchoes()
			end
		end)
	else
		task.delay(4.2, triggerEchoes)
	end
end

local function stopOutsideAmbience()
	if outsideAmbienceSound then
		outsideAmbienceSound:Stop()
		outsideAmbienceSound:Destroy()
		outsideAmbienceSound = nil
	end
end

local function stopOutsideCaveAudio()
	outsideCaveAudioDone = true
	ambientToken += 1
	stopOutsideAmbience()

	for sound in pairs(outsideCaveOneShots) do
		if sound and sound.Parent then
			sound:Stop()
			sound:Destroy()
		end
	end
	outsideCaveOneShots = {}
end

local function startOutsideAmbience()
	if outsideCaveAudioDone then
		return
	end

	local prologueAudio = if Constants.AudioAssets then Constants.AudioAssets.Prologue else nil
	local soundId = prologueAudio and prologueAudio.OutsideCaveAmbienceId
	soundId = normalizeSoundId(soundId)
	if not soundId then
		return
	end

	stopOutsideAmbience()

	local sound = Instance.new("Sound")
	sound.Name = "PrologueOutsideCaveAmbience"
	sound.SoundId = soundId
	sound.Volume = 0.28
	sound.PlaybackSpeed = 1
	sound.Looped = true
	sound.Parent = gui
	sound:Play()
	outsideAmbienceSound = sound
end

local function getRandomSoundId(soundIds)
	if typeof(soundIds) ~= "table" or #soundIds == 0 then
		return nil
	end

	return soundIds[math.random(1, #soundIds)]
end

local function captureLightingBaseline()
	if lightingBaseline then
		return
	end

	lightingBaseline = {
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		Brightness = Lighting.Brightness,
		ClockTime = Lighting.ClockTime,
		FogStart = Lighting.FogStart,
		FogEnd = Lighting.FogEnd,
		FogColor = Lighting.FogColor,
	}
end

local function ancestorNameContains(instance, pattern)
	local current = instance
	while current and current ~= workspace do
		if string.find(string.lower(current.Name), pattern) then
			return true
		end
		current = current.Parent
	end

	return false
end

local function isControlPanelLight(light)
	return ancestorNameContains(light, "control")
		or ancestorNameContains(light, "digital")
		or ancestorNameContains(light, "panel")
end

local function isCavePathLight(light)
	return ancestorNameContains(light, "cave") and not ancestorNameContains(light, "alarm")
end

local function shouldKeepLightInPrologue(light)
	return isCavePathLight(light) or isControlPanelLight(light)
end

local function dimWorldLights()
	lightBaseline = {}

	for _, instance in ipairs(workspace:GetDescendants()) do
		if instance:IsA("PointLight") or instance:IsA("SpotLight") or instance:IsA("SurfaceLight") then
			lightBaseline[instance] = {
				Enabled = instance.Enabled,
				Brightness = instance.Brightness,
			}

			if not shouldKeepLightInPrologue(instance) then
				instance.Enabled = false
				instance.Brightness = 0
			end
		end
	end
end

local function applyDarkLighting(darkLighting)
	captureLightingBaseline()
	darkLighting = darkLighting or Constants.Prologue.DarkLighting or {}
	Lighting.Ambient = darkLighting.Ambient or Color3.fromRGB(1, 2, 5)
	Lighting.OutdoorAmbient = darkLighting.OutdoorAmbient or Color3.fromRGB(0, 0, 0)
	Lighting.Brightness = darkLighting.Brightness or 0.05
	Lighting.ClockTime = darkLighting.ClockTime or 0
	Lighting.FogStart = darkLighting.FogStart or 16
	Lighting.FogEnd = darkLighting.FogEnd or 120
	Lighting.FogColor = darkLighting.FogColor or Color3.fromRGB(4, 6, 12)
end

local function destroyFlashlight()
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end

	if characterConnection then
		characterConnection:Disconnect()
		characterConnection = nil
	end

	if heldFlashlightModel then
		heldFlashlightModel:Destroy()
		heldFlashlightModel = nil
	end

	if beamPart then
		beamPart:Destroy()
		beamPart = nil
	end

	if spotPart then
		spotPart:Destroy()
		spotPart = nil
	end

	if flashlightPart then
		flashlightPart:Destroy()
		flashlightPart = nil
	end
end

local function getHandPart()
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChild("RightHand")
		or character:FindFirstChild("Right Arm")
		or character:FindFirstChild("RightLowerArm")
end

local function weldToHand(part, hand)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hand
	weld.Part1 = part
	weld.Parent = part
end

local function createHeldFlashlight()
	if heldFlashlightModel then
		heldFlashlightModel:Destroy()
		heldFlashlightModel = nil
	end

	local hand = getHandPart()
	if not hand then
		return
	end

	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local forward = rootPart and rootPart.CFrame.LookVector or Vector3.new(0, 0, -1)
	local baseCFrame = CFrame.lookAt(hand.Position + forward * 0.45 - Vector3.new(0, 0.2, 0), hand.Position + forward * 2)

	local model = Instance.new("Model")
	model.Name = "LocalHeldFlashlight"
	model.Parent = character

	local body = Instance.new("Part")
	body.Name = "FlashlightBody"
	body.Anchored = false
	body.CanCollide = false
	body.CastShadow = false
	body.Massless = true
	body.Shape = Enum.PartType.Cylinder
	body.Size = Vector3.new(0.26, 0.92, 0.26)
	body.Color = Color3.fromRGB(34, 39, 46)
	body.Material = Enum.Material.Metal
	body.CFrame = baseCFrame * CFrame.Angles(math.rad(90), 0, 0)
	body.Parent = model
	weldToHand(body, hand)

	local lens = Instance.new("Part")
	lens.Name = "FlashlightLens"
	lens.Anchored = false
	lens.CanCollide = false
	lens.CastShadow = false
	lens.Massless = true
	lens.Shape = Enum.PartType.Cylinder
	lens.Size = Vector3.new(0.34, 0.12, 0.34)
	lens.Color = FLASHLIGHT_LENS_COLOR
	lens.Material = Enum.Material.Neon
	lens.CFrame = baseCFrame * CFrame.new(0, 0, -0.5) * CFrame.Angles(math.rad(90), 0, 0)
	lens.Parent = model
	weldToHand(lens, hand)

	local grip = Instance.new("Part")
	grip.Name = "FlashlightGrip"
	grip.Anchored = false
	grip.CanCollide = false
	grip.CastShadow = false
	grip.Massless = true
	grip.Size = Vector3.new(0.18, 0.5, 0.18)
	grip.Color = Color3.fromRGB(22, 24, 29)
	grip.Material = Enum.Material.Metal
	grip.CFrame = baseCFrame * CFrame.new(0, -0.32, 0.08)
	grip.Parent = model
	weldToHand(grip, hand)

	heldFlashlightModel = model
end

local function prettifyName(name)
	name = tostring(name or "")
	name = name:gsub("(%l)(%u)", "%1 %2")
	name = name:gsub("_", " ")
	name = name:gsub("%d+$", "")
	name = name:gsub("^%s+", ""):gsub("%s+$", "")
	return name
end

local function getPromptNear(instance)
	local current = instance
	while current and current ~= workspace do
		local prompt = if current:IsA("ProximityPrompt") then current else current:FindFirstChild("InteractPrompt", true)
		if prompt and prompt:IsA("ProximityPrompt") and not prompt:GetAttribute("PrologueInspectIgnore") then
			return prompt
		end
		current = current.Parent
	end

	return nil
end

local function hasPrologueInspectIgnore(instance)
	local current = instance
	while current and current ~= workspace do
		if current:GetAttribute("PrologueInspectIgnore") == true then
			return true
		end
		current = current.Parent
	end

	return false
end

local function getPrologueDescriptionData(instance)
	if hasPrologueInspectIgnore(instance) then
		return nil
	end

	local current = instance
	while current and current ~= workspace do
		local text = current:GetAttribute("PrologueDescription")
		if typeof(text) == "string" and text ~= "" then
			return {
				Key = current:GetFullName(),
				Priority = tonumber(current:GetAttribute("ProloguePriority")) or 100,
				Text = text,
			}
		end
		current = current.Parent
	end

	local prompt = getPromptNear(instance)
	if prompt and prompt.ObjectText ~= "" then
		local ownsFlashlight = player:GetAttribute(FLASHLIGHT_OWNED_ATTRIBUTE) == true
		return {
			Key = prompt:GetFullName(),
			Priority = tonumber(prompt:GetAttribute("ProloguePriority")) or 60,
			Text = if ownsFlashlight
				then ("The flashlight catches %s. It looks much less harmless in the dark."):format(prompt.ObjectText)
				else ("%s is close enough to notice, even without a light."):format(prompt.ObjectText),
		}
	end

	if instance and instance.Name ~= "" and instance.Name ~= "Part" then
		local name = prettifyName(instance.Name)
		if name ~= "" then
			return {
				Key = instance:GetFullName(),
				Priority = tonumber(instance:GetAttribute("ProloguePriority")) or 20,
				Text = ("The beam lands on %s. No labels explain why it is here."):format(name),
			}
		end
	end

	return nil
end

local function getPrologueDescription(instance)
	local data = getPrologueDescriptionData(instance)
	return if data then data.Text else nil
end

local function getRootPart()
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function getInspectionRaycastParams()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude = {}
	if player.Character then
		table.insert(exclude, player.Character)
	end
	if flashlightPart then
		table.insert(exclude, flashlightPart)
	end
	if beamPart then
		table.insert(exclude, beamPart)
	end
	if spotPart then
		table.insert(exclude, spotPart)
	end
	params.FilterDescendantsInstances = exclude
	return params
end

local function getInspectionRays(camera)
	local viewportSize = camera.ViewportSize
	local spread = Constants.Prologue.InspectCandidateSpreadPixels or 32
	if viewportSize.X <= 0 or viewportSize.Y <= 0 then
		return {
			{
				Origin = camera.CFrame.Position,
				Direction = camera.CFrame.LookVector,
				Center = true,
			},
		}
	end

	local center = Vector2.new(viewportSize.X * 0.5, viewportSize.Y * 0.5)
	local offsets = {
		Vector2.new(0, 0),
		Vector2.new(spread, 0),
		Vector2.new(-spread, 0),
		Vector2.new(0, spread),
		Vector2.new(0, -spread),
		Vector2.new(spread, spread),
		Vector2.new(-spread, spread),
		Vector2.new(spread, -spread),
		Vector2.new(-spread, -spread),
	}

	local rays = {}
	for index, offset in ipairs(offsets) do
		local ray = camera:ViewportPointToRay(center.X + offset.X, center.Y + offset.Y)
		table.insert(rays, {
			Origin = ray.Origin,
			Direction = ray.Direction.Unit,
			Center = index == 1,
		})
	end

	return rays
end

local function getInspectionCandidates(camera)
	local params = getInspectionRaycastParams()
	local range = Constants.Prologue.InspectRange or 34
	local seenByKey = {}
	local candidates = {}

	for _, ray in ipairs(getInspectionRays(camera)) do
		local result = workspace:Raycast(ray.Origin, ray.Direction * range, params)
		if result and result.Instance then
			local data = getPrologueDescriptionData(result.Instance)
			if data then
				local distanceScore = math.clamp((range - result.Distance) / range, 0, 1) * 4
				local centerScore = if ray.Center then 7 else 0
				local score = data.Priority + distanceScore + centerScore
				local existing = seenByKey[data.Key]
				if not existing or score > existing.Score then
					local candidate = {
						Key = data.Key,
						Priority = data.Priority,
						Score = score,
						Text = data.Text,
					}
					seenByKey[data.Key] = candidate
				end
			end
		end
	end

	for _, candidate in pairs(seenByKey) do
		table.insert(candidates, candidate)
	end

	table.sort(candidates, function(left, right)
		if left.Priority ~= right.Priority then
			return left.Priority > right.Priority
		end
		if left.Score ~= right.Score then
			return left.Score > right.Score
		end
		return left.Key < right.Key
	end)

	local maxCandidates = Constants.Prologue.InspectMaxCandidates or 5
	while #candidates > maxCandidates do
		table.remove(candidates)
	end

	return candidates
end

local function getInspectionSignature(candidates)
	local keys = {}
	for _, candidate in ipairs(candidates) do
		table.insert(keys, candidate.Key)
	end

	return table.concat(keys, "|")
end

local function shouldSampleInspection(camera)
	local now = os.clock()
	local root = getRootPart()
	local position = if root then root.Position else nil
	local lookVector = camera.CFrame.LookVector
	local moved = false
	local looked = false

	if not lastInspectPosition or not lastInspectLookVector then
		return true, position, lookVector, true
	end

	if position then
		local movementThreshold = Constants.Prologue.InspectMovementThreshold or 0.85
		moved = (position - lastInspectPosition).Magnitude >= movementThreshold
	end

	local lookDot = math.clamp(lookVector:Dot(lastInspectLookVector), -1, 1)
	local lookAngle = math.deg(math.acos(lookDot))
	looked = lookAngle >= (Constants.Prologue.InspectLookThresholdDegrees or 10)

	local stillResampleSeconds = Constants.Prologue.InspectStillResampleSeconds or 4.5
	local stale = now - lastInspectSampleAt >= stillResampleSeconds
	return moved or looked or stale, position, lookVector, moved
end

local function updateInspection(deltaTime)
	inspectAccumulator += deltaTime
	local interval = Constants.Prologue.InspectIntervalSeconds or 0.18
	if inspectAccumulator < interval then
		return
	end
	inspectAccumulator = 0

	if not active or lockedDown then
		description.Visible = false
		lastInspectPosition = nil
		lastInspectLookVector = nil
		lastInspectSignature = nil
		return
	end

	local camera = workspace.CurrentCamera
	if not camera then
		description.Visible = false
		return
	end

	local shouldSample, position, lookVector, moved = shouldSampleInspection(camera)
	if not shouldSample then
		return
	end
	lastInspectPosition = position or camera.CFrame.Position
	lastInspectLookVector = lookVector
	lastInspectSampleAt = os.clock()

	local candidates = getInspectionCandidates(camera)
	if #candidates == 0 then
		description.Visible = false
		lastInspectSignature = nil
		lastInspectCandidateIndex = 1
		return
	end

	local signature = getInspectionSignature(candidates)
	if moved and signature == lastInspectSignature and #candidates > 1 then
		lastInspectCandidateIndex = (lastInspectCandidateIndex % #candidates) + 1
	else
		lastInspectCandidateIndex = 1
	end

	lastInspectSignature = signature
	local selected = candidates[lastInspectCandidateIndex] or candidates[1]
	description.Text = selected.Text
	description.Visible = true
end

local function getFlashlightRaycast(camera, range)
	local params = getInspectionRaycastParams()
	return workspace:Raycast(camera.CFrame.Position, camera.CFrame.LookVector * range, params)
end

local function cframeWithUp(position, upVector)
	local up = upVector.Unit
	local seed = if math.abs(up:Dot(Vector3.yAxis)) > 0.95 then Vector3.xAxis else Vector3.yAxis
	local right = seed:Cross(up).Unit
	local back = right:Cross(up).Unit
	return CFrame.fromMatrix(position, right, up, back)
end

local function updateVisibleBeam(camera, range)
	if not camera or not beamPart or not spotPart then
		return
	end

	local result = getFlashlightRaycast(camera, range)
	local origin = camera.CFrame.Position
	local direction = camera.CFrame.LookVector
	local distance = range
	if result then
		distance = math.max(1, (result.Position - origin).Magnitude)
	end

	beamPart.Size = Vector3.new(0.16, 0.16, distance)
	beamPart.CFrame = CFrame.lookAt(origin + direction * (distance * 0.5), origin + direction * distance)
	beamPart.Transparency = if result then 0.78 else 0.9

	if result then
		local spotSize = math.clamp(distance / 8, 1.8, 5.2)
		spotPart.Size = Vector3.new(spotSize, 0.045, spotSize)
		spotPart.CFrame = cframeWithUp(result.Position + result.Normal * 0.045, result.Normal)
		spotPart.Transparency = 0.28
	else
		spotPart.Transparency = 1
	end
end

local function createFlashlight(range)
	destroyFlashlight()
	createHeldFlashlight()

	local part = Instance.new("Part")
	part.Name = "LocalPrologueFlashlight"
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.Transparency = 1
	part:SetAttribute("PrologueInspectIgnore", true)
	part.Parent = workspace

	local light = Instance.new("SpotLight")
	light.Name = "FlashlightBeam"
	light.Angle = 50
	light.Brightness = 8
	light.Color = FLASHLIGHT_LIGHT_COLOR
	light.Face = Enum.NormalId.Front
	light.Range = range or Constants.Prologue.FlashlightRange or 58
	light.Shadows = true
	light.Parent = part

	beamPart = Instance.new("Part")
	beamPart.Name = "LocalPrologueFlashlightBeam"
	beamPart.Anchored = true
	beamPart.CanCollide = false
	beamPart.CanTouch = false
	beamPart.CanQuery = false
	beamPart.CastShadow = false
	beamPart.Color = FLASHLIGHT_BEAM_COLOR
	beamPart.Material = Enum.Material.Neon
	beamPart.Size = Vector3.new(0.16, 0.16, 8)
	beamPart.Transparency = 0.86
	beamPart:SetAttribute("PrologueInspectIgnore", true)
	beamPart.Parent = workspace

	spotPart = Instance.new("Part")
	spotPart.Name = "LocalPrologueFlashlightSpot"
	spotPart.Anchored = true
	spotPart.CanCollide = false
	spotPart.CanTouch = false
	spotPart.CanQuery = false
	spotPart.CastShadow = false
	spotPart.Color = FLASHLIGHT_SPOT_COLOR
	spotPart.Material = Enum.Material.Neon
	spotPart.Shape = Enum.PartType.Cylinder
	spotPart.Size = Vector3.new(2.2, 0.045, 2.2)
	spotPart.Transparency = 1
	spotPart:SetAttribute("PrologueInspectIgnore", true)
	spotPart.Parent = workspace

	flashlightPart = part
	characterConnection = player.CharacterAdded:Connect(function()
		task.wait(0.25)
		if active and not lockedDown then
			createHeldFlashlight()
		end
	end)

	local flashlightRange = range or Constants.Prologue.FlashlightRange or 58
	renderConnection = RunService.RenderStepped:Connect(function(deltaTime)
		local camera = workspace.CurrentCamera
		if camera and flashlightPart then
			flashlightPart.CFrame = camera.CFrame
			updateVisibleBeam(camera, flashlightRange)
		end
		updateInspection(deltaTime)
	end)
end

local function startInspectionOnly()
	destroyFlashlight()
	renderConnection = RunService.RenderStepped:Connect(function(deltaTime)
		updateInspection(deltaTime)
	end)
end

local function startAmbientLoop()
	ambientToken += 1
	local token = ambientToken

	task.spawn(function()
		while active and token == ambientToken and not outsideCaveAudioDone do
			task.wait(math.random(24, 70) / 10)
			if not active or token ~= ambientToken or outsideCaveAudioDone then
				return
			end

			local prologueAudio = if Constants.AudioAssets then Constants.AudioAssets.Prologue else nil
			local dripId = if prologueAudio then getRandomSoundId(prologueAudio.DripIds) else nil
			local creakId = if prologueAudio then getRandomSoundId(prologueAudio.CreakIds) else nil
			if dripId and math.random() < 0.68 then
				trackOutsideCaveSound(playLocalSound(dripId, 0.34, math.random(94, 106) / 100, 4))
			elseif creakId then
				trackOutsideCaveSound(playLocalSound(creakId, 0.22, math.random(90, 104) / 100, 4))
			end
		end
	end)
end

local function beginPrologue(payload)
	active = true
	lockedDown = false
	outsideCaveAudioDone = false
	playerGui:SetAttribute("DontTouchItPrologueActive", true)
	countdown.Visible = false
	flash.BackgroundTransparency = 1
	description.Text = payload.Message or "The flashlight works. That is more reassuring than the cave."
	description.Visible = true

	applyDarkLighting(payload.DarkLighting)
	dimWorldLights()
	if player:GetAttribute(FLASHLIGHT_OWNED_ATTRIBUTE) == true then
		createFlashlight(payload.FlashlightRange)
	else
		startInspectionOnly()
	end
	startOutsideAmbience()
	startAmbientLoop()
	clearFirstTouchAlarm()
	playLocalSound("rbxasset://sounds/button.wav", 0.18, 0.36, 2.5)
end

local function playLockdownCountdown(payload)
	if lockedDown then
		return
	end

	lockedDown = true
	active = false
	ambientToken += 1
	stopOutsideAmbience()
	description.Visible = false
	local seconds = math.max(1, math.floor(payload.CountdownSeconds or Constants.Prologue.CountdownSeconds or 3))
	local prefix = payload.Message or "Forced teleportation of unknown personnel in"
	countdown.Visible = true
	local prologueAudio = if Constants.AudioAssets then Constants.AudioAssets.Prologue else nil
	local firstTouchAlarmId = prologueAudio and (prologueAudio.FirstTouchAlarmId or prologueAudio.LockdownId)
	local doorEchoId = prologueAudio and prologueAudio.LockdownDoorEchoId
	local alarmSound = startFirstTouchAlarm(firstTouchAlarmId)
	playDoorLockEchoesAfter(nil, doorEchoId)

	task.spawn(function()
		for remaining = seconds, 1, -1 do
			countdown.Text = ("%s %d..."):format(prefix, remaining)
			if not alarmSound then
				playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.82, 0.42 + remaining * 0.08, 1.4)
				playLocalSound("rbxasset://sounds/snap.wav", 0.55, 0.34, 1.4)
			end
			task.wait(1)
		end

		countdown.Text = "LOCKING DOORS"
		playLocalSound("rbxasset://sounds/snap.wav", 0.9, 0.28, 2.5)
		playLocalSound("rbxasset://sounds/button.wav", 0.8, 0.38, 2.5)
		flash.BackgroundTransparency = 0
		TweenService:Create(
			flash,
			TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1 }
		):Play()
	end)
end

local function restoreNormalLighting(seconds)
	seconds = math.max(1, tonumber(seconds) or Constants.Prologue.LightSpinUpSeconds or 30)
	destroyFlashlight()
	active = false
	lockedDown = false
	playerGui:SetAttribute("DontTouchItPrologueActive", false)
	ambientToken += 1
	stopOutsideAmbience()
	description.Visible = false
	countdown.Visible = false

	local prologueAudio = if Constants.AudioAssets then Constants.AudioAssets.Prologue else nil
	finishFirstTouchAudio(prologueAudio and prologueAudio.ComputerBootUpId)

	if lightingBaseline then
		TweenService:Create(
			Lighting,
			TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{
				Ambient = lightingBaseline.Ambient,
				OutdoorAmbient = lightingBaseline.OutdoorAmbient,
				Brightness = lightingBaseline.Brightness,
				ClockTime = lightingBaseline.ClockTime,
				FogStart = lightingBaseline.FogStart,
				FogEnd = lightingBaseline.FogEnd,
				FogColor = lightingBaseline.FogColor,
			}
		):Play()
	end

	for light, saved in pairs(lightBaseline) do
		if light and light.Parent then
			if saved.Enabled then
				light.Enabled = true
				light.Brightness = 0
				TweenService:Create(
					light,
					TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
					{ Brightness = saved.Brightness or 1 }
				):Play()
			else
				light.Enabled = false
				light.Brightness = saved.Brightness or 0
			end
		end
	end

	task.delay(seconds + 0.2, function()
		lightingBaseline = nil
		lightBaseline = {}
	end)
end

prologueRemote.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end

	if payload.Action == "Begin" then
		beginPrologue(payload)
	elseif payload.Action == "Lockdown" then
		playLockdownCountdown(payload)
	elseif payload.Action == "Contained" then
		restoreNormalLighting(payload.SpinUpSeconds)
	elseif payload.Action == "StopOutsideCaveAudio" then
		stopOutsideCaveAudio()
	end
end)
