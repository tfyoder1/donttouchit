local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local discoveryRemote = remotes:WaitForChild(Constants.Remotes.DiscoveryUpdate)
local roomStatusRemote = remotes:WaitForChild(Constants.Remotes.RoomStatus)

local HUD_NAME = "DontTouchItCoreHud"
local TOUCH_EDIT_MODE_ATTRIBUTE = "DontTouchItTouchEditLayoutActive"
local DEV_LAYOUT_RESET_ATTRIBUTE = "DontTouchItDevLayoutResetNonce"
local BUNKER_ENERGY_MONITOR_ATTRIBUTE = "DontTouchItBunkerEnergyMonitorUnlocked"
local DRAG_MARGIN = 8
local gui = playerGui:FindFirstChild(HUD_NAME)
if gui and gui:IsA("ScreenGui") then
	gui:Destroy()
end

gui = Instance.new("ScreenGui")
gui.Name = HUD_NAME
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 35
gui.Parent = playerGui
pcall(function()
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
end)

local function makePanel(name, anchorPoint, position, size)
	local panel = Instance.new("Frame")
	panel.Name = name
	panel.AnchorPoint = anchorPoint
	panel.BackgroundColor3 = Color3.fromRGB(18, 20, 24)
	panel.BackgroundTransparency = 0.16
	panel.BorderSizePixel = 0
	panel.Position = position
	panel.Size = size
	panel.ZIndex = 2
	panel.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 7)
	corner.Parent = panel

	return panel
end

local topInfoBar = Instance.new("Frame")
topInfoBar.Name = "UnifiedInfoBar"
topInfoBar.AnchorPoint = Vector2.new(0.5, 0)
topInfoBar.BackgroundColor3 = Color3.fromRGB(10, 13, 18)
topInfoBar.BackgroundTransparency = 0.18
topInfoBar.BorderSizePixel = 0
topInfoBar.Position = UDim2.new(0.5, 0, 0, 8)
topInfoBar.Size = UDim2.new(0.78, 0, 0, 88)
topInfoBar.ZIndex = 1
topInfoBar.Parent = gui

local topInfoCorner = Instance.new("UICorner")
topInfoCorner.CornerRadius = UDim.new(0, 8)
topInfoCorner.Parent = topInfoBar

local topInfoStroke = Instance.new("UIStroke")
topInfoStroke.Color = Color3.fromRGB(226, 238, 246)
topInfoStroke.Thickness = 1.5
topInfoStroke.Transparency = 0.18
topInfoStroke.Parent = topInfoBar

local hudItems = {}
local sessionPositions = {}
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

local function isEditMode()
	return playerGui:GetAttribute(TOUCH_EDIT_MODE_ATTRIBUTE) == true
end

local function clampPanelPosition(panel, position)
	local parent = panel.Parent
	if not parent then
		return position
	end

	local parentSize = parent.AbsoluteSize
	if parentSize.X <= 0 or parentSize.Y <= 0 then
		return position
	end

	local size = panel.AbsoluteSize
	local anchor = panel.AnchorPoint
	local absoluteX = parentSize.X * position.X.Scale + position.X.Offset
	local absoluteY = parentSize.Y * position.Y.Scale + position.Y.Offset
	local minX = DRAG_MARGIN + size.X * anchor.X
	local minY = DRAG_MARGIN + size.Y * anchor.Y
	local maxX = math.max(minX, parentSize.X - DRAG_MARGIN - size.X * (1 - anchor.X))
	local maxY = math.max(minY, parentSize.Y - DRAG_MARGIN - size.Y * (1 - anchor.Y))
	local clampedX = math.clamp(absoluteX, minX, maxX)
	local clampedY = math.clamp(absoluteY, minY, maxY)
	return UDim2.new(position.X.Scale, position.X.Offset + (clampedX - absoluteX), position.Y.Scale, position.Y.Offset + (clampedY - absoluteY))
end

local function ensureCoordinateLabel(panel)
	local label = panel:FindFirstChild("HudCoordinateLabel")
	if label and label:IsA("TextLabel") then
		return label
	end

	label = Instance.new("TextLabel")
	label.Name = "HudCoordinateLabel"
	label.Active = false
	label.BackgroundColor3 = Color3.fromRGB(8, 11, 16)
	label.BackgroundTransparency = 0.08
	label.BorderSizePixel = 0
	label.Font = Enum.Font.Code
	label.Position = UDim2.new(0, 0, 0, -22)
	label.Size = UDim2.new(1, 38, 0, 18)
	label.TextColor3 = Color3.fromRGB(226, 245, 255)
	label.TextSize = 10
	label.TextWrapped = false
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.ZIndex = panel.ZIndex + 10
	label.Parent = panel

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = label

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(102, 217, 255)
	stroke.Thickness = 1
	stroke.Transparency = 0.45
	stroke.Parent = label
	return label
end

local function applyHudEditState()
	for id, panel in pairs(hudItems) do
		if panel and panel.Parent then
			local label = ensureCoordinateLabel(panel)
			local anchorPosition = panel.AbsolutePosition + panel.AbsoluteSize * panel.AnchorPoint
			label.Text = ("%s  x=%d y=%d"):format(id, math.floor(anchorPosition.X + 0.5), math.floor(anchorPosition.Y + 0.5))
			label.Visible = isEditMode() and panel.Visible
			panel.Active = isEditMode()
			local stroke = panel:FindFirstChild("HudEditStroke")
			if isEditMode() then
				if not stroke then
					stroke = Instance.new("UIStroke")
					stroke.Name = "HudEditStroke"
					stroke.Color = Color3.fromRGB(255, 255, 255)
					stroke.Thickness = 2
					stroke.Transparency = 0.08
					stroke.Parent = panel
				end
				stroke.Enabled = true
			elseif stroke then
				stroke.Enabled = false
			end
		end
	end
end

local function registerHudItem(id, panel)
	hudItems[id] = panel
	panel.InputBegan:Connect(function(input)
		if not isEditMode() or not isTouchPointer(input) then
			return
		end
		activeDrag = {
			Id = id,
			Panel = panel,
			StartInput = toVector2(input.Position),
			StartPosition = panel.Position,
		}
	end)
end

local function makeLabel(parent, name, text)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.Position = UDim2.fromOffset(9, 2)
	label.Size = UDim2.new(1, -18, 0, 20)
	label.Text = text
	label.TextColor3 = Color3.fromRGB(236, 246, 255)
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function makeTrack(parent, name)
	local track = Instance.new("Frame")
	track.Name = name
	track.BackgroundColor3 = Color3.fromRGB(42, 47, 56)
	track.BorderSizePixel = 0
	track.Position = UDim2.new(0, 9, 1, -9)
	track.Size = UDim2.new(1, -18, 0, 5)
	track.Parent = parent

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, 3)
	trackCorner.Parent = track

	local fill = Instance.new("Frame")
	fill.Name = name .. "Fill"
	fill.BackgroundColor3 = Color3.fromRGB(119, 255, 203)
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(1, 1)
	fill.Parent = track

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 3)
	fillCorner.Parent = fill

	return track, fill
end

local progressPanel = makePanel(
	"DiscoveryProgress",
	Vector2.new(0.5, 0),
	UDim2.new(0.5, 0, 0, 42),
	UDim2.new(0.56, 0, 0, 30)
)
registerHudItem("Discoveries", progressPanel)
local progressLabel = makeLabel(progressPanel, "DiscoveryProgressLabel", "Discoveries: 0 / 0")
local _, progressFill = makeTrack(progressPanel, "DiscoveryProgressTrack")

local roomCounter = makePanel(
	"DiscoveryRoomCounter",
	Vector2.new(0, 0),
	UDim2.new(0, 32, 0, 100),
	UDim2.fromOffset(180, 30)
)
registerHudItem("Room", roomCounter)
local roomCounterLabel = makeLabel(roomCounter, "DiscoveryRoomCounterLabel", "Finding room...")

local energyPanel = makePanel(
	"PlayerEnergy",
	Vector2.new(1, 0),
	UDim2.new(1, -32, 0, 100),
	UDim2.fromOffset(136, 32)
)
registerHudItem("Energy", energyPanel)
local energyLabel = makeLabel(energyPanel, "PlayerEnergyLabel", "Energy 100%")
local _, energyFill = makeTrack(energyPanel, "PlayerEnergyTrack")

local bunkerEnergyPanel = makePanel(
	"BunkerEnergyMonitor",
	Vector2.new(1, 0),
	UDim2.new(0.91, 0, 0, 88),
	UDim2.fromOffset(180, 28)
)
registerHudItem("Bunker", bunkerEnergyPanel)
local bunkerEnergyLabel = makeLabel(bunkerEnergyPanel, "BunkerEnergyLabel", "Bunker 0%")
local _, bunkerEnergyFill = makeTrack(bunkerEnergyPanel, "BunkerEnergyTrack")
bunkerEnergyPanel.Visible = false

local lastDiscoveryPayload = {
	Count = 0,
	Total = Constants.TotalDiscoveries or 0,
}
local lastRoomPayload = nil

local function getReplicatedAttribute(name, fallback)
	local value = player:GetAttribute(name)
	if typeof(value) == "number" then
		return value
	end
	value = playerGui:GetAttribute(name)
	if typeof(value) == "number" then
		return value
	end
	return fallback
end

local function isTitleSplashVisible()
	local splashGui = playerGui:FindFirstChild("DontTouchItTitleSplash")
	return splashGui and splashGui:IsA("ScreenGui") and splashGui.Enabled ~= false
end

local function isTouchLandscape()
	local camera = Workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	return UserInputService.TouchEnabled and viewport.X > viewport.Y
end

local function applyLayout()
	local touchLandscape = isTouchLandscape()
	local sideInset = UserInputService.TouchEnabled and 32 or 18

	if touchLandscape then
		topInfoBar.Position = UDim2.new(0.5, 0, 0, 10)
		topInfoBar.Size = UDim2.new(0.76, -8, 0, 98)
		progressPanel.Position = UDim2.new(0.46, 0, 0, 17)
		progressPanel.Size = UDim2.new(0.46, 0, 0, 28)
		roomCounter.Position = UDim2.new(0.14, 0, 0, 47)
		roomCounter.Size = UDim2.fromOffset(190, 28)
		energyPanel.Position = UDim2.new(0.86, 0, 0, 47)
		energyPanel.Size = UDim2.fromOffset(170, 28)
		bunkerEnergyPanel.Position = UDim2.new(0.86, 0, 0, 76)
		bunkerEnergyPanel.Size = UDim2.fromOffset(170, 24)
	else
		topInfoBar.Position = UDim2.new(0.5, 0, 0, 46)
		topInfoBar.Size = UDim2.new(0.72, 0, 0, 112)
		progressPanel.Position = UDim2.new(0.46, 0, 0, 58)
		progressPanel.Size = UDim2.new(0.44, 0, 0, 32)
		roomCounter.Position = UDim2.new(0.17, 0, 0, 96)
		roomCounter.Size = UDim2.fromOffset(220, 32)
		energyPanel.Position = UDim2.new(0.84, 0, 0, 96)
		energyPanel.Size = UDim2.fromOffset(200, 32)
		bunkerEnergyPanel.Position = UDim2.new(0.84, 0, 0, 130)
		bunkerEnergyPanel.Size = UDim2.fromOffset(200, 28)
	end

	for id, position in pairs(sessionPositions) do
		local panel = hudItems[id]
		if panel and panel.Parent then
			panel.Position = clampPanelPosition(panel, position)
			sessionPositions[id] = panel.Position
		end
	end
	applyHudEditState()
end

local function applyVisibility()
	local hidden = isTitleSplashVisible()
	topInfoBar.Visible = not hidden
	progressPanel.Visible = not hidden
	roomCounter.Visible = not hidden
	energyPanel.Visible = not hidden
	bunkerEnergyPanel.Visible = not hidden and (
		player:GetAttribute(BUNKER_ENERGY_MONITOR_ATTRIBUTE) == true
		or playerGui:GetAttribute(BUNKER_ENERGY_MONITOR_ATTRIBUTE) == true
	)
	applyHudEditState()
end

local function updateEnergy()
	local energy = math.clamp(getReplicatedAttribute("DontTouchItPlayerEnergy", 1), 0, 1)
	local percent = math.floor(energy * 100 + 0.5)
	energyLabel.Text = ("Energy %d%%"):format(percent)
	energyPanel.BackgroundColor3 = if energy <= 0.22
		then Color3.fromRGB(48, 16, 22)
		elseif energy <= 0.48
		then Color3.fromRGB(45, 35, 22)
		else Color3.fromRGB(18, 20, 24)
	energyFill.Size = UDim2.fromScale(energy, 1)
	energyFill.BackgroundColor3 = if energy <= 0.22
		then Color3.fromRGB(255, 96, 102)
		elseif energy <= 0.48
		then Color3.fromRGB(255, 198, 82)
		else Color3.fromRGB(119, 255, 203)
end

local function getBunkerDrawText(hunger)
	if hunger >= 0.66 then
		return "High"
	elseif hunger >= 0.33 then
		return "Med"
	end
	return "Low"
end

local function updateBunkerEnergy()
	local power = math.clamp(getReplicatedAttribute("DontTouchItBunkerPower", 0), 0, 1)
	local hunger = math.clamp(getReplicatedAttribute("DontTouchItBunkerHunger", 0), 0, 1)
	local percent = math.floor(power * 100 + 0.5)
	local color = if hunger >= 0.66
		then Color3.fromRGB(255, 96, 102)
		elseif hunger >= 0.33
		then Color3.fromRGB(255, 198, 82)
		else Color3.fromRGB(119, 255, 203)

	bunkerEnergyLabel.Text = ("Bunker %d%% %s"):format(percent, getBunkerDrawText(hunger))
	bunkerEnergyLabel.TextColor3 = color
	bunkerEnergyFill.Size = UDim2.fromScale(power, 1)
	bunkerEnergyFill.BackgroundColor3 = color
	applyVisibility()
end

local function updateProgress(payload)
	if typeof(payload) == "table" then
		lastDiscoveryPayload = payload
	end

	local count = tonumber(lastDiscoveryPayload.Count) or 0
	local total = math.max(1, tonumber(lastDiscoveryPayload.Total) or Constants.TotalDiscoveries or 1)
	progressLabel.Text = ("Discoveries: %d / %d"):format(count, total)
	progressFill.Size = UDim2.fromScale(math.clamp(count / total, 0, 1), 1)
end

local function updateRoomStatus(payload)
	if typeof(payload) == "table" then
		lastRoomPayload = payload
	end

	local status = lastRoomPayload
	if typeof(status) ~= "table" then
		roomCounterLabel.Text = "Finding room..."
		return
	end

	if status.Type == "Hallway" then
		roomCounterLabel.Text = ("Hall: %d/%d rooms"):format(status.UnlockedRooms or 0, status.TotalRooms or 0)
	elseif status.Type == "Room" then
		roomCounterLabel.Text = ("%s: %d/%d"):format(status.RoomName or "Room", status.Count or 0, status.Total or 0)
	else
		roomCounterLabel.Text = ("Discoveries: %d/%d"):format(
			tonumber(lastDiscoveryPayload.Count) or 0,
			tonumber(lastDiscoveryPayload.Total) or Constants.TotalDiscoveries or 0
		)
	end
end

discoveryRemote.OnClientEvent:Connect(function(payload)
	if typeof(payload) == "table" then
		updateProgress(payload)
		if not lastRoomPayload then
			updateRoomStatus(nil)
		end
	end
end)

roomStatusRemote.OnClientEvent:Connect(function(payload)
	updateRoomStatus(payload)
end)

player:GetAttributeChangedSignal("DontTouchItPlayerEnergy"):Connect(updateEnergy)
playerGui:GetAttributeChangedSignal("DontTouchItPlayerEnergy"):Connect(updateEnergy)
player:GetAttributeChangedSignal("DontTouchItBunkerPower"):Connect(updateBunkerEnergy)
player:GetAttributeChangedSignal("DontTouchItBunkerHunger"):Connect(updateBunkerEnergy)
player:GetAttributeChangedSignal(BUNKER_ENERGY_MONITOR_ATTRIBUTE):Connect(updateBunkerEnergy)
playerGui:GetAttributeChangedSignal("DontTouchItBunkerPower"):Connect(updateBunkerEnergy)
playerGui:GetAttributeChangedSignal("DontTouchItBunkerHunger"):Connect(updateBunkerEnergy)
playerGui:GetAttributeChangedSignal(BUNKER_ENERGY_MONITOR_ATTRIBUTE):Connect(updateBunkerEnergy)
playerGui.ChildAdded:Connect(function(child)
	if child.Name == "DontTouchItTitleSplash" or child.Name == "DontTouchItUI" then
		task.defer(applyVisibility)
	end
end)
playerGui:GetAttributeChangedSignal(TOUCH_EDIT_MODE_ATTRIBUTE):Connect(function()
	if not isEditMode() then
		activeDrag = nil
	end
	applyHudEditState()
end)
playerGui:GetAttributeChangedSignal(DEV_LAYOUT_RESET_ATTRIBUTE):Connect(function()
	table.clear(sessionPositions)
	activeDrag = nil
	applyLayout()
end)

UserInputService.InputChanged:Connect(function(input)
	if not activeDrag or not activeDrag.Panel then
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
	nextPosition = clampPanelPosition(activeDrag.Panel, nextPosition)
	sessionPositions[activeDrag.Id] = nextPosition
	activeDrag.Panel.Position = nextPosition
	applyHudEditState()
end)

UserInputService.InputEnded:Connect(function(input)
	if activeDrag and isTouchPointer(input) then
		activeDrag = nil
	end
end)

UserInputService.TouchEnded:Connect(function()
	activeDrag = nil
end)

UserInputService.LastInputTypeChanged:Connect(function()
	applyLayout()
end)
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	applyLayout()
end)

task.spawn(function()
	while gui.Parent do
		applyVisibility()
		updateEnergy()
		task.wait(0.5)
	end
end)

applyLayout()
applyVisibility()
updateEnergy()
updateBunkerEnergy()
updateProgress(lastDiscoveryPayload)
updateRoomStatus(nil)
