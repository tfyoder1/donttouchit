local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local roomStatusRemote = remotes:WaitForChild(Constants.Remotes.RoomStatus)
local topDownRemote = remotes:WaitForChild(Constants.Remotes.TopDownArena)

local RENDER_STEP_NAME = "DontTouchItTopDownArenaCamera"
local THROW_ACTION = "DontTouchItTopDownThrow"
local AIM_ACTION = "DontTouchItTopDownAim"
local JUMP_AIM_ACTION = "DontTouchItTopDownJumpAim"
local AIM_MARKER_NAME = "DontTouchItTopDownAimMarker"
local MIN_HEIGHT = 54
local MAX_HEIGHT = 92
local DEFAULT_HEIGHT = 72
local DEFAULT_BACK_OFFSET = 34
local YAW_SPEED = 2.45
local PITCH_SPEED = 2.15
local MIN_FPV_PITCH = math.rad(-58)
local MAX_FPV_PITCH = math.rad(42)
local AIM_DISTANCE = 58
local OVERHEAD_AIM_MIN_DISTANCE = 10
local OVERHEAD_AIM_DEFAULT_DISTANCE = 34
local AIM_STICK_DEADZONE = 0.12
local TOUCH_AIM_BUTTON_SIZE = UDim2.fromOffset(78, 78)
local TOUCH_AIM_BUTTON_POSITION = UDim2.fromScale(0.82, 0.66)
local TOUCH_AIM_RADIUS = 62

local active = false
local roomActive = false
local savedCameraState = nil
local cameraHeight = DEFAULT_HEIGHT
local backOffset = DEFAULT_BACK_OFFSET
local cameraYaw = 0
local cameraPitch = math.rad(-8)
local rightStickX = 0
local rightStickY = 0
local aiming = false
local cameraMode = "Overhead"
local inputConnection = nil
local inputEndedConnection = nil
local ammoCount = 0
local ammoMax = 6
local aimMarker = nil
local overheadAimDirection = Vector3.new(0, 0, -1)
local overheadAimDistance = OVERHEAD_AIM_DEFAULT_DISTANCE
local touchAimInput = nil

local gui = Instance.new("ScreenGui")
gui.Name = "DontTouchItTopDownArenaHud"
gui.IgnoreGuiInset = false
gui.ResetOnSpawn = false
gui.DisplayOrder = 148
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")
pcall(function()
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
end)

local ammoLabel = Instance.new("TextLabel")
ammoLabel.Name = "TopDownAmmoLabel"
ammoLabel.AnchorPoint = Vector2.new(0.5, 1)
ammoLabel.BackgroundColor3 = Color3.fromRGB(10, 14, 22)
ammoLabel.BackgroundTransparency = 0.12
ammoLabel.BorderSizePixel = 0
ammoLabel.Font = Enum.Font.GothamBlack
ammoLabel.Position = UDim2.new(0.5, 0, 1, -88)
ammoLabel.Size = UDim2.new(0.42, 0, 0, 42)
ammoLabel.TextColor3 = Color3.fromRGB(224, 246, 255)
ammoLabel.TextScaled = true
ammoLabel.TextWrapped = true
ammoLabel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = ammoLabel

local reticle = Instance.new("TextLabel")
reticle.Name = "TopDownAimReticle"
reticle.AnchorPoint = Vector2.new(0.5, 0.5)
reticle.BackgroundTransparency = 1
reticle.Font = Enum.Font.GothamBlack
reticle.Position = UDim2.fromScale(0.5, 0.5)
reticle.Size = UDim2.fromOffset(96, 96)
reticle.Text = "+"
reticle.TextColor3 = Color3.fromRGB(119, 255, 203)
reticle.TextScaled = true
reticle.TextStrokeColor3 = Color3.fromRGB(10, 14, 22)
reticle.TextStrokeTransparency = 0.15
reticle.Visible = false
reticle.Parent = gui

local touchAimButton = Instance.new("TextButton")
touchAimButton.Name = "TopDownTouchAimButton"
touchAimButton.AnchorPoint = Vector2.new(0.5, 0.5)
touchAimButton.AutoButtonColor = true
touchAimButton.BackgroundColor3 = Color3.fromRGB(18, 23, 29)
touchAimButton.BackgroundTransparency = 0.08
touchAimButton.BorderSizePixel = 0
touchAimButton.Font = Enum.Font.GothamBlack
touchAimButton.Position = TOUCH_AIM_BUTTON_POSITION
touchAimButton.Size = TOUCH_AIM_BUTTON_SIZE
touchAimButton.Text = "Aim"
touchAimButton.TextColor3 = Color3.fromRGB(224, 255, 244)
touchAimButton.TextScaled = true
touchAimButton.TextStrokeColor3 = Color3.fromRGB(5, 8, 12)
touchAimButton.TextStrokeTransparency = 0.35
touchAimButton.TextWrapped = true
touchAimButton.Visible = false
touchAimButton.ZIndex = 20
touchAimButton.Parent = gui

local touchAimCorner = Instance.new("UICorner")
touchAimCorner.CornerRadius = UDim.new(1, 0)
touchAimCorner.Parent = touchAimButton

local touchAimStroke = Instance.new("UIStroke")
touchAimStroke.Color = Color3.fromRGB(119, 255, 203)
touchAimStroke.Thickness = 2
touchAimStroke.Transparency = 0.18
touchAimStroke.Parent = touchAimButton

local function getRootPart()
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function getControlHint()
	if UserInputService.TouchEnabled then
		return "Hold Aim  tap Throw"
	elseif UserInputService.GamepadEnabled then
		return "LT Aim  RT Throw"
	end

	return "Right-click Aim  click Throw"
end

local function updateAmmoLabel(message)
	if not active then
		return
	end

	if message and message ~= "" then
		ammoLabel.Text = message
	elseif ammoCount > 0 then
		ammoLabel.Text = ("Balloons %d / %d  |  %s"):format(ammoCount, ammoMax, getControlHint())
	else
		ammoLabel.Text = "Walk over a bucket to load balloons"
	end
end

local function flattenDirection(direction, fallback)
	if typeof(direction) ~= "Vector3" then
		return fallback
	end

	local flatDirection = Vector3.new(direction.X, 0, direction.Z)
	if flatDirection.Magnitude < 0.1 then
		return fallback
	end

	return flatDirection.Unit
end

local function resetOverheadAim()
	local rootPart = getRootPart()
	local fallback = Vector3.new(0, 0, -1)
	overheadAimDirection = if rootPart then flattenDirection(rootPart.CFrame.LookVector, fallback) else fallback
	overheadAimDistance = OVERHEAD_AIM_DEFAULT_DISTANCE
end

local function getCameraRelativeFlatDirection(x, y)
	local yawFrame = CFrame.Angles(0, cameraYaw, 0)
	local right = yawFrame:VectorToWorldSpace(Vector3.new(1, 0, 0))
	local forward = yawFrame:VectorToWorldSpace(Vector3.new(0, 0, -1))
	local direction = right * x + forward * y
	return flattenDirection(direction, overheadAimDirection)
end

local function applyOverheadAimVector(x, y)
	if cameraMode ~= "Overhead" then
		return
	end

	local stick = Vector2.new(x, y)
	local magnitude = math.min(stick.Magnitude, 1)
	if magnitude <= AIM_STICK_DEADZONE then
		return
	end

	local scaledMagnitude = math.clamp((magnitude - AIM_STICK_DEADZONE) / (1 - AIM_STICK_DEADZONE), 0, 1)
	overheadAimDirection = getCameraRelativeFlatDirection(stick.X, stick.Y)
	overheadAimDistance = OVERHEAD_AIM_MIN_DISTANCE
		+ (AIM_DISTANCE - OVERHEAD_AIM_MIN_DISTANCE) * scaledMagnitude
end

local function updateOverheadAimFromStick()
	if not aiming then
		return
	end

	applyOverheadAimVector(rightStickX, rightStickY)
end

local function getAimDirection()
	local direction
	if cameraMode == "FPV" then
		direction = (CFrame.Angles(0, cameraYaw, 0) * CFrame.Angles(cameraPitch, 0, 0)):VectorToWorldSpace(Vector3.new(0, 0, -1))
	else
		direction = overheadAimDirection
	end
	if direction.Magnitude < 0.1 then
		return Vector3.new(0, 0, -1)
	end
	return direction.Unit
end

local function ensureAimMarker()
	if aimMarker and aimMarker.Parent then
		return aimMarker
	end

	aimMarker = Instance.new("Part")
	aimMarker.Name = AIM_MARKER_NAME
	aimMarker.Anchored = true
	aimMarker.CanCollide = false
	aimMarker.CanTouch = false
	aimMarker.CastShadow = false
	aimMarker.Shape = Enum.PartType.Cylinder
	aimMarker.Size = Vector3.new(0.14, 3.4, 3.4)
	aimMarker.Color = Color3.fromRGB(119, 255, 203)
	aimMarker.Material = Enum.Material.Neon
	aimMarker.Transparency = 0.36
	aimMarker.Parent = workspace
	return aimMarker
end

local function getAimTargetPosition()
	local rootPart = getRootPart()
	if not rootPart then
		return nil
	end

	local direction = getAimDirection()
	local aimDistance = if cameraMode == "Overhead" then overheadAimDistance else AIM_DISTANCE
	local guess = rootPart.Position + direction * aimDistance
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }

	local result = workspace:Raycast(guess + Vector3.new(0, 35, 0), Vector3.new(0, -80, 0), params)
	if result then
		return result.Position + Vector3.new(0, 0.12, 0)
	end

	return Vector3.new(guess.X, rootPart.Position.Y, guess.Z)
end

local function unbindThrow()
	ContextActionService:UnbindAction(THROW_ACTION)
end

local function unbindAim()
	ContextActionService:UnbindAction(AIM_ACTION)
end

local function unbindJumpAim()
	ContextActionService:UnbindAction(JUMP_AIM_ACTION)
end

local function updateTouchAimButton()
	local visible = active and UserInputService.TouchEnabled
	touchAimButton.Visible = visible
	touchAimButton.Text = if aiming then "Aiming" else "Aim"
	touchAimButton.BackgroundColor3 = if aiming then Color3.fromRGB(43, 76, 68) else Color3.fromRGB(18, 23, 29)
	touchAimStroke.Transparency = if aiming then 0.02 else 0.18
end

local function updateReticle(camera, aimTarget)
	if not active or not aiming then
		reticle.Visible = false
		return
	end

	if cameraMode == "Overhead" and aimTarget then
		local screenPoint, onScreen = camera:WorldToViewportPoint(aimTarget + Vector3.new(0, 1.2, 0))
		reticle.Position = UDim2.fromOffset(screenPoint.X, screenPoint.Y)
		reticle.Visible = onScreen == true
	else
		reticle.Position = UDim2.fromScale(0.5, 0.5)
		reticle.Visible = true
	end
end

local function setAiming(nextAiming)
	aiming = nextAiming == true
	reticle.Visible = active and aiming and cameraMode ~= "Overhead"
	local marker = ensureAimMarker()
	marker.Transparency = aiming and 0.36 or 1
	updateTouchAimButton()
end

local function finishTouchAim(input)
	if input and input ~= touchAimInput then
		return
	end

	touchAimInput = nil
	setAiming(false)
end

local function updateOverheadAimFromTouch(position)
	if not touchAimButton.Visible then
		return
	end

	local center = touchAimButton.AbsolutePosition + touchAimButton.AbsoluteSize * 0.5
	local delta = Vector2.new(position.X, position.Y) - center
	local x = math.clamp(delta.X / TOUCH_AIM_RADIUS, -1, 1)
	local y = math.clamp(-delta.Y / TOUCH_AIM_RADIUS, -1, 1)
	applyOverheadAimVector(x, y)
end

touchAimButton.InputBegan:Connect(function(input)
	if not active
		or not UserInputService.TouchEnabled
		or (input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1)
	then
		return
	end

	touchAimInput = input
	setAiming(true)
	updateOverheadAimFromTouch(input.Position)
end)

touchAimButton.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		finishTouchAim(input)
	end
end

local function bindThrow()
	unbindThrow()
	ContextActionService:BindAction(THROW_ACTION, function(_, inputState)
		if inputState ~= Enum.UserInputState.Begin or not active then
			return Enum.ContextActionResult.Pass
		end

		topDownRemote:FireServer({
			Action = "Throw",
			Direction = getAimDirection(),
			TargetPosition = getAimTargetPosition(),
		})
		return Enum.ContextActionResult.Sink
	end, true, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)

	pcall(function()
		ContextActionService:SetTitle(THROW_ACTION, "Throw")
		ContextActionService:SetPosition(THROW_ACTION, UDim2.fromScale(0.68, 0.66))
	end)
end

local function bindAim()
	unbindAim()
	ContextActionService:BindAction(AIM_ACTION, function(_, inputState)
		if not active then
			return Enum.ContextActionResult.Pass
		end

		if inputState == Enum.UserInputState.Begin then
			setAiming(true)
			return Enum.ContextActionResult.Sink
		elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
			setAiming(false)
			return Enum.ContextActionResult.Sink
		end

		return Enum.ContextActionResult.Sink
	end, false, Enum.UserInputType.MouseButton2, Enum.KeyCode.ButtonL2)

	pcall(function()
		ContextActionService:SetTitle(AIM_ACTION, "Aim")
		ContextActionService:SetPosition(AIM_ACTION, UDim2.fromScale(0.68, 0.66))
	end)
end

local function bindJumpAim()
	unbindJumpAim()
	ContextActionService:BindActionAtPriority(
		JUMP_AIM_ACTION,
		function(_, inputState)
			if not active or not UserInputService.TouchEnabled then
				return Enum.ContextActionResult.Pass
			end

			if inputState == Enum.UserInputState.Begin then
				setAiming(true)
				return Enum.ContextActionResult.Sink
			elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
				setAiming(false)
				return Enum.ContextActionResult.Sink
			end

			return Enum.ContextActionResult.Sink
		end,
		false,
		Enum.ContextActionPriority.High.Value + 10,
		Enum.PlayerActions.CharacterJump
	)
end

local function restoreCamera()
	if not active then
		return
	end

	active = false
	gui.Enabled = false
	rightStickX = 0
	rightStickY = 0
	touchAimInput = nil
	setAiming(false)
	RunService:UnbindFromRenderStep(RENDER_STEP_NAME)
	unbindThrow()
	unbindAim()
	unbindJumpAim()

	if inputConnection then
		inputConnection:Disconnect()
		inputConnection = nil
	end

	if inputEndedConnection then
		inputEndedConnection:Disconnect()
		inputEndedConnection = nil
	end

	local camera = workspace.CurrentCamera
	if camera and savedCameraState then
		camera.CameraType = savedCameraState.CameraType or Enum.CameraType.Custom
		camera.CameraSubject = savedCameraState.CameraSubject
		camera.FieldOfView = savedCameraState.FieldOfView or 70
		if savedCameraState.CFrame then
			camera.CFrame = savedCameraState.CFrame
		end
	end

	savedCameraState = nil
end

local function updateCamera(deltaTime)
	local camera = workspace.CurrentCamera
	local rootPart = getRootPart()
	if not camera or not rootPart then
		return
	end

	if cameraMode == "FPV" then
		if math.abs(rightStickX) > 0.08 then
			cameraYaw -= rightStickX * YAW_SPEED * deltaTime
		end

		if math.abs(rightStickY) > 0.08 then
			cameraPitch = math.clamp(cameraPitch - rightStickY * PITCH_SPEED * deltaTime, MIN_FPV_PITCH, MAX_FPV_PITCH)
		end
	elseif cameraMode == "Overhead" then
		updateOverheadAimFromStick()
	end

	local aimTarget = getAimTargetPosition()
	local marker = ensureAimMarker()
	if marker then
		if aiming and aimTarget then
			marker.CFrame = CFrame.new(aimTarget) * CFrame.Angles(0, 0, math.rad(90))
			marker.Transparency = 0.36
		else
			marker.Transparency = 1
		end
	end

	if cameraMode == "Normal" then
		camera.CameraType = Enum.CameraType.Custom
		camera.FieldOfView = savedCameraState and savedCameraState.FieldOfView or 70
		updateReticle(camera, aimTarget)
		return
	end

	local focus = rootPart.Position + Vector3.new(0, 1.8, 0)
	local aimDirection = getAimDirection()
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = if aiming then 40 elseif cameraMode == "FPV" then 62 else 48
	if cameraMode == "FPV" then
		local cameraPosition = rootPart.Position + Vector3.new(0, 2.65, 0)
		camera.CFrame = CFrame.new(cameraPosition, cameraPosition + aimDirection * 45)
	else
		local cameraOffset = CFrame.Angles(0, cameraYaw, 0):VectorToWorldSpace(Vector3.new(0, cameraHeight, backOffset))
		local cameraPosition = focus + cameraOffset
		camera.CFrame = CFrame.new(cameraPosition, focus)
	end
	updateReticle(camera, aimTarget)
end

local function enableCamera()
	if active then
		return
	end

	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	active = true
	gui.Enabled = true
	savedCameraState = {
		CameraType = camera.CameraType,
		CameraSubject = camera.CameraSubject,
		FieldOfView = camera.FieldOfView,
		CFrame = camera.CFrame,
	}
	cameraHeight = DEFAULT_HEIGHT
	backOffset = DEFAULT_BACK_OFFSET
	cameraYaw = 0
	cameraPitch = math.rad(-8)
	rightStickX = 0
	rightStickY = 0
	touchAimInput = nil
	resetOverheadAim()
	updateAmmoLabel()
	updateTouchAimButton()
	bindThrow()
	bindAim()
	bindJumpAim()

	inputConnection = UserInputService.InputChanged:Connect(function(input, gameProcessed)
		if not active then
			return
		end

		if touchAimInput and input == touchAimInput then
			updateOverheadAimFromTouch(input.Position)
			return
		end

		if input.KeyCode == Enum.KeyCode.Thumbstick2 then
			rightStickX = math.abs(input.Position.X) > 0.08 and input.Position.X or 0
			rightStickY = math.abs(input.Position.Y) > 0.08 and input.Position.Y or 0
			return
		end

		if gameProcessed then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseWheel then
			cameraHeight = math.clamp(cameraHeight - input.Position.Z * 5, MIN_HEIGHT, MAX_HEIGHT)
			backOffset = math.clamp(DEFAULT_BACK_OFFSET * (cameraHeight / DEFAULT_HEIGHT), 24, 44)
		end
	end)

	inputEndedConnection = UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Thumbstick2 then
			rightStickX = 0
			rightStickY = 0
		end
		finishTouchAim(input)
	end)

	RunService:BindToRenderStep(RENDER_STEP_NAME, Enum.RenderPriority.Camera.Value + 1, updateCamera)
end

roomStatusRemote.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end

	if payload.Type == "Room" and payload.RoomId == "TopDownArena" then
		roomActive = true
		enableCamera()
	else
		roomActive = false
		restoreCamera()
	end
end)

topDownRemote.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end

	if payload.Action == "Ammo" then
		ammoCount = math.max(0, math.floor(payload.Count or ammoCount))
		ammoMax = math.max(1, math.floor(payload.Max or ammoMax))
		updateAmmoLabel(payload.Message)
		if payload.Message and payload.Message ~= "" then
			task.delay(2.2, function()
				updateAmmoLabel()
			end)
		end
	elseif payload.Action == "CameraMode" then
		cameraMode = payload.Mode or "Overhead"
		if cameraMode == "Overhead" then
			resetOverheadAim()
		end
		setAiming(false)
		if roomActive then
			enableCamera()
			updateAmmoLabel(payload.Message)
			if payload.Message and payload.Message ~= "" then
				task.delay(2.2, function()
					updateAmmoLabel()
				end)
			end
		end
	end
end)

player.CharacterRemoving:Connect(restoreCamera)
UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(updateTouchAimButton)
