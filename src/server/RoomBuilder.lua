local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local ResetService = require(script.Parent:WaitForChild("ResetService"))

local RoomBuilder = {}

local ROOM_ATTRIBUTE = "DontTouchItGenerated"
local BOWLING_COSMIC_COLORS = {
	Color3.fromRGB(119, 255, 203),
	Color3.fromRGB(255, 88, 128),
	Color3.fromRGB(150, 112, 255),
	Color3.fromRGB(255, 232, 92),
	Color3.fromRGB(93, 217, 255),
}

local function tag(instance, tagName)
	CollectionService:AddTag(instance, tagName)
end

local function mark(instance)
	ResetService.MarkBaseline(instance)
	return instance
end

local function createPart(parent, name, size, cframe, color, material, className)
	local part = Instance.new(className or "Part")
	part.Name = name
	part.Anchored = true
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.TopSurface = Enum.SurfaceType.Smooth
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Parent = parent
	mark(part)
	return part
end

local function createPrompt(parent, actionText, objectText, holdDuration)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "InteractPrompt"
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = holdDuration or 0
	prompt.RequiresLineOfSight = false
	prompt.ClickablePrompt = true
	prompt.MaxActivationDistance = 10
	prompt.Parent = parent
	mark(prompt)
	return prompt
end

local function createSpawnLocation(parent, name, roomId, destinationCFrame, color, enabled)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = name
	spawn.Anchored = true
	spawn.BottomSurface = Enum.SurfaceType.Smooth
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Size = Vector3.new(7, 1, 7)
	local spawnPosition = destinationCFrame.Position - Vector3.new(0, 2.45, 0)
	spawn.CFrame = CFrame.new(spawnPosition) * (destinationCFrame - destinationCFrame.Position)
	spawn.Color = color
	spawn.Material = Enum.Material.Neon
	spawn.Neutral = true
	spawn.Enabled = enabled == true
	spawn.Transparency = 0.32
	spawn:SetAttribute("RoomId", roomId)
	spawn:SetAttribute("DestinationCFrame", destinationCFrame)
	spawn.Parent = parent
	mark(spawn)
	return spawn
end

local function createSurfaceText(parent, name, text, face, textColor, backgroundColor)
	local gui = Instance.new("SurfaceGui")
	gui.Name = name .. "SurfaceGui"
	gui.Face = face or Enum.NormalId.Front
	gui.LightInfluence = 0.2
	gui.PixelsPerStud = 55
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundColor3 = backgroundColor or Color3.fromRGB(20, 20, 24)
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBlack
	label.Size = UDim2.fromScale(1, 1)
	label.Text = text
	label.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = gui
	mark(label)

	return label
end

local function createNoTouchClock(parent, name, roomId, size, cframe, face)
	local clock = createPart(parent, name, size, cframe, Color3.fromRGB(24, 28, 34), Enum.Material.Metal)
	clock:SetAttribute("RoomId", roomId)
	local label = createSurfaceText(clock, "ClockText", "Still 0.0 / 2.0m\nRoom 0.0m", face, Color3.fromRGB(255, 242, 181), Color3.fromRGB(24, 28, 34))
	label.Font = Enum.Font.GothamBold
	tag(clock, Constants.Tags.NoTouchClock)
	return clock
end

local function createReferenceBookcaseFace(door)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "ReferenceBookcaseSurfaceGui"
	gui.Face = Enum.NormalId.Back
	gui.LightInfluence = 0.18
	gui.PixelsPerStud = 60
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.Parent = door
	mark(gui)

	local frame = Instance.new("Frame")
	frame.Name = "ReferenceBookcaseFrame"
	frame.BackgroundColor3 = Color3.fromRGB(66, 41, 30)
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = gui

	local title = Instance.new("TextLabel")
	title.Name = "ReferenceBookcaseTitle"
	title.BackgroundColor3 = Color3.fromRGB(96, 62, 40)
	title.BorderSizePixel = 0
	title.Font = Enum.Font.GothamBlack
	title.Position = UDim2.fromScale(0.06, 0.04)
	title.Size = UDim2.fromScale(0.88, 0.13)
	title.Text = "REFERENCE BOOKCASE"
	title.TextColor3 = Color3.fromRGB(255, 235, 149)
	title.TextScaled = true
	title.TextWrapped = true
	title.Parent = frame
	mark(title)

	for row = 1, 4 do
		local shelfY = 0.2 + (row - 1) * 0.19
		local shelf = Instance.new("Frame")
		shelf.Name = "ReferenceShelf" .. row
		shelf.BackgroundColor3 = Color3.fromRGB(104, 67, 43)
		shelf.BorderSizePixel = 0
		shelf.Position = UDim2.fromScale(0.06, shelfY + 0.12)
		shelf.Size = UDim2.fromScale(0.88, 0.026)
		shelf.Parent = frame

		for bookIndex = 1, 9 do
			local book = Instance.new("Frame")
			book.Name = ("ReferenceBook%d_%d"):format(row, bookIndex)
			book.BackgroundColor3 = Color3.fromRGB(
				74 + (bookIndex * 29 + row * 11) % 135,
				46 + (bookIndex * 17 + row * 31) % 125,
				70 + (bookIndex * 23 + row * 13) % 120
			)
			book.BorderSizePixel = 0
			book.Position = UDim2.fromScale(0.08 + (bookIndex - 1) * 0.092, shelfY + 0.01 + (bookIndex % 2) * 0.014)
			book.Size = UDim2.fromScale(0.055 + (bookIndex % 3) * 0.012, 0.11 - (bookIndex % 2) * 0.015)
			book.Parent = frame
		end
	end
end

local function clearGeneratedFolder(name)
	local existing = workspace:FindFirstChild(name)
	if existing and existing:GetAttribute(ROOM_ATTRIBUTE) then
		existing:Destroy()
	end
end

local function createFolder(parent, name)
	local folder = Instance.new("Folder")
	folder.Name = name
	folder:SetAttribute(ROOM_ATTRIBUTE, true)
	folder.Parent = parent
	return folder
end

local function makeModel(parent, name)
	local model = Instance.new("Model")
	model.Name = name
	model:SetAttribute(ROOM_ATTRIBUTE, true)
	model.Parent = parent
	return model
end

local function cframeAt(origin, x, y, z)
	return CFrame.new(origin + Vector3.new(x, y, z))
end

local function createBeamBetween(parent, name, startPosition, endPosition, thickness, color, material)
	local midpoint = (startPosition + endPosition) / 2
	local distance = (endPosition - startPosition).Magnitude
	local beam = createPart(
		parent,
		name,
		Vector3.new(thickness, thickness, distance),
		CFrame.new(midpoint, endPosition),
		color,
		material or Enum.Material.Metal
	)
	beam.CanCollide = false
	beam:SetAttribute("BaseCanCollide", false)
	return beam
end

local function makeFloor(roomFolder)
	local floorFolder = Instance.new("Folder")
	floorFolder.Name = "FloorSections"
	floorFolder.Parent = roomFolder

	local sectionColumns = 4
	local sectionRows = 4
	local sectionWidth = Constants.Room.Width / sectionColumns
	local sectionDepth = Constants.Room.Depth / sectionRows

	for column = 1, sectionColumns do
		for row = 1, sectionRows do
			local x = -Constants.Room.Width / 2 + sectionWidth * (column - 0.5)
			local z = -Constants.Room.Depth / 2 + sectionDepth * (row - 0.5)
			local floor = createPart(
				floorFolder,
				("Floor_%d_%d"):format(column, row),
				Vector3.new(sectionWidth + 0.05, 1, sectionDepth + 0.05),
				CFrame.new(x, Constants.Room.FloorY, z),
				Color3.fromRGB(122, 132, 128),
				Enum.Material.Concrete
			)

			local prompt = createPrompt(floor, "Press", "The Floor", 0)
			prompt.MaxActivationDistance = 7
			tag(floor, Constants.Tags.FloorSection)
		end
	end

	local recoveryFloor = createPart(
		roomFolder,
		"RecoveryFloor",
		Vector3.new(Constants.Room.Width + 18, 1, Constants.Room.Depth + 18),
		CFrame.new(0, Constants.Room.RecoveryY, 0),
		Color3.fromRGB(75, 168, 255),
		Enum.Material.SmoothPlastic
	)
	recoveryFloor.Transparency = 0.25
	recoveryFloor:SetAttribute("BaseTransparency", recoveryFloor.Transparency)

	return floorFolder, recoveryFloor
end

local function makeShell(roomFolder)
	local width = Constants.Room.Width
	local depth = Constants.Room.Depth
	local height = Constants.Room.TVHeight
	local wallColor = Color3.fromRGB(178, 184, 182)
	local doorWidth = 7
	local doorHeight = 10
	local sideWallWidth = (width - doorWidth) / 2

	createPart(roomFolder, "BackWall", Vector3.new(width, height, 1), CFrame.new(0, height / 2, -depth / 2), wallColor, Enum.Material.SmoothPlastic)
	createPart(roomFolder, "LeftWall", Vector3.new(1, height, depth), CFrame.new(-width / 2, height / 2, 0), wallColor, Enum.Material.SmoothPlastic)
	createPart(roomFolder, "RightWall", Vector3.new(1, height, depth), CFrame.new(width / 2, height / 2, 0), wallColor, Enum.Material.SmoothPlastic)
	createPart(roomFolder, "FrontWallLeft", Vector3.new(sideWallWidth, height, 1), CFrame.new(-(doorWidth / 2 + sideWallWidth / 2), height / 2, depth / 2), wallColor, Enum.Material.SmoothPlastic)
	createPart(roomFolder, "FrontWallRight", Vector3.new(sideWallWidth, height, 1), CFrame.new(doorWidth / 2 + sideWallWidth / 2, height / 2, depth / 2), wallColor, Enum.Material.SmoothPlastic)
	createPart(roomFolder, "FrontWallHeader", Vector3.new(doorWidth, height - doorHeight, 1), CFrame.new(0, doorHeight + (height - doorHeight) / 2, depth / 2), wallColor, Enum.Material.SmoothPlastic)
	createPart(roomFolder, "Ceiling", Vector3.new(width, 1, depth), CFrame.new(0, height, 0), Color3.fromRGB(138, 144, 142), Enum.Material.Concrete)

	local door = createPart(
		roomFolder,
		"EntranceDoor",
		Vector3.new(7, 10, 0.45),
		CFrame.new(0, 5.1, depth / 2 - 0.53),
		Color3.fromRGB(72, 102, 119),
		Enum.Material.Wood
	)
	createSurfaceText(door, "DoorText", "ENTRANCE?", Enum.NormalId.Front, Color3.fromRGB(230, 255, 240), Color3.fromRGB(42, 66, 76))
	createPrompt(door, "Inspect", "Entrance?", 0)
	door:SetAttribute("DestinationCFrame", CFrame.new(0, 3, depth / 2 + 9))
	tag(door, Constants.Tags.ExitDoor)

	return door
end

local function makeTVRoomClocks(roomFolder)
	createNoTouchClock(
		roomFolder,
		"TVRoomWallClock",
		"TVRoom",
		Vector3.new(0.28, 2.3, 5.6),
		CFrame.new(Constants.Room.Width / 2 - 0.57, 8.2, 6.4),
		Enum.NormalId.Left
	)

	createNoTouchClock(
		roomFolder,
		"TVRoomPedestalClock",
		"TVRoom",
		Vector3.new(4.2, 1.05, 0.22),
		CFrame.new(0, 2.75, 2.9) * CFrame.Angles(0, 0, math.rad(180)),
		Enum.NormalId.Front
	)
end

local function makeSpawn(roomFolder)
	return createSpawnLocation(
		roomFolder,
		"TVRoomSpawn",
		"TVRoom",
		Constants.GetRoomSpawnCFrame("TVRoom"),
		Color3.fromRGB(91, 188, 124),
		true
	)
end

local function makePedestal(objectsFolder)
	local pedestal = makeModel(objectsFolder, "Pedestal")

	local base = createPart(
		pedestal,
		"PedestalBase",
		Vector3.new(5.2, 2.8, 5.2),
		CFrame.new(0, 1.9, 0),
		Color3.fromRGB(72, 76, 82),
		Enum.Material.Metal,
		"Part"
	)

	createPart(
		pedestal,
		"ButtonPlate",
		Vector3.new(5.25, 0.34, 5.25),
		CFrame.new(0, 3.42, 0),
		Color3.fromRGB(28, 30, 34),
		Enum.Material.Metal
	)

	for screwIndex, offset in ipairs({
		Vector3.new(-2.1, 0, -2.1),
		Vector3.new(2.1, 0, -2.1),
		Vector3.new(-2.1, 0, 2.1),
		Vector3.new(2.1, 0, 2.1),
	}) do
		local screw = createPart(
			pedestal,
			"BigRedButtonScrew" .. screwIndex,
			Vector3.new(0.12, 0.42, 0.42),
			CFrame.new(offset.X, 3.65, offset.Z) * CFrame.Angles(0, 0, math.rad(90)),
			Color3.fromRGB(197, 204, 210),
			Enum.Material.Metal
		)
		screw.Shape = Enum.PartType.Cylinder
	end

	local buttonBase = createPart(
		pedestal,
		"BigRedButtonBase",
		Vector3.new(0.22, 4.55, 4.55),
		CFrame.new(0, 3.76, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(18, 18, 22),
		Enum.Material.SmoothPlastic,
		"Part"
	)
	buttonBase.Shape = Enum.PartType.Cylinder

	local redSkirt = createPart(
		pedestal,
		"BigRedButtonRedSkirt",
		Vector3.new(0.42, 4.35, 4.35),
		CFrame.new(0, 3.98, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(166, 10, 20),
		Enum.Material.SmoothPlastic,
		"Part"
	)
	redSkirt.Shape = Enum.PartType.Cylinder

	local ringCrown = createPart(
		pedestal,
		"BigRedButtonUpperRing",
		Vector3.new(4.45, 0.54, 4.45),
		CFrame.new(0, 4.12, 0),
		Color3.fromRGB(214, 16, 28),
		Enum.Material.SmoothPlastic,
		"Part"
	)
	ringCrown.Shape = Enum.PartType.Ball

	local groove = createPart(
		pedestal,
		"BigRedButtonInnerGroove",
		Vector3.new(0.1, 3.62, 3.62),
		CFrame.new(0, 4.28, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(25, 5, 7),
		Enum.Material.SmoothPlastic,
		"Part"
	)
	groove.Shape = Enum.PartType.Cylinder
	groove.CanCollide = false
	groove:SetAttribute("BaseCanCollide", false)

	local button = createPart(
		pedestal,
		"BigRedButton",
		Vector3.new(3.55, 0.62, 3.55),
		CFrame.new(0, 4.44, 0),
		Color3.fromRGB(242, 17, 28),
		Enum.Material.SmoothPlastic,
		"Part"
	)
	button.Shape = Enum.PartType.Ball
	button:SetAttribute("PressedCFrame", CFrame.new(0, 4.2, 0))
	button:SetAttribute("ButtonVisualGroup", "TVMainButtonCap")

	local ringShine = createPart(
		pedestal,
		"BigRedButtonRingShine",
		Vector3.new(1.25, 0.08, 0.34),
		CFrame.new(-1.6, 4.42, -0.82) * CFrame.Angles(0, math.rad(-18), math.rad(-16)),
		Color3.fromRGB(255, 107, 116),
		Enum.Material.Neon,
		"Part"
	)
	ringShine.Shape = Enum.PartType.Ball
	ringShine.CanCollide = false
	ringShine.Transparency = 0.18
	ringShine:SetAttribute("BaseCanCollide", false)
	mark(ringShine)

	local shine = createPart(
		pedestal,
		"BigRedButtonShine",
		Vector3.new(1.05, 0.08, 0.42),
		CFrame.new(0.76, 4.79, -0.62) * CFrame.Angles(0, 0, math.rad(16)),
		Color3.fromRGB(255, 190, 196),
		Enum.Material.Neon,
		"Part"
	)
	shine.Shape = Enum.PartType.Ball
	shine.CanCollide = false
	shine.Transparency = 0.12
	shine:SetAttribute("BaseCanCollide", false)
	shine:SetAttribute("ButtonVisualGroup", "TVMainButtonCap")
	mark(shine)

	local buttonPrompt = createPrompt(button, "Press", "Absolutely Do Not Touch", 0.15)
	buttonPrompt.GamepadKeyCode = Enum.KeyCode.ButtonB
	tag(button, Constants.Tags.MainButton)

	local sign = createPart(
		pedestal,
		"DontTouchItSign",
		Vector3.new(9, 3, 0.35),
		CFrame.new(0, 6.4, -3.35),
		Color3.fromRGB(245, 234, 93),
		Enum.Material.SmoothPlastic
	)
	createSurfaceText(sign, "SignText", "DON'T TOUCH IT", Enum.NormalId.Back, Color3.fromRGB(25, 25, 25), Color3.fromRGB(245, 234, 93))

	pedestal.PrimaryPart = base
	return pedestal
end

local function makeLightSwitch(parent, name, baseCFrame, options)
	options = options or {}
	local scale = options.Scale or 1

	local switch = makeModel(parent, name or "LightSwitch")
	baseCFrame = baseCFrame or CFrame.new(-6.15, 4.55, Constants.Room.Depth / 2 - 0.58)
	if options.RoomId then
		switch:SetAttribute("RoomId", options.RoomId)
	end
	if options.UnlocksGiantDiscovery then
		switch:SetAttribute("UnlocksGiantDiscovery", true)
	end

	local plate = createPart(
		switch,
		"SwitchPlate",
		Vector3.new(1.15 * scale, 1.85 * scale, 0.18 * scale),
		baseCFrame,
		Color3.fromRGB(238, 238, 226),
		Enum.Material.SmoothPlastic
	)
	local leverNeutralCFrame = baseCFrame * CFrame.new(0, 0.05 * scale, -0.2 * scale)
	local leverOnCFrame = leverNeutralCFrame * CFrame.Angles(math.rad(-18), 0, 0)
	local leverOffCFrame = leverNeutralCFrame * CFrame.Angles(math.rad(18), 0, 0)
	local lever = createPart(
		switch,
		"SwitchLever",
		Vector3.new(0.26 * scale, 0.88 * scale, 0.22 * scale),
		leverOnCFrame,
		Color3.fromRGB(244, 244, 238),
		Enum.Material.Metal
	)
	lever:SetAttribute("SwitchOnCFrame", leverOnCFrame)
	lever:SetAttribute("SwitchOffCFrame", leverOffCFrame)

	plate:SetAttribute("IsOn", true)
	createSurfaceText(plate, "SwitchText", options.Label or "LIGHT", Enum.NormalId.Front, Color3.fromRGB(34, 34, 32), Color3.fromRGB(238, 238, 226))
	local prompt = createPrompt(plate, "Flip", options.PromptObjectText or "Light Switch", 0)
	prompt.MaxActivationDistance = options.MaxActivationDistance or 7
	tag(switch, Constants.Tags.LightSwitch)
	if options.HighlightTag then
		tag(switch, options.HighlightTag)
	end

	switch.PrimaryPart = plate
	return switch, { plate, lever }
end

local function makeCouch(objectsFolder)
	local couch = makeModel(objectsFolder, "Couch")
	couch:SetAttribute("RideDirection", Vector3.new(1, 0, 0))

	local baseColor = Color3.fromRGB(74, 139, 158)
	local seat = createPart(couch, "CouchSeat", Vector3.new(8, 1, 3.2), CFrame.new(-14, 1.1, 3), baseColor, Enum.Material.Fabric)
	local sitTarget = createPart(couch, "CouchSitTarget", Vector3.new(2.8, 0.5, 2.2), CFrame.new(-14, 1.8, 3), baseColor, Enum.Material.SmoothPlastic, "Seat")
	sitTarget.Transparency = 1
	sitTarget.CanCollide = false
	sitTarget.CanTouch = false
	mark(sitTarget)
	local back = createPart(couch, "CouchBack", Vector3.new(8.4, 3.4, 0.8), CFrame.new(-14, 2.4, 4.8), Color3.fromRGB(62, 121, 139), Enum.Material.Fabric)
	local leftArm = createPart(couch, "LeftArm", Vector3.new(0.8, 2.2, 3.6), CFrame.new(-18.4, 1.8, 3.2), Color3.fromRGB(62, 121, 139), Enum.Material.Fabric)
	local rightArm = createPart(couch, "RightArm", Vector3.new(0.8, 2.2, 3.6), CFrame.new(-9.6, 1.8, 3.2), Color3.fromRGB(62, 121, 139), Enum.Material.Fabric)

	couch.PrimaryPart = seat
	createPrompt(seat, "Sit", "Suspicious Couch", 0)
	tag(couch, Constants.Tags.Couch)

	return couch, { seat, sitTarget, back, leftArm, rightArm }
end

local function makeLamp(objectsFolder)
	local lamp = makeModel(objectsFolder, "FloorLamp")

	local base = createPart(lamp, "LampBase", Vector3.new(2.2, 0.25, 2.2), CFrame.new(14, 0.72, -9), Color3.fromRGB(58, 58, 66), Enum.Material.Metal)
	local pole = createPart(lamp, "LampPole", Vector3.new(0.25, 5.6, 0.25), CFrame.new(14, 3.35, -9), Color3.fromRGB(44, 44, 52), Enum.Material.Metal)
	local shade = createPart(lamp, "LampShade", Vector3.new(2.6, 1.2, 2.6), CFrame.new(14, 6.25, -9), Color3.fromRGB(255, 231, 125), Enum.Material.SmoothPlastic)
	shade.Shape = Enum.PartType.Cylinder
	shade.Name = "LampShade"

	for index = 1, 5 do
		local bead = createPart(
			lamp,
			"LampChainBead",
			Vector3.new(0.16, 0.16, 0.16),
			CFrame.new(15.05, 6.15 - index * 0.24, -8.35),
			Color3.fromRGB(214, 203, 168),
			Enum.Material.Metal
		)
		bead.Shape = Enum.PartType.Ball
	end

	local chainHandle = createPart(
		lamp,
		"LampPullHandle",
		Vector3.new(0.34, 0.34, 0.34),
		CFrame.new(15.05, 4.65, -8.35),
		Color3.fromRGB(255, 235, 136),
		Enum.Material.Metal
	)
	chainHandle.Shape = Enum.PartType.Ball

	local light = Instance.new("PointLight")
	light.Name = "LampLight"
	light.Brightness = 1.6
	light.Color = Color3.fromRGB(255, 239, 176)
	light.Enabled = false
	light.Range = 17
	light.Parent = shade
	mark(light)

	createPrompt(shade, "Toggle", "Floor Lamp", 0)
	tag(lamp, Constants.Tags.FloorLamp)

	lamp.PrimaryPart = pole
	return lamp, { base, pole, shade }
end

local function makeTableAndAppliance(objectsFolder)
	local tableModel = makeModel(objectsFolder, "Table")
	createPart(tableModel, "TableTop", Vector3.new(8, 0.45, 4), CFrame.new(9, 2.3, 6), Color3.fromRGB(132, 92, 62), Enum.Material.Wood)

	for xOffset = -3, 3, 6 do
		for zOffset = -1.4, 1.4, 2.8 do
			createPart(tableModel, "TableLeg", Vector3.new(0.35, 3, 0.35), CFrame.new(9 + xOffset, 1.15, 6 + zOffset), Color3.fromRGB(100, 69, 47), Enum.Material.Wood)
		end
	end

	local appliance = makeModel(objectsFolder, "TinyAppliance")
	local body = createPart(appliance, "ApplianceBody", Vector3.new(3.8, 2.1, 2.2), CFrame.new(9, 3.65, 6), Color3.fromRGB(205, 209, 214), Enum.Material.Metal)
	local door = createPart(appliance, "ApplianceDoor", Vector3.new(3.4, 1.6, 0.15), CFrame.new(9, 3.65, 4.86), Color3.fromRGB(38, 42, 47), Enum.Material.Glass)
	createSurfaceText(door, "ApplianceText", "00:00", Enum.NormalId.Front, Color3.fromRGB(109, 255, 177), Color3.fromRGB(23, 28, 31))
	createPrompt(door, "Start", "Tiny Appliance", 0)
	tag(appliance, Constants.Tags.Appliance)
	appliance.PrimaryPart = body
end

local function makeSquishy(objectsFolder)
	local squishy = createPart(
		objectsFolder,
		"SquishyObject",
		Vector3.new(3, 1.6, 3),
		CFrame.new(-7, 1.3, -8),
		Color3.fromRGB(238, 121, 183),
		Enum.Material.SmoothPlastic
	)
	squishy.Shape = Enum.PartType.Ball
	createPrompt(squishy, "Squeeze", "Squishy Thing", 0)
	tag(squishy, Constants.Tags.Squishy)
	return squishy
end

local function makeTelevision(objectsFolder)
	local tv = makeModel(objectsFolder, "Television")

	local body = createPart(tv, "TVBody", Vector3.new(7.6, 4.6, 0.7), CFrame.new(0, 3.2, -15.2), Color3.fromRGB(16, 18, 22), Enum.Material.Metal)
	local screen = createPart(tv, "TVScreen", Vector3.new(6.8, 3.7, 0.2), CFrame.new(0, 3.25, -14.8), Color3.fromRGB(37, 43, 53), Enum.Material.Glass)
	local stand = createPart(tv, "TVStand", Vector3.new(2.5, 0.6, 1.7), CFrame.new(0, 0.85, -15.2), Color3.fromRGB(18, 19, 22), Enum.Material.Metal)

	local text = createSurfaceText(screen, "TVText", "NO SIGNAL", Enum.NormalId.Back, Color3.fromRGB(202, 248, 255), Color3.fromRGB(26, 30, 36))
	text.Font = Enum.Font.Code
	text.TextScaled = true
	ResetService.MarkBaseline(text)

	createPrompt(body, "Power", "Television", 0)
	tag(tv, Constants.Tags.Television)

	tv.PrimaryPart = body
	return tv, { body, screen, stand }
end

local function makeUnderfloorChamber(roomFolder, recoveryFloor)
	local chamber = makeModel(roomFolder, "UnderfloorChamber")
	local y = Constants.Room.RecoveryY
	local width = Constants.Room.Width + 14
	local depth = Constants.Room.Depth + 14
	local wallColor = Color3.fromRGB(61, 70, 82)

	recoveryFloor.Name = "UnderfloorFloor"
	recoveryFloor.Color = Color3.fromRGB(55, 88, 123)
	recoveryFloor.Material = Enum.Material.Concrete
	recoveryFloor.Transparency = 0.05
	recoveryFloor:SetAttribute("BaseTransparency", recoveryFloor.Transparency)

	createPart(chamber, "UnderfloorBackWall", Vector3.new(width, 8, 1), CFrame.new(0, y + 4, -depth / 2), wallColor, Enum.Material.Concrete)
	createPart(chamber, "UnderfloorFrontWall", Vector3.new(width, 8, 1), CFrame.new(0, y + 4, depth / 2), wallColor, Enum.Material.Concrete)
	createPart(chamber, "UnderfloorLeftWall", Vector3.new(1, 8, depth), CFrame.new(-width / 2, y + 4, 0), wallColor, Enum.Material.Concrete)
	createPart(chamber, "UnderfloorRightWall", Vector3.new(1, 8, depth), CFrame.new(width / 2, y + 4, 0), wallColor, Enum.Material.Concrete)
	local subLevelOneFloor = createPart(chamber, "SubLevel1Floor", Vector3.new(width, 0.45, depth), CFrame.new(0, y + 8.2, 0), Color3.fromRGB(40, 47, 58), Enum.Material.Concrete)
	createSurfaceText(subLevelOneFloor, "SubLevel1FloorText", "SUB LEVEL 1", Enum.NormalId.Top, Color3.fromRGB(106, 255, 196), Color3.fromRGB(40, 47, 58))

	local subLevelOneSign = createPart(chamber, "SubLevel1Sign", Vector3.new(13.5, 2.1, 0.3), CFrame.new(0, y + 12, depth / 2 - 2.2), Color3.fromRGB(106, 255, 196), Enum.Material.Neon)
	createSurfaceText(subLevelOneSign, "SubLevel1SignText", "SUB LEVEL 1\nRAIN SORTING DECK", Enum.NormalId.Front, Color3.fromRGB(12, 26, 24), Color3.fromRGB(106, 255, 196))

	local subLevelOnePad = createPart(chamber, "SubLevel1ReturnPad", Vector3.new(6.5, 0.35, 6.5), CFrame.new(-16.5, y + 8.65, 12.5), Color3.fromRGB(61, 217, 132), Enum.Material.Neon)
	subLevelOnePad.Transparency = 0.12
	subLevelOnePad:SetAttribute("BaseTransparency", subLevelOnePad.Transparency)
	subLevelOnePad:SetAttribute("DestinationCFrame", CFrame.new(0, 5, 10))
	createSurfaceText(subLevelOnePad, "SubLevel1PadText", "UP\nTO TV", Enum.NormalId.Top, Color3.fromRGB(12, 26, 24), Color3.fromRGB(61, 217, 132))
	createPrompt(subLevelOnePad, "Return", "Sub Level 1 Elevator Pad", 0)
	tag(subLevelOnePad, Constants.Tags.UnderfloorReturn)

	local sign = createPart(chamber, "UnderfloorSign", Vector3.new(12, 2.2, 0.3), CFrame.new(0, y + 4.7, -depth / 2 + 0.55), Color3.fromRGB(106, 255, 196), Enum.Material.Neon)
	createSurfaceText(sign, "UnderfloorSignText", "SUB LEVEL 2\nFLOOR LOST & FOUND", Enum.NormalId.Front, Color3.fromRGB(12, 26, 24), Color3.fromRGB(106, 255, 196))
	createSurfaceText(sign, "UnderfloorSignBackText", "SUB LEVEL 2\nFLOOR LOST & FOUND", Enum.NormalId.Back, Color3.fromRGB(12, 26, 24), Color3.fromRGB(106, 255, 196))

	local pad = createPart(chamber, "UnderfloorReturnPad", Vector3.new(6.5, 0.35, 6.5), CFrame.new(0, y + 0.72, 5.5), Color3.fromRGB(61, 217, 132), Enum.Material.Neon)
	pad.Transparency = 0.12
	pad:SetAttribute("BaseTransparency", pad.Transparency)
	pad:SetAttribute("DestinationCFrame", CFrame.new(0, 5, 10))
	createPrompt(pad, "Return", "Elevator Pad", 0)
	tag(pad, Constants.Tags.UnderfloorReturn)

	local ceilingButton = createPart(chamber, "UnderfloorCeilingButton", Vector3.new(2.4, 0.7, 2.4), CFrame.new(0, y + 7.62, -4), Color3.fromRGB(235, 47, 61), Enum.Material.Neon)
	ceilingButton.Shape = Enum.PartType.Ball
	ceilingButton:SetAttribute("DestinationCFrame", CFrame.new(0, 5, 10))
	createPrompt(ceilingButton, "Press", "Ceiling Button", 0)
	tag(ceilingButton, Constants.Tags.UnderfloorReturn)

	local light = Instance.new("PointLight")
	light.Name = "UnderfloorReturnLight"
	light.Brightness = 2.3
	light.Color = Color3.fromRGB(116, 255, 205)
	light.Range = 18
	light.Parent = pad
	mark(light)

	local subLevelOneLight = Instance.new("PointLight")
	subLevelOneLight.Name = "SubLevel1ReturnLight"
	subLevelOneLight.Brightness = 1.9
	subLevelOneLight.Color = Color3.fromRGB(116, 255, 205)
	subLevelOneLight.Range = 16
	subLevelOneLight.Parent = subLevelOnePad
	mark(subLevelOneLight)

	local safetyFloor = createPart(chamber, "UnderfloorSafetyNet", Vector3.new(width + 10, 1, depth + 10), CFrame.new(0, y - 14, 0), Color3.fromRGB(61, 217, 132), Enum.Material.Neon)
	safetyFloor.Transparency = 0.6
	safetyFloor:SetAttribute("BaseTransparency", safetyFloor.Transparency)
	safetyFloor:SetAttribute("DestinationCFrame", CFrame.new(0, y + 3, 5.5))

	return chamber, safetyFloor
end

local HALLWAY_SPAWN_CFRAME = CFrame.new(0, 3, 27)
local TV_ROOM_RETURN_CFRAME = CFrame.new(0, 3, 10)
local LIBRARY_WIDTH = 36
local LIBRARY_DEPTH = 34
local LIBRARY_HEIGHT = 15
local TV_SECRET_ROOM_ORIGIN = Vector3.new(-14, 0, -45)
local TV_SECRET_ROOM_ENTRY_CFRAME = CFrame.new(-14, 3, -29) * CFrame.Angles(0, math.rad(180), 0)
local TV_SECRET_ROOM_RETURN_CFRAME = CFrame.new(-14, 3, -10.5)
local BOWLING_ALLEY_ORIGIN = Vector3.new(-14, 0, -132)
local BOWLING_ALLEY_SPAWN_CFRAME = CFrame.new(-14, 3, -84)
local BOWLING_ALLEY_RETURN_CFRAME = CFrame.new(Vector3.new(-7, 3, -58), Vector3.new(-14, 3, -45))
local BOWLING_MAINTENANCE_CFRAME = CFrame.new(-14, 3, -175)
local LIBRARY_LOFT_SPAWN_CFRAME = CFrame.new(Vector3.new(-14, 17.6, -45), Vector3.new(-14, 17.6, -36))
local LIBRARY_LOFT_RETURN_CFRAME = CFrame.new(Vector3.new(-8.8, 10.6, -13.0), Vector3.new(-8.8, 9.8, -16.55))
local TREETOP_ENTRY_CFRAME = CFrame.new(Vector3.new(-14, 29, -220), Vector3.new(-7, 29, -240))
local TREETOP_ZIPLINE_END_CFRAME = CFrame.new(Vector3.new(0, 5.8, 132), Vector3.new(0, 4, 154))
local TREETOP_ZIPLINE_PATH_POINTS = {
	Vector3.new(-14, 32, -229),
	Vector3.new(16, 44, -156),
	Vector3.new(16, 52, -48),
	Vector3.new(-24, 46, 58),
	Vector3.new(-10, 28, 108),
	TREETOP_ZIPLINE_END_CFRAME.Position + Vector3.new(0, 5, 0),
}
local SNACK_LAB_ORIGIN = Vector3.new(48, 0, 44)
local SNACK_LAB_SPAWN_CFRAME = cframeAt(SNACK_LAB_ORIGIN, -11, 3, 10)
local ISLAND_ORIGIN = Vector3.new(0, 0, 150)
local ISLAND_SPAWN_CFRAME = Constants.GetRoomSpawnCFrame("Island")
local ISLAND_RETURN_CFRAME = CFrame.new(Vector3.new(0, 3, 103), Vector3.new(0, 3, 88))
local SPACE_STATION_ORIGIN = Vector3.new(92, 80, 150)
local SPACE_STATION_SPAWN_CFRAME = Constants.GetRoomSpawnCFrame("SpaceStation")
local ISLAND_SPACE_BLOCK_ID = "bent_palm_orbit_block"

local function makeSnackCeilingFan(objectsFolder)
	local fan = makeModel(objectsFolder, "SnackCeilingFan")
	local origin = SNACK_LAB_ORIGIN
	local center = cframeAt(origin, 0, Constants.Room.Height - 1.25, 3.2)

	createPart(fan, "FanStem", Vector3.new(0.32, 1.2, 0.32), center * CFrame.new(0, 0.75, 0), Color3.fromRGB(74, 84, 94), Enum.Material.Metal)

	local hub = createPart(fan, "FanHub", Vector3.new(1.3, 0.55, 1.3), center, Color3.fromRGB(80, 95, 108), Enum.Material.Metal)
	hub.Shape = Enum.PartType.Ball

	for index = 1, 4 do
		local angle = math.rad((index - 1) * 90)
		local blade = createPart(
			fan,
			"FanBlade",
			Vector3.new(4.2, 0.18, 0.72),
			center * CFrame.Angles(0, angle, 0) * CFrame.new(2.65, 0, 0),
			Color3.fromRGB(210, 232, 238),
			Enum.Material.SmoothPlastic
		)
		blade:SetAttribute("BladeIndex", index)
	end

	local button = createPart(
		fan,
		"FanPullButton",
		Vector3.new(1.1, 0.34, 1.1),
		center * CFrame.new(0, -0.58, 0) * CFrame.Angles(math.rad(90), 0, 0),
		Color3.fromRGB(93, 217, 255),
		Enum.Material.Neon
	)
	button.Shape = Enum.PartType.Cylinder

	local label = createPart(fan, "FanLabel", Vector3.new(5.6, 0.16, 1.55), center * CFrame.new(0, -0.95, 2.7), Color3.fromRGB(38, 45, 55), Enum.Material.Metal)
	createSurfaceText(label, "FanLabelText", "GRAVITY\nAPOLOGY FAN", Enum.NormalId.Bottom, Color3.fromRGB(185, 246, 255), Color3.fromRGB(38, 45, 55))

	local prompt = createPrompt(button, "Pull", "Gravity Apology Fan", 0)
	prompt.MaxActivationDistance = 22
	tag(button, Constants.Tags.SnackCeilingFan)

	fan.PrimaryPart = hub
	return fan
end

local function makeHallDoor(parent, name, size, cframe, face, label, destinationCFrame, lockedMessage, roomId)
	local door = createPart(parent, name, size, cframe, Color3.fromRGB(79, 92, 116), Enum.Material.Wood)
	createSurfaceText(door, "DoorText", label, face, Color3.fromRGB(232, 245, 255), Color3.fromRGB(38, 48, 64))

	local prompt = createPrompt(door, lockedMessage and "Knock" or "Enter", label, 0)
	if destinationCFrame then
		door:SetAttribute("DestinationCFrame", destinationCFrame)
	end
	if roomId then
		door:SetAttribute("RoomId", roomId)
	end
	if lockedMessage then
		door:SetAttribute("LockedMessage", lockedMessage)
		prompt.ActionText = "Knock"
	end

	tag(door, Constants.Tags.HallDoor)
	return door
end

local function makeCompactReferenceBook(parent, name, cframe, roomId, title, options)
	options = options or {}
	local width = options.Width or 2.35
	local height = options.Height or 1.7
	local log = makeModel(parent, name)

	local back = createPart(
		log,
		"DigitalLogBack",
		Vector3.new(width, height, 0.16),
		cframe,
		Color3.fromRGB(34, 39, 47),
		Enum.Material.Metal
	)
	local screen = createPart(
		log,
		"DigitalLogScreen",
		Vector3.new(width - 0.34, height - 0.4, 0.08),
		cframe * CFrame.new(0, -0.08, -0.13),
		Color3.fromRGB(4, 10, 8),
		Enum.Material.Neon
	)
	local clip = createPart(
		log,
		"DigitalLogClip",
		Vector3.new(width * 0.42, 0.14, 0.1),
		cframe * CFrame.new(0, height / 2 - 0.18, -0.18),
		Color3.fromRGB(118, 130, 144),
		Enum.Material.Metal
	)
	clip.CanCollide = false
	clip:SetAttribute("BaseCanCollide", false)

	screen:SetAttribute("RoomId", roomId)
	screen:SetAttribute("FixtureType", "DigitalRoomLog")
	createSurfaceText(screen, "DigitalLogText", options.Text or (title .. "\nLOG\nOPEN"), Enum.NormalId.Front, Color3.fromRGB(86, 255, 150), Color3.fromRGB(4, 10, 8))
	local prompt = createPrompt(screen, "Open", title .. " Log", 0)
	prompt.MaxActivationDistance = options.MaxActivationDistance or 7
	tag(screen, Constants.Tags.ReferenceBook)

	log.PrimaryPart = back
	return log
end

local function makeCompactResetRoomButton(parent, name, cframe, promptObjectText)
	local resetModel = makeModel(parent, name)

	local plate = createPart(
		resetModel,
		"ResetButtonPlate",
		Vector3.new(1.2, 1.08, 0.13),
		cframe,
		Color3.fromRGB(42, 47, 56),
		Enum.Material.Metal
	)
	local button = createPart(
		resetModel,
		"ResetButton",
		Vector3.new(0.72, 0.22, 0.72),
		cframe * CFrame.new(0, -0.05, -0.16) * CFrame.Angles(math.rad(90), 0, 0),
		Color3.fromRGB(255, 221, 84),
		Enum.Material.Neon
	)
	button.Shape = Enum.PartType.Cylinder

	createSurfaceText(plate, "ResetButtonText", "RESET", Enum.NormalId.Front, Color3.fromRGB(255, 242, 181), Color3.fromRGB(42, 47, 56))
	local prompt = createPrompt(button, "Reset", promptObjectText or "Room Reset", 0.2)
	prompt.MaxActivationDistance = 7
	tag(button, Constants.Tags.ResetRoomButton)

	resetModel.PrimaryPart = plate
	return resetModel
end

local function makeRoomControlPanel(parent, name, panelCFrame, roomId, title, options)
	options = options or {}
	local includeReset = options.IncludeReset == true
	local includeLightSwitch = options.IncludeLightSwitch ~= false
	local panelWidth = options.PanelWidth or (includeReset and 5.6 or 4.55)
	local panelHeight = options.PanelHeight or (includeReset and 3.1 or 2.55)
	local controls = makeModel(parent, name)
	controls:SetAttribute("StrictPromptTargets", true)

	local panel = createPart(
		controls,
		"ControlPanelBack",
		Vector3.new(panelWidth, panelHeight, 0.22),
		panelCFrame,
		Color3.fromRGB(32, 37, 45),
		Enum.Material.Metal
	)
	local titleStrip = createPart(
		controls,
		"ControlPanelTitleStrip",
		Vector3.new(panelWidth - 0.4, 0.36, 0.08),
		panelCFrame * CFrame.new(0, panelHeight / 2 - 0.28, -0.18),
		Color3.fromRGB(62, 69, 82),
		Enum.Material.SmoothPlastic
	)
	createSurfaceText(titleStrip, "ControlPanelTitle", options.PanelLabel or (title .. " CONTROLS"), Enum.NormalId.Front, Color3.fromRGB(236, 245, 255), Color3.fromRGB(62, 69, 82))

	local logX = if includeReset then -1.45 else -0.85
	local logY = if includeReset then -0.24 else -0.18
	local referenceBook = makeCompactReferenceBook(
		controls,
		name .. "Log",
		panelCFrame * CFrame.new(logX, logY, -0.22),
		roomId,
		title,
		{
			Height = if includeReset then 1.66 else 1.5,
			Text = options.LogText,
			MaxActivationDistance = options.LogPromptDistance or 7,
		}
	)

	local lightSwitch = nil
	if includeLightSwitch then
		lightSwitch = makeLightSwitch(
			controls,
			name .. "LightSwitch",
			panelCFrame * CFrame.new(if includeReset then 1.55 else 1.38, if includeReset then 0.48 else -0.16, -0.22),
			{
				RoomId = roomId,
				Label = options.SwitchLabel or "LIGHT",
				PromptObjectText = options.LightPromptObjectText or (title .. " Light Switch"),
				HighlightTag = options.HighlightTag,
				UnlocksGiantDiscovery = options.UnlocksGiantDiscovery,
				Scale = options.SwitchScale or 0.58,
				MaxActivationDistance = options.LightPromptDistance or 7,
			}
		)
	end

	local resetRoomButton = nil
	if includeReset then
		resetRoomButton = makeCompactResetRoomButton(
			controls,
			name .. "ResetRoomButton",
			panelCFrame * CFrame.new(1.55, -0.78, -0.22),
			options.ResetPromptObjectText or "Room Reset"
		)
	end

	controls.PrimaryPart = panel
	return {
		Model = controls,
		Panel = panel,
		ReferenceBook = referenceBook,
		LightSwitch = lightSwitch,
		ResetRoomButton = resetRoomButton,
	}
end

local function makeHallway(roomFolder)
	local hallway = makeModel(roomFolder, "DoorHallway")

	createPart(hallway, "HallwayFloor", Vector3.new(13, 1, 56), CFrame.new(0, 0, 45), Color3.fromRGB(92, 101, 112), Enum.Material.Concrete)
	createPart(hallway, "HallwayLeftWall", Vector3.new(1, 10, 56), CFrame.new(-6.5, 5, 45), Color3.fromRGB(150, 156, 168), Enum.Material.SmoothPlastic)
	createPart(hallway, "HallwayRightWall", Vector3.new(1, 10, 56), CFrame.new(6.5, 5, 45), Color3.fromRGB(150, 156, 168), Enum.Material.SmoothPlastic)
	createPart(hallway, "HallwayCeiling", Vector3.new(13, 1, 56), CFrame.new(0, 10, 45), Color3.fromRGB(116, 119, 128), Enum.Material.Concrete)
	createPart(hallway, "IslandApproachFloor", Vector3.new(9, 1, 48), CFrame.new(0, 0, 97), Color3.fromRGB(65, 84, 104), Enum.Material.Concrete)
	createPart(hallway, "IslandApproachLeftWall", Vector3.new(1, 9, 48), CFrame.new(-4.5, 4.5, 97), Color3.fromRGB(76, 103, 130), Enum.Material.SmoothPlastic)
	createPart(hallway, "IslandApproachRightWall", Vector3.new(1, 9, 48), CFrame.new(4.5, 4.5, 97), Color3.fromRGB(76, 103, 130), Enum.Material.SmoothPlastic)
	createPart(hallway, "IslandApproachCeiling", Vector3.new(9, 1, 48), CFrame.new(0, 9.5, 97), Color3.fromRGB(41, 65, 91), Enum.Material.Concrete)
	createPart(hallway, "IslandApproachArchTop", Vector3.new(13, 2, 1), CFrame.new(0, 9, 73), Color3.fromRGB(150, 156, 168), Enum.Material.SmoothPlastic)
	createPart(hallway, "IslandApproachArchLeft", Vector3.new(2, 9, 1), CFrame.new(-5.5, 4.5, 73), Color3.fromRGB(150, 156, 168), Enum.Material.SmoothPlastic)
	createPart(hallway, "IslandApproachArchRight", Vector3.new(2, 9, 1), CFrame.new(5.5, 4.5, 73), Color3.fromRGB(150, 156, 168), Enum.Material.SmoothPlastic)

	local label = createPart(hallway, "HallwaySign", Vector3.new(9.5, 2.2, 0.3), CFrame.new(0, 7.1, 22), Color3.fromRGB(250, 238, 111), Enum.Material.SmoothPlastic)
	createSurfaceText(label, "HallwaySignText", "ROOMS", Enum.NormalId.Back, Color3.fromRGB(22, 22, 26), Color3.fromRGB(250, 238, 111))
	local oceanSign = createPart(hallway, "IslandApproachSign", Vector3.new(7.2, 1.9, 0.3), CFrame.new(0, 8.15, 88), Color3.fromRGB(112, 222, 255), Enum.Material.SmoothPlastic)
	oceanSign.CanCollide = false
	oceanSign:SetAttribute("BaseCanCollide", false)
	createSurfaceText(oceanSign, "IslandApproachSignText", "LONG HALLWAY\nFROM A SHORT VACATION", Enum.NormalId.Back, Color3.fromRGB(18, 42, 54), Color3.fromRGB(112, 222, 255))
	createSurfaceText(oceanSign, "IslandApproachReturnText", "THIS WAY\nTO PARADISE", Enum.NormalId.Front, Color3.fromRGB(18, 42, 54), Color3.fromRGB(112, 222, 255))
	createSpawnLocation(hallway, "HallwaySpawn", "Hallway", Constants.Hallway.SpawnCFrame, Color3.fromRGB(96, 194, 134), false)
	makeRoomControlPanel(
		hallway,
		"TVHallControlPanel",
		CFrame.new(-5.88, 4.55, 25.2) * CFrame.Angles(0, math.rad(-90), 0),
		"TVRoom",
		"TV ROOM",
		{
			IncludeReset = false,
			PanelLabel = "TV ROOM",
			LightPromptObjectText = "Hall Light Switch",
		}
	)
	makeRoomControlPanel(
		hallway,
		"SnackHallControlPanel",
		CFrame.new(5.88, 4.55, 39.4) * CFrame.Angles(0, math.rad(90), 0),
		"SnackLab",
		"SNACK LAB",
		{
			IncludeReset = false,
			PanelLabel = "SNACK LAB",
			LightPromptObjectText = "Snack Door Light Switch",
		}
	)
	makeLightSwitch(
		hallway,
		"ConstructionHallLightSwitch",
		CFrame.new(-5.88, 4.55, 39.4) * CFrame.Angles(0, math.rad(-90), 0),
		{
			PromptObjectText = "Mystery Door Light Switch",
		}
	)
	makeRoomControlPanel(
		hallway,
		"IslandHallControlPanel",
		CFrame.new(3.95, 4.55, 114.2) * CFrame.Angles(0, math.rad(90), 0),
		"Island",
		"ISLAND",
		{
			IncludeReset = false,
			PanelLabel = "ISLAND",
			LightPromptObjectText = "Island Door Light Switch",
		}
	)

	local snackDoor = makeHallDoor(
		hallway,
		"SnackLabDoor",
		Vector3.new(0.45, 8.5, 6.5),
		CFrame.new(5.95, 4.75, 45),
		Enum.NormalId.Left,
		"SNACK LAB",
		SNACK_LAB_SPAWN_CFRAME,
		nil,
		"SnackLab"
	)

	makeHallDoor(
		hallway,
		"UnderConstructionDoor",
		Vector3.new(0.45, 8.5, 6.5),
		CFrame.new(-5.95, 4.75, 45),
		Enum.NormalId.Right,
		"???",
		nil,
		"Something behind this door is still rehearsing."
	)

		local islandDoor = makeHallDoor(
			hallway,
			"IslandDoor",
			Vector3.new(7, 8.5, 0.45),
			CFrame.new(0, 4.75, 121),
		Enum.NormalId.Back,
		"ISLAND",
		ISLAND_SPAWN_CFRAME,
			nil,
			"Island"
		)
		local islandDoorPrompt = islandDoor:FindFirstChild("InteractPrompt", true)
		if islandDoorPrompt and islandDoorPrompt:IsA("ProximityPrompt") then
			islandDoorPrompt.MaxActivationDistance = 6
		end

	local returnPad = createPart(hallway, "HallwayLanding", Vector3.new(8, 0.25, 8), CFrame.new(HALLWAY_SPAWN_CFRAME.Position - Vector3.new(0, 2.9, 0)), Color3.fromRGB(96, 194, 134), Enum.Material.Neon)
	returnPad.Transparency = 0.35
	returnPad:SetAttribute("BaseTransparency", returnPad.Transparency)

	local islandReturnPad = createPart(hallway, "IslandReturnLanding", Vector3.new(7.8, 0.25, 7.8), CFrame.new(ISLAND_RETURN_CFRAME.Position - Vector3.new(0, 2.9, 0)), Color3.fromRGB(112, 222, 255), Enum.Material.Neon)
	islandReturnPad.Transparency = 0.35
	islandReturnPad:SetAttribute("BaseTransparency", islandReturnPad.Transparency)

	return {
		Model = hallway,
		SnackDoor = snackDoor,
		IslandDoor = islandDoor,
	}
end

local function makeSnackLabShell(roomFolder)
	local room = makeModel(roomFolder, "SnackLabRoom")
	local width = Constants.Room.Width
	local depth = Constants.Room.Depth
	local height = Constants.Room.Height
	local origin = SNACK_LAB_ORIGIN

	createPart(room, "SnackFloor", Vector3.new(width, 1, depth), cframeAt(origin, 0, 0, 0), Color3.fromRGB(112, 122, 119), Enum.Material.Concrete)
	createPart(room, "SnackBackWall", Vector3.new(width, height, 1), cframeAt(origin, 0, height / 2, -depth / 2), Color3.fromRGB(186, 187, 174), Enum.Material.SmoothPlastic)
	createPart(room, "SnackFrontWall", Vector3.new(width, height, 1), cframeAt(origin, 0, height / 2, depth / 2), Color3.fromRGB(186, 187, 174), Enum.Material.SmoothPlastic)
	createPart(room, "SnackLeftWall", Vector3.new(1, height, depth), cframeAt(origin, -width / 2, height / 2, 0), Color3.fromRGB(186, 187, 174), Enum.Material.SmoothPlastic)
	createPart(room, "SnackRightWall", Vector3.new(1, height, depth), cframeAt(origin, width / 2, height / 2, 0), Color3.fromRGB(186, 187, 174), Enum.Material.SmoothPlastic)
	createPart(room, "SnackCeiling", Vector3.new(width, 1, depth), cframeAt(origin, 0, height, 0), Color3.fromRGB(135, 137, 127), Enum.Material.Concrete)

	local exitDoor = makeHallDoor(
		room,
		"SnackExitDoor",
		Vector3.new(0.45, 8.5, 6.5),
		cframeAt(origin, -width / 2 + 0.53, 4.75, 9),
		Enum.NormalId.Right,
		"HALLWAY",
		HALLWAY_SPAWN_CFRAME
	)

	local roomSign = createPart(room, "SnackLabSign", Vector3.new(14, 2.6, 0.35), cframeAt(origin, 0, 7.2, -depth / 2 + 0.54), Color3.fromRGB(255, 232, 115), Enum.Material.SmoothPlastic)
	createSurfaceText(roomSign, "SnackLabSignText", "SNACK LAB", Enum.NormalId.Front, Color3.fromRGB(28, 27, 24), Color3.fromRGB(255, 232, 115))

	local snackControls = makeRoomControlPanel(
		room,
		"SnackLabInsideControlPanel",
		cframeAt(origin, -width / 2 + 0.58, 4.6, 3.7) * CFrame.Angles(0, math.rad(-90), 0),
		"SnackLab",
		"SNACK LAB",
		{
			IncludeReset = true,
			PanelLabel = "ROOM CONTROLS",
			LightPromptObjectText = "Snack Lab Light Switch",
		}
	)
	local resetRoomButton = snackControls.ResetRoomButton
	local lightSwitch = snackControls.LightSwitch
	local referenceBook = snackControls.ReferenceBook
	createSpawnLocation(room, "SnackLabSpawn", "SnackLab", Constants.GetRoomSpawnCFrame("SnackLab"), Color3.fromRGB(91, 188, 124), false)

	return {
		Model = room,
		ExitDoor = exitDoor,
		ResetRoomButton = resetRoomButton,
		LightSwitch = lightSwitch,
		ReferenceBook = referenceBook,
	}
end

local function makeSnackButton(objectsFolder)
	local origin = SNACK_LAB_ORIGIN
	local model = makeModel(objectsFolder, "SnackLabButton")

	local base = createPart(model, "SnackButtonBase", Vector3.new(4.6, 2.6, 4.6), cframeAt(origin, 0, 1.8, 0), Color3.fromRGB(59, 67, 76), Enum.Material.Metal)
	createNoTouchClock(
		model,
		"SnackButtonClock",
		"SnackLab",
		Vector3.new(4.1, 1.05, 0.22),
		cframeAt(origin, 0, 2.05, 2.42) * CFrame.Angles(0, 0, math.rad(180)),
		Enum.NormalId.Front
	)

	local button = createPart(model, "SnackBlueButton", Vector3.new(3.1, 0.65, 3.1), cframeAt(origin, 0, 3.4, 0), Color3.fromRGB(45, 151, 255), Enum.Material.SmoothPlastic)
	button.Shape = Enum.PartType.Ball
	createPrompt(button, "Press", "Snack Lab Button", 0.1)
	tag(button, Constants.Tags.SnackButton)

	local sign = createPart(model, "SnackButtonSign", Vector3.new(10, 2.4, 0.35), cframeAt(origin, 0, 5.8, -3.4), Color3.fromRGB(244, 248, 112), Enum.Material.SmoothPlastic)
	createSurfaceText(sign, "SnackButtonText", "DO NOT FEED THE ROOM", Enum.NormalId.Back, Color3.fromRGB(22, 23, 25), Color3.fromRGB(244, 248, 112))

	model.PrimaryPart = base
	return model
end

local function hideFridgeContentAtBaseline(root)
	local instances = root:GetDescendants()
	table.insert(instances, root)

	for _, instance in ipairs(instances) do
		if instance:IsA("BasePart") then
			instance:SetAttribute("OpenTransparency", instance.Transparency)
			instance:SetAttribute("OpenCanCollide", instance.CanCollide)
			instance.Transparency = 1
			instance.CanCollide = false
			instance:SetAttribute("BaseTransparency", 1)
			instance:SetAttribute("BaseCanCollide", false)
		elseif instance:IsA("PointLight") or instance:IsA("SpotLight") or instance:IsA("SurfaceLight") then
			instance:SetAttribute("OpenEnabled", instance.Enabled)
			instance.Enabled = false
			instance:SetAttribute("BaseEnabled", false)
		elseif instance:IsA("SurfaceGui") then
			instance:SetAttribute("OpenEnabled", instance.Enabled)
			instance.Enabled = false
			instance:SetAttribute("BaseEnabled", false)
		end
	end
end

local function makeSnackFridge(objectsFolder)
	local origin = SNACK_LAB_ORIGIN
	local fridge = makeModel(objectsFolder, "Fridge")

	local body = createPart(fridge, "FridgeBody", Vector3.new(6.4, 9.2, 0.34), cframeAt(origin, -13, 4.9, -10.92), Color3.fromRGB(213, 225, 228), Enum.Material.Metal)
	createPart(fridge, "FridgeLeftWall", Vector3.new(0.36, 9.2, 4), cframeAt(origin, -16.02, 4.9, -8.95), Color3.fromRGB(213, 225, 228), Enum.Material.Metal)
	createPart(fridge, "FridgeRightWall", Vector3.new(0.36, 9.2, 4), cframeAt(origin, -9.98, 4.9, -8.95), Color3.fromRGB(213, 225, 228), Enum.Material.Metal)
	createPart(fridge, "FridgeTopCap", Vector3.new(6.4, 0.36, 4), cframeAt(origin, -13, 9.32, -8.95), Color3.fromRGB(213, 225, 228), Enum.Material.Metal)
	createPart(fridge, "FridgeBottomCap", Vector3.new(6.4, 0.36, 4), cframeAt(origin, -13, 0.48, -8.95), Color3.fromRGB(190, 205, 208), Enum.Material.Metal)

	local interior = makeModel(fridge, "FridgeInteriorDetails")
	createPart(interior, "FridgeInteriorBack", Vector3.new(5.45, 7.65, 0.22), cframeAt(origin, -13, 4.9, -10.62), Color3.fromRGB(55, 78, 92), Enum.Material.SmoothPlastic)
	createPart(interior, "FridgeInteriorLeft", Vector3.new(0.18, 7.65, 3.2), cframeAt(origin, -15.68, 4.9, -8.95), Color3.fromRGB(72, 95, 108), Enum.Material.SmoothPlastic)
	createPart(interior, "FridgeInteriorRight", Vector3.new(0.18, 7.65, 3.2), cframeAt(origin, -10.32, 4.9, -8.95), Color3.fromRGB(72, 95, 108), Enum.Material.SmoothPlastic)
	createPart(interior, "FridgeShelfTop", Vector3.new(5.1, 0.18, 2.85), cframeAt(origin, -13, 6.32, -8.95), Color3.fromRGB(185, 244, 255), Enum.Material.Glass).Transparency = 0.34
	createPart(interior, "FridgeShelfBottom", Vector3.new(5.1, 0.18, 2.85), cframeAt(origin, -13, 4.1, -8.95), Color3.fromRGB(185, 244, 255), Enum.Material.Glass).Transparency = 0.34
	createPart(interior, "FridgeShelfTopLip", Vector3.new(5.15, 0.24, 0.12), cframeAt(origin, -13, 6.45, -7.48), Color3.fromRGB(212, 250, 255), Enum.Material.Glass).Transparency = 0.22
	createPart(interior, "FridgeShelfBottomLip", Vector3.new(5.15, 0.24, 0.12), cframeAt(origin, -13, 4.23, -7.48), Color3.fromRGB(212, 250, 255), Enum.Material.Glass).Transparency = 0.22
	local crisper = createPart(interior, "FridgeCrisperDrawer", Vector3.new(4.85, 1.25, 2.65), cframeAt(origin, -13, 2.25, -8.95), Color3.fromRGB(185, 244, 255), Enum.Material.Glass)
	crisper.Transparency = 0.55
	local crisperFront = createPart(interior, "FridgeCrisperFront", Vector3.new(4.85, 1.12, 0.12), cframeAt(origin, -13, 2.25, -7.48), Color3.fromRGB(202, 250, 255), Enum.Material.Glass)
	crisperFront.Transparency = 0.32
	createSurfaceText(crisperFront, "CrisperText", "IDEAS\nCRISPER", Enum.NormalId.Front, Color3.fromRGB(36, 84, 92), Color3.fromRGB(202, 250, 255))
	local lightPanel = createPart(interior, "FridgeLightPanel", Vector3.new(1.4, 0.22, 0.18), cframeAt(origin, -13, 8.45, -7.55), Color3.fromRGB(255, 249, 196), Enum.Material.Neon)
	local fridgeLight = Instance.new("PointLight")
	fridgeLight.Name = "FridgeInteriorLight"
	fridgeLight.Brightness = 2.5
	fridgeLight.Color = Color3.fromRGB(210, 248, 255)
	fridgeLight.Range = 10
	fridgeLight.Parent = lightPanel
	mark(fridgeLight)

	local milk = createPart(interior, "FridgeMilkCarton", Vector3.new(0.95, 1.8, 0.9), cframeAt(origin, -14.45, 5.15, -9.05), Color3.fromRGB(245, 248, 250), Enum.Material.SmoothPlastic)
	createSurfaceText(milk, "MilkText", "MILK?", Enum.NormalId.Front, Color3.fromRGB(72, 118, 205), Color3.fromRGB(245, 248, 250))
	createPart(interior, "FridgeMilkCap", Vector3.new(0.34, 0.2, 0.34), cframeAt(origin, -14.1, 6.15, -8.72), Color3.fromRGB(72, 118, 205), Enum.Material.SmoothPlastic).Shape = Enum.PartType.Cylinder

	local eggTray = createPart(interior, "FridgeEggTray", Vector3.new(2.1, 0.18, 0.75), cframeAt(origin, -11.85, 6.58, -8.65), Color3.fromRGB(235, 226, 202), Enum.Material.SmoothPlastic)
	for eggIndex = 1, 6 do
		local egg = createPart(
			interior,
			"FridgeEgg" .. eggIndex,
			Vector3.new(0.32, 0.42, 0.32),
			eggTray.CFrame * CFrame.new(-0.85 + ((eggIndex - 1) % 3) * 0.58, 0.24, -0.18 + math.floor((eggIndex - 1) / 3) * 0.38),
			Color3.fromRGB(250, 245, 228),
			Enum.Material.SmoothPlastic
		)
		egg.Shape = Enum.PartType.Ball
	end

	for bottleIndex, bottleData in ipairs({
		{ X = -10.95, Y = 5.08, Z = -9.4, Color = Color3.fromRGB(255, 219, 86), Label = "MUSTARD" },
		{ X = -10.95, Y = 5.08, Z = -8.45, Color = Color3.fromRGB(221, 45, 58), Label = "KETCHUP" },
	}) do
		local bottle = createPart(interior, "FridgeBottle" .. bottleIndex, Vector3.new(0.5, 1.25, 0.5), cframeAt(origin, bottleData.X, bottleData.Y, bottleData.Z), bottleData.Color, Enum.Material.SmoothPlastic)
		bottle.Shape = Enum.PartType.Cylinder
		createPart(interior, "FridgeBottleCap" .. bottleIndex, Vector3.new(0.34, 0.18, 0.34), cframeAt(origin, bottleData.X, bottleData.Y + 0.7, bottleData.Z), Color3.fromRGB(245, 245, 242), Enum.Material.SmoothPlastic).Shape = Enum.PartType.Cylinder
		local label = createPart(interior, "FridgeBottleLabel" .. bottleIndex, Vector3.new(0.55, 0.42, 0.08), cframeAt(origin, bottleData.X, bottleData.Y, bottleData.Z + 0.28), Color3.fromRGB(255, 255, 245), Enum.Material.SmoothPlastic)
		createSurfaceText(label, "BottleLabelText", bottleData.Label, Enum.NormalId.Front, bottleData.Color, Color3.fromRGB(255, 255, 245))
	end
	hideFridgeContentAtBaseline(interior)

	local iceCube = createPart(fridge, "ColdIdeaIceCube", Vector3.new(1.4, 1.4, 1.4), cframeAt(origin, -13, 5.05, -7.55), Color3.fromRGB(134, 238, 255), Enum.Material.Ice)
	iceCube.Transparency = 0.22
	iceCube:SetAttribute("BaseTransparency", iceCube.Transparency)
	local iceLight = Instance.new("PointLight")
	iceLight.Name = "ColdIdeaLight"
	iceLight.Brightness = 1.5
	iceLight.Color = Color3.fromRGB(134, 238, 255)
	iceLight.Range = 8
	iceLight.Parent = iceCube
	mark(iceLight)
	hideFridgeContentAtBaseline(iceCube)

	local pizza = makeModel(fridge, "FridgePizza")
	local pizzaSlice = createPart(pizza, "PizzaSlice", Vector3.new(2.3, 0.25, 1.45), cframeAt(origin, -14.3, 6.78, -7.75) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(246, 184, 85), Enum.Material.SmoothPlastic, "WedgePart")
	createPart(pizza, "PizzaCrust", Vector3.new(0.28, 0.32, 1.5), cframeAt(origin, -15.05, 6.79, -7.75), Color3.fromRGB(177, 103, 47), Enum.Material.SmoothPlastic)
	for index = 1, 4 do
		local topping = createPart(
			pizza,
			"Pepperoni",
			Vector3.new(0.28, 0.08, 0.28),
			cframeAt(origin, -14.35 + (index % 2) * 0.6, 6.96, -8.08 + math.floor((index - 1) / 2) * 0.55),
			Color3.fromRGB(190, 42, 45),
			Enum.Material.SmoothPlastic
		)
		topping.Shape = Enum.PartType.Cylinder
	end
	local pizzaPrompt = createPrompt(pizzaSlice, "Inspect", "Cold Pizza", 0)
	pizzaPrompt.Enabled = false
	pizzaPrompt:SetAttribute("BaseEnabled", false)
	tag(pizzaSlice, Constants.Tags.FridgePizza)
	pizza.PrimaryPart = pizzaSlice
	hideFridgeContentAtBaseline(pizza)

	local cola = makeModel(fridge, "FridgeBloxyCola")
	local can = createPart(cola, "BloxyColaCan", Vector3.new(0.82, 1.55, 0.82), cframeAt(origin, -11.6, 4.85, -7.6), Color3.fromRGB(218, 40, 47), Enum.Material.Metal)
	can.Shape = Enum.PartType.Cylinder
	local canLabel = createPart(cola, "BloxyColaLabel", Vector3.new(0.9, 0.68, 0.08), cframeAt(origin, -11.6, 4.85, -7.16), Color3.fromRGB(245, 245, 242), Enum.Material.SmoothPlastic)
	createSurfaceText(canLabel, "BloxyColaText", "BLOXY\nCOLA", Enum.NormalId.Front, Color3.fromRGB(218, 40, 47), Color3.fromRGB(245, 245, 242))
	local colaPrompt = createPrompt(can, "Sip", "Bloxy Cola", 0)
	colaPrompt.Enabled = false
	colaPrompt:SetAttribute("BaseEnabled", false)
	tag(can, Constants.Tags.FridgeBloxyCola)
	cola.PrimaryPart = can
	hideFridgeContentAtBaseline(cola)

	local door = createPart(fridge, "FridgeDoor", Vector3.new(5.5, 8, 0.32), cframeAt(origin, -13, 4.9, -6.83), Color3.fromRGB(237, 246, 247), Enum.Material.Metal)
	createSurfaceText(door, "FridgeDoorText", "DO NOT OPEN", Enum.NormalId.Front, Color3.fromRGB(26, 35, 39), Color3.fromRGB(237, 246, 247))
	local doorPrompt = createPrompt(door, "Open", "Fridge", 0)
	doorPrompt.MaxActivationDistance = 13

	local secretButton = createPart(fridge, "SecretFridgeButton", Vector3.new(2.55, 1.2, 0.24), cframeAt(origin, -15.7, 4.85, -6.18), Color3.fromRGB(255, 72, 86), Enum.Material.Neon)
	secretButton.Transparency = 1
	secretButton.CanCollide = false
	secretButton:SetAttribute("BaseTransparency", 1)
	secretButton:SetAttribute("BaseCanCollide", false)
	local secretLabel = createSurfaceText(secretButton, "SecretFridgeButtonText", "SECRET\nFRIDGE\nBUTTON", Enum.NormalId.Front, Color3.fromRGB(255, 246, 220), Color3.fromRGB(115, 18, 31))
	secretLabel.Text = ""
	secretLabel:SetAttribute("BaseText", "")
	if secretLabel.Parent and secretLabel.Parent:IsA("SurfaceGui") then
		secretLabel.Parent.Enabled = false
	end
	local secretPrompt = createPrompt(secretButton, "Press", "Secret Fridge Button", 0)
	secretPrompt.Enabled = false
	secretPrompt:SetAttribute("BaseEnabled", false)
	tag(secretButton, Constants.Tags.SecretFridgeButton)
	tag(door, Constants.Tags.SnackFridge)
	tag(fridge, Constants.Tags.SnackFridge)

	fridge.PrimaryPart = body
	return fridge
end

local function makeSnackToaster(objectsFolder)
	local origin = SNACK_LAB_ORIGIN
	local toaster = makeModel(objectsFolder, "Toaster")

	createPart(toaster, "ToasterCounter", Vector3.new(9, 2.2, 3.8), cframeAt(origin, -2, 1.55, -9), Color3.fromRGB(134, 93, 63), Enum.Material.Wood)
	local body = createPart(toaster, "ToasterBody", Vector3.new(4.2, 2, 2.5), cframeAt(origin, -2, 3.65, -9), Color3.fromRGB(194, 200, 207), Enum.Material.Metal)
	local slot = createPart(toaster, "ToasterSlot", Vector3.new(3.2, 0.18, 1.2), cframeAt(origin, -2, 4.75, -9), Color3.fromRGB(34, 36, 40), Enum.Material.SmoothPlastic)
	createPrompt(body, "Toast", "Toaster", 0)
	tag(toaster, Constants.Tags.SnackToaster)

	toaster.PrimaryPart = body
	return toaster, slot
end

local function makeSnackSink(objectsFolder)
	local origin = SNACK_LAB_ORIGIN
	local sink = makeModel(objectsFolder, "Sink")

	createPart(sink, "SinkCounter", Vector3.new(9, 2.2, 3.8), cframeAt(origin, 10, 1.55, -9), Color3.fromRGB(122, 128, 132), Enum.Material.Metal)
	createPart(sink, "SinkBasinOuter", Vector3.new(5.2, 0.45, 2.8), cframeAt(origin, 10, 2.93, -9), Color3.fromRGB(215, 224, 229), Enum.Material.Metal)
	createPart(sink, "SinkBasinDark", Vector3.new(4.1, 0.5, 1.8), cframeAt(origin, 10, 3.02, -9), Color3.fromRGB(40, 55, 65), Enum.Material.SmoothPlastic)
	createPart(sink, "SinkWaterRest", Vector3.new(3.4, 0.08, 1.25), cframeAt(origin, 10, 3.33, -9), Color3.fromRGB(72, 183, 238), Enum.Material.Glass)
	local faucetPost = createPart(sink, "FaucetPost", Vector3.new(0.42, 1.9, 0.42), cframeAt(origin, 10, 4.05, -10.22), Color3.fromRGB(216, 223, 226), Enum.Material.Metal)
	local faucetSpout = createPart(sink, "FaucetSpout", Vector3.new(0.42, 0.42, 1.65), cframeAt(origin, 10, 4.78, -9.55), Color3.fromRGB(216, 223, 226), Enum.Material.Metal)
	createPart(sink, "HotHandle", Vector3.new(0.7, 0.25, 0.7), cframeAt(origin, 8.65, 3.55, -10.35), Color3.fromRGB(255, 80, 80), Enum.Material.Neon)
	createPart(sink, "ColdHandle", Vector3.new(0.7, 0.25, 0.7), cframeAt(origin, 11.35, 3.55, -10.35), Color3.fromRGB(80, 160, 255), Enum.Material.Neon)
	createPrompt(faucetSpout, "Turn", "Sink", 0)
	tag(sink, Constants.Tags.SnackSink)

	sink.PrimaryPart = faucetPost
	return sink
end

local function makeSnackMixer(objectsFolder)
	local origin = SNACK_LAB_ORIGIN
	local mixer = makeModel(objectsFolder, "Mixer")
	local mixerX = 17.8
	local mixerZ = 11.3
	local mixerFrame = CFrame.new(origin + Vector3.new(mixerX, 0, mixerZ)) * CFrame.Angles(0, math.rad(180), 0)

	local function mixerCFrame(x, y, z)
		return mixerFrame * CFrame.new(x, y, z)
	end

	local function markBlade(part, side)
		part:SetAttribute("MixerBladeSide", side)
		return part
	end

	local base = createPart(mixer, "MixerBase", Vector3.new(5.2, 0.8, 4.2), mixerCFrame(0, 1.15, 0), Color3.fromRGB(94, 101, 115), Enum.Material.Metal)
	createPart(mixer, "MixerStand", Vector3.new(0.8, 3.45, 0.8), mixerCFrame(-1.85, 2.8, 0), Color3.fromRGB(224, 230, 235), Enum.Material.Metal)
	createPart(mixer, "MixerNeck", Vector3.new(2.45, 0.82, 1.15), mixerCFrame(-1.08, 4.45, 0), Color3.fromRGB(217, 226, 232), Enum.Material.Metal)
	local head = createPart(mixer, "MixerHead", Vector3.new(3.8, 1.35, 2.35), mixerCFrame(0.2, 4.45, 0), Color3.fromRGB(236, 63, 77), Enum.Material.Metal)
	createPart(mixer, "MixerHeadBand", Vector3.new(3.95, 0.2, 2.5), mixerCFrame(0.2, 4.8, 0), Color3.fromRGB(255, 222, 98), Enum.Material.Neon)
	createPart(mixer, "MixerSpeedKnob", Vector3.new(0.55, 0.55, 0.22), mixerCFrame(0.2, 4.52, -1.32), Color3.fromRGB(54, 61, 71), Enum.Material.Metal)

	local bowl = createPart(mixer, "MixerBowl", Vector3.new(4, 1.9, 4), mixerCFrame(0.55, 2.35, 0), Color3.fromRGB(142, 225, 241), Enum.Material.Glass)
	bowl.Shape = Enum.PartType.Ball
	bowl.Transparency = 0.46
	bowl:SetAttribute("BaseTransparency", bowl.Transparency)
	local bowlRim = createPart(mixer, "MixerBowlRim", Vector3.new(4.25, 0.18, 4.25), mixerCFrame(0.55, 3.12, 0), Color3.fromRGB(198, 246, 255), Enum.Material.Glass)
	bowlRim.Shape = Enum.PartType.Cylinder
	bowlRim.Transparency = 0.34
	bowlRim:SetAttribute("BaseTransparency", bowlRim.Transparency)
	local bowlHighlight = createPart(mixer, "MixerBowlHighlight", Vector3.new(0.12, 1.1, 1.8), mixerCFrame(-0.42, 2.55, -1.35) * CFrame.Angles(0, math.rad(18), math.rad(-8)), Color3.fromRGB(236, 255, 255), Enum.Material.Glass)
	bowlHighlight.Transparency = 0.32
	bowlHighlight:SetAttribute("BaseTransparency", bowlHighlight.Transparency)
	local batter = createPart(mixer, "MixerBatter", Vector3.new(3.15, 0.48, 3.15), mixerCFrame(0.55, 2.05, 0), Color3.fromRGB(255, 238, 158), Enum.Material.SmoothPlastic)
	batter.Shape = Enum.PartType.Ball

	local function makeBeater(side, zOffset)
		local root = markBlade(createPart(mixer, "Beater" .. side, Vector3.new(0.2, 1.3, 0.2), mixerCFrame(0.42, 3.22, zOffset), Color3.fromRGB(224, 232, 235), Enum.Material.Metal), side)
		local loopOuter = markBlade(createPart(mixer, "Beater" .. side .. "OuterLoop", Vector3.new(0.12, 1, 0.12), mixerCFrame(0.08, 2.56, zOffset) * CFrame.Angles(0, 0, math.rad(-18)), Color3.fromRGB(236, 242, 244), Enum.Material.Metal), side)
		local loopInner = markBlade(createPart(mixer, "Beater" .. side .. "InnerLoop", Vector3.new(0.12, 1, 0.12), mixerCFrame(0.76, 2.56, zOffset) * CFrame.Angles(0, 0, math.rad(18)), Color3.fromRGB(236, 242, 244), Enum.Material.Metal), side)
		markBlade(createPart(mixer, "Beater" .. side .. "BottomWire", Vector3.new(0.9, 0.12, 0.12), mixerCFrame(0.42, 2.08, zOffset), Color3.fromRGB(236, 242, 244), Enum.Material.Metal), side)
		markBlade(createPart(mixer, "Beater" .. side .. "CrossBlade", Vector3.new(0.95, 0.1, 0.22), mixerCFrame(0.42, 2.38, zOffset) * CFrame.Angles(0, math.rad(90), math.rad(12)), Color3.fromRGB(236, 242, 244), Enum.Material.Metal), side)
		return root, loopOuter, loopInner
	end

	makeBeater("Left", -0.48)
	makeBeater("Right", 0.48)
	createPrompt(head, "Mix", "Mixer", 0)
	tag(mixer, Constants.Tags.SnackMixer)

	mixer.PrimaryPart = base
	return mixer, bowl, head
end

local function makeSnackRack(objectsFolder)
	local origin = SNACK_LAB_ORIGIN
	local rack = makeModel(objectsFolder, "SnackRack")
	local colors = {
		Color3.fromRGB(255, 86, 86),
		Color3.fromRGB(255, 207, 78),
		Color3.fromRGB(76, 208, 123),
		Color3.fromRGB(84, 154, 255),
		Color3.fromRGB(219, 112, 255),
	}
	local names = { "CRONCH", "ZAP CHIPS", "MYSTERY", "PUFFS", "NOPE" }
	local rackX = Constants.Room.Width / 2 - 0.78
	local rackZ = -1.5
	local rackRotation = CFrame.Angles(0, math.rad(90), 0)
	local function rackCFrame(x, y, z)
		return CFrame.new(origin + Vector3.new(rackX, 0, rackZ)) * rackRotation * CFrame.new(x, y, z)
	end

	local back = createPart(rack, "RackBack", Vector3.new(9.5, 6.6, 0.35), rackCFrame(0, 4.0, 0), Color3.fromRGB(68, 76, 90), Enum.Material.Metal)
	createPart(rack, "RackLeft", Vector3.new(0.35, 6.8, 2.2), rackCFrame(-4.9, 4.0, -0.85), Color3.fromRGB(48, 54, 66), Enum.Material.Metal)
	createPart(rack, "RackRight", Vector3.new(0.35, 6.8, 2.2), rackCFrame(4.9, 4.0, -0.85), Color3.fromRGB(48, 54, 66), Enum.Material.Metal)

	for shelfIndex = 1, 3 do
		local y = 1.65 + shelfIndex * 1.85
		createPart(rack, "SnackShelf", Vector3.new(10, 0.28, 2.3), rackCFrame(0, y, -0.85), Color3.fromRGB(94, 103, 116), Enum.Material.Metal)

		for packIndex = 1, 5 do
			local x = -3.6 + (packIndex - 1) * 1.8
			local pack = createPart(
				rack,
				"SnackPack",
				Vector3.new(1.1, 1.45, 0.28),
				rackCFrame(x, y + 0.88, -2.02),
				colors[((shelfIndex + packIndex - 2) % #colors) + 1],
				Enum.Material.SmoothPlastic
			)
			pack:SetAttribute("IsSnackPack", true)
			pack:SetAttribute("SnackId", ("snack_%d_%d"):format(shelfIndex, packIndex))
			pack:SetAttribute("SnackName", names[((shelfIndex + packIndex - 2) % #names) + 1])
			createSurfaceText(pack, "SnackPackText", pack:GetAttribute("SnackName"), Enum.NormalId.Front, Color3.fromRGB(255, 255, 255), pack.Color)
			createPrompt(pack, "Listen", pack:GetAttribute("SnackName"), 0)
			tag(pack, Constants.Tags.SnackPack)
		end
	end

	createPrompt(back, "Inspect", "Snack Rack", 0)
	tag(rack, Constants.Tags.SnackRack)
	rack.PrimaryPart = back
	return rack
end

local function makeFruitBowl(objectsFolder)
	local origin = SNACK_LAB_ORIGIN
	local fruitBowl = makeModel(objectsFolder, "FruitBowl")

	local tableTop = createPart(fruitBowl, "FruitTable", Vector3.new(7, 1.3, 4.4), cframeAt(origin, 1.5, 1.1, 7.5), Color3.fromRGB(119, 82, 55), Enum.Material.Wood)
	local bowl = createPart(fruitBowl, "Bowl", Vector3.new(4.7, 1.25, 4.7), cframeAt(origin, 1.5, 2.2, 7.5), Color3.fromRGB(255, 226, 122), Enum.Material.SmoothPlastic)
	bowl.Shape = Enum.PartType.Ball

	local function finishFruit(model, primary, kind)
		model:SetAttribute("IsFruitModel", true)
		model:SetAttribute("FruitKind", kind)
		model.PrimaryPart = primary

		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant:SetAttribute("FruitKind", kind)
				if descendant == primary then
					descendant:SetAttribute("IsFruit", true)
				end
			end
		end

		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant ~= primary then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = primary
				weld.Part1 = descendant
				weld.Parent = descendant
			end
		end
	end

	local function makeLeaf(parent, cframe)
		return createPart(parent, "Leaf", Vector3.new(0.5, 0.14, 0.3), cframe, Color3.fromRGB(66, 166, 72), Enum.Material.SmoothPlastic, "WedgePart")
	end

	local function makeRoundFruit(name, kind, pivot, color, size, stemColor)
		local model = makeModel(fruitBowl, name)
		local body = createPart(model, kind .. "Body", size, pivot, color, Enum.Material.SmoothPlastic)
		body.Shape = Enum.PartType.Ball

		local stem = createPart(model, "Stem", Vector3.new(0.16, 0.46, 0.16), pivot * CFrame.new(0, size.Y / 2 + 0.18, 0) * CFrame.Angles(math.rad(12), 0, math.rad(18)), stemColor or Color3.fromRGB(95, 58, 35), Enum.Material.Wood)
		stem.Shape = Enum.PartType.Cylinder
		makeLeaf(model, pivot * CFrame.new(0.32, size.Y / 2 + 0.32, 0.02) * CFrame.Angles(0, math.rad(-25), math.rad(16)))

		finishFruit(model, body, kind)
	end

	makeRoundFruit("Apple", "Apple", cframeAt(origin, 0.55, 3.28, 7.05), Color3.fromRGB(216, 38, 52), Vector3.new(1.05, 1.0, 1.05))
	makeRoundFruit("Orange", "Orange", cframeAt(origin, 1.5, 3.35, 6.75), Color3.fromRGB(255, 134, 35), Vector3.new(1.0, 1.0, 1.0), Color3.fromRGB(68, 126, 55))
	makeRoundFruit("Lime", "Lime", cframeAt(origin, 2.45, 3.18, 7.15), Color3.fromRGB(70, 184, 76), Vector3.new(0.82, 0.78, 0.82), Color3.fromRGB(58, 116, 45))

	local lemon = makeModel(fruitBowl, "Lemon")
	local lemonPivot = cframeAt(origin, 2.3, 3.28, 8.05) * CFrame.Angles(0, 0, math.rad(-10))
	local lemonBody = createPart(lemon, "LemonBody", Vector3.new(1.25, 0.78, 0.78), lemonPivot, Color3.fromRGB(247, 226, 56), Enum.Material.SmoothPlastic)
	lemonBody.Shape = Enum.PartType.Ball
	local lemonTipA = createPart(lemon, "LemonTipA", Vector3.new(0.22, 0.28, 0.28), lemonPivot * CFrame.new(-0.65, 0, 0), Color3.fromRGB(239, 211, 49), Enum.Material.SmoothPlastic)
	lemonTipA.Shape = Enum.PartType.Ball
	local lemonTipB = createPart(lemon, "LemonTipB", Vector3.new(0.22, 0.28, 0.28), lemonPivot * CFrame.new(0.65, 0, 0), Color3.fromRGB(239, 211, 49), Enum.Material.SmoothPlastic)
	lemonTipB.Shape = Enum.PartType.Ball
	finishFruit(lemon, lemonBody, "Lemon")

	local banana = makeModel(fruitBowl, "Banana")
	local bananaPivot = cframeAt(origin, 0.75, 3.55, 8.15) * CFrame.Angles(0, math.rad(20), math.rad(-8))
	local bananaPrimary = nil
	for index = 1, 5 do
		local curve = index - 3
		local segment = createPart(
			banana,
			"BananaSegment",
			Vector3.new(0.34, 0.34, 0.85),
			bananaPivot * CFrame.new(curve * 0.28, math.abs(curve) * 0.07, 0) * CFrame.Angles(0, math.rad(curve * 8), math.rad(curve * 8)),
			Color3.fromRGB(250, 219, 61),
			Enum.Material.SmoothPlastic
		)
		segment.Shape = Enum.PartType.Cylinder
		bananaPrimary = bananaPrimary or segment
	end
	local bananaTip = createPart(banana, "BananaStem", Vector3.new(0.28, 0.28, 0.34), bananaPivot * CFrame.new(-0.7, 0.16, 0), Color3.fromRGB(111, 72, 35), Enum.Material.Wood)
	bananaTip.Shape = Enum.PartType.Ball
	finishFruit(banana, bananaPrimary, "Banana")

	local grapes = makeModel(fruitBowl, "Grapes")
	local grapePivot = cframeAt(origin, 1.45, 3.45, 8.4)
	local grapePrimary = nil
	local grapeOffsets = {
		Vector3.new(0, 0.2, 0),
		Vector3.new(-0.28, -0.08, -0.05),
		Vector3.new(0.28, -0.08, 0.05),
		Vector3.new(-0.14, -0.36, 0.1),
		Vector3.new(0.18, -0.38, -0.08),
		Vector3.new(0.02, -0.66, 0.02),
	}
	for _, offset in ipairs(grapeOffsets) do
		local grape = createPart(grapes, "Grape", Vector3.new(0.38, 0.38, 0.38), grapePivot * CFrame.new(offset), Color3.fromRGB(125, 65, 184), Enum.Material.SmoothPlastic)
		grape.Shape = Enum.PartType.Ball
		grapePrimary = grapePrimary or grape
	end
	local grapeStem = createPart(grapes, "GrapeStem", Vector3.new(0.12, 0.55, 0.12), grapePivot * CFrame.new(0, 0.55, 0) * CFrame.Angles(math.rad(16), 0, math.rad(-18)), Color3.fromRGB(77, 113, 49), Enum.Material.Wood)
	grapeStem.Shape = Enum.PartType.Cylinder
	finishFruit(grapes, grapePrimary, "Grapes")

	createPrompt(bowl, "Inspect", "Fruit Bowl", 0)
	tag(fruitBowl, Constants.Tags.FruitBowl)
	fruitBowl.PrimaryPart = tableTop
	return fruitBowl
end

local function setHiddenBaseline(root)
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Transparency = 1
			descendant.CanCollide = false
			descendant:SetAttribute("BaseTransparency", 1)
			descendant:SetAttribute("BaseCanCollide", false)
		elseif descendant:IsA("ProximityPrompt") then
			descendant.Enabled = false
			descendant:SetAttribute("BaseEnabled", false)
		elseif descendant:IsA("SurfaceGui") then
			descendant.Enabled = false
			descendant:SetAttribute("BaseEnabled", false)
		end
	end
end

local function rememberSecretDoorVisibleState(root)
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant:SetAttribute("SecretVisibleTransparency", descendant.Transparency)
			descendant:SetAttribute("SecretVisibleCanCollide", descendant.CanCollide)
		elseif descendant:IsA("ProximityPrompt") then
			descendant:SetAttribute("SecretVisibleEnabled", descendant.Enabled)
		elseif descendant:IsA("SurfaceGui") then
			descendant:SetAttribute("SecretVisibleEnabled", descendant.Enabled)
		end
	end
end

local function markSecretDoorOutline(part)
	part:SetAttribute("SecretOutlineVisible", true)
	part:SetAttribute("SecretOutlineTransparency", part.Transparency)
	part:SetAttribute("SecretOutlineCanCollide", false)
	part.CanCollide = false
	return part
end

local function makeLibraryLoftRoom(room)
	local origin = TV_SECRET_ROOM_ORIGIN
	local loft = makeModel(room, "LibraryUpperLoftRoom")
	local center = origin + Vector3.new(0, 0, 0)

	createPart(loft, "LoftRoomFloor", Vector3.new(17, 0.5, 13), CFrame.new(center + Vector3.new(0, 14.75, 0)), Color3.fromRGB(86, 58, 42), Enum.Material.WoodPlanks)
	createPart(loft, "LoftRoomBackWall", Vector3.new(17, 7.5, 0.4), CFrame.new(center + Vector3.new(0, 18.45, -6.5)), Color3.fromRGB(50, 43, 54), Enum.Material.SmoothPlastic)
	createPart(loft, "LoftRoomLeftWall", Vector3.new(0.4, 7.5, 13), CFrame.new(center + Vector3.new(-8.5, 18.45, 0)), Color3.fromRGB(44, 38, 51), Enum.Material.SmoothPlastic)
	createPart(loft, "LoftRoomRightWall", Vector3.new(0.4, 7.5, 13), CFrame.new(center + Vector3.new(8.5, 18.45, 0)), Color3.fromRGB(44, 38, 51), Enum.Material.SmoothPlastic)
	createPart(loft, "LoftRoomCeiling", Vector3.new(17, 0.45, 13), CFrame.new(center + Vector3.new(0, 22.25, 0)), Color3.fromRGB(33, 31, 42), Enum.Material.WoodPlanks)

	local window = createPart(loft, "LoftMoonWindow", Vector3.new(5.4, 3.2, 0.18), CFrame.new(center + Vector3.new(0, 18.8, -6.72)), Color3.fromRGB(120, 195, 255), Enum.Material.Glass)
	window.Transparency = 0.18
	window:SetAttribute("BaseTransparency", window.Transparency)
	createSurfaceText(window, "LoftWindowText", "QUIET\nABOVE", Enum.NormalId.Front, Color3.fromRGB(245, 250, 255), Color3.fromRGB(42, 67, 96))

	for shelfIndex, x in ipairs({ -5.4, 0, 5.4 }) do
		local shelf = createPart(loft, "LoftShelf" .. shelfIndex, Vector3.new(4.4, 4.1, 0.42), CFrame.new(center + Vector3.new(x, 17.2, 5.85)), Color3.fromRGB(82, 53, 38), Enum.Material.Wood)
		for bookIndex = 1, 5 do
			createPart(
				loft,
				("LoftShelf%dBook%d"):format(shelfIndex, bookIndex),
				Vector3.new(0.42, 1.3 + (bookIndex % 2) * 0.25, 0.34),
				shelf.CFrame * CFrame.new(-1.6 + bookIndex * 0.62, 0.25, -0.42),
				Color3.fromRGB(90 + bookIndex * 23, 60 + shelfIndex * 31, 110 + bookIndex * 11),
				Enum.Material.SmoothPlastic
			)
		end
	end

	local rug = createPart(loft, "LoftReadingRug", Vector3.new(8.5, 0.08, 5.4), CFrame.new(center + Vector3.new(0, 15.04, -0.5)), Color3.fromRGB(122, 49, 85), Enum.Material.Fabric)
	rug:SetAttribute("BaseCanCollide", false)
	rug.CanCollide = false

	local returnDoor = createPart(loft, "LibraryLoftReturnDoor", Vector3.new(4.2, 5.2, 0.32), CFrame.new(center + Vector3.new(0, 17.6, 6.32)), Color3.fromRGB(73, 91, 122), Enum.Material.Wood)
	returnDoor:SetAttribute("DestinationCFrame", LIBRARY_LOFT_RETURN_CFRAME)
	returnDoor:SetAttribute("DestinationName", "the Library loft ladder")
	createSurfaceText(returnDoor, "LoftReturnText", "DOWN\nTO LIBRARY", Enum.NormalId.Back, Color3.fromRGB(235, 245, 255), Color3.fromRGB(73, 91, 122))
	createPrompt(returnDoor, "Exit", "Library", 0)
	tag(returnDoor, Constants.Tags.SecretRoomExit)

	loft.PrimaryPart = returnDoor
	return loft
end

local function makeLibraryFurnishings(room)
	local origin = TV_SECRET_ROOM_ORIGIN

	createNoTouchClock(
		room,
		"LibraryClock",
		"Library",
		Vector3.new(5.4, 1.9, 0.24),
		CFrame.new(origin + Vector3.new(7.0, 9.2, LIBRARY_DEPTH / 2 - 0.62), origin + Vector3.new(0, 5, -2)),
		Enum.NormalId.Front
	)

	for shelfIndex, shelf in ipairs({
		{ Name = "LibraryLeftShelf", X = -17.25, Z = -2.2, Yaw = 90, Width = 25.5 },
		{ Name = "LibraryRightShelf", X = 17.25, Z = -2.2, Yaw = -90, Width = 25.5 },
		{ Name = "LibraryBackShelf", X = 0, Z = -16.25, Yaw = 0, Width = 31.2 },
	}) do
		local shelfModel = makeModel(room, shelf.Name)
		local base = CFrame.new(origin + Vector3.new(shelf.X, 3.7, shelf.Z)) * CFrame.Angles(0, math.rad(shelf.Yaw), 0)
		local back = createPart(shelfModel, "ShelfBack", Vector3.new(shelf.Width, 7.4, 0.34), base, Color3.fromRGB(72, 48, 36), Enum.Material.Wood)
		if shelfIndex == 1 then
			createPrompt(back, "Inspect", "Whispering Shelf", 0)
			tag(back, Constants.Tags.LibraryShelf)
		end

		for row = 1, 4 do
			createPart(shelfModel, "ShelfBoard" .. row, Vector3.new(shelf.Width + 0.2, 0.28, 0.72), base * CFrame.new(0, -3.1 + row * 1.55, 0.22), Color3.fromRGB(92, 61, 43), Enum.Material.Wood)
			for bookIndex = 1, 8 do
				local bookX = -shelf.Width / 2 + 0.7 + (bookIndex - 1) * (shelf.Width - 1.4) / 7
				local color = Color3.fromRGB(90 + (bookIndex * 17) % 120, 52 + (row * 31) % 130, 70 + (shelfIndex * 43) % 120)
				createPart(
					shelfModel,
					("Book_%d_%d"):format(row, bookIndex),
					Vector3.new(0.42, 1.05 + (bookIndex % 3) * 0.14, 0.38),
					base * CFrame.new(bookX, -3.05 + row * 1.55, 0.58),
					color,
					Enum.Material.SmoothPlastic
				)
			end
		end
	end

	local tableTop = createPart(room, "LibraryReadingTable", Vector3.new(9.6, 0.5, 4.2), cframeAt(origin, 0, 2.15, 3.2), Color3.fromRGB(94, 62, 42), Enum.Material.Wood)
	createPart(room, "LibraryTableLegA", Vector3.new(0.45, 2.2, 0.45), cframeAt(origin, -4.0, 1.1, 1.8), Color3.fromRGB(75, 49, 35), Enum.Material.Wood)
	createPart(room, "LibraryTableLegB", Vector3.new(0.45, 2.2, 0.45), cframeAt(origin, 4.0, 1.1, 1.8), Color3.fromRGB(75, 49, 35), Enum.Material.Wood)
	createPart(room, "LibraryTableLegC", Vector3.new(0.45, 2.2, 0.45), cframeAt(origin, -4.0, 1.1, 4.6), Color3.fromRGB(75, 49, 35), Enum.Material.Wood)
	createPart(room, "LibraryTableLegD", Vector3.new(0.45, 2.2, 0.45), cframeAt(origin, 4.0, 1.1, 4.6), Color3.fromRGB(75, 49, 35), Enum.Material.Wood)

	local book = createPart(room, "ForbiddenLibraryBook", Vector3.new(2.3, 0.34, 1.55), cframeAt(origin, -2.2, 2.6, 3.0) * CFrame.Angles(0, math.rad(-8), 0), Color3.fromRGB(114, 28, 61), Enum.Material.SmoothPlastic)
	createSurfaceText(book, "ForbiddenBookText", "DO NOT\nREAD", Enum.NormalId.Top, Color3.fromRGB(255, 235, 149), Color3.fromRGB(114, 28, 61))
	createPrompt(book, "Read", "Book That Sighed", 0)
	tag(book, Constants.Tags.LibraryBook)

	local lamp = createPart(room, "LibraryReadingLamp", Vector3.new(0.75, 1.35, 0.75), cframeAt(origin, 3.4, 3.0, 3.35), Color3.fromRGB(255, 214, 102), Enum.Material.Metal)
	lamp.Shape = Enum.PartType.Cylinder
	createPrompt(lamp, "Toggle", "Reading Lamp", 0)
	tag(lamp, Constants.Tags.LibraryLamp)
	local lampLight = Instance.new("PointLight")
	lampLight.Name = "LibraryLampLight"
	lampLight.Brightness = 0
	lampLight.Color = Color3.fromRGB(255, 232, 170)
	lampLight.Range = 15
	lampLight.Parent = lamp
	mark(lampLight)

	local globeStand = makeModel(room, "LibraryGlobeStand")
	local globeCenter = Vector3.new(-5.3, 3.25, 5.45)
	local globeVisualGroup = "LibraryWrongGlobeVisual"
	local globeWood = Color3.fromRGB(116, 75, 45)
	local globeBase = createPart(globeStand, "GlobePedestalBase", Vector3.new(0.34, 2.8, 2.8), cframeAt(origin, globeCenter.X, 1.08, globeCenter.Z) * CFrame.Angles(0, 0, math.rad(90)), globeWood, Enum.Material.Wood)
	globeBase.Shape = Enum.PartType.Cylinder
	local globeStem = createPart(globeStand, "GlobePedestalStem", Vector3.new(0.36, 2.18, 0.36), cframeAt(origin, globeCenter.X, 2.1, globeCenter.Z), globeWood, Enum.Material.Wood)
	globeStem.Shape = Enum.PartType.Cylinder
	local leftYoke = createPart(globeStand, "GlobeLeftYoke", Vector3.new(0.32, 2.25, 0.32), cframeAt(origin, globeCenter.X - 1.05, 2.92, globeCenter.Z) * CFrame.Angles(0, 0, math.rad(-16)), globeWood, Enum.Material.Wood)
	leftYoke.Shape = Enum.PartType.Cylinder
	local rightYoke = createPart(globeStand, "GlobeRightYoke", Vector3.new(0.32, 2.25, 0.32), cframeAt(origin, globeCenter.X + 1.05, 2.92, globeCenter.Z) * CFrame.Angles(0, 0, math.rad(16)), globeWood, Enum.Material.Wood)
	rightYoke.Shape = Enum.PartType.Cylinder
	local axle = createPart(globeStand, "GlobeAxle", Vector3.new(0.18, 2.55, 0.18), cframeAt(origin, globeCenter.X, globeCenter.Y, globeCenter.Z) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(171, 118, 65), Enum.Material.Wood)
	axle.Shape = Enum.PartType.Cylinder

	local globe = createPart(globeStand, "LibraryWrongGlobe", Vector3.new(1.75, 1.75, 1.75), cframeAt(origin, globeCenter.X, globeCenter.Y, globeCenter.Z), Color3.fromRGB(91, 156, 197), Enum.Material.SmoothPlastic)
	globe.Shape = Enum.PartType.Ball
	globe:SetAttribute("LibraryGlobeVisualGroup", globeVisualGroup)

	local function addGlobePatch(name, size, offset, rotation)
		local patch = createPart(
			globeStand,
			name,
			size,
			cframeAt(origin, globeCenter.X, globeCenter.Y, globeCenter.Z) * CFrame.new(offset) * rotation,
			Color3.fromRGB(64, 143, 76),
			Enum.Material.SmoothPlastic
		)
		patch.Shape = Enum.PartType.Ball
		patch.CanCollide = false
		patch:SetAttribute("BaseCanCollide", false)
		patch:SetAttribute("LibraryGlobeVisualGroup", globeVisualGroup)
	end

	addGlobePatch("GlobePatchNorth", Vector3.new(0.58, 0.08, 0.34), Vector3.new(-0.45, 0.36, -0.73), CFrame.Angles(math.rad(8), math.rad(-18), math.rad(20)))
	addGlobePatch("GlobePatchMain", Vector3.new(0.76, 0.08, 0.5), Vector3.new(0.34, -0.08, -0.8), CFrame.Angles(math.rad(-10), math.rad(18), math.rad(-8)))
	addGlobePatch("GlobePatchEast", Vector3.new(0.36, 0.08, 0.62), Vector3.new(0.79, 0.2, 0.12), CFrame.Angles(math.rad(14), math.rad(86), math.rad(12)))
	addGlobePatch("GlobePatchSouth", Vector3.new(0.42, 0.07, 0.3), Vector3.new(-0.1, -0.58, 0.68), CFrame.Angles(math.rad(-10), math.rad(24), math.rad(18)))

	createPrompt(globe, "Spin", "Wrong Globe", 0)
	tag(globe, Constants.Tags.LibraryGlobe)

	local catalog = createPart(room, "LibraryCardCatalog", Vector3.new(3.4, 2.2, 1.5), cframeAt(origin, 12.2, 1.5, 8.0), Color3.fromRGB(115, 78, 51), Enum.Material.Wood)
	createSurfaceText(catalog, "CatalogText", "CATALOG", Enum.NormalId.Front, Color3.fromRGB(255, 235, 149), Color3.fromRGB(115, 78, 51))
	createPrompt(catalog, "Open", "Card Catalog", 0)
	tag(catalog, Constants.Tags.LibraryCatalog)

	local ladder = createPart(room, "LibraryRollingLadder", Vector3.new(1.15, 7.6, 1.15), cframeAt(origin, -15.4, 4.0, -9.2) * CFrame.Angles(0, 0, math.rad(-10)), Color3.fromRGB(181, 121, 67), Enum.Material.Wood, "TrussPart")
	createPrompt(ladder, "Roll", "Rolling Ladder", 0)
	tag(ladder, Constants.Tags.LibraryLadder)

	createPart(room, "LibraryLoftPlatform", Vector3.new(10.5, 0.45, 3.4), cframeAt(origin, -8.8, 8.05, -14.7), Color3.fromRGB(84, 57, 41), Enum.Material.Wood)
	createPart(room, "LibraryLoftRail", Vector3.new(10.5, 1.1, 0.22), cframeAt(origin, -8.8, 8.9, -13.0), Color3.fromRGB(118, 82, 55), Enum.Material.Wood)
	local loftDoor = createPart(room, "LibraryLoftDoor", Vector3.new(3.2, 4.1, 0.28), cframeAt(origin, -8.8, 10.2, -16.55), Color3.fromRGB(68, 88, 118), Enum.Material.Wood)
	loftDoor:SetAttribute("DestinationCFrame", LIBRARY_LOFT_SPAWN_CFRAME)
	createSurfaceText(loftDoor, "LoftDoorText", "LOFT", Enum.NormalId.Front, Color3.fromRGB(235, 245, 255), Color3.fromRGB(68, 88, 118))
	createPrompt(loftDoor, "Open", "Loft Door", 0)
	tag(loftDoor, Constants.Tags.LibraryLoftDoor)

	local key = createPart(room, "BowlingKeyTopShelf", Vector3.new(0.34, 0.34, 1.45), cframeAt(origin, -14.7, 9.42, -15.4) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 219, 92), Enum.Material.Metal)
	key.Shape = Enum.PartType.Cylinder
	local keyHead = createPart(room, "BowlingKeyHead", Vector3.new(0.82, 0.18, 0.82), cframeAt(origin, -15.55, 9.42, -15.4), Color3.fromRGB(255, 219, 92), Enum.Material.Metal)
	keyHead.Shape = Enum.PartType.Cylinder
	createPrompt(key, "Take", "Bowling Key", 0)
	tag(key, Constants.Tags.LibraryTopShelfKey)

	local bookcaseDoor = createPart(room, "LibraryBookcaseDoor", Vector3.new(5.6, 7.6, 0.42), cframeAt(origin, 7.2, 4.0, -16.55), Color3.fromRGB(76, 48, 34), Enum.Material.Wood)
	bookcaseDoor:SetAttribute("DestinationCFrame", BOWLING_ALLEY_SPAWN_CFRAME)
	bookcaseDoor:SetAttribute("SecretClosedCFrame", bookcaseDoor.CFrame)
	createReferenceBookcaseFace(bookcaseDoor)
	createPrompt(bookcaseDoor, "Inspect", "Reference Bookcase", 0)
	tag(bookcaseDoor, Constants.Tags.LibraryBookcaseDoor)

	makeLibraryLoftRoom(room)
end

local function makeBowlingPins(parent, laneIndex, laneX, z, origin)
	origin = origin or Vector3.zero
	local laneSurfaceY = 0.72 + 0.34 / 2
	local pinOffsets = {
		{ 0, 0 },
		{ -0.7, -1.0 },
		{ 0.7, -1.0 },
		{ -1.4, -2.0 },
		{ 0, -2.0 },
		{ 1.4, -2.0 },
		{ -2.1, -3.0 },
		{ -0.7, -3.0 },
		{ 0.7, -3.0 },
		{ 2.1, -3.0 },
	}

	for index, offset in ipairs(pinOffsets) do
		local pinModel = makeModel(parent, ("Lane%dPin%dModel"):format(laneIndex, index))
		pinModel:SetAttribute("BowlingPinModel", true)
		pinModel:SetAttribute("LaneIndex", laneIndex)

		local footPosition = origin + Vector3.new(laneX + offset[1], laneSurfaceY, z + offset[2])
		local coreHeight = 2.55
		local coreDiameter = 0.58
		local pin = createPart(
			pinModel,
			("Lane%dPin%d"):format(laneIndex, index),
			Vector3.new(coreDiameter, coreHeight, coreDiameter),
			CFrame.new(footPosition + Vector3.new(0, coreHeight / 2, 0)),
			Color3.fromRGB(245, 244, 232),
			Enum.Material.SmoothPlastic
		)
		pin.Shape = Enum.PartType.Cylinder
		pin.Transparency = 1
		pin.Anchored = true
		pin.CanCollide = true
		pin.CustomPhysicalProperties = PhysicalProperties.new(0.8, 0.9, 0.08, 1, 1)
		pin:SetAttribute("LaneIndex", laneIndex)
		pin:SetAttribute("BowlingPinCore", true)
		pin:SetAttribute("BaseTransparency", 1)
		pin:SetAttribute("BaseCanCollide", true)
		pin:SetAttribute("BaseAnchored", true)
		tag(pin, Constants.Tags.BowlingPin)
		pinModel.PrimaryPart = pin

		local function addPinPiece(name, size, yOffset, color)
			local piece = createPart(
				pinModel,
				("Lane%dPin%d%s"):format(laneIndex, index, name),
				size,
				CFrame.new(footPosition + Vector3.new(0, yOffset, 0)),
				color,
				Enum.Material.SmoothPlastic
			)
			piece.Shape = Enum.PartType.Ball
			piece.Anchored = true
			piece.CanCollide = false
			piece.Massless = true
			piece:SetAttribute("LaneIndex", laneIndex)
			piece:SetAttribute("BowlingPinVisual", true)
			piece:SetAttribute("BaseCanCollide", false)
			piece:SetAttribute("BaseAnchored", true)

			local weld = Instance.new("WeldConstraint")
			weld.Name = "PinPieceWeld"
			weld.Part0 = pin
			weld.Part1 = piece
			weld.Parent = piece
			return piece
		end

		addPinPiece("Foot", Vector3.new(0.9, 0.28, 0.9), 0.14, Color3.fromRGB(248, 247, 237))
		addPinPiece("Belly", Vector3.new(0.98, 1.05, 0.98), 0.64, Color3.fromRGB(248, 247, 237))
		addPinPiece("Shoulder", Vector3.new(0.72, 0.78, 0.72), 1.34, Color3.fromRGB(248, 247, 237))
		addPinPiece("LowerStripe", Vector3.new(0.64, 0.11, 0.64), 1.65, Color3.fromRGB(220, 52, 67))
		addPinPiece("UpperStripe", Vector3.new(0.55, 0.11, 0.55), 1.82, Color3.fromRGB(220, 52, 67))
		addPinPiece("Neck", Vector3.new(0.42, 0.66, 0.42), 2.02, Color3.fromRGB(248, 247, 237))
		addPinPiece("Head", Vector3.new(0.54, 0.54, 0.54), 2.42, Color3.fromRGB(248, 247, 237))
	end
end

local function makeBowlingAdTv(parent, name, cframe, adOffset, laneIndex)
	local tv = makeModel(parent, name)
	local frame = createPart(tv, name .. "Frame", Vector3.new(8.6, 4.3, 0.42), cframe, Color3.fromRGB(12, 14, 19), Enum.Material.Metal)
	local screen = createPart(tv, name .. "Screen", Vector3.new(7.8, 3.45, 0.18), cframe * CFrame.new(0, 0, -0.26), Color3.fromRGB(20, 28, 42), Enum.Material.Neon)
	screen:SetAttribute("BowlingAdScreen", true)
	screen:SetAttribute("BowlingAdOffset", adOffset)
	local label = createSurfaceText(screen, "BowlingAdText", "BLOXY\nBOWLING", Enum.NormalId.Front, Color3.fromRGB(255, 235, 149), Color3.fromRGB(20, 28, 42))
	label.Font = Enum.Font.GothamBlack

	local glow = Instance.new("SurfaceLight")
	glow.Name = "BowlingAdLight"
	glow.Face = Enum.NormalId.Front
	glow.Brightness = 1.25
	glow.Range = 14
	glow.Color = Color3.fromRGB(119, 255, 203)
	glow.Parent = screen
	mark(glow)

	if laneIndex then
		local sign = createPart(tv, name .. "LaneSign", Vector3.new(7.4, 0.9, 0.18), cframe * CFrame.new(0, -2.85, -0.25), Color3.fromRGB(25, 31, 45), Enum.Material.Neon)
		createSurfaceText(sign, "LaneSignText", "LANE " .. laneIndex, Enum.NormalId.Front, BOWLING_COSMIC_COLORS[((laneIndex - 1) % #BOWLING_COSMIC_COLORS) + 1], Color3.fromRGB(25, 31, 45))
		sign:SetAttribute("CosmicSurface", true)
	end

	tv.PrimaryPart = frame
	return tv
end

local function createZiplineFrame(parent, name, cframe, width, height, color)
	local top = createPart(parent, name .. "Top", Vector3.new(width, 0.16, 0.22), cframe * CFrame.new(0, height / 2, 0), color, Enum.Material.Neon)
	local bottom = createPart(parent, name .. "Bottom", Vector3.new(width, 0.16, 0.22), cframe * CFrame.new(0, -height / 2, 0), color, Enum.Material.Neon)
	local left = createPart(parent, name .. "Left", Vector3.new(0.16, height, 0.22), cframe * CFrame.new(-width / 2, 0, 0), color, Enum.Material.Neon)
	local right = createPart(parent, name .. "Right", Vector3.new(0.16, height, 0.22), cframe * CFrame.new(width / 2, 0, 0), color, Enum.Material.Neon)

	for _, part in ipairs({ top, bottom, left, right }) do
		part.CanCollide = false
		part:SetAttribute("BaseCanCollide", false)
	end
end

local function createZiplineWarpCorridor(parent, pathPoints)
	local tunnel = makeModel(parent, "ZiplineParallaxWarpTunnel")
	local colors = {
		Color3.fromRGB(30, 54, 94),
		Color3.fromRGB(44, 18, 80),
		Color3.fromRGB(14, 72, 91),
		Color3.fromRGB(69, 36, 112),
	}

	for index = 1, #pathPoints - 1 do
		local startPoint = pathPoints[index]
		local endPoint = pathPoints[index + 1]
		local midpoint = (startPoint + endPoint) / 2
		local length = (endPoint - startPoint).Magnitude
		local segmentCFrame = CFrame.new(midpoint, endPoint)
		local color = colors[((index - 1) % #colors) + 1]

		for _, data in ipairs({
			{ Name = "LeftWall", Offset = CFrame.new(-18, 0, 0), Size = Vector3.new(0.5, 34, length + 8), Color = color, Transparency = 0.08 },
			{ Name = "RightWall", Offset = CFrame.new(18, 0, 0), Size = Vector3.new(0.5, 34, length + 8), Color = color, Transparency = 0.08 },
			{ Name = "Ceiling", Offset = CFrame.new(0, 17, 0), Size = Vector3.new(36, 0.45, length + 8), Color = Color3.fromRGB(15, 22, 54), Transparency = 0.18 },
			{ Name = "FloorMist", Offset = CFrame.new(0, -13, 0), Size = Vector3.new(36, 0.34, length + 8), Color = Color3.fromRGB(69, 201, 255), Transparency = 0.54 },
		}) do
			local panel = createPart(tunnel, ("ZiplineWarp%d%s"):format(index, data.Name), data.Size, segmentCFrame * data.Offset, data.Color, Enum.Material.SmoothPlastic)
			panel.Transparency = data.Transparency
			panel.CanCollide = false
			panel:SetAttribute("BaseTransparency", data.Transparency)
			panel:SetAttribute("BaseCanCollide", false)
		end

		for stripeIndex = 1, 4 do
			local z = -length / 2 + stripeIndex * length / 5
			local stripeColor = BOWLING_COSMIC_COLORS[((index + stripeIndex - 2) % #BOWLING_COSMIC_COLORS) + 1]
			local leftStripe = createPart(tunnel, ("ZiplineWarp%dLeftStripe%d"):format(index, stripeIndex), Vector3.new(0.14, 0.18, 8), segmentCFrame * CFrame.new(-17.55, -8 + stripeIndex * 4, z) * CFrame.Angles(0, 0, math.rad(18)), stripeColor, Enum.Material.Neon)
			local rightStripe = createPart(tunnel, ("ZiplineWarp%dRightStripe%d"):format(index, stripeIndex), Vector3.new(0.14, 0.18, 8), segmentCFrame * CFrame.new(17.55, 8 - stripeIndex * 4, z) * CFrame.Angles(0, 0, math.rad(-18)), stripeColor, Enum.Material.Neon)
			leftStripe.CanCollide = false
			rightStripe.CanCollide = false
			leftStripe:SetAttribute("BaseCanCollide", false)
			rightStripe:SetAttribute("BaseCanCollide", false)
		end

		for ringIndex = 1, 3 do
			local alpha = ringIndex / 4
			local ringPosition = startPoint:Lerp(endPoint, alpha)
			local ringCFrame = CFrame.new(ringPosition, endPoint)
			local ringColor = BOWLING_COSMIC_COLORS[((index + ringIndex - 2) % #BOWLING_COSMIC_COLORS) + 1]
			createZiplineFrame(tunnel, ("ZiplineWarpRing%d_%d"):format(index, ringIndex), ringCFrame, 25 + ringIndex * 2, 17 + ringIndex, ringColor)

			local angle = math.rad((index * 50 + ringIndex * 80) % 360)
			local dot = createPart(
				tunnel,
				("ZiplineWarpSpiralDot%d_%d"):format(index, ringIndex),
				Vector3.new(1.2, 1.2, 1.2),
				ringCFrame * CFrame.new(math.cos(angle) * 12, math.sin(angle) * 7, 0),
				ringColor,
				Enum.Material.Neon
			)
			dot.Shape = Enum.PartType.Ball
			dot.CanCollide = false
			dot:SetAttribute("BaseCanCollide", false)
		end
	end

	tunnel.PrimaryPart = tunnel:FindFirstChildWhichIsA("BasePart", true)
	return tunnel
end

local function makeTreetopZiplineArea(room, bowlingOrigin)
	local treetop = makeModel(room, "TreetopZiplineArea")
	local platformCenter = Vector3.new(-14, 26.15, -224)
	local ziplinePath = TREETOP_ZIPLINE_PATH_POINTS
	local ziplineStart = ziplinePath[1]
	local ziplineEnd = ziplinePath[#ziplinePath]

	local accessDoor = createPart(
		room,
		"TreetopAccessDoor",
		Vector3.new(6.4, 7.4, 0.34),
		CFrame.new(bowlingOrigin + Vector3.new(8.6, 5.0, -49.35)),
		Color3.fromRGB(68, 105, 80),
		Enum.Material.Wood
	)
	accessDoor:SetAttribute("DestinationCFrame", TREETOP_ENTRY_CFRAME)
	accessDoor:SetAttribute("DestinationName", "the treetop platform")
	createSurfaceText(accessDoor, "TreetopAccessText", "TREE LINE\nZIPLINE", Enum.NormalId.Front, Color3.fromRGB(225, 255, 206), Color3.fromRGB(68, 105, 80))
	createPrompt(accessDoor, "Enter", "Treetop Zipline", 0)
	tag(accessDoor, Constants.Tags.SecretRoomExit)

	local platform = createPart(treetop, "TreetopPlatform", Vector3.new(24, 0.7, 18), CFrame.new(platformCenter), Color3.fromRGB(115, 78, 45), Enum.Material.WoodPlanks)
	platform:SetAttribute("CosmicSurface", true)
	createPart(treetop, "TreetopLeftRail", Vector3.new(0.35, 2.4, 16), CFrame.new(platformCenter + Vector3.new(-12, 1.4, 0)), Color3.fromRGB(78, 52, 34), Enum.Material.Wood)
	createPart(treetop, "TreetopRightRail", Vector3.new(0.35, 2.4, 16), CFrame.new(platformCenter + Vector3.new(12, 1.4, 0)), Color3.fromRGB(78, 52, 34), Enum.Material.Wood)
	createPart(treetop, "TreetopBackRail", Vector3.new(24, 2.4, 0.35), CFrame.new(platformCenter + Vector3.new(0, 1.4, 8)), Color3.fromRGB(78, 52, 34), Enum.Material.Wood)

	local sign = createPart(treetop, "TreetopZiplineSign", Vector3.new(9, 3, 0.28), CFrame.new(platformCenter + Vector3.new(0, 4.6, 7.5)), Color3.fromRGB(255, 232, 112), Enum.Material.Wood)
	createSurfaceText(sign, "TreetopSignText", "ABOVE THE TREES\nISLAND ZIPLINE", Enum.NormalId.Front, Color3.fromRGB(42, 38, 24), Color3.fromRGB(255, 232, 112))

	for treeIndex, data in ipairs({
		{ X = -27, Z = -237, Height = 24 },
		{ X = -23, Z = -214, Height = 30 },
		{ X = -2, Z = -238, Height = 28 },
		{ X = 2, Z = -215, Height = 25 },
		{ X = -34, Z = -224, Height = 27 },
	}) do
		local trunk = createPart(
			treetop,
			"TreetopTreeTrunk" .. treeIndex,
			Vector3.new(1.4, data.Height, 1.4),
			CFrame.new(data.X, data.Height / 2, data.Z),
			Color3.fromRGB(99, 64, 36),
			Enum.Material.Wood
		)
		trunk.Shape = Enum.PartType.Cylinder
		local canopy = createPart(
			treetop,
			"TreetopCanopy" .. treeIndex,
			Vector3.new(9, 5.8, 9),
			CFrame.new(data.X, data.Height + 2.4, data.Z),
			Color3.fromRGB(45, 134, 70),
			Enum.Material.Grass
		)
		canopy.Shape = Enum.PartType.Ball
		canopy.CanCollide = false
		canopy:SetAttribute("BaseCanCollide", false)
	end

	local cliff = createPart(treetop, "TreetopCliffFace", Vector3.new(28, 18, 1.2), CFrame.new(platformCenter + Vector3.new(0, -8, -9.4)), Color3.fromRGB(93, 91, 85), Enum.Material.Slate)
	cliff:SetAttribute("BaseCanCollide", true)

	createZiplineWarpCorridor(treetop, ziplinePath)

	for segmentIndex = 1, #ziplinePath - 1 do
		local startPoint = ziplinePath[segmentIndex]
		local endPoint = ziplinePath[segmentIndex + 1]
		createBeamBetween(treetop, "IslandZiplineCable" .. segmentIndex, startPoint, endPoint, 0.24, Color3.fromRGB(35, 38, 42), Enum.Material.Metal)
		createBeamBetween(treetop, "IslandZiplineGuideGlow" .. segmentIndex, startPoint + Vector3.new(0, -0.35, 0), endPoint + Vector3.new(0, -0.35, 0), 0.08, BOWLING_COSMIC_COLORS[((segmentIndex - 1) % #BOWLING_COSMIC_COLORS) + 1], Enum.Material.Neon)
	end

	local zipHandle = createPart(
		treetop,
		"IslandZiplineHandle",
		Vector3.new(2.2, 0.42, 1.1),
		CFrame.new(ziplineStart + Vector3.new(0, -1.6, 0), ziplineEnd),
		Color3.fromRGB(255, 214, 96),
		Enum.Material.Metal
	)
	zipHandle:SetAttribute("StartCFrame", CFrame.new(ziplineStart + Vector3.new(0, -3, 3), ziplineEnd))
	zipHandle:SetAttribute("EndCFrame", TREETOP_ZIPLINE_END_CFRAME)
	zipHandle:SetAttribute("PathPointCount", #ziplinePath)
	for index, point in ipairs(ziplinePath) do
		zipHandle:SetAttribute("PathPoint" .. index, point)
	end
	createPrompt(zipHandle, "Ride", "Zipline to Island", 0.2)
	tag(zipHandle, Constants.Tags.TreetopZipline)

	local returnDoor = createPart(treetop, "TreetopReturnDoor", Vector3.new(5.4, 6.4, 0.32), CFrame.new(platformCenter + Vector3.new(-8.8, 3.5, 7.65)), Color3.fromRGB(73, 91, 122), Enum.Material.Wood)
	returnDoor:SetAttribute("DestinationCFrame", BOWLING_MAINTENANCE_CFRAME)
	returnDoor:SetAttribute("DestinationName", "the bowling alley")
	createSurfaceText(returnDoor, "TreetopReturnText", "BACK TO\nBOWLING", Enum.NormalId.Front, Color3.fromRGB(235, 245, 255), Color3.fromRGB(73, 91, 122))
	createPrompt(returnDoor, "Exit", "Bowling Alley", 0)
	tag(returnDoor, Constants.Tags.SecretRoomExit)

	treetop.PrimaryPart = platform
	return treetop
end

local function makeBowlingAlley(roomFolder)
	local room = makeModel(roomFolder, "BowlingAlleyRoom")
	local origin = BOWLING_ALLEY_ORIGIN
	local width = 42
	local depth = 100
	local height = 17

	createPart(room, "BowlingFloor", Vector3.new(width, 1, depth), cframeAt(origin, 0, 0, 0), Color3.fromRGB(37, 40, 48), Enum.Material.Concrete)
	createPart(room, "BowlingBackWall", Vector3.new(width, height, 1), cframeAt(origin, 0, height / 2, -depth / 2), Color3.fromRGB(42, 43, 55), Enum.Material.SmoothPlastic)
	createPart(room, "BowlingFrontWall", Vector3.new(width, height, 1), cframeAt(origin, 0, height / 2, depth / 2), Color3.fromRGB(42, 43, 55), Enum.Material.SmoothPlastic)
	createPart(room, "BowlingLeftWall", Vector3.new(1, height, depth), cframeAt(origin, -width / 2, height / 2, 0), Color3.fromRGB(37, 38, 49), Enum.Material.SmoothPlastic)
	createPart(room, "BowlingRightWall", Vector3.new(1, height, depth), cframeAt(origin, width / 2, height / 2, 0), Color3.fromRGB(37, 38, 49), Enum.Material.SmoothPlastic)
	createPart(room, "BowlingCeiling", Vector3.new(width, 1, depth), cframeAt(origin, 0, height, 0), Color3.fromRGB(24, 25, 34), Enum.Material.Concrete)

	createSpawnLocation(room, "BowlingAlleySpawn", "BowlingAlley", BOWLING_ALLEY_SPAWN_CFRAME, Color3.fromRGB(119, 203, 255), false)
	local bowlingControls = makeRoomControlPanel(
		room,
		"BowlingInsideControlPanel",
		CFrame.new(origin + Vector3.new(13.2, 4.6, 48.85), origin + Vector3.new(0, 4.6, 0)),
		"BowlingAlley",
		"BOWLING",
		{
			IncludeReset = true,
			PanelLabel = "ROOM CONTROLS",
			LightPromptObjectText = "Bowling Light Switch",
		}
	)
	createNoTouchClock(
		room,
		"BowlingClock",
		"BowlingAlley",
		Vector3.new(7.4, 2.3, 0.28),
		CFrame.new(origin + Vector3.new(13.8, 8.4, 48.18), origin + Vector3.new(0, 5, -82)),
		Enum.NormalId.Front
	)

	local exitDoor = createPart(room, "BowlingLibraryExit", Vector3.new(6.4, 7.8, 0.36), cframeAt(origin, 0, 4.35, depth / 2 - 0.52), Color3.fromRGB(83, 64, 122), Enum.Material.Wood)
	exitDoor:SetAttribute("DestinationCFrame", BOWLING_ALLEY_RETURN_CFRAME)
	exitDoor:SetAttribute("DestinationName", "the Library")
	createSurfaceText(exitDoor, "BowlingExitText", "LIBRARY", Enum.NormalId.Front, Color3.fromRGB(255, 235, 149), Color3.fromRGB(83, 64, 122))
	createPrompt(exitDoor, "Exit", "Library", 0)
	tag(exitDoor, Constants.Tags.SecretRoomExit)

	local switch = createPart(room, "CosmicBowlingSwitch", Vector3.new(1.2, 1.8, 0.22), cframeAt(origin, -8.2, 4.3, 47.8), Color3.fromRGB(235, 235, 226), Enum.Material.SmoothPlastic)
	createSurfaceText(switch, "CosmicSwitchText", "COSMIC", Enum.NormalId.Front, Color3.fromRGB(31, 28, 43), Color3.fromRGB(235, 235, 226))
	createPrompt(switch, "Flip", "Cosmic Bowling", 0)
	tag(switch, Constants.Tags.BowlingCosmicSwitch)

	local shoeRack = createPart(
		room,
		"BowlingShoeRack",
		Vector3.new(5.8, 2.8, 1.5),
		CFrame.new(origin + Vector3.new(-20.2, 1.9, 42.5), origin + Vector3.new(0, 1.9, 42.5)),
		Color3.fromRGB(89, 56, 48),
		Enum.Material.Wood
	)
	createSurfaceText(shoeRack, "ShoeRackText", "SHOES\nOPTIONAL?", Enum.NormalId.Front, Color3.fromRGB(255, 235, 149), Color3.fromRGB(89, 56, 48))
	createPrompt(shoeRack, "Inspect", "Shoe Rack", 0)
	tag(shoeRack, Constants.Tags.BowlingShoeRack)

	local scoreboard = createPart(
		room,
		"BowlingScoreboard",
		Vector3.new(30, 4.2, 0.35),
		CFrame.new(origin + Vector3.new(0, 11.5, 34), origin + Vector3.new(0, 9.4, 48)),
		Color3.fromRGB(18, 24, 36),
		Enum.Material.Neon
	)
	createSurfaceText(scoreboard, "ScoreboardText", "LANE 1: 00     LANE 2: 00     LANE 3: 00\nROLL COUNTER: AVOIDING TOUCHES POORLY", Enum.NormalId.Front, Color3.fromRGB(119, 255, 203), Color3.fromRGB(18, 24, 36))
	createPrompt(scoreboard, "Read", "Scoreboard", 0)
	tag(scoreboard, Constants.Tags.BowlingScoreboard)

	for adIndex, laneX in ipairs({ -12, 0, 12 }) do
		makeBowlingAdTv(
			room,
			"BowlingAdTV" .. adIndex,
			CFrame.new(origin + Vector3.new(laneX, 12.8, 24), origin + Vector3.new(laneX, 8.2, 48)),
			adIndex,
			adIndex
		)
	end

	local disco = createPart(room, "BowlingDiscoBall", Vector3.new(2.3, 2.3, 2.3), cframeAt(origin, 0, 13.8, 4), Color3.fromRGB(192, 222, 255), Enum.Material.Glass)
	disco.Shape = Enum.PartType.Ball
	createPrompt(disco, "Inspect", "Disco Ball", 0)
	tag(disco, Constants.Tags.BowlingDiscoBall)
	local discoLight = Instance.new("PointLight")
	discoLight.Name = "DiscoLight"
	discoLight.Brightness = 0
	discoLight.Color = Color3.fromRGB(119, 203, 255)
	discoLight.Range = 36
	discoLight.Parent = disco
	mark(discoLight)

	local laserLength = 48
	for laserIndex = 1, 6 do
		local laser = createPart(
			room,
			"BowlingCosmicLaser" .. laserIndex,
			Vector3.new(if laserIndex % 2 == 0 then 0.14 else 0.2, 0.16, laserLength),
			disco.CFrame * CFrame.Angles(math.rad(-5), math.rad((laserIndex - 1) * 60), 0) * CFrame.new(0, 0, -laserLength / 2),
			BOWLING_COSMIC_COLORS[((laserIndex - 1) % #BOWLING_COSMIC_COLORS) + 1],
			Enum.Material.Neon
		)
		laser.CanCollide = false
		laser.Transparency = 1
		laser:SetAttribute("BaseCanCollide", false)
		laser:SetAttribute("BaseTransparency", 1)
		laser:SetAttribute("CosmicLaser", true)
		laser:SetAttribute("LaserIndex", laserIndex)
		laser:SetAttribute("LaserLength", laserLength)
		laser:SetAttribute("LaserOriginCFrame", disco.CFrame)
		laser:SetAttribute("LaserAngleOffset", (laserIndex - 1) * 60)
		laser:SetAttribute("LaserPitchDegrees", -5 - (laserIndex % 2) * 3)
	end

	local fogVolume = createPart(room, "BowlingCosmicFogVolume", Vector3.new(38, 0.2, 76), cframeAt(origin, 0, 1.2, -2), Color3.fromRGB(155, 205, 255), Enum.Material.SmoothPlastic)
	fogVolume.CanCollide = false
	fogVolume.Transparency = 1
	fogVolume:SetAttribute("BaseCanCollide", false)
	fogVolume:SetAttribute("BaseTransparency", 1)
	local fog = Instance.new("ParticleEmitter")
	fog.Name = "BowlingCosmicFog"
	fog.Texture = "rbxasset://textures/particles/smoke_main.dds"
	fog.Enabled = false
	fog.Rate = 22
	fog.Lifetime = NumberRange.new(3.5, 6)
	fog.Speed = NumberRange.new(0.15, 0.55)
	fog.Drag = 1.5
	fog.SpreadAngle = Vector2.new(12, 12)
	fog.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 3.5),
		NumberSequenceKeypoint.new(0.55, 7),
		NumberSequenceKeypoint.new(1, 10),
	})
	fog.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.86),
		NumberSequenceKeypoint.new(0.45, 0.68),
		NumberSequenceKeypoint.new(1, 1),
	})
	fog.Color = ColorSequence.new(Color3.fromRGB(116, 232, 255), Color3.fromRGB(255, 118, 218))
	fog:SetAttribute("CosmicFog", true)
	fog.Parent = fogVolume

	local laneXs = { -12, 0, 12 }
	for laneIndex, laneX in ipairs(laneXs) do
		local lane = createPart(room, "Lane" .. laneIndex, Vector3.new(8.2, 0.34, 74), cframeAt(origin, laneX, 0.72, -9), Color3.fromRGB(197, 151, 87), Enum.Material.WoodPlanks)
		lane:SetAttribute("CosmicSurface", true)
		createPart(room, "Lane" .. laneIndex .. "LeftGutter", Vector3.new(1, 0.28, 74), cframeAt(origin, laneX - 4.7, 0.86, -9), Color3.fromRGB(20, 22, 28), Enum.Material.Metal)
		local gutter = createPart(room, "Lane" .. laneIndex .. "RightGutter", Vector3.new(1, 0.28, 74), cframeAt(origin, laneX + 4.7, 0.86, -9), Color3.fromRGB(20, 22, 28), Enum.Material.Metal)
		createPrompt(gutter, "Inspect", "Gutter", 0)
		tag(gutter, Constants.Tags.BowlingGutter)

		local button = createPart(room, "Lane" .. laneIndex .. "BowlButton", Vector3.new(2.2, 0.55, 2.2), cframeAt(origin, laneX, 1.45, 35.8), Color3.fromRGB(255, 88, 128), Enum.Material.Neon)
		button.Shape = Enum.PartType.Ball
		button:SetAttribute("LaneIndex", laneIndex)
		button:SetAttribute("LaneX", origin.X + laneX)
		button:SetAttribute("BallSpawnZ", origin.Z + 31.2)
		button:SetAttribute("BallVelocityZ", -118)
		createPrompt(button, "Bowl", "Lane " .. laneIndex, 0)
		tag(button, Constants.Tags.BowlingLaneButton)

		local ballReturn = createPart(room, "Lane" .. laneIndex .. "BallReturn", Vector3.new(3.8, 1.6, 2.8), cframeAt(origin, laneX, 1.35, 42.8) * CFrame.Angles(0, math.rad(180), 0), Color3.fromRGB(58, 63, 75), Enum.Material.Metal)
		ballReturn:SetAttribute("LaneIndex", laneIndex)
		createSurfaceText(ballReturn, "BallReturnText", "RESET\nLANE", Enum.NormalId.Front, Color3.fromRGB(255, 235, 149), Color3.fromRGB(58, 63, 75))
		createSurfaceText(ballReturn, "BallReturnBackText", "RESET\nLANE", Enum.NormalId.Back, Color3.fromRGB(255, 235, 149), Color3.fromRGB(58, 63, 75))
		createPrompt(ballReturn, "Reset", "Lane " .. laneIndex, 0)
		tag(ballReturn, Constants.Tags.BowlingBallReturn)

		local pinResetter = createPart(
			room,
			"Lane" .. laneIndex .. "PinResetter",
			Vector3.new(1.25, 0.42, 1.25),
			cframeAt(origin, laneX, 2.38, 42.8),
			Color3.fromRGB(255, 214, 96),
			Enum.Material.Neon
		)
		pinResetter.Shape = Enum.PartType.Cylinder
		pinResetter:SetAttribute("LaneIndex", laneIndex)

		makeBowlingPins(room, laneIndex, laneX, -26, origin)
	end

	local machinery = createPart(room, "BowlingPinMachine", Vector3.new(36, 5, 4), CFrame.new(origin + Vector3.new(0, 3.6, -33.5)), Color3.fromRGB(48, 52, 63), Enum.Material.Metal)
	createSurfaceText(machinery, "PinMachineText", "PIN MACHINE\nDO NOT ENTER", Enum.NormalId.Front, Color3.fromRGB(255, 235, 149), Color3.fromRGB(48, 52, 63))
	local maintenanceDoor = createPart(room, "BowlingMaintenanceDoor", Vector3.new(6.2, 7.6, 0.35), CFrame.new(origin + Vector3.new(0, 4.25, -37.8)), Color3.fromRGB(91, 95, 107), Enum.Material.Metal)
	maintenanceDoor:SetAttribute("DestinationCFrame", BOWLING_MAINTENANCE_CFRAME)
	createSurfaceText(maintenanceDoor, "MaintenanceDoorText", "MAINTENANCE\nROOM", Enum.NormalId.Front, Color3.fromRGB(255, 235, 149), Color3.fromRGB(91, 95, 107))
	createPrompt(maintenanceDoor, "Enter", "Maintenance Room", 0)
	tag(maintenanceDoor, Constants.Tags.BowlingMaintenanceDoor)

	createPart(room, "MaintenanceFloor", Vector3.new(20, 1, 12), CFrame.new(origin + Vector3.new(0, 0, -45)), Color3.fromRGB(55, 58, 66), Enum.Material.Concrete)
	createPart(room, "MaintenanceBackWall", Vector3.new(20, 10, 1), CFrame.new(origin + Vector3.new(0, 5, -51)), Color3.fromRGB(43, 45, 54), Enum.Material.SmoothPlastic)
	local lever = createPart(room, "PinsetterResetLever", Vector3.new(0.55, 3.2, 0.55), CFrame.new(origin + Vector3.new(-6.5, 3.1, -47.5)) * CFrame.Angles(0, 0, math.rad(-18)), Color3.fromRGB(255, 214, 96), Enum.Material.Metal)
	createPrompt(lever, "Pull", "Pinsetter Lever", 0)
	tag(lever, Constants.Tags.BowlingResetLever)

	makeTreetopZiplineArea(room, origin)

	room.PrimaryPart = scoreboard
	return {
		Model = room,
		ExitDoor = exitDoor,
		LightSwitch = bowlingControls.LightSwitch,
		ResetRoomButton = bowlingControls.ResetRoomButton,
		ReferenceBook = bowlingControls.ReferenceBook,
	}
end

local function makeTVSecretRoom(roomFolder)
	local secretDoor = makeModel(roomFolder, "TVSecretDoor")
	secretDoor:SetAttribute("RoomId", "TVRoom")
	secretDoor:SetAttribute("DestinationCFrame", TV_SECRET_ROOM_ENTRY_CFRAME)

	local doorFrame = CFrame.new(-14, 5.2, -16.42)
	local backPlate = createPart(secretDoor, "SecretDoorFrame", Vector3.new(6.6, 8.4, 0.22), doorFrame, Color3.fromRGB(43, 45, 53), Enum.Material.Metal)
	local panel = createPart(secretDoor, "SecretDoorPanel", Vector3.new(5.55, 7.45, 0.28), doorFrame * CFrame.new(0, 0, 0.12), Color3.fromRGB(76, 55, 132), Enum.Material.Wood)
	markSecretDoorOutline(createPart(secretDoor, "SecretDoorOutlineTop", Vector3.new(6.95, 0.2, 0.18), doorFrame * CFrame.new(0, 4.25, 0.28), Color3.fromRGB(161, 112, 255), Enum.Material.Neon))
	markSecretDoorOutline(createPart(secretDoor, "SecretDoorOutlineBottom", Vector3.new(6.95, 0.2, 0.18), doorFrame * CFrame.new(0, -4.25, 0.28), Color3.fromRGB(161, 112, 255), Enum.Material.Neon))
	markSecretDoorOutline(createPart(secretDoor, "SecretDoorOutlineLeft", Vector3.new(0.2, 8.5, 0.18), doorFrame * CFrame.new(-3.45, 0, 0.28), Color3.fromRGB(161, 112, 255), Enum.Material.Neon))
	markSecretDoorOutline(createPart(secretDoor, "SecretDoorOutlineRight", Vector3.new(0.2, 8.5, 0.18), doorFrame * CFrame.new(3.45, 0, 0.28), Color3.fromRGB(161, 112, 255), Enum.Material.Neon))
	panel:SetAttribute("RoomId", "TVRoom")
	panel:SetAttribute("DestinationCFrame", TV_SECRET_ROOM_ENTRY_CFRAME)
	panel:SetAttribute("SecretClosedCFrame", panel.CFrame)
	local handle = createPart(secretDoor, "SecretDoorHandle", Vector3.new(0.42, 0.42, 0.42), doorFrame * CFrame.new(2.1, -0.15, 0.34), Color3.fromRGB(255, 219, 92), Enum.Material.Metal)
	handle.Shape = Enum.PartType.Ball
	createSurfaceText(panel, "SecretDoorText", "LIBRARY\nAWAITING KEY", Enum.NormalId.Front, Color3.fromRGB(255, 235, 149), Color3.fromRGB(76, 55, 132))
	local prompt = createPrompt(panel, "Open", "Library", 0)
	prompt.MaxActivationDistance = 11
	tag(panel, Constants.Tags.SecretRoomDoor)
	secretDoor.PrimaryPart = panel
	rememberSecretDoorVisibleState(secretDoor)
	setHiddenBaseline(secretDoor)

	local room = makeModel(roomFolder, "TVSecretRoom")
	local origin = TV_SECRET_ROOM_ORIGIN
	local width = LIBRARY_WIDTH
	local depth = LIBRARY_DEPTH
	local height = LIBRARY_HEIGHT
	createPart(room, "SecretRoomFloor", Vector3.new(width, 1, depth), cframeAt(origin, 0, 0, 0), Color3.fromRGB(74, 69, 91), Enum.Material.Concrete)
	createPart(room, "SecretRoomBackWall", Vector3.new(width, height, 1), cframeAt(origin, 0, height / 2, -depth / 2), Color3.fromRGB(42, 44, 55), Enum.Material.SmoothPlastic)
	createPart(room, "SecretRoomFrontWall", Vector3.new(width, height, 1), cframeAt(origin, 0, height / 2, depth / 2), Color3.fromRGB(42, 44, 55), Enum.Material.SmoothPlastic)
	createPart(room, "SecretRoomLeftWall", Vector3.new(1, height, depth), cframeAt(origin, -width / 2, height / 2, 0), Color3.fromRGB(50, 48, 63), Enum.Material.SmoothPlastic)
	createPart(room, "SecretRoomRightWall", Vector3.new(1, height, depth), cframeAt(origin, width / 2, height / 2, 0), Color3.fromRGB(50, 48, 63), Enum.Material.SmoothPlastic)
	createPart(room, "SecretRoomCeiling", Vector3.new(width, 1, depth), cframeAt(origin, 0, height, 0), Color3.fromRGB(34, 36, 48), Enum.Material.Concrete)

	local sign = createPart(room, "SecretRoomSign", Vector3.new(16, 2.3, 0.28), cframeAt(origin, 0, height - 3, -depth / 2 + 0.65), Color3.fromRGB(255, 226, 102), Enum.Material.SmoothPlastic)
	createSurfaceText(sign, "SecretRoomSignText", "THE LIBRARY\nPLEASE TOUCH QUIETLY", Enum.NormalId.Front, Color3.fromRGB(36, 27, 42), Color3.fromRGB(255, 226, 102))

	local keyhole = createPart(room, "SecretRoomKeyhole", Vector3.new(2.1, 2.1, 0.2), cframeAt(origin, 0, 4.5, -depth / 2 + 0.76), Color3.fromRGB(161, 112, 255), Enum.Material.Neon)
	keyhole.Shape = Enum.PartType.Ball

	local exitDoor = createPart(room, "SecretRoomExitDoor", Vector3.new(5.2, 7.1, 0.35), cframeAt(origin, 0, 4.25, depth / 2 - 0.55), Color3.fromRGB(63, 84, 105), Enum.Material.Wood)
	exitDoor:SetAttribute("DestinationCFrame", TV_SECRET_ROOM_RETURN_CFRAME)
	exitDoor:SetAttribute("DestinationName", "the TV Room")
	createSurfaceText(exitDoor, "SecretRoomExitText", "BACK TO\nTV ROOM", Enum.NormalId.Back, Color3.fromRGB(228, 247, 255), Color3.fromRGB(43, 57, 72))
	createPrompt(exitDoor, "Exit", "TV Room", 0)
	tag(exitDoor, Constants.Tags.SecretRoomExit)

	local libraryControls = makeRoomControlPanel(
		room,
		"LibraryInsideControlPanel",
		CFrame.new(origin + Vector3.new(-width / 2 + 5.4, 4.6, depth / 2 - 0.58), origin + Vector3.new(0, 4.6, 0)),
		"Library",
		"LIBRARY",
		{
			IncludeReset = true,
			PanelLabel = "ROOM CONTROLS",
			LightPromptObjectText = "Library Light Switch",
		}
	)
	local libraryLightSwitch = libraryControls.LightSwitch
	local libraryResetRoomButton = libraryControls.ResetRoomButton

	makeLibraryFurnishings(room)
	room.PrimaryPart = keyhole
	return {
		Door = secretDoor,
		Room = room,
		ExitDoor = exitDoor,
		LightSwitch = libraryLightSwitch,
		ResetRoomButton = libraryResetRoomButton,
		ReferenceBook = libraryControls.ReferenceBook,
	}
end

local function makePalmTree(parent, name, x, z, leanDegrees, coconutCount, dropCoconutId)
	local tree = makeModel(parent, name)
	local trunkHeight = 7.2
	local trunkDiameter = 0.8
	local baseCFrame = cframeAt(ISLAND_ORIGIN, x, 1.02, z) * CFrame.Angles(0, 0, math.rad(leanDegrees or 0))
	local trunk = createPart(tree, "PalmTrunk", Vector3.new(trunkDiameter, trunkHeight, trunkDiameter), baseCFrame * CFrame.new(0, trunkHeight / 2, 0), Color3.fromRGB(119, 76, 42), Enum.Material.Wood)
	trunk.CanCollide = false
	trunk:SetAttribute("BaseCanCollide", false)
	local climbTruss = createPart(
		tree,
		"PalmClimbTruss",
		Vector3.new(1.35, trunkHeight + 0.8, 1.35),
		baseCFrame * CFrame.new(0, trunkHeight / 2, 0),
		Color3.fromRGB(99, 64, 38),
		Enum.Material.Wood,
		"TrussPart"
	)
	climbTruss.Transparency = 0.22
	climbTruss:SetAttribute("BaseTransparency", climbTruss.Transparency)
	climbTruss:SetAttribute("BaseCanCollide", true)
	if dropCoconutId then
		trunk:SetAttribute("DropCoconutId", dropCoconutId)
		createPrompt(trunk, "Shake", "Coconut Palm", 0)
		tag(trunk, Constants.Tags.IslandCoconutTree)
	end

	for index = 1, 5 do
		createPart(tree, "PalmTrunkBand", Vector3.new(trunkDiameter + 0.14, 0.14, trunkDiameter + 0.14), baseCFrame * CFrame.new(0, 0.9 + index * 1.05, 0), Color3.fromRGB(91, 58, 34), Enum.Material.Wood)
	end

	local crownCFrame = baseCFrame * CFrame.new(0, trunkHeight + 0.15, 0)
	for index = 1, 6 do
		local angle = (index - 1) * math.pi / 3
		local leaf = createPart(
			tree,
			"PalmLeaf",
			Vector3.new(5.8, 0.32, 1.25),
			crownCFrame * CFrame.Angles(0, angle, math.rad(-14)),
			Color3.fromRGB(61, 156, 77),
			Enum.Material.Grass,
			"WedgePart"
		)
		leaf:SetAttribute("LeafIndex", index)
	end

	for coconutIndex = 1, coconutCount or 0 do
		local angle = math.rad(115 + coconutIndex * 72)
		local coconut = createPart(
			tree,
			"PalmCoconut" .. coconutIndex,
			Vector3.new(0.72, 0.72, 0.72),
			crownCFrame * CFrame.new(math.cos(angle) * 0.62, -0.38 - coconutIndex * 0.08, math.sin(angle) * 0.62),
			Color3.fromRGB(91, 54, 31),
			Enum.Material.Wood
		)
		coconut.Shape = Enum.PartType.Ball
		coconut:SetAttribute("TreeCoconutIndex", coconutIndex)
		if dropCoconutId and coconutIndex == 1 then
			coconut:SetAttribute("DropsWithCoconutId", dropCoconutId)
		end
	end

	tree.PrimaryPart = trunk
	return tree
end

local function makeIslandSpaceLadderSecret(parent)
	local secret = makeModel(parent, "IslandSpaceLadderSecret")
	local blockCFrame = cframeAt(ISLAND_ORIGIN, -10, 11.15, 8)
	local block = createPart(
		secret,
		"IslandHiddenSkyBlock",
		Vector3.new(4.2, 0.9, 4.2),
		blockCFrame,
		Color3.fromRGB(255, 230, 91),
		Enum.Material.Neon
	)
	block.Transparency = 1
	block.CanCollide = true
	block:SetAttribute("BaseTransparency", 1)
	block:SetAttribute("BaseCanCollide", true)
	block:SetAttribute("SpaceBlockId", ISLAND_SPACE_BLOCK_ID)

	local blockLabel = createSurfaceText(block, "IslandSkyBlockText", "BONK\nBLOCK", Enum.NormalId.Bottom, Color3.fromRGB(44, 35, 18), Color3.fromRGB(255, 230, 91))
	blockLabel.Parent.Enabled = false
	blockLabel.Parent:SetAttribute("BaseEnabled", false)
	local blockPrompt = createPrompt(block, "Inspect", "Bonk Block", 0)
	blockPrompt.Enabled = false
	blockPrompt:SetAttribute("BaseEnabled", false)
	tag(block, Constants.Tags.IslandHiddenSkyBlock)

	local ladderFullSize = Vector3.new(1.45, 14.8, 1.45)
	local ladderFullCFrame = blockCFrame * CFrame.new(0, 7.85, 0)
	local ladder = createPart(
		secret,
		"IslandSpaceLadder",
		Vector3.new(1.45, 0.25, 1.45),
		blockCFrame * CFrame.new(0, 0.65, 0),
		Color3.fromRGB(119, 255, 203),
		Enum.Material.Neon,
		"TrussPart"
	)
	ladder.Transparency = 1
	ladder.CanCollide = false
	ladder:SetAttribute("BaseTransparency", 1)
	ladder:SetAttribute("BaseCanCollide", false)
	ladder:SetAttribute("SpaceBlockId", ISLAND_SPACE_BLOCK_ID)
	ladder:SetAttribute("FullSize", ladderFullSize)
	ladder:SetAttribute("FullCFrame", ladderFullCFrame)
	local ladderPrompt = createPrompt(ladder, "Climb", "Ladder to Orbit", 0.2)
	ladderPrompt.Enabled = false
	ladderPrompt:SetAttribute("BaseEnabled", false)
	tag(ladder, Constants.Tags.IslandSpaceLadder)

	secret.PrimaryPart = block
	return secret
end

local function makeIslandWarningSign(parent, name, text, x, z, targetX, targetZ, tagName)
	local signModel = makeModel(parent, name .. "Model")
	local signPosition = ISLAND_ORIGIN + Vector3.new(x, 3.05, z)
	local targetPosition = ISLAND_ORIGIN + Vector3.new(targetX, 2.9, targetZ)
	local signCFrame = CFrame.new(signPosition, targetPosition)

	local post = createPart(
		signModel,
		name .. "Post",
		Vector3.new(0.34, 2.7, 0.34),
		signCFrame * CFrame.new(0, -1.45, 0.1),
		Color3.fromRGB(103, 66, 38),
		Enum.Material.Wood
	)
	local board = createPart(
		signModel,
		name,
		Vector3.new(5.2, 2.05, 0.28),
		signCFrame,
		Color3.fromRGB(255, 238, 139),
		Enum.Material.WoodPlanks
	)
	local trim = createPart(
		signModel,
		name .. "Trim",
		Vector3.new(5.55, 2.35, 0.12),
		signCFrame * CFrame.new(0, 0, 0.08),
		Color3.fromRGB(132, 84, 45),
		Enum.Material.Wood
	)
	trim.CanCollide = false
	trim:SetAttribute("BaseCanCollide", false)

	createSurfaceText(board, name .. "Text", text, Enum.NormalId.Front, Color3.fromRGB(42, 37, 24), Color3.fromRGB(255, 238, 139))
	createPrompt(board, "Read", text:gsub("\n", " "), 0)
	tag(board, tagName)

	signModel.PrimaryPart = post
	return signModel
end

local function makeIslandRoom(roomFolder)
	local room = makeModel(roomFolder, "IslandRoom")
	local origin = ISLAND_ORIGIN

	local ocean = createPart(room, "OceanPlane", Vector3.new(150, 0.28, 112), cframeAt(origin, 0, -0.18, 31), Color3.fromRGB(43, 152, 215), Enum.Material.Glass)
	ocean.Transparency = 0.18
	ocean:SetAttribute("BaseTransparency", ocean.Transparency)

	local sand = createPart(room, "IslandSand", Vector3.new(34, 1.05, 26), cframeAt(origin, 0, 0.45, 4), Color3.fromRGB(229, 202, 123), Enum.Material.Sand)
	createPart(room, "IslandSandNorth", Vector3.new(22, 0.85, 12), cframeAt(origin, -5, 0.62, 14), Color3.fromRGB(235, 211, 140), Enum.Material.Sand)
	createPart(room, "IslandSandSouth", Vector3.new(18, 0.85, 10), cframeAt(origin, 7, 0.62, -6), Color3.fromRGB(224, 194, 112), Enum.Material.Sand)
	sand:SetAttribute("RoomId", "Island")

	for index = 1, 5 do
		local rock = createPart(
			room,
			"IslandRock",
			Vector3.new(1.2 + index * 0.15, 0.7 + index * 0.05, 1.4),
			cframeAt(origin, -13 + index * 5.2, 1.12, 14 - (index % 2) * 20) * CFrame.Angles(0, math.rad(index * 24), math.rad(index * 9)),
			Color3.fromRGB(104, 112, 116),
			Enum.Material.Slate
		)
		rock.Shape = Enum.PartType.Ball
	end

	makePalmTree(room, "BentPalm", -10, 8, -9, 1)
	makePalmTree(room, "SmallPalm", 10, 1, 6, 2, "dropped_palm_coconut")
	makeIslandSpaceLadderSecret(room)

		local function makeIslandBackdrop(name, size, cframe, color, transparency)
			local layer = createPart(room, name, size, cframe, color, Enum.Material.SmoothPlastic)
			layer.Transparency = transparency
			layer.CanCollide = false
			layer:SetAttribute("BaseTransparency", layer.Transparency)
			layer:SetAttribute("BaseCanCollide", false)
			return layer
		end

		for _, data in ipairs({
			{ Name = "NorthSkyParallaxFar", Size = Vector3.new(170, 96, 0.82), CFrame = cframeAt(origin, 0, 46, 88), Color = Color3.fromRGB(132, 213, 255), Transparency = 0.05 },
			{ Name = "NorthOceanParallaxMid", Size = Vector3.new(170, 16, 0.74), CFrame = cframeAt(origin, 0, 6.6, 86.6), Color = Color3.fromRGB(40, 149, 213), Transparency = 0.04 },
			{ Name = "NorthCloudParallaxNear", Size = Vector3.new(50, 3.4, 0.58), CFrame = cframeAt(origin, -28, 24.5, 85.8), Color = Color3.fromRGB(235, 248, 255), Transparency = 0.16 },
			{ Name = "NorthCloudParallaxWide", Size = Vector3.new(42, 2.8, 0.58), CFrame = cframeAt(origin, 31, 21.4, 85.6), Color = Color3.fromRGB(229, 244, 255), Transparency = 0.2 },
			{ Name = "SouthSkyParallaxFar", Size = Vector3.new(170, 96, 0.82), CFrame = cframeAt(origin, 0, 46, -29), Color = Color3.fromRGB(118, 197, 238), Transparency = 0.05 },
			{ Name = "SouthOceanParallaxMid", Size = Vector3.new(170, 16, 0.74), CFrame = cframeAt(origin, 0, 6.2, -27.8), Color = Color3.fromRGB(37, 137, 202), Transparency = 0.05 },
			{ Name = "WestSkyParallaxFar", Size = Vector3.new(0.82, 96, 130), CFrame = cframeAt(origin, -76, 46, 31), Color = Color3.fromRGB(109, 192, 238), Transparency = 0.05 },
			{ Name = "WestOceanParallaxMid", Size = Vector3.new(0.74, 16, 130), CFrame = cframeAt(origin, -74.6, 6.2, 31), Color = Color3.fromRGB(40, 148, 213), Transparency = 0.05 },
			{ Name = "EastSkyParallaxFar", Size = Vector3.new(0.82, 96, 130), CFrame = cframeAt(origin, 76, 46, 31), Color = Color3.fromRGB(109, 192, 238), Transparency = 0.05 },
			{ Name = "EastOceanParallaxMid", Size = Vector3.new(0.74, 16, 130), CFrame = cframeAt(origin, 74.6, 6.2, 31), Color = Color3.fromRGB(40, 148, 213), Transparency = 0.05 },
			{ Name = "IslandSkyParallaxCanopy", Size = Vector3.new(170, 0.74, 130), CFrame = cframeAt(origin, 0, 82, 31), Color = Color3.fromRGB(122, 207, 248), Transparency = 0.18 },
			{ Name = "IslandHighCloudWrap", Size = Vector3.new(130, 0.42, 32), CFrame = cframeAt(origin, -8, 70, 14), Color = Color3.fromRGB(238, 249, 255), Transparency = 0.42 },
		}) do
			makeIslandBackdrop(data.Name, data.Size, data.CFrame, data.Color, data.Transparency)
		end

		for waveIndex = 1, 7 do
			local z = 43 + waveIndex * 5.3
			local wave = createPart(
				room,
				"IslandParallaxWave" .. waveIndex,
				Vector3.new(112 - waveIndex * 5, 0.16, 0.32),
				cframeAt(origin, (waveIndex % 2 == 0) and -8 or 9, 0.55 + waveIndex * 0.04, z),
				Color3.fromRGB(176, 236, 255),
				Enum.Material.Neon
			)
			wave.Transparency = 0.36 + waveIndex * 0.045
			wave.CanCollide = false
			wave:SetAttribute("BaseTransparency", wave.Transparency)
			wave:SetAttribute("BaseCanCollide", false)
		end

		for _, data in ipairs({
			{ Name = "IslandBoundaryLeft", Size = Vector3.new(1, 34, 68), CFrame = cframeAt(origin, -31, 17, 5) },
			{ Name = "IslandBoundaryRight", Size = Vector3.new(1, 34, 68), CFrame = cframeAt(origin, 31, 17, 5) },
			{ Name = "IslandBoundaryBack", Size = Vector3.new(62, 34, 1), CFrame = cframeAt(origin, 0, 17, 34) },
			{ Name = "IslandBoundaryFront", Size = Vector3.new(62, 34, 1), CFrame = cframeAt(origin, 0, 17, -25) },
		}) do
			local boundary = createPart(room, data.Name, data.Size, data.CFrame, Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
			boundary.Transparency = 1
			boundary:SetAttribute("BaseTransparency", boundary.Transparency)
		end

		local sunGlow = createPart(room, "IslandSunGlow", Vector3.new(34, 34, 0.18), cframeAt(origin, 28, 20, 83.8), Color3.fromRGB(255, 240, 151), Enum.Material.Neon)
		sunGlow.Shape = Enum.PartType.Ball
		sunGlow.Transparency = 0.72
		sunGlow.CanCollide = false
		sunGlow:SetAttribute("BaseTransparency", sunGlow.Transparency)
		sunGlow:SetAttribute("BaseCanCollide", false)
		local sun = createPart(room, "IslandSun", Vector3.new(20, 20, 0.35), cframeAt(origin, 28, 20, 84), Color3.fromRGB(255, 222, 88), Enum.Material.Neon)
		sun.Shape = Enum.PartType.Ball
		sun.CanCollide = false
		sun:SetAttribute("BaseCanCollide", false)
	local sunLight = Instance.new("PointLight")
	sunLight.Name = "IslandSunLight"
	sunLight.Brightness = 1.6
	sunLight.Color = Color3.fromRGB(255, 230, 132)
	sunLight.Range = 42
	sunLight.Parent = sun
	mark(sunLight)

	for index = 1, 8 do
		createPart(
			room,
			"DockPlank",
			Vector3.new(6.2, 0.38, 1.15),
			cframeAt(origin, 0, 0.9, -21 + index * 1.55),
			Color3.fromRGB(118, 75, 45),
			Enum.Material.WoodPlanks
		)
	end
	createPart(room, "DockLeftRail", Vector3.new(0.28, 2.1, 15), cframeAt(origin, -3.3, 2.15, -14.8), Color3.fromRGB(98, 61, 37), Enum.Material.Wood)
	createPart(room, "DockRightRail", Vector3.new(0.28, 2.1, 15), cframeAt(origin, 3.3, 2.15, -14.8), Color3.fromRGB(98, 61, 37), Enum.Material.Wood)

		local exitGate = createPart(room, "IslandExitGate", Vector3.new(8.2, 6.4, 0.62), cframeAt(origin, 0, 3.2, -23.4), Color3.fromRGB(67, 93, 112), Enum.Material.Metal)
		exitGate:SetAttribute("DestinationCFrame", ISLAND_RETURN_CFRAME)
		exitGate:SetAttribute("RoomId", "Island")
		exitGate:SetAttribute("ExitMode", "Door")
		createSurfaceText(exitGate, "IslandExitText", "HALLWAY", Enum.NormalId.Front, Color3.fromRGB(231, 247, 255), Color3.fromRGB(35, 55, 70))
		local exitPrompt = createPrompt(exitGate, "Leave", "Hallway", 0)
		exitPrompt.MaxActivationDistance = 6
		tag(exitGate, Constants.Tags.IslandExit)

		for _, data in ipairs({
			{ Name = "IslandOceanExitLeft", Size = Vector3.new(1.8, 8, 52), CFrame = cframeAt(origin, -25.4, 4, 7.8) },
			{ Name = "IslandOceanExitRight", Size = Vector3.new(1.8, 8, 52), CFrame = cframeAt(origin, 25.4, 4, 7.8) },
			{ Name = "IslandOceanExitBack", Size = Vector3.new(50, 8, 1.8), CFrame = cframeAt(origin, 0, 4, 28.4) },
			{ Name = "IslandOceanExitFrontLeft", Size = Vector3.new(20, 8, 1.8), CFrame = cframeAt(origin, -16, 4, -16.4) },
			{ Name = "IslandOceanExitFrontRight", Size = Vector3.new(20, 8, 1.8), CFrame = cframeAt(origin, 16, 4, -16.4) },
		}) do
			local oceanExit = createPart(room, data.Name, data.Size, data.CFrame, Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
			oceanExit.Transparency = 1
			oceanExit.CanCollide = false
			oceanExit.CanTouch = true
			oceanExit:SetAttribute("BaseTransparency", 1)
			oceanExit:SetAttribute("BaseCanCollide", false)
			oceanExit:SetAttribute("RoomId", "Island")
			oceanExit:SetAttribute("ExitMode", "Ocean")
			tag(oceanExit, Constants.Tags.IslandExit)
		end

	local islandControls = makeRoomControlPanel(
		room,
		"IslandInsideControlPanel",
		CFrame.new(origin + Vector3.new(-7.35, 4.65, -22.85), origin + Vector3.new(0, 4.65, 4)),
		"Island",
		"ISLAND",
		{
			IncludeReset = true,
			PanelLabel = "ROOM CONTROLS",
			LightPromptObjectText = "Island Light Switch",
		}
	)
	local lightSwitch = islandControls.LightSwitch
	local resetRoomButton = islandControls.ResetRoomButton
	local referenceBook = islandControls.ReferenceBook

	makeIslandWarningSign(room, "IslandSharkWarningSign", "BEWARE\nOF SHARKS\nWATCH OUT FOR\nLAND SHARKS!", 12.5, -7.5, 1, 2, Constants.Tags.IslandSharkSign)
	makeIslandWarningSign(room, "IslandJellyfishWarningSign", "BEWARE\nOF JELLYFISH", -12.5, 12.5, -1, 5, Constants.Tags.IslandJellyfishSign)

		createNoTouchClock(
		room,
		"IslandClock",
		"Island",
		Vector3.new(6.2, 2.1, 0.28),
		CFrame.new(origin + Vector3.new(0, 8.05, -22.85), origin + Vector3.new(0, 5, 4)),
		Enum.NormalId.Front
	)
	createSpawnLocation(room, "IslandSpawn", "Island", ISLAND_SPAWN_CFRAME, Color3.fromRGB(255, 205, 91), false)

	room.PrimaryPart = sand
	return {
		Model = room,
		ExitGate = exitGate,
		LightSwitch = lightSwitch,
		ResetRoomButton = resetRoomButton,
		ReferenceBook = referenceBook,
	}
end

local function makeIslandObjects(objectsFolder)
	local origin = ISLAND_ORIGIN
	local objects = makeModel(objectsFolder, "IslandObjects")

	local function makeGroundCoconut(name, localPosition, coconutId, startsCrab, hidden)
		local coconut = createPart(
			objects,
			name,
			Vector3.new(1.05, 1.05, 1.05),
			cframeAt(origin, localPosition.X, localPosition.Y, localPosition.Z) * CFrame.Angles(math.rad(8), math.rad(25), math.rad(-11)),
			Color3.fromRGB(94, 55, 31),
			Enum.Material.Wood
		)
		coconut.Shape = Enum.PartType.Ball
			coconut:SetAttribute("CoconutId", coconutId)
			coconut:SetAttribute("StartsCrab", startsCrab == true)
			coconut:SetAttribute("StartsSeagulls", coconutId == "quiet_coconut")

		local eyeA = createPart(objects, name .. "EyeA", Vector3.new(0.12, 0.08, 0.08), coconut.CFrame * CFrame.new(-0.18, 0.22, -0.5), Color3.fromRGB(28, 18, 12), Enum.Material.SmoothPlastic)
		local eyeB = createPart(objects, name .. "EyeB", Vector3.new(0.12, 0.08, 0.08), coconut.CFrame * CFrame.new(0.1, 0.26, -0.52), Color3.fromRGB(28, 18, 12), Enum.Material.SmoothPlastic)
		local eyeC = createPart(objects, name .. "EyeC", Vector3.new(0.1, 0.08, 0.08), coconut.CFrame * CFrame.new(0.26, 0.03, -0.48), Color3.fromRGB(28, 18, 12), Enum.Material.SmoothPlastic)
		eyeA.CanCollide = false
		eyeB.CanCollide = false
		eyeC.CanCollide = false
		eyeA:SetAttribute("BaseCanCollide", false)
		eyeB:SetAttribute("BaseCanCollide", false)
		eyeC:SetAttribute("BaseCanCollide", false)

		local prompt = createPrompt(coconut, "Inspect", "Coconut", 0)
		if hidden then
			for _, part in ipairs({ coconut, eyeA, eyeB, eyeC }) do
				part.Transparency = 1
				part.CanCollide = false
				part:SetAttribute("BaseTransparency", 1)
				part:SetAttribute("BaseCanCollide", false)
			end
			prompt.Enabled = false
			prompt:SetAttribute("BaseEnabled", false)
		end
		tag(coconut, Constants.Tags.IslandCoconut)
		return coconut
	end

	makeGroundCoconut("IslandCoconutCrabShell", Vector3.new(-3.2, 1.12, 11.8), "crab_shell", true, false)
	makeGroundCoconut("IslandQuietCoconut", Vector3.new(13.5, 1.08, -4.2), "quiet_coconut", false, false)
	makeGroundCoconut("IslandDroppedPalmCoconut", Vector3.new(9.8, 1.08, 1.2), "dropped_palm_coconut", false, true)

	for woodIndex, data in ipairs({
		{ Position = Vector3.new(-15.2, 1.0, -4.8), Yaw = -25 },
		{ Position = Vector3.new(14.6, 1.0, 12.4), Yaw = 18 },
		{ Position = Vector3.new(1.8, 1.0, 17.4), Yaw = 64 },
		{ Position = Vector3.new(-11.8, 1.0, 15.3), Yaw = -72 },
	}) do
		local wood = createPart(
			objects,
			"IslandScrapWood" .. woodIndex,
			Vector3.new(2.8, 0.28, 0.42),
			cframeAt(origin, data.Position.X, data.Position.Y, data.Position.Z) * CFrame.Angles(0, math.rad(data.Yaw), math.rad(5)),
			Color3.fromRGB(126, 78, 43),
			Enum.Material.WoodPlanks
		)
		wood:SetAttribute("WoodId", "scrap_" .. woodIndex)
		createPrompt(wood, "Collect", "Scrap Wood", 0)
		tag(wood, Constants.Tags.IslandScrapWood)
	end

	local fireRing = makeModel(objects, "IslandFireRing")
	local fireCenter = cframeAt(origin, 0, 1.04, 4.6)
	for rockIndex = 1, 10 do
		local angle = (rockIndex - 1) * math.pi * 2 / 10
		local rock = createPart(
			fireRing,
			"FireRingRock" .. rockIndex,
			Vector3.new(1.05, 0.62, 0.9),
			fireCenter * CFrame.new(math.cos(angle) * 2.45, 0, math.sin(angle) * 2.45) * CFrame.Angles(0, -angle, math.rad((rockIndex % 3 - 1) * 7)),
			Color3.fromRGB(102, 101, 93),
			Enum.Material.Slate
		)
		rock.Shape = Enum.PartType.Ball
	end

	for stickIndex = 1, 3 do
		local stick = createPart(
			fireRing,
			"FireRingWoodStick" .. stickIndex,
			Vector3.new(2.45, 0.28, 0.32),
			fireCenter * CFrame.new(0, 0.15 + stickIndex * 0.12, 0) * CFrame.Angles(0, math.rad((stickIndex - 1) * 60), math.rad(7)),
			Color3.fromRGB(118, 70, 36),
			Enum.Material.Wood
		)
		stick.Transparency = 1
		stick.CanCollide = false
		stick:SetAttribute("FirewoodIndex", stickIndex)
		stick:SetAttribute("BaseTransparency", 1)
		stick:SetAttribute("BaseCanCollide", false)
	end

	local fireEmitter = createPart(fireRing, "IslandFireEmitter", Vector3.new(0.6, 0.6, 0.6), fireCenter * CFrame.new(0, 0.6, 0), Color3.fromRGB(255, 135, 42), Enum.Material.Neon)
	fireEmitter.Shape = Enum.PartType.Ball
	fireEmitter.Transparency = 1
	fireEmitter.CanCollide = false
	fireEmitter:SetAttribute("BaseTransparency", 1)
	fireEmitter:SetAttribute("BaseCanCollide", false)

	local function addEmitter(name, texture, rate, lifetime, speed, size, color, transparency, acceleration)
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = name
		emitter.Texture = texture
		emitter.Enabled = false
		emitter.Rate = rate
		emitter.Lifetime = lifetime
		emitter.Speed = speed
		emitter.Drag = 1.25
		emitter.SpreadAngle = Vector2.new(18, 18)
		emitter.Size = size
		emitter.Color = color
		emitter.Transparency = transparency
		emitter.Acceleration = acceleration
		emitter:SetAttribute("IslandFireEmitter", true)
		emitter.Parent = fireEmitter
		return emitter
	end

	addEmitter(
		"IslandFireCore",
		"rbxasset://textures/particles/fire_main.dds",
		42,
		NumberRange.new(0.35, 0.7),
		NumberRange.new(1.2, 2.8),
		NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1.2),
			NumberSequenceKeypoint.new(0.45, 2.1),
			NumberSequenceKeypoint.new(1, 0.25),
		}),
		ColorSequence.new(Color3.fromRGB(255, 239, 118), Color3.fromRGB(255, 78, 31)),
		NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.08),
			NumberSequenceKeypoint.new(0.75, 0.24),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Vector3.new(0, 3.1, 0)
	)
	addEmitter(
		"IslandFireGlow",
		"rbxasset://textures/particles/sparkles_main.dds",
		16,
		NumberRange.new(0.3, 0.55),
		NumberRange.new(0.8, 1.8),
		NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(1, 0.08),
		}),
		ColorSequence.new(Color3.fromRGB(255, 170, 48), Color3.fromRGB(255, 62, 36)),
		NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.22),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Vector3.new(0, 4.2, 0)
	)
	addEmitter(
		"IslandCampfireSmoke",
		"rbxasset://textures/particles/smoke_main.dds",
		11,
		NumberRange.new(3.8, 6.5),
		NumberRange.new(0.35, 0.8),
		NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1.5),
			NumberSequenceKeypoint.new(0.55, 4.5),
			NumberSequenceKeypoint.new(1, 7.5),
		}),
		ColorSequence.new(Color3.fromRGB(99, 99, 95), Color3.fromRGB(182, 182, 174)),
		NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.68),
			NumberSequenceKeypoint.new(0.6, 0.82),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Vector3.new(0, 2.5, 0)
	)

	local firePromptPart = createPart(fireRing, "IslandFireRingPrompt", Vector3.new(5.2, 1.4, 5.2), fireCenter * CFrame.new(0, 0.45, 0), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
	firePromptPart.Transparency = 1
	firePromptPart.CanCollide = false
	firePromptPart:SetAttribute("BaseTransparency", 1)
	firePromptPart:SetAttribute("BaseCanCollide", false)
	createPrompt(firePromptPart, "Add Wood", "Rock Ring", 0)
	tag(firePromptPart, Constants.Tags.IslandFireRing)
	fireRing.PrimaryPart = firePromptPart

	local shovel = makeModel(objects, "IslandShovel")
	local shovelCFrame = cframeAt(origin, -8, 2.35, 1.5) * CFrame.Angles(math.rad(-4), math.rad(18), math.rad(-34))
	local handle = createPart(shovel, "ShovelHandle", Vector3.new(0.24, 4.55, 0.24), shovelCFrame, Color3.fromRGB(113, 71, 39), Enum.Material.Wood)
	createPart(shovel, "ShovelGrip", Vector3.new(1.42, 0.22, 0.28), shovelCFrame * CFrame.new(0, 2.42, 0), Color3.fromRGB(84, 51, 30), Enum.Material.Wood)
	createPart(shovel, "ShovelGripBack", Vector3.new(0.26, 0.62, 0.26), shovelCFrame * CFrame.new(0, 2.12, 0), Color3.fromRGB(84, 51, 30), Enum.Material.Wood)
	createPart(shovel, "ShovelBladeCollar", Vector3.new(0.7, 0.32, 0.34), shovelCFrame * CFrame.new(0, -2.18, 0), Color3.fromRGB(137, 143, 148), Enum.Material.Metal)
	createPart(shovel, "ShovelBladeNeck", Vector3.new(0.36, 0.58, 0.3), shovelCFrame * CFrame.new(0, -2.55, 0), Color3.fromRGB(163, 169, 174), Enum.Material.Metal)
	createPart(shovel, "ShovelBlade", Vector3.new(1.35, 1.52, 0.24), shovelCFrame * CFrame.new(0, -3.08, 0), Color3.fromRGB(191, 197, 201), Enum.Material.Metal, "WedgePart")
	createPrompt(handle, "Dig", "Shovel", 0)
	tag(handle, Constants.Tags.IslandShovel)
	shovel.PrimaryPart = handle

	local treasure = makeModel(objects, "IslandTreasureBox")
	local base = createPart(treasure, "TreasureChestBase", Vector3.new(4.4, 1.55, 2.55), cframeAt(origin, 5.5, 1.18, 8.4), Color3.fromRGB(111, 63, 33), Enum.Material.Wood)
	base:SetAttribute("TreasureLayer", "Chest")
	local lid = createPart(treasure, "TreasureChestLid", Vector3.new(4.6, 0.9, 2.7), cframeAt(origin, 5.5, 2.42, 8.4), Color3.fromRGB(132, 76, 41), Enum.Material.Wood)
	lid:SetAttribute("TreasureLayer", "Chest")
	createPart(treasure, "TreasureBandFront", Vector3.new(4.7, 0.24, 0.2), cframeAt(origin, 5.5, 2.35, 7.02), Color3.fromRGB(255, 202, 75), Enum.Material.Metal):SetAttribute("TreasureLayer", "Chest")
	createPart(treasure, "TreasureLock", Vector3.new(0.55, 0.55, 0.18), cframeAt(origin, 5.5, 1.85, 7.03), Color3.fromRGB(255, 214, 96), Enum.Material.Metal):SetAttribute("TreasureLayer", "Chest")
	local treasurePrompt = createPrompt(base, "Open", "Treasure Box", 0)
	treasurePrompt.Enabled = false
	treasurePrompt:SetAttribute("BaseEnabled", false)
	tag(base, Constants.Tags.IslandTreasure)

	local colaCFrame = cframeAt(origin, 5.5, 2.3, 8.25) * CFrame.Angles(0, 0, math.rad(90))
	local colaCan = createPart(treasure, "IslandBloxyColaCan", Vector3.new(1.55, 0.82, 0.82), colaCFrame, Color3.fromRGB(220, 38, 47), Enum.Material.Metal)
	colaCan.Shape = Enum.PartType.Cylinder
	colaCan:SetAttribute("TreasureLayer", "Cola")
	local colaTop = createPart(treasure, "IslandBloxyColaTop", Vector3.new(0.78, 0.08, 0.78), cframeAt(origin, 5.5, 3.1, 8.25), Color3.fromRGB(238, 238, 232), Enum.Material.Metal)
	colaTop:SetAttribute("TreasureLayer", "Cola")
	local colaBottom = createPart(treasure, "IslandBloxyColaBottom", Vector3.new(0.78, 0.08, 0.78), cframeAt(origin, 5.5, 1.5, 8.25), Color3.fromRGB(196, 203, 207), Enum.Material.Metal)
	colaBottom:SetAttribute("TreasureLayer", "Cola")
	local colaLabel = createPart(treasure, "IslandBloxyColaLabel", Vector3.new(0.94, 0.76, 0.08), cframeAt(origin, 5.5, 2.32, 7.78), Color3.fromRGB(245, 245, 242), Enum.Material.SmoothPlastic)
	colaLabel:SetAttribute("TreasureLayer", "Cola")
	createSurfaceText(colaLabel, "IslandBloxyColaText", "BLOXY\nCOLA", Enum.NormalId.Front, Color3.fromRGB(220, 38, 47), Color3.fromRGB(245, 245, 242))
	local colaPrompt = createPrompt(colaCan, "Sip", "Bloxy Cola", 0)
	colaPrompt.Enabled = false
	colaPrompt:SetAttribute("BaseEnabled", false)
	tag(colaCan, Constants.Tags.IslandBloxyCola)
	treasure.PrimaryPart = base
	setHiddenBaseline(treasure)

	objects.PrimaryPart = handle
	return {
		Model = objects,
		Shovel = shovel,
		Treasure = treasure,
	}
end

local function makeSpaceStationRoom(roomFolder)
	local room = makeModel(roomFolder, "SpaceStationRoom")
	local origin = SPACE_STATION_ORIGIN
	local width = 42
	local depth = 32
	local height = 18

	createPart(room, "SpaceStationFloor", Vector3.new(width, 1, depth), cframeAt(origin, 0, 0, 0), Color3.fromRGB(72, 82, 94), Enum.Material.DiamondPlate)
	createPart(room, "SpaceStationCeiling", Vector3.new(width, 1, depth), cframeAt(origin, 0, height, 0), Color3.fromRGB(31, 38, 52), Enum.Material.Metal)
	createPart(room, "SpaceStationBackWall", Vector3.new(width, height, 1), cframeAt(origin, 0, height / 2, -depth / 2), Color3.fromRGB(37, 47, 65), Enum.Material.Metal)
	createPart(room, "SpaceStationFrontWall", Vector3.new(width, height, 1), cframeAt(origin, 0, height / 2, depth / 2), Color3.fromRGB(37, 47, 65), Enum.Material.Metal)
	createPart(room, "SpaceStationLeftWall", Vector3.new(1, height, depth), cframeAt(origin, -width / 2, height / 2, 0), Color3.fromRGB(32, 41, 58), Enum.Material.Metal)
	createPart(room, "SpaceStationRightWall", Vector3.new(1, height, depth), cframeAt(origin, width / 2, height / 2, 0), Color3.fromRGB(32, 41, 58), Enum.Material.Metal)

	for ribIndex = 1, 5 do
		local z = -depth / 2 + ribIndex * (depth / 6)
		createPart(room, "SpaceStationCeilingRib" .. ribIndex, Vector3.new(width - 3, 0.28, 0.28), cframeAt(origin, 0, height - 0.72, z), Color3.fromRGB(119, 255, 203), Enum.Material.Neon)
	end

	local returnDoor = createPart(room, "SpaceStationReturnDoor", Vector3.new(6.6, 7.4, 0.36), cframeAt(origin, 0, 4.2, depth / 2 - 0.55), Color3.fromRGB(67, 92, 126), Enum.Material.Metal)
	returnDoor:SetAttribute("DestinationCFrame", ISLAND_SPAWN_CFRAME)
	returnDoor:SetAttribute("DestinationName", "the island")
	createSurfaceText(returnDoor, "SpaceStationReturnText", "AIRLOCK\nTO ISLAND", Enum.NormalId.Front, Color3.fromRGB(231, 247, 255), Color3.fromRGB(67, 92, 126))
	createPrompt(returnDoor, "Cycle", "Airlock to Island", 0)
	tag(returnDoor, Constants.Tags.SecretRoomExit)

	local controls = makeRoomControlPanel(
		room,
		"SpaceStationInsideControlPanel",
		CFrame.new(origin + Vector3.new(-12.4, 4.75, depth / 2 - 0.65), origin + Vector3.new(0, 4.75, 0)),
		"SpaceStation",
		"SPACE STATION",
		{
			IncludeReset = true,
			PanelLabel = "ROOM CONTROLS",
			LightPromptObjectText = "Station Light Switch",
		}
	)

	createNoTouchClock(
		room,
		"SpaceStationClock",
		"SpaceStation",
		Vector3.new(6.4, 2.0, 0.28),
		CFrame.new(origin + Vector3.new(12.6, 7.6, depth / 2 - 0.7), origin + Vector3.new(0, 5, 0)),
		Enum.NormalId.Front
	)
	createSpawnLocation(room, "SpaceStationSpawn", "SpaceStation", SPACE_STATION_SPAWN_CFRAME, Color3.fromRGB(119, 255, 203), false)

	local airlockHandle = createPart(room, "SpaceStationAirlockHandle", Vector3.new(0.55, 1.7, 0.55), cframeAt(origin, 4.2, 3.45, depth / 2 - 1.05), Color3.fromRGB(255, 221, 92), Enum.Material.Metal)
	airlockHandle.Shape = Enum.PartType.Cylinder
	createPrompt(airlockHandle, "Inspect", "Airlock Handle", 0)
	tag(airlockHandle, Constants.Tags.SpaceStationAirlock)

	local gravityPanel = createPart(room, "SpaceStationGravityPanel", Vector3.new(5.6, 3.8, 0.34), cframeAt(origin, -width / 2 + 0.74, 5.0, -8) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(21, 30, 44), Enum.Material.Metal)
	createSurfaceText(gravityPanel, "GravityPanelText", "GRAVITY\nPLEASE SELECT\nRESPONSIBLE", Enum.NormalId.Front, Color3.fromRGB(119, 255, 203), Color3.fromRGB(21, 30, 44))
	local gravityDial = createPart(room, "SpaceStationGravityDial", Vector3.new(1.55, 1.55, 0.36), gravityPanel.CFrame * CFrame.new(0, -0.2, -0.28), Color3.fromRGB(255, 232, 92), Enum.Material.Neon)
	gravityDial.Shape = Enum.PartType.Cylinder
	createPrompt(gravityDial, "Turn", "Gravity Dial", 0)
	tag(gravityDial, Constants.Tags.SpaceStationGravityDial)

	local window = createPart(room, "SpaceObservationWindow", Vector3.new(19, 7.4, 0.24), cframeAt(origin, 0, 8.5, -depth / 2 + 0.45), Color3.fromRGB(18, 21, 36), Enum.Material.Glass)
	window.Transparency = 0.18
	window:SetAttribute("BaseTransparency", window.Transparency)
	createPrompt(window, "Look", "Observation Window", 0)
	tag(window, Constants.Tags.SpaceStationObservationWindow)
	for starIndex = 1, 18 do
		local x = -8.2 + (starIndex * 37 % 164) / 10
		local y = 5.4 + (starIndex * 29 % 74) / 10
		local star = createPart(room, "SpaceWindowStar" .. starIndex, Vector3.new(0.18, 0.18, 0.18), cframeAt(origin, x, y, -depth / 2 + 0.22), Color3.fromRGB(235, 246, 255), Enum.Material.Neon)
		star.Shape = Enum.PartType.Ball
		star.CanCollide = false
		star:SetAttribute("BaseCanCollide", false)
	end

	local comms = createPart(room, "SpaceStationCommsPanel", Vector3.new(5.2, 3.2, 0.34), cframeAt(origin, width / 2 - 0.72, 5.2, -8.6) * CFrame.Angles(0, math.rad(-90), 0), Color3.fromRGB(16, 26, 36), Enum.Material.Metal)
	createSurfaceText(comms, "CommsPanelText", "COMMS\nSEND HELP?\nSEND SNACKS.", Enum.NormalId.Front, Color3.fromRGB(255, 232, 115), Color3.fromRGB(16, 26, 36))
	createPrompt(comms, "Ping", "Comms Panel", 0)
	tag(comms, Constants.Tags.SpaceStationCommsPanel)

	local foodPrinter = createPart(room, "SpaceStationFoodPrinter", Vector3.new(5.4, 2.2, 3.1), cframeAt(origin, -13.7, 2.0, 4.4), Color3.fromRGB(198, 205, 214), Enum.Material.Metal)
	createSurfaceText(foodPrinter, "FoodPrinterText", "FOOD\nPRINTER", Enum.NormalId.Front, Color3.fromRGB(22, 34, 46), Color3.fromRGB(198, 205, 214))
	local foodTray = createPart(room, "SpaceFoodTray", Vector3.new(2.6, 0.18, 1.4), cframeAt(origin, -13.7, 3.34, 2.72), Color3.fromRGB(230, 233, 238), Enum.Material.Metal)
	foodTray:SetAttribute("FoodOutput", true)
	local drumstickMeat = createPart(room, "SpaceFoodDrumstickMeat", Vector3.new(0.82, 0.72, 0.82), cframeAt(origin, -14.15, 3.78, 2.72), Color3.fromRGB(205, 106, 50), Enum.Material.SmoothPlastic)
	drumstickMeat.Shape = Enum.PartType.Ball
	drumstickMeat:SetAttribute("FoodOutput", true)
	local drumstickBone = createPart(room, "SpaceFoodDrumstickBone", Vector3.new(1.1, 0.2, 0.2), cframeAt(origin, -13.35, 3.72, 2.72), Color3.fromRGB(245, 232, 201), Enum.Material.SmoothPlastic)
	drumstickBone:SetAttribute("FoodOutput", true)
	local foodTube = createPart(room, "SpaceFoodTube", Vector3.new(0.42, 0.42, 1.15), cframeAt(origin, -13.2, 3.63, 2.22) * CFrame.Angles(math.rad(12), math.rad(18), 0), Color3.fromRGB(119, 255, 203), Enum.Material.Metal)
	foodTube:SetAttribute("FoodOutput", true)
	createPrompt(foodPrinter, "Print", "Space Food", 0)
	tag(foodPrinter, Constants.Tags.SpaceStationFoodPrinter)

	local suitLocker = createPart(room, "SpaceSuitLocker", Vector3.new(4.4, 7.2, 1.0), cframeAt(origin, 14.5, 4.0, 4.4), Color3.fromRGB(46, 58, 78), Enum.Material.Metal)
	createSurfaceText(suitLocker, "SuitLockerText", "SUIT\nLOCKER", Enum.NormalId.Front, Color3.fromRGB(231, 247, 255), Color3.fromRGB(46, 58, 78))
	local suitHelmet = createPart(room, "SpaceSuitHelmet", Vector3.new(1.65, 1.65, 1.65), cframeAt(origin, 14.5, 6.3, 3.76), Color3.fromRGB(240, 244, 247), Enum.Material.SmoothPlastic)
	suitHelmet.Shape = Enum.PartType.Ball
	local suitTorso = createPart(room, "SpaceSuitTorso", Vector3.new(2.2, 2.8, 0.72), cframeAt(origin, 14.5, 4.35, 3.76), Color3.fromRGB(235, 239, 242), Enum.Material.SmoothPlastic)
	createPrompt(suitTorso, "Inspect", "Space Suit", 0)
	tag(suitTorso, Constants.Tags.SpaceStationSuit)

	local starMapCore = createPart(room, "SpaceStationStarMapCore", Vector3.new(5.8, 5.8, 5.8), cframeAt(origin, 0, 7.8, 6.6), Color3.fromRGB(14, 24, 48), Enum.Material.Glass)
	starMapCore.Shape = Enum.PartType.Ball
	starMapCore.Transparency = 0.44
	starMapCore.CanCollide = false
	starMapCore:SetAttribute("BaseTransparency", starMapCore.Transparency)
	starMapCore:SetAttribute("BaseCanCollide", false)
	local starMapRingA = createPart(room, "SpaceStationStarMapRingA", Vector3.new(6.8, 0.12, 6.8), starMapCore.CFrame * CFrame.Angles(math.rad(90), 0, math.rad(18)), Color3.fromRGB(119, 255, 203), Enum.Material.Neon)
	starMapRingA.Transparency = 0.28
	starMapRingA.CanCollide = false
	starMapRingA:SetAttribute("BaseTransparency", starMapRingA.Transparency)
	starMapRingA:SetAttribute("BaseCanCollide", false)
	local starMapRingB = createPart(room, "SpaceStationStarMapRingB", Vector3.new(6.2, 0.12, 6.2), starMapCore.CFrame * CFrame.Angles(math.rad(35), math.rad(90), math.rad(-10)), Color3.fromRGB(255, 232, 92), Enum.Material.Neon)
	starMapRingB.Transparency = 0.34
	starMapRingB.CanCollide = false
	starMapRingB:SetAttribute("BaseTransparency", starMapRingB.Transparency)
	starMapRingB:SetAttribute("BaseCanCollide", false)
	local starMapPanel = createPart(room, "SpaceStationStarMap", Vector3.new(7.6, 2.15, 0.34), cframeAt(origin, 0, 3.9, 7.05), Color3.fromRGB(10, 16, 32), Enum.Material.Metal)
	createSurfaceText(starMapPanel, "StarMapText", "STAR MAP\nFLOATING OBJECT\nBELOW AVERAGE PLAN", Enum.NormalId.Front, Color3.fromRGB(119, 255, 203), Color3.fromRGB(10, 16, 32))
	createPrompt(starMapPanel, "Rearrange", "Star Map Controls", 0)
	tag(starMapPanel, Constants.Tags.SpaceStationStarMap)
	for dotIndex = 1, 12 do
		local angle = dotIndex * math.pi * 2 / 12
		local radius = 1.5 + (dotIndex % 4) * 0.45
		local dot = createPart(room, "StarMapDot" .. dotIndex, Vector3.new(0.28, 0.28, 0.28), starMapCore.CFrame * CFrame.new(math.cos(angle) * radius, math.sin(dotIndex * 1.3) * 1.2, math.sin(angle) * radius), BOWLING_COSMIC_COLORS[((dotIndex - 1) % #BOWLING_COSMIC_COLORS) + 1], Enum.Material.Neon)
		dot.Shape = Enum.PartType.Ball
		dot.CanCollide = false
		dot:SetAttribute("BaseCanCollide", false)
	end

	local plantPod = createPart(room, "SpaceStationPlantPod", Vector3.new(2.2, 3.8, 2.2), cframeAt(origin, -6.5, 3.0, -4.6), Color3.fromRGB(184, 229, 255), Enum.Material.Glass)
	plantPod.Transparency = 0.32
	plantPod:SetAttribute("BaseTransparency", plantPod.Transparency)
	local plantStem = createPart(room, "SpacePlantStem", Vector3.new(0.18, 1.8, 0.18), cframeAt(origin, -6.5, 2.7, -4.6), Color3.fromRGB(71, 187, 95), Enum.Material.Grass)
	local plantLeaf = createPart(room, "SpacePlantLeaf", Vector3.new(1.2, 0.24, 0.72), cframeAt(origin, -6.2, 3.45, -4.6) * CFrame.Angles(0, 0, math.rad(18)), Color3.fromRGB(91, 220, 112), Enum.Material.Grass)
	plantStem.CanCollide = false
	plantLeaf.CanCollide = false
	plantStem:SetAttribute("BaseCanCollide", false)
	plantLeaf:SetAttribute("BaseCanCollide", false)
	createPrompt(plantPod, "Water", "Space Plant", 0)
	tag(plantPod, Constants.Tags.SpaceStationPlantPod)

	createPart(room, "SpaceMeteorButtonPedestal", Vector3.new(3.2, 2.1, 3.2), cframeAt(origin, 6.2, 1.55, -4.6), Color3.fromRGB(46, 52, 64), Enum.Material.Metal)
	local meteorButton = createPart(room, "SpaceStationMeteorButton", Vector3.new(1.7, 0.58, 1.7), cframeAt(origin, 6.2, 2.9, -4.6), Color3.fromRGB(235, 42, 51), Enum.Material.Neon)
	meteorButton.Shape = Enum.PartType.Ball
	createPrompt(meteorButton, "Press", "Meteor Request", 0)
	tag(meteorButton, Constants.Tags.SpaceStationMeteorButton)

	local podBase = createPart(room, "SpaceEscapePodBase", Vector3.new(5.4, 3.3, 3.4), cframeAt(origin, 0, 2.2, -10.5), Color3.fromRGB(180, 191, 205), Enum.Material.Metal)
	local podNose = createPart(room, "SpaceEscapePodNose", Vector3.new(3.2, 3.2, 3.2), cframeAt(origin, 0, 4.15, -10.5), Color3.fromRGB(231, 239, 244), Enum.Material.SmoothPlastic)
	podNose.Shape = Enum.PartType.Ball
	local podWindow = createPart(room, "SpaceEscapePodWindow", Vector3.new(2.2, 1.1, 0.18), cframeAt(origin, 0, 4.35, -12.25), Color3.fromRGB(96, 194, 255), Enum.Material.Glass)
	podWindow.CanCollide = false
	podWindow:SetAttribute("BaseCanCollide", false)
	createSurfaceText(podBase, "EscapePodText", "ESCAPE POD\nDO NOT TEST", Enum.NormalId.Front, Color3.fromRGB(31, 38, 52), Color3.fromRGB(180, 191, 205))
	createPrompt(podBase, "Test", "Escape Pod", 0)
	tag(podBase, Constants.Tags.SpaceStationEscapePod)

	room.PrimaryPart = returnDoor
	return {
		Model = room,
		ExitDoor = returnDoor,
		LightSwitch = controls.LightSwitch,
		ResetRoomButton = controls.ResetRoomButton,
		ReferenceBook = controls.ReferenceBook,
	}
end

local function connectSafetyFloor(safetyFloor)
	local debounceByCharacter = {}

	safetyFloor.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		if not character or debounceByCharacter[character] then
			return
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local rootPart = character:FindFirstChild("HumanoidRootPart")

		if not humanoid or not rootPart then
			return
		end

		debounceByCharacter[character] = true
		local destinationCFrame = safetyFloor:GetAttribute("DestinationCFrame") or CFrame.new(0, 5, 10)
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.CFrame = destinationCFrame
		task.delay(1, function()
			debounceByCharacter[character] = nil
		end)
	end)
end

function RoomBuilder.Build()
	clearGeneratedFolder("Room")
	clearGeneratedFolder("InteractiveObjects")

	local roomFolder = createFolder(workspace, "Room")
	local objectsFolder = createFolder(workspace, "InteractiveObjects")

	local _, recoveryFloor = makeFloor(roomFolder)
	local exitDoor = makeShell(roomFolder)
	local tvControls = makeRoomControlPanel(
		roomFolder,
		"TVRoomInsideControlPanel",
		CFrame.new(-12.15, 4.7, Constants.Room.Depth / 2 - 0.62),
		"TVRoom",
		"TV ROOM",
		{
			IncludeReset = true,
			PanelLabel = "ROOM CONTROLS",
			LightPromptObjectText = "Light Switch",
			HighlightTag = Constants.Tags.TVLightSwitch,
			UnlocksGiantDiscovery = true,
		}
	)
	local resetRoomButton = tvControls.ResetRoomButton
	local tvInsideLog = tvControls.ReferenceBook
	makeTVRoomClocks(roomFolder)
	local underfloorChamber, safetyFloor = makeUnderfloorChamber(roomFolder, recoveryFloor)
	makeSpawn(roomFolder)
	local hallway = makeHallway(roomFolder)
	local snackLab = makeSnackLabShell(roomFolder)
	local islandRoom = makeIslandRoom(roomFolder)
	local tvSecretRoom = makeTVSecretRoom(roomFolder)
	local bowlingAlley = makeBowlingAlley(roomFolder)
	local spaceStation = makeSpaceStationRoom(roomFolder)
	createNoTouchClock(
		snackLab.Model,
		"SnackLabWallClock",
		"SnackLab",
		Vector3.new(0.28, 2.3, 5.6),
		cframeAt(SNACK_LAB_ORIGIN, Constants.Room.Width / 2 - 0.57, 8.2, -2.5),
		Enum.NormalId.Left
	)

	local pedestal = makePedestal(objectsFolder)
	local lightSwitch = tvControls.LightSwitch
	local couch = makeCouch(objectsFolder)
	local lamp = makeLamp(objectsFolder)
	makeTableAndAppliance(objectsFolder)
	local squishy = makeSquishy(objectsFolder)
	local television = makeTelevision(objectsFolder)
	local snackButton = makeSnackButton(objectsFolder)
	local snackCeilingFan = makeSnackCeilingFan(objectsFolder)
	local fridge = makeSnackFridge(objectsFolder)
	local toaster = makeSnackToaster(objectsFolder)
	local sink = makeSnackSink(objectsFolder)
	local mixer = makeSnackMixer(objectsFolder)
	local snackRack = makeSnackRack(objectsFolder)
	local fruitBowl = makeFruitBowl(objectsFolder)
	local islandObjects = makeIslandObjects(objectsFolder)

	connectSafetyFloor(safetyFloor)
	ResetService.CaptureRoots(roomFolder, objectsFolder)

	return {
		Room = roomFolder,
		InteractiveObjects = objectsFolder,
		RecoveryFloor = recoveryFloor,
		UnderfloorChamber = underfloorChamber,
		ExitDoor = exitDoor,
		ResetRoomButton = resetRoomButton,
		TVInsideLog = tvInsideLog,
		Hallway = hallway,
		TVSecretRoom = tvSecretRoom,
		BowlingAlley = bowlingAlley,
		SpaceStation = spaceStation,
		Island = islandRoom,
		Pedestal = pedestal,
		LightSwitch = lightSwitch,
		Couch = couch,
		Lamp = lamp,
		Squishy = squishy,
		Television = television,
		SnackLab = snackLab,
		SnackButton = snackButton,
		SnackCeilingFan = snackCeilingFan,
		Fridge = fridge,
		Toaster = toaster,
		Sink = sink,
		Mixer = mixer,
		SnackRack = snackRack,
		FruitBowl = fruitBowl,
		IslandObjects = islandObjects,
	}
end

return RoomBuilder
