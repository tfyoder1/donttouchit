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
	prompt.MaxActivationDistance = 10
	prompt.Parent = parent
	mark(prompt)
	return prompt
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
	local height = Constants.Room.Height
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

local function makeSpawn(roomFolder)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PlayerSpawn"
	spawn.Anchored = true
	spawn.BottomSurface = Enum.SurfaceType.Smooth
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Size = Vector3.new(7, 1, 7)
	spawn.CFrame = CFrame.new(0, 0.55, 11)
	spawn.Color = Color3.fromRGB(91, 188, 124)
	spawn.Material = Enum.Material.Neon
	spawn.Neutral = true
	spawn.Transparency = 0.25
	spawn.Parent = roomFolder
	mark(spawn)
	return spawn
end

local function makePedestal(objectsFolder)
	local pedestal = makeModel(objectsFolder, "Pedestal")

	local base = createPart(
		pedestal,
		"PedestalBase",
		Vector3.new(4.8, 3, 4.8),
		CFrame.new(0, 2, 0),
		Color3.fromRGB(72, 76, 82),
		Enum.Material.Metal,
		"Part"
	)
	base.Shape = Enum.PartType.Cylinder

	local button = createPart(
		pedestal,
		"BigRedButton",
		Vector3.new(3.2, 0.7, 3.2),
		CFrame.new(0, 3.85, 0),
		Color3.fromRGB(220, 25, 35),
		Enum.Material.SmoothPlastic,
		"Part"
	)
	button.Shape = Enum.PartType.Cylinder
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

local function makeCouch(objectsFolder)
	local couch = makeModel(objectsFolder, "Couch")
	couch:SetAttribute("RideDirection", Vector3.new(1, 0, 0))

	local baseColor = Color3.fromRGB(74, 139, 158)
	local seat = createPart(couch, "CouchSeat", Vector3.new(8, 1, 3.2), CFrame.new(-14, 1.1, 3), baseColor, Enum.Material.Fabric, "Seat")
	local back = createPart(couch, "CouchBack", Vector3.new(8.4, 3.4, 0.8), CFrame.new(-14, 2.4, 4.8), Color3.fromRGB(62, 121, 139), Enum.Material.Fabric)
	local leftArm = createPart(couch, "LeftArm", Vector3.new(0.8, 2.2, 3.6), CFrame.new(-18.4, 1.8, 3.2), Color3.fromRGB(62, 121, 139), Enum.Material.Fabric)
	local rightArm = createPart(couch, "RightArm", Vector3.new(0.8, 2.2, 3.6), CFrame.new(-9.6, 1.8, 3.2), Color3.fromRGB(62, 121, 139), Enum.Material.Fabric)

	couch.PrimaryPart = seat
	createPrompt(seat, "Sit", "Suspicious Couch", 0)
	tag(couch, Constants.Tags.Couch)

	return couch, { seat, back, leftArm, rightArm }
end

local function makeLamp(objectsFolder)
	local lamp = makeModel(objectsFolder, "FloorLamp")

	local base = createPart(lamp, "LampBase", Vector3.new(2.2, 0.25, 2.2), CFrame.new(14, 0.72, -9), Color3.fromRGB(58, 58, 66), Enum.Material.Metal)
	local pole = createPart(lamp, "LampPole", Vector3.new(0.25, 5.6, 0.25), CFrame.new(14, 3.35, -9), Color3.fromRGB(44, 44, 52), Enum.Material.Metal)
	local shade = createPart(lamp, "LampShade", Vector3.new(2.6, 1.2, 2.6), CFrame.new(14, 6.25, -9), Color3.fromRGB(255, 231, 125), Enum.Material.SmoothPlastic)
	shade.Shape = Enum.PartType.Cylinder
	shade.Name = "LampShade"

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
	createPart(appliance, "ApplianceBody", Vector3.new(3.8, 2.1, 2.2), CFrame.new(9, 3.65, 6), Color3.fromRGB(205, 209, 214), Enum.Material.Metal)
	local door = createPart(appliance, "ApplianceDoor", Vector3.new(3.4, 1.6, 0.15), CFrame.new(9, 3.65, 4.86), Color3.fromRGB(38, 42, 47), Enum.Material.Glass)
	createSurfaceText(door, "ApplianceText", "00:00", Enum.NormalId.Front, Color3.fromRGB(109, 255, 177), Color3.fromRGB(23, 28, 31))
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

local HALLWAY_SPAWN_CFRAME = CFrame.new(0, 3, 27)
local TV_ROOM_RETURN_CFRAME = CFrame.new(0, 3, 10)
local SNACK_LAB_ORIGIN = Vector3.new(48, 0, 44)
local SNACK_LAB_SPAWN_CFRAME = cframeAt(SNACK_LAB_ORIGIN, -11, 3, 10)

local function makeHallDoor(parent, name, size, cframe, face, label, destinationCFrame, lockedMessage)
	local door = createPart(parent, name, size, cframe, Color3.fromRGB(79, 92, 116), Enum.Material.Wood)
	createSurfaceText(door, "DoorText", label, face, Color3.fromRGB(232, 245, 255), Color3.fromRGB(38, 48, 64))

	local prompt = createPrompt(door, lockedMessage and "Knock" or "Enter", label, 0)
	if destinationCFrame then
		door:SetAttribute("DestinationCFrame", destinationCFrame)
	end
	if lockedMessage then
		door:SetAttribute("LockedMessage", lockedMessage)
		prompt.ActionText = "Knock"
	end

	tag(door, Constants.Tags.HallDoor)
	return door
end

local function makeHallway(roomFolder)
	local hallway = makeModel(roomFolder, "DoorHallway")

	createPart(hallway, "HallwayFloor", Vector3.new(13, 1, 56), CFrame.new(0, 0, 45), Color3.fromRGB(92, 101, 112), Enum.Material.Concrete)
	createPart(hallway, "HallwayLeftWall", Vector3.new(1, 10, 56), CFrame.new(-6.5, 5, 45), Color3.fromRGB(150, 156, 168), Enum.Material.SmoothPlastic)
	createPart(hallway, "HallwayRightWall", Vector3.new(1, 10, 56), CFrame.new(6.5, 5, 45), Color3.fromRGB(150, 156, 168), Enum.Material.SmoothPlastic)
	createPart(hallway, "HallwayCeiling", Vector3.new(13, 1, 56), CFrame.new(0, 10, 45), Color3.fromRGB(116, 119, 128), Enum.Material.Concrete)
	createPart(hallway, "HallwayEndWall", Vector3.new(13, 10, 1), CFrame.new(0, 5, 73), Color3.fromRGB(150, 156, 168), Enum.Material.SmoothPlastic)

	local label = createPart(hallway, "HallwaySign", Vector3.new(9.5, 2.2, 0.3), CFrame.new(0, 7.1, 22), Color3.fromRGB(250, 238, 111), Enum.Material.SmoothPlastic)
	createSurfaceText(label, "HallwaySignText", "ROOMS", Enum.NormalId.Back, Color3.fromRGB(22, 22, 26), Color3.fromRGB(250, 238, 111))

	local snackDoor = makeHallDoor(
		hallway,
		"SnackLabDoor",
		Vector3.new(0.45, 8.5, 6.5),
		CFrame.new(5.95, 4.75, 45),
		Enum.NormalId.Left,
		"SNACK LAB",
		SNACK_LAB_SPAWN_CFRAME
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

	makeHallDoor(
		hallway,
		"DeepHallDoor",
		Vector3.new(7, 8.5, 0.45),
		CFrame.new(0, 4.75, 72.4),
		Enum.NormalId.Back,
		"MORE SOON",
		nil,
		"The hallway refuses to be bigger yet."
	)

	local returnPad = createPart(hallway, "HallwayLanding", Vector3.new(8, 0.25, 8), CFrame.new(HALLWAY_SPAWN_CFRAME.Position - Vector3.new(0, 2.9, 0)), Color3.fromRGB(96, 194, 134), Enum.Material.Neon)
	returnPad.Transparency = 0.35
	returnPad:SetAttribute("BaseTransparency", returnPad.Transparency)

	return {
		Model = hallway,
		SnackDoor = snackDoor,
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

	local spawnPad = createPart(room, "SnackSpawnPad", Vector3.new(7, 0.25, 7), CFrame.new(SNACK_LAB_SPAWN_CFRAME.Position - Vector3.new(0, 2.9, 0)), Color3.fromRGB(91, 188, 124), Enum.Material.Neon)
	spawnPad.Transparency = 0.35
	spawnPad:SetAttribute("BaseTransparency", spawnPad.Transparency)

	return {
		Model = room,
		ExitDoor = exitDoor,
	}
end

local function makeSnackButton(objectsFolder)
	local origin = SNACK_LAB_ORIGIN
	local model = makeModel(objectsFolder, "SnackLabButton")

	local base = createPart(model, "SnackButtonBase", Vector3.new(4.6, 2.6, 4.6), cframeAt(origin, 0, 1.8, 0), Color3.fromRGB(59, 67, 76), Enum.Material.Metal)
	base.Shape = Enum.PartType.Cylinder

	local button = createPart(model, "SnackBlueButton", Vector3.new(3.1, 0.65, 3.1), cframeAt(origin, 0, 3.4, 0), Color3.fromRGB(45, 151, 255), Enum.Material.SmoothPlastic)
	button.Shape = Enum.PartType.Cylinder
	createPrompt(button, "Press", "Snack Lab Button", 0.1)
	tag(button, Constants.Tags.SnackButton)

	local sign = createPart(model, "SnackButtonSign", Vector3.new(10, 2.4, 0.35), cframeAt(origin, 0, 5.8, -3.4), Color3.fromRGB(244, 248, 112), Enum.Material.SmoothPlastic)
	createSurfaceText(sign, "SnackButtonText", "DO NOT FEED THE ROOM", Enum.NormalId.Back, Color3.fromRGB(22, 23, 25), Color3.fromRGB(244, 248, 112))

	model.PrimaryPart = base
	return model
end

local function makeSnackFridge(objectsFolder)
	local origin = SNACK_LAB_ORIGIN
	local fridge = makeModel(objectsFolder, "Fridge")

	local body = createPart(fridge, "FridgeBody", Vector3.new(6, 9, 4), cframeAt(origin, -13, 4.9, -9), Color3.fromRGB(213, 225, 228), Enum.Material.Metal)
	local door = createPart(fridge, "FridgeDoor", Vector3.new(5.5, 8, 0.32), cframeAt(origin, -13, 4.9, -6.83), Color3.fromRGB(237, 246, 247), Enum.Material.Metal)
	createSurfaceText(door, "FridgeDoorText", "DO NOT OPEN", Enum.NormalId.Front, Color3.fromRGB(26, 35, 39), Color3.fromRGB(237, 246, 247))
	createPrompt(door, "Open", "Fridge", 0)
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
	createPart(sink, "SinkBasin", Vector3.new(4.6, 0.55, 2.2), cframeAt(origin, 10, 2.95, -9), Color3.fromRGB(61, 75, 83), Enum.Material.Metal)
	local faucet = createPart(sink, "Faucet", Vector3.new(0.45, 2.3, 0.45), cframeAt(origin, 10, 4, -10.1), Color3.fromRGB(216, 223, 226), Enum.Material.Metal)
	createPrompt(faucet, "Turn", "Sink", 0)
	tag(sink, Constants.Tags.SnackSink)

	sink.PrimaryPart = faucet
	return sink
end

local function makeSnackMixer(objectsFolder)
	local origin = SNACK_LAB_ORIGIN
	local mixer = makeModel(objectsFolder, "Mixer")

	local base = createPart(mixer, "MixerBase", Vector3.new(5.2, 0.8, 4.2), cframeAt(origin, 12, 1.15, 7), Color3.fromRGB(94, 101, 115), Enum.Material.Metal)
	local bowl = createPart(mixer, "MixerBowl", Vector3.new(3.6, 2.2, 3.6), cframeAt(origin, 12, 2.5, 7), Color3.fromRGB(116, 210, 225), Enum.Material.Glass)
	bowl.Shape = Enum.PartType.Ball
	local arm = createPart(mixer, "MixerArm", Vector3.new(4.6, 0.75, 1.1), cframeAt(origin, 12, 4.05, 7), Color3.fromRGB(225, 229, 235), Enum.Material.Metal)
	createPrompt(bowl, "Mix", "Mixer", 0)
	tag(mixer, Constants.Tags.SnackMixer)

	mixer.PrimaryPart = base
	return mixer, bowl, arm
end

local function connectRecoveryFloor(recoveryFloor)
	local debounceByCharacter = {}

	recoveryFloor.Touched:Connect(function(hit)
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
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.CFrame = CFrame.new(0, 5, 10)
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
	makeSpawn(roomFolder)
	local hallway = makeHallway(roomFolder)
	local snackLab = makeSnackLabShell(roomFolder)

	local pedestal = makePedestal(objectsFolder)
	local couch = makeCouch(objectsFolder)
	local lamp = makeLamp(objectsFolder)
	makeTableAndAppliance(objectsFolder)
	local squishy = makeSquishy(objectsFolder)
	local television = makeTelevision(objectsFolder)
	local snackButton = makeSnackButton(objectsFolder)
	local fridge = makeSnackFridge(objectsFolder)
	local toaster = makeSnackToaster(objectsFolder)
	local sink = makeSnackSink(objectsFolder)
	local mixer = makeSnackMixer(objectsFolder)

	connectRecoveryFloor(recoveryFloor)
	ResetService.CaptureRoots(roomFolder, objectsFolder)

	return {
		Room = roomFolder,
		InteractiveObjects = objectsFolder,
		RecoveryFloor = recoveryFloor,
		ExitDoor = exitDoor,
		Hallway = hallway,
		Pedestal = pedestal,
		Couch = couch,
		Lamp = lamp,
		Squishy = squishy,
		Television = television,
		SnackLab = snackLab,
		SnackButton = snackButton,
		Fridge = fridge,
		Toaster = toaster,
		Sink = sink,
		Mixer = mixer,
	}
end

return RoomBuilder
