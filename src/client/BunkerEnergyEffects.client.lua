local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local recoveryRemote = remotes:WaitForChild(Constants.Remotes.NourishmentRecovery)

local PERSONAL_LIGHT_NAME = "DontTouchItPersonalBunkerLight"
local COLOR_EFFECT_NAME = "DontTouchItBunkerPerceptionColor"
local BLOOM_EFFECT_NAME = "DontTouchItBunkerPerceptionBloom"
local ATMOSPHERE_EFFECT_NAME = "DontTouchItBunkerEnergyAtmosphere"
local DOF_EFFECT_NAME = "DontTouchItBunkerEnergyDepth"
local LOW_ENERGY_GUI_NAME = "DontTouchItLowEnergyVignette"
local RECOVERY_GUI_NAME = "DontTouchItNourishmentRecovery"
local OBSERVED_HIGHLIGHT_NAME = "DontTouchItObservedBunkerAura"
local OBSERVED_ATTACHMENT_NAME = "DontTouchItObservedBunkerAuraAttachment"
local OBSERVED_LIGHT_NAME = "DontTouchItObservedBunkerAuraLight"
local OBSERVED_SPARKS_NAME = "DontTouchItObservedBunkerAuraSparks"

local currentGlow = 0
local currentEnergy = 1
local currentHunger = 0
local personalLight = nil
local atmosphereEffect = nil
local depthEffect = nil
local lowEnergyGui = nil
local lowEnergyVignette = nil
local lowEnergyLabel = nil
local recoveryGui = nil
local recoveryFadeFrame = nil
local recoveryLabel = nil
local recoveryToken = 0
local recoveryBeepSound = nil
local recoveryBeepCanStopAt = 0
local recoveryBeepBaseVolume = 0
local recoveryBeepMovingVolume = 0
local recoveryBeepVolumeTween = nil
local observedAuraByPlayer = {}
local observedAuraAccumulator = 1
local getRootPart
local getHumanoid

local colorEffect = Lighting:FindFirstChild(COLOR_EFFECT_NAME)
if not colorEffect then
	colorEffect = Instance.new("ColorCorrectionEffect")
	colorEffect.Name = COLOR_EFFECT_NAME
	colorEffect.Parent = Lighting
end

local bloomEffect = Lighting:FindFirstChild(BLOOM_EFFECT_NAME)
if not bloomEffect then
	bloomEffect = Instance.new("BloomEffect")
	bloomEffect.Name = BLOOM_EFFECT_NAME
	bloomEffect.Parent = Lighting
end

local function ensureAtmosphere()
	if atmosphereEffect and atmosphereEffect.Parent == Lighting then
		return atmosphereEffect
	end

	local existing = Lighting:FindFirstChild(ATMOSPHERE_EFFECT_NAME)
	if existing and existing:IsA("Atmosphere") then
		atmosphereEffect = existing
	else
		atmosphereEffect = Instance.new("Atmosphere")
		atmosphereEffect.Name = ATMOSPHERE_EFFECT_NAME
		atmosphereEffect.Parent = Lighting
	end

	return atmosphereEffect
end

local function ensureDepthEffect()
	if depthEffect and depthEffect.Parent == Lighting then
		return depthEffect
	end

	local existing = Lighting:FindFirstChild(DOF_EFFECT_NAME)
	if existing and existing:IsA("DepthOfFieldEffect") then
		depthEffect = existing
	else
		depthEffect = Instance.new("DepthOfFieldEffect")
		depthEffect.Name = DOF_EFFECT_NAME
		depthEffect.Parent = Lighting
	end

	return depthEffect
end

local function ensureLowEnergyGui()
	if lowEnergyGui and lowEnergyGui.Parent == playerGui then
		return
	end

	local existing = playerGui:FindFirstChild(LOW_ENERGY_GUI_NAME)
	if existing and existing:IsA("ScreenGui") then
		lowEnergyGui = existing
	else
		lowEnergyGui = Instance.new("ScreenGui")
		lowEnergyGui.Name = LOW_ENERGY_GUI_NAME
		lowEnergyGui.IgnoreGuiInset = true
		lowEnergyGui.ResetOnSpawn = false
		lowEnergyGui.DisplayOrder = 44
		lowEnergyGui.Parent = playerGui
	end

	lowEnergyVignette = lowEnergyGui:FindFirstChild("LowEnergyVignette")
	if not lowEnergyVignette then
		lowEnergyVignette = Instance.new("Frame")
		lowEnergyVignette.Name = "LowEnergyVignette"
		lowEnergyVignette.BackgroundColor3 = Color3.fromRGB(1, 2, 5)
		lowEnergyVignette.BorderSizePixel = 0
		lowEnergyVignette.Size = UDim2.fromScale(1, 1)
		lowEnergyVignette.Parent = lowEnergyGui
	end

	lowEnergyLabel = lowEnergyGui:FindFirstChild("LowEnergyLabel")
	if not lowEnergyLabel then
		lowEnergyLabel = Instance.new("TextLabel")
		lowEnergyLabel.Name = "LowEnergyLabel"
		lowEnergyLabel.AnchorPoint = Vector2.new(0.5, 1)
		lowEnergyLabel.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
		lowEnergyLabel.BackgroundTransparency = 0.18
		lowEnergyLabel.BorderSizePixel = 0
		lowEnergyLabel.Font = Enum.Font.GothamBlack
		lowEnergyLabel.Position = UDim2.new(0.5, 0, 1, -88)
		lowEnergyLabel.Size = UDim2.new(0.62, 0, 0, 36)
		lowEnergyLabel.Text = "ENERGY FIELD SHRINKING"
		lowEnergyLabel.TextColor3 = Color3.fromRGB(255, 132, 140)
		lowEnergyLabel.TextScaled = true
		lowEnergyLabel.TextWrapped = true
		lowEnergyLabel.Visible = false
		lowEnergyLabel.Parent = lowEnergyGui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = lowEnergyLabel
	end
end

local function ensureRecoveryGui()
	if recoveryGui and recoveryGui.Parent == playerGui then
		return
	end

	local existing = playerGui:FindFirstChild(RECOVERY_GUI_NAME)
	if existing and existing:IsA("ScreenGui") then
		recoveryGui = existing
	else
		recoveryGui = Instance.new("ScreenGui")
		recoveryGui.Name = RECOVERY_GUI_NAME
		recoveryGui.IgnoreGuiInset = true
		recoveryGui.ResetOnSpawn = false
		recoveryGui.DisplayOrder = 240
		recoveryGui.Parent = playerGui
	end

	recoveryFadeFrame = recoveryGui:FindFirstChild("RecoveryFadeFrame")
	if not recoveryFadeFrame then
		recoveryFadeFrame = Instance.new("Frame")
		recoveryFadeFrame.Name = "RecoveryFadeFrame"
		recoveryFadeFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		recoveryFadeFrame.BackgroundTransparency = 1
		recoveryFadeFrame.BorderSizePixel = 0
		recoveryFadeFrame.Size = UDim2.fromScale(1, 1)
		recoveryFadeFrame.Parent = recoveryGui
	end

	recoveryLabel = recoveryGui:FindFirstChild("RecoveryMessage")
	if not recoveryLabel then
		recoveryLabel = Instance.new("TextLabel")
		recoveryLabel.Name = "RecoveryMessage"
		recoveryLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		recoveryLabel.BackgroundTransparency = 1
		recoveryLabel.Font = Enum.Font.GothamBold
		recoveryLabel.Position = UDim2.fromScale(0.5, 0.58)
		recoveryLabel.Size = UDim2.fromScale(0.76, 0.12)
		recoveryLabel.Text = ""
		recoveryLabel.TextColor3 = Color3.fromRGB(224, 244, 255)
		recoveryLabel.TextScaled = true
		recoveryLabel.TextTransparency = 1
		recoveryLabel.TextWrapped = true
		recoveryLabel.Parent = recoveryGui
	end
end

local function normalizeSoundId(soundId)
	local text = tostring(soundId or "")
	if text == "" then
		return nil
	end
	if text:match("^rbxassetid://") then
		return text
	end
	if tonumber(text) then
		return "rbxassetid://" .. text
	end
	return text
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

local function isLocalPlayerInInfirmary()
	if not getRootPart then
		return false
	end

	local rootPart = getRootPart()
	local infirmary = Constants.GetRoom and Constants.GetRoom("Infirmary")
	return rootPart ~= nil and infirmary ~= nil and positionInZone(rootPart.Position, infirmary.Zone)
end

local function stopRecoveryBeep()
	if recoveryBeepVolumeTween then
		recoveryBeepVolumeTween:Cancel()
		recoveryBeepVolumeTween = nil
	end
	if recoveryBeepSound then
		recoveryBeepSound:Stop()
		recoveryBeepSound:Destroy()
		recoveryBeepSound = nil
	end
	recoveryBeepBaseVolume = 0
	recoveryBeepMovingVolume = 0
end

local function startRecoveryBeep(soundId, volume)
	local normalizedSoundId = normalizeSoundId(soundId)
	if not normalizedSoundId then
		return
	end

	stopRecoveryBeep()

	local sound = Instance.new("Sound")
	sound.Name = "DontTouchItRecoveryBeep"
	sound.SoundId = normalizedSoundId
	recoveryBeepBaseVolume = math.clamp(tonumber(volume) or 0.3, 0, 1)
	recoveryBeepMovingVolume = math.clamp(
		tonumber(Constants.BunkerEnergy and Constants.BunkerEnergy.RecoveryBeepMovingVolume) or recoveryBeepBaseVolume * 0.55,
		0,
		recoveryBeepBaseVolume
	)
	sound.Volume = recoveryBeepBaseVolume
	sound.Looped = true
	sound.Parent = SoundService
	recoveryBeepSound = sound
	recoveryBeepCanStopAt = os.clock() + 0.35
	sound:Play()
end

local function updateRecoveryBeepContainment()
	if not recoveryBeepSound or os.clock() < recoveryBeepCanStopAt then
		return
	end

	if not isLocalPlayerInInfirmary() then
		stopRecoveryBeep()
		return
	end

	local humanoid = getHumanoid and getHumanoid()
	local isMoving = humanoid and (humanoid.MoveDirection.Magnitude > 0.05 or humanoid.Jump)
	local targetVolume = if isMoving then recoveryBeepMovingVolume else recoveryBeepBaseVolume
	if math.abs(recoveryBeepSound.Volume - targetVolume) <= 0.01 then
		return
	end

	if recoveryBeepVolumeTween then
		recoveryBeepVolumeTween:Cancel()
	end
	recoveryBeepVolumeTween = TweenService:Create(
		recoveryBeepSound,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Volume = targetVolume }
	)
	recoveryBeepVolumeTween:Play()
	recoveryBeepVolumeTween.Completed:Connect(function()
		recoveryBeepVolumeTween = nil
	end)
end

local function playRecoverySequence(payload)
	if typeof(payload) ~= "table" then
		return
	end

	ensureRecoveryGui()
	if not recoveryFadeFrame or not recoveryLabel then
		return
	end

	stopRecoveryBeep()
	recoveryToken += 1
	local token = recoveryToken
	local fadeOut = math.max(0.2, tonumber(payload.FadeOutSeconds) or 2)
	local black = math.max(0.15, tonumber(payload.BlackSeconds) or 0.8)
	local fadeIn = math.max(0.2, tonumber(payload.FadeInSeconds) or 2)
	local message = tostring(payload.Message or "Condition stabilized.")

	recoveryFadeFrame.Visible = true
	recoveryFadeFrame.BackgroundTransparency = 1
	recoveryLabel.Text = ""
	recoveryLabel.TextTransparency = 1

	local outTween = TweenService:Create(
		recoveryFadeFrame,
		TweenInfo.new(fadeOut, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		{ BackgroundTransparency = 0 }
	)
	outTween:Play()
	outTween.Completed:Wait()
	if token ~= recoveryToken then
		return
	end

	startRecoveryBeep(
		payload.BeepSoundId or (Constants.BunkerEnergy and Constants.BunkerEnergy.RecoveryBeepSoundId),
		payload.BeepVolume or (Constants.BunkerEnergy and Constants.BunkerEnergy.RecoveryBeepVolume)
	)
	recoveryLabel.Text = message
	local labelIn = TweenService:Create(recoveryLabel, TweenInfo.new(0.35), { TextTransparency = 0.08 })
	labelIn:Play()
	task.wait(black)
	if token ~= recoveryToken then
		return
	end

	local labelOut = TweenService:Create(recoveryLabel, TweenInfo.new(0.45), { TextTransparency = 1 })
	local inTween = TweenService:Create(
		recoveryFadeFrame,
		TweenInfo.new(fadeIn, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		{ BackgroundTransparency = 1 }
	)
	labelOut:Play()
	inTween:Play()
	inTween.Completed:Wait()
	if token == recoveryToken then
		recoveryFadeFrame.Visible = false
		recoveryLabel.Text = ""
	end
end

local function getNumericAttribute(attributeName, fallback)
	local value = playerGui:GetAttribute(attributeName)
	if value == nil then
		value = player:GetAttribute(attributeName)
	end

	return tonumber(value) or fallback or 0
end

local function getTargetGlow()
	if playerGui:GetAttribute("DontTouchItPrologueActive") == true then
		return 0
	end

	local explicitGlow = getNumericAttribute("DontTouchItBunkerPersonalGlow", nil)
	if explicitGlow ~= nil then
		return math.clamp(explicitGlow, 0, 1)
	end

	local worldPower = getNumericAttribute("DontTouchItBunkerPower", 0)
	local personalPower = getNumericAttribute("DontTouchItBunkerPersonalPower", worldPower)
	return math.clamp((personalPower - worldPower) / math.max(0.05, 1 - worldPower), 0, 1)
end

local function getReplicatedPlayerGlow(targetPlayer)
	local glow = tonumber(targetPlayer:GetAttribute("DontTouchItBunkerPersonalGlow"))
	if glow then
		return math.clamp(glow, 0, 1)
	end

	local worldPower = tonumber(targetPlayer:GetAttribute("DontTouchItBunkerPower")) or 0
	local personalPower = tonumber(targetPlayer:GetAttribute("DontTouchItBunkerPersonalPower")) or worldPower
	return math.clamp((personalPower - worldPower) / math.max(0.05, 1 - worldPower), 0, 1)
end

getRootPart = function()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

getHumanoid = function()
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function getPlayerEnergy()
	return math.clamp(getNumericAttribute("DontTouchItPlayerEnergy", 1), 0, 1)
end

local function getBunkerHunger()
	return math.clamp(getNumericAttribute("DontTouchItBunkerHunger", 0), 0, 1)
end

local function ensurePersonalLight()
	local rootPart = getRootPart()
	if not rootPart then
		return nil
	end

	if personalLight and personalLight.Parent == rootPart then
		return personalLight
	end

	if personalLight then
		personalLight:Destroy()
	end

	local existing = rootPart:FindFirstChild(PERSONAL_LIGHT_NAME)
	if existing and existing:IsA("PointLight") then
		personalLight = existing
	else
		personalLight = Instance.new("PointLight")
		personalLight.Name = PERSONAL_LIGHT_NAME
		personalLight.Shadows = false
		personalLight.Parent = rootPart
	end

	return personalLight
end

local function applyGlow(glow, energy, hunger)
	local activeGlow = if glow > 0.015 then glow else 0
	local prologueActive = playerGui:GetAttribute("DontTouchItPrologueActive") == true
	local lowEnergy = math.clamp(1 - (energy or 1), 0, 1)
	local energyPressure = math.clamp((lowEnergy ^ 1.35) * (0.72 + (hunger or 0) * 0.55), 0, 1)

	colorEffect.Enabled = activeGlow > 0 or energyPressure > 0.025
	colorEffect.Brightness = (0.015 + activeGlow * 0.075) - energyPressure * 0.2
	colorEffect.Contrast = activeGlow * 0.035 + energyPressure * 0.34
	colorEffect.Saturation = activeGlow * 0.105 - energyPressure * 0.5
	colorEffect.TintColor = Color3.fromRGB(255, 255, 255)
		:Lerp(Color3.fromRGB(255, 244, 209), activeGlow * 0.34)
		:Lerp(Color3.fromRGB(91, 105, 132), energyPressure * 0.55)

	bloomEffect.Enabled = activeGlow > 0
	bloomEffect.Intensity = activeGlow * 0.24
	bloomEffect.Size = 14 + activeGlow * 12
	bloomEffect.Threshold = 1.15 - activeGlow * 0.25

	local atmosphere = ensureAtmosphere()
	if atmosphere then
		local atmosphereActive = not prologueActive and energyPressure > 0.035
		atmosphere.Density = if atmosphereActive then 0.18 + energyPressure * 0.62 else 0
		atmosphere.Offset = -0.18 - energyPressure * 0.28
		atmosphere.Color = Color3.fromRGB(90, 101, 118):Lerp(Color3.fromRGB(22, 28, 42), energyPressure)
		atmosphere.Decay = Color3.fromRGB(9, 11, 18)
		atmosphere.Glare = 0.03 + activeGlow * 0.06
		atmosphere.Haze = if atmosphereActive then 0.8 + energyPressure * 2.8 else 0
	end

	local depth = ensureDepthEffect()
	if depth then
		depth.Enabled = not prologueActive and energyPressure > 0.16
		depth.FarIntensity = energyPressure * 0.38
		depth.FocusDistance = 24 + energy * 42
		depth.InFocusRadius = 18 + energy * 34
		depth.NearIntensity = 0
	end

	ensureLowEnergyGui()
	if lowEnergyVignette then
		lowEnergyVignette.BackgroundTransparency = 1 - math.clamp(energyPressure * 0.3, 0, 0.3)
		lowEnergyVignette.Visible = not prologueActive and energyPressure > 0.08
	end
		if lowEnergyLabel then
			lowEnergyLabel.Visible = not prologueActive and energy <= 0.3
			lowEnergyLabel.Text = if hunger >= 0.62
				then "ENERGY FIELD SHRINKING - SIGNAL IRREGULAR"
				else "ENERGY FIELD SHRINKING"
			lowEnergyLabel.TextTransparency = math.clamp(energy * 1.6, 0, 0.45)
		end

	local light = ensurePersonalLight()
	if light then
		local fieldStrength = math.clamp(0.16 + activeGlow * 0.84 + (energy or 1) * 0.38, 0, 1)
		local strain = math.clamp(energyPressure, 0, 1)
		light.Enabled = activeGlow > 0 or strain > 0.035
		light.Color = Color3.fromRGB(255, 229, 169):Lerp(Color3.fromRGB(180, 246, 255), activeGlow * 0.2)
		light.Brightness = 0.16 + activeGlow * 1.35 + strain * 0.58
		light.Range = 7 + fieldStrength * 22 - strain * 8
	end
end

local function getObservedAura(targetPlayer)
	if targetPlayer == player then
		return nil
	end

	local character = targetPlayer.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not rootPart then
		return nil
	end

	local aura = observedAuraByPlayer[targetPlayer]
	if aura and aura.Character == character and aura.RootPart == rootPart then
		return aura
	end

	if aura then
		for _, instance in ipairs(aura.Instances or {}) do
			if instance then
				instance:Destroy()
			end
		end
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = OBSERVED_HIGHLIGHT_NAME
	highlight.Adornee = character
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.FillColor = Color3.fromRGB(255, 223, 136)
	highlight.OutlineColor = Color3.fromRGB(104, 241, 255)
	highlight.Parent = character

	local attachment = rootPart:FindFirstChild(OBSERVED_ATTACHMENT_NAME)
	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Name = OBSERVED_ATTACHMENT_NAME
		attachment.Parent = rootPart
	end

	local light = Instance.new("PointLight")
	light.Name = OBSERVED_LIGHT_NAME
	light.Color = Color3.fromRGB(255, 229, 159)
	light.Shadows = false
	light.Parent = rootPart

	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = OBSERVED_SPARKS_NAME
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Color = ColorSequence.new(Color3.fromRGB(255, 226, 128), Color3.fromRGB(130, 243, 255))
	sparks.LightEmission = 0.65
	sparks.Lifetime = NumberRange.new(0.55, 1.15)
	sparks.Rotation = NumberRange.new(-180, 180)
	sparks.RotSpeed = NumberRange.new(-40, 40)
	sparks.Speed = NumberRange.new(0.35, 1.1)
	sparks.SpreadAngle = Vector2.new(45, 45)
	sparks.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.5, 0.18),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparks.Parent = attachment

	aura = {
		Character = character,
		RootPart = rootPart,
		Highlight = highlight,
		Attachment = attachment,
		Light = light,
		Sparks = sparks,
		Instances = { highlight, attachment, light },
	}
	observedAuraByPlayer[targetPlayer] = aura

	return aura
end

local function setObservedAuraVisible(aura, visible)
	if aura.Highlight then
		aura.Highlight.Enabled = visible
	end
	if aura.Light then
		aura.Light.Enabled = visible
	end
	if aura.Sparks then
		aura.Sparks.Enabled = visible
	end
end

local function updateObservedAuras()
	local localPrologue = playerGui:GetAttribute("DontTouchItPrologueActive") == true

	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		if targetPlayer ~= player then
			local glow = if localPrologue then 0 else getReplicatedPlayerGlow(targetPlayer)
			local aura = getObservedAura(targetPlayer)
			if aura then
				local visible = glow > 0.18
				setObservedAuraVisible(aura, visible)

				if visible then
					local auraStrength = math.clamp((glow - 0.18) / 0.82, 0, 1)
					aura.Highlight.FillTransparency = 0.94 - auraStrength * 0.16
					aura.Highlight.OutlineTransparency = 0.72 - auraStrength * 0.28
					aura.Light.Brightness = auraStrength * 0.85
					aura.Light.Range = 7 + auraStrength * 13
					aura.Sparks.Rate = 2 + auraStrength * 12
				end
			end
		end
	end
end

Players.PlayerRemoving:Connect(function(leavingPlayer)
	local aura = observedAuraByPlayer[leavingPlayer]
	if not aura then
		return
	end

	for _, instance in ipairs(aura.Instances or {}) do
		if instance then
			instance:Destroy()
		end
	end
	observedAuraByPlayer[leavingPlayer] = nil
end)

player.CharacterAdded:Connect(function()
	stopRecoveryBeep()
	if personalLight then
		personalLight:Destroy()
		personalLight = nil
	end
	ensureRecoveryGui()
	if recoveryFadeFrame then
		recoveryToken += 1
		recoveryFadeFrame.BackgroundTransparency = 1
		recoveryFadeFrame.Visible = false
	end
	if recoveryLabel then
		recoveryLabel.Text = ""
		recoveryLabel.TextTransparency = 1
	end
end)

recoveryRemote.OnClientEvent:Connect(function(payload)
	if typeof(payload) == "table" and payload.Action == "PassOut" then
		task.spawn(playRecoverySequence, payload)
	end
end)

RunService.RenderStepped:Connect(function(deltaTime)
	local targetGlow = getTargetGlow()
	local targetEnergy = getPlayerEnergy()
	local targetHunger = getBunkerHunger()
	local smoothing = 1 - math.exp(-math.max(0.001, deltaTime) * 3.4)
	currentGlow += (targetGlow - currentGlow) * smoothing
	currentEnergy += (targetEnergy - currentEnergy) * smoothing
	currentHunger += (targetHunger - currentHunger) * smoothing
	applyGlow(currentGlow, currentEnergy, currentHunger)
	updateRecoveryBeepContainment()

	observedAuraAccumulator += deltaTime
	if observedAuraAccumulator >= 0.2 then
		observedAuraAccumulator = 0
		updateObservedAuras()
	end
end)
