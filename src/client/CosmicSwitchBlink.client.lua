local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local bowlingAudio = Constants.AudioAssets and Constants.AudioAssets.Bowling
local COSMIC_ACTIVE_ATTRIBUTE = (bowlingAudio and bowlingAudio.CosmicActiveAttribute) or "DontTouchItBowlingCosmicActive"
local SWITCH_TAG = Constants.Tags.BowlingCosmicSwitch

local animatedSwitches = {}

local function tween(instance, duration, properties)
	if not instance or not instance.Parent then
		return nil
	end

	local effect = TweenService:Create(
		instance,
		TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		properties
	)
	effect:Play()
	return effect
end

local function animateSwitch(instance)
	if animatedSwitches[instance] or not instance:IsA("BasePart") or instance:GetAttribute("CosmicAttentionBlink") ~= true then
		return
	end

	animatedSwitches[instance] = true
	local baseColor = instance.Color
	local light = instance:FindFirstChild("CosmicSwitchBlinkLight")

	task.spawn(function()
		while instance.Parent do
			local cosmicActive = workspace:GetAttribute(COSMIC_ACTIVE_ATTRIBUTE) == true
			local highBrightness = if cosmicActive then 0.9 else 2.5
			local lowBrightness = if cosmicActive then 0.25 else 0.45
			local highColor = if cosmicActive then Color3.fromRGB(150, 112, 255) else Color3.fromRGB(119, 255, 203)

			tween(instance, 0.42, { Color = highColor })
			if light and light.Parent then
				tween(light, 0.42, { Brightness = highBrightness })
			end
			task.wait(0.46)

			tween(instance, 0.52, { Color = baseColor })
			if light and light.Parent then
				tween(light, 0.52, { Brightness = lowBrightness })
			end
			task.wait(0.58)
		end

		animatedSwitches[instance] = nil
	end)
end

for _, instance in ipairs(CollectionService:GetTagged(SWITCH_TAG)) do
	animateSwitch(instance)
end

CollectionService:GetInstanceAddedSignal(SWITCH_TAG):Connect(animateSwitch)
