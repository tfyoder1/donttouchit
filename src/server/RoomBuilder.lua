local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local ResetService = require(script.Parent:WaitForChild("ResetService"))

local RoomBuilder = {}

local ROOM_ATTRIBUTE = "DontTouchItGenerated"

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
	spawn.CFrame = CFrame.new(destinationCFrame.Position - Vector3.new(0, 2.45, 0))
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

local function makeResetRoomButton(roomFolder)
	local resetModel = makeModel(roomFolder, "ResetRoomButton")
	local wallZ = Constants.Room.Depth / 2 - 0.6
	local panelX = -12.4

	local plate = createPart(
		resetModel,
		"ResetButtonPlate",
		Vector3.new(3.4, 2.1, 0.24),
		CFrame.new(panelX, 4.5, wallZ),
		Color3.fromRGB(42, 47, 56),
		Enum.Material.Metal
	)

	local button = createPart(
		resetModel,
		"ResetButton",
		Vector3.new(1.45, 0.38, 1.45),
		CFrame.new(panelX, 4.5, wallZ - 0.24) * CFrame.Angles(math.rad(90), 0, 0),
		Color3.fromRGB(255, 221, 84),
		Enum.Material.Neon
	)
	button.Shape = Enum.PartType.Cylinder

	createSurfaceText(plate, "ResetButtonText", "RESET\nROOM", Enum.NormalId.Front, Color3.fromRGB(255, 242, 181), Color3.fromRGB(42, 47, 56))
	createPrompt(button, "Reset", "Room Reset", 0.2)
	tag(button, Constants.Tags.ResetRoomButton)

	resetModel.PrimaryPart = plate
	return resetModel
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
		CFrame.new(0, 2.75, 2.9),
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
		Vector3.new(4.4, 0.25, 4.4),
		CFrame.new(0, 3.42, 0),
		Color3.fromRGB(32, 35, 40),
		Enum.Material.Metal
	)

	local buttonBase = createPart(
		pedestal,
		"BigRedButtonBase",
		Vector3.new(3.55, 0.45, 3.55),
		CFrame.new(0, 3.72, 0),
		Color3.fromRGB(117, 14, 22),
		Enum.Material.Metal,
		"Part"
	)
	buttonBase.Shape = Enum.PartType.Cylinder

	local button = createPart(
		pedestal,
		"BigRedButton",
		Vector3.new(3.15, 1.15, 3.15),
		CFrame.new(0, 4.15, 0),
		Color3.fromRGB(231, 30, 42),
		Enum.Material.Neon,
		"Part"
	)
	button.Shape = Enum.PartType.Ball
	button:SetAttribute("PressedCFrame", CFrame.new(0, 3.88, 0))

	local shine = createPart(
		pedestal,
		"BigRedButtonShine",
		Vector3.new(0.92, 0.08, 0.42),
		CFrame.new(-0.68, 4.74, -0.58) * CFrame.Angles(0, 0, math.rad(-18)),
		Color3.fromRGB(255, 176, 182),
		Enum.Material.Neon,
		"Part"
	)
	shine.Shape = Enum.PartType.Ball
	shine.CanCollide = false
	shine.Transparency = 0.12
	mark(shine)

	createPrompt(button, "Press", "Absolutely Do Not Touch", 0.15)
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
		Vector3.new(1.15, 1.85, 0.18),
		baseCFrame,
		Color3.fromRGB(238, 238, 226),
		Enum.Material.SmoothPlastic
	)
	local leverNeutralCFrame = baseCFrame * CFrame.new(0, 0.05, -0.2)
	local leverOnCFrame = leverNeutralCFrame * CFrame.Angles(math.rad(-18), 0, 0)
	local leverOffCFrame = leverNeutralCFrame * CFrame.Angles(math.rad(18), 0, 0)
	local lever = createPart(
		switch,
		"SwitchLever",
		Vector3.new(0.26, 0.88, 0.22),
		leverOnCFrame,
		Color3.fromRGB(244, 244, 238),
		Enum.Material.Metal
	)
	lever:SetAttribute("SwitchOnCFrame", leverOnCFrame)
	lever:SetAttribute("SwitchOffCFrame", leverOffCFrame)

	plate:SetAttribute("IsOn", true)
	createSurfaceText(plate, "SwitchText", options.Label or "LIGHT", Enum.NormalId.Front, Color3.fromRGB(34, 34, 32), Color3.fromRGB(238, 238, 226))
	createPrompt(plate, "Flip", options.PromptObjectText or "Light Switch", 0)
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
	createPart(chamber, "UnderfloorCeiling", Vector3.new(width, 0.45, depth), CFrame.new(0, y + 8.2, 0), Color3.fromRGB(40, 47, 58), Enum.Material.Concrete)

	local sign = createPart(chamber, "UnderfloorSign", Vector3.new(12, 2.2, 0.3), CFrame.new(0, y + 4.7, -depth / 2 + 0.55), Color3.fromRGB(106, 255, 196), Enum.Material.Neon)
	createSurfaceText(sign, "UnderfloorSignText", "FLOOR LOST & FOUND", Enum.NormalId.Front, Color3.fromRGB(12, 26, 24), Color3.fromRGB(106, 255, 196))

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

	local safetyFloor = createPart(chamber, "UnderfloorSafetyNet", Vector3.new(width + 10, 1, depth + 10), CFrame.new(0, y - 14, 0), Color3.fromRGB(61, 217, 132), Enum.Material.Neon)
	safetyFloor.Transparency = 0.6
	safetyFloor:SetAttribute("BaseTransparency", safetyFloor.Transparency)
	safetyFloor:SetAttribute("DestinationCFrame", CFrame.new(0, y + 3, 5.5))

	return chamber, safetyFloor
end

local HALLWAY_SPAWN_CFRAME = CFrame.new(0, 3, 27)
local TV_ROOM_RETURN_CFRAME = CFrame.new(0, 3, 10)
local TV_SECRET_ROOM_ORIGIN = Vector3.new(-14, 0, -38)
local TV_SECRET_ROOM_ENTRY_CFRAME = CFrame.new(-14, 3, -31.5)
local TV_SECRET_ROOM_RETURN_CFRAME = CFrame.new(-14, 3, -10.5)
local BOWLING_ALLEY_ORIGIN = Vector3.new(-14, 0, -100)
local BOWLING_ALLEY_SPAWN_CFRAME = CFrame.new(-14, 3, -56)
local BOWLING_ALLEY_RETURN_CFRAME = CFrame.new(-14, 3, -42)
local BOWLING_MAINTENANCE_CFRAME = CFrame.new(-14, 3, -143)
local SNACK_LAB_ORIGIN = Vector3.new(48, 0, 44)
local SNACK_LAB_SPAWN_CFRAME = cframeAt(SNACK_LAB_ORIGIN, -11, 3, 10)
local ISLAND_ORIGIN = Vector3.new(0, 0, 150)
local ISLAND_SPAWN_CFRAME = Constants.GetRoomSpawnCFrame("Island")
local ISLAND_RETURN_CFRAME = CFrame.new(0, 3, 113)

local function makeSnackResetRoomButton(parent)
	local resetModel = makeModel(parent, "SnackResetRoomButton")
	local width = Constants.Room.Width
	local origin = SNACK_LAB_ORIGIN
	local wallX = -width / 2 + 0.58
	local panelZ = 3.7

	local plate = createPart(
		resetModel,
		"SnackResetButtonPlate",
		Vector3.new(0.24, 2.1, 3.4),
		cframeAt(origin, wallX, 4.45, panelZ),
		Color3.fromRGB(42, 47, 56),
		Enum.Material.Metal
	)

	local button = createPart(
		resetModel,
		"SnackResetButton",
		Vector3.new(1.45, 0.38, 1.45),
		cframeAt(origin, wallX + 0.28, 4.45, panelZ) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(255, 221, 84),
		Enum.Material.Neon
	)
	button.Shape = Enum.PartType.Cylinder

	createSurfaceText(plate, "SnackResetButtonText", "RESET\nROOM", Enum.NormalId.Right, Color3.fromRGB(255, 242, 181), Color3.fromRGB(42, 47, 56))
	local prompt = createPrompt(button, "Reset", "Room Reset", 0.2)
	prompt.MaxActivationDistance = 12
	tag(button, Constants.Tags.ResetRoomButton)

	resetModel.PrimaryPart = plate
	return resetModel
end

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

local function makeReferenceBook(parent, name, cframe, roomId, title)
	local log = makeModel(parent, name)
	local base = createPart(log, "DigitalLogBase", Vector3.new(4.2, 0.24, 2.5), cframe * CFrame.new(0, 0.58, 0.62), Color3.fromRGB(31, 35, 42), Enum.Material.Metal)
	local stem = createPart(log, "DigitalLogStem", Vector3.new(0.42, 2.1, 0.42), cframe * CFrame.new(0, 1.52, 0.62), Color3.fromRGB(45, 50, 58), Enum.Material.Metal)
	local back = createPart(log, "DigitalClipboardBack", Vector3.new(4.1, 0.28, 2.9), cframe * CFrame.new(0, 2.7, 0) * CFrame.Angles(math.rad(-10), 0, 0), Color3.fromRGB(34, 39, 47), Enum.Material.Metal)
	local screen = createPart(log, "DigitalClipboardScreen", Vector3.new(3.55, 0.12, 2.2), cframe * CFrame.new(0, 2.82, -0.04) * CFrame.Angles(math.rad(-10), 0, 0), Color3.fromRGB(4, 10, 8), Enum.Material.Neon)
	local clip = createPart(log, "DigitalClipboardClip", Vector3.new(1.55, 0.16, 0.24), cframe * CFrame.new(0, 3.26, 1.08) * CFrame.Angles(math.rad(-10), 0, 0), Color3.fromRGB(118, 130, 144), Enum.Material.Metal)
	clip.CanCollide = false
	clip:SetAttribute("BaseCanCollide", false)

	screen:SetAttribute("RoomId", roomId)
	screen:SetAttribute("FixtureType", "DigitalRoomLog")
	createSurfaceText(screen, "DigitalLogText", title .. "\nROOM LOG\n> OPEN", Enum.NormalId.Top, Color3.fromRGB(86, 255, 150), Color3.fromRGB(4, 10, 8))
	createPrompt(screen, "Open", title .. " Log", 0)
	tag(screen, Constants.Tags.ReferenceBook)

	log.PrimaryPart = back
	return log
end

local function makeWallResetRoomButton(parent, name, baseCFrame, face, promptObjectText)
	local resetModel = makeModel(parent, name)

	local plate = createPart(
		resetModel,
		"ResetButtonPlate",
		Vector3.new(3.4, 2.1, 0.24),
		baseCFrame,
		Color3.fromRGB(42, 47, 56),
		Enum.Material.Metal
	)

	local button = createPart(
		resetModel,
		"ResetButton",
		Vector3.new(1.45, 0.38, 1.45),
		baseCFrame * CFrame.new(0, 0, -0.24) * CFrame.Angles(math.rad(90), 0, 0),
		Color3.fromRGB(255, 221, 84),
		Enum.Material.Neon
	)
	button.Shape = Enum.PartType.Cylinder

	createSurfaceText(plate, "ResetButtonText", "RESET\nROOM", face or Enum.NormalId.Front, Color3.fromRGB(255, 242, 181), Color3.fromRGB(42, 47, 56))
	local prompt = createPrompt(button, "Reset", promptObjectText or "Room Reset", 0.2)
	prompt.MaxActivationDistance = 12
	tag(button, Constants.Tags.ResetRoomButton)

	resetModel.PrimaryPart = plate
	return resetModel
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
	local oceanSign = createPart(hallway, "IslandApproachSign", Vector3.new(7.2, 1.9, 0.3), CFrame.new(0, 6.4, 88), Color3.fromRGB(112, 222, 255), Enum.Material.SmoothPlastic)
	createSurfaceText(oceanSign, "IslandApproachSignText", "LONG HALLWAY\nTO A SHORT VACATION", Enum.NormalId.Back, Color3.fromRGB(18, 42, 54), Color3.fromRGB(112, 222, 255))
	createSurfaceText(oceanSign, "IslandApproachReturnText", "THIS WAY\nTO PARADISE", Enum.NormalId.Front, Color3.fromRGB(18, 42, 54), Color3.fromRGB(112, 222, 255))
	createSpawnLocation(hallway, "HallwaySpawn", "Hallway", Constants.Hallway.SpawnCFrame, Color3.fromRGB(96, 194, 134), false)
	makeReferenceBook(hallway, "TVRoomReferenceBook", CFrame.new(-3.5, 0, 30), "TVRoom", "TV ROOM")
	makeReferenceBook(hallway, "SnackLabReferenceBook", CFrame.new(3.5, 0, 38), "SnackLab", "SNACK LAB")
	makeReferenceBook(hallway, "IslandReferenceBook", CFrame.new(-2.8, 0, 107), "Island", "ISLAND")
	makeLightSwitch(
		hallway,
		"TVHallLightSwitch",
		CFrame.new(-5.88, 4.55, 25.2) * CFrame.Angles(0, math.rad(-90), 0),
		{
			PromptObjectText = "Hall Light Switch",
		}
	)
	makeLightSwitch(
		hallway,
		"SnackHallLightSwitch",
		CFrame.new(5.88, 4.55, 39.4) * CFrame.Angles(0, math.rad(90), 0),
		{
			PromptObjectText = "Snack Door Light Switch",
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
	makeLightSwitch(
		hallway,
		"IslandHallLightSwitch",
		CFrame.new(4.0, 4.55, 120.38),
		{
			PromptObjectText = "Island Door Light Switch",
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

	local resetRoomButton = makeSnackResetRoomButton(room)
	local lightSwitch = makeLightSwitch(
		room,
		"SnackLabLightSwitch",
		cframeAt(origin, -width / 2 + 0.58, 4.55, 4.6) * CFrame.Angles(0, math.rad(-90), 0),
		{
			RoomId = "SnackLab",
			PromptObjectText = "Snack Lab Light Switch",
		}
	)
	local referenceBook = makeReferenceBook(room, "SnackLabInsideLog", cframeAt(origin, -14.2, 0, 13.1) * CFrame.Angles(0, math.rad(90), 0), "SnackLab", "SNACK LAB")
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
		cframeAt(origin, 0, 2.05, 2.42),
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

	local body = createPart(fridge, "FridgeBody", Vector3.new(6, 9, 4), cframeAt(origin, -13, 4.9, -9), Color3.fromRGB(213, 225, 228), Enum.Material.Metal)
	createPart(fridge, "FridgeInterior", Vector3.new(5.2, 7.3, 0.24), cframeAt(origin, -13, 4.9, -7.18), Color3.fromRGB(55, 78, 92), Enum.Material.SmoothPlastic)
	createPart(fridge, "FridgeShelfTop", Vector3.new(5.1, 0.18, 2.7), cframeAt(origin, -13, 6.2, -8.55), Color3.fromRGB(185, 244, 255), Enum.Material.Glass)
	createPart(fridge, "FridgeShelfBottom", Vector3.new(5.1, 0.18, 2.7), cframeAt(origin, -13, 3.9, -8.55), Color3.fromRGB(185, 244, 255), Enum.Material.Glass)
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
	local mixerFrame = CFrame.new(origin + Vector3.new(mixerX, 0, mixerZ))

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

local function makeLibraryFurnishings(room)
	local origin = TV_SECRET_ROOM_ORIGIN

	makeReferenceBook(room, "LibraryReferenceBook", cframeAt(origin, -5.8, 0, 3.9), "Library", "LIBRARY")
	createNoTouchClock(
		room,
		"LibraryClock",
		"Library",
		Vector3.new(5.4, 1.9, 0.24),
		CFrame.new(origin + Vector3.new(5.35, 8.3, 7.39), origin + Vector3.new(0, 5, 0)),
		Enum.NormalId.Front
	)

	for shelfIndex, shelf in ipairs({
		{ Name = "LibraryLeftShelf", X = -8.25, Z = -0.8, Yaw = 90, Width = 13.5 },
		{ Name = "LibraryRightShelf", X = 8.25, Z = -0.8, Yaw = -90, Width = 13.5 },
		{ Name = "LibraryBackShelf", X = 0, Z = -7.25, Yaw = 0, Width = 15.6 },
	}) do
		local shelfModel = makeModel(room, shelf.Name)
		local base = CFrame.new(origin + Vector3.new(shelf.X, 3.7, shelf.Z)) * CFrame.Angles(0, math.rad(shelf.Yaw), 0)
		local back = createPart(shelfModel, "ShelfBack", Vector3.new(shelf.Width, 7.4, 0.34), base, Color3.fromRGB(72, 48, 36), Enum.Material.Wood)
		if shelfIndex == 1 then
			createPrompt(back, "Inspect", "Whispering Shelf", 0)
			tag(back, Constants.Tags.LibraryShelf)
		end

		for row = 1, 4 do
			createPart(shelfModel, "ShelfBoard" .. row, Vector3.new(shelf.Width + 0.2, 0.28, 0.72), base * CFrame.new(0, -3.1 + row * 1.55, -0.22), Color3.fromRGB(92, 61, 43), Enum.Material.Wood)
			for bookIndex = 1, 8 do
				local bookX = -shelf.Width / 2 + 0.7 + (bookIndex - 1) * (shelf.Width - 1.4) / 7
				local color = Color3.fromRGB(90 + (bookIndex * 17) % 120, 52 + (row * 31) % 130, 70 + (shelfIndex * 43) % 120)
				createPart(
					shelfModel,
					("Book_%d_%d"):format(row, bookIndex),
					Vector3.new(0.42, 1.05 + (bookIndex % 3) * 0.14, 0.38),
					base * CFrame.new(bookX, -3.05 + row * 1.55, -0.58),
					color,
					Enum.Material.SmoothPlastic
				)
			end
		end
	end

	local tableTop = createPart(room, "LibraryReadingTable", Vector3.new(7.8, 0.5, 3.4), cframeAt(origin, 0, 2.15, 0.5), Color3.fromRGB(94, 62, 42), Enum.Material.Wood)
	createPart(room, "LibraryTableLegA", Vector3.new(0.45, 2.2, 0.45), cframeAt(origin, -3.2, 1.1, -0.6), Color3.fromRGB(75, 49, 35), Enum.Material.Wood)
	createPart(room, "LibraryTableLegB", Vector3.new(0.45, 2.2, 0.45), cframeAt(origin, 3.2, 1.1, -0.6), Color3.fromRGB(75, 49, 35), Enum.Material.Wood)
	createPart(room, "LibraryTableLegC", Vector3.new(0.45, 2.2, 0.45), cframeAt(origin, -3.2, 1.1, 1.6), Color3.fromRGB(75, 49, 35), Enum.Material.Wood)
	createPart(room, "LibraryTableLegD", Vector3.new(0.45, 2.2, 0.45), cframeAt(origin, 3.2, 1.1, 1.6), Color3.fromRGB(75, 49, 35), Enum.Material.Wood)

	local book = createPart(room, "ForbiddenLibraryBook", Vector3.new(2.3, 0.34, 1.55), cframeAt(origin, -1.8, 2.6, 0.35) * CFrame.Angles(0, math.rad(-8), 0), Color3.fromRGB(114, 28, 61), Enum.Material.SmoothPlastic)
	createSurfaceText(book, "ForbiddenBookText", "DO NOT\nREAD", Enum.NormalId.Top, Color3.fromRGB(255, 235, 149), Color3.fromRGB(114, 28, 61))
	createPrompt(book, "Read", "Book That Sighed", 0)
	tag(book, Constants.Tags.LibraryBook)

	local lamp = createPart(room, "LibraryReadingLamp", Vector3.new(0.75, 1.35, 0.75), cframeAt(origin, 2.5, 3.0, 0.4), Color3.fromRGB(255, 214, 102), Enum.Material.Metal)
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

	local globe = createPart(room, "LibraryWrongGlobe", Vector3.new(1.75, 1.75, 1.75), cframeAt(origin, 1.5, 3.25, 1.2), Color3.fromRGB(91, 156, 197), Enum.Material.SmoothPlastic)
	globe.Shape = Enum.PartType.Ball
	createPrompt(globe, "Spin", "Wrong Globe", 0)
	tag(globe, Constants.Tags.LibraryGlobe)

	local catalog = createPart(room, "LibraryCardCatalog", Vector3.new(3.4, 2.2, 1.5), cframeAt(origin, 5.9, 1.5, 3.2), Color3.fromRGB(115, 78, 51), Enum.Material.Wood)
	createSurfaceText(catalog, "CatalogText", "CATALOG", Enum.NormalId.Front, Color3.fromRGB(255, 235, 149), Color3.fromRGB(115, 78, 51))
	createPrompt(catalog, "Open", "Card Catalog", 0)
	tag(catalog, Constants.Tags.LibraryCatalog)

	local ladder = createPart(room, "LibraryRollingLadder", Vector3.new(1.15, 7.6, 1.15), cframeAt(origin, -7.35, 4.0, -3.6) * CFrame.Angles(0, 0, math.rad(-10)), Color3.fromRGB(181, 121, 67), Enum.Material.Wood, "TrussPart")
	createPrompt(ladder, "Roll", "Rolling Ladder", 0)
	tag(ladder, Constants.Tags.LibraryLadder)

	createPart(room, "LibraryLoftPlatform", Vector3.new(8.6, 0.45, 3.2), cframeAt(origin, -4.7, 8.05, -5.5), Color3.fromRGB(84, 57, 41), Enum.Material.Wood)
	createPart(room, "LibraryLoftRail", Vector3.new(8.6, 1.1, 0.22), cframeAt(origin, -4.7, 8.9, -3.95), Color3.fromRGB(118, 82, 55), Enum.Material.Wood)
	local loftDoor = createPart(room, "LibraryLoftDoor", Vector3.new(3.2, 4.1, 0.28), cframeAt(origin, -4.7, 10.2, -7.42), Color3.fromRGB(68, 88, 118), Enum.Material.Wood)
	createSurfaceText(loftDoor, "LoftDoorText", "LOFT", Enum.NormalId.Front, Color3.fromRGB(235, 245, 255), Color3.fromRGB(68, 88, 118))
	createPrompt(loftDoor, "Open", "Loft Door", 0)
	tag(loftDoor, Constants.Tags.LibraryLoftDoor)

	local key = createPart(room, "BowlingKeyTopShelf", Vector3.new(0.34, 0.34, 1.45), cframeAt(origin, -6.6, 9.42, -6.75) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 219, 92), Enum.Material.Metal)
	key.Shape = Enum.PartType.Cylinder
	local keyHead = createPart(room, "BowlingKeyHead", Vector3.new(0.82, 0.18, 0.82), cframeAt(origin, -7.45, 9.42, -6.75), Color3.fromRGB(255, 219, 92), Enum.Material.Metal)
	keyHead.Shape = Enum.PartType.Cylinder
	createPrompt(key, "Take", "Bowling Key", 0)
	tag(key, Constants.Tags.LibraryTopShelfKey)

	local bookcaseDoor = createPart(room, "LibraryBookcaseDoor", Vector3.new(5.6, 7.6, 0.42), cframeAt(origin, 3.1, 4.0, -7.52), Color3.fromRGB(76, 48, 34), Enum.Material.Wood)
	bookcaseDoor:SetAttribute("DestinationCFrame", BOWLING_ALLEY_SPAWN_CFRAME)
	bookcaseDoor:SetAttribute("SecretClosedCFrame", bookcaseDoor.CFrame)
	createSurfaceText(bookcaseDoor, "BookcaseDoorText", "REFERENCE\nONLY", Enum.NormalId.Front, Color3.fromRGB(255, 235, 149), Color3.fromRGB(76, 48, 34))
	createPrompt(bookcaseDoor, "Inspect", "Reference Bookcase", 0)
	tag(bookcaseDoor, Constants.Tags.LibraryBookcaseDoor)
end

local function makeBowlingPins(parent, laneIndex, laneX, z)
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
		local pin = createPart(
			parent,
			("Lane%dPin%d"):format(laneIndex, index),
			Vector3.new(0.62, 1.85, 0.62),
			CFrame.new(laneX + offset[1], 1.42, z + offset[2]),
			Color3.fromRGB(245, 244, 232),
			Enum.Material.SmoothPlastic
		)
		pin.Shape = Enum.PartType.Cylinder
		pin.Anchored = false
		pin:SetAttribute("LaneIndex", laneIndex)
		pin:SetAttribute("BaseAnchored", false)
		mark(pin)
		tag(pin, Constants.Tags.BowlingPin)

		local stripe = createPart(
			parent,
			("Lane%dPin%dStripe"):format(laneIndex, index),
			Vector3.new(0.66, 0.2, 0.66),
			CFrame.new(laneX + offset[1], 1.95, z + offset[2]),
			Color3.fromRGB(220, 52, 67),
			Enum.Material.SmoothPlastic
		)
		stripe.Shape = Enum.PartType.Cylinder
		stripe.Anchored = false
		stripe.CanCollide = false
		stripe.Massless = true
		stripe:SetAttribute("LaneIndex", laneIndex)
		mark(stripe)

		local weld = Instance.new("WeldConstraint")
		weld.Name = "PinStripeWeld"
		weld.Part0 = pin
		weld.Part1 = stripe
		weld.Parent = stripe
	end
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
	makeReferenceBook(room, "BowlingReferenceBook", cframeAt(origin, -16, 0, 42), "BowlingAlley", "BOWLING")
	makeLightSwitch(
		room,
		"BowlingLightSwitch",
		CFrame.new(origin + Vector3.new(8.2, 4.45, 48.85), origin + Vector3.new(0, 4.45, 0)),
		{
			RoomId = "BowlingAlley",
			PromptObjectText = "Bowling Light Switch",
		}
	)
	makeWallResetRoomButton(
		room,
		"BowlingResetRoomButton",
		CFrame.new(origin + Vector3.new(16.2, 4.45, 48.85), origin + Vector3.new(0, 4.45, 0)),
		Enum.NormalId.Front,
		"Room Reset"
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

	local shoeRack = createPart(room, "BowlingShoeRack", Vector3.new(5.8, 2.8, 1.5), cframeAt(origin, 14.5, 1.9, 42), Color3.fromRGB(89, 56, 48), Enum.Material.Wood)
	createSurfaceText(shoeRack, "ShoeRackText", "SHOES\nOPTIONAL?", Enum.NormalId.Front, Color3.fromRGB(255, 235, 149), Color3.fromRGB(89, 56, 48))
	createPrompt(shoeRack, "Inspect", "Shoe Rack", 0)
	tag(shoeRack, Constants.Tags.BowlingShoeRack)

	local scoreboard = createPart(room, "BowlingScoreboard", Vector3.new(21, 4.2, 0.35), cframeAt(origin, 0, 11.5, 34), Color3.fromRGB(18, 24, 36), Enum.Material.Neon)
	createSurfaceText(scoreboard, "ScoreboardText", "LANE 1   LANE 2   LANE 3\nYOU: ?   ROOM: WINNING", Enum.NormalId.Front, Color3.fromRGB(119, 255, 203), Color3.fromRGB(18, 24, 36))
	createPrompt(scoreboard, "Read", "Scoreboard", 0)
	tag(scoreboard, Constants.Tags.BowlingScoreboard)

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

	local laneXs = { -12, 0, 12 }
	for laneIndex, laneX in ipairs(laneXs) do
		local lane = createPart(room, "Lane" .. laneIndex, Vector3.new(8.2, 0.34, 74), CFrame.new(laneX, 0.72, -91), Color3.fromRGB(197, 151, 87), Enum.Material.WoodPlanks)
		lane:SetAttribute("CosmicSurface", true)
		createPart(room, "Lane" .. laneIndex .. "LeftGutter", Vector3.new(1, 0.28, 74), CFrame.new(laneX - 4.7, 0.86, -91), Color3.fromRGB(20, 22, 28), Enum.Material.Metal)
		local gutter = createPart(room, "Lane" .. laneIndex .. "RightGutter", Vector3.new(1, 0.28, 74), CFrame.new(laneX + 4.7, 0.86, -91), Color3.fromRGB(20, 22, 28), Enum.Material.Metal)
		createPrompt(gutter, "Inspect", "Gutter", 0)
		tag(gutter, Constants.Tags.BowlingGutter)

		local button = createPart(room, "Lane" .. laneIndex .. "BowlButton", Vector3.new(2.2, 0.55, 2.2), CFrame.new(laneX, 1.45, -54.5), Color3.fromRGB(255, 88, 128), Enum.Material.Neon)
		button.Shape = Enum.PartType.Ball
		button:SetAttribute("LaneIndex", laneIndex)
		button:SetAttribute("LaneX", laneX)
		createPrompt(button, "Bowl", "Lane " .. laneIndex, 0)
		tag(button, Constants.Tags.BowlingLaneButton)

		local ballReturn = createPart(room, "Lane" .. laneIndex .. "BallReturn", Vector3.new(3.8, 1.6, 2.8), CFrame.new(laneX, 1.35, -49.2), Color3.fromRGB(58, 63, 75), Enum.Material.Metal)
		ballReturn:SetAttribute("LaneIndex", laneIndex)
		createSurfaceText(ballReturn, "BallReturnText", "BALL\nRETURN", Enum.NormalId.Front, Color3.fromRGB(255, 235, 149), Color3.fromRGB(58, 63, 75))
		createPrompt(ballReturn, "Press", "Ball Return", 0)
		tag(ballReturn, Constants.Tags.BowlingBallReturn)

		makeBowlingPins(room, laneIndex, laneX, -126)
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

	room.PrimaryPart = scoreboard
	return {
		Model = room,
		ExitDoor = exitDoor,
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
	createPart(room, "SecretRoomFloor", Vector3.new(18, 1, 16), cframeAt(origin, 0, 0, 0), Color3.fromRGB(74, 69, 91), Enum.Material.Concrete)
	createPart(room, "SecretRoomBackWall", Vector3.new(18, 12, 1), cframeAt(origin, 0, 6, -8), Color3.fromRGB(42, 44, 55), Enum.Material.SmoothPlastic)
	createPart(room, "SecretRoomFrontWall", Vector3.new(18, 12, 1), cframeAt(origin, 0, 6, 8), Color3.fromRGB(42, 44, 55), Enum.Material.SmoothPlastic)
	createPart(room, "SecretRoomLeftWall", Vector3.new(1, 12, 16), cframeAt(origin, -9, 6, 0), Color3.fromRGB(50, 48, 63), Enum.Material.SmoothPlastic)
	createPart(room, "SecretRoomRightWall", Vector3.new(1, 12, 16), cframeAt(origin, 9, 6, 0), Color3.fromRGB(50, 48, 63), Enum.Material.SmoothPlastic)
	createPart(room, "SecretRoomCeiling", Vector3.new(18, 1, 16), cframeAt(origin, 0, 12, 0), Color3.fromRGB(34, 36, 48), Enum.Material.Concrete)

	local sign = createPart(room, "SecretRoomSign", Vector3.new(12.5, 2.3, 0.28), cframeAt(origin, 0, 7.8, -7.35), Color3.fromRGB(255, 226, 102), Enum.Material.SmoothPlastic)
	createSurfaceText(sign, "SecretRoomSignText", "THE LIBRARY\nPLEASE TOUCH QUIETLY", Enum.NormalId.Front, Color3.fromRGB(36, 27, 42), Color3.fromRGB(255, 226, 102))

	local keyhole = createPart(room, "SecretRoomKeyhole", Vector3.new(2.1, 2.1, 0.2), cframeAt(origin, 0, 4.5, -7.24), Color3.fromRGB(161, 112, 255), Enum.Material.Neon)
	keyhole.Shape = Enum.PartType.Ball

	local exitDoor = createPart(room, "SecretRoomExitDoor", Vector3.new(5.2, 7.1, 0.35), cframeAt(origin, 0, 4.25, 7.45), Color3.fromRGB(63, 84, 105), Enum.Material.Wood)
	exitDoor:SetAttribute("DestinationCFrame", TV_SECRET_ROOM_RETURN_CFRAME)
	exitDoor:SetAttribute("DestinationName", "the TV Room")
	createSurfaceText(exitDoor, "SecretRoomExitText", "BACK TO\nTV ROOM", Enum.NormalId.Back, Color3.fromRGB(228, 247, 255), Color3.fromRGB(43, 57, 72))
	createPrompt(exitDoor, "Exit", "TV Room", 0)
	tag(exitDoor, Constants.Tags.SecretRoomExit)

	local libraryLightSwitch = makeLightSwitch(
		room,
		"LibraryLightSwitch",
		CFrame.new(origin + Vector3.new(-6.35, 4.45, 7.43), origin + Vector3.new(0, 4.45, 0)),
		{
			RoomId = "Library",
			PromptObjectText = "Library Light Switch",
		}
	)
	local libraryResetRoomButton = makeWallResetRoomButton(
		room,
		"LibraryResetRoomButton",
		CFrame.new(origin + Vector3.new(6.35, 4.45, 7.43), origin + Vector3.new(0, 4.45, 0)),
		Enum.NormalId.Front,
		"Room Reset"
	)

	makeLibraryFurnishings(room)
	room.PrimaryPart = keyhole
	return {
		Door = secretDoor,
		Room = room,
		ExitDoor = exitDoor,
		LightSwitch = libraryLightSwitch,
		ResetRoomButton = libraryResetRoomButton,
	}
end

local function makePalmTree(parent, name, x, z, leanDegrees)
	local tree = makeModel(parent, name)
	local trunkHeight = 7.2
	local trunkDiameter = 0.8
	local baseCFrame = cframeAt(ISLAND_ORIGIN, x, 1.02, z) * CFrame.Angles(0, 0, math.rad(leanDegrees or 0))
	local trunk = createPart(tree, "PalmTrunk", Vector3.new(trunkDiameter, trunkHeight, trunkDiameter), baseCFrame * CFrame.new(0, trunkHeight / 2, 0), Color3.fromRGB(119, 76, 42), Enum.Material.Wood)

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

	tree.PrimaryPart = trunk
	return tree
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

	makePalmTree(room, "BentPalm", -10, 8, -9)
	makePalmTree(room, "SmallPalm", 10, 1, 6)

	for _, data in ipairs({
		{ Name = "NorthHorizon", Size = Vector3.new(150, 28, 0.4), CFrame = cframeAt(origin, 0, 13, 87), Color = Color3.fromRGB(133, 215, 255) },
		{ Name = "SouthHorizon", Size = Vector3.new(150, 28, 0.4), CFrame = cframeAt(origin, 0, 13, -28), Color = Color3.fromRGB(118, 197, 238) },
		{ Name = "WestHorizon", Size = Vector3.new(0.4, 28, 112), CFrame = cframeAt(origin, -75, 13, 31), Color = Color3.fromRGB(109, 192, 238) },
		{ Name = "EastHorizon", Size = Vector3.new(0.4, 28, 112), CFrame = cframeAt(origin, 75, 13, 31), Color = Color3.fromRGB(109, 192, 238) },
	}) do
		local horizon = createPart(room, data.Name, data.Size, data.CFrame, data.Color, Enum.Material.SmoothPlastic)
		horizon.Transparency = 0.22
		horizon.CanCollide = false
		horizon:SetAttribute("BaseTransparency", horizon.Transparency)
		horizon:SetAttribute("BaseCanCollide", false)
	end

	local sun = createPart(room, "IslandSun", Vector3.new(7, 7, 0.35), cframeAt(origin, -30, 17, 63.5), Color3.fromRGB(255, 222, 88), Enum.Material.Neon)
	sun.Shape = Enum.PartType.Ball
	sun.CanCollide = false
	sun:SetAttribute("BaseCanCollide", false)

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
	createSurfaceText(exitGate, "IslandExitText", "HALLWAY", Enum.NormalId.Front, Color3.fromRGB(231, 247, 255), Color3.fromRGB(35, 55, 70))
	createPrompt(exitGate, "Leave", "Hallway", 0)
	tag(exitGate, Constants.Tags.IslandExit)

	local islandSwitchCFrame = CFrame.new(origin + Vector3.new(-5.7, 4.55, -22.85), origin + Vector3.new(0, 4.55, 4))
	local lightSwitch = makeLightSwitch(
		room,
		"IslandLightSwitch",
		islandSwitchCFrame,
		{
			RoomId = "Island",
			PromptObjectText = "Island Light Switch",
		}
	)
	local resetRoomButton = makeWallResetRoomButton(
		room,
		"IslandResetRoomButton",
		CFrame.new(origin + Vector3.new(5.7, 4.5, -22.85), origin + Vector3.new(0, 4.5, 4)),
		Enum.NormalId.Front,
		"Room Reset"
	)
	local referenceBook = makeReferenceBook(room, "IslandInsideLog", cframeAt(origin, -8.6, 0, -18.4) * CFrame.Angles(0, math.rad(24), 0), "Island", "ISLAND")

	makeIslandWarningSign(room, "IslandSharkWarningSign", "BEWARE\nOF SHARKS", -10.5, -7.5, -1, 2, Constants.Tags.IslandSharkSign)
	makeIslandWarningSign(room, "IslandJellyfishWarningSign", "BEWARE\nOF JELLYFISH", 12.5, 12.5, 1, 5, Constants.Tags.IslandJellyfishSign)

	for _, data in ipairs({
		{ Name = "IslandBoundaryLeft", Size = Vector3.new(1, 16, 68), CFrame = cframeAt(origin, -31, 8, 5) },
		{ Name = "IslandBoundaryRight", Size = Vector3.new(1, 16, 68), CFrame = cframeAt(origin, 31, 8, 5) },
		{ Name = "IslandBoundaryBack", Size = Vector3.new(62, 16, 1), CFrame = cframeAt(origin, 0, 8, 34) },
		{ Name = "IslandBoundaryFront", Size = Vector3.new(62, 16, 1), CFrame = cframeAt(origin, 0, 8, -25) },
	}) do
		local boundary = createPart(room, data.Name, data.Size, data.CFrame, Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
		boundary.Transparency = 1
		boundary:SetAttribute("BaseTransparency", 1)
	end

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

	local shovel = makeModel(objects, "IslandShovel")
	local handle = createPart(shovel, "ShovelHandle", Vector3.new(0.28, 4.6, 0.28), cframeAt(origin, -8, 2.4, 1.5) * CFrame.Angles(0, 0, math.rad(-32)), Color3.fromRGB(113, 71, 39), Enum.Material.Wood)
	handle.Shape = Enum.PartType.Cylinder
	createPart(shovel, "ShovelGrip", Vector3.new(1.5, 0.22, 0.22), cframeAt(origin, -9.25, 4.3, 1.5) * CFrame.Angles(0, 0, math.rad(-32)), Color3.fromRGB(84, 51, 30), Enum.Material.Wood)
	createPart(shovel, "ShovelBlade", Vector3.new(1.2, 1.5, 0.24), cframeAt(origin, -6.55, 0.95, 1.5) * CFrame.Angles(0, 0, math.rad(-32)), Color3.fromRGB(191, 197, 201), Enum.Material.Metal, "WedgePart")
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

	local colaCan = createPart(treasure, "IslandBloxyColaCan", Vector3.new(0.82, 1.55, 0.82), cframeAt(origin, 5.5, 2.3, 8.25), Color3.fromRGB(220, 38, 47), Enum.Material.Metal)
	colaCan.Shape = Enum.PartType.Cylinder
	colaCan:SetAttribute("TreasureLayer", "Cola")
	local colaTop = createPart(treasure, "IslandBloxyColaTop", Vector3.new(0.7, 0.08, 0.7), cframeAt(origin, 5.5, 3.11, 8.25), Color3.fromRGB(238, 238, 232), Enum.Material.Metal)
	colaTop.Shape = Enum.PartType.Cylinder
	colaTop:SetAttribute("TreasureLayer", "Cola")
	local colaLabel = createPart(treasure, "IslandBloxyColaLabel", Vector3.new(0.92, 0.68, 0.08), cframeAt(origin, 5.5, 2.3, 7.79), Color3.fromRGB(245, 245, 242), Enum.Material.SmoothPlastic)
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
	local resetRoomButton = makeResetRoomButton(roomFolder)
	local tvInsideLog = makeReferenceBook(roomFolder, "TVRoomInsideLog", CFrame.new(12.3, 0, Constants.Room.Depth / 2 - 3.1) * CFrame.Angles(0, math.rad(180), 0), "TVRoom", "TV ROOM")
	makeTVRoomClocks(roomFolder)
	local underfloorChamber, safetyFloor = makeUnderfloorChamber(roomFolder, recoveryFloor)
	makeSpawn(roomFolder)
	local hallway = makeHallway(roomFolder)
	local snackLab = makeSnackLabShell(roomFolder)
	local islandRoom = makeIslandRoom(roomFolder)
	local tvSecretRoom = makeTVSecretRoom(roomFolder)
	local bowlingAlley = makeBowlingAlley(roomFolder)
	createNoTouchClock(
		snackLab.Model,
		"SnackLabWallClock",
		"SnackLab",
		Vector3.new(0.28, 2.3, 5.6),
		cframeAt(SNACK_LAB_ORIGIN, Constants.Room.Width / 2 - 0.57, 8.2, -2.5),
		Enum.NormalId.Left
	)

	local pedestal = makePedestal(objectsFolder)
	local lightSwitch = makeLightSwitch(
		objectsFolder,
		"TVRoomLightSwitch",
		CFrame.new(-6.15, 4.55, Constants.Room.Depth / 2 - 0.58),
		{
			RoomId = "TVRoom",
			HighlightTag = Constants.Tags.TVLightSwitch,
			UnlocksGiantDiscovery = true,
		}
	)
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
