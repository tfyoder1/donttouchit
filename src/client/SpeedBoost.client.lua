local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local TouchControls = require(script.Parent:WaitForChild("TouchControls"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local movementRemote = remotes:WaitForChild(Constants.Remotes.MovementAuthority)

local BOOST_ACTION = "DontTouchItSpeedBoost"
local BOOST_KEY = Enum.KeyCode.ButtonL3
local BOOST_LEFT_SHIFT_KEY = Enum.KeyCode.LeftShift
local BOOST_RIGHT_SHIFT_KEY = Enum.KeyCode.RightShift
local FLIGHT_ACTIVE_ATTRIBUTE = "DontTouchItSnackFlightActive"

local boosting = false

local function isSnackFlightActive()
	return playerGui:GetAttribute(FLIGHT_ACTIVE_ATTRIBUTE) == true
end

local function requestBoost(active)
	movementRemote:FireServer({
		Action = "SpeedBoost",
		Active = active == true,
	})
end

local function stopBoost()
	if not boosting then
		return
	end

	boosting = false
	requestBoost(false)
end

local function startBoost()
	if boosting then
		return
	end
	if isSnackFlightActive() then
		return
	end

	boosting = true
	requestBoost(true)
end

local function setupTouchRunButton()
	TouchControls.RegisterAction({
		Id = "Run",
		Label = "Run",
		Text = "Run",
		Order = 10,
		Desktop = "Left Shift / Right Shift",
		Xbox = "L3",
		Touch = "Run button",
		Position = UDim2.new(1, -92, 1, -176),
		TextColor = Color3.fromRGB(216, 255, 234),
		StrokeColor = Color3.fromRGB(114, 255, 199),
		OnBegan = startBoost,
		OnEnded = stopBoost,
	})
end

ContextActionService:UnbindAction(BOOST_ACTION)
ContextActionService:BindAction(BOOST_ACTION, function(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		startBoost()
		return Enum.ContextActionResult.Sink
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		stopBoost()
		return Enum.ContextActionResult.Sink
	end

	return Enum.ContextActionResult.Sink
end, false, BOOST_KEY, BOOST_LEFT_SHIFT_KEY, BOOST_RIGHT_SHIFT_KEY)

pcall(function()
	ContextActionService:SetTitle(BOOST_ACTION, "Run")
	ContextActionService:SetPosition(BOOST_ACTION, UDim2.fromScale(0.86, 0.42))
end)

setupTouchRunButton()

player.CharacterAdded:Connect(function()
	stopBoost()
end)

playerGui:GetAttributeChangedSignal(FLIGHT_ACTIVE_ATTRIBUTE):Connect(function()
	if isSnackFlightActive() then
		stopBoost()
	end
end)
