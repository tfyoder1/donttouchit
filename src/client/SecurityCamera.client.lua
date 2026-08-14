local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local securityCameraRemote = remotes:WaitForChild(Constants.Remotes.SecurityCamera)
local playerGui = player:WaitForChild("PlayerGui")

local SCREEN_BUTTON_ACTION = "DontTouchItSecurityScreenButton"
local STOP_ACTION = "DontTouchItSecurityCameraStop"
local activeSession = nil

local function restoreCamera()
	if not activeSession then
		return
	end

	local camera = workspace.CurrentCamera
	if camera then
		camera.CameraType = activeSession.CameraType or Enum.CameraType.Custom
		camera.CameraSubject = activeSession.CameraSubject
		camera.FieldOfView = activeSession.FieldOfView or 70
		if activeSession.CameraCFrame then
			camera.CFrame = activeSession.CameraCFrame
		end
	end

	if activeSession.Gui then
		activeSession.Gui:Destroy()
	end

	if activeSession.CameraUpdateConnection then
		activeSession.CameraUpdateConnection:Disconnect()
	end

	ContextActionService:UnbindAction(SCREEN_BUTTON_ACTION)
	ContextActionService:UnbindAction(STOP_ACTION)
	activeSession = nil
end

local function fireHiddenButton()
	if not activeSession then
		return
	end

	securityCameraRemote:FireServer({
		Action = "HiddenButton",
	})
end

local function makeOverlay(duration, cameraLabel)
	local gui = Instance.new("ScreenGui")
	gui.Name = "DontTouchItSecurityCamera"
	gui.DisplayOrder = 85
	gui.IgnoreGuiInset = false
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	local vignette = Instance.new("Frame")
	vignette.Name = "SecurityVignette"
	vignette.BackgroundColor3 = Color3.fromRGB(2, 8, 10)
	vignette.BackgroundTransparency = 0.38
	vignette.BorderSizePixel = 0
	vignette.Size = UDim2.fromScale(1, 1)
	vignette.Parent = gui

	local scan = Instance.new("Frame")
	scan.Name = "ScanlineBand"
	scan.AnchorPoint = Vector2.new(0.5, 0)
	scan.BackgroundColor3 = Color3.fromRGB(119, 255, 203)
	scan.BackgroundTransparency = 0.86
	scan.BorderSizePixel = 0
	scan.Position = UDim2.fromScale(0.5, 0.18)
	scan.Size = UDim2.fromScale(1, 0.025)
	scan.Parent = gui

	local label = Instance.new("TextLabel")
	label.Name = "SecurityFeedLabel"
	label.AnchorPoint = Vector2.new(0, 0)
	label.BackgroundColor3 = Color3.fromRGB(5, 13, 16)
	label.BackgroundTransparency = 0.12
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBlack
	label.Position = UDim2.new(0, 22, 0, 22)
	label.Size = UDim2.fromOffset(330, 74)
	label.Text = ("%s\nSCREEN-ONLY OBJECT DETECTED"):format(cameraLabel or "CAM 23 - INTERNAL FEED")
	label.TextColor3 = Color3.fromRGB(119, 255, 203)
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = gui

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(119, 255, 203)
	stroke.Thickness = 2
	stroke.Transparency = 0.18
	stroke.Parent = label

	local button = Instance.new("TextButton")
	button.Name = "ScreenOnlyButton"
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.AutoButtonColor = true
	button.BackgroundColor3 = Color3.fromRGB(255, 72, 86)
	button.BackgroundTransparency = 0.04
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBlack
	button.Position = UDim2.fromScale(0.68, 0.6)
	button.Size = UDim2.fromOffset(236, 78)
	button.Text = "SCREEN-ONLY\nBUTTON"
	button.TextColor3 = Color3.fromRGB(255, 246, 220)
	button.TextScaled = true
	button.TextWrapped = true
	button.Parent = gui

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 12)
	buttonCorner.Parent = button

	local buttonStroke = Instance.new("UIStroke")
	buttonStroke.Color = Color3.fromRGB(255, 246, 220)
	buttonStroke.Thickness = 3
	buttonStroke.Transparency = 0.1
	buttonStroke.Parent = button

	local hint = Instance.new("TextLabel")
	hint.Name = "SecurityFeedHint"
	hint.AnchorPoint = Vector2.new(0.5, 1)
	hint.BackgroundColor3 = Color3.fromRGB(5, 13, 16)
	hint.BackgroundTransparency = 0.12
	hint.BorderSizePixel = 0
	hint.Font = Enum.Font.GothamBold
	hint.Position = UDim2.new(0.5, 0, 1, -22)
	hint.Size = UDim2.new(0.84, 0, 0, 58)
	hint.Text = ("Press X / tap the screen button before the feed times out in %ds."):format(duration or 45)
	hint.TextColor3 = Color3.fromRGB(255, 242, 181)
	hint.TextScaled = true
	hint.TextWrapped = true
	hint.Parent = gui

	button.MouseButton1Click:Connect(fireHiddenButton)
	return gui
end

local function startCamera(payload)
	restoreCamera()

	local camera = workspace.CurrentCamera
	local cameraCFrame = payload.CameraCFrame
	if not camera or typeof(cameraCFrame) ~= "CFrame" then
		return
	end

	activeSession = {
		CameraType = camera.CameraType,
		CameraSubject = camera.CameraSubject,
		CameraCFrame = camera.CFrame,
		FieldOfView = camera.FieldOfView,
		TargetCFrame = cameraCFrame,
		Gui = makeOverlay(payload.Duration or 45, payload.CameraLabel),
	}

	camera.CameraType = Enum.CameraType.Scriptable
	camera.CameraSubject = nil
	camera.CFrame = cameraCFrame
	camera.FieldOfView = 64

	activeSession.CameraUpdateConnection = RunService.RenderStepped:Connect(function()
		local currentCamera = workspace.CurrentCamera
		if currentCamera and activeSession then
			currentCamera.CameraType = Enum.CameraType.Scriptable
			currentCamera.CameraSubject = nil
			currentCamera.CFrame = activeSession.TargetCFrame
		end
	end)

	ContextActionService:BindAction(SCREEN_BUTTON_ACTION, function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			fireHiddenButton()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.E, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonA)

	ContextActionService:BindAction(STOP_ACTION, function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			securityCameraRemote:FireServer({
				Action = "Stop",
			})
			restoreCamera()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.Escape, Enum.KeyCode.ButtonB)

	task.delay(payload.Duration or 45, function()
		if activeSession then
			securityCameraRemote:FireServer({
				Action = "Stop",
			})
			restoreCamera()
		end
	end)
end

securityCameraRemote.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end

	if payload.Action == "Start" then
		startCamera(payload)
	elseif payload.Action == "Stop" then
		restoreCamera()
	end
end)

player.CharacterAdded:Connect(function()
	restoreCamera()
end)
