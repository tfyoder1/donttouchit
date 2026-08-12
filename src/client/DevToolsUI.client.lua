local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local devRemote = remotes:WaitForChild(Constants.Remotes.DevTools)

local authorized = false
local gui = nil
local toggleButton = nil
local panel = nil
local statusLabel = nil
local roomList = nil
local presetList = nil
local eventList = nil
local areaList = nil
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
local DEV_DISMISS_START_ATTRIBUTE = "DontTouchItDevDismissedStartIntro"

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
	title.Size = UDim2.new(1, 0, 0, 24)
	title.Text = titleText
	title.TextColor3 = Color3.fromRGB(154, 255, 192)
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = parent
	return title
end

local function makeButton(parent, text, color, onClick)
	local button = Instance.new("TextButton")
	button.BackgroundColor3 = color or Color3.fromRGB(47, 55, 68)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Size = UDim2.new(1, 0, 0, 34)
	button.Text = text
	button.TextColor3 = Color3.fromRGB(238, 247, 255)
	button.TextScaled = true
	button.TextWrapped = true
	button.Parent = parent
	makeCorner(button, 5)

	button.Activated:Connect(onClick)
	return button
end

local function makeList(parent, height)
	local list = Instance.new("Frame")
	list.BackgroundTransparency = 1
	list.Size = UDim2.new(1, 0, 0, height)
	list.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 5)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

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
	flyEnabled = fly == true
	noclipEnabled = noclip == true

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
		if gameProcessed then
			return
		end
		pressedKeys[input.KeyCode] = true
	end))

	table.insert(flyConnections, UserInputService.InputEnded:Connect(function(input)
		pressedKeys[input.KeyCode] = nil
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
		if pressedKeys[Enum.KeyCode.Space] or pressedKeys[Enum.KeyCode.E] then
			direction += Vector3.yAxis
		end
		if pressedKeys[Enum.KeyCode.LeftControl] or pressedKeys[Enum.KeyCode.Q] then
			direction -= Vector3.yAxis
		end

		if direction.Magnitude > 0 then
			direction = direction.Unit
		end

		flyVelocity.Velocity = direction * 55
		flyGyro.CFrame = camera and camera.CFrame or flyGyro.CFrame
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

	makeSection(discoveryList, "Room Log Overrides")
	local unlockedById = getSnapshotUnlockedById(latestState.RoomSnapshot)

	for _, discoveryId in ipairs(getRoomDiscoveryIds(selectedRoomId)) do
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
	}

	makeSection(storeList, "Store Prices")
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

local function rebuildPanel()
	if not latestState or not gui then
		return
	end

	selectedRoomId = selectedRoomId or latestState.CurrentRoomId or Constants.RoomOrder[1]

	clearList(roomList)
	clearList(presetList)
	clearList(eventList)
	clearList(areaList)
	clearList(storeList)

	makeSection(roomList, "Jump To Room")
	for _, room in ipairs(latestState.Rooms or {}) do
		local isSelected = room.Id == selectedRoomId
		makeButton(roomList, (isSelected and "> " or "") .. room.Name, isSelected and Color3.fromRGB(54, 90, 124) or Color3.fromRGB(45, 52, 64), function()
			selectedRoomId = room.Id
			send({
				Action = "JumpToRoom",
				RoomId = room.Id,
			})
		end)
	end

	makeSection(presetList, "Room State")
	for _, presetName in ipairs(latestState.Presets or {}) do
		makeButton(presetList, presetName, Color3.fromRGB(74, 58, 112), function()
			send({
				Action = "SetRoomPreset",
				RoomId = selectedRoomId,
				Preset = presetName,
			})
		end)
	end
	makeButton(presetList, "Complete Current Room", Color3.fromRGB(38, 114, 76), function()
		send({
			Action = "CompleteCurrentRoom",
		})
	end)
	makeButton(presetList, "Reset Current Room", Color3.fromRGB(126, 75, 38), function()
		send({
			Action = "ResetCurrentRoom",
		})
	end)

	makeSection(eventList, "Events")
	makeButton(eventList, "Trigger Random Event", Color3.fromRGB(138, 77, 56), function()
		send({
			Action = "TriggerRandomEvent",
		})
	end)
	for _, eventDefinition in ipairs(latestState.Events or {}) do
		makeButton(eventList, eventDefinition.Id, Color3.fromRGB(89, 67, 117), function()
			send({
				Action = "TriggerSpecificEvent",
				EventId = eventDefinition.Id,
			})
		end)
	end

	makeSection(areaList, "Secret Areas")
	for _, area in ipairs(latestState.SecretAreas or {}) do
		makeButton(areaList, area.Name, Color3.fromRGB(55, 93, 113), function()
			send({
				Action = "TeleportSecretArea",
				AreaId = area.Id,
			})
		end)
	end
	makeButton(areaList, "Unlock All This Session", Color3.fromRGB(35, 103, 68), function()
		send({
			Action = "UnlockAllSession",
		})
	end)
	makeButton(areaList, "Restore Normal Progress", Color3.fromRGB(116, 48, 52), function()
		send({
			Action = "RestoreNormalProgress",
		})
	end)
	makeButton(areaList, (flyEnabled and "Fly: ON" or "Fly: OFF"), flyEnabled and Color3.fromRGB(38, 113, 96) or Color3.fromRGB(64, 70, 82), function()
		send({
			Action = "SetMovement",
			Fly = not flyEnabled,
			Noclip = noclipEnabled,
		})
	end)
	makeButton(areaList, (noclipEnabled and "Noclip: ON" or "Noclip: OFF"), noclipEnabled and Color3.fromRGB(38, 113, 96) or Color3.fromRGB(64, 70, 82), function()
		send({
			Action = "SetMovement",
			Fly = flyEnabled,
			Noclip = not noclipEnabled,
		})
	end)

	rebuildStorePrices()
	rebuildDiscoveries()
	updateStatus()
end

local function buildGui()
	if gui then
		return
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "DontTouchItDevTools"
	gui.IgnoreGuiInset = false
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

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

	local panelConstraint = Instance.new("UISizeConstraint")
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

	roomList = makeList(scroll, 204)
	presetList = makeList(scroll, 246)
	eventList = makeList(scroll, 330)
	areaList = makeList(scroll, 365)
	storeList = makeList(scroll, 525)
	discoveryList = makeList(scroll, 620)

	toggleButton.Activated:Connect(function()
		panel.Visible = not panel.Visible
		if panel.Visible then
			dismissStartOverlayForDevSession()
			send({
				Action = "Refresh",
				RoomId = selectedRoomId,
			})
		end
	end)

	close.Activated:Connect(function()
		panel.Visible = false
	end)
end

devRemote.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end

	if payload.Type == "MovementState" then
		setMovementState(payload.Fly == true, payload.Noclip == true)
		return
	end

	if payload.Authorized ~= true then
		return
	end

	authorized = true
	connectMovementLoops()
	buildGui()

	if typeof(payload.Movement) == "table" then
		setMovementState(payload.Movement.Fly == true, payload.Movement.Noclip == true)
	end

	latestState = payload
	if payload.CurrentRoomId and (not selectedRoomId or payload.Type == "Auth") then
		selectedRoomId = payload.CurrentRoomId
	end

	rebuildPanel()
end)

devRemote:FireServer({
	Action = "Handshake",
})
