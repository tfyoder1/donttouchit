local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local BOOST_KEY = Enum.KeyCode.ButtonL3
local BOOST_MULTIPLIER = 1.55
local BOOST_MIN_SPEED = 24

local boosting = false
local boostHumanoid = nil
local baseWalkSpeed = nil

local function getHumanoid()
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

local function stopBoost()
	if not boosting then
		return
	end

	if boostHumanoid and boostHumanoid.Parent and baseWalkSpeed then
		boostHumanoid.WalkSpeed = baseWalkSpeed
	end

	boosting = false
	boostHumanoid = nil
	baseWalkSpeed = nil
end

local function startBoost()
	if boosting then
		return
	end

	local humanoid = getHumanoid()
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	boosting = true
	boostHumanoid = humanoid
	baseWalkSpeed = humanoid.WalkSpeed
	humanoid.WalkSpeed = math.max(BOOST_MIN_SPEED, baseWalkSpeed * BOOST_MULTIPLIER)
end

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode ~= BOOST_KEY then
		return
	end

	startBoost()
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode ~= BOOST_KEY then
		return
	end

	stopBoost()
end)

player.CharacterAdded:Connect(function()
	stopBoost()
end)
