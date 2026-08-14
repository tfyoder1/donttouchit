local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local movementRemote = remotes:WaitForChild(Constants.Remotes.MovementAuthority)

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

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

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
