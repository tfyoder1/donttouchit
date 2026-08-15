local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local TouchControls = require(script.Parent:WaitForChild("TouchControls"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local movementRemote = remotes:WaitForChild(Constants.Remotes.MovementAuthority)

local FLIGHT_ACTIVE_ATTRIBUTE = "DontTouchItSnackFlightActive"
local SLIDE_MIN_WALK_SPEED = 21
local SLIDE_MIN_HORIZONTAL_SPEED = 18
local CROUCH_KEYS = {
	[Enum.KeyCode.ButtonB] = true,
	[Enum.KeyCode.C] = true,
}

local crouching = false

local function requestCrouch(active)
	movementRemote:FireServer({
		Action = "Crouch",
		Active = active == true,
	})
end

local function requestSlide()
	movementRemote:FireServer({
		Action = "Slide",
	})
end

local function getHumanoid()
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function getRootPart()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function isRoomLogOpen()
	local gui = playerGui:FindFirstChild("DontTouchItUI")
	local referenceBook = gui and gui:FindFirstChild("ReferenceBook")
	return referenceBook and referenceBook.Visible == true
end

local function shouldSlide()
	if isRoomLogOpen() or playerGui:GetAttribute(FLIGHT_ACTIVE_ATTRIBUTE) == true then
		return false
	end

	local humanoid = getHumanoid()
	if not humanoid or humanoid.Health <= 0 or humanoid.MoveDirection.Magnitude < 0.25 then
		return false
	end

	local rootPart = getRootPart()
	local velocity = rootPart and rootPart.AssemblyLinearVelocity or Vector3.zero
	local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	return humanoid.WalkSpeed >= SLIDE_MIN_WALK_SPEED or horizontalSpeed >= SLIDE_MIN_HORIZONTAL_SPEED
end

local function restoreCrouch()
	if not crouching then
		return
	end

	crouching = false
	requestCrouch(false)
end

local function beginCrouch()
	if crouching or isRoomLogOpen() or playerGui:GetAttribute(FLIGHT_ACTIVE_ATTRIBUTE) == true then
		return
	end

	crouching = true
	requestCrouch(true)
end

local function beginCrouchOrSlide()
	if shouldSlide() then
		requestSlide()
		return
	end

	beginCrouch()
end

local function setupTouchCrouchButton()
	TouchControls.RegisterAction({
		Id = "CrouchSlide",
		Label = "Crouch / Slide",
		Text = "Crouch",
		Order = 20,
		Desktop = "C",
		Xbox = "B",
		Touch = "Crouch button",
		Position = UDim2.new(1, -92, 1, -230),
		TextColor = Color3.fromRGB(231, 224, 255),
		StrokeColor = Color3.fromRGB(173, 145, 255),
		OnBegan = beginCrouchOrSlide,
		OnEnded = restoreCrouch,
	})
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not CROUCH_KEYS[input.KeyCode] or gameProcessed then
		return
	end

	beginCrouchOrSlide()
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

setupTouchCrouchButton()

playerGui:GetAttributeChangedSignal(FLIGHT_ACTIVE_ATTRIBUTE):Connect(function()
	if playerGui:GetAttribute(FLIGHT_ACTIVE_ATTRIBUTE) == true then
		restoreCrouch()
	end
end)
