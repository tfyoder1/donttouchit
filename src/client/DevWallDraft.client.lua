local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local DeviceProfile = require(script.Parent:WaitForChild("DeviceProfile"))
local devRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild(Constants.Remotes.DevTools)

local ENABLED_ATTRIBUTE = "DontTouchItDevWallDraftEnabled"
local OWNER_USER_ID = 74299698
local GUI_NAME = "DontTouchItDevWallDraft"
local STEP_MOVE = 0.5
local STEP_MOVE_LARGE = 5
local STEP_SIZE = 0.5
local STEP_ROTATE_DEGREES = 5
local PANEL_SIZE = Vector2.new(430, 370)
local PANEL_DEFAULT_LEFT = 12
local GAMEPAD_STACK_LEFT = 12
local GAMEPAD_STACK_TOP = 142
local GAMEPAD_INSPECT_HEIGHT = 196
local GAMEPAD_DEV_PANEL_HEIGHT = 300
local GAMEPAD_STACK_GAP = 10

if player.UserId ~= OWNER_USER_ID then
	return
end

local gui = nil
local panel = nil
local dataLabel = nil
local wallPart = nil
local visualFolder = nil
local sourcePart = nil
local sourceCFrame = nil
local sourceSize = nil
local draftIntent = "Add"
local cloneSourcePart = nil
local hiddenParts = {}
local deleteCandidate = nil
local currentDeviceProfile = DeviceProfile.Get()

local function fmt(n)
	return string.format("%.2f", n)
end

local function vectorText(v)
	return ("%s, %s, %s"):format(fmt(v.X), fmt(v.Y), fmt(v.Z))
end

local function cframeCode(cf)
	local p = cf.Position
	local rx, ry, rz = cf:ToOrientation()
	return ("CFrame.new(%s, %s, %s) * CFrame.Angles(math.rad(%d), math.rad(%d), math.rad(%d))"):format(
		fmt(p.X),
		fmt(p.Y),
		fmt(p.Z),
		math.floor(math.deg(rx) + 0.5),
		math.floor(math.deg(ry) + 0.5),
		math.floor(math.deg(rz) + 0.5)
	)
end

local function getRotationDegrees(cf)
	local rx, ry, rz = cf:ToOrientation()
	return Vector3.new(math.deg(rx), math.deg(ry), math.deg(rz))
end

local function vectorPayload(v)
	return {
		X = v.X,
		Y = v.Y,
		Z = v.Z,
	}
end

local function getViewportSize()
	local viewport = currentDeviceProfile and currentDeviceProfile.Viewport
	if viewport then
		return viewport
	end

	local camera = Workspace.CurrentCamera
	return camera and camera.ViewportSize or Vector2.new(1024, 768)
end

local function isGamepadProfile()
	return currentDeviceProfile and currentDeviceProfile.IsGamepad == true
end

local function applyPanelLayout()
	if not panel then
		return
	end

	local viewport = getViewportSize()
	local margin = 12
	local left = PANEL_DEFAULT_LEFT
	local top = nil
	local anchor = Vector2.new(0, 0.5)
	if isGamepadProfile() then
		left = GAMEPAD_STACK_LEFT
		top = GAMEPAD_STACK_TOP + GAMEPAD_INSPECT_HEIGHT + GAMEPAD_STACK_GAP + GAMEPAD_DEV_PANEL_HEIGHT + GAMEPAD_STACK_GAP
		anchor = Vector2.zero
	end
	local maxLeft = math.max(margin, viewport.X - PANEL_SIZE.X - margin)

	panel.AnchorPoint = anchor
	if top then
		local maxTop = math.max(margin, viewport.Y - PANEL_SIZE.Y - margin)
		panel.Position = UDim2.fromOffset(math.clamp(left, margin, maxLeft), math.clamp(top, margin, maxTop))
	else
		panel.Position = UDim2.new(0, math.clamp(left, margin, maxLeft), 0.5, 0)
	end
	panel.Size = UDim2.fromOffset(PANEL_SIZE.X, PANEL_SIZE.Y)
	if dataLabel then
		dataLabel.TextSize = isGamepadProfile() and 10 or 9
	end
end

local function destroyVisuals()
	if visualFolder then
		visualFolder:Destroy()
		visualFolder = nil
	end
end

local function ensureVisualFolder()
	if visualFolder and visualFolder.Parent then
		return visualFolder
	end
	visualFolder = Instance.new("Folder")
	visualFolder.Name = "DontTouchItWallDraftVisuals"
	visualFolder.Parent = Workspace
	return visualFolder
end

local function makeVisualPart(name, size, cframe, color, transparency, shape)
	local folder = ensureVisualFolder()
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Color = color
	part.Material = Enum.Material.Neon
	part.Shape = shape or Enum.PartType.Block
	part.Size = size
	part.Transparency = transparency or 0.12
	part.CFrame = cframe
	part.Parent = folder
	return part
end

local function makeVisualLabel(parent, text, color)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = text .. "Label"
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.Size = UDim2.fromOffset(56, 24)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 0.75, 0)
	billboard.Parent = parent

	local label = Instance.new("TextLabel")
	label.BackgroundColor3 = Color3.fromRGB(8, 11, 16)
	label.BackgroundTransparency = 0.18
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBlack
	label.Size = UDim2.fromScale(1, 1)
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.Parent = billboard
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = label
end

local function refreshVisuals()
	destroyVisuals()
	if not wallPart or not wallPart.Parent then
		return
	end

	local cf = wallPart.CFrame
	local size = wallPart.Size
	local axisLength = math.max(3, math.min(10, math.max(size.X, size.Y, size.Z) * 0.55))
	local xColor = Color3.fromRGB(255, 94, 94)
	local yColor = Color3.fromRGB(119, 255, 150)
	local zColor = Color3.fromRGB(94, 170, 255)
	local cornerColor = Color3.fromRGB(255, 231, 112)
	local ringColor = Color3.fromRGB(255, 124, 231)

	local xAxis = makeVisualPart("Axis_X_Red", Vector3.new(axisLength, 0.12, 0.12), cf * CFrame.new(axisLength / 2 + size.X / 2 + 0.3, 0, 0), xColor, 0.08)
	makeVisualLabel(xAxis, "X+", xColor)
	local yAxis = makeVisualPart("Axis_Y_Green", Vector3.new(0.12, axisLength, 0.12), cf * CFrame.new(0, axisLength / 2 + size.Y / 2 + 0.3, 0), yColor, 0.08)
	makeVisualLabel(yAxis, "Y+", yColor)
	local zAxis = makeVisualPart("Axis_Z_Blue", Vector3.new(0.12, 0.12, axisLength), cf * CFrame.new(0, 0, axisLength / 2 + size.Z / 2 + 0.3), zColor, 0.08)
	makeVisualLabel(zAxis, "Z+", zColor)

	for _, sx in ipairs({ -1, 1 }) do
		for _, sy in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				makeVisualPart(
					("DragCorner_%d_%d_%d"):format(sx, sy, sz),
					Vector3.new(0.45, 0.45, 0.45),
					cf * CFrame.new(sx * size.X / 2, sy * size.Y / 2, sz * size.Z / 2),
					cornerColor,
					0.05
				)
			end
		end
	end

	makeVisualPart("Rotate_X_Ring", Vector3.new(0.1, axisLength * 1.05, axisLength * 1.05), cf, ringColor, 0.45, Enum.PartType.Cylinder)
	makeVisualPart("Rotate_Y_Ring", Vector3.new(axisLength * 1.05, 0.1, axisLength * 1.05), cf * CFrame.Angles(0, 0, math.rad(90)), ringColor, 0.45, Enum.PartType.Cylinder)
	makeVisualPart("Rotate_Z_Ring", Vector3.new(axisLength * 1.05, axisLength * 1.05, 0.1), cf * CFrame.Angles(math.rad(90), 0, 0), ringColor, 0.45, Enum.PartType.Cylinder)
end

local function getSourcePath(part)
	if part and part.Parent then
		return part:GetFullName()
	end
	return "-"
end

local function getSourceSearchName(part)
	if part and part.Name and part.Name ~= "" then
		return part.Name
	end
	return wallPart and wallPart.Name or "DraftTemporaryWall"
end

local function getSourceSectionHint(part)
	local path = getSourcePath(part)
	local roomModelName = path:match("^Workspace%.Room%.([^%.]+)")
	if roomModelName then
		return roomModelName
	end
	return "-"
end

local function buildCodeInstructionLines(mode, targetPart, draftPart)
	local sourceName = getSourceSearchName(targetPart)
	local partForValues = draftPart or targetPart
	local lines = {
		("CODE REQUEST: %s"):format(mode),
		("Search RoomBuilder.lua: %q"):format(sourceName),
		("Section Hint: %s"):format(getSourceSectionHint(targetPart)),
		("Source Path: %s"):format(getSourcePath(targetPart)),
	}
	if partForValues then
		table.insert(lines, ("New Size: Vector3.new(%s)"):format(vectorText(partForValues.Size)))
		table.insert(lines, ("New CFrame: %s"):format(cframeCode(partForValues.CFrame)))
	end
	if mode == "DELETE / HIDE WALL" then
		table.insert(lines, "Ask Codex: remove/comment the createPart for this named wall.")
	elseif mode == "MOVE WALL" then
		table.insert(lines, "Ask Codex: move this wall by replacing its CFrame with the New CFrame.")
		table.insert(lines, "Code Note: keep the original Size unless Delta Size is intentionally non-zero.")
	elseif mode == "CLONE WALL" then
		table.insert(lines, "Ask Codex: duplicate this wall's createPart with a unique new name.")
		table.insert(lines, "Code Note: keep the original wall; use the new Size/CFrame for the clone.")
	elseif mode == "UPDATE WALL" then
		table.insert(lines, "Ask Codex: replace that wall's Size/CFrame with these values.")
	else
		table.insert(lines, "Ask Codex: add this as a new generated wall near this room.")
	end
	table.insert(lines, "Code Note: use Search + Section + Source Path to locate the generated createPart.")
	table.insert(lines, "Commit button = live server marker only; screenshot this box for code.")
	return lines
end

local function updateData()
	if not dataLabel then
		return
	end
	if deleteCandidate then
		dataLabel.Text = table.concat(buildCodeInstructionLines("DELETE / HIDE WALL", deleteCandidate, deleteCandidate), "\n")
		return
	end
	if not wallPart then
		dataLabel.Text = "WALL DRAFT\nNew Wall: place a new wall draft.\nSelect Wall: edit an existing wall.\nMove Wall: reposition an existing wall.\nClone Wall: copy an existing wall into a new generated wall.\nX<</X>>: large X moves; X-/X+: fine X moves.\nScreenshot this box after moving/sizing."
		return
	end
	local mode = "ADD WALL"
	local instructionSource = nil
	if draftIntent == "Move" and sourcePart then
		mode = "MOVE WALL"
		instructionSource = sourcePart
	elseif draftIntent == "Clone" and cloneSourcePart then
		mode = "CLONE WALL"
		instructionSource = cloneSourcePart
	elseif sourcePart then
		mode = "UPDATE WALL"
		instructionSource = sourcePart
	end
	local lines = buildCodeInstructionLines(mode, instructionSource, wallPart)
	table.insert(lines, ("Draft Name: %s"):format(wallPart.Name))
	table.insert(lines, ("Rot: %.1f, %.1f, %.1f deg"):format(getRotationDegrees(wallPart.CFrame).X, getRotationDegrees(wallPart.CFrame).Y, getRotationDegrees(wallPart.CFrame).Z))
	if sourcePart and sourceCFrame and sourceSize then
		table.insert(lines, ("Delta Pos: %s"):format(vectorText(wallPart.Position - sourceCFrame.Position)))
		table.insert(lines, ("Delta Size: %s"):format(vectorText(wallPart.Size - sourceSize)))
		table.insert(lines, "Code Note: if the source uses room variables, prefer applying the delta to that expression.")
	end
	dataLabel.Text = table.concat(lines, "\n")
end

local function makeDraftWall(cf, size, source, intent)
	if wallPart then
		wallPart:Destroy()
	end
	wallPart = Instance.new("Part")
	draftIntent = intent or (source and "Update" or "Add")
	cloneSourcePart = if draftIntent == "Clone" then source else nil
	wallPart.Name = if draftIntent == "Clone" and source
		then ("CloneDraft_" .. source.Name)
		elseif source then ("Draft_" .. source.Name)
		else "DraftTemporaryWall"
	wallPart.Anchored = true
	wallPart.CanCollide = false
	wallPart.CanQuery = false
	wallPart.CanTouch = false
	wallPart.Color = Color3.fromRGB(91, 217, 255)
	wallPart.Material = Enum.Material.ForceField
	wallPart.Transparency = 0.42
	wallPart.Size = size or Vector3.new(8, 8, 0.5)
	wallPart.CFrame = cf or CFrame.new(0, 5, 0)
	wallPart.Parent = Workspace
	sourcePart = source
	sourceCFrame = source and source.CFrame or nil
	sourceSize = source and source.Size or nil
	deleteCandidate = nil
	refreshVisuals()
	updateData()
end

local function getCenterTarget()
	local camera = Workspace.CurrentCamera
	if not camera then
		return nil
	end
	local viewport = camera.ViewportSize
	local ray = camera:ViewportPointToRay(viewport.X * 0.5, viewport.Y * 0.5)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character, wallPart }
	local result = Workspace:Raycast(ray.Origin, ray.Direction * 700, params)
	return result and result.Instance or nil, result and result.Position or nil
end

local function nudge(offset)
	if wallPart then
		wallPart.CFrame += offset
		refreshVisuals()
		updateData()
	end
end

local function resize(delta)
	if wallPart then
		wallPart.Size = Vector3.new(
			math.max(0.25, wallPart.Size.X + delta.X),
			math.max(0.25, wallPart.Size.Y + delta.Y),
			math.max(0.25, wallPart.Size.Z + delta.Z)
		)
		refreshVisuals()
		updateData()
	end
end

local function rotate(axis, degrees)
	if not wallPart then
		return
	end
	local rotation = if axis == "X"
		then CFrame.Angles(math.rad(degrees), 0, 0)
		elseif axis == "Y" then CFrame.Angles(0, math.rad(degrees), 0)
		else CFrame.Angles(0, 0, math.rad(degrees))
	wallPart.CFrame = wallPart.CFrame * rotation
	refreshVisuals()
	updateData()
end

local function closeDraft()
	destroyVisuals()
	playerGui:SetAttribute(ENABLED_ATTRIBUTE, false)
	if gui then
		gui.Enabled = false
	end
end

local function commitDraft()
	if deleteCandidate and deleteCandidate.Parent then
		devRemote:FireServer({
			Action = "CommitWallDraft",
			Mode = "Delete",
			SourcePath = deleteCandidate:GetFullName(),
			Position = vectorPayload(deleteCandidate.Position),
			Size = vectorPayload(deleteCandidate.Size),
		})
		return
	end
	if not wallPart then
		return
	end
	devRemote:FireServer({
		Action = "CommitWallDraft",
		Mode = "Wall",
		SourcePath = sourcePart and sourcePart:GetFullName() or "",
		DraftIntent = draftIntent,
		Position = vectorPayload(wallPart.Position),
		Size = vectorPayload(wallPart.Size),
		RotationDegrees = vectorPayload(getRotationDegrees(wallPart.CFrame)),
	})
end

local function makeButton(parent, text, order, callback)
	local button = Instance.new("TextButton")
	button.BackgroundColor3 = Color3.fromRGB(21, 26, 34)
	button.BackgroundTransparency = 0.04
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.LayoutOrder = order
	button.Size = UDim2.new(0, 78, 0, 28)
	button.Text = text
	button.TextColor3 = Color3.fromRGB(226, 245, 255)
	button.TextSize = 11
	button.TextScaled = true
	button.TextWrapped = true
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = button
	local textSizeConstraint = Instance.new("UITextSizeConstraint")
	textSizeConstraint.MinTextSize = 7
	textSizeConstraint.MaxTextSize = 11
	textSizeConstraint.Parent = button
	button.Activated:Connect(callback)
	return button
end

local function makeGridSpacer(parent, order)
	local spacer = Instance.new("Frame")
	spacer.BackgroundTransparency = 1
	spacer.LayoutOrder = order
	spacer.Size = UDim2.fromOffset(64, 28)
	spacer.Parent = parent
	return spacer
end

local function ensureGui()
	if gui and gui.Parent then
		return
	end
	gui = Instance.new("ScreenGui")
	gui.Name = GUI_NAME
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 190
	gui.Parent = playerGui

	panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0, 0.5)
	panel.BackgroundColor3 = Color3.fromRGB(8, 11, 16)
	panel.BackgroundTransparency = 0.05
	panel.BorderSizePixel = 0
	panel.Position = UDim2.new(0, PANEL_DEFAULT_LEFT, 0.5, 0)
	panel.Size = UDim2.fromOffset(PANEL_SIZE.X, PANEL_SIZE.Y)
	panel.Parent = gui
	applyPanelLayout()
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = panel

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.BackgroundColor3 = Color3.fromRGB(33, 40, 50)
	closeButton.BackgroundTransparency = 0.02
	closeButton.BorderSizePixel = 0
	closeButton.Font = Enum.Font.GothamBlack
	closeButton.Position = UDim2.new(1, -8, 0, 8)
	closeButton.Size = UDim2.fromOffset(28, 28)
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(235, 245, 255)
	closeButton.TextSize = 14
	closeButton.Parent = panel
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 7)
	closeCorner.Parent = closeButton
	closeButton.Activated:Connect(closeDraft)

	dataLabel = Instance.new("TextLabel")
	dataLabel.BackgroundTransparency = 1
	dataLabel.Font = Enum.Font.Code
	dataLabel.Position = UDim2.fromOffset(10, 8)
	dataLabel.Size = UDim2.new(1, -50, 0, 154)
	dataLabel.TextColor3 = Color3.fromRGB(196, 249, 255)
	dataLabel.TextSize = isGamepadProfile() and 10 or 9
	dataLabel.TextWrapped = true
	dataLabel.TextXAlignment = Enum.TextXAlignment.Left
	dataLabel.TextYAlignment = Enum.TextYAlignment.Top
	dataLabel.Parent = panel

	local grid = Instance.new("Frame")
	grid.BackgroundTransparency = 1
	grid.Position = UDim2.fromOffset(10, 170)
	grid.Size = UDim2.new(1, -20, 1, -180)
	grid.Parent = panel
	local layout = Instance.new("UIGridLayout")
	layout.CellPadding = UDim2.fromOffset(5, 5)
	layout.CellSize = UDim2.fromOffset(64, 28)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid

	makeButton(grid, "New Wall", 1, function()
		local _, hitPosition = getCenterTarget()
		makeDraftWall(CFrame.new(hitPosition or Vector3.new(0, 5, 0)), Vector3.new(8, 8, 0.5), nil)
	end)
	makeButton(grid, "Select Wall", 2, function()
		local target = getCenterTarget()
		if target and target:IsA("BasePart") then
			makeDraftWall(target.CFrame, target.Size, target, "Update")
		end
	end)
	makeButton(grid, "Move Wall", 3, function()
		local target = getCenterTarget()
		if target and target:IsA("BasePart") then
			makeDraftWall(target.CFrame, target.Size, target, "Move")
		end
	end)
	makeButton(grid, "Clone Wall", 4, function()
		local target = getCenterTarget()
		if target and target:IsA("BasePart") then
			makeDraftWall(target.CFrame, target.Size, target, "Clone")
		end
	end)
	makeButton(grid, "Hide Sel", 5, function()
		local target = sourcePart or getCenterTarget()
		if target and target:IsA("BasePart") then
			deleteCandidate = target
			hiddenParts[target] = { Transparency = target.Transparency, CanCollide = target.CanCollide }
			target.LocalTransparencyModifier = 1
			target.CanCollide = false
			updateData()
		end
	end)
	makeButton(grid, "Clear", 6, function()
		if wallPart then
			wallPart:Destroy()
			wallPart = nil
		end
		destroyVisuals()
		for part, old in pairs(hiddenParts) do
			if part and part.Parent then
				part.LocalTransparencyModifier = 0
				part.CanCollide = old.CanCollide
			end
		end
		table.clear(hiddenParts)
		sourcePart = nil
		sourceCFrame = nil
		sourceSize = nil
		draftIntent = "Add"
		cloneSourcePart = nil
		deleteCandidate = nil
		updateData()
	end)
	makeButton(grid, "Commit", 7, commitDraft)
	makeButton(grid, "Close", 8, closeDraft)
	makeGridSpacer(grid, 9)
	makeGridSpacer(grid, 10)
	makeGridSpacer(grid, 11)
	makeGridSpacer(grid, 12)
	makeButton(grid, "X<<", 20, function() nudge(Vector3.new(-STEP_MOVE_LARGE, 0, 0)) end)
	makeButton(grid, "X>>", 21, function() nudge(Vector3.new(STEP_MOVE_LARGE, 0, 0)) end)
	makeButton(grid, "X-", 22, function() nudge(Vector3.new(-STEP_MOVE, 0, 0)) end)
	makeButton(grid, "X+", 23, function() nudge(Vector3.new(STEP_MOVE, 0, 0)) end)
	makeButton(grid, "Rot X+", 24, function() rotate("X", STEP_ROTATE_DEGREES) end)
	makeButton(grid, "Rot X-", 25, function() rotate("X", -STEP_ROTATE_DEGREES) end)
	makeButton(grid, "Y-", 30, function() nudge(Vector3.new(0, -STEP_MOVE, 0)) end)
	makeButton(grid, "Y+", 31, function() nudge(Vector3.new(0, STEP_MOVE, 0)) end)
	makeButton(grid, "Z-", 32, function() nudge(Vector3.new(0, 0, -STEP_MOVE)) end)
	makeButton(grid, "Z+", 33, function() nudge(Vector3.new(0, 0, STEP_MOVE)) end)
	makeButton(grid, "W-", 40, function() resize(Vector3.new(-STEP_SIZE, 0, 0)) end)
	makeButton(grid, "W+", 41, function() resize(Vector3.new(STEP_SIZE, 0, 0)) end)
	makeButton(grid, "H-", 42, function() resize(Vector3.new(0, -STEP_SIZE, 0)) end)
	makeButton(grid, "H+", 43, function() resize(Vector3.new(0, STEP_SIZE, 0)) end)
	makeButton(grid, "D-", 44, function() resize(Vector3.new(0, 0, -STEP_SIZE)) end)
	makeButton(grid, "D+", 45, function() resize(Vector3.new(0, 0, STEP_SIZE)) end)
	makeButton(grid, "Rot Y-", 50, function() rotate("Y", -STEP_ROTATE_DEGREES) end)
	makeButton(grid, "Rot Y+", 51, function() rotate("Y", STEP_ROTATE_DEGREES) end)
	makeButton(grid, "Rot Z-", 52, function() rotate("Z", -STEP_ROTATE_DEGREES) end)
	makeButton(grid, "Rot Z+", 53, function() rotate("Z", STEP_ROTATE_DEGREES) end)
	updateData()
end

local function setEnabled(enabled)
	if enabled then
		ensureGui()
		gui.Enabled = true
	else
		destroyVisuals()
		if gui then
			gui.Enabled = false
		end
	end
end

playerGui:GetAttributeChangedSignal(ENABLED_ATTRIBUTE):Connect(function()
	setEnabled(playerGui:GetAttribute(ENABLED_ATTRIBUTE) == true)
end)

DeviceProfile.Bind(function(profile)
	currentDeviceProfile = profile
	applyPanelLayout()
end)

RunService.RenderStepped:Connect(function()
	if gui and gui.Enabled and wallPart then
		updateData()
	end
end)

setEnabled(playerGui:GetAttribute(ENABLED_ATTRIBUTE) == true)
