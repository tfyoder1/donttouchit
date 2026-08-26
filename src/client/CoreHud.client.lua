local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local UiLayerController = require(script.Parent:WaitForChild("UiLayerController"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local discoveryRemote = remotes:WaitForChild(Constants.Remotes.DiscoveryUpdate)
local roomStatusRemote = remotes:WaitForChild(Constants.Remotes.RoomStatus)
local uiLayoutRemote = remotes:WaitForChild(Constants.Remotes.UiLayout)

local HUD_NAME = UiLayerController.GuiNames.CoreHud
local TOUCH_EDIT_MODE_ATTRIBUTE = "DontTouchItTouchEditLayoutActive"
local DEV_LAYOUT_RESET_ATTRIBUTE = "DontTouchItDevLayoutResetNonce"
local BUNKER_ENERGY_MONITOR_ATTRIBUTE = "DontTouchItBunkerEnergyMonitorUnlocked"
local SIGNAL_BAND_ATTRIBUTE = "DontTouchItSignalBandEquipped"
local DRAG_MARGIN = 8
local gui = playerGui:FindFirstChild(HUD_NAME)
if gui and gui:IsA("ScreenGui") then
	gui:Destroy()
end

gui = Instance.new("ScreenGui")
gui.Name = HUD_NAME
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
UiLayerController.ApplyRole(gui, "CoreHud")
gui.Parent = playerGui
pcall(function()
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
end)

local function makePanel(name, anchorPoint, position, size)
	local panel = Instance.new("Frame")
	panel.Name = name
	panel.AnchorPoint = anchorPoint
	panel.BackgroundColor3 = Color3.fromRGB(18, 20, 24)
	panel.BackgroundTransparency = 0.22
	panel.BorderSizePixel = 0
	panel.Position = position
	panel.Size = size
	panel.ZIndex = 4
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
topInfoBar.BackgroundTransparency = 1
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
topInfoStroke.Transparency = 1
topInfoStroke.Parent = topInfoBar

local topInfoDividers = {}
for index = 1, 3 do
	local divider = Instance.new("Frame")
	divider.Name = "UnifiedInfoDivider" .. index
	divider.AnchorPoint = Vector2.new(0.5, 0.5)
	divider.BackgroundColor3 = Color3.fromRGB(226, 238, 246)
	divider.BackgroundTransparency = 1
	divider.BorderSizePixel = 0
	divider.Position = UDim2.fromScale(index / 4, 0.5)
	divider.Size = UDim2.new(0, 1, 1, -10)
	divider.ZIndex = 2
	divider.Parent = topInfoBar
	topInfoDividers[index] = divider
end

local hudItems = {}
local sessionPositions = {}
local activeDrag = nil
local loadedLayout = {}
local layoutSaveQueued = false

local function udim2ToPayload(position)
	return {
		XScale = position.X.Scale,
		XOffset = position.X.Offset,
		YScale = position.Y.Scale,
		YOffset = position.Y.Offset,
	}
end

local function payloadToUdim2(payload)
	if typeof(payload) ~= "table" then
		return nil
	end

	return UDim2.new(
		tonumber(payload.XScale) or 0,
		tonumber(payload.XOffset) or 0,
		tonumber(payload.YScale) or 0,
		tonumber(payload.YOffset) or 0
	)
end

local function buildLayoutPayload()
	local layout = {}
	for key, value in pairs(loadedLayout) do
		layout[key] = value
	end
	for id, position in pairs(sessionPositions) do
		layout[id] = udim2ToPayload(position)
	end
	return layout
end

local function saveLayoutNow()
	uiLayoutRemote:FireServer({
		Action = "Save",
		Layout = buildLayoutPayload(),
	})
end

local function queueSaveLayout()
	if layoutSaveQueued then
		return
	end

	layoutSaveQueued = true
	task.delay(0.35, function()
		layoutSaveQueued = false
		saveLayoutNow()
	end)
end

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
	label.TextScaled = false
	label.TextSize = 12
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.TextStrokeTransparency = 0.25
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = parent.ZIndex + 2
	label.Parent = parent
	return label
end

local function makeTrack(parent, name)
	local track = Instance.new("Frame")
	track.Name = name
	track.BackgroundColor3 = Color3.fromRGB(74, 84, 99)
	track.BackgroundTransparency = 0.18
	track.BorderSizePixel = 0
	track.ZIndex = parent.ZIndex + 1
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
	fill.ZIndex = track.ZIndex + 1
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
local roomCountByRoomId = {}
local lastRoomSparkleAt = 0

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
	return UiLayerController.IsTitleSplashVisible(playerGui)
end

local function isTouchLandscape()
	local camera = Workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	return UserInputService.TouchEnabled and viewport.X > viewport.Y
end

local function setPanelTop(panel, top)
	local delta = top - panel.AbsolutePosition.Y
	panel.Position = clampPanelPosition(
		panel,
		UDim2.new(panel.Position.X.Scale, panel.Position.X.Offset, panel.Position.Y.Scale, panel.Position.Y.Offset + delta)
	)
end

local function nudgePanelRight(panel, amount)
	panel.Position = clampPanelPosition(
		panel,
		UDim2.new(panel.Position.X.Scale, panel.Position.X.Offset + amount, panel.Position.Y.Scale, panel.Position.Y.Offset)
	)
end

local function separatePanelPair(leftPanel, rightPanel, gap)
	if isEditMode() or activeDrag then
		return
	end
	if not leftPanel.Visible or not rightPanel.Visible then
		return
	end

	local leftRight = leftPanel.AbsolutePosition.X + leftPanel.AbsoluteSize.X
	local rightLeft = rightPanel.AbsolutePosition.X
	local top = math.max(leftPanel.AbsolutePosition.Y, rightPanel.AbsolutePosition.Y)
	local bottom = math.min(
		leftPanel.AbsolutePosition.Y + leftPanel.AbsoluteSize.Y,
		rightPanel.AbsolutePosition.Y + rightPanel.AbsoluteSize.Y
	)
	if bottom <= top or rightLeft - leftRight >= gap then
		return
	end

	nudgePanelRight(rightPanel, gap - (rightLeft - leftRight))

	leftRight = leftPanel.AbsolutePosition.X + leftPanel.AbsoluteSize.X
	rightLeft = rightPanel.AbsolutePosition.X
	if rightLeft - leftRight < 0 then
		setPanelTop(rightPanel, leftPanel.AbsolutePosition.Y + leftPanel.AbsoluteSize.Y + gap)
	end
end

local function separateVerticalPair(topPanel, bottomPanel, gap)
	if isEditMode() or activeDrag then
		return
	end
	if not topPanel.Visible or not bottomPanel.Visible then
		return
	end

	local topBottom = topPanel.AbsolutePosition.Y + topPanel.AbsoluteSize.Y
	local bottomTop = bottomPanel.AbsolutePosition.Y
	if bottomTop - topBottom >= gap then
		return
	end

	setPanelTop(bottomPanel, topBottom + gap)
end

local function separateVisibleHudPanels()
	separatePanelPair(roomCounter, progressPanel, 10)
	separateVerticalPair(energyPanel, bunkerEnergyPanel, UserInputService.TouchEnabled and 4 or 8)
end

local function applyLayout()
	local touchLandscape = isTouchLandscape()
	local sideInset = UserInputService.TouchEnabled and 32 or 18

	if touchLandscape then
		topInfoBar.Position = UDim2.new(0.5, 0, 0, 8)
		topInfoBar.Size = UDim2.new(0.97, 0, 0, 32)
		roomCounter.Position = UDim2.new(0.012, 0, 0, 8)
		roomCounter.Size = UDim2.new(0.14, -4, 0, 28)
		progressPanel.Position = UDim2.new(0.16, 0, 0, 8)
		progressPanel.Size = UDim2.new(0.36, -4, 0, 28)
		energyPanel.Position = UDim2.new(0.54, 0, 0, 8)
		energyPanel.Size = UDim2.new(0.36, -4, 0, 28)
		bunkerEnergyPanel.Position = UDim2.new(0.54, 0, 0, 38)
		bunkerEnergyPanel.Size = UDim2.new(0.36, -4, 0, 22)
		roomCounterLabel.TextSize = 12
		progressLabel.TextSize = 12
		energyLabel.TextSize = 12
		bunkerEnergyLabel.TextSize = 11
	else
		topInfoBar.Position = UDim2.new(0.5, 0, 0, 44)
		topInfoBar.Size = UDim2.new(0.94, 0, 0, 52)
		roomCounter.Position = UDim2.new(0.105, 0, 0, 48)
		roomCounter.Size = UDim2.fromOffset(315, 42)
		progressPanel.Position = UDim2.new(0.43, 0, 0, 48)
		progressPanel.Size = UDim2.fromOffset(292, 42)
		energyPanel.Position = UDim2.new(0.76, 0, 0, 48)
		energyPanel.Size = UDim2.fromOffset(292, 42)
		bunkerEnergyPanel.Position = UDim2.new(0.76, 0, 0, 94)
		bunkerEnergyPanel.Size = UDim2.fromOffset(292, 36)
		roomCounter.BackgroundTransparency = 0.12
		progressPanel.BackgroundTransparency = 0.12
		energyPanel.BackgroundTransparency = 0.12
		bunkerEnergyPanel.BackgroundTransparency = 0.12
		roomCounterLabel.TextSize = 17
		progressLabel.TextSize = 17
		energyLabel.TextSize = 17
		bunkerEnergyLabel.TextSize = 15
	end

	for id, position in pairs(sessionPositions) do
		local panel = hudItems[id]
		if panel and panel.Parent then
			panel.Position = clampPanelPosition(panel, position)
			sessionPositions[id] = panel.Position
		end
	end
	separateVisibleHudPanels()
	applyHudEditState()
end

local function applyVisibility()
	local hidden = isTitleSplashVisible()
	local signalBandEquipped = player:GetAttribute(SIGNAL_BAND_ATTRIBUTE) == true
		or playerGui:GetAttribute(SIGNAL_BAND_ATTRIBUTE) == true
	local hudVisible = not hidden and signalBandEquipped
	topInfoBar.Visible = hudVisible
	progressPanel.Visible = hudVisible
	roomCounter.Visible = hudVisible
	energyPanel.Visible = hudVisible
	bunkerEnergyPanel.Visible = hudVisible and (
		player:GetAttribute(BUNKER_ENERGY_MONITOR_ATTRIBUTE) == true
		or playerGui:GetAttribute(BUNKER_ENERGY_MONITOR_ATTRIBUTE) == true
	)
	separateVisibleHudPanels()
	applyHudEditState()
end

local function updateEnergy()
	local energy = math.clamp(getReplicatedAttribute("DontTouchItPlayerEnergy", 1), 0, 1)
	local percent = math.floor(energy * 100 + 0.5)
	energyLabel.Text = ("Energy %d%%"):format(percent)
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

local function getGuiLocalPoint(screenPoint)
	local guiPosition = gui.AbsolutePosition
	return Vector2.new(screenPoint.X - guiPosition.X, screenPoint.Y - guiPosition.Y)
end

local function playRoomDiscoverySparkle(amount)
	if not gui.Parent or not roomCounter.Visible then
		return
	end

	local now = os.clock()
	if now - lastRoomSparkleAt < 0.2 then
		return
	end
	lastRoomSparkleAt = now

	local target = getGuiLocalPoint(roomCounter.AbsolutePosition + roomCounter.AbsoluteSize * Vector2.new(0.5, 0.5))
	local source = getGuiLocalPoint(Vector2.new(gui.AbsoluteSize.X * 0.5, gui.AbsoluteSize.Y * 0.72))
	local count = math.clamp(math.floor(amount or 1) + 3, 4, 8)

	for index = 1, count do
		local sparkle = Instance.new("Frame")
		sparkle.Name = "RoomDiscoverySparkle"
		sparkle.AnchorPoint = Vector2.new(0.5, 0.5)
		sparkle.BackgroundColor3 = if index % 2 == 0
			then Color3.fromRGB(255, 242, 125)
			else Color3.fromRGB(119, 255, 203)
		sparkle.BorderSizePixel = 0
		sparkle.Position = UDim2.fromOffset(source.X + (index - count / 2) * 9, source.Y + (index % 3) * 8)
		sparkle.Rotation = 45
		sparkle.Size = UDim2.fromOffset(7, 7)
		sparkle.ZIndex = 80
		sparkle.Parent = gui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = sparkle

		local midway = source:Lerp(target, 0.48) + Vector2.new((index - count / 2) * 18, -34 - (index % 2) * 18)
		local firstTween = TweenService:Create(
			sparkle,
			TweenInfo.new(0.28 + index * 0.018, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = UDim2.fromOffset(midway.X, midway.Y),
				Size = UDim2.fromOffset(10, 10),
			}
		)
		local secondTween = TweenService:Create(
			sparkle,
			TweenInfo.new(0.34, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(target.X, target.Y),
				Size = UDim2.fromOffset(3, 3),
			}
		)

		firstTween.Completed:Connect(function()
			if sparkle.Parent then
				secondTween:Play()
			end
		end)
		secondTween.Completed:Connect(function()
			if sparkle.Parent then
				sparkle:Destroy()
			end
		end)
		firstTween:Play()
	end

	local originalSize = roomCounter.Size
	local expandedSize = UDim2.new(
		originalSize.X.Scale,
		originalSize.X.Offset + 8,
		originalSize.Y.Scale,
		originalSize.Y.Offset + 4
	)
	local pulseOut = TweenService:Create(roomCounter, TweenInfo.new(0.11, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = expandedSize,
	})
	local pulseIn = TweenService:Create(roomCounter, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = originalSize,
	})
	pulseOut.Completed:Connect(function()
		if roomCounter.Parent then
			pulseIn:Play()
		end
	end)
	pulseOut:Play()
end

local function trackRoomCount(roomId, count)
	if typeof(roomId) ~= "string" or typeof(count) ~= "number" then
		return
	end

	local previous = roomCountByRoomId[roomId]
	roomCountByRoomId[roomId] = count
	if previous and count > previous then
		playRoomDiscoverySparkle(count - previous)
	end
end

local function updateRoomCountsFromDiscoveryPayload(payload)
	if typeof(payload) ~= "table" or typeof(payload.Rooms) ~= "table" then
		return
	end
	local currentRoomId = if typeof(lastRoomPayload) == "table" then lastRoomPayload.RoomId else nil
	if typeof(currentRoomId) ~= "string" then
		return
	end

	for _, room in ipairs(payload.Rooms) do
		if typeof(room) == "table" and room.RoomId == currentRoomId then
			trackRoomCount(currentRoomId, tonumber(room.Count))
			return
		end
	end
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
		trackRoomCount(status.RoomId, tonumber(status.Count))
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
		if payload.Id == Constants.Discoveries.SecurityBunkerEnergy.Id then
			playerGui:SetAttribute(BUNKER_ENERGY_MONITOR_ATTRIBUTE, true)
			playerGui:SetAttribute(SIGNAL_BAND_ATTRIBUTE, true)
		end
		updateProgress(payload)
		updateRoomCountsFromDiscoveryPayload(payload)
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
player:GetAttributeChangedSignal(SIGNAL_BAND_ATTRIBUTE):Connect(applyVisibility)
playerGui:GetAttributeChangedSignal("DontTouchItBunkerPower"):Connect(updateBunkerEnergy)
playerGui:GetAttributeChangedSignal("DontTouchItBunkerHunger"):Connect(updateBunkerEnergy)
playerGui:GetAttributeChangedSignal(BUNKER_ENERGY_MONITOR_ATTRIBUTE):Connect(updateBunkerEnergy)
playerGui:GetAttributeChangedSignal(SIGNAL_BAND_ATTRIBUTE):Connect(applyVisibility)
playerGui.ChildAdded:Connect(function(child)
	if child.Name == UiLayerController.GuiNames.TitleSplash or child.Name == UiLayerController.GuiNames.DiscoveryUI then
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
		queueSaveLayout()
		activeDrag = nil
	end
end)

UserInputService.TouchEnded:Connect(function()
	if activeDrag then
		queueSaveLayout()
		activeDrag = nil
	end
end)

UserInputService.LastInputTypeChanged:Connect(function()
	applyLayout()
end)
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	applyLayout()
end)

uiLayoutRemote.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" or payload.Action ~= "Loaded" then
		return
	end
	if isEditMode() or activeDrag then
		return
	end

	loadedLayout = if typeof(payload.Layout) == "table" then payload.Layout else {}
	table.clear(sessionPositions)
	for id, _ in pairs(hudItems) do
		local position = payloadToUdim2(loadedLayout[id])
		if position then
			sessionPositions[id] = position
		end
	end
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
uiLayoutRemote:FireServer({
	Action = "Request",
})
