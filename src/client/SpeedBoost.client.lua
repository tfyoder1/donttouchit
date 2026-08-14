local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local movementRemote = remotes:WaitForChild(Constants.Remotes.MovementAuthority)

local BOOST_ACTION = "DontTouchItSpeedBoost"
local BOOST_KEY = Enum.KeyCode.ButtonL3

local boosting = false

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

	boosting = true
	requestBoost(true)
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
end, true, BOOST_KEY)

pcall(function()
	ContextActionService:SetTitle(BOOST_ACTION, "Run")
	ContextActionService:SetPosition(BOOST_ACTION, UDim2.fromScale(0.86, 0.42))
end)

player.CharacterAdded:Connect(function()
	stopBoost()
end)
