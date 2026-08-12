local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CROUCH_ATTRIBUTE = "DontTouchItCrouching"
local FLIGHT_ACTIVE_ATTRIBUTE = "DontTouchItSnackFlightActive"
local CROUCH_KEYS = {
	[Enum.KeyCode.ButtonB] = true,
	[Enum.KeyCode.C] = true,
}

local crouching = false
local crouchHumanoid = nil
local baseWalkSpeed = nil
local baseHipHeight = nil
local baseCameraOffset = nil

local function getHumanoid()
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

local function isRoomLogOpen()
	local gui = playerGui:FindFirstChild("DontTouchItUI")
	local referenceBook = gui and gui:FindFirstChild("ReferenceBook")
	return referenceBook and referenceBook.Visible == true
end

local function restoreCrouch()
	if not crouching then
		return
	end

	local humanoid = crouchHumanoid
	if humanoid and humanoid.Parent then
		humanoid.WalkSpeed = baseWalkSpeed or humanoid.WalkSpeed
		humanoid.HipHeight = baseHipHeight or humanoid.HipHeight
		humanoid.CameraOffset = baseCameraOffset or Vector3.zero
		humanoid:SetAttribute(CROUCH_ATTRIBUTE, false)
	end

	crouching = false
	crouchHumanoid = nil
	baseWalkSpeed = nil
	baseHipHeight = nil
	baseCameraOffset = nil
end

local function beginCrouch()
	if crouching or isRoomLogOpen() or playerGui:GetAttribute(FLIGHT_ACTIVE_ATTRIBUTE) == true then
		return
	end

	local humanoid = getHumanoid()
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	crouching = true
	crouchHumanoid = humanoid
	baseWalkSpeed = humanoid.WalkSpeed
	baseHipHeight = humanoid.HipHeight
	baseCameraOffset = humanoid.CameraOffset

	humanoid:SetAttribute(CROUCH_ATTRIBUTE, true)
	humanoid.WalkSpeed = math.max(6, baseWalkSpeed * 0.58)
	humanoid.HipHeight = math.max(0.45, baseHipHeight - 1.05)
	humanoid.CameraOffset = baseCameraOffset + Vector3.new(0, -1.05, 0)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not CROUCH_KEYS[input.KeyCode] or gameProcessed then
		return
	end

	beginCrouch()
end)

UserInputService.InputEnded:Connect(function(input)
	if not CROUCH_KEYS[input.KeyCode] then
		return
	end

	restoreCrouch()
end)

player.CharacterAdded:Connect(function()
	restoreCrouch()
end)

playerGui:GetAttributeChangedSignal(FLIGHT_ACTIVE_ATTRIBUTE):Connect(function()
	if playerGui:GetAttribute(FLIGHT_ACTIVE_ATTRIBUTE) == true then
		restoreCrouch()
	end
end)
