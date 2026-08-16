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
local DOUBLE_TAP_RUN_SECONDS = 0.32

local boosting = false
local runToggleActive = false
local lastTouchRunTapAt = 0
local runControl = nil

local function isSnackFlightActive()
	return playerGui:GetAttribute(FLIGHT_ACTIVE_ATTRIBUTE) == true
end

local function requestBoost(active)
	movementRemote:FireServer({
		Action = "SpeedBoost",
		Active = active == true,
	})
end

local function updateRunBadge()
	if runControl and runControl.SetBadgeText then
		runControl:SetBadgeText(if runToggleActive then "W" else nil)
	end
end

local function stopBoost(clearToggle)
	if clearToggle then
		runToggleActive = false
		updateRunBadge()
	end
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

local function beginTouchRun()
	if isSnackFlightActive() then
		runToggleActive = false
		updateRunBadge()
		return
	end

	local now = os.clock()
	if now - lastTouchRunTapAt <= DOUBLE_TAP_RUN_SECONDS then
		runToggleActive = not runToggleActive
		lastTouchRunTapAt = 0
		updateRunBadge()
		if runToggleActive then
			startBoost()
		else
			stopBoost(false)
		end
		return
	end

	lastTouchRunTapAt = now
	startBoost()
end

local function endTouchRun()
	if runToggleActive then
		return
	end
	stopBoost(false)
end

local function setupTouchRunButton()
	runControl = TouchControls.RegisterAction({
		Id = "Run",
		Label = "Run",
		Text = "Run",
		Order = 10,
		Desktop = "Left Shift / Right Shift",
		Xbox = "L3",
		Touch = "Run button",
		Position = UDim2.new(0, 111, 0, 260),
		TextColor = Color3.fromRGB(216, 255, 234),
		StrokeColor = Color3.fromRGB(114, 255, 199),
		OnBegan = beginTouchRun,
		OnEnded = endTouchRun,
	})
	updateRunBadge()
end

ContextActionService:UnbindAction(BOOST_ACTION)
ContextActionService:BindAction(BOOST_ACTION, function(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		runToggleActive = false
		updateRunBadge()
		startBoost()
		return Enum.ContextActionResult.Sink
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		stopBoost(false)
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
	stopBoost(true)
end)

playerGui:GetAttributeChangedSignal(FLIGHT_ACTIVE_ATTRIBUTE):Connect(function()
	if isSnackFlightActive() then
		stopBoost(true)
	end
end)
