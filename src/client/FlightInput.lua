local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local FlightInput = {}

local controls = nil

local MOVE_VECTOR_DEADZONE = 0.05

local function getControls()
	if controls then
		return controls
	end

	local playerScripts = player:FindFirstChild("PlayerScripts")
	if not playerScripts then
		return nil
	end

	local playerModule = playerScripts:FindFirstChild("PlayerModule")
	if not playerModule then
		return nil
	end

	local ok, module = pcall(require, playerModule)
	if not ok or typeof(module) ~= "table" or typeof(module.GetControls) ~= "function" then
		return nil
	end

	local controlsOk, resolvedControls = pcall(function()
		return module:GetControls()
	end)
	if not controlsOk or typeof(resolvedControls) ~= "table" or typeof(resolvedControls.GetMoveVector) ~= "function" then
		return nil
	end

	controls = resolvedControls
	return controls
end

local function flattenUnit(vector, fallback)
	local flat = Vector3.new(vector.X, 0, vector.Z)
	if flat.Magnitude > 0.001 then
		return flat.Unit
	end

	return fallback
end

function FlightInput.GetMoveVector()
	local resolvedControls = getControls()
	if not resolvedControls then
		return Vector3.zero
	end

	local ok, moveVector = pcall(function()
		return resolvedControls:GetMoveVector()
	end)
	if not ok or typeof(moveVector) ~= "Vector3" then
		return Vector3.zero
	end

	if math.abs(moveVector.X) < MOVE_VECTOR_DEADZONE then
		moveVector = Vector3.new(0, moveVector.Y, moveVector.Z)
	end
	if math.abs(moveVector.Z) < MOVE_VECTOR_DEADZONE then
		moveVector = Vector3.new(moveVector.X, moveVector.Y, 0)
	end

	return moveVector
end

function FlightInput.GetCameraRelativeMoveDirection(includeVerticalLook)
	local moveVector = FlightInput.GetMoveVector()
	if math.abs(moveVector.X) < MOVE_VECTOR_DEADZONE and math.abs(moveVector.Z) < MOVE_VECTOR_DEADZONE then
		return Vector3.zero
	end

	local camera = Workspace.CurrentCamera
	local cameraCFrame = camera and camera.CFrame or CFrame.new()
	local right = cameraCFrame.RightVector
	local look = cameraCFrame.LookVector

	if not includeVerticalLook then
		right = flattenUnit(right, Vector3.xAxis)
		look = flattenUnit(look, -Vector3.zAxis)
	end

	local direction = right * moveVector.X + look * -moveVector.Z
	if direction.Magnitude > 1 then
		direction = direction.Unit
	end

	return direction
end

return FlightInput
