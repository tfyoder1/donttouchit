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
local selectedRoomId = nil
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
local idLabelsEnabled = false
local idLabelFolder = nil
local lastIdLabelsUpdateAt = 0
local DEV_DISMISS_START_ATTRIBUTE = "DontTouchItDevDismissedStartIntro"
local FLY_SPEED = 55
local GAMEPAD_STICK_DEADZONE = 0.16
local INSPECT_RANGE = 700
local INSPECT_SKIP_EPSILON = 0.15
local MAX_INSPECT_RAYCAST_SKIPS = 8
local ID_LABEL_RANGE = 52
local ID_LABEL_MAX_PARTS = 24
local ID_LABEL_UPDATE_INTERVAL = 0.9
local DOUBLE_JUMP_MIN_SECONDS = 0.08
local DOUBLE_JUMP_MAX_SECONDS = 0.45
local DOUBLE_JUMP_FLY_COOLDOWN_SECONDS = 1
local BUTTON_ACTIVATION_DEBOUNCE_SECONDS = 0.25
local TOUCH_TAP_MAX_DRAG_PIXELS = 18
local currentDeviceProfile = DeviceProfile.Get()
local showDevInfo
local rebuildPanel
local lastJumpRequestAt = 0
local lastDoubleJumpFlyRequestAt = 0

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
}

local function isPhoneProfile()
	return currentDeviceProfile and currentDeviceProfile.IsPhone == true
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

local function findFirstSelectableButton(root, preferredText)
	if not root then
		return nil
	end

	local fallback = nil
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("TextButton") and descendant.Visible and descendant.Selectable then
			if not fallback then
				fallback = descendant
			end
			if preferredText and descendant.Text == preferredText then
				return descendant
			end
		end
	end

	return fallback
end

local function preserveGamepadSelection(previousText)
	if not panel or not panel.Visible or not UserInputService.GamepadEnabled then
		return
	end

	task.defer(function()
		if not panel or not panel.Visible then
			return
		end

		local selectedObject = findFirstSelectableButton(panel, previousText)
		if selectedObject then
			GuiService.SelectedObject = selectedObject
		end
	end)
end

local function clearPanelSelection()
	local selectedObject = GuiService.SelectedObject
	if selectedObject and panel and selectedObject:IsDescendantOf(panel) then
		GuiService.SelectedObject = nil
	end
end

local function applyDevLayout(profile)
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
	if inspectLabel then
		if isPhoneProfile() then
			inspectLabel.Position = UDim2.new(1, touchLandscape and -22 or -8, touchLandscape and 0.48 or 0.5, 0)
			inspectLabel.Size = UDim2.new(touchLandscape and 0.34 or 0.48, 0, 0, touchLandscape and 116 or 128)
			inspectLabel.TextSize = touchLandscape and 7 or 8
		else
			inspectLabel.Position = UDim2.new(1, -16, 0.5, 0)
			inspectLabel.Size = UDim2.fromOffset(330, 196)
			inspectLabel.TextSize = 13
		end
	end
	if inspectCloseButton then
		if isPhoneProfile() then
			inspectCloseButton.Position = UDim2.new(1, touchLandscape and -30 or -15, touchLandscape and 0.48 or 0.5, touchLandscape and -66 or -74)
			inspectCloseButton.Size = UDim2.fromOffset(touchLandscape and 22 or 24, touchLandscape and 20 or 22)
			inspectCloseButton.TextSize = touchLandscape and 10 or 11
		else
			inspectCloseButton.Position = UDim2.new(1, -24, 0.5, -111)
			inspectCloseButton.Size = UDim2.fromOffset(30, 28)
			inspectCloseButton.TextSize = 14
		end
	end

	if isPhoneProfile() then
		toggleButton.AnchorPoint = Vector2.new(0, 1)
		toggleButton.Position = UDim2.new(0, touchLandscape and 34 or 20, 1, touchLandscape and -138 or -112)
		toggleButton.Size = UDim2.fromOffset(touchLandscape and 54 or 48, touchLandscape and 28 or 25)
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

local function dismissStartOverlayForDevSession()
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then
		return
	end

	playerGui:SetAttribute(DEV_DISMISS_START_ATTRIBUTE, true)

	local mainGui = playerGui:FindFirstChild("DontTouchItUI")
	if mainGui then
		mainGui:SetAttribute(DEV_DISMISS_START_ATTRIBUTE, true)
	end

	local startOverlay = mainGui and mainGui:FindFirstChild("StartChoiceOverlay")
	if startOverlay and startOverlay:IsA("GuiObject") then
		startOverlay.Visible = false
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
	local playerPositionText = if rootPart then formatVector3(rootPart.Position) else "-"
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
	if not gui then
		return nil
	end

	if not idLabelFolder then
		idLabelFolder = Instance.new("Folder")
		idLabelFolder.Name = "DevIdLabels"
		idLabelFolder.Parent = gui
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
		return "Dev fly ON. Touch support is limited for dev testing. Use the move stick to drift; attach a keyboard/gamepad for full up/down control."
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
end

local function isFlyAscendPressed()
	return pressedKeys[Enum.KeyCode.Space]
		or pressedKeys[Enum.KeyCode.E]
		or pressedKeys[Enum.KeyCode.ButtonA]
		or pressedKeys[Enum.KeyCode.DPadUp]
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

rebuildPanel = function()
	if not latestState or not gui then
		return
	end

	local selectedObject = GuiService.SelectedObject
	local previousSelectionText = nil
	if selectedObject and panel and selectedObject:IsDescendantOf(panel) and selectedObject:IsA("TextButton") then
		previousSelectionText = selectedObject.Text
	end

	selectedRoomId = selectedRoomId or latestState.CurrentRoomId or Constants.RoomOrder[1]

	clearList(roomList)
	clearList(sessionList)
	clearList(roomStateList)
	clearList(eventList)
	clearList(areaList)
	clearList(toolsList)
	clearList(energyList)
	clearList(storeList)

	local rooms = latestState.Rooms or {}
	if makeCollapseHeader(roomList, "Locations", "Locations", #rooms) then
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

	if makeCollapseHeader(sessionList, "SessionSimulation", "Session Simulation", 1) then
		makeButton(sessionList, "Fresh Start", Color3.fromRGB(42, 103, 92), function()
			send({
				Action = "FreshStart",
			})
		end)
	end

	local presets = latestState.Presets or {}
	if makeCollapseHeader(roomStateList, "RoomState", "Room State", #presets + 2) then
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
	if makeCollapseHeader(eventList, "Events", "Events", #events + 1) then
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
	if makeCollapseHeader(areaList, "SecretAreas", "Secret Areas", #secretAreas) then
		for _, area in ipairs(secretAreas) do
			makeButton(areaList, area.Name, Color3.fromRGB(55, 93, 113), function()
				send({
					Action = "TeleportSecretArea",
					AreaId = area.Id,
				})
			end)
		end
	end

	if makeCollapseHeader(toolsList, "SessionTools", "Session Tools", 5) then
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
	if makeCollapseHeader(energyList, "EnergyRecovery", energyTitle, 9) then
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

	rebuildStorePrices()
	rebuildDiscoveries()
	updateStatus()
	preserveGamepadSelection(previousSelectionText)
end

local function buildGui()
	if gui then
		return
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "DontTouchItDevTools"
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 100
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
	inspectLabel.AnchorPoint = Vector2.new(1, 0.5)
	inspectLabel.BackgroundColor3 = Color3.fromRGB(8, 11, 16)
	inspectLabel.BackgroundTransparency = 0.04
	inspectLabel.BorderSizePixel = 0
	inspectLabel.Font = Enum.Font.Code
	inspectLabel.Position = UDim2.new(1, -16, 0.5, 0)
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
	inspectPadding.PaddingRight = UDim.new(0, 28)
	inspectPadding.Parent = inspectLabel

	inspectCloseButton = Instance.new("TextButton")
	inspectCloseButton.Name = "CloseDevInspect"
	inspectCloseButton.AnchorPoint = Vector2.new(1, 0)
	inspectCloseButton.BackgroundColor3 = Color3.fromRGB(34, 40, 50)
	inspectCloseButton.BackgroundTransparency = 0.02
	inspectCloseButton.BorderSizePixel = 0
	inspectCloseButton.Font = Enum.Font.GothamBlack
	inspectCloseButton.Position = UDim2.new(1, -24, 0.5, -111)
	inspectCloseButton.Size = UDim2.fromOffset(30, 28)
	inspectCloseButton.Text = "X"
	inspectCloseButton.TextColor3 = Color3.fromRGB(238, 247, 255)
	inspectCloseButton.TextSize = 14
	inspectCloseButton.Visible = false
	inspectCloseButton.ZIndex = 92
	inspectCloseButton.Parent = gui
	makeCorner(inspectCloseButton, 6)
	wireButtonActivation(inspectCloseButton, function()
		setInspectState(false)
		if latestState then
			rebuildPanel()
		end
	end)

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

	panelConstraint = Instance.new("UISizeConstraint")
	panelConstraint.MaxSize = Vector2.new(360, 560)
	panelConstraint.MinSize = Vector2.new(292, 390)
	panelConstraint.Parent = panel

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.Position = UDim2.fromOffset(12, 8)
	title.Size = UDim2.new(1, -78, 0, 30)
	title.Text = "DEV TOOLS"
	title.TextColor3 = Color3.fromRGB(154, 255, 192)
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

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
	applyDevLayout(currentDeviceProfile)

	wireButtonActivation(toggleButton, function()
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

	if payload.Authorized ~= true then
		return
	end

	authorized = true
	connectMovementLoops()
	buildGui()
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

DeviceProfile.Bind(function(profile)
	applyDevLayout(profile)
	if latestState then
		rebuildPanel()
	end
end)

devRemote:FireServer({
	Action = "Handshake",
})
