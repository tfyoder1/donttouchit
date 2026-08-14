local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local transformCameraRemote = remotes:WaitForChild(Constants.Remotes.TransformCamera)

local ASSIST_RENDER_STEP = "DontTouchItCameraAssist"
local FOCUS_PANEL_ACTION = "DontTouchItFocusControlPanel"
local activeToken = nil
local savedCameraState = nil
local savedVisibilityState = nil
local currentPanel = nil

local function getRootPart()
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function getHeadPart()
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChild("Head")
end

local function rememberLocalCharacterVisibility()
	if savedVisibilityState then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	savedVisibilityState = {}
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") then
			table.insert(savedVisibilityState, {
				Part = descendant,
				LocalTransparencyModifier = descendant.LocalTransparencyModifier,
			})
		end
	end
end

local function forceLocalCharacterVisible()
	rememberLocalCharacterVisibility()

	if not savedVisibilityState then
		return
	end

	for _, entry in savedVisibilityState do
		local part = entry.Part
		if part and part.Parent then
			part.LocalTransparencyModifier = 0
		end
	end
end

local function restoreLocalCharacterVisibility()
	if not savedVisibilityState then
		return
	end

	for _, entry in savedVisibilityState do
		local part = entry.Part
		if part and part.Parent then
			part.LocalTransparencyModifier = entry.LocalTransparencyModifier or 0
		end
	end

	savedVisibilityState = nil
end

local function isCameraFirstPerson(camera)
	local rootPart = getRootPart()
	if not camera or not rootPart then
		return false
	end

	if player.CameraMode == Enum.CameraMode.LockFirstPerson then
		return true
	end

	local referencePart = getHeadPart() or rootPart
	local distance = (camera.CFrame.Position - referencePart.Position).Magnitude
	return distance <= 2.75
end

local function smoothstep(alpha)
	alpha = math.clamp(alpha, 0, 1)
	return alpha * alpha * (3 - 2 * alpha)
end

local function restoreCamera(token)
	if token and activeToken ~= token then
		return
	end

	RunService:UnbindFromRenderStep(ASSIST_RENDER_STEP)
	activeToken = nil

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
	restoreLocalCharacterVisibility()
end

local function beginCameraAssist(cframeProvider, fieldOfView, duration, options)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	if activeToken then
		restoreCamera(activeToken)
	end

	local token = {}
	activeToken = token
	options = options or {}
	savedCameraState = {
		CameraType = camera.CameraType,
		CameraSubject = camera.CameraSubject,
		FieldOfView = camera.FieldOfView,
		CFrame = camera.CFrame,
	}

	if options.ForceCharacterVisible then
		forceLocalCharacterVisible()
	end

	local startedAt = os.clock()
	RunService:BindToRenderStep(ASSIST_RENDER_STEP, Enum.RenderPriority.Camera.Value + 45, function()
		if activeToken ~= token then
			return
		end

		local elapsed = os.clock() - startedAt
		local nextCFrame = cframeProvider(elapsed)
		if not nextCFrame then
			restoreCamera(token)
			return
		end

		local activeCamera = workspace.CurrentCamera
		if not activeCamera then
			return
		end

		activeCamera.CameraType = Enum.CameraType.Scriptable
		activeCamera.FieldOfView = fieldOfView or 54
		activeCamera.CFrame = nextCFrame

		if options.ForceCharacterVisible then
			forceLocalCharacterVisible()
		end
	end)

	task.delay(math.max(0.2, duration or 3), function()
		restoreCamera(token)
	end)
end

local function getControlPanelFromPrompt(prompt)
	local current = prompt and prompt.Parent

	while current and current ~= workspace do
		if current:IsA("Model") and current:GetAttribute("StrictPromptTargets") then
			local panel = current:FindFirstChild("ControlPanelBack", true)
			if panel and panel:IsA("BasePart") then
				return panel
			end

			if current.PrimaryPart and current.PrimaryPart:IsA("BasePart") then
				return current.PrimaryPart
			end
		end

		current = current.Parent
	end

	return nil
end

local function getHorizontalDirection(direction, fallback)
	local horizontal = Vector3.new(direction.X, 0, direction.Z)
	if horizontal.Magnitude > 0.1 then
		return horizontal.Unit
	end

	local fallbackHorizontal = Vector3.new(fallback.X, 0, fallback.Z)
	if fallbackHorizontal.Magnitude > 0.1 then
		return fallbackHorizontal.Unit
	end

	return Vector3.new(0, 0, -1)
end

local function beginSizeTransformReveal(scale, duration)
	local camera = workspace.CurrentCamera
	local rootPart = getRootPart()
	if not camera or not rootPart then
		return
	end

	if not isCameraFirstPerson(camera) then
		return
	end

	local isGiant = (scale or 1) > 1.2
	local startCFrame = camera.CFrame
	local startFieldOfView = camera.FieldOfView
	local forward = getHorizontalDirection(startCFrame.LookVector, rootPart.CFrame.LookVector)
	local right = getHorizontalDirection(startCFrame.RightVector, rootPart.CFrame.RightVector)
	local pullBackDistance = if isGiant then 26 else 11
	local sideOffset = if isGiant then 4.2 else 2.2
	local cameraLift = if isGiant then 8.6 else 3.6
	local targetHeight = if isGiant then 5.8 else 2
	local totalDuration = math.max(1.8, tonumber(duration) or Constants.SizeTransformCameraDuration or 3)
	local pullBackDuration = math.min(0.7, totalDuration * 0.25)
	local returnDuration = math.min(0.75, totalDuration * 0.25)
	local holdUntil = math.max(pullBackDuration, totalDuration - returnDuration)

	beginCameraAssist(function(elapsed)
		local currentRoot = getRootPart()
		if not currentRoot then
			return nil
		end

		local revealPosition = currentRoot.Position
			- forward * pullBackDistance
			+ right * sideOffset
			+ Vector3.new(0, cameraLift, 0)
		local targetPosition = currentRoot.Position + Vector3.new(0, targetHeight, 0)
		local revealCFrame = CFrame.new(revealPosition, targetPosition)

		if elapsed < pullBackDuration then
			return startCFrame:Lerp(revealCFrame, smoothstep(elapsed / pullBackDuration))
		end

		if elapsed > holdUntil then
			return revealCFrame:Lerp(startCFrame, smoothstep((elapsed - holdUntil) / returnDuration))
		end

		return revealCFrame
	end, startFieldOfView, totalDuration, {
		ForceCharacterVisible = true,
	})
end

local function focusControlPanel(panel)
	panel = panel or currentPanel
	if not panel or not panel.Parent then
		return
	end

	beginCameraAssist(function()
		if not panel or not panel.Parent then
			return nil
		end

		local panelFront = -panel.CFrame.LookVector
		local targetPosition = panel.Position + panel.CFrame.UpVector * 0.08
		local distance = math.clamp(panel.Size.X * 1.62, 7, 12)
		local cameraPosition = targetPosition + panelFront * distance + panel.CFrame.UpVector * 0.45
		return CFrame.new(cameraPosition, targetPosition)
	end, 42, 3.4)
end

local function bindPanelFocus()
	ContextActionService:UnbindAction(FOCUS_PANEL_ACTION)
	ContextActionService:BindAction(FOCUS_PANEL_ACTION, function(_, inputState)
		if inputState ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Sink
		end

		focusControlPanel(currentPanel)
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.F, Enum.KeyCode.ButtonL1)

	pcall(function()
		ContextActionService:SetTitle(FOCUS_PANEL_ACTION, "Panel")
		ContextActionService:SetPosition(FOCUS_PANEL_ACTION, UDim2.fromScale(0.74, 0.54))
	end)
end

local function unbindPanelFocus()
	ContextActionService:UnbindAction(FOCUS_PANEL_ACTION)
end

ProximityPromptService.PromptShown:Connect(function(prompt)
	local panel = getControlPanelFromPrompt(prompt)
	if not panel then
		return
	end

	currentPanel = panel
	bindPanelFocus()
end)

ProximityPromptService.PromptHidden:Connect(function(prompt)
	local panel = getControlPanelFromPrompt(prompt)
	if panel and currentPanel == panel then
		currentPanel = nil
		unbindPanelFocus()
	end
end)

transformCameraRemote.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" or payload.Action ~= "SizeTransform" then
		return
	end

	local scale = tonumber(payload.Scale) or 1
	beginSizeTransformReveal(scale, payload.Duration or Constants.SizeTransformCameraDuration or 3)
end)

player.CharacterRemoving:Connect(function()
	restoreCamera(activeToken)
	currentPanel = nil
	unbindPanelFocus()
end)
