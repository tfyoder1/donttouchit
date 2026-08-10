local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local snackEffectRemote = remotes:WaitForChild(Constants.Remotes.SnackEffect)

local activeFlight = nil

local function getCharacterParts()
	local character = player.Character
	if not character then
		return nil, nil
	end

	return character:FindFirstChild("HumanoidRootPart"), character:FindFirstChildOfClass("Humanoid")
end

local function stopFlight()
	if not activeFlight then
		return
	end

	if activeFlight.Connection then
		activeFlight.Connection:Disconnect()
	end

	if activeFlight.LinearVelocity then
		activeFlight.LinearVelocity:Destroy()
	end

	if activeFlight.Attachment then
		activeFlight.Attachment:Destroy()
	end

	if activeFlight.Humanoid and activeFlight.Humanoid.Parent then
		activeFlight.Humanoid.AutoRotate = activeFlight.AutoRotate
	end

	activeFlight = nil
end

local function startFlight(duration)
	stopFlight()

	local rootPart, humanoid = getCharacterParts()
	if not rootPart or not humanoid then
		return
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = "SnackFlightAttachment"
	attachment.Parent = rootPart

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "SnackFlightVelocity"
	linearVelocity.Attachment0 = attachment
	linearVelocity.MaxForce = 85000
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.VectorVelocity = Vector3.new(0, 12, 0)
	linearVelocity.Parent = rootPart

	local token = {}
	activeFlight = {
		Token = token,
		Attachment = attachment,
		LinearVelocity = linearVelocity,
		Humanoid = humanoid,
		AutoRotate = humanoid.AutoRotate,
		Connection = nil,
	}

	humanoid.AutoRotate = true
	humanoid:ChangeState(Enum.HumanoidStateType.Freefall)

	activeFlight.Connection = RunService.RenderStepped:Connect(function()
		if not activeFlight or activeFlight.Token ~= token then
			return
		end

		local currentRootPart, currentHumanoid = getCharacterParts()
		if currentRootPart ~= rootPart or currentHumanoid ~= humanoid or not rootPart.Parent then
			stopFlight()
			return
		end

		local vertical = 7
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			vertical = 30
		elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
			or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
			or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
			or UserInputService:IsKeyDown(Enum.KeyCode.C)
		then
			vertical = -24
		end

		linearVelocity.VectorVelocity = humanoid.MoveDirection * 42 + Vector3.new(0, vertical, 0)
	end)

	task.delay(duration or 12, function()
		if activeFlight and activeFlight.Token == token then
			stopFlight()
		end
	end)
end

snackEffectRemote.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end

	if payload.Action == "Flight" then
		startFlight(payload.Duration or 12)
	end
end)

player.CharacterRemoving:Connect(stopFlight)
