local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local DeviceProfile = require(script.Parent:WaitForChild("DeviceProfile"))
local FlightInput = require(script.Parent:WaitForChild("FlightInput"))
local UiLayerController = require(script.Parent:WaitForChild("UiLayerController"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local devRemote = remotes:WaitForChild(Constants.Remotes.DevTools)

local authorized = false
local gui = nil
local toggleButton = nil
local panel = nil
local panelConstraint = nil
local panelScroll = nil
local statusLabel = nil
local roomList = nil
local sessionList = nil
local roomStateList = nil
local eventList = nil
local areaList = nil
local toolsList = nil
local energyList = nil
local storeList = nil
local discoveryList = nil
local userList = nil
local userManagementList = nil
local manualLookupBox = nil
local selectedRoomId = nil
local selectedManagedUserId = nil
local selectedModerationReasonCode = "HARASSMENT"
local moderationReasonText = ""
local pendingAdminActionKey = nil
local latestState = nil
local flyEnabled = false
local noclipEnabled = false
local flyVelocity = nil
local flyGyro = nil
local flyConnections = {}
local pressedKeys = {}
local devInfoLabel = nil
local devInfoToken = 0
local inspectEnabled = false
local inspectAutoEnabled = false
local inspectLabel = nil
local inspectCloseButton = nil
local inspectHighlight = nil
local inspectWindowManuallyPositioned = false
local inspectDragging = false
local inspectDragInput = nil
local inspectDragStartPosition = nil
local inspectDragStartTopLeft = nil
local idLabelsEnabled = false
local idLabelFolder = nil
local lastIdLabelsUpdateAt = 0
local DEV_DISMISS_START_ATTRIBUTE = "DontTouchItDevDismissedStartIntro"
local DEV_TITLE_SEQUENCE_ENABLED_ATTRIBUTE = "DontTouchItDevTitleSequenceEnabled"
local DEV_SHOW_TITLE_SEQUENCE_NONCE_ATTRIBUTE = "DontTouchItDevShowTitleSequenceNonce"
local DEV_WALL_DRAFT_ENABLED_ATTRIBUTE = "DontTouchItDevWallDraftEnabled"
local TOUCH_EDIT_MODE_ATTRIBUTE = "DontTouchItTouchEditLayoutActive"
local DEV_LAYOUT_RESET_ATTRIBUTE = "DontTouchItDevLayoutResetNonce"
local playerGui = player:WaitForChild("PlayerGui")
local FLY_SPEED = 55
local GAMEPAD_STICK_DEADZONE = 0.16
local INSPECT_RANGE = 700
local INSPECT_SKIP_EPSILON = 0.15
local MAX_INSPECT_RAYCAST_SKIPS = 8
local ID_LABEL_RANGE = 52
local ID_LABEL_MAX_PARTS = 24
local ID_LABEL_UPDATE_INTERVAL = 0.9
local ID_LABEL_FOLDER_NAME = "DontTouchItDevIdLabels"
local DOUBLE_JUMP_MIN_SECONDS = 0.08
local DOUBLE_JUMP_MAX_SECONDS = 0.45
local DOUBLE_JUMP_FLY_COOLDOWN_SECONDS = 1
local BUTTON_ACTIVATION_DEBOUNCE_SECONDS = 0.25
local TOUCH_TAP_MAX_DRAG_PIXELS = 18
local currentDeviceProfile = DeviceProfile.Get()
local showDevInfo
local rebuildPanel
local applyDevLayout
local lastJumpRequestAt = 0
local lastDoubleJumpFlyRequestAt = 0
local devToggleManualPosition = nil
local devPanelManualPosition = nil
local devLayoutDragging = nil
local devToggleCoordinateLabel = nil
local devPanelCoordinateLabel = nil
local flyTouchGui = nil
local flyTouchUpPressed = false
local flyTouchDownPressed = false

local sectionExpanded = {
	Locations = false,
	SessionSimulation = false,
	RoomState = false,
	Events = false,
	SecretAreas = false,
	SessionTools = false,
	EnergyRecovery = false,
	StorePrices = false,
	RoomLogOverrides = false,
	UserManagement = false,
}

local function isPhoneProfile()
	return currentDeviceProfile and currentDeviceProfile.IsPhone == true
end

local function isGamepadProfile()
	return currentDeviceProfile and currentDeviceProfile.IsGamepad == true
end

local function clearList(container)
	if not container then
		return
	end

	for _, child in ipairs(container:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

local function makeCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 6)
	corner.Parent = parent
	return corner
end

local function makeCoordinateLabel(parent, name)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Active = false
	label.BackgroundColor3 = Color3.fromRGB(8, 11, 16)
	label.BackgroundTransparency = 0.08
	label.BorderSizePixel = 0
	label.Font = Enum.Font.Code
	label.Position = UDim2.new(0, 0, 0, -22)
	label.Size = UDim2.new(1, 36, 0, 18)
	label.TextColor3 = Color3.fromRGB(226, 245, 255)
	label.TextSize = 10
	label.TextWrapped = false
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Visible = false
	label.ZIndex = (parent.ZIndex or 1) + 6
	label.Parent = parent
	makeCorner(label, 5)

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(102, 217, 255)
	stroke.Thickness = 1
	stroke.Transparency = 0.45
	stroke.Parent = label
	return label
end

local function makeSection(parent, titleText)
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.Size = UDim2.new(1, 0, 0, isPhoneProfile() and 21 or 24)
	title.Text = titleText
	title.TextColor3 = Color3.fromRGB(154, 255, 192)
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = parent
	return title
end

local function isSectionExpanded(sectionKey)
	return sectionExpanded[sectionKey] == true
end

local function isButtonVisibleForActivation(button)
	local current = button
	while current and current ~= game do
		if current:IsA("GuiObject") and not current.Visible then
			return false
		end
		if current:IsA("ScreenGui") and not current.Enabled then
			return false
		end
		current = current.Parent
	end

	return button.Parent ~= nil
end

local function wireButtonActivation(button, onActivate)
	button.Active = true
	button.AutoButtonColor = true
	button.Selectable = true

	local lastActivationAt = 0
	local touchStartByInput = {}

	local function activate()
		if not isButtonVisibleForActivation(button) then
			return
		end

		local now = os.clock()
		if now - lastActivationAt < BUTTON_ACTIVATION_DEBOUNCE_SECONDS then
			return
		end
		lastActivationAt = now

		local ok, err = pcall(onActivate)
		if not ok then
			warn(("[DON'T TOUCH IT] Dev tool button failed: %s"):format(tostring(err)))
			if showDevInfo then
				showDevInfo("Dev tool action failed. Check the output log for details.", 6)
			end
		end
	end

	button.Activated:Connect(activate)
	button.MouseButton1Click:Connect(activate)
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			touchStartByInput[input] = input.Position
		end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			local startPosition = touchStartByInput[input]
			touchStartByInput[input] = nil
			if startPosition and (input.Position - startPosition).Magnitude <= TOUCH_TAP_MAX_DRAG_PIXELS then
				activate()
			end
		elseif input.UserInputType == Enum.UserInputType.Gamepad1
			and input.KeyCode == Enum.KeyCode.ButtonA
			and GuiService.SelectedObject == button
			and isButtonVisibleForActivation(button) then
			activate()
		end
	end)
end

local function makeCollapseHeader(parent, sectionKey, titleText, count)
	local expanded = isSectionExpanded(sectionKey)
	local header = Instance.new("TextButton")
	header.BackgroundColor3 = Color3.fromRGB(25, 31, 40)
	header.BorderSizePixel = 0
	header.Font = Enum.Font.GothamBlack
	header.Size = UDim2.new(1, 0, 0, isPhoneProfile() and 28 or 32)
	header.Text = ("%s %s%s"):format(expanded and "v" or ">", titleText, count and ("  (" .. tostring(count) .. ")") or "")
	header.TextColor3 = Color3.fromRGB(154, 255, 192)
	header.TextScaled = true
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Parent = parent
	makeCorner(header, 5)

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = header

	wireButtonActivation(header, function()
		sectionExpanded[sectionKey] = not isSectionExpanded(sectionKey)
		if rebuildPanel then
			rebuildPanel()
		end
	end)

	return expanded
end

local function makeButton(parent, text, color, onClick)
	local button = Instance.new("TextButton")
	button.BackgroundColor3 = color or Color3.fromRGB(47, 55, 68)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Size = UDim2.new(1, 0, 0, isPhoneProfile() and 30 or 34)
	button.Text = text
	button.TextColor3 = Color3.fromRGB(238, 247, 255)
	button.TextScaled = true
	button.TextWrapped = true
	button.Parent = parent
	makeCorner(button, 5)

	wireButtonActivation(button, onClick)
	return button
end

local function makeInfoText(parent, text, height)
	local label = Instance.new("TextLabel")
	label.BackgroundColor3 = Color3.fromRGB(20, 25, 32)
	label.BackgroundTransparency = 0.08
	label.BorderSizePixel = 0
	label.Font = Enum.Font.Code
	label.Size = UDim2.new(1, 0, 0, height or (isPhoneProfile() and 52 or 60))
	label.Text = text
	label.TextColor3 = Color3.fromRGB(224, 239, 248)
	label.TextSize = isPhoneProfile() and 8 or 10
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Parent = parent
	makeCorner(label, 5)

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.PaddingLeft = UDim.new(0, 7)
	padding.PaddingRight = UDim.new(0, 7)
	padding.Parent = label
	return label
end

local function makeTextBox(parent, placeholder, text, onChanged)
	local box = Instance.new("TextBox")
	box.BackgroundColor3 = Color3.fromRGB(10, 14, 20)
	box.BorderSizePixel = 0
	box.ClearTextOnFocus = false
	box.Font = Enum.Font.GothamBold
	box.PlaceholderText = placeholder
	box.Size = UDim2.new(1, 0, 0, isPhoneProfile() and 30 or 34)
	box.Text = text or ""
	box.TextColor3 = Color3.fromRGB(238, 247, 255)
	box.PlaceholderColor3 = Color3.fromRGB(132, 147, 164)
	box.TextScaled = true
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.Parent = parent
	makeCorner(box, 5)

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = box

	box.FocusLost:Connect(function()
		if onChanged then
			onChanged(box.Text)
		end
	end)
	box:GetPropertyChangedSignal("Text"):Connect(function()
		if onChanged then
			onChanged(box.Text)
		end
	end)
	return box
end

local function hasCapability(capability)
	local capabilities = latestState and latestState.Capabilities
	return typeof(capabilities) == "table" and capabilities[capability] == true
end

local function hasAnyCapability(capabilities)
	for _, capability in ipairs(capabilities or {}) do
		if hasCapability(capability) then
			return true
		end
	end
	return false
end

local function getModerationReasonLabel(reasonCode)
	return (Constants.ModerationReasons and Constants.ModerationReasons[reasonCode]) or tostring(reasonCode or "Other")
end

local function getNextModerationReason(reasonCode)
	local order = Constants.ModerationReasonOrder or { "OTHER" }
	for index, code in ipairs(order) do
		if code == reasonCode then
			return order[(index % #order) + 1]
		end
	end
	return order[1]
end

local function makeConfirmableButton(parent, actionKey, label, confirmLabel, color, onConfirm)
	local confirming = pendingAdminActionKey == actionKey
	makeButton(parent, confirming and confirmLabel or label, confirming and Color3.fromRGB(138, 65, 55) or color, function()
		if pendingAdminActionKey == actionKey then
			pendingAdminActionKey = nil
			onConfirm()
		else
			pendingAdminActionKey = actionKey
			if rebuildPanel then
				rebuildPanel()
			end
		end
	end)
end

local function findFirstSelectableButton(root, selectionSnapshot)
	if not root then
		return nil
	end

	local preferredText = selectionSnapshot and selectionSnapshot.Text
	local preferredPosition = selectionSnapshot and selectionSnapshot.Position
	local fallback = nil
	local closest = nil
	local closestDistance = math.huge
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("TextButton") and descendant.Selectable and isButtonVisibleForActivation(descendant) then
			if not fallback then
				fallback = descendant
			end
			if preferredText and descendant.Text == preferredText then
				return descendant
			end
			if preferredPosition then
				local center = descendant.AbsolutePosition + (descendant.AbsoluteSize * 0.5)
				local distance = (center - preferredPosition).Magnitude
				if distance < closestDistance then
					closestDistance = distance
					closest = descendant
				end
			end
		end
	end

	return closest or fallback
end

local function getGamepadSelectionSnapshot()
	if not panel or not panel.Visible or not UserInputService.GamepadEnabled then
		return nil
	end

	local snapshot = {
		ScrollPosition = panelScroll and panelScroll.CanvasPosition or nil,
	}
	local selectedObject = GuiService.SelectedObject
	if selectedObject and panel and selectedObject:IsDescendantOf(panel) and selectedObject:IsA("TextButton") then
		snapshot.Text = selectedObject.Text
		snapshot.Position = selectedObject.AbsolutePosition + (selectedObject.AbsoluteSize * 0.5)
	end

	return snapshot
end

local function preserveGamepadSelection(selectionSnapshot)
	if not panel or not panel.Visible or not UserInputService.GamepadEnabled then
		return
	end

	task.defer(function()
		if not panel or not panel.Visible then
			return
		end

		local scrollPosition = selectionSnapshot and selectionSnapshot.ScrollPosition
		if panelScroll and scrollPosition then
			panelScroll.CanvasPosition = scrollPosition
		end

		local selectedObject = findFirstSelectableButton(panel, selectionSnapshot)
		if selectedObject then
			GuiService.SelectedObject = selectedObject
		end

		if panelScroll and scrollPosition then
			task.defer(function()
				if panel and panel.Visible and panelScroll then
					panelScroll.CanvasPosition = scrollPosition
				end
			end)
		end
	end)
end

local function clearPanelSelection()
	local selectedObject = GuiService.SelectedObject
	if selectedObject and panel and selectedObject:IsDescendantOf(panel) then
		GuiService.SelectedObject = nil
	end
end

local function getInspectViewportSize()
	local viewport = currentDeviceProfile and currentDeviceProfile.Viewport
	if viewport then
		return viewport
	end

	local camera = Workspace.CurrentCamera
	return camera and camera.ViewportSize or Vector2.new(1024, 768)
end

local function clampInspectTopLeft(topLeft, size)
	local viewport = getInspectViewportSize()
	local margin = isPhoneProfile() and 6 or 8
	local maxX = math.max(margin, viewport.X - size.X - margin)
	local maxY = math.max(margin, viewport.Y - size.Y - margin)
	return Vector2.new(
		math.clamp(topLeft.X, margin, maxX),
		math.clamp(topLeft.Y, margin, maxY)
	)
end

local function setInspectTopLeft(topLeft, manual)
	if not inspectLabel then
		return
	end

	local size = inspectLabel.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then
		size = Vector2.new(inspectLabel.Size.X.Offset, inspectLabel.Size.Y.Offset)
	end

	local clamped = clampInspectTopLeft(topLeft, size)
	inspectLabel.AnchorPoint = Vector2.zero
	inspectLabel.Position = UDim2.fromOffset(clamped.X, clamped.Y)
	if manual then
		inspectWindowManuallyPositioned = true
	end
end

local function applyInspectCloseButtonLayout()
	if not inspectCloseButton then
		return
	end

	local touchLandscape = currentDeviceProfile and currentDeviceProfile.IsTouch == true
		and currentDeviceProfile.Viewport
		and currentDeviceProfile.Viewport.X > currentDeviceProfile.Viewport.Y
	inspectCloseButton.AnchorPoint = Vector2.new(1, 0)
	inspectCloseButton.Position = UDim2.new(1, -8, 0, 8)
	inspectCloseButton.Size = UDim2.fromOffset(isPhoneProfile() and (touchLandscape and 22 or 24) or 30, isPhoneProfile() and (touchLandscape and 20 or 22) or 28)
	inspectCloseButton.TextSize = isPhoneProfile() and (touchLandscape and 10 or 11) or 14
end

local function applyInspectLayout(touchLandscape)
	if not inspectLabel then
		return
	end

	local viewport = getInspectViewportSize()
	local size
	local defaultLeft
	local defaultBottom
	local defaultTop
	if isPhoneProfile() then
		size = Vector2.new(math.floor(viewport.X * (touchLandscape and 0.29 or 0.48)), touchLandscape and 170 or 128)
		defaultLeft = touchLandscape and 104 or 20
		defaultTop = touchLandscape and 92 or nil
		defaultBottom = (touchLandscape and 138 or 112) + (touchLandscape and 28 or 25) + 10
		inspectLabel.TextSize = touchLandscape and 7 or 8
	elseif isGamepadProfile() then
		size = Vector2.new(330, 196)
		defaultLeft = 12
		defaultTop = 12
		inspectLabel.TextSize = 13
	else
		size = Vector2.new(330, 196)
		defaultLeft = 12
		defaultBottom = 78 + 34 + 10
		inspectLabel.TextSize = 13
	end

	inspectLabel.AnchorPoint = Vector2.zero
	inspectLabel.Size = UDim2.fromOffset(size.X, size.Y)
	if inspectWindowManuallyPositioned then
		setInspectTopLeft(inspectLabel.AbsolutePosition, false)
	elseif defaultTop then
		setInspectTopLeft(Vector2.new(defaultLeft, defaultTop), false)
	else
		setInspectTopLeft(Vector2.new(defaultLeft, viewport.Y - defaultBottom - size.Y), false)
	end
	applyInspectCloseButtonLayout()
end

local function getInputScreenPosition(input)
	local position = input.Position
	return Vector2.new(position.X, position.Y)
end

local function isPointInsideGuiObject(guiObject, position)
	if not guiObject then
		return false
	end

	local topLeft = guiObject.AbsolutePosition
	local size = guiObject.AbsoluteSize
	return position.X >= topLeft.X
		and position.X <= topLeft.X + size.X
		and position.Y >= topLeft.Y
		and position.Y <= topLeft.Y + size.Y
end

local function endInspectDrag()
	inspectDragging = false
	inspectDragInput = nil
	inspectDragStartPosition = nil
	inspectDragStartTopLeft = nil
end

local function updateInspectDrag(input)
	if not inspectDragging or not inspectLabel or not inspectDragStartPosition or not inspectDragStartTopLeft then
		return
	end
	if inspectDragInput == Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end
	if inspectDragInput == Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	local delta = getInputScreenPosition(input) - inspectDragStartPosition
	setInspectTopLeft(inspectDragStartTopLeft + delta, true)
end

local function wireInspectRepositioning()
	if not inspectLabel then
		return
	end

	inspectLabel.Active = true
	inspectLabel.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local position = getInputScreenPosition(input)
		if isPointInsideGuiObject(inspectCloseButton, position) then
			return
		end

		inspectDragging = true
		inspectDragInput = input.UserInputType
		inspectDragStartPosition = position
		inspectDragStartTopLeft = inspectLabel.AbsolutePosition
	end)

	UserInputService.InputChanged:Connect(updateInspectDrag)
	UserInputService.InputEnded:Connect(function(input)
		if not inspectDragging then
			return
		end
		if input.UserInputType == inspectDragInput
			or (inspectDragInput == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement) then
			endInspectDrag()
		end
	end)
end

local function isTouchEditLayoutActive()
	return playerGui:GetAttribute(TOUCH_EDIT_MODE_ATTRIBUTE) == true
end

local function clampGuiPosition(guiObject, position)
	if not guiObject then
		return position
	end

	local viewport = getInspectViewportSize()
	local size = guiObject.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then
		size = Vector2.new(guiObject.Size.X.Offset, guiObject.Size.Y.Offset)
	end

	local anchor = guiObject.AnchorPoint
	local margin = isPhoneProfile() and 6 or 8
	local minX = margin + size.X * anchor.X
	local minY = margin + size.Y * anchor.Y
	local maxX = math.max(minX, viewport.X - margin - size.X * (1 - anchor.X))
	local maxY = math.max(minY, viewport.Y - margin - size.Y * (1 - anchor.Y))

	local absoluteX = position.X.Scale * viewport.X + position.X.Offset
	local absoluteY = position.Y.Scale * viewport.Y + position.Y.Offset
	local clampedX = math.clamp(absoluteX, minX, maxX)
	local clampedY = math.clamp(absoluteY, minY, maxY)
	return UDim2.new(position.X.Scale, position.X.Offset + (clampedX - absoluteX), position.Y.Scale, position.Y.Offset + (clampedY - absoluteY))
end

local function applyDevManualPositions()
	if toggleButton and devToggleManualPosition then
		toggleButton.Position = clampGuiPosition(toggleButton, devToggleManualPosition)
		devToggleManualPosition = toggleButton.Position
	end
	if panel and devPanelManualPosition then
		panel.Position = clampGuiPosition(panel, devPanelManualPosition)
		devPanelManualPosition = panel.Position
	end
end

local function updateDevCoordinateLabel(label, guiObject, text)
	if not label or not guiObject then
		return
	end
	local anchorPosition = guiObject.AbsolutePosition + guiObject.AbsoluteSize * guiObject.AnchorPoint
	label.Text = ("%s  x=%d y=%d"):format(text, math.floor(anchorPosition.X + 0.5), math.floor(anchorPosition.Y + 0.5))
	label.Visible = isTouchEditLayoutActive()
end

local function updateDevCoordinateLabels()
	updateDevCoordinateLabel(devToggleCoordinateLabel, toggleButton, "DEV")
	updateDevCoordinateLabel(devPanelCoordinateLabel, panel, "DevPanel")
end

local function beginDevLayoutDrag(guiObject, input, key)
	if not isTouchEditLayoutActive() then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	devLayoutDragging = {
		Object = guiObject,
		Key = key,
		InputType = input.UserInputType,
		StartInput = getInputScreenPosition(input),
		StartPosition = guiObject.Position,
	}
	updateDevCoordinateLabels()
end

local function updateDevLayoutDrag(input)
	if not devLayoutDragging then
		return
	end
	if devLayoutDragging.InputType == Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end
	if devLayoutDragging.InputType == Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	local delta = getInputScreenPosition(input) - devLayoutDragging.StartInput
	local start = devLayoutDragging.StartPosition
	local nextPosition = UDim2.new(start.X.Scale, start.X.Offset + delta.X, start.Y.Scale, start.Y.Offset + delta.Y)
	nextPosition = clampGuiPosition(devLayoutDragging.Object, nextPosition)
	devLayoutDragging.Object.Position = nextPosition
	if devLayoutDragging.Key == "Toggle" then
		devToggleManualPosition = nextPosition
	elseif devLayoutDragging.Key == "Panel" then
		devPanelManualPosition = nextPosition
	end
	updateDevCoordinateLabels()
end

local function endDevLayoutDrag(input)
	if not devLayoutDragging then
		return
	end
	if input.UserInputType == devLayoutDragging.InputType
		or (devLayoutDragging.InputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement) then
		devLayoutDragging = nil
	end
end

local function wireDevLayoutDrag(guiObject, key)
	if not guiObject then
		return
	end
	guiObject.InputBegan:Connect(function(input)
		beginDevLayoutDrag(guiObject, input, key)
	end)
end

local function resetDevLayoutPositions()
	devToggleManualPosition = nil
	devPanelManualPosition = nil
	devLayoutDragging = nil
	inspectWindowManuallyPositioned = false
	applyDevLayout(currentDeviceProfile)
	updateDevCoordinateLabels()
end

applyDevLayout = function(profile)
	currentDeviceProfile = profile or DeviceProfile.Get()

	if not gui or not toggleButton or not panel then
		return
	end

	local viewport = currentDeviceProfile.Viewport or Vector2.new(1024, 768)
	local touchLandscape = currentDeviceProfile.IsTouch == true and viewport.X > viewport.Y
	if devInfoLabel then
		if isPhoneProfile() then
			devInfoLabel.Position = UDim2.new(touchLandscape and 0.34 or 0.5, 0, 1, touchLandscape and -82 or -96)
			devInfoLabel.Size = UDim2.new(touchLandscape and 0.38 or 0.7, 0, 0, touchLandscape and 34 or 36)
			devInfoLabel.TextScaled = false
			devInfoLabel.TextSize = touchLandscape and 13 or 16
		else
			devInfoLabel.Position = UDim2.new(0.5, 0, 1, -92)
			devInfoLabel.Size = UDim2.new(0.62, 0, 0, 52)
			devInfoLabel.TextScaled = true
		end
	end
	applyInspectLayout(touchLandscape)

	if isPhoneProfile() then
		toggleButton.AnchorPoint = Vector2.new(0, 0)
		toggleButton.Position = UDim2.new(0, touchLandscape and 34 or 20, 0, touchLandscape and 104 or 146)
		toggleButton.Size = UDim2.fromOffset(touchLandscape and 70 or 58, touchLandscape and 34 or 30)
		panel.AnchorPoint = Vector2.new(0.5, 0.5)
		panel.Position = UDim2.fromScale(touchLandscape and 0.42 or 0.5, 0.56)
		panel.Size = UDim2.new(touchLandscape and 0.68 or 0.94, 0, 0.74, 0)
		if panelConstraint then
			panelConstraint.MaxSize = Vector2.new(touchLandscape and math.max(360, viewport.X - 220) or math.max(560, viewport.X - 36), math.max(320, viewport.Y - 96))
			panelConstraint.MinSize = Vector2.new(300, 280)
		end
		if panelScroll then
			panelScroll.Position = UDim2.fromOffset(10, 64)
			panelScroll.Size = UDim2.new(1, -20, 1, -74)
			panelScroll.ScrollBarThickness = 5
		end
		applyDevManualPositions()
		updateDevCoordinateLabels()
		return
	end

	if isGamepadProfile() then
		local stackLeft = 12
		local stackTop = 12
		local stackGap = 10
		local inspectHeight = 196
		local panelTop = stackTop + inspectHeight + stackGap
		local panelHeight = math.min(500, math.max(390, viewport.Y - panelTop - stackTop))

		toggleButton.AnchorPoint = Vector2.new(0, 0)
		toggleButton.Position = UDim2.fromOffset(stackLeft + 330 + stackGap, stackTop)
		toggleButton.Size = UDim2.fromOffset(70, 34)
		panel.AnchorPoint = Vector2.new(0, 0)
		panel.Position = UDim2.fromOffset(stackLeft, panelTop)
		panel.Size = UDim2.fromOffset(330, panelHeight)
		if panelConstraint then
			panelConstraint.MaxSize = Vector2.new(360, 560)
			panelConstraint.MinSize = Vector2.new(292, 390)
		end
		if panelScroll then
			panelScroll.Position = UDim2.fromOffset(12, 70)
			panelScroll.Size = UDim2.new(1, -24, 1, -82)
			panelScroll.ScrollBarThickness = 6
		end
		applyDevManualPositions()
		updateDevCoordinateLabels()
		return
	end

	toggleButton.AnchorPoint = Vector2.new(0, 1)
	toggleButton.Position = UDim2.new(0, 12, 1, -78)
	toggleButton.Size = UDim2.fromOffset(70, 34)
	panel.AnchorPoint = Vector2.new(0, 0.5)
	panel.Position = UDim2.new(0, 12, 0.5, 0)
	panel.Size = UDim2.fromOffset(330, 500)
	if panelConstraint then
		panelConstraint.MaxSize = Vector2.new(360, 560)
		panelConstraint.MinSize = Vector2.new(292, 390)
	end
	if panelScroll then
		panelScroll.Position = UDim2.fromOffset(12, 70)
		panelScroll.Size = UDim2.new(1, -24, 1, -82)
		panelScroll.ScrollBarThickness = 6
	end
	applyDevManualPositions()
	updateDevCoordinateLabels()
end

local function makeList(parent)
	local list = Instance.new("Frame")
	list.AutomaticSize = Enum.AutomaticSize.Y
	list.BackgroundTransparency = 1
	list.Size = UDim2.new(1, 0, 0, 0)
	list.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 5)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		list.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y)
	end)

	return list
end

local function send(payload)
	if authorized and typeof(payload) == "table" then
		devRemote:FireServer(payload)
	end
end

local function getMainUi()
	return playerGui:FindFirstChild(UiLayerController.GuiNames.DiscoveryUI)
end

local function waitForMainUi(timeoutSeconds)
	local mainGui = getMainUi()
	if mainGui then
		return mainGui
	end

	mainGui = playerGui:WaitForChild(UiLayerController.GuiNames.DiscoveryUI, timeoutSeconds)
	if mainGui and mainGui:IsA("ScreenGui") then
		return mainGui
	end

	return nil
end

local function setDevUiAttribute(attributeName, value)
	playerGui:SetAttribute(attributeName, value)

	local mainGui = getMainUi()
	if mainGui then
		mainGui:SetAttribute(attributeName, value)
	end
end

if playerGui:GetAttribute(DEV_TITLE_SEQUENCE_ENABLED_ATTRIBUTE) == nil then
	playerGui:SetAttribute(DEV_TITLE_SEQUENCE_ENABLED_ATTRIBUTE, true)
end

local function isTitleSequenceEnabledForDev()
	local value = playerGui:GetAttribute(DEV_TITLE_SEQUENCE_ENABLED_ATTRIBUTE)
	if value ~= nil then
		return value ~= false
	end

	local mainGui = getMainUi()
	if mainGui then
		local mainValue = mainGui:GetAttribute(DEV_TITLE_SEQUENCE_ENABLED_ATTRIBUTE)
		if mainValue ~= nil then
			return mainValue ~= false
		end
	end

	return true
end

local function dismissStartOverlayForDevSession(force)
	if not force and isTitleSequenceEnabledForDev() then
		return false
	end

	setDevUiAttribute(DEV_DISMISS_START_ATTRIBUTE, true)

	local mainGui = getMainUi()
	local startOverlay = mainGui and mainGui:FindFirstChild("StartChoiceOverlay")
	if startOverlay and startOverlay:IsA("GuiObject") then
		startOverlay.Visible = false
	end

	return true
end

local function setTitleSequenceEnabledForDev(enabled)
	enabled = enabled == true
	setDevUiAttribute(DEV_TITLE_SEQUENCE_ENABLED_ATTRIBUTE, enabled)

	if enabled then
		setDevUiAttribute(DEV_DISMISS_START_ATTRIBUTE, false)
		if showDevInfo then
			showDevInfo("Title sequence ON. Dev tools will not bypass the start intro.", 5)
		end
	else
		dismissStartOverlayForDevSession(true)
		if showDevInfo then
			showDevInfo("Title sequence OFF. Dev tools will bypass the start intro.", 5)
		end
	end
end

local function getShowTitleSequenceNonce()
	local nonce = tonumber(playerGui:GetAttribute(DEV_SHOW_TITLE_SEQUENCE_NONCE_ATTRIBUTE)) or 0
	local mainGui = getMainUi()
	if mainGui then
		nonce = math.max(nonce, tonumber(mainGui:GetAttribute(DEV_SHOW_TITLE_SEQUENCE_NONCE_ATTRIBUTE)) or 0)
	end

	return nonce
end

local function showEmergencyTitleOverlay()
	local existing = playerGui:FindFirstChild("DontTouchItDevTitleOverlay")
	if existing then
		existing:Destroy()
	end

	local overlayGui = Instance.new("ScreenGui")
	overlayGui.Name = "DontTouchItDevTitleOverlay"
	overlayGui.DisplayOrder = UiLayerController.DisplayOrder.Emergency
	overlayGui.IgnoreGuiInset = false
	overlayGui.ResetOnSpawn = false
	overlayGui.Parent = playerGui

	pcall(function()
		overlayGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	end)

	local root = Instance.new("TextButton")
	root.Name = "OverlayRoot"
	root.AutoButtonColor = false
	root.BackgroundColor3 = Color3.fromRGB(6, 8, 12)
	root.BackgroundTransparency = 0.08
	root.BorderSizePixel = 0
	root.Modal = true
	root.Size = UDim2.fromScale(1, 1)
	root.Text = ""
	root.Parent = overlayGui

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.Position = UDim2.fromScale(0.5, 0.42)
	titleLabel.Size = UDim2.new(0.9, 0, 0, 72)
	titleLabel.Text = "DON'T TOUCH IT"
	titleLabel.TextColor3 = Color3.fromRGB(255, 242, 181)
	titleLabel.TextScaled = true
	titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	titleLabel.TextStrokeTransparency = 0.22
	titleLabel.TextWrapped = true
	titleLabel.Parent = root

	local statusText = Instance.new("TextLabel")
	statusText.Name = "Status"
	statusText.AnchorPoint = Vector2.new(0.5, 0.5)
	statusText.BackgroundTransparency = 1
	statusText.Font = Enum.Font.GothamSemibold
	statusText.Position = UDim2.fromScale(0.5, 0.56)
	statusText.Size = UDim2.new(0.82, 0, 0, 44)
	statusText.Text = "Dev title overlay\nv" .. tostring(Constants.BuildVersion or "?")
	statusText.TextColor3 = Color3.fromRGB(206, 222, 238)
	statusText.TextScaled = true
	statusText.TextWrapped = true
	statusText.Parent = root

	local prompt = Instance.new("TextLabel")
	prompt.Name = "Prompt"
	prompt.AnchorPoint = Vector2.new(0.5, 0.5)
	prompt.BackgroundTransparency = 1
	prompt.Font = Enum.Font.GothamBold
	prompt.Position = UDim2.fromScale(0.5, 0.76)
	prompt.Size = UDim2.new(0.82, 0, 0, 30)
	prompt.Text = "Tap, click, or press any button to close"
	prompt.TextColor3 = Color3.fromRGB(174, 190, 210)
	prompt.TextScaled = true
	prompt.TextWrapped = true
	prompt.Parent = root

	local closed = false
	local inputConnection = nil
	local function closeOverlay()
		if closed then
			return
		end
		closed = true
		if inputConnection then
			inputConnection:Disconnect()
		end
		if overlayGui.Parent then
			overlayGui:Destroy()
		end
	end

	root.Activated:Connect(closeOverlay)
	inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.UserInputType == Enum.UserInputType.Keyboard
			or input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.Gamepad1
		then
			closeOverlay()
		end
	end)
end

local function showTitleSequenceNowForDev()
	showEmergencyTitleOverlay()
	setDevUiAttribute(DEV_TITLE_SEQUENCE_ENABLED_ATTRIBUTE, true)
	setDevUiAttribute(DEV_DISMISS_START_ATTRIBUTE, false)
	local nextNonce = getShowTitleSequenceNonce() + 1
	playerGui:SetAttribute(DEV_SHOW_TITLE_SEQUENCE_NONCE_ATTRIBUTE, nextNonce)
	local mainGui = waitForMainUi(2)
	if mainGui then
		mainGui:SetAttribute(DEV_TITLE_SEQUENCE_ENABLED_ATTRIBUTE, true)
		mainGui:SetAttribute(DEV_DISMISS_START_ATTRIBUTE, false)
		mainGui:SetAttribute(DEV_SHOW_TITLE_SEQUENCE_NONCE_ATTRIBUTE, nextNonce)
	end
	clearPanelSelection()
	if panel then
		panel.Visible = false
	end
	if showDevInfo then
		showDevInfo("Title sequence requested. First action opens the start menu.", 5)
	end
end

local function getSnapshotUnlockedById(snapshot)
	local unlockedById = {}

	if typeof(snapshot) ~= "table" or typeof(snapshot.Discoveries) ~= "table" then
		return unlockedById
	end

	for _, discovery in ipairs(snapshot.Discoveries) do
		if discovery.Unlocked then
			unlockedById[discovery.Id] = true
		end
	end

	return unlockedById
end

local function getRoomDiscoveryIds(roomId)
	local room = Constants.GetRoom(roomId)
	local ids = {}

	if room then
		for _, discoveryId in ipairs(room.DiscoveryOrder or {}) do
			table.insert(ids, discoveryId)
		end
	end

	for _, discoveryId in ipairs(Constants.SecretDiscoveryOrderByRoom[roomId] or {}) do
		table.insert(ids, discoveryId)
	end

	return ids
end

local function getRootPart()
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

local function formatNumber(value)
	return string.format("%.1f", value)
end

local function formatVector3(value)
	return ("%s, %s, %s"):format(formatNumber(value.X), formatNumber(value.Y), formatNumber(value.Z))
end

local function formatHeading(rootPart)
	if not rootPart then
		return "-"
	end

	local lookVector = rootPart.CFrame.LookVector
	local degrees = (math.deg(math.atan2(lookVector.X, -lookVector.Z)) + 360) % 360
	local roundedDegrees = math.floor(degrees + 0.5) % 360
	local headings = {
		"N",
		"NE",
		"E",
		"SE",
		"S",
		"SW",
		"W",
		"NW",
	}
	local headingIndex = (math.floor((roundedDegrees + 22.5) / 45) % #headings) + 1
	return ("%s %03d°"):format(headings[headingIndex], roundedDegrees)
end

local function formatPlayerLocation(rootPart)
	if not rootPart then
		return "- | H -\nHeading: -"
	end

	return ("%s | H %s\nHeading: %s"):format(formatVector3(rootPart.Position), formatNumber(rootPart.Position.Y), formatHeading(rootPart))
end

local function formatAttributeValue(value)
	local valueType = typeof(value)
	if valueType == "Vector3" then
		return ("(%s)"):format(formatVector3(value))
	elseif valueType == "CFrame" then
		return ("CFrame(%s)"):format(formatVector3(value.Position))
	elseif valueType == "Color3" then
		return ("Color3(%d,%d,%d)"):format(math.floor(value.R * 255), math.floor(value.G * 255), math.floor(value.B * 255))
	end

	return tostring(value)
end

local function getInstancePath(instance)
	local names = {}
	local current = instance
	while current and current ~= game do
		table.insert(names, 1, current.Name)
		current = current.Parent
	end

	return table.concat(names, ".")
end

local function getUsefulAttributes(instance)
	local rows = {}
	local attributes = instance:GetAttributes()
	local preferredKeys = {
		"RoomId",
		"DiscoveryId",
		"DestinationCFrame",
		"PrologueDescription",
		"ProloguePriority",
		"PrologueInspectIgnore",
		"BaseCanCollide",
		"BaseTransparency",
	}
	local used = {}

	for _, key in ipairs(preferredKeys) do
		if attributes[key] ~= nil then
			used[key] = true
			table.insert(rows, ("%s=%s"):format(key, formatAttributeValue(attributes[key])))
		end
	end

	for key, value in pairs(attributes) do
		if not used[key] and #rows < 6 then
			table.insert(rows, ("%s=%s"):format(key, formatAttributeValue(value)))
		end
	end

	if #rows == 0 then
		return "-"
	end

	return table.concat(rows, "\n")
end

local function getInspectRaycastParams()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude = {}
	if player.Character then
		table.insert(exclude, player.Character)
	end
	params.FilterDescendantsInstances = exclude
	return params, exclude
end

local function getInspectIgnoredRoot(instance)
	local current = instance
	while current and current ~= Workspace do
		if current:GetAttribute("PrologueInspectIgnore") == true
			or current.Name == "LocalPrologueFlashlight"
			or current.Name == "LocalPrologueFlashlightBeam"
			or current.Name == "LocalPrologueFlashlightSpot" then
			return current
		end
		current = current.Parent
	end

	return nil
end

local function getInspectRaycastResult(camera)
	local direction = camera.CFrame.LookVector
	local origin = camera.CFrame.Position
	local remaining = INSPECT_RANGE
	local params, exclude = getInspectRaycastParams()

	for _ = 1, MAX_INSPECT_RAYCAST_SKIPS do
		local result = Workspace:Raycast(origin, direction * remaining, params)
		if not result or not result.Instance then
			return nil
		end

		local ignoredRoot = getInspectIgnoredRoot(result.Instance)
		if not ignoredRoot then
			return result
		end

		table.insert(exclude, ignoredRoot)
		params.FilterDescendantsInstances = exclude
		local traveled = (result.Position - origin).Magnitude + INSPECT_SKIP_EPSILON
		origin = result.Position + direction * INSPECT_SKIP_EPSILON
		remaining = remaining - traveled
		if remaining <= 0 then
			return nil
		end
	end

	return nil
end

local function setInspectTarget(instance)
	if not inspectHighlight then
		inspectHighlight = Instance.new("Highlight")
		inspectHighlight.Name = "DontTouchItDevInspectHighlight"
		inspectHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		inspectHighlight.FillColor = Color3.fromRGB(85, 217, 255)
		inspectHighlight.FillTransparency = 0.82
		inspectHighlight.OutlineColor = Color3.fromRGB(154, 255, 255)
		inspectHighlight.OutlineTransparency = 0
		inspectHighlight.Parent = Workspace
	end

	inspectHighlight.Enabled = inspectEnabled and instance ~= nil
	inspectHighlight.Adornee = instance
end

local function updateInspectReadout()
	if not inspectEnabled or not inspectLabel then
		return
	end

	local rootPart = getRootPart()
	local playerPositionText = formatPlayerLocation(rootPart)
	local camera = Workspace.CurrentCamera
	if not camera then
		inspectLabel.Text = ("DEV INSPECT\nPlayer: %s\nNo camera"):format(playerPositionText)
		setInspectTarget(nil)
		return
	end

	local result = getInspectRaycastResult(camera)
	if not result or not result.Instance then
		inspectLabel.Text = ("DEV INSPECT\nPlayer: %s\nNo part under reticle."):format(playerPositionText)
		setInspectTarget(nil)
		return
	end

	local instance = result.Instance
	setInspectTarget(instance)
	local tags = CollectionService:GetTags(instance)
	local tagText = if #tags > 0 then table.concat(tags, ", ") else "-"
	local positionText = if instance:IsA("BasePart") then formatVector3(instance.Position) else "-"
	local sizeText = if instance:IsA("BasePart") then formatVector3(instance.Size) else "-"
	local collisionText = if instance:IsA("BasePart") then tostring(instance.CanCollide) else "-"
	local transparencyText = if instance:IsA("BasePart") then string.format("%.2f", instance.Transparency) else "-"

	inspectLabel.Text = ("DEV INSPECT\nPlayer: %s\nName: %s\nClass: %s\nPath: %s\nPos: %s\nSize: %s\nCollide: %s  Trans: %s\nTags: %s\nAttrs:\n%s"):format(
		playerPositionText,
		instance.Name,
		instance.ClassName,
		getInstancePath(instance),
		positionText,
		sizeText,
		collisionText,
		transparencyText,
		tagText,
		getUsefulAttributes(instance)
	)
end

local function setInspectState(enabled)
	inspectEnabled = enabled == true
	if inspectLabel then
		inspectLabel.Visible = inspectEnabled
	end
	if inspectCloseButton then
		inspectCloseButton.Visible = inspectEnabled
	end
	if inspectHighlight then
		inspectHighlight.Enabled = inspectEnabled and inspectHighlight.Adornee ~= nil
	end

	if inspectEnabled then
		showDevInfo("Dev inspect ON. Aim the center reticle at a part to see its name, path, tags, and attributes.", 9)
		updateInspectReadout()
	else
		showDevInfo("Dev inspect OFF.", 4)
		setInspectTarget(nil)
	end
end

showDevInfo = function(text, durationSeconds)
	if not devInfoLabel or typeof(text) ~= "string" or text == "" then
		return
	end

	devInfoToken += 1
	local token = devInfoToken
	devInfoLabel.Text = text
	devInfoLabel.Visible = true

	task.delay(durationSeconds or 12, function()
		if token == devInfoToken and devInfoLabel then
			devInfoLabel.Visible = false
		end
	end)
end

local function getIdLabelFolder()
	if not gui or not gui.Enabled then
		return nil
	end

	if idLabelFolder and idLabelFolder.Parent then
		return idLabelFolder
	end

	local legacyFolder = gui:FindFirstChild("DevIdLabels")
	if legacyFolder and legacyFolder:IsA("Folder") then
		legacyFolder:ClearAllChildren()
		legacyFolder:Destroy()
	end

	local existingFolder = playerGui:FindFirstChild(ID_LABEL_FOLDER_NAME)
	if existingFolder and existingFolder:IsA("Folder") then
		idLabelFolder = existingFolder
	else
		idLabelFolder = Instance.new("Folder")
		idLabelFolder.Name = ID_LABEL_FOLDER_NAME
		idLabelFolder.Parent = playerGui
	end

	return idLabelFolder
end

local function clearIdLabels()
	if idLabelFolder then
		idLabelFolder:ClearAllChildren()
	end
end

local function shouldIgnoreForIdLabels(instance)
	local current = instance
	while current and current ~= Workspace do
		if current:GetAttribute("PrologueInspectIgnore") == true
			or current:GetAttribute("DevIdIgnore") == true
			or current.Name == "DontTouchItDevInspectHighlight" then
			return true
		end
		current = current.Parent
	end

	return false
end

local function makeIdLabel(part, index)
	local folder = getIdLabelFolder()
	if not folder then
		return
	end

	local label = Instance.new("BillboardGui")
	label.Name = "DevIdLabel_" .. tostring(index)
	label.Adornee = part
	label.AlwaysOnTop = true
	label.LightInfluence = 0
	label.MaxDistance = 140
	label.Size = UDim2.fromOffset(isPhoneProfile() and 132 or 180, isPhoneProfile() and 32 or 38)
	label.StudsOffsetWorldSpace = Vector3.new(0, math.max(2.1, part.Size.Y * 0.5 + 0.65), 0)
	label.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	label.Parent = folder

	local text = Instance.new("TextLabel")
	text.BackgroundColor3 = Color3.fromRGB(8, 11, 16)
	text.BackgroundTransparency = 0.08
	text.BorderSizePixel = 0
	text.Font = Enum.Font.Code
	text.Size = UDim2.fromScale(1, 1)
	text.Text = ("%02d %s\n%s"):format(index, part.Name, formatVector3(part.Position))
	text.TextColor3 = Color3.fromRGB(188, 246, 255)
	text.TextSize = isPhoneProfile() and 7 or 9
	text.TextWrapped = true
	text.Parent = label
	makeCorner(text, 4)
end

local function updateIdLabels(force)
	if not idLabelsEnabled then
		return
	end

	if not gui or not gui.Enabled then
		clearIdLabels()
		return
	end

	local now = os.clock()
	if not force and now - lastIdLabelsUpdateAt < ID_LABEL_UPDATE_INTERVAL then
		return
	end
	lastIdLabelsUpdateAt = now
	clearIdLabels()

	local rootPart = getRootPart()
	local camera = Workspace.CurrentCamera
	local origin = rootPart and rootPart.Position or (camera and camera.CFrame.Position)
	if not origin then
		return
	end

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = if player.Character then { player.Character } else {}

	local parts = Workspace:GetPartBoundsInRadius(origin, ID_LABEL_RANGE, params)
	local candidates = {}
	for _, part in ipairs(parts) do
		if part:IsA("BasePart")
			and part.Transparency < 0.98
			and part.Name ~= "Terrain"
			and not shouldIgnoreForIdLabels(part) then
			table.insert(candidates, {
				Part = part,
				Distance = (part.Position - origin).Magnitude,
			})
		end
	end

	table.sort(candidates, function(a, b)
		return a.Distance < b.Distance
	end)

	for index = 1, math.min(ID_LABEL_MAX_PARTS, #candidates) do
		makeIdLabel(candidates[index].Part, index)
	end
end

local function setIdLabelsState(enabled)
	idLabelsEnabled = enabled == true
	if idLabelsEnabled then
		showDevInfo("ID labels ON. Nearby generated parts now show small names and positions for screenshots.", 7)
		updateIdLabels(true)
	else
		showDevInfo("ID labels OFF.", 4)
		clearIdLabels()
	end
end

local function getFlightControlsText()
	local profile = DeviceProfile.Get()
	currentDeviceProfile = profile

	if profile.IsGamepad then
		return "Dev fly ON. Xbox: left stick flies, right stick looks, A climbs, X or B descends. The dev panel closes so the stick controls you."
	end

	if profile.IsTouch then
		return "Dev fly ON. Touch: left thumbstick flies, drag to look, UP climbs, DN descends."
	end

	return "Dev fly ON. Keyboard/mouse: WASD moves with the camera, Space or E climbs, Ctrl or Q descends. Mouse aims."
end

local function getPrimaryGamepad()
	local gamepads = UserInputService:GetConnectedGamepads()
	if #gamepads > 0 then
		return gamepads[1]
	end

	return Enum.UserInputType.Gamepad1
end

local function getGamepadThumbstick()
	if not UserInputService.GamepadEnabled then
		return Vector2.zero
	end

	local ok, states = pcall(function()
		return UserInputService:GetGamepadState(getPrimaryGamepad())
	end)
	if not ok then
		return Vector2.zero
	end

	for _, input in ipairs(states) do
		if input.KeyCode == Enum.KeyCode.Thumbstick1 then
			local position = input.Position
			return Vector2.new(position.X, position.Y)
		end
	end

	return Vector2.zero
end

local function isFlyDescendPressed()
	return pressedKeys[Enum.KeyCode.LeftControl]
		or pressedKeys[Enum.KeyCode.Q]
		or pressedKeys[Enum.KeyCode.ButtonX]
		or pressedKeys[Enum.KeyCode.ButtonB]
		or pressedKeys[Enum.KeyCode.DPadDown]
		or flyTouchDownPressed
end

local function isFlyAscendPressed()
	return pressedKeys[Enum.KeyCode.Space]
		or pressedKeys[Enum.KeyCode.E]
		or pressedKeys[Enum.KeyCode.ButtonA]
		or pressedKeys[Enum.KeyCode.DPadUp]
		or flyTouchUpPressed
end

local function isAirborneForDoubleJump()
	if flyEnabled then
		return true
	end

	local humanoid = getHumanoid()
	if not humanoid then
		return false
	end

	local state = humanoid:GetState()
	return state == Enum.HumanoidStateType.Jumping
		or state == Enum.HumanoidStateType.Freefall
		or state == Enum.HumanoidStateType.FallingDown
end

local function requestDevFlyFromDoubleJump()
	local now = os.clock()
	local delta = now - lastJumpRequestAt
	lastJumpRequestAt = now

	if not authorized then
		return
	end
	if delta < DOUBLE_JUMP_MIN_SECONDS or delta > DOUBLE_JUMP_MAX_SECONDS then
		return
	end
	if now - lastDoubleJumpFlyRequestAt < DOUBLE_JUMP_FLY_COOLDOWN_SECONDS then
		return
	end
	if not isAirborneForDoubleJump() then
		return
	end

	lastDoubleJumpFlyRequestAt = now
	local nextFlyEnabled = not flyEnabled
	send({
		Action = "SetMovement",
		Fly = nextFlyEnabled,
		Noclip = noclipEnabled,
	})
	showDevInfo(if nextFlyEnabled then "Double jump detected. Dev fly requested." else "Double jump detected. Dev fly stop requested.", 4)
end

local function isJumpLikeInput(input)
	return input.KeyCode == Enum.KeyCode.Space
		or input.KeyCode == Enum.KeyCode.ButtonA
end

local function setCharacterCollision(enabled)
	local character = player.Character
	if not character then
		return
	end

	for _, instance in ipairs(character:GetDescendants()) do
		if instance:IsA("BasePart") then
			instance.CanCollide = enabled
		end
	end
end

local function destroyFlyObjects()
	if flyVelocity then
		flyVelocity:Destroy()
		flyVelocity = nil
	end

	if flyGyro then
		flyGyro:Destroy()
		flyGyro = nil
	end
end

local function destroyFlyTouchButtons()
	flyTouchUpPressed = false
	flyTouchDownPressed = false
	if flyTouchGui then
		flyTouchGui:Destroy()
		flyTouchGui = nil
	end
end

local function makeFlyTouchButton(parent, name, text, position, began, ended)
	local button = Instance.new("TextButton")
	button.Name = name
	button.AnchorPoint = Vector2.new(1, 1)
	button.BackgroundColor3 = Color3.fromRGB(18, 23, 29)
	button.BackgroundTransparency = 0.12
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBlack
	button.Position = position
	button.Size = UDim2.fromOffset(64, 48)
	button.Text = text
	button.TextColor3 = Color3.fromRGB(226, 245, 255)
	button.TextScaled = true
	button.TextStrokeTransparency = 0.35
	button.ZIndex = 16
	button.Parent = parent
	makeCorner(button, 8)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(119, 255, 203)
	stroke.Thickness = 1.2
	stroke.Transparency = 0.25
	stroke.Parent = button
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			began()
		end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			ended()
		end
	end)
	return button
end

local function ensureFlyTouchButtons()
	if not UserInputService.TouchEnabled or flyTouchGui then
		return
	end
	flyTouchGui = Instance.new("ScreenGui")
	flyTouchGui.Name = "DontTouchItDevFlyTouchControls"
	flyTouchGui.ResetOnSpawn = false
	flyTouchGui.IgnoreGuiInset = true
	flyTouchGui.DisplayOrder = UiLayerController.DisplayOrder.DevFlyControls
	flyTouchGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	flyTouchGui.Parent = playerGui
	makeFlyTouchButton(flyTouchGui, "DevFlyUp", "UP", UDim2.new(1, -24, 1, -196), function()
		flyTouchUpPressed = true
	end, function()
		flyTouchUpPressed = false
	end)
	makeFlyTouchButton(flyTouchGui, "DevFlyDown", "DN", UDim2.new(1, -24, 1, -132), function()
		flyTouchDownPressed = true
	end, function()
		flyTouchDownPressed = false
	end)
end

local function updateFlyObjects()
	local rootPart = getRootPart()
	if not rootPart then
		destroyFlyObjects()
		return
	end

	if not flyVelocity then
		flyVelocity = Instance.new("BodyVelocity")
		flyVelocity.Name = "DevFlyVelocity"
		flyVelocity.MaxForce = Vector3.new(1, 1, 1) * 100000
		flyVelocity.P = 1800
		flyVelocity.Parent = rootPart
	end

	if not flyGyro then
		flyGyro = Instance.new("BodyGyro")
		flyGyro.Name = "DevFlyGyro"
		flyGyro.MaxTorque = Vector3.new(1, 1, 1) * 100000
		flyGyro.P = 8000
		flyGyro.Parent = rootPart
	end
end

local function setMovementState(fly, noclip)
	local wasFlyEnabled = flyEnabled
	flyEnabled = fly == true
	noclipEnabled = noclip == true

	if flyEnabled and not wasFlyEnabled then
		if panel then
			clearPanelSelection()
			panel.Visible = false
		end
		showDevInfo(getFlightControlsText(), 14)
	elseif not flyEnabled and wasFlyEnabled then
		showDevInfo("Dev fly OFF. Character movement is back to normal.", 5)
	end

	if not flyEnabled then
		destroyFlyObjects()
		destroyFlyTouchButtons()
	elseif flyEnabled then
		ensureFlyTouchButtons()
	end

	if not noclipEnabled then
		setCharacterCollision(true)
	end
end

local function connectMovementLoops()
	if #flyConnections > 0 then
		return
	end

	table.insert(flyConnections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if UserInputService:GetFocusedTextBox() then
			return
		end
		if gameProcessed and input.UserInputType ~= Enum.UserInputType.Gamepad1 then
			return
		end

		pressedKeys[input.KeyCode] = true

		if flyEnabled and isJumpLikeInput(input) then
			requestDevFlyFromDoubleJump()
		end
	end))

	table.insert(flyConnections, UserInputService.InputEnded:Connect(function(input)
		pressedKeys[input.KeyCode] = nil
	end))

	table.insert(flyConnections, UserInputService.JumpRequest:Connect(function()
		if UserInputService:GetFocusedTextBox() then
			return
		end

		requestDevFlyFromDoubleJump()
	end))

	table.insert(flyConnections, RunService.Stepped:Connect(function()
		if noclipEnabled then
			setCharacterCollision(false)
		end
	end))

	table.insert(flyConnections, RunService.RenderStepped:Connect(function()
		if not flyEnabled then
			return
		end

		updateFlyObjects()
		if not flyVelocity or not flyGyro then
			return
		end

		local camera = Workspace.CurrentCamera
		local look = camera and camera.CFrame.LookVector or Vector3.new(0, 0, -1)
		local right = camera and camera.CFrame.RightVector or Vector3.new(1, 0, 0)
		local direction = Vector3.zero

		if pressedKeys[Enum.KeyCode.W] then
			direction += look
		end
		if pressedKeys[Enum.KeyCode.S] then
			direction -= look
		end
		if pressedKeys[Enum.KeyCode.D] then
			direction += right
		end
		if pressedKeys[Enum.KeyCode.A] then
			direction -= right
		end

		local stick = getGamepadThumbstick()
		if math.abs(stick.X) >= GAMEPAD_STICK_DEADZONE then
			direction += right * stick.X
		end
		if math.abs(stick.Y) >= GAMEPAD_STICK_DEADZONE then
			direction += look * stick.Y
		end
		if UserInputService.TouchEnabled then
			local touchMoveDirection = FlightInput.GetCameraRelativeMoveDirection(true)
			if touchMoveDirection.Magnitude >= GAMEPAD_STICK_DEADZONE then
				direction += touchMoveDirection
			end
		end

		if isFlyAscendPressed() then
			direction += Vector3.yAxis
		end
		if isFlyDescendPressed() then
			direction -= Vector3.yAxis
		end

		if direction.Magnitude > 0 then
			direction = direction.Unit
		end

		flyVelocity.Velocity = direction * FLY_SPEED
		flyGyro.CFrame = camera and camera.CFrame or flyGyro.CFrame
	end))

	table.insert(flyConnections, RunService.RenderStepped:Connect(function()
		if inspectEnabled then
			updateInspectReadout()
		end
		if idLabelsEnabled then
			updateIdLabels(false)
		end
	end))
end

local function updateStatus()
	if not statusLabel then
		return
	end

	local room = selectedRoomId and Constants.GetRoom(selectedRoomId)
	local sessionText = latestState and latestState.DevSessionActive and "session override ON" or "real progress visible"
	statusLabel.Text = ("%s | %s"):format(room and room.Name or "No room", sessionText)
end

local function rebuildDiscoveries()
	clearList(discoveryList)

	if not latestState or not selectedRoomId or not discoveryList then
		return
	end

	local discoveryIds = getRoomDiscoveryIds(selectedRoomId)
	if not makeCollapseHeader(discoveryList, "RoomLogOverrides", "Room Log Overrides", #discoveryIds) then
		return
	end

	local unlockedById = getSnapshotUnlockedById(latestState.RoomSnapshot)

	for _, discoveryId in ipairs(discoveryIds) do
		local discovery = Constants.GetDiscovery(discoveryId)
		if discovery then
			local unlocked = unlockedById[discoveryId] == true
			local prefix = unlocked and "[x] " or "[ ] "
			makeButton(discoveryList, prefix .. discovery.Name, unlocked and Color3.fromRGB(36, 82, 50) or Color3.fromRGB(50, 55, 66), function()
				send({
					Action = "SetDiscovery",
					RoomId = selectedRoomId,
					DiscoveryId = discoveryId,
					Completed = not unlocked,
				})
			end)
		end
	end
end

local function rebuildStorePrices()
	clearList(storeList)

	if not storeList or not latestState then
		return
	end

	local prices = latestState.StorePrices or Constants.NoTouch
	local priceRows = {
		{
			Key = "HintPackRobux",
			Label = "Hint Pack R$",
		},
		{
			Key = "ClueRobux",
			Label = "Clue R$",
		},
		{
			Key = "RevealRobux",
			Label = "Reveal R$",
		},
		{
			Key = "ClueHintCost",
			Label = "Clue hint cost",
		},
		{
			Key = "RevealClueCost",
			Label = "Reveal clue cost",
		},
		{
			Key = "SecretKeyClueCost",
			Label = "Secret key clue cost",
		},
		{
			Key = "TeleportKeyClueCost",
			Label = "Teleport key clue cost",
		},
		{
			Key = "TeleportKeyRobux",
			Label = "Teleport key R$",
		},
		{
			Key = "DuckFounderRobux",
			Label = "Duck founder R$",
		},
		{
			Key = "VictoryBrickRobux",
			Label = "Victory brick R$",
		},
	}

	if not makeCollapseHeader(storeList, "StorePrices", "Store Prices", (#priceRows * 2) + 1) then
		return
	end

	for _, row in ipairs(priceRows) do
		local value = prices[row.Key] or 0
		makeButton(storeList, ("%s: %d  +"):format(row.Label, value), Color3.fromRGB(52, 83, 70), function()
			send({
				Action = "AdjustStorePrice",
				Key = row.Key,
				Delta = 1,
			})
		end)
		makeButton(storeList, ("%s: %d  -"):format(row.Label, value), Color3.fromRGB(82, 61, 55), function()
			send({
				Action = "AdjustStorePrice",
				Key = row.Key,
				Delta = -1,
			})
		end)
	end
	makeButton(storeList, "Reset Store Prices", Color3.fromRGB(116, 48, 52), function()
		send({
			Action = "ResetStorePrices",
		})
	end)
end

local function sendUserAction(payload)
	pendingAdminActionKey = nil
	send(payload)
end

local function getSelectedManagedUser()
	local userManagement = latestState and latestState.UserManagement
	return userManagement and userManagement.SelectedUser or nil
end

local function rebuildUserManagement()
	clearList(userList)
	clearList(userManagementList)

	if not latestState or not userList or not userManagementList then
		return
	end

	if not hasAnyCapability({
		"ROLE_MANAGEMENT",
		"TEST_BUILD_ACCESS_MANAGEMENT",
		"MOD_WARN_PLAYER",
		"MOD_BAN_24H",
		"MOD_VIEW_HISTORY",
		"MOD_REMOVE_BAN",
	}) then
		return
	end

	local userManagement = latestState.UserManagement or {}
	local livePlayers = userManagement.LivePlayers or {}
	if makeCollapseHeader(userList, "UserManagement", "User Management", #livePlayers) then
		makeSection(userList, "Manual Lookup")
		manualLookupBox = makeTextBox(userList, "Roblox username", manualLookupBox and manualLookupBox.Text or "", function() end)
		makeButton(userList, "Look Up Username", Color3.fromRGB(47, 85, 102), function()
			selectedManagedUserId = nil
			pendingAdminActionKey = nil
			send({
				Action = "LookupManagedUser",
				Username = manualLookupBox and manualLookupBox.Text or "",
			})
		end)
		makeButton(userList, "Refresh User List", Color3.fromRGB(45, 52, 64), function()
			send({
				Action = "RefreshUserManagement",
			})
		end)

		makeSection(userList, "Live Players")
		for _, summary in ipairs(livePlayers) do
			local moderation = summary.Moderation or {}
			local selected = selectedManagedUserId == summary.UserId
			local text = ("%s%s\n@%s | %d | %s | Test %s | %s"):format(
				selected and "> " or "",
				summary.DisplayName or summary.Username or "Player",
				summary.Username or "unknown",
				summary.UserId or 0,
				summary.Role or "Player",
				summary.TestBuildAccess and "ON" or "OFF",
				moderation.Status or "Normal"
			)
			makeButton(userList, text, selected and Color3.fromRGB(54, 90, 124) or Color3.fromRGB(45, 52, 64), function()
				selectedManagedUserId = summary.UserId
				pendingAdminActionKey = nil
				send({
					Action = "SelectManagedUser",
					TargetUserId = summary.UserId,
				})
			end)
		end
	end

	local selected = getSelectedManagedUser()
	if not selected then
		return
	end

	selectedManagedUserId = selected.UserId
	local moderation = selected.Moderation or {}
	local activeBan = moderation.ActiveBan
	local onlineText = selected.Online and "ONLINE" or "PLAYER OFFLINE"
	makeSection(userManagementList, "Player Management")
	makeInfoText(
		userManagementList,
		("%s\nDisplay: %s\nUsername: @%s\nUserId: %d\nRole: %s | Test Access: %s\nModeration: %s | Warnings: %d"):format(
			onlineText,
			selected.DisplayName or selected.Username or "Unknown",
			selected.Username or "unknown",
			selected.UserId or 0,
			selected.Role or "Player",
			selected.TestBuildAccess and "Enabled" or "Disabled",
			moderation.Status or "Normal",
			moderation.WarningCount or 0
		),
		isPhoneProfile() and 86 or 102
	)

	if hasCapability("ROLE_MANAGEMENT") then
		makeSection(userManagementList, "Role / Access")
		for _, role in ipairs((latestState.UserManagement and latestState.UserManagement.RoleOrder) or Constants.AdminRoleOrder or {}) do
			makeConfirmableButton(userManagementList, ("role:%d:%s"):format(selected.UserId, role), ("Set %s"):format(role), ("CONFIRM Set %s"):format(role), Color3.fromRGB(52, 83, 70), function()
				sendUserAction({
					Action = "SetManagedUserRole",
					TargetUserId = selected.UserId,
					Role = role,
				})
			end)
		end
	end

	if hasCapability("TEST_BUILD_ACCESS_MANAGEMENT") then
		makeConfirmableButton(
			userManagementList,
			("test:%d:%s"):format(selected.UserId, tostring(not selected.TestBuildAccess)),
			selected.TestBuildAccess and "Disable Test Access" or "Enable Test Access",
			selected.TestBuildAccess and "CONFIRM Disable Test Access" or "CONFIRM Enable Test Access",
			selected.TestBuildAccess and Color3.fromRGB(116, 48, 52) or Color3.fromRGB(38, 113, 96),
			function()
				sendUserAction({
					Action = "SetManagedUserTestAccess",
					TargetUserId = selected.UserId,
					Enabled = not selected.TestBuildAccess,
				})
			end
		)
	end

	if hasAnyCapability({ "MOD_WARN_PLAYER", "MOD_BAN_24H", "MOD_VIEW_HISTORY", "MOD_REMOVE_BAN" }) then
		makeSection(userManagementList, "Moderation")
		makeButton(userManagementList, ("Reason: %s"):format(getModerationReasonLabel(selectedModerationReasonCode)), Color3.fromRGB(64, 70, 82), function()
			selectedModerationReasonCode = getNextModerationReason(selectedModerationReasonCode)
			pendingAdminActionKey = nil
			rebuildPanel()
		end)
		makeTextBox(userManagementList, "Optional details / required for Other", moderationReasonText, function(text)
			moderationReasonText = text
		end)
	end

	if hasCapability("MOD_WARN_PLAYER") then
		makeConfirmableButton(userManagementList, ("warn:%d"):format(selected.UserId), "Warn Player", "CONFIRM Issue Warning", Color3.fromRGB(126, 93, 42), function()
			sendUserAction({
				Action = "WarnManagedUser",
				TargetUserId = selected.UserId,
				ReasonCode = selectedModerationReasonCode,
				ReasonText = moderationReasonText,
			})
		end)
	end

	if hasCapability("MOD_BAN_24H") then
		makeConfirmableButton(userManagementList, ("ban:%d"):format(selected.UserId), "24-Hour Ban", "CONFIRM 24-HOUR BAN", Color3.fromRGB(132, 54, 61), function()
			sendUserAction({
				Action = "BanManagedUser24h",
				TargetUserId = selected.UserId,
				ReasonCode = selectedModerationReasonCode,
				ReasonText = moderationReasonText,
			})
		end)
	end

	if activeBan and hasCapability("MOD_REMOVE_BAN") then
		makeConfirmableButton(userManagementList, ("unban:%d"):format(selected.UserId), "Remove Active Ban", "CONFIRM Remove Ban", Color3.fromRGB(116, 48, 52), function()
			sendUserAction({
				Action = "RemoveManagedUserBan",
				TargetUserId = selected.UserId,
				ReasonText = moderationReasonText,
			})
		end)
	end

	if hasCapability("MOD_VIEW_HISTORY") then
		makeButton(userManagementList, "View Moderation History", Color3.fromRGB(47, 85, 102), function()
			send({
				Action = "ViewManagedUserHistory",
				TargetUserId = selected.UserId,
			})
		end)
	end

	local history = selected.ModerationHistory
	if typeof(history) == "table" then
		local rows = {}
		for _, warning in ipairs(history.Warnings or {}) do
			table.insert(rows, ("WARN %s | %s"):format(warning.ReasonCode or "OTHER", warning.ReasonText or ""))
		end
		for _, ban in ipairs(history.Bans or {}) do
			table.insert(rows, ("BAN %s | until %s | %s"):format(ban.ReasonCode or "OTHER", tostring(ban.ExpirationTime or "?"), ban.ReasonText or ""))
		end
		for _, unban in ipairs(history.Unbans or {}) do
			table.insert(rows, ("UNBAN | %s"):format(unban.ReasonText or ""))
		end
		makeInfoText(userManagementList, if #rows > 0 then table.concat(rows, "\n") else "No moderation history.", math.min(180, math.max(54, #rows * 30)))
	end
end

rebuildPanel = function()
	if not latestState or not gui then
		return
	end

	local selectionSnapshot = getGamepadSelectionSnapshot()

	selectedRoomId = selectedRoomId or latestState.CurrentRoomId or Constants.RoomOrder[1]

	clearList(roomList)
	clearList(sessionList)
	clearList(roomStateList)
	clearList(eventList)
	clearList(areaList)
	clearList(toolsList)
	clearList(energyList)
	clearList(storeList)
	clearList(userList)
	clearList(userManagementList)

	local rooms = latestState.Rooms or {}
	if hasAnyCapability({ "DEV_ROOM_TESTING", "DEV_FULL", "TEST_ROOM_TELEPORT" }) and makeCollapseHeader(roomList, "Locations", "Locations", #rooms) then
		for _, room in ipairs(rooms) do
			local isSelected = room.Id == selectedRoomId
			makeButton(roomList, (isSelected and "> " or "") .. room.Name, isSelected and Color3.fromRGB(54, 90, 124) or Color3.fromRGB(45, 52, 64), function()
				selectedRoomId = room.Id
				send({
					Action = "JumpToRoom",
					RoomId = room.Id,
				})
			end)
		end
	end

	if hasCapability("DEV_FULL") and makeCollapseHeader(sessionList, "SessionSimulation", "Session Simulation", 1) then
		makeButton(sessionList, "Fresh Start", Color3.fromRGB(42, 103, 92), function()
			send({
				Action = "FreshStart",
			})
		end)
	end

	local presets = latestState.Presets or {}
	if hasAnyCapability({ "DEV_ROOM_TESTING", "DEV_FULL", "TEST_ROOM_STATE" }) and makeCollapseHeader(roomStateList, "RoomState", "Room State", #presets + 2) then
		for _, presetName in ipairs(presets) do
			makeButton(roomStateList, presetName, Color3.fromRGB(74, 58, 112), function()
				send({
					Action = "SetRoomPreset",
					RoomId = selectedRoomId,
					Preset = presetName,
				})
			end)
		end
		makeButton(roomStateList, "Complete Current Room", Color3.fromRGB(38, 114, 76), function()
			send({
				Action = "CompleteCurrentRoom",
			})
		end)
		makeButton(roomStateList, "Reset Current Room", Color3.fromRGB(126, 75, 38), function()
			send({
				Action = "ResetCurrentRoom",
			})
		end)
	end

	local events = latestState.Events or {}
	if hasCapability("DEV_FULL") and makeCollapseHeader(eventList, "Events", "Events", #events + 1) then
		makeButton(eventList, "Trigger Random Event", Color3.fromRGB(138, 77, 56), function()
			send({
				Action = "TriggerRandomEvent",
			})
		end)
		for _, eventDefinition in ipairs(events) do
			makeButton(eventList, eventDefinition.Id, Color3.fromRGB(89, 67, 117), function()
				send({
					Action = "TriggerSpecificEvent",
					EventId = eventDefinition.Id,
				})
			end)
		end
	end

	local secretAreas = latestState.SecretAreas or {}
	if hasAnyCapability({ "DEV_FULL", "DEV_SURVEILLANCE" }) and makeCollapseHeader(areaList, "SecretAreas", "Secret Areas", #secretAreas) then
		for _, area in ipairs(secretAreas) do
			makeButton(areaList, area.Name, Color3.fromRGB(55, 93, 113), function()
				send({
					Action = "TeleportSecretArea",
					AreaId = area.Id,
				})
			end)
		end
	end

	if hasAnyCapability({ "DEV_FULL", "TEST_BUILD_ACCESS" }) and makeCollapseHeader(toolsList, "SessionTools", hasCapability("DEV_FULL") and "Session Tools" or "Facility Test Panel", 7) then
		local titleSequenceEnabled = isTitleSequenceEnabledForDev()
		if hasCapability("DEV_FULL") then
			makeButton(
				toolsList,
				titleSequenceEnabled and "Title Sequence: ON" or "Title Sequence: OFF",
				titleSequenceEnabled and Color3.fromRGB(38, 113, 96) or Color3.fromRGB(116, 48, 52),
				function()
					setTitleSequenceEnabledForDev(not isTitleSequenceEnabledForDev())
					rebuildPanel()
				end
			)
			makeButton(toolsList, "Show Title Now", Color3.fromRGB(47, 85, 102), showTitleSequenceNowForDev)
			makeButton(toolsList, "Unlock All This Session", Color3.fromRGB(35, 103, 68), function()
				send({
					Action = "UnlockAllSession",
				})
			end)
			makeButton(toolsList, "Restore Normal Progress", Color3.fromRGB(116, 48, 52), function()
				send({
					Action = "RestoreNormalProgress",
				})
			end)
			makeButton(toolsList, (flyEnabled and "Fly: ON" or "Fly: OFF"), flyEnabled and Color3.fromRGB(38, 113, 96) or Color3.fromRGB(64, 70, 82), function()
				send({
					Action = "SetMovement",
					Fly = not flyEnabled,
					Noclip = noclipEnabled,
				})
			end)
			makeButton(toolsList, (noclipEnabled and "Noclip: ON" or "Noclip: OFF"), noclipEnabled and Color3.fromRGB(38, 113, 96) or Color3.fromRGB(64, 70, 82), function()
				send({
					Action = "SetMovement",
					Fly = flyEnabled,
					Noclip = not noclipEnabled,
				})
			end)
			makeButton(
				toolsList,
				(playerGui:GetAttribute(DEV_WALL_DRAFT_ENABLED_ATTRIBUTE) == true and "Wall Draft: ON" or "Wall Draft: OFF"),
				playerGui:GetAttribute(DEV_WALL_DRAFT_ENABLED_ATTRIBUTE) == true and Color3.fromRGB(38, 113, 96) or Color3.fromRGB(64, 70, 82),
				function()
					playerGui:SetAttribute(DEV_WALL_DRAFT_ENABLED_ATTRIBUTE, playerGui:GetAttribute(DEV_WALL_DRAFT_ENABLED_ATTRIBUTE) ~= true)
					rebuildPanel()
				end
			)
		else
			makeInfoText(toolsList, ("TEST SESSION\nBuild: %s\nCurrent room: %s"):format(tostring(Constants.BuildVersion or "?"), selectedRoomId or "?"), 64)
		end
		makeButton(toolsList, (inspectEnabled and "Inspect: ON" or "Inspect: OFF"), inspectEnabled and Color3.fromRGB(38, 113, 96) or Color3.fromRGB(64, 70, 82), function()
			setInspectState(not inspectEnabled)
			rebuildPanel()
		end)
		makeButton(toolsList, (idLabelsEnabled and "ID Labels: ON" or "ID Labels: OFF"), idLabelsEnabled and Color3.fromRGB(38, 113, 96) or Color3.fromRGB(64, 70, 82), function()
			setIdLabelsState(not idLabelsEnabled)
			rebuildPanel()
		end)
		if idLabelsEnabled then
			makeButton(toolsList, "Refresh ID Labels", Color3.fromRGB(47, 85, 102), function()
				updateIdLabels(true)
			end)
		end
	end

	local energy = latestState.Energy or {}
	local playerEnergy = math.floor((tonumber(energy.PlayerEnergy) or 1) * 100 + 0.5)
	local bunkerPower = math.floor((tonumber(energy.WorldPower) or 0) * 100 + 0.5)
	local signalLoad = math.floor((tonumber(energy.BunkerHunger) or 0) * 100 + 0.5)
	local energyTitle = ("Energy / Recovery  P%d%% B%d%% S%d%%"):format(playerEnergy, bunkerPower, signalLoad)
	if hasAnyCapability({ "DEV_BUNKER_ENERGY", "DEV_FULL" }) and makeCollapseHeader(energyList, "EnergyRecovery", energyTitle, 9) then
		makeButton(energyList, "Nourishment: 100%", Color3.fromRGB(38, 113, 96), function()
			send({
				Action = "SetNourishment",
				Value = 1,
			})
		end)
		makeButton(energyList, "Nourishment: 45%", Color3.fromRGB(101, 89, 45), function()
			send({
				Action = "SetNourishment",
				Value = 0.45,
			})
		end)
		makeButton(energyList, "Nourishment: 8%", Color3.fromRGB(126, 75, 38), function()
			send({
				Action = "SetNourishment",
				Value = 0.08,
			})
		end)
		makeButton(energyList, "Bunker Power: 100%", Color3.fromRGB(38, 113, 96), function()
			send({
				Action = "SetBunkerPower",
				Value = 1,
			})
		end)
		makeButton(energyList, "Bunker Power: 20%", Color3.fromRGB(101, 89, 45), function()
			send({
				Action = "SetBunkerPower",
				Value = 0.2,
			})
		end)
		makeButton(energyList, "Simulate Inactivity", Color3.fromRGB(112, 65, 120), function()
			send({
				Action = "SimulateInactivity",
			})
		end)
		makeButton(energyList, "Trigger Pass-Out", Color3.fromRGB(132, 54, 61), function()
			send({
				Action = "TriggerPassOut",
			})
		end)
		makeButton(energyList, "Teleport to Infirmary", Color3.fromRGB(55, 93, 113), function()
			send({
				Action = "TeleportInfirmary",
			})
		end)
		makeButton(energyList, "Restore Healthy State", Color3.fromRGB(35, 103, 68), function()
			send({
				Action = "RestoreHealthyState",
			})
		end)
		makeButton(energyList, "Reset Infirmary State", Color3.fromRGB(87, 76, 97), function()
			send({
				Action = "ResetInfirmaryState",
			})
		end)
	end

	if hasAnyCapability({ "DEV_ECONOMY_TESTING", "DEV_FULL" }) then
		rebuildStorePrices()
	end
	if hasAnyCapability({ "DEV_ROOM_TESTING", "DEV_FULL" }) then
		rebuildDiscoveries()
	end
	rebuildUserManagement()
	updateStatus()
	preserveGamepadSelection(selectionSnapshot)
end

local function buildGui()
	if gui then
		gui.Enabled = true
		return
	end

	gui = Instance.new("ScreenGui")
	gui.Name = UiLayerController.GuiNames.DevTools
	gui.IgnoreGuiInset = false
	UiLayerController.ApplyRole(gui, "DevTools")
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")
	pcall(function()
		gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	end)

	toggleButton = Instance.new("TextButton")
	toggleButton.Name = "DevToggle"
	toggleButton.AnchorPoint = Vector2.new(0, 1)
	toggleButton.BackgroundColor3 = Color3.fromRGB(20, 25, 32)
	toggleButton.BorderSizePixel = 0
	toggleButton.Font = Enum.Font.GothamBlack
	toggleButton.Position = UDim2.new(0, 12, 1, -78)
	toggleButton.Size = UDim2.fromOffset(70, 34)
	toggleButton.Text = "DEV"
	toggleButton.TextColor3 = Color3.fromRGB(154, 255, 192)
	toggleButton.TextScaled = true
	toggleButton.Parent = gui
	makeCorner(toggleButton, 6)
	devToggleCoordinateLabel = makeCoordinateLabel(toggleButton, "DevToggleCoordinateLabel")
	wireDevLayoutDrag(toggleButton, "Toggle")

	devInfoLabel = Instance.new("TextLabel")
	devInfoLabel.Name = "DevInfoMessage"
	devInfoLabel.AnchorPoint = Vector2.new(0.5, 1)
	devInfoLabel.BackgroundColor3 = Color3.fromRGB(12, 16, 22)
	devInfoLabel.BackgroundTransparency = 0.06
	devInfoLabel.BorderSizePixel = 0
	devInfoLabel.Font = Enum.Font.GothamBold
	devInfoLabel.Position = UDim2.new(0.5, 0, 1, -92)
	devInfoLabel.Size = UDim2.new(0.62, 0, 0, 52)
	devInfoLabel.Text = ""
	devInfoLabel.TextColor3 = Color3.fromRGB(224, 244, 255)
	devInfoLabel.TextScaled = true
	devInfoLabel.TextWrapped = true
	devInfoLabel.Visible = false
	devInfoLabel.ZIndex = 90
	devInfoLabel.Parent = gui
	makeCorner(devInfoLabel, 8)

	inspectLabel = Instance.new("TextLabel")
	inspectLabel.Name = "DevInspectReadout"
	inspectLabel.Active = true
	inspectLabel.AnchorPoint = Vector2.zero
	inspectLabel.BackgroundColor3 = Color3.fromRGB(8, 11, 16)
	inspectLabel.BackgroundTransparency = 0.04
	inspectLabel.BorderSizePixel = 0
	inspectLabel.Font = Enum.Font.Code
	inspectLabel.Position = UDim2.new(0, 12, 1, -318)
	inspectLabel.Size = UDim2.fromOffset(330, 196)
	inspectLabel.Text = "DEV INSPECT"
	inspectLabel.TextColor3 = Color3.fromRGB(188, 246, 255)
	inspectLabel.TextSize = 13
	inspectLabel.TextWrapped = true
	inspectLabel.TextXAlignment = Enum.TextXAlignment.Left
	inspectLabel.TextYAlignment = Enum.TextYAlignment.Top
	inspectLabel.Visible = false
	inspectLabel.ZIndex = 91
	inspectLabel.Parent = gui
	makeCorner(inspectLabel, 8)
	local inspectPadding = Instance.new("UIPadding")
	inspectPadding.PaddingTop = UDim.new(0, 8)
	inspectPadding.PaddingBottom = UDim.new(0, 8)
	inspectPadding.PaddingLeft = UDim.new(0, 9)
	inspectPadding.PaddingRight = UDim.new(0, 58)
	inspectPadding.Parent = inspectLabel

	inspectCloseButton = Instance.new("TextButton")
	inspectCloseButton.Name = "CloseDevInspect"
	inspectCloseButton.AnchorPoint = Vector2.new(1, 0)
	inspectCloseButton.BackgroundColor3 = Color3.fromRGB(34, 40, 50)
	inspectCloseButton.BackgroundTransparency = 0.02
	inspectCloseButton.BorderSizePixel = 0
	inspectCloseButton.Font = Enum.Font.GothamBlack
	inspectCloseButton.Position = UDim2.new(1, -8, 0, 8)
	inspectCloseButton.Size = UDim2.fromOffset(30, 28)
	inspectCloseButton.Text = "X"
	inspectCloseButton.TextColor3 = Color3.fromRGB(238, 247, 255)
	inspectCloseButton.TextSize = 14
	inspectCloseButton.Visible = false
	inspectCloseButton.ZIndex = 92
	inspectCloseButton.Parent = inspectLabel
	makeCorner(inspectCloseButton, 6)
	wireButtonActivation(inspectCloseButton, function()
		setInspectState(false)
		if latestState then
			rebuildPanel()
		end
	end)
	wireInspectRepositioning()

	panel = Instance.new("Frame")
	panel.Name = "DevPanel"
	panel.AnchorPoint = Vector2.new(0, 0.5)
	panel.BackgroundColor3 = Color3.fromRGB(15, 18, 24)
	panel.BackgroundTransparency = 0.04
	panel.BorderSizePixel = 0
	panel.Position = UDim2.new(0, 12, 0.5, 0)
	panel.Size = UDim2.fromOffset(330, 500)
	panel.Visible = false
	panel.Parent = gui
	makeCorner(panel, 8)
	devPanelCoordinateLabel = makeCoordinateLabel(panel, "DevPanelCoordinateLabel")

	panelConstraint = Instance.new("UISizeConstraint")
	panelConstraint.MaxSize = Vector2.new(360, 560)
	panelConstraint.MinSize = Vector2.new(292, 390)
	panelConstraint.Parent = panel

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.Position = UDim2.fromOffset(12, 8)
	title.Size = UDim2.new(1, -78, 0, 30)
	title.Text = ("DEV TOOLS  v%s"):format(tostring(Constants.BuildVersion or "?"))
	title.TextColor3 = Color3.fromRGB(154, 255, 192)
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel
	wireDevLayoutDrag(title, "Panel")
	wireDevLayoutDrag(panel, "Panel")

	local close = Instance.new("TextButton")
	close.BackgroundColor3 = Color3.fromRGB(54, 60, 72)
	close.BorderSizePixel = 0
	close.Font = Enum.Font.GothamBlack
	close.Position = UDim2.new(1, -48, 0, 8)
	close.Size = UDim2.fromOffset(36, 30)
	close.Text = "X"
	close.TextColor3 = Color3.fromRGB(238, 247, 255)
	close.TextScaled = true
	close.Parent = panel
	makeCorner(close, 5)

	statusLabel = Instance.new("TextLabel")
	statusLabel.BackgroundTransparency = 1
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.Position = UDim2.fromOffset(12, 40)
	statusLabel.Size = UDim2.new(1, -24, 0, 22)
	statusLabel.Text = "Loading..."
	statusLabel.TextColor3 = Color3.fromRGB(225, 237, 246)
	statusLabel.TextScaled = true
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Parent = panel

	local scroll = Instance.new("ScrollingFrame")
	panelScroll = scroll
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.CanvasSize = UDim2.fromOffset(0, 0)
	scroll.Position = UDim2.fromOffset(12, 70)
	scroll.ScrollBarThickness = 6
	scroll.Size = UDim2.new(1, -24, 1, -82)
	scroll.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 9)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll

	local padding = Instance.new("UIPadding")
	padding.PaddingBottom = UDim.new(0, 12)
	padding.Parent = scroll

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 18)
	end)

	roomList = makeList(scroll)
	sessionList = makeList(scroll)
	roomStateList = makeList(scroll)
	eventList = makeList(scroll)
	areaList = makeList(scroll)
	toolsList = makeList(scroll)
	energyList = makeList(scroll)
	storeList = makeList(scroll)
	discoveryList = makeList(scroll)
	userList = makeList(scroll)
	userManagementList = makeList(scroll)
	applyDevLayout(currentDeviceProfile)

	wireButtonActivation(toggleButton, function()
		if isTouchEditLayoutActive() then
			return
		end
		panel.Visible = not panel.Visible
		if panel.Visible then
			dismissStartOverlayForDevSession()
			preserveGamepadSelection(nil)
			send({
				Action = "Refresh",
				RoomId = selectedRoomId,
			})
		else
			clearPanelSelection()
		end
	end)

	wireButtonActivation(close, function()
		clearPanelSelection()
		panel.Visible = false
	end)
end

devRemote.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end

	if payload.Type == "MovementState" then
		setMovementState(payload.Fly == true, payload.Noclip == true)
		if latestState then
			latestState.Movement = {
				Fly = payload.Fly == true,
				Noclip = payload.Noclip == true,
			}
		end
		rebuildPanel()
		return
	end

	if payload.Type == "UserManagement" then
		if latestState then
			latestState.UserManagement = payload.UserManagement
			if payload.UserMessage and showDevInfo then
				showDevInfo(payload.UserMessage, 6)
			end
			rebuildPanel()
		end
		return
	end

	if payload.Type == "AuthorizationRevoked" then
		authorized = false
		latestState = nil
		clearIdLabels()
		setInspectState(false)
		if panel then
			panel.Visible = false
		end
		if toggleButton then
			toggleButton.Visible = false
		end
		return
	end

	if payload.Authorized ~= true then
		return
	end

	authorized = true
	connectMovementLoops()
	buildGui()
	if gui then
		gui.Enabled = true
	end
	if toggleButton then
		toggleButton.Visible = true
	end
	if not inspectAutoEnabled then
		inspectAutoEnabled = true
		setInspectState(true)
	end

	if typeof(payload.Movement) == "table" then
		setMovementState(payload.Movement.Fly == true, payload.Movement.Noclip == true)
	end

	latestState = payload
	if payload.CurrentRoomId and (not selectedRoomId or payload.Type == "Auth") then
		selectedRoomId = payload.CurrentRoomId
	end

	rebuildPanel()
	applyDevLayout(currentDeviceProfile)
end)

UserInputService.InputChanged:Connect(updateDevLayoutDrag)
UserInputService.InputEnded:Connect(endDevLayoutDrag)
UserInputService.TouchEnded:Connect(function(input)
	endDevLayoutDrag(input)
end)
UserInputService.WindowFocusReleased:Connect(function()
	devLayoutDragging = nil
end)
playerGui:GetAttributeChangedSignal(DEV_LAYOUT_RESET_ATTRIBUTE):Connect(resetDevLayoutPositions)
playerGui:GetAttributeChangedSignal(TOUCH_EDIT_MODE_ATTRIBUTE):Connect(function()
	if not isTouchEditLayoutActive() then
		devLayoutDragging = nil
	end
	updateDevCoordinateLabels()
end)

DeviceProfile.Bind(function(profile)
	applyDevLayout(profile)
	if latestState then
		rebuildPanel()
	end
end)

devRemote:FireServer({
	Action = "Handshake",
})
