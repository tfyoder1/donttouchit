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
	panel.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 7)
	corner.Parent = panel

	return panel
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
local progressLabel = makeLabel(progressPanel, "DiscoveryProgressLabel", "Discoveries: 0 / 0")
local _, progressFill = makeTrack(progressPanel, "DiscoveryProgressTrack")

local roomCounter = makePanel(
	"DiscoveryRoomCounter",
	Vector2.new(0, 0),
	UDim2.new(0, 32, 0, 100),
	UDim2.fromOffset(180, 30)
)
local roomCounterLabel = makeLabel(roomCounter, "DiscoveryRoomCounterLabel", "Finding room...")

local energyPanel = makePanel(
	"PlayerEnergy",
	Vector2.new(1, 0),
	UDim2.new(1, -32, 0, 100),
	UDim2.fromOffset(136, 32)
)
local energyLabel = makeLabel(energyPanel, "PlayerEnergyLabel", "Energy 100%")
local _, energyFill = makeTrack(energyPanel, "PlayerEnergyTrack")

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

local function isLegacyStartOverlayVisible()
	local legacyGui = playerGui:FindFirstChild("DontTouchItUI")
	local overlay = legacyGui and legacyGui:FindFirstChild("StartChoiceOverlay", true)
	return overlay and overlay:IsA("GuiObject") and overlay.Visible == true
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
		progressPanel.Position = UDim2.new(0.5, 0, 0, 42)
		progressPanel.Size = UDim2.new(0.56, 0, 0, 30)
		roomCounter.Position = UDim2.new(0, sideInset, 0, 100)
		roomCounter.Size = UDim2.fromOffset(180, 30)
		energyPanel.Position = UDim2.new(1, -sideInset, 0, 100)
		energyPanel.Size = UDim2.fromOffset(136, 32)
	else
		progressPanel.Position = UDim2.new(0.5, 0, 0, 74)
		progressPanel.Size = UDim2.new(0.72, 0, 0, 36)
		roomCounter.Position = UDim2.new(0, sideInset, 0, 126)
		roomCounter.Size = UDim2.fromOffset(240, 34)
		energyPanel.Position = UDim2.new(1, -sideInset, 0, 126)
		energyPanel.Size = UDim2.fromOffset(210, 36)
	end
end

local function applyVisibility()
	local hidden = isTitleSplashVisible() or isLegacyStartOverlayVisible()
	progressPanel.Visible = not hidden
	roomCounter.Visible = not hidden
	energyPanel.Visible = not hidden
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
playerGui.ChildAdded:Connect(function(child)
	if child.Name == "DontTouchItTitleSplash" or child.Name == "DontTouchItUI" then
		task.defer(applyVisibility)
	end
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
updateProgress(lastDiscoveryPayload)
updateRoomStatus(nil)
