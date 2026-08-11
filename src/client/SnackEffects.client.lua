local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local snackEffectRemote = remotes:WaitForChild(Constants.Remotes.SnackEffect)

local activeFlight = nil

local SNACK_FLIGHT_HORIZONTAL_SPEED = 38
local SNACK_FLIGHT_IDLE_VERTICAL = 3
local SNACK_FLIGHT_UP_VERTICAL = 16
local SNACK_FLIGHT_DOWN_VERTICAL = -22
local SNACK_FLIGHT_DEFAULT_CEILING_Y = Constants.Rooms.SnackLab.Zone.Max.Y - 5.2

local function getCharacterParts()
	local character = player.Character
	if not character then
		return nil, nil
	end

	return character:FindFirstChild("HumanoidRootPart"), character:FindFirstChildOfClass("Humanoid")
end

local function isAnyGamepadButtonDown(keyCode)
	local gamepads = UserInputService:GetConnectedGamepads()
	if #gamepads == 0 and UserInputService.GamepadEnabled then
		gamepads = { Enum.UserInputType.Gamepad1 }
	end

	for _, gamepad in ipairs(gamepads) do
		if UserInputService:IsGamepadButtonDown(gamepad, keyCode) then
			return true
		end
	end

	return false
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

local function startFlight(duration, ceilingY)
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
	linearVelocity.VectorVelocity = Vector3.new(0, SNACK_FLIGHT_IDLE_VERTICAL, 0)
	linearVelocity.Parent = rootPart

	local token = {}
	activeFlight = {
		Token = token,
		Attachment = attachment,
		LinearVelocity = linearVelocity,
		Humanoid = humanoid,
		AutoRotate = humanoid.AutoRotate,
		CeilingY = ceilingY or SNACK_FLIGHT_DEFAULT_CEILING_Y,
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

		local vertical = SNACK_FLIGHT_IDLE_VERTICAL
		if UserInputService:IsKeyDown(Enum.KeyCode.Space)
			or isAnyGamepadButtonDown(Enum.KeyCode.ButtonA)
		then
			vertical = SNACK_FLIGHT_UP_VERTICAL
		elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
			or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
			or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
			or UserInputService:IsKeyDown(Enum.KeyCode.C)
			or isAnyGamepadButtonDown(Enum.KeyCode.ButtonB)
			or isAnyGamepadButtonDown(Enum.KeyCode.ButtonX)
		then
			vertical = SNACK_FLIGHT_DOWN_VERTICAL
		end

		local ceiling = activeFlight.CeilingY or SNACK_FLIGHT_DEFAULT_CEILING_Y
		if rootPart.Position.Y >= ceiling and vertical > -6 then
			vertical = -6
		elseif rootPart.Position.Y >= ceiling - 1.2 and vertical > SNACK_FLIGHT_IDLE_VERTICAL then
			vertical = SNACK_FLIGHT_IDLE_VERTICAL
		end

		linearVelocity.VectorVelocity = humanoid.MoveDirection * SNACK_FLIGHT_HORIZONTAL_SPEED + Vector3.new(0, vertical, 0)
	end)

	task.delay(duration or 60, function()
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
		startFlight(payload.Duration or 60, payload.CeilingY)
	elseif payload.Action == "StopFlight" then
		stopFlight()
	end
end)

player.CharacterRemoving:Connect(stopFlight)
