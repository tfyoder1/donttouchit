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

	local plate = createPart(
		resetModel,
		"ResetButtonPlate",
		Vector3.new(3.4, 2.1, 0.24),
		CFrame.new(-8.4, 4.5, wallZ),
		Color3.fromRGB(42, 47, 56),
		Enum.Material.Metal
	)

	local button = createPart(
		resetModel,
		"ResetButton",
		Vector3.new(1.45, 0.38, 1.45),
		CFrame.new(-8.4, 4.5, wallZ - 0.24) * CFrame.Angles(math.rad(90), 0, 0),
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

local function makeLightSwitch(objectsFolder)
	local switch = makeModel(objectsFolder, "TVRoomLightSwitch")
	local wallZ = Constants.Room.Depth / 2 - 0.58
	local baseCFrame = CFrame.new(-6.15, 4.55, wallZ)

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
	createSurfaceText(plate, "SwitchText", "LIGHT", Enum.NormalId.Front, Color3.fromRGB(34, 34, 32), Color3.fromRGB(238, 238, 226))
	createPrompt(plate, "Flip", "Light Switch", 0)
	tag(switch, Constants.Tags.LightSwitch)

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

local function makeReferenceBook(parent, name, cframe, roomId, title)
	local book = makeModel(parent, name)
	local base = createPart(book, "BookStand", Vector3.new(3.8, 2.4, 2.4), cframe * CFrame.new(0, 1.2, 0), Color3.fromRGB(53, 59, 68), Enum.Material.Metal)
	local cover = createPart(book, "BookCover", Vector3.new(3.4, 0.35, 2.5), cframe * CFrame.new(0, 2.55, -0.08) * CFrame.Angles(math.rad(-10), 0, 0), Color3.fromRGB(70, 45, 122), Enum.Material.SmoothPlastic)

	cover:SetAttribute("RoomId", roomId)
	createSurfaceText(cover, "BookText", title .. "\nLOG", Enum.NormalId.Top, Color3.fromRGB(255, 242, 181), Color3.fromRGB(70, 45, 122))
	createPrompt(cover, "Read", title .. " Book", 0)
	tag(cover, Constants.Tags.ReferenceBook)

	book.PrimaryPart = base
	return book
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
	createSpawnLocation(hallway, "HallwaySpawn", "Hallway", Constants.Hallway.SpawnCFrame, Color3.fromRGB(96, 194, 134), false)
	makeReferenceBook(hallway, "TVRoomReferenceBook", CFrame.new(-3.5, 0, 30), "TVRoom", "TV ROOM")
	makeReferenceBook(hallway, "SnackLabReferenceBook", CFrame.new(3.5, 0, 38), "SnackLab", "SNACK LAB")

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

	createSpawnLocation(room, "SnackLabSpawn", "SnackLab", Constants.GetRoomSpawnCFrame("SnackLab"), Color3.fromRGB(91, 188, 124), false)

	return {
		Model = room,
		ExitDoor = exitDoor,
	}
end

local function makeSnackButton(objectsFolder)
	local origin = SNACK_LAB_ORIGIN
	local model = makeModel(objectsFolder, "SnackLabButton")

	local base = createPart(model, "SnackButtonBase", Vector3.new(4.6, 2.6, 4.6), cframeAt(origin, 0, 1.8, 0), Color3.fromRGB(59, 67, 76), Enum.Material.Metal)

	local button = createPart(model, "SnackBlueButton", Vector3.new(3.1, 0.65, 3.1), cframeAt(origin, 0, 3.4, 0), Color3.fromRGB(45, 151, 255), Enum.Material.SmoothPlastic)
	button.Shape = Enum.PartType.Ball
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

	local base = createPart(mixer, "MixerBase", Vector3.new(5.2, 0.8, 4.2), cframeAt(origin, 12, 1.15, 7), Color3.fromRGB(94, 101, 115), Enum.Material.Metal)
	createPart(mixer, "MixerStand", Vector3.new(0.75, 3.4, 0.75), cframeAt(origin, 10.1, 2.75, 7), Color3.fromRGB(225, 229, 235), Enum.Material.Metal)
	local head = createPart(mixer, "MixerHead", Vector3.new(3.9, 1.3, 2.1), cframeAt(origin, 11.75, 4.35, 7), Color3.fromRGB(236, 63, 77), Enum.Material.Metal)
	local bowl = createPart(mixer, "MixerBowl", Vector3.new(3.6, 1.75, 3.6), cframeAt(origin, 12.25, 2.25, 7), Color3.fromRGB(116, 210, 225), Enum.Material.Glass)
	bowl.Shape = Enum.PartType.Ball
	bowl.Transparency = 0.25
	bowl:SetAttribute("BaseTransparency", bowl.Transparency)
	createPart(mixer, "BeaterLeft", Vector3.new(0.18, 1.8, 0.18), cframeAt(origin, 11.8, 3.15, 6.55), Color3.fromRGB(224, 232, 235), Enum.Material.Metal)
	createPart(mixer, "BeaterRight", Vector3.new(0.18, 1.8, 0.18), cframeAt(origin, 11.8, 3.15, 7.45), Color3.fromRGB(224, 232, 235), Enum.Material.Metal)
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

	local back = createPart(rack, "RackBack", Vector3.new(9.5, 6.6, 0.35), cframeAt(origin, -12, 4.0, 6.8), Color3.fromRGB(68, 76, 90), Enum.Material.Metal)
	createPart(rack, "RackLeft", Vector3.new(0.35, 6.8, 2.2), cframeAt(origin, -16.9, 4.0, 7.65), Color3.fromRGB(48, 54, 66), Enum.Material.Metal)
	createPart(rack, "RackRight", Vector3.new(0.35, 6.8, 2.2), cframeAt(origin, -7.1, 4.0, 7.65), Color3.fromRGB(48, 54, 66), Enum.Material.Metal)

	for shelfIndex = 1, 3 do
		local y = 1.65 + shelfIndex * 1.85
		createPart(rack, "SnackShelf", Vector3.new(10, 0.28, 2.3), cframeAt(origin, -12, y, 7.7), Color3.fromRGB(94, 103, 116), Enum.Material.Metal)

		for packIndex = 1, 5 do
			local x = -15.6 + (packIndex - 1) * 1.8
			local pack = createPart(
				rack,
				"SnackPack",
				Vector3.new(1.1, 1.45, 0.28),
				cframeAt(origin, x, y + 0.88, 6.45),
				colors[((shelfIndex + packIndex - 2) % #colors) + 1],
				Enum.Material.SmoothPlastic
			)
			pack:SetAttribute("IsSnackPack", true)
			createSurfaceText(pack, "SnackPackText", names[((shelfIndex + packIndex - 2) % #names) + 1], Enum.NormalId.Back, Color3.fromRGB(255, 255, 255), pack.Color)
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

	local fruitData = {
		{ Name = "Apple", Offset = Vector3.new(-0.9, 1.0, -0.35), Color = Color3.fromRGB(233, 52, 60), Size = 0.95 },
		{ Name = "Lemon", Offset = Vector3.new(0.2, 1.12, 0.2), Color = Color3.fromRGB(247, 224, 55), Size = 0.8 },
		{ Name = "Lime", Offset = Vector3.new(1.0, 0.95, -0.1), Color = Color3.fromRGB(74, 197, 91), Size = 0.82 },
		{ Name = "Orange", Offset = Vector3.new(-0.05, 1.2, -0.9), Color = Color3.fromRGB(255, 142, 47), Size = 0.88 },
	}

	for _, data in ipairs(fruitData) do
		local fruit = createPart(
			fruitBowl,
			data.Name,
			Vector3.new(data.Size, data.Size, data.Size),
			cframeAt(origin, 1.5 + data.Offset.X, 2.2 + data.Offset.Y, 7.5 + data.Offset.Z),
			data.Color,
			Enum.Material.SmoothPlastic
		)
		fruit.Shape = Enum.PartType.Ball
		fruit:SetAttribute("IsFruit", true)
	end

	createPrompt(bowl, "Inspect", "Fruit Bowl", 0)
	tag(fruitBowl, Constants.Tags.FruitBowl)
	fruitBowl.PrimaryPart = tableTop
	return fruitBowl
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
	local underfloorChamber, safetyFloor = makeUnderfloorChamber(roomFolder, recoveryFloor)
	makeSpawn(roomFolder)
	local hallway = makeHallway(roomFolder)
	local snackLab = makeSnackLabShell(roomFolder)

	local pedestal = makePedestal(objectsFolder)
	local lightSwitch = makeLightSwitch(objectsFolder)
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
	local snackRack = makeSnackRack(objectsFolder)
	local fruitBowl = makeFruitBowl(objectsFolder)

	connectSafetyFloor(safetyFloor)
	ResetService.CaptureRoots(roomFolder, objectsFolder)

	return {
		Room = roomFolder,
		InteractiveObjects = objectsFolder,
		RecoveryFloor = recoveryFloor,
		UnderfloorChamber = underfloorChamber,
		ExitDoor = exitDoor,
		ResetRoomButton = resetRoomButton,
		Hallway = hallway,
		Pedestal = pedestal,
		LightSwitch = lightSwitch,
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
		SnackRack = snackRack,
		FruitBowl = fruitBowl,
	}
end

return RoomBuilder
