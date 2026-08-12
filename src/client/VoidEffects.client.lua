local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local voidEffectRemote = remotes:WaitForChild(Constants.Remotes.VoidEffect)

local REVERSE_BIND_NAME = "DontTouchItVoidReverseControls"
local reverseToken = nil

local function getHumanoid()
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

local function stopReverseControls(token)
	if token and reverseToken ~= token then
		return
	end

	reverseToken = nil
	RunService:UnbindFromRenderStep(REVERSE_BIND_NAME)
end

local function startReverseControls(duration)
	local token = {}
	reverseToken = token
	RunService:UnbindFromRenderStep(REVERSE_BIND_NAME)

	RunService:BindToRenderStep(REVERSE_BIND_NAME, Enum.RenderPriority.Character.Value + 1, function()
		if reverseToken ~= token then
			stopReverseControls(token)
			return
		end

		local humanoid = getHumanoid()
		if not humanoid or humanoid.Health <= 0 then
			return
		end

		local moveDirection = humanoid.MoveDirection
		if moveDirection.Magnitude > 0.01 then
			humanoid:Move(-moveDirection, false)
		end
	end)

	task.delay(duration or 12, function()
		stopReverseControls(token)
	end)
end

voidEffectRemote.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end

	if payload.Action == "ReverseControls" then
		startReverseControls(payload.Duration or 12)
	end
end)

player.CharacterAdded:Connect(function()
	stopReverseControls()
end)
