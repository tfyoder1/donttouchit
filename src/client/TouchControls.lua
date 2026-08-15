local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TouchControls = {}

local TOUCH_GUI_NAME = "DontTouchItTouchControls"
local OPTIONS_GUI_NAME = "DontTouchItControlOptions"
local TOUCH_GUI_ORDER = 145
local OPTIONS_GUI_ORDER = 155
local BUTTON_Z_INDEX = 10
local PANEL_Z_INDEX = 50
local DRAG_MARGIN = 8
local TOUCH_BUTTON_SIZE = UDim2.fromOffset(80, 52)
local TOUCH_ICON_DISK_SIZE = 32
local TOUCH_ICON_COLOR = Color3.fromRGB(246, 249, 255)
local TOUCH_ICON_DISABLED_COLOR = Color3.fromRGB(156, 164, 178)
local TOUCH_ICON_DISK_COLOR = Color3.fromRGB(86, 90, 100)
local TOUCH_ICON_DISK_DISABLED_COLOR = Color3.fromRGB(57, 62, 72)

local ICON_KIND_BY_ID = {
	Run = "Run",
	Drop = "Drop",
	Ping = "Ping",
	CrouchSlide = "Crouch",
}

local controlsById = {}
local orderedIds = {}
local sessionPositions = {}
local touchGui = nil
local optionsGui = nil
local optionsPanel = nil
local controlsList = nil
local editButton = nil
local resetButton = nil
local editMode = false
local activeDrag = nil

local function isTouchPointer(input)
	return input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1
end

local function isDragMovement(input)
	return input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseMovement
end

local function toVector2(position)
	return Vector2.new(position.X, position.Y)
end

local function getTouchGui()
	if touchGui and touchGui.Parent then
		return touchGui
	end

	local existing = playerGui:FindFirstChild(TOUCH_GUI_NAME)
	if existing and existing:IsA("ScreenGui") then
		touchGui = existing
		return touchGui
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = TOUCH_GUI_NAME
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = TOUCH_GUI_ORDER
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui
	touchGui = gui
	return touchGui
end

local function getOptionText(state)
	local desktop = state.Desktop or "Default"
	local xbox = state.Xbox or "Default"
	local touch = state.Touch or state.Text or state.Label
	return ("PC/Mac: %s    Xbox: %s    iOS: %s"):format(desktop, xbox, touch)
end

local function setRounded(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
	return corner
end

local function setStroke(instance, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Transparency = transparency
	stroke.Parent = instance
	return stroke
end

local function clearIconLayer(layer)
	for _, child in ipairs(layer:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function addIconPart(parent, name, x, y, width, height, rotation, color)
	local part = Instance.new("Frame")
	part.Name = name
	part.Active = false
	part.AnchorPoint = Vector2.new(0.5, 0.5)
	part.BackgroundColor3 = color
	part.BorderSizePixel = 0
	part.Position = UDim2.fromScale(x, y)
	part.Rotation = rotation or 0
	part.Size = UDim2.fromScale(width, height)
	part.ZIndex = parent.ZIndex + 1
	part.Parent = parent
	setRounded(part, 999)
	return part
end

local function drawRunIcon(layer, color)
	addIconPart(layer, "Head", 0.58, 0.25, 0.22, 0.22, 0, color)
	addIconPart(layer, "Torso", 0.51, 0.45, 0.11, 0.34, -22, color)
	addIconPart(layer, "ArmForward", 0.39, 0.43, 0.09, 0.31, 52, color)
	addIconPart(layer, "ArmBack", 0.61, 0.49, 0.08, 0.27, -52, color)
	addIconPart(layer, "LegForward", 0.62, 0.72, 0.10, 0.39, 48, color)
	addIconPart(layer, "LegBack", 0.41, 0.73, 0.10, 0.36, -42, color)
end

local function drawPingIcon(layer, color, cutoutColor)
	addIconPart(layer, "PinHead", 0.5, 0.34, 0.38, 0.38, 0, color)
	addIconPart(layer, "PinHole", 0.5, 0.34, 0.15, 0.15, 0, cutoutColor)
	addIconPart(layer, "PinStem", 0.5, 0.61, 0.18, 0.42, 45, color)
	addIconPart(layer, "PinPoint", 0.5, 0.79, 0.15, 0.15, 45, color)
end

local function drawDropIcon(layer, color)
	addIconPart(layer, "Palm", 0.38, 0.55, 0.31, 0.20, -12, color)
	addIconPart(layer, "Thumb", 0.24, 0.54, 0.09, 0.23, 34, color)
	addIconPart(layer, "FingerOne", 0.31, 0.40, 0.08, 0.26, -12, color)
	addIconPart(layer, "FingerTwo", 0.42, 0.38, 0.08, 0.25, -6, color)
	addIconPart(layer, "FingerThree", 0.53, 0.40, 0.08, 0.22, 8, color)
	addIconPart(layer, "DropLine", 0.68, 0.49, 0.07, 0.23, 0, color)
	addIconPart(layer, "FallingObject", 0.68, 0.73, 0.17, 0.17, 0, color)
end

local function drawCrouchIcon(layer, color)
	addIconPart(layer, "Head", 0.34, 0.31, 0.23, 0.23, 0, color)
	addIconPart(layer, "Back", 0.49, 0.49, 0.11, 0.34, 42, color)
	addIconPart(layer, "Arm", 0.50, 0.59, 0.09, 0.28, 72, color)
	addIconPart(layer, "UpperLeg", 0.62, 0.68, 0.12, 0.39, 80, color)
	addIconPart(layer, "LowerLeg", 0.44, 0.78, 0.11, 0.32, -32, color)
end

local function drawDefaultIcon(layer, color)
	addIconPart(layer, "Dot", 0.5, 0.5, 0.38, 0.38, 0, color)
end

local function drawTouchIcon(layer, kind, color, cutoutColor)
	clearIconLayer(layer)
	if kind == "Run" then
		drawRunIcon(layer, color)
	elseif kind == "Ping" then
		drawPingIcon(layer, color, cutoutColor)
	elseif kind == "Drop" then
		drawDropIcon(layer, color)
	elseif kind == "Crouch" then
		drawCrouchIcon(layer, color)
	else
		drawDefaultIcon(layer, color)
	end
end

local function ensureTouchButtonVisual(button)
	local iconDisk = button:FindFirstChild("TouchControlIconDisk")
	if not iconDisk or not iconDisk:IsA("Frame") then
		iconDisk = Instance.new("Frame")
		iconDisk.Name = "TouchControlIconDisk"
		iconDisk.Active = false
		iconDisk.AnchorPoint = Vector2.new(0, 0.5)
		iconDisk.BorderSizePixel = 0
		iconDisk.ZIndex = button.ZIndex + 1
		iconDisk.Parent = button
		setRounded(iconDisk, 999)
	end

	local diskStroke = iconDisk:FindFirstChild("TouchControlIconDiskStroke")
	if not diskStroke or not diskStroke:IsA("UIStroke") then
		diskStroke = setStroke(iconDisk, Color3.fromRGB(255, 255, 255), 1, 0.82)
		diskStroke.Name = "TouchControlIconDiskStroke"
	end

	local iconLayer = iconDisk:FindFirstChild("TouchControlIconLayer")
	if not iconLayer or not iconLayer:IsA("Frame") then
		iconLayer = Instance.new("Frame")
		iconLayer.Name = "TouchControlIconLayer"
		iconLayer.Active = false
		iconLayer.BackgroundTransparency = 1
		iconLayer.BorderSizePixel = 0
		iconLayer.Position = UDim2.fromScale(0.14, 0.14)
		iconLayer.Size = UDim2.fromScale(0.72, 0.72)
		iconLayer.ZIndex = iconDisk.ZIndex + 1
		iconLayer.Parent = iconDisk
	end

	local label = button:FindFirstChild("TouchControlLabel")
	if not label or not label:IsA("TextLabel") then
		label = Instance.new("TextLabel")
		label.Name = "TouchControlLabel"
		label.Active = false
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.TextWrapped = false
		label.TextXAlignment = Enum.TextXAlignment.Center
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.ZIndex = button.ZIndex + 1
		label.Parent = button

		local sizeConstraint = Instance.new("UITextSizeConstraint")
		sizeConstraint.Name = "TouchControlTextSize"
		sizeConstraint.MinTextSize = 8
		sizeConstraint.MaxTextSize = 14
		sizeConstraint.Parent = label
	end

	return iconDisk, iconLayer, label, diskStroke
end

local function upsertOrderedId(id)
	if table.find(orderedIds, id) then
		return
	end

	table.insert(orderedIds, id)
	table.sort(orderedIds, function(left, right)
		local leftState = controlsById[left]
		local rightState = controlsById[right]
		local leftOrder = leftState and leftState.Order or 1000
		local rightOrder = rightState and rightState.Order or 1000
		if leftOrder == rightOrder then
			return tostring(left) < tostring(right)
		end
		return leftOrder < rightOrder
	end)
end

local function clampButtonPosition(button, position)
	local parent = button.Parent
	if not parent then
		return position
	end

	local parentSize = parent.AbsoluteSize
	if parentSize.X <= 0 or parentSize.Y <= 0 then
		return position
	end

	local buttonSize = button.AbsoluteSize
	local anchorX = parentSize.X * position.X.Scale + position.X.Offset
	local anchorY = parentSize.Y * position.Y.Scale + position.Y.Offset
	local clampedX = math.clamp(anchorX, buttonSize.X + DRAG_MARGIN, parentSize.X - DRAG_MARGIN)
	local clampedY = math.clamp(anchorY, buttonSize.Y + DRAG_MARGIN, parentSize.Y - DRAG_MARGIN)
	return UDim2.fromOffset(clampedX, clampedY)
end

local function getButtonPosition(state)
	return sessionPositions[state.Id] or state.DefaultPosition
end

local function applyButtonState(state)
	local button = state.Button
	if not button then
		return
	end

	local enabled = state.Enabled ~= false
	button.Text = ""
	button.Size = state.Size
	button.Position = getButtonPosition(state)
	button.BackgroundColor3 = state.Color
	button.TextColor3 = state.TextColor
	button.AutoButtonColor = enabled and not editMode
	button.BackgroundTransparency = if enabled then state.BackgroundTransparency else 0.42
	button.TextTransparency = if enabled then 0 else 0.25
	button.Visible = UserInputService.TouchEnabled and (editMode or state.Visible ~= false)
	button.Selectable = true
	button.Active = true

	local iconDisk, iconLayer, label, diskStroke = ensureTouchButtonVisual(button)
	local iconDiskColor = if enabled then TOUCH_ICON_DISK_COLOR else TOUCH_ICON_DISK_DISABLED_COLOR
	iconDisk.BackgroundColor3 = iconDiskColor
	iconDisk.BackgroundTransparency = if enabled then 0.08 else 0.18
	iconDisk.Position = UDim2.new(0, 6, 0.5, 0)
	iconDisk.Size = UDim2.fromOffset(TOUCH_ICON_DISK_SIZE, TOUCH_ICON_DISK_SIZE)
	iconDisk.ZIndex = button.ZIndex + 1
	iconLayer.ZIndex = iconDisk.ZIndex + 1
	label.Position = UDim2.new(0, TOUCH_ICON_DISK_SIZE + 12, 0, 4)
	label.Size = UDim2.new(1, -(TOUCH_ICON_DISK_SIZE + 17), 1, -8)
	label.Text = state.Text
	label.TextColor3 = if enabled then state.TextColor else TOUCH_ICON_DISABLED_COLOR
	label.TextTransparency = if enabled then 0 else 0.22

	diskStroke.Color = if editMode then Color3.fromRGB(255, 255, 255) else state.StrokeColor
	diskStroke.Transparency = if editMode then 0.12 else 0.58

	local iconColor = if enabled then TOUCH_ICON_COLOR else TOUCH_ICON_DISABLED_COLOR
	drawTouchIcon(iconLayer, ICON_KIND_BY_ID[state.Id], iconColor, iconDiskColor)

	local stroke = button:FindFirstChild("TouchControlStroke")
	if stroke and stroke:IsA("UIStroke") then
		stroke.Color = if editMode then Color3.fromRGB(255, 255, 255) else state.StrokeColor
		stroke.Thickness = if editMode then 3 else 2
		stroke.Transparency = if editMode then 0.06 else 0.25
	end
end

local function applyAllButtonStates()
	for _, state in pairs(controlsById) do
		applyButtonState(state)
	end
end

local function renderOptionsRows()
	if not controlsList then
		return
	end

	for _, child in ipairs(controlsList:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	for index, id in ipairs(orderedIds) do
		local state = controlsById[id]
		if not state then
			continue
		end

		local row = Instance.new("Frame")
		row.Name = "ControlRow"
		row.BackgroundColor3 = Color3.fromRGB(28, 32, 40)
		row.BackgroundTransparency = 0.06
		row.BorderSizePixel = 0
		row.LayoutOrder = index
		row.Size = UDim2.new(1, 0, 0, 56)
		row.ZIndex = PANEL_Z_INDEX + 2
		row.Parent = controlsList
		setRounded(row, 5)

		local title = Instance.new("TextLabel")
		title.Name = "ControlName"
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBlack
		title.Position = UDim2.fromOffset(10, 5)
		title.Size = UDim2.new(1, -20, 0, 19)
		title.Text = state.Label
		title.TextColor3 = Color3.fromRGB(238, 244, 255)
		title.TextScaled = false
		title.TextSize = 15
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.ZIndex = PANEL_Z_INDEX + 3
		title.Parent = row

		local mapping = Instance.new("TextLabel")
		mapping.Name = "ControlMapping"
		mapping.BackgroundTransparency = 1
		mapping.Font = Enum.Font.GothamSemibold
		mapping.Position = UDim2.fromOffset(10, 27)
		mapping.Size = UDim2.new(1, -20, 0, 23)
		mapping.Text = getOptionText(state)
		mapping.TextColor3 = Color3.fromRGB(190, 204, 222)
		mapping.TextScaled = false
		mapping.TextSize = 11
		mapping.TextWrapped = true
		mapping.TextXAlignment = Enum.TextXAlignment.Left
		mapping.ZIndex = PANEL_Z_INDEX + 3
		mapping.Parent = row
	end

	local layout = controlsList:FindFirstChildOfClass("UIListLayout")
	if layout then
		controlsList.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 12)
	end
end

local function setEditMode(active)
	editMode = active == true
	activeDrag = nil
	if editButton then
		editButton.Text = editMode and "Done" or "Edit Layout"
		editButton.BackgroundColor3 = editMode and Color3.fromRGB(255, 211, 102) or Color3.fromRGB(61, 217, 132)
		editButton.TextColor3 = editMode and Color3.fromRGB(46, 33, 4) or Color3.fromRGB(14, 40, 24)
	end
	if resetButton then
		resetButton.Visible = UserInputService.TouchEnabled
	end
	applyAllButtonStates()
end

local function finishDrag()
	if activeDrag and activeDrag.State and activeDrag.State.Button then
		activeDrag.State.Button.ZIndex = BUTTON_Z_INDEX
	end
	activeDrag = nil
end

local function beginDrag(state, input)
	if not state.Button then
		return
	end

	activeDrag = {
		State = state,
		StartInput = toVector2(input.Position),
		StartPosition = state.Button.Position,
	}
	state.Button.ZIndex = BUTTON_Z_INDEX + 10
end

local function ensureTouchButton(state)
	if not UserInputService.TouchEnabled or state.HasTouchButton == false then
		return nil
	end

	if state.Button and state.Button.Parent then
		return state.Button
	end

	local button = getTouchGui():FindFirstChild(state.Id .. "Button")
	if not button or not button:IsA("TextButton") then
		button = Instance.new("TextButton")
		button.Name = state.Id .. "Button"
		button.AnchorPoint = Vector2.new(1, 1)
		button.BorderSizePixel = 0
		button.Font = Enum.Font.GothamBlack
		button.TextScaled = true
		button.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		button.TextStrokeTransparency = 0.35
		button.TextWrapped = true
		button.ZIndex = BUTTON_Z_INDEX
		button.Parent = getTouchGui()
		setRounded(button, state.CornerRadius)
		local stroke = setStroke(button, state.StrokeColor, 2, 0.25)
		stroke.Name = "TouchControlStroke"
	end

	state.Button = button

	button.InputBegan:Connect(function(input)
		if not isTouchPointer(input) then
			return
		end

		if editMode then
			beginDrag(state, input)
			return
		end

		if state.Enabled == false then
			return
		end

		if state.OnBegan then
			state.OnBegan(input)
		end
	end)

	button.InputEnded:Connect(function(input)
		if not isTouchPointer(input) then
			return
		end

		if editMode then
			finishDrag()
			return
		end

		if state.OnEnded then
			state.OnEnded(input)
		end
	end)

	button.MouseLeave:Connect(function()
		if editMode then
			return
		end
		if state.OnEnded then
			state.OnEnded(nil)
		end
	end)

	button.Activated:Connect(function()
		if editMode or state.Enabled == false then
			return
		end
		if state.OnActivated then
			state.OnActivated()
		end
	end)

	applyButtonState(state)
	return button
end

local function makePanelButton(parent, name, text, color, textColor, position, size)
	local button = Instance.new("TextButton")
	button.Name = name
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBlack
	button.Position = position
	button.Size = size
	button.Text = text
	button.TextColor3 = textColor
	button.TextScaled = true
	button.TextWrapped = true
	button.ZIndex = PANEL_Z_INDEX + 3
	button.Parent = parent
	setRounded(button, 5)
	return button
end

local function ensureOptionsGui()
	if optionsGui and optionsGui.Parent then
		return optionsGui
	end

	local existing = playerGui:FindFirstChild(OPTIONS_GUI_NAME)
	if existing and existing:IsA("ScreenGui") then
		optionsGui = existing
		return optionsGui
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = OPTIONS_GUI_NAME
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = OPTIONS_GUI_ORDER
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui
	pcall(function()
		gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	end)
	optionsGui = gui
	return optionsGui
end

local function createOptionsPanel()
	local gui = ensureOptionsGui()
	if optionsPanel and optionsPanel.Parent then
		return
	end

	local toggle = makePanelButton(
		gui,
		"ControlsToggle",
		"Controls",
		Color3.fromRGB(18, 23, 29),
		Color3.fromRGB(224, 236, 245),
		UDim2.new(1, -106, 0, 12),
		UDim2.fromOffset(94, 34)
	)
	toggle.AnchorPoint = Vector2.new(0, 0)
	setStroke(toggle, Color3.fromRGB(102, 217, 255), 1.5, 0.22)

	local panel = Instance.new("Frame")
	panel.Name = "ControlsPanel"
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.BackgroundColor3 = Color3.fromRGB(18, 21, 28)
	panel.BackgroundTransparency = 0.02
	panel.BorderSizePixel = 0
	panel.Position = UDim2.new(1, -12, 0, 54)
	panel.Size = UDim2.new(1, -24, 1, -78)
	panel.Visible = false
	panel.ZIndex = PANEL_Z_INDEX
	panel.Parent = gui
	setRounded(panel, 8)
	setStroke(panel, Color3.fromRGB(86, 98, 116), 1.5, 0.2)
	optionsPanel = panel

	local panelSize = Instance.new("UISizeConstraint")
	panelSize.MaxSize = Vector2.new(360, 386)
	panelSize.MinSize = Vector2.new(280, 250)
	panelSize.Parent = panel

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.Position = UDim2.fromOffset(14, 10)
	title.Size = UDim2.new(1, -80, 0, 24)
	title.Text = "Controls"
	title.TextColor3 = Color3.fromRGB(255, 242, 181)
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = PANEL_Z_INDEX + 2
	title.Parent = panel

	local close = makePanelButton(
		panel,
		"Close",
		"Close",
		Color3.fromRGB(45, 51, 64),
		Color3.fromRGB(224, 236, 245),
		UDim2.new(1, -67, 0, 10),
		UDim2.fromOffset(53, 26)
	)

	local list = Instance.new("ScrollingFrame")
	list.Name = "ControlsList"
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = UDim2.fromOffset(14, 46)
	list.Size = UDim2.new(1, -28, 1, -112)
	list.CanvasSize = UDim2.fromOffset(0, 0)
	list.ScrollBarThickness = 5
	list.ScrollingDirection = Enum.ScrollingDirection.Y
	list.ZIndex = PANEL_Z_INDEX + 1
	list.Parent = panel
	controlsList = list

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 7)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		list.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 12)
	end)

	editButton = makePanelButton(
		panel,
		"EditLayout",
		"Edit Layout",
		Color3.fromRGB(61, 217, 132),
		Color3.fromRGB(14, 40, 24),
		UDim2.new(0, 14, 1, -52),
		UDim2.new(0.5, -21, 0, 36)
	)
	editButton.Visible = UserInputService.TouchEnabled

	resetButton = makePanelButton(
		panel,
		"ResetLayout",
		"Reset",
		Color3.fromRGB(84, 154, 255),
		Color3.fromRGB(14, 27, 46),
		UDim2.new(0.5, 7, 1, -52),
		UDim2.new(0.5, -21, 0, 36)
	)
	resetButton.Visible = UserInputService.TouchEnabled

	toggle.Activated:Connect(function()
		panel.Visible = not panel.Visible
	end)

	close.Activated:Connect(function()
		panel.Visible = false
		setEditMode(false)
	end)

	editButton.Activated:Connect(function()
		setEditMode(not editMode)
	end)

	resetButton.Activated:Connect(function()
		for id in pairs(controlsById) do
			sessionPositions[id] = nil
		end
		applyAllButtonStates()
	end)

	renderOptionsRows()
end

local function register(config, hasTouchButton)
	local id = tostring(config.Id or config.Label or config.Text or "")
	if id == "" then
		error("TouchControls.RegisterAction requires Id")
	end

	local state = controlsById[id]
	if not state then
		state = {
			Id = id,
			Handle = {},
		}
		controlsById[id] = state
	end

	state.HasTouchButton = hasTouchButton
	state.Label = tostring(config.Label or config.Text or id)
	state.Text = tostring(config.Text or config.Label or id)
	state.Desktop = tostring(config.Desktop or "Default")
	state.Xbox = tostring(config.Xbox or "Default")
	state.Touch = tostring(config.Touch or state.Text)
	state.Order = tonumber(config.Order) or 100
	state.DefaultPosition = config.Position or config.DefaultPosition or UDim2.new(1, -92, 1, -176)
	state.Size = config.Size or TOUCH_BUTTON_SIZE
	state.Color = config.Color or Color3.fromRGB(18, 23, 29)
	state.TextColor = config.TextColor or Color3.fromRGB(224, 236, 245)
	state.StrokeColor = config.StrokeColor or Color3.fromRGB(102, 217, 255)
	state.BackgroundTransparency = if config.BackgroundTransparency ~= nil then config.BackgroundTransparency else 0.08
	state.CornerRadius = config.CornerRadius or 8
	state.OnActivated = config.OnActivated
	state.OnBegan = config.OnBegan
	state.OnEnded = config.OnEnded
	state.Visible = config.Visible ~= false
	state.Enabled = config.Enabled ~= false

	upsertOrderedId(id)
	ensureTouchButton(state)
	applyButtonState(state)
	renderOptionsRows()

	local handle = state.Handle
	function handle:SetVisible(visible)
		state.Visible = visible == true
		applyButtonState(state)
	end
	function handle:SetEnabled(enabled)
		state.Enabled = enabled ~= false
		applyButtonState(state)
	end
	function handle:SetText(text)
		state.Text = tostring(text or state.Text)
		applyButtonState(state)
		renderOptionsRows()
	end
	function handle:GetButton()
		return state.Button
	end

	return handle
end

function TouchControls.RegisterAction(config)
	return register(config or {}, true)
end

function TouchControls.RegisterInfo(config)
	return register(config or {}, false)
end

function TouchControls.StartOptionsPanel()
	createOptionsPanel()
end

function TouchControls.SetEditMode(active)
	setEditMode(active)
end

function TouchControls.ResetLayout()
	for id in pairs(controlsById) do
		sessionPositions[id] = nil
	end
	applyAllButtonStates()
end

UserInputService.InputChanged:Connect(function(input)
	if not activeDrag or not activeDrag.State or not activeDrag.State.Button then
		return
	end
	if not isDragMovement(input) then
		return
	end

	local delta = toVector2(input.Position) - activeDrag.StartInput
	local start = activeDrag.StartPosition
	local nextPosition = UDim2.new(
		start.X.Scale,
		start.X.Offset + delta.X,
		start.Y.Scale,
		start.Y.Offset + delta.Y
	)
	nextPosition = clampButtonPosition(activeDrag.State.Button, nextPosition)
	sessionPositions[activeDrag.State.Id] = nextPosition
	activeDrag.State.Button.Position = nextPosition
end)

UserInputService.InputEnded:Connect(function(input)
	if activeDrag and isTouchPointer(input) then
		finishDrag()
	end
end)

UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(function()
	applyAllButtonStates()
	if editButton then
		editButton.Visible = UserInputService.TouchEnabled
	end
	if resetButton then
		resetButton.Visible = UserInputService.TouchEnabled
	end
end)

return TouchControls
