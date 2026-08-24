local AssetService = game:GetService("AssetService")
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
local SNACK_DONUT_ASSET_ID = 13742217239
local SNACK_DONUT_MESH_ID = "rbxassetid://13582448483"
local SNACK_DONUT_TEXTURE_ID = "rbxassetid://13582452879"
local SLEEPING_REPLACEMENT_TENT_ASSET_ID = 140322654375696
local LIBRARY_ROLLING_LADDER_ASSET_ID = 88745654506698
local MAIN_HALLWAY_WALL_TEXTURE_ID = "rbxassetid://12813020091"
local ATOMIC_COLORS = {
	Pink = Color3.fromRGB(255, 102, 176),
	Orange = Color3.fromRGB(255, 134, 58),
	Brown = Color3.fromRGB(121, 72, 45),
	Cream = Color3.fromRGB(255, 229, 161),
	NeonPink = Color3.fromRGB(255, 72, 158),
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

local function applyTextureToFace(part, name, textureId, face, studsPerTile)
	local texture = Instance.new("Texture")
	texture.Name = name
	texture.Texture = textureId
	texture.Face = face
	texture.StudsPerTileU = studsPerTile
	texture.StudsPerTileV = studsPerTile
	texture.Parent = part
	mark(texture)
	return texture
end

local function createSoundSourceAnchor(parent, name, cframe)
	local anchor = createPart(parent, name, Vector3.new(1, 1, 1), cframe, Color3.fromRGB(0, 0, 0), Enum.Material.SmoothPlastic)
	anchor.Transparency = 1
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.CastShadow = false
	anchor:SetAttribute("BaseTransparency", 1)
	anchor:SetAttribute("BaseCanCollide", false)
	anchor:SetAttribute("BaseCanQuery", false)
	anchor:SetAttribute("BaseCanTouch", false)
	anchor:SetAttribute("PrologueInspectIgnore", true)
	return anchor
end

local function createPrompt(parent, actionText, objectText, holdDuration)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "InteractPrompt"
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = holdDuration or 0
	prompt.RequiresLineOfSight = true
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
	local spawnPosition = destinationCFrame.Position - Vector3.new(0, 3.55, 0)
	spawn.CFrame = CFrame.new(spawnPosition) * (destinationCFrame - destinationCFrame.Position)
	spawn.Color = color
	spawn.Material = Enum.Material.Neon
	spawn.Neutral = true
	spawn.Enabled = enabled == true
	spawn.Transparency = 0.32
	spawn.CanCollide = false
	spawn:SetAttribute("BaseCanCollide", false)
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

local function getOppositeFace(face)
	if face == Enum.NormalId.Front then
		return Enum.NormalId.Back
	elseif face == Enum.NormalId.Back then
		return Enum.NormalId.Front
	elseif face == Enum.NormalId.Left then
		return Enum.NormalId.Right
	elseif face == Enum.NormalId.Right then
		return Enum.NormalId.Left
	elseif face == Enum.NormalId.Top then
		return Enum.NormalId.Bottom
	elseif face == Enum.NormalId.Bottom then
		return Enum.NormalId.Top
	end

	return Enum.NormalId.Back
end

local function createDoubleSidedSurfaceText(parent, name, text, face, textColor, backgroundColor)
	local frontLabel = createSurfaceText(parent, name, text, face, textColor, backgroundColor)
	createSurfaceText(parent, name .. "Back", text, getOppositeFace(face or Enum.NormalId.Front), textColor, backgroundColor)
	return frontLabel
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

local function makeDecorPart(parent, name, size, cframe, color, material, className)
	local part = createPart(parent, name, size, cframe, color, material, className)
	part.CanCollide = false
	part.CastShadow = false
	part:SetAttribute("BaseCanCollide", false)
	return part
end

local function makeAtomicStarburst(parent, name, centerCFrame, scale, colorA, colorB)
	scale = scale or 1
	colorA = colorA or ATOMIC_COLORS.NeonPink
	colorB = colorB or ATOMIC_COLORS.Orange

	local burst = makeModel(parent, name)
	local core = makeDecorPart(
		burst,
		"Core",
		Vector3.new(0.5 * scale, 0.5 * scale, 0.5 * scale),
		centerCFrame,
		colorA,
		Enum.Material.Neon
	)
	core.Shape = Enum.PartType.Ball

	for spokeIndex = 1, 8 do
		local angle = math.rad((spokeIndex - 1) * 45)
		local length = (if spokeIndex % 2 == 0 then 2.15 else 3.15) * scale
		local spoke = makeDecorPart(
			burst,
			"Spoke" .. spokeIndex,
			Vector3.new(length, 0.09 * scale, 0.09 * scale),
			centerCFrame * CFrame.Angles(0, 0, angle) * CFrame.new(length / 2 + 0.32 * scale, 0, 0),
			if spokeIndex % 2 == 0 then colorB else colorA,
			Enum.Material.Neon
		)
		spoke:SetAttribute("AtomicDecor", true)
	end

	burst.PrimaryPart = core
	return burst
end

local function makeAtomicBoomerang(parent, name, centerCFrame, scale, color)
	scale = scale or 1
	color = color or ATOMIC_COLORS.Orange

	local boomerang = makeModel(parent, name)
	for armIndex, angle in ipairs({ 28, -28 }) do
		local arm = makeDecorPart(
			boomerang,
			"Arm" .. armIndex,
			Vector3.new(2.45 * scale, 0.24 * scale, 0.12 * scale),
			centerCFrame * CFrame.Angles(0, 0, math.rad(angle)) * CFrame.new(0.92 * scale, 0, 0),
			color,
			Enum.Material.Neon
		)
		arm:SetAttribute("AtomicDecor", true)
		if armIndex == 1 then
			boomerang.PrimaryPart = arm
		end
	end

	local hinge = makeDecorPart(
		boomerang,
		"HingeDot",
		Vector3.new(0.34 * scale, 0.34 * scale, 0.34 * scale),
		centerCFrame,
		ATOMIC_COLORS.Cream,
		Enum.Material.Neon
	)
	hinge.Shape = Enum.PartType.Ball
	return boomerang
end

local function makeAtomicDiamondCluster(parent, name, centerCFrame, scale)
	scale = scale or 1

	local cluster = makeModel(parent, name)
	local diamond = makeDecorPart(
		cluster,
		"Diamond",
		Vector3.new(1.12 * scale, 1.12 * scale, 0.12 * scale),
		centerCFrame * CFrame.Angles(0, 0, math.rad(45)),
		ATOMIC_COLORS.Cream,
		Enum.Material.Neon
	)
	cluster.PrimaryPart = diamond

	for dotIndex, data in ipairs({
		{ Offset = Vector3.new(-1.25, 0.75, 0), Color = ATOMIC_COLORS.Brown, Size = 0.32 },
		{ Offset = Vector3.new(1.35, -0.72, 0), Color = ATOMIC_COLORS.Pink, Size = 0.38 },
		{ Offset = Vector3.new(0.35, 1.55, 0), Color = ATOMIC_COLORS.Orange, Size = 0.26 },
	}) do
		local dot = makeDecorPart(
			cluster,
			"SatelliteDot" .. dotIndex,
			Vector3.new(data.Size * scale, data.Size * scale, data.Size * scale),
			centerCFrame * CFrame.new(data.Offset * scale),
			data.Color,
			Enum.Material.Neon
		)
		dot.Shape = Enum.PartType.Ball
	end

	return cluster
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
			if (column >= 3 and row >= 3) or (column == 2 and row == 3) then
				floor:SetAttribute("FloorGoneProtected", true)
			end
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
	createSurfaceText(door, "DoorText", "", Enum.NormalId.Front, Color3.fromRGB(230, 255, 240), Color3.fromRGB(42, 66, 76))
	local prompt = createPrompt(door, "Inspect", "TV Room", 0)
	prompt.Enabled = false
	door:SetAttribute("DestinationCFrame", CFrame.new(Vector3.new(0, 3, depth / 2 + 9), Vector3.new(0, 3, depth / 2 + 24)))
	door:SetAttribute("RoomId", "TVRoom")
	door:SetAttribute("LockedDuringPrologue", true)
	door:SetAttribute("PrologueLockedMessage", "The TV room door is quiet. It does not open before lockdown.")
	door:SetAttribute("InvisiblePassage", true)
	door.Transparency = 1
	door.CanCollide = false
	door.CanQuery = false
	door.CanTouch = false
	door:SetAttribute("BaseTransparency", 1)
	door:SetAttribute("BaseCanCollide", false)
	door:SetAttribute("BaseCanQuery", false)
	door:SetAttribute("BaseCanTouch", false)
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
	buttonPrompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	tag(button, Constants.Tags.MainButton)

	local sign = createPart(
		pedestal,
		"DontTouchItSign",
		Vector3.new(9, 3, 0.35),
		CFrame.new(0, 6.4, -3.35),
		Color3.fromRGB(245, 234, 93),
		Enum.Material.SmoothPlastic
	)
	createDoubleSidedSurfaceText(sign, "SignText", "DON'T TOUCH IT", Enum.NormalId.Back, Color3.fromRGB(25, 25, 25), Color3.fromRGB(245, 234, 93))

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
	lever.CanQuery = false
	lever:SetAttribute("BaseCanQuery", false)
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
	local tableCFrame = CFrame.new(18.5, 2.3, 5.8) * CFrame.Angles(0, math.rad(90), 0)
	createPart(tableModel, "TableTop", Vector3.new(8, 0.45, 4), tableCFrame, Color3.fromRGB(132, 92, 62), Enum.Material.Wood)

	for xOffset = -3, 3, 6 do
		for zOffset = -1.4, 1.4, 2.8 do
			createPart(tableModel, "TableLeg", Vector3.new(0.35, 3, 0.35), tableCFrame * CFrame.new(xOffset, -1.15, zOffset), Color3.fromRGB(100, 69, 47), Enum.Material.Wood)
		end
	end

	local appliance = makeModel(objectsFolder, "Microwave")
	local microwaveCFrame = CFrame.new(18.85, 3.65, 5.8) * CFrame.Angles(0, math.rad(90), 0)
	local body = createPart(appliance, "ApplianceBody", Vector3.new(3.8, 2.1, 2.2), microwaveCFrame, Color3.fromRGB(205, 209, 214), Enum.Material.Metal)
	local door = createPart(appliance, "ApplianceDoor", Vector3.new(3.4, 1.6, 0.15), microwaveCFrame * CFrame.new(0, 0, -1.14), Color3.fromRGB(38, 42, 47), Enum.Material.Glass)
	createSurfaceText(door, "ApplianceText", "00:00", Enum.NormalId.Front, Color3.fromRGB(109, 255, 177), Color3.fromRGB(23, 28, 31))
	createPrompt(door, "Start", "Microwave", 0)
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
	createDoubleSidedSurfaceText(subLevelOneSign, "SubLevel1SignText", "SUB LEVEL 1\nRAIN SORTING DECK", Enum.NormalId.Front, Color3.fromRGB(12, 26, 24), Color3.fromRGB(106, 255, 196))

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

local HALLWAY_SPAWN_CFRAME = CFrame.new(Vector3.new(0, 3, 27), Vector3.new(0, 3, 42))
local TV_ROOM_RETURN_CFRAME = CFrame.new(0, 3, 10)
local CAVE_SPAWN_CFRAME = Constants.GetRoomSpawnCFrame("CaveEntrance")
local CAVE_HALLWAY_RETURN_CFRAME = CFrame.new(Vector3.new(-1.4, 3, 45), Vector3.new(5.5, 3, 45))
local CAVE_HALLWAY_CAVE_RETURN_CFRAME = CFrame.new(Vector3.new(-124, -5.2, -112), Vector3.new(-124, -5.2, -82))
local SECURITY_ROOM_ORIGIN = Vector3.new(82, 0, -28)
local SECURITY_ROOM_SPAWN_CFRAME = Constants.GetRoomSpawnCFrame("SecurityRoom")
local SECURITY_HALLWAY_RETURN_CFRAME = CFrame.new(Vector3.new(3.2, 3, 59), Vector3.new(-3.2, 3, 59))
local SLEEPING_QUARTERS_ORIGIN = Vector3.new(82, 0, -188)
local SLEEPING_QUARTERS_SPAWN_CFRAME = Constants.GetRoomSpawnCFrame("SleepingQuarters")
local SLEEPING_HALLWAY_RETURN_CFRAME = CFrame.new(Vector3.new(-3.2, 3, 59), Vector3.new(3.2, 3, 59))
local INFIRMARY_ORIGIN = Vector3.new(170, 0, -154)
local INFIRMARY_SPAWN_CFRAME = Constants.GetRoomSpawnCFrame("Infirmary")
local GYM_ORIGIN = Vector3.new(170, 6, -224)
local GYM_SPAWN_CFRAME = Constants.GetRoomSpawnCFrame("Gym")
local TOP_DOWN_ARENA_ORIGIN = Vector3.new(82, 0, -398)
local TOP_DOWN_ARENA_SPAWN_CFRAME = Constants.GetRoomSpawnCFrame("TopDownArena")
local TOP_DOWN_SLEEPING_RETURN_CFRAME = CFrame.new(Vector3.new(82, 3, -322), Vector3.new(82, 3, -188))
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
local BOWLING_MAINTENANCE_ROOM_CFRAME = CFrame.new(Vector3.new(-21, 3, -194), Vector3.new(-21, 3, -184))
local LIBRARY_LOFT_SPAWN_CFRAME = CFrame.new(Vector3.new(-14, 17.6, -45), Vector3.new(-14, 17.6, -54))
local LIBRARY_LOFT_RETURN_CFRAME = CFrame.new(Vector3.new(-8.8, 10.6, -14.7), Vector3.new(-8.8, 10.2, -16.55))
local TREETOP_ENTRY_CFRAME = CFrame.new(Vector3.new(-14, 29, -220), Vector3.new(-7, 29, -240))
local TREETOP_ZIPLINE_END_CFRAME = CFrame.new(Vector3.new(0, 5.8, 132), Vector3.new(0, 4, 154))
local VOID_ORIGIN = Vector3.new(-92, 44, -28)
local VOID_SPAWN_CFRAME = Constants.GetRoomSpawnCFrame("Void")
local TREETOP_ZIPLINE_PATH_POINTS = {
	Vector3.new(-14, 32, -229),
	Vector3.new(8, 47, -192),
	Vector3.new(38, 53, -142),
	Vector3.new(4, 61, -98),
	Vector3.new(-46, 56, -78),
	Vector3.new(-85, 52, -58),
	Vector3.new(-108, 49, -40),
	VOID_SPAWN_CFRAME.Position + Vector3.new(0, 5, 16),
}
local VOID_ZIPLINE_PATH_POINTS = {
	VOID_SPAWN_CFRAME.Position + Vector3.new(0, 5, -16),
	Vector3.new(-116, 64, -2),
	Vector3.new(-72, 70, 42),
	Vector3.new(22, 66, 46),
	Vector3.new(44, 58, 92),
	Vector3.new(-28, 44, 112),
	Vector3.new(-10, 28, 124),
	TREETOP_ZIPLINE_END_CFRAME.Position + Vector3.new(0, 5, 0),
}
local SNACK_LAB_ORIGIN = Vector3.new(48, 0, 44)
local SNACK_LAB_SPAWN_CFRAME = CFrame.new(SNACK_LAB_ORIGIN + Vector3.new(-11, 3, 10), SNACK_LAB_ORIGIN + Vector3.new(0, 3, 0))
local ISLAND_ORIGIN = Vector3.new(0, 0, 150)
local ISLAND_SPAWN_CFRAME = Constants.GetRoomSpawnCFrame("Island")
local ISLAND_RETURN_CFRAME = CFrame.new(Vector3.new(0, 3, 103), Vector3.new(0, 3, 88))
local SPACE_STATION_ORIGIN = Vector3.new(92, 80, 150)
local SPACE_STATION_SPAWN_CFRAME = Constants.GetRoomSpawnCFrame("SpaceStation")
local ISLAND_SPACE_BLOCK_ID = "bent_palm_orbit_block"

local function setCaveSealBaseline(part, closedTransparency, closedCanCollide)
	part.Transparency = 1
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part:SetAttribute("BaseTransparency", 1)
	part:SetAttribute("BaseCanCollide", false)
	part:SetAttribute("BaseCanQuery", false)
	part:SetAttribute("BaseCanTouch", false)
	part:SetAttribute("ClosedTransparency", closedTransparency or 0.1)
	part:SetAttribute("ClosedCanCollide", closedCanCollide == true)
	part:SetAttribute("ClosedCanQuery", true)
	part:SetAttribute("ClosedCanTouch", false)
end

local OBSERVATION_SUITES = {
	{
		Id = "ObservationSecurity",
		RoomId = "SecurityRoom",
		Label = "OBS-SEC-01",
		MirrorCFrame = CFrame.new(104.42, 6.7, -28),
		MirrorSize = Vector3.new(0.18, 5.7, 9.4),
		RoomCFrame = Constants.GetNamedPlaceCFrame("ObservationSecurity"),
	},
	{
		Id = "ObservationTVRoom",
		RoomId = "TVRoom",
		Label = "OBS-TV-01",
		MirrorCFrame = CFrame.new(-20.42, 7.6, 0),
		MirrorSize = Vector3.new(0.18, 5.4, 8.4),
		RoomCFrame = Constants.GetNamedPlaceCFrame("ObservationTVRoom"),
	},
	{
		Id = "ObservationSnackLab",
		RoomId = "SnackLab",
		Label = "OBS-SNK-01",
		MirrorCFrame = CFrame.new(68.42, 6.6, 44),
		MirrorSize = Vector3.new(0.18, 5.0, 8.4),
		RoomCFrame = Constants.GetNamedPlaceCFrame("ObservationSnackLab"),
	},
	{
		Id = "ObservationIsland",
		RoomId = "Island",
		Label = "OBS-ISL-01",
		MirrorCFrame = CFrame.new(-54.42, 6.4, 160),
		MirrorSize = Vector3.new(0.18, 5.0, 8.8),
		RoomCFrame = Constants.GetNamedPlaceCFrame("ObservationIsland"),
	},
	{
		Id = "ObservationLibrary",
		RoomId = "Library",
		Label = "OBS-LIB-01",
		MirrorCFrame = CFrame.new(-31.42, 6.4, -45),
		MirrorSize = Vector3.new(0.18, 5.0, 7.2),
		RoomCFrame = Constants.GetNamedPlaceCFrame("ObservationLibrary"),
	},
	{
		Id = "ObservationBowling",
		RoomId = "BowlingAlley",
		Label = "OBS-BOWL-01",
		MirrorCFrame = CFrame.new(-37.22, 6.4, -132),
		MirrorSize = Vector3.new(0.18, 5.0, 9.6),
		RoomCFrame = Constants.GetNamedPlaceCFrame("ObservationBowling"),
	},
	{
		Id = "ObservationSleeping",
		RoomId = "SleepingQuarters",
		Label = "OBS-SLEEP-01",
		MirrorCFrame = CFrame.new(49.55, 8.2, -188),
		MirrorSize = Vector3.new(0.24, 14.2, 13.6),
		MirrorCanCollide = true,
		RoomCFrame = Constants.GetNamedPlaceCFrame("ObservationSleeping"),
	},
	{
		Id = "ObservationTopDown",
		RoomId = "TopDownArena",
		Label = "OBS-TOP-01",
		MirrorCFrame = CFrame.new(145.42, 9.4, -398),
		MirrorSize = Vector3.new(0.18, 6.4, 12.0),
		RoomCFrame = Constants.GetNamedPlaceCFrame("ObservationTopDown"),
	},
	{
		Id = "ObservationCave",
		RoomId = "CaveEntrance",
		Label = "OBS-CAVE-01",
		MirrorCFrame = CFrame.new(-88, 5.2, 64.42),
		MirrorSize = Vector3.new(9.2, 4.8, 0.18),
		RoomCFrame = Constants.GetNamedPlaceCFrame("ObservationCave"),
	},
	{
		Id = "ObservationVoid",
		RoomId = "Void",
		Label = "OBS-VOID-01",
		MirrorCFrame = CFrame.new(-109.42, 50.4, -28),
		MirrorSize = Vector3.new(0.18, 5.8, 9.2),
		RoomCFrame = Constants.GetNamedPlaceCFrame("ObservationVoid"),
	},
	{
		Id = "ObservationSpace",
		RoomId = "SpaceStation",
		Label = "OBS-SPACE-01",
		MirrorCFrame = CFrame.new(115.42, 86.5, 150),
		MirrorSize = Vector3.new(0.18, 5.4, 8.4),
		RoomCFrame = Constants.GetNamedPlaceCFrame("ObservationSpace"),
	},
	{
		Id = "ObservationTreetop",
		RoomId = "TreetopZipline",
		Label = "OBS-ZIP-01",
		MirrorCFrame = CFrame.new(-22, 32.8, -220),
		MirrorSize = Vector3.new(8.2, 4.8, 0.18),
		RoomCFrame = Constants.GetNamedPlaceCFrame("ObservationTreetop"),
	},
}

local function makeObservationTeleportPanel(parent, spec, cframe)
	local panel = makeModel(parent, spec.Id .. "MiniTeleportPanel")
	panel:SetAttribute("BunkerEnergyIgnored", true)
	panel:SetAttribute("RoomId", spec.RoomId)
	panel:SetAttribute("ObservationPlaceId", spec.Id)

	local panelColor = Color3.fromRGB(30, 39, 48)
	local teleporterColor = Color3.fromRGB(119, 255, 203)
	local plate = createPart(
		panel,
		"MiniTeleportPanelPlate",
		Vector3.new(1.25, 1.0, 0.12),
		cframe,
		panelColor,
		Enum.Material.Metal
	)
	plate.CanCollide = false
	plate:SetAttribute("BaseCanCollide", false)
	plate:SetAttribute("RoomId", spec.RoomId)
	plate:SetAttribute("ObservationPlaceId", spec.Id)

	local label = createSurfaceText(
		plate,
		"MiniTeleportText",
		"TELE\nPORT",
		Enum.NormalId.Front,
		teleporterColor,
		panelColor
	)
	label.Position = UDim2.fromScale(0, 0.04)
	label.Size = UDim2.fromScale(1, 0.44)

	local button = createPart(
		panel,
		"MiniTeleportButton",
		Vector3.new(0.58, 0.16, 0.58),
		cframe * CFrame.new(0, -0.24, -0.18) * CFrame.Angles(math.rad(90), 0, 0),
		teleporterColor,
		Enum.Material.Neon
	)
	button.Shape = Enum.PartType.Cylinder
	button.CanCollide = false
	button:SetAttribute("BaseCanCollide", false)
	button:SetAttribute("RoomId", spec.RoomId)
	button:SetAttribute("ObservationPlaceId", spec.Id)
	button:SetAttribute("ObservationLabel", spec.Label)

	local lowerGlow = createPart(
		panel,
		"MiniTeleportLowerGlow",
		Vector3.new(0.64, 0.08, 0.05),
		cframe * CFrame.new(0, -0.26, -0.24),
		teleporterColor,
		Enum.Material.Neon
	)
	lowerGlow.CanCollide = false
	lowerGlow:SetAttribute("BaseCanCollide", false)

	local prompt = createPrompt(button, "Open", "Teleport", 0.2)
	prompt.MaxActivationDistance = 7
	tag(button, Constants.Tags.TeleportButton)

	panel.PrimaryPart = plate
	return panel
end

local function makeObservationSuite(parent, spec)
	local suite = makeModel(parent, spec.Id .. "Suite")
	suite:SetAttribute("BunkerEnergyIgnored", true)

	local mirror = createPart(
		suite,
		spec.Id .. "DoubleSidedMirror",
		spec.MirrorSize,
		spec.MirrorCFrame,
		Color3.fromRGB(128, 176, 190),
		Enum.Material.Glass
	)
	mirror.Name = spec.Id .. "ObservationMirror"
	mirror.Transparency = 0.42
	mirror.Reflectance = 0.28
	local mirrorCanCollide = spec.MirrorCanCollide == true
	mirror.CanCollide = mirrorCanCollide
	mirror:SetAttribute("BaseTransparency", mirror.Transparency)
	mirror:SetAttribute("BaseCanCollide", mirrorCanCollide)
	mirror:SetAttribute("RoomId", spec.RoomId)
	mirror:SetAttribute("ObservationPlaceId", spec.Id)
	mirror:SetAttribute("ObservationLabel", spec.Label)
	createPrompt(mirror, "Inspect", "Strange Mirror", 0.08)
	tag(mirror, Constants.Tags.ObservationMirror)

	local spark = createPart(suite, spec.Id .. "MirrorEdgeGlow", spec.MirrorSize + Vector3.new(0.04, 0.18, 0.18), spec.MirrorCFrame, Color3.fromRGB(119, 255, 203), Enum.Material.Neon)
	spark.Transparency = 0.84
	spark.CanCollide = false
	spark.CanQuery = false
	spark:SetAttribute("BaseTransparency", spark.Transparency)
	spark:SetAttribute("BaseCanCollide", false)
	spark:SetAttribute("BaseCanQuery", false)

	local roomCFrame = spec.RoomCFrame
	local origin = roomCFrame.Position
	local function roomRelativeCFrame(x, y, z)
		return roomCFrame * CFrame.new(x, y, z)
	end

	local roomWidth = 10
	local roomDepth = 8
	local roomHeight = 7
	local wallColor = Color3.fromRGB(12, 15, 19)
	local trimColor = Color3.fromRGB(41, 58, 70)

	createPart(suite, spec.Id .. "Floor", Vector3.new(roomWidth, 0.38, roomDepth), roomRelativeCFrame(0, -2.05, 0), Color3.fromRGB(26, 32, 38), Enum.Material.Metal)
	createPart(suite, spec.Id .. "Ceiling", Vector3.new(roomWidth, 0.38, roomDepth), roomRelativeCFrame(0, roomHeight - 2.05, 0), wallColor, Enum.Material.Metal)
	createPart(suite, spec.Id .. "BackWall", Vector3.new(roomWidth, roomHeight, 0.42), roomRelativeCFrame(0, 1.45, roomDepth / 2), wallColor, Enum.Material.Metal)
	createPart(suite, spec.Id .. "FrontWallLow", Vector3.new(roomWidth, 1.2, 0.42), roomRelativeCFrame(0, -1.45, -roomDepth / 2), trimColor, Enum.Material.Metal)
	createPart(suite, spec.Id .. "FrontWallHigh", Vector3.new(roomWidth, 1.2, 0.42), roomRelativeCFrame(0, 4.35, -roomDepth / 2), trimColor, Enum.Material.Metal)
	createPart(suite, spec.Id .. "LeftWall", Vector3.new(0.42, roomHeight, roomDepth), roomRelativeCFrame(-roomWidth / 2, 1.45, 0), wallColor, Enum.Material.Metal)
	createPart(suite, spec.Id .. "RightWall", Vector3.new(0.42, roomHeight, roomDepth), roomRelativeCFrame(roomWidth / 2, 1.45, 0), wallColor, Enum.Material.Metal)

	local window = createPart(suite, spec.Id .. "ObservationWindow", Vector3.new(roomWidth - 1.6, 4.45, 0.22), roomRelativeCFrame(0, 1.45, -roomDepth / 2 - 0.04), Color3.fromRGB(126, 213, 232), Enum.Material.Glass)
	window.Transparency = 0.5
	window.Reflectance = 0.12
	window.CanCollide = false
	window:SetAttribute("BaseTransparency", window.Transparency)
	window:SetAttribute("BaseCanCollide", false)

	local console = createPart(suite, spec.Id .. "CoordinateConsole", Vector3.new(5.6, 1.0, 1.7), roomRelativeCFrame(0, -0.85, roomDepth / 2 - 1.35), Color3.fromRGB(23, 36, 42), Enum.Material.Metal)
	createSurfaceText(console, spec.Id .. "CoordinateText", spec.Label .. "\nTELEPORT COORDINATE", Enum.NormalId.Top, Color3.fromRGB(119, 255, 203), Color3.fromRGB(23, 36, 42))

	local status = createPart(suite, spec.Id .. "StatusPanel", Vector3.new(5.4, 2.2, 0.24), roomRelativeCFrame(0, 1.6, roomDepth / 2 - 0.24), Color3.fromRGB(14, 22, 26), Enum.Material.Metal)
	createSurfaceText(status, spec.Id .. "StatusText", "OBSERVATION\nROOM\nNO DOOR FILED", Enum.NormalId.Back, Color3.fromRGB(194, 255, 246), Color3.fromRGB(14, 22, 26))

	makeObservationTeleportPanel(
		suite,
		spec,
		roomRelativeCFrame(roomWidth / 2 - 0.28, 0.85, 1.25) * CFrame.Angles(0, math.rad(90), 0)
	)

	local light = Instance.new("PointLight")
	light.Name = spec.Id .. "ObservationStatusLight"
	light.Brightness = 0.75
	light.Color = Color3.fromRGB(119, 255, 203)
	light.Range = 11
	light.Parent = console
	mark(light)

	suite.PrimaryPart = console
	return suite
end

local function makeObservationSuites(parent)
	local observationRoot = makeModel(parent, "ObservationNetwork")
	observationRoot:SetAttribute("BunkerEnergyIgnored", true)
	for _, spec in ipairs(OBSERVATION_SUITES) do
		makeObservationSuite(observationRoot, spec)
	end
	return observationRoot
end

local function makeBunkerPowerMeter(parent, cframe, face)
	local meter = makeModel(parent, "BunkerPowerMeter")
	meter:SetAttribute("BunkerEnergyIgnored", true)

	local panel = createPart(meter, "BunkerPowerMeterPanel", Vector3.new(0.36, 5.4, 7.6), cframe, Color3.fromRGB(13, 18, 21), Enum.Material.Metal)
	panel:SetAttribute("BunkerEnergyIgnored", true)
	tag(panel, Constants.Tags.BunkerPowerMeter)
	createPrompt(panel, "Inspect", "Bunker Energy", 0.1)

	local gui = Instance.new("SurfaceGui")
	gui.Name = "BunkerPowerMeterSurfaceGui"
	gui.Face = face or Enum.NormalId.Left
	gui.LightInfluence = 0.05
	gui.PixelsPerStud = 70
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.Parent = panel
	mark(gui)

	local background = Instance.new("Frame")
	background.Name = "BunkerPowerMeterBackground"
	background.BackgroundColor3 = Color3.fromRGB(6, 10, 11)
	background.BorderSizePixel = 0
	background.Size = UDim2.fromScale(1, 1)
	background.Parent = gui
	mark(background)

	local title = Instance.new("TextLabel")
	title.Name = "BunkerPowerMeterTitle"
	title.BackgroundColor3 = Color3.fromRGB(36, 44, 50)
	title.BorderSizePixel = 0
	title.Font = Enum.Font.GothamBlack
	title.Position = UDim2.fromScale(0.05, 0.05)
	title.Size = UDim2.fromScale(0.9, 0.16)
	title.Text = "BUNKER POWER"
	title.TextColor3 = Color3.fromRGB(255, 235, 149)
	title.TextScaled = true
	title.TextWrapped = true
	title.Parent = background
	mark(title)

	local readout = Instance.new("TextLabel")
	readout.Name = "BunkerPowerMeterReadout"
	readout.BackgroundTransparency = 1
	readout.BorderSizePixel = 0
	readout.Font = Enum.Font.GothamBlack
	readout.Position = UDim2.fromScale(0.08, 0.25)
	readout.Size = UDim2.fromScale(0.84, 0.2)
	readout.Text = "POWER 18%"
	readout.TextColor3 = Color3.fromRGB(119, 255, 203)
	readout.TextScaled = true
	readout.TextWrapped = true
	readout.Parent = background
	mark(readout)

	local track = Instance.new("Frame")
	track.Name = "BunkerPowerMeterTrack"
	track.BackgroundColor3 = Color3.fromRGB(25, 32, 38)
	track.BorderSizePixel = 0
	track.Position = UDim2.fromScale(0.08, 0.51)
	track.Size = UDim2.fromScale(0.84, 0.12)
	track.Parent = background
	mark(track)

	local fill = Instance.new("Frame")
	fill.Name = "BunkerPowerMeterFillFrame"
	fill.BackgroundColor3 = Color3.fromRGB(119, 255, 203)
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0.18, 1)
	fill.Parent = track
	mark(fill)

	local hunger = Instance.new("TextLabel")
	hunger.Name = "BunkerPowerMeterState"
	hunger.BackgroundColor3 = Color3.fromRGB(39, 28, 24)
	hunger.BorderSizePixel = 0
	hunger.Font = Enum.Font.GothamBlack
	hunger.Position = UDim2.fromScale(0.08, 0.69)
	hunger.Size = UDim2.fromScale(0.84, 0.18)
	hunger.Text = "DRAW: QUIET"
	hunger.TextColor3 = Color3.fromRGB(255, 206, 116)
	hunger.TextScaled = true
	hunger.TextWrapped = true
	hunger.Parent = background
	mark(hunger)

	local status = Instance.new("TextLabel")
	status.Name = "BunkerPowerMeterStatus"
	status.BackgroundTransparency = 1
	status.BorderSizePixel = 0
	status.Font = Enum.Font.GothamBold
	status.Position = UDim2.fromScale(0.08, 0.88)
	status.Size = UDim2.fromScale(0.84, 0.08)
	status.Text = "WAITING FOR TOUCH INPUT"
	status.TextColor3 = Color3.fromRGB(180, 208, 220)
	status.TextScaled = true
	status.TextWrapped = true
	status.Parent = background
	mark(status)

	local glow = Instance.new("SurfaceLight")
	glow.Name = "BunkerPowerMeterGlow"
	glow.Face = face or Enum.NormalId.Left
	glow.Brightness = 0.8
	glow.Color = Color3.fromRGB(119, 255, 203)
	glow.Range = 9
	glow.Parent = panel
	mark(glow)

	meter.PrimaryPart = panel
	return meter
end

local function makeCaveElectricLight(parent, name, position, index)
	local lightModel = makeModel(parent, name)
	local cable = createPart(lightModel, name .. "Cable", Vector3.new(0.12, 1.7, 0.12), CFrame.new(position + Vector3.new(0, 1.03, 0)), Color3.fromRGB(24, 24, 28), Enum.Material.Metal)
	local shade = createPart(lightModel, name .. "Shade", Vector3.new(1.8, 0.35, 1.8), CFrame.new(position + Vector3.new(0, 0.32, 0)), Color3.fromRGB(52, 56, 61), Enum.Material.Metal)
	shade.Shape = Enum.PartType.Cylinder
	local bulb = createPart(lightModel, name .. "Bulb", Vector3.new(0.95, 0.95, 0.95), CFrame.new(position + Vector3.new(0, -0.12, 0)), Color3.fromRGB(255, 224, 145), Enum.Material.Neon)
	bulb.Shape = Enum.PartType.Ball
	bulb:SetAttribute("CaveLightIndex", index)
	bulb:SetAttribute("CaveLightColorIndex", 1)
	bulb:SetAttribute("PrologueDescription", "An electric bulb hangs from rough stone. It should not have power this far underground.")
	local pointLight = Instance.new("PointLight")
	pointLight.Name = "CaveBulbLight"
	pointLight.Brightness = if index == 1 then 2.8 else 1.8
	pointLight.Color = bulb.Color
	pointLight.Range = if index == 1 then 18 else 13
	pointLight.Parent = bulb
	mark(pointLight)
	local prompt = createPrompt(bulb, "Touch", if index == 1 then "First Electric Cave Light" else "Electric Cave Light", 0)
	prompt.MaxActivationDistance = 15
	tag(bulb, Constants.Tags.CaveLight)
	lightModel.PrimaryPart = bulb
	return lightModel
end

local function makeCaveSpike(parent, name, position, height, diameter, hangsDown)
	local spike = makeModel(parent, name)
	local direction = if hangsDown then -1 else 1
	local rootY = position.Y
	local spikeRotation = CFrame.Angles(0, 0, math.rad(90))

	for segmentIndex = 1, 3 do
		local segmentHeight = height * (0.42 - (segmentIndex - 1) * 0.08)
		local segmentDiameter = diameter * (1.05 - (segmentIndex - 1) * 0.26)
		local offset = (segmentIndex - 0.5) * height / 4
		local part = createPart(
			spike,
			name .. "Segment" .. segmentIndex,
			Vector3.new(segmentHeight, segmentDiameter, segmentDiameter),
			CFrame.new(position.X, rootY + direction * offset, position.Z) * spikeRotation,
			Color3.fromRGB(81, 78, 73),
			Enum.Material.Slate
		)
		part.Shape = Enum.PartType.Cylinder
	end

	local tip = createPart(
		spike,
		name .. "Tip",
		Vector3.new(diameter * 0.42, diameter * 0.42, diameter * 0.42),
		CFrame.new(position.X, rootY + direction * (height * 0.72), position.Z),
		Color3.fromRGB(100, 96, 89),
		Enum.Material.Slate
	)
	tip.Shape = Enum.PartType.Ball
	spike.PrimaryPart = tip
	return spike
end

local function makeCaveKeyShape(parent, name, cframe, scale, color, material)
	local key = makeModel(parent, name)
	scale = scale or 1
	color = color or Color3.fromRGB(255, 221, 84)
	material = material or Enum.Material.Neon

	local head = createPart(key, name .. "Head", Vector3.new(0.2 * scale, 1.65 * scale, 1.65 * scale), cframe * CFrame.new(0, 0, -1.45 * scale), color, material)
	head.Shape = Enum.PartType.Ball
	local shaft = createPart(key, name .. "Shaft", Vector3.new(0.18 * scale, 0.24 * scale, 3.2 * scale), cframe * CFrame.new(0, 0, 0.35 * scale), color, material)
	local toothA = createPart(key, name .. "ToothA", Vector3.new(0.18 * scale, 0.85 * scale, 0.24 * scale), cframe * CFrame.new(0, -0.48 * scale, 1.72 * scale), color, material)
	local toothB = createPart(key, name .. "ToothB", Vector3.new(0.18 * scale, 0.62 * scale, 0.24 * scale), cframe * CFrame.new(0, 0.42 * scale, 1.38 * scale), color, material)

	for _, part in ipairs({ head, shaft, toothA, toothB }) do
		part.CanCollide = false
		part:SetAttribute("BaseCanCollide", false)
	end

	key.PrimaryPart = shaft
	return key
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
	createDoubleSidedSurfaceText(door, "DoorText", label, face, Color3.fromRGB(232, 245, 255), Color3.fromRGB(38, 48, 64))

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

local function makeVictoryWalkway(parent)
	local walkway = makeModel(parent, "VictoryWalkway")

	local sign = createPart(walkway, "VictoryWalkwaySign", Vector3.new(7.6, 2.0, 0.28), CFrame.new(-46.8, 6.85, 45) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(255, 229, 161), Enum.Material.SmoothPlastic)
	sign.CanCollide = false
	sign:SetAttribute("BaseCanCollide", false)
	createDoubleSidedSurfaceText(sign, "VictoryWalkwaySignText", "VICTORY\nWALKWAY", Enum.NormalId.Front, Color3.fromRGB(71, 43, 29), Color3.fromRGB(255, 229, 161))

	local function makeVictoryBrickBorder(parentModel, slotIndex, brickCFrame)
		local borderColor = Constants.VictoryWalkway.GoldBorderColor or Color3.fromRGB(255, 213, 83)
		local borderParts = {
			{
				Name = "VictoryBrickBorderFront",
				Size = Vector3.new(2.58, 0.08, 0.08),
				CFrame = brickCFrame * CFrame.new(0, 0.1, -0.68),
			},
			{
				Name = "VictoryBrickBorderBack",
				Size = Vector3.new(2.58, 0.08, 0.08),
				CFrame = brickCFrame * CFrame.new(0, 0.1, 0.68),
			},
			{
				Name = "VictoryBrickBorderLeft",
				Size = Vector3.new(0.08, 0.08, 1.38),
				CFrame = brickCFrame * CFrame.new(-1.29, 0.1, 0),
			},
			{
				Name = "VictoryBrickBorderRight",
				Size = Vector3.new(0.08, 0.08, 1.38),
				CFrame = brickCFrame * CFrame.new(1.29, 0.1, 0),
			},
		}

		for index, borderData in ipairs(borderParts) do
			local border = createPart(parentModel, ("%s_%d_%d"):format(borderData.Name, slotIndex, index), borderData.Size, borderData.CFrame, borderColor, Enum.Material.Neon)
			border.CanCollide = false
			border.Transparency = 1
			border:SetAttribute("BaseCanCollide", false)
			border:SetAttribute("BaseTransparency", 1)
			border:SetAttribute("VictoryBrickSlotIndex", slotIndex)
			tag(border, Constants.Tags.VictoryBrickBorder)
		end
	end

	local slotIndex = 0
	for row = 1, 10 do
		for column = 1, 4 do
			slotIndex += 1
			local brickCFrame = CFrame.new(-62.4 + row * 3.0, 0.38, 40.9 + column * 1.65)
				* CFrame.Angles(0, math.rad(180), 0)
			local brick = createPart(
				walkway,
				("VictoryBrick_%d_%d"):format(row, column),
				Vector3.new(2.42, 0.16, 1.24),
				brickCFrame,
				if (row + column) % 2 == 0 then Color3.fromRGB(180, 96, 62) else Color3.fromRGB(124, 72, 48),
				Enum.Material.Brick
			)
			brick:SetAttribute("BaseCanCollide", false)
			brick:SetAttribute("PrologueInspectIgnore", true)
			brick:SetAttribute("VictoryBrickSlotIndex", slotIndex)
			brick:SetAttribute("VictoryBrickRow", row)
			brick:SetAttribute("VictoryBrickColumn", column)
			brick.CanCollide = false
			createSurfaceText(brick, "VictoryBrickText", Constants.VictoryWalkway.EmptyBrickText or "FUTURE\nWINNER", Enum.NormalId.Top, Color3.fromRGB(255, 226, 174), brick.Color)
			local prompt = createPrompt(brick, "Choose", "Deluxe Brick Spot", 0.12)
			prompt.MaxActivationDistance = 5
			prompt:SetAttribute("PrologueInspectIgnore", true)
			tag(brick, Constants.Tags.VictoryBrick)
			makeVictoryBrickBorder(walkway, slotIndex, brickCFrame)
		end
	end

	local stand = createPart(walkway, "VictoryBrickStand", Vector3.new(2.8, 2.0, 0.36), CFrame.new(-28.4, 2.55, 51.7) * CFrame.Angles(0, math.rad(180), 0), Color3.fromRGB(54, 42, 36), Enum.Material.Metal)
	createDoubleSidedSurfaceText(stand, "VictoryBrickStandText", "EARN OR\nBUY", Enum.NormalId.Front, Color3.fromRGB(255, 226, 174), Color3.fromRGB(54, 42, 36))
	createPrompt(stand, "Inspect", "Victory Brick Stand", 0.2)
	tag(stand, Constants.Tags.VictoryBrickStand)

	walkway.PrimaryPart = sign
	return walkway
end

local function makeRubberDuck(parent, name, cframe, scale)
	scale = scale or 1
	local duck = makeModel(parent, name)
	local body = createPart(duck, "DuckBody", Vector3.new(1.05 * scale, 0.64 * scale, 1.45 * scale), cframe, Color3.fromRGB(255, 221, 84), Enum.Material.SmoothPlastic)
	body.Shape = Enum.PartType.Ball
	body.CanCollide = false
	body:SetAttribute("BaseCanCollide", false)
	local head = createPart(duck, "DuckHead", Vector3.new(0.58 * scale, 0.58 * scale, 0.58 * scale), cframe * CFrame.new(0, 0.42 * scale, -0.56 * scale), Color3.fromRGB(255, 226, 91), Enum.Material.SmoothPlastic)
	head.Shape = Enum.PartType.Ball
	head.CanCollide = false
	head:SetAttribute("BaseCanCollide", false)
	local beak = createPart(duck, "DuckBeak", Vector3.new(0.44 * scale, 0.18 * scale, 0.32 * scale), cframe * CFrame.new(0, 0.4 * scale, -0.95 * scale), Color3.fromRGB(255, 134, 58), Enum.Material.SmoothPlastic)
	beak.CanCollide = false
	beak:SetAttribute("BaseCanCollide", false)
	local eyeA = createPart(duck, "DuckEyeA", Vector3.new(0.08 * scale, 0.08 * scale, 0.05 * scale), cframe * CFrame.new(-0.16 * scale, 0.55 * scale, -0.85 * scale), Color3.fromRGB(22, 22, 22), Enum.Material.SmoothPlastic)
	local eyeB = createPart(duck, "DuckEyeB", Vector3.new(0.08 * scale, 0.08 * scale, 0.05 * scale), cframe * CFrame.new(0.16 * scale, 0.55 * scale, -0.85 * scale), Color3.fromRGB(22, 22, 22), Enum.Material.SmoothPlastic)
	eyeA.CanCollide = false
	eyeB.CanCollide = false
	eyeA:SetAttribute("BaseCanCollide", false)
	eyeB:SetAttribute("BaseCanCollide", false)
	duck.PrimaryPart = body
	return duck
end

local function makeLowerTunnelBranch(parent)
	local tunnel = makeModel(parent, "LowerDuckPondTunnel")
	local wallColor = Color3.fromRGB(58, 66, 76)
	local floorColor = Color3.fromRGB(48, 55, 62)
	local waterColor = Color3.fromRGB(38, 125, 156)

	createPart(tunnel, "StairwellEntryFloor", Vector3.new(7.2, 0.45, 6.4), CFrame.new(-4.95, 0.32, 82), floorColor, Enum.Material.Concrete)
	createPart(tunnel, "StairwellDoorTop", Vector3.new(0.4, 2.0, 6.8), CFrame.new(-4.8, 7.8, 82), Color3.fromRGB(64, 81, 98), Enum.Material.Metal)
	createPart(tunnel, "StairwellDoorTrimA", Vector3.new(0.45, 8.6, 0.28), CFrame.new(-4.72, 4.3, 78.5), Color3.fromRGB(119, 255, 203), Enum.Material.Neon)
	createPart(tunnel, "StairwellDoorTrimB", Vector3.new(0.45, 8.6, 0.28), CFrame.new(-4.72, 4.3, 85.5), Color3.fromRGB(119, 255, 203), Enum.Material.Neon)
	createPart(tunnel, "StairwellEntryLeftWall", Vector3.new(7.2, 7.6, 0.42), CFrame.new(-7.1, 3.8, 78.55), wallColor, Enum.Material.Concrete)
	createPart(tunnel, "StairwellEntryRightWall", Vector3.new(7.2, 7.6, 0.42), CFrame.new(-7.1, 3.8, 85.45), wallColor, Enum.Material.Concrete)
	createPart(tunnel, "StairwellEntryCeiling", Vector3.new(7.6, 0.42, 7.2), CFrame.new(-7.1, 7.6, 82), Color3.fromRGB(34, 39, 46), Enum.Material.Concrete)
	local stairSign = createPart(tunnel, "LowerTunnelEntrySign", Vector3.new(0.32, 2.4, 5.2), CFrame.new(-4.95, 6.85, 82), Color3.fromRGB(255, 229, 161), Enum.Material.SmoothPlastic)
	stairSign.CanCollide = false
	stairSign:SetAttribute("BaseCanCollide", false)
	createDoubleSidedSurfaceText(stairSign, "LowerTunnelEntrySignText", "STAIRS\nDOWN", Enum.NormalId.Right, Color3.fromRGB(56, 45, 31), Color3.fromRGB(255, 229, 161))

	for stepIndex = 1, 12 do
		local alpha = stepIndex / 12
		createPart(
			tunnel,
			"FirstFlightStep" .. stepIndex,
			Vector3.new(0.86, 0.28, 4.8),
			CFrame.new(-8.1 - stepIndex * 0.78, 0.32 - alpha * 4.1, 82),
			Color3.fromRGB(86, 93, 103),
			Enum.Material.Concrete
		)
	end
	createPart(tunnel, "FirstFlightLeftWall", Vector3.new(10.8, 11.2, 0.38), CFrame.new(-13.2, 1.05, 78.72), wallColor, Enum.Material.Concrete)
	createPart(tunnel, "FirstFlightRightWall", Vector3.new(10.8, 11.2, 0.38), CFrame.new(-13.2, 1.05, 85.28), wallColor, Enum.Material.Concrete)
	createPart(tunnel, "FirstFlightLowCeiling", Vector3.new(10.8, 0.38, 6.9), CFrame.new(-13.2, 6.35, 82), Color3.fromRGB(31, 36, 43), Enum.Material.Concrete)

	local landing = createPart(tunnel, "MiddleLanding", Vector3.new(5.6, 0.42, 6.6), CFrame.new(-18.45, -3.92, 82), floorColor, Enum.Material.Concrete)
	createPart(tunnel, "MiddleLandingLeftWall", Vector3.new(0.38, 7.4, 7.0), CFrame.new(-21.45, -0.45, 82), wallColor, Enum.Material.Concrete)
	createPart(tunnel, "MiddleLandingRightWall", Vector3.new(0.38, 7.4, 7.0), CFrame.new(-15.45, -0.45, 82), wallColor, Enum.Material.Concrete)
	createPart(tunnel, "MiddleLandingCeiling", Vector3.new(6.4, 0.38, 7.0), CFrame.new(-18.45, 3.55, 82), Color3.fromRGB(31, 36, 43), Enum.Material.Concrete)
	local landingLight = createPart(tunnel, "MiddleLandingLight", Vector3.new(1.15, 1.15, 1.15), CFrame.new(-18.45, 1.6, 82), Color3.fromRGB(255, 232, 92), Enum.Material.Neon)
	landingLight.Shape = Enum.PartType.Ball
	local pointLight = Instance.new("PointLight")
	pointLight.Name = "MiddleLandingPointLight"
	pointLight.Brightness = 2.3
	pointLight.Color = Color3.fromRGB(255, 232, 122)
	pointLight.Range = 20
	pointLight.Parent = landingLight
	mark(pointLight)

	for stepIndex = 1, 12 do
		local alpha = stepIndex / 12
		createPart(
			tunnel,
			"SecondFlightStep" .. stepIndex,
			Vector3.new(4.8, 0.28, 0.86),
			CFrame.new(-18.45, -3.92 - alpha * 4.6, 81.4 - stepIndex * 0.92),
			Color3.fromRGB(76, 84, 96),
			Enum.Material.Concrete
		)
	end
	createPart(tunnel, "SecondFlightLeftWall", Vector3.new(0.38, 10.8, 12.8), CFrame.new(-21.45, -2.7, 75.8), wallColor, Enum.Material.Concrete)
	createPart(tunnel, "SecondFlightRightWall", Vector3.new(0.38, 10.8, 12.8), CFrame.new(-15.45, -2.7, 75.8), wallColor, Enum.Material.Concrete)
	createPart(tunnel, "SecondFlightLowCeiling", Vector3.new(6.4, 0.38, 12.8), CFrame.new(-18.45, 2.45, 75.8), Color3.fromRGB(27, 33, 40), Enum.Material.Concrete)

	local lowerLanding = createPart(tunnel, "LowerLanding", Vector3.new(7.2, 0.42, 6.8), CFrame.new(-18.45, -8.82, 68), floorColor, Enum.Material.Concrete)
	createPart(tunnel, "LowerLandingLeftWall", Vector3.new(0.38, 7.6, 7.0), CFrame.new(-22.2, -5.1, 68), wallColor, Enum.Material.Concrete)
	createPart(tunnel, "LowerLandingRightWall", Vector3.new(0.38, 7.6, 7.0), CFrame.new(-14.7, -5.1, 68), wallColor, Enum.Material.Concrete)
	createPart(tunnel, "LowerLandingCeiling", Vector3.new(8.0, 0.38, 7.0), CFrame.new(-18.45, -1.15, 68), Color3.fromRGB(25, 31, 38), Enum.Material.Concrete)
	local lowerLandingLight = createPart(tunnel, "LowerLandingLight", Vector3.new(1.15, 1.15, 1.15), CFrame.new(-18.45, -3.3, 68), Color3.fromRGB(119, 255, 203), Enum.Material.Neon)
	lowerLandingLight.Shape = Enum.PartType.Ball
	local lowerPointLight = Instance.new("PointLight")
	lowerPointLight.Name = "LowerLandingPointLight"
	lowerPointLight.Brightness = 2.1
	lowerPointLight.Color = Color3.fromRGB(119, 255, 203)
	lowerPointLight.Range = 20
	lowerPointLight.Parent = lowerLandingLight
	mark(lowerPointLight)

	for stepIndex = 1, 12 do
		local alpha = stepIndex / 12
		createPart(
			tunnel,
			"ThirdFlightStep" .. stepIndex,
			Vector3.new(4.8, 0.28, 0.86),
			CFrame.new(-18.45, -8.82 - alpha * 4.6, 67.4 - stepIndex * 0.92),
			Color3.fromRGB(67, 75, 86),
			Enum.Material.Concrete
		)
	end
	createPart(tunnel, "ThirdFlightLeftWall", Vector3.new(0.38, 10.8, 12.8), CFrame.new(-21.45, -7.4, 61.8), wallColor, Enum.Material.Concrete)
	createPart(tunnel, "ThirdFlightRightWall", Vector3.new(0.38, 10.8, 12.8), CFrame.new(-15.45, -7.4, 61.8), wallColor, Enum.Material.Concrete)
	createPart(tunnel, "ThirdFlightLowCeiling", Vector3.new(6.4, 0.38, 12.8), CFrame.new(-18.45, -2.1, 61.8), Color3.fromRGB(24, 30, 37), Enum.Material.Concrete)

	local lowerTunnelCenterX = -45.45
	local lowerTunnelShiftX = lowerTunnelCenterX + 18.45
	local fourthLanding = createPart(tunnel, "FourthTurnLanding", Vector3.new(7.2, 0.42, 7.0), CFrame.new(-18.45, -13.72, 54), floorColor, Enum.Material.Concrete)
	createPart(tunnel, "FourthTurnLandingLeftWall", Vector3.new(7.6, 8.2, 0.38), CFrame.new(-18.45, -9.8, 50.35), wallColor, Enum.Material.Concrete)
	createPart(tunnel, "FourthTurnLandingRightWall", Vector3.new(7.6, 8.2, 0.38), CFrame.new(-18.45, -9.8, 57.65), wallColor, Enum.Material.Concrete)
	createPart(tunnel, "FourthTurnLandingCeiling", Vector3.new(7.8, 0.38, 7.4), CFrame.new(-18.45, -5.45, 54), Color3.fromRGB(23, 29, 36), Enum.Material.Concrete)
	for stepIndex = 1, 14 do
		local alpha = stepIndex / 14
		createPart(
			tunnel,
			"FourthFlightStep" .. stepIndex,
			Vector3.new(0.86, 0.28, 4.8),
			CFrame.new(-20.2 - stepIndex * 1.72, -13.72 - alpha * 0.35, 54),
			Color3.fromRGB(61, 70, 82),
			Enum.Material.Concrete
		)
	end
	createPart(tunnel, "FourthFlightLeftWall", Vector3.new(27.5, 8.6, 0.38), CFrame.new(-33.4, -9.92, 50.72), wallColor, Enum.Material.Concrete)
	createPart(tunnel, "FourthFlightRightWall", Vector3.new(27.5, 8.6, 0.38), CFrame.new(-33.4, -9.92, 57.28), wallColor, Enum.Material.Concrete)
	createPart(tunnel, "FourthFlightLowCeiling", Vector3.new(27.5, 0.38, 6.9), CFrame.new(-33.4, -5.65, 54), Color3.fromRGB(22, 28, 35), Enum.Material.Concrete)
	createPart(tunnel, "LowerTunnelEntryLanding", Vector3.new(8.2, 0.42, 7.0), CFrame.new(lowerTunnelCenterX, -14.07, 54), floorColor, Enum.Material.Concrete)
	createPart(tunnel, "LowerTunnelEntryLandingLeftWall", Vector3.new(8.6, 8.4, 0.38), CFrame.new(lowerTunnelCenterX, -10.02, 50.35), wallColor, Enum.Material.Concrete)
	createPart(tunnel, "LowerTunnelEntryLandingRightWall", Vector3.new(8.6, 8.4, 0.38), CFrame.new(lowerTunnelCenterX, -10.02, 57.65), wallColor, Enum.Material.Concrete)
	createPart(tunnel, "LowerTunnelEntryLandingCeiling", Vector3.new(8.8, 0.38, 7.4), CFrame.new(lowerTunnelCenterX, -5.65, 54), Color3.fromRGB(22, 28, 35), Enum.Material.Concrete)

	createPart(tunnel, "LowerTunnelFloor", Vector3.new(28, 0.7, 58), CFrame.new(lowerTunnelCenterX, -13.72, 25), Color3.fromRGB(37, 43, 50), Enum.Material.Concrete)
	createPart(tunnel, "LowerTunnelCeiling", Vector3.new(28, 0.7, 58), CFrame.new(lowerTunnelCenterX, -5.25, 25), Color3.fromRGB(26, 31, 38), Enum.Material.Concrete)
	createPart(tunnel, "LowerTunnelLeftWall", Vector3.new(0.8, 8.8, 58), CFrame.new(lowerTunnelCenterX - 14, -9.5, 25), wallColor, Enum.Material.Concrete)
	createPart(tunnel, "LowerTunnelRightWall", Vector3.new(0.8, 8.8, 58), CFrame.new(lowerTunnelCenterX + 14, -9.5, 25), wallColor, Enum.Material.Concrete)
	createPart(tunnel, "LowerTunnelWalkway", Vector3.new(5.6, 0.24, 42), CFrame.new(lowerTunnelCenterX, -13.22, 18), Color3.fromRGB(74, 82, 92), Enum.Material.Metal)
	createPart(tunnel, "LowerTunnelRailLeft", Vector3.new(0.22, 1.3, 42), CFrame.new(lowerTunnelCenterX - 3, -12.36, 18), Color3.fromRGB(119, 255, 203), Enum.Material.Neon)
	createPart(tunnel, "LowerTunnelRailRight", Vector3.new(0.22, 1.3, 42), CFrame.new(lowerTunnelCenterX + 3, -12.36, 18), Color3.fromRGB(119, 255, 203), Enum.Material.Neon)

	for _, pond in ipairs({
		{ Name = "LeftRetainingPond", X = -26.7 + lowerTunnelShiftX },
		{ Name = "RightRetainingPond", X = -10.2 + lowerTunnelShiftX },
	}) do
		local water = createPart(tunnel, pond.Name, Vector3.new(8.8, 0.16, 34), CFrame.new(pond.X, -13.1, 17), waterColor, Enum.Material.Glass)
		water.Transparency = 0.2
		water:SetAttribute("BaseTransparency", water.Transparency)
		createPart(tunnel, pond.Name .. "DarkEndA", Vector3.new(8.8, 3.5, 0.32), CFrame.new(pond.X, -11.55, 0), Color3.fromRGB(4, 7, 12), Enum.Material.SmoothPlastic)
		createPart(tunnel, pond.Name .. "DarkEndB", Vector3.new(8.8, 3.5, 0.32), CFrame.new(pond.X, -11.55, 34), Color3.fromRGB(4, 7, 12), Enum.Material.SmoothPlastic)
	end

	for duckIndex, data in ipairs({
		{ X = -26.3 + lowerTunnelShiftX, Z = 11.5, Yaw = 18 },
		{ X = -29.0 + lowerTunnelShiftX, Z = 23.0, Yaw = -22 },
		{ X = -10.0 + lowerTunnelShiftX, Z = 13.0, Yaw = 35 },
		{ X = -7.7 + lowerTunnelShiftX, Z = 28.2, Yaw = -35 },
	}) do
		makeRubberDuck(tunnel, "LowerTunnelRubberDuck" .. duckIndex, CFrame.new(data.X, -12.76, data.Z) * CFrame.Angles(0, math.rad(data.Yaw), 0), 0.88)
	end

	local duckStand = createPart(tunnel, "ContributorDuckStand", Vector3.new(4.8, 2.2, 0.36), CFrame.new(lowerTunnelCenterX, -11.62, 37.3), Color3.fromRGB(28, 72, 82), Enum.Material.Metal)
	duckStand.CanCollide = false
	duckStand:SetAttribute("BaseCanCollide", false)
	createSurfaceText(duckStand, "ContributorDuckStandText", "DUCK\nFOUNDER\n80,000 R$", Enum.NormalId.Front, Color3.fromRGB(196, 249, 255), Color3.fromRGB(28, 72, 82))
	createPrompt(duckStand, "Inspect", "Name a Duck", 0.2)
	tag(duckStand, Constants.Tags.ContributorDuckStand)

	local blastLeft = createPart(tunnel, "LowerBlastDoorLeft", Vector3.new(7.2, 8.1, 0.5), CFrame.new(lowerTunnelCenterX - 3.75, -9.45, -2.2), Color3.fromRGB(84, 90, 99), Enum.Material.Metal)
	local blastRight = createPart(tunnel, "LowerBlastDoorRight", Vector3.new(7.2, 8.1, 0.5), CFrame.new(lowerTunnelCenterX + 3.75, -9.45, -2.2), Color3.fromRGB(84, 90, 99), Enum.Material.Metal)
	local blastCenter = createPart(tunnel, "LowerBlastDoorWarningSeal", Vector3.new(3.2, 3.2, 0.58), CFrame.new(lowerTunnelCenterX, -9.45, -2.55), Color3.fromRGB(255, 221, 84), Enum.Material.Neon)
	blastCenter.Shape = Enum.PartType.Cylinder
	blastCenter:SetAttribute("PrologueDescription", "The blast doors are not part of a cave. That is the first truly bad sign.")
	createSurfaceText(blastCenter, "BlastDoorWarningText", "?", Enum.NormalId.Front, Color3.fromRGB(34, 28, 16), Color3.fromRGB(255, 221, 84))
	createPrompt(blastCenter, "Inspect", "Blast Doors", 0)
	tag(blastCenter, Constants.Tags.LowerTunnelBlastDoor)
	createPart(tunnel, "BlastDoorFrameTop", Vector3.new(16, 0.5, 0.8), CFrame.new(lowerTunnelCenterX, -5.25, -2.2), Color3.fromRGB(24, 28, 34), Enum.Material.Metal)
	createPart(tunnel, "BlastDoorFrameLeft", Vector3.new(0.5, 8.6, 0.8), CFrame.new(lowerTunnelCenterX - 8, -9.45, -2.2), Color3.fromRGB(24, 28, 34), Enum.Material.Metal)
	createPart(tunnel, "BlastDoorFrameRight", Vector3.new(0.5, 8.6, 0.8), CFrame.new(lowerTunnelCenterX + 8, -9.45, -2.2), Color3.fromRGB(24, 28, 34), Enum.Material.Metal)
	createSurfaceText(blastLeft, "BlastLeftText", "AUTHORIZED\nTO TOUCH\nNOTHING", Enum.NormalId.Front, Color3.fromRGB(235, 245, 255), Color3.fromRGB(84, 90, 99))
	createSurfaceText(blastRight, "BlastRightText", "BLAST\nDOORS", Enum.NormalId.Front, Color3.fromRGB(235, 245, 255), Color3.fromRGB(84, 90, 99))

	tunnel.PrimaryPart = fourthLanding
	return tunnel
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
	back.CanQuery = false
	back:SetAttribute("BaseCanQuery", false)
	clip.CanCollide = false
	clip:SetAttribute("BaseCanCollide", false)
	clip.CanQuery = false
	clip:SetAttribute("BaseCanQuery", false)

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
		cframe * CFrame.new(0, -0.27, -0.18) * CFrame.Angles(math.rad(90), 0, 0),
		Color3.fromRGB(255, 221, 84),
		Enum.Material.Neon
	)
	button.Shape = Enum.PartType.Cylinder

	local resetLabel =
		createSurfaceText(plate, "ResetButtonText", "RESET", Enum.NormalId.Front, Color3.fromRGB(255, 242, 181), Color3.fromRGB(42, 47, 56))
	resetLabel.Position = UDim2.fromScale(0, 0.04)
	resetLabel.Size = UDim2.fromScale(1, 0.46)
	local prompt = createPrompt(button, "Reset", promptObjectText or "Room Reset", 0.2)
	prompt.MaxActivationDistance = 7
	tag(button, Constants.Tags.ResetRoomButton)

	resetModel.PrimaryPart = plate
	return resetModel
end

local function makeCompactPanelButton(parent, name, cframe, labelText, actionText, objectText, color, tagName)
	local buttonModel = makeModel(parent, name)
	local plate = createPart(
		buttonModel,
		"PanelButtonPlate",
		Vector3.new(1.2, 0.78, 0.12),
		cframe,
		Color3.fromRGB(38, 44, 54),
		Enum.Material.Metal
	)
	local button = createPart(
		buttonModel,
		"PanelButton",
		Vector3.new(0.68, 0.18, 0.68),
		cframe * CFrame.new(0, -0.24, -0.18) * CFrame.Angles(math.rad(90), 0, 0),
		color or Color3.fromRGB(119, 255, 203),
		Enum.Material.Neon
	)
	button.Shape = Enum.PartType.Cylinder
	button.CanQuery = false
	button:SetAttribute("BaseCanQuery", false)

	local label = createSurfaceText(plate, name .. "Text", labelText, Enum.NormalId.Front, color or Color3.fromRGB(119, 255, 203), Color3.fromRGB(42, 47, 56))
	label.Position = UDim2.fromScale(0, 0.04)
	label.Size = UDim2.fromScale(1, 0.46)
	local lowerGlow = createPart(
		buttonModel,
		"PanelButtonLowerGlow",
		Vector3.new(0.74, 0.08, 0.05),
		cframe * CFrame.new(0, -0.26, -0.24),
		color or Color3.fromRGB(119, 255, 203),
		Enum.Material.Neon
	)
	lowerGlow.CanCollide = false
	lowerGlow:SetAttribute("BaseCanCollide", false)
	lowerGlow.CanQuery = false
	lowerGlow:SetAttribute("BaseCanQuery", false)
	local prompt = createPrompt(plate, actionText, objectText, 0.2)
	prompt.MaxActivationDistance = 7
	if tagName then
		tag(plate, tagName)
	end

	buttonModel.PrimaryPart = plate
	return buttonModel, plate
end

local function makePanelReadout(parent, name, cframe, size, text, textColor, backgroundColor)
	local readout = createPart(
		parent,
		name,
		size,
		cframe,
		backgroundColor or Color3.fromRGB(6, 12, 15),
		Enum.Material.Neon
	)
	readout.CanCollide = false
	readout:SetAttribute("BaseCanCollide", false)

	local label = createSurfaceText(
		readout,
		name .. "Text",
		text,
		Enum.NormalId.Front,
		textColor or Color3.fromRGB(205, 255, 218),
		backgroundColor or Color3.fromRGB(6, 12, 15)
	)
	label.Font = Enum.Font.GothamBold
	return readout
end

local function makePanelBezel(parent, name, cframe, panelWidth, panelHeight)
	local bezelColor = Color3.fromRGB(48, 58, 70)
	local accentColor = Color3.fromRGB(119, 255, 232)

	local pieces = {
		{
			Name = "Top",
			Size = Vector3.new(panelWidth + 0.16, 0.08, 0.08),
			CFrame = cframe * CFrame.new(0, panelHeight / 2 + 0.02, -0.25),
			Color = bezelColor,
			Material = Enum.Material.Metal,
		},
		{
			Name = "Bottom",
			Size = Vector3.new(panelWidth + 0.16, 0.08, 0.08),
			CFrame = cframe * CFrame.new(0, -panelHeight / 2 - 0.02, -0.25),
			Color = bezelColor,
			Material = Enum.Material.Metal,
		},
		{
			Name = "Left",
			Size = Vector3.new(0.08, panelHeight + 0.16, 0.08),
			CFrame = cframe * CFrame.new(-panelWidth / 2 - 0.02, 0, -0.25),
			Color = bezelColor,
			Material = Enum.Material.Metal,
		},
		{
			Name = "Right",
			Size = Vector3.new(0.08, panelHeight + 0.16, 0.08),
			CFrame = cframe * CFrame.new(panelWidth / 2 + 0.02, 0, -0.25),
			Color = bezelColor,
			Material = Enum.Material.Metal,
		},
		{
			Name = "Signal",
			Size = Vector3.new(0.08, panelHeight - 0.44, 0.07),
			CFrame = cframe * CFrame.new(panelWidth / 2 - 0.24, -0.02, -0.32),
			Color = accentColor,
			Material = Enum.Material.Neon,
		},
	}

	for _, piece in ipairs(pieces) do
		local part = createPart(parent, name .. piece.Name, piece.Size, piece.CFrame, piece.Color, piece.Material)
		part.CanCollide = false
		part:SetAttribute("BaseCanCollide", false)
		part.CanQuery = false
		part:SetAttribute("BaseCanQuery", false)
	end

	for index, offset in ipairs({
		Vector3.new(-panelWidth / 2 + 0.26, panelHeight / 2 - 0.24, -0.33),
		Vector3.new(panelWidth / 2 - 0.26, panelHeight / 2 - 0.24, -0.33),
		Vector3.new(-panelWidth / 2 + 0.26, -panelHeight / 2 + 0.24, -0.33),
		Vector3.new(panelWidth / 2 - 0.26, -panelHeight / 2 + 0.24, -0.33),
	}) do
		local rivet = createPart(
			parent,
			name .. "Rivet" .. index,
			Vector3.new(0.14, 0.14, 0.06),
			cframe * CFrame.new(offset) * CFrame.Angles(math.rad(90), 0, 0),
			Color3.fromRGB(124, 137, 151),
			Enum.Material.Metal
		)
		rivet.Shape = Enum.PartType.Cylinder
		rivet.CanCollide = false
		rivet:SetAttribute("BaseCanCollide", false)
		rivet.CanQuery = false
		rivet:SetAttribute("BaseCanQuery", false)
	end
end

local function makeRoomControlPanel(parent, name, panelCFrame, roomId, title, options)
	options = options or {}
	local includeReset = options.IncludeReset == true
	local includeLightSwitch = options.IncludeLightSwitch ~= false
	local panelWidth = options.PanelWidth or (includeReset and 5.15 or 4.75)
	local panelHeight = options.PanelHeight or (includeReset and 6.35 or 5.85)
	local panelLabel = options.PanelLabel or "ROOM CONSOLE"
	local controls = makeModel(parent, name)
	controls:SetAttribute("StrictPromptTargets", true)

	local panel = createPart(
		controls,
		"ControlPanelBack",
		Vector3.new(panelWidth, panelHeight, 0.22),
		panelCFrame,
		Color3.fromRGB(24, 31, 39),
		Enum.Material.Metal
	)
	panel.CanQuery = false
	panel:SetAttribute("BaseCanQuery", false)
	makePanelBezel(controls, "ControlPanelBezel", panelCFrame, panelWidth, panelHeight)
	local titleStrip = createPart(
		controls,
		"ControlPanelTitleStrip",
		Vector3.new(panelWidth - 0.4, 0.36, 0.08),
		panelCFrame * CFrame.new(0, panelHeight / 2 - 0.28, -0.18),
		Color3.fromRGB(55, 66, 80),
		Enum.Material.SmoothPlastic
	)
	titleStrip.CanQuery = false
	titleStrip:SetAttribute("BaseCanQuery", false)
	createSurfaceText(titleStrip, "ControlPanelTitle", panelLabel, Enum.NormalId.Front, Color3.fromRGB(236, 245, 255), Color3.fromRGB(62, 69, 82))
	local topGlow = createPart(
		controls,
		"ControlPanelTopGlow",
		Vector3.new(panelWidth - 0.55, 0.06, 0.06),
		panelCFrame * CFrame.new(0, panelHeight / 2 - 0.52, -0.24),
		Color3.fromRGB(119, 255, 232),
		Enum.Material.Neon
	)
	topGlow.CanCollide = false
	topGlow:SetAttribute("BaseCanCollide", false)
	topGlow.CanQuery = false
	topGlow:SetAttribute("BaseCanQuery", false)

	local rewardReadout = makePanelReadout(
		controls,
		"ControlPanelRewardReadout",
		panelCFrame * CFrame.new(0, panelHeight / 2 - 0.92, -0.22),
		Vector3.new(panelWidth - 0.78, 0.56, 0.08),
		"REWARDS\n5m=HINTS  2m=STILL",
		Color3.fromRGB(255, 242, 181),
		Color3.fromRGB(13, 21, 22)
	)
	rewardReadout.CanQuery = false
	rewardReadout:SetAttribute("BaseCanQuery", false)

	local logX = if includeReset then -1.16 else -1.05
	local logY = panelHeight / 2 - 2.22
	local referenceBook = makeCompactReferenceBook(
		controls,
		name .. "Log",
		panelCFrame * CFrame.new(logX, logY, -0.22),
		roomId,
		title,
		{
			Height = if includeReset then 1.5 else 1.35,
			Text = options.LogText,
			MaxActivationDistance = options.LogPromptDistance or 7,
		}
	)

	local lightSwitch = nil
	if includeLightSwitch then
		lightSwitch = makeLightSwitch(
			controls,
			name .. "LightSwitch",
			panelCFrame * CFrame.new(if includeReset then 1.48 else 1.34, logY + 0.32, -0.22),
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
			panelCFrame * CFrame.new(1.48, logY - 0.82, -0.22),
			options.ResetPromptObjectText or "Room Reset"
		)
	end

	local commandButtonX = 0
	local commandButtonTopY = if includeReset then -0.95 else -0.7
	local commandButtonSpacing = 0.84

	local storeButtonModel, storeButton = makeCompactPanelButton(
		controls,
		name .. "StoreButton",
		panelCFrame * CFrame.new(commandButtonX, commandButtonTopY, -0.22),
		"REWARD",
		"Open",
		"Rewards & Store",
		Color3.fromRGB(255, 221, 84),
		Constants.Tags.StoreButton
	)
	storeButton:SetAttribute("RoomId", roomId)

	local teleportButtonModel, teleportButton = makeCompactPanelButton(
		controls,
		name .. "TeleportButton",
		panelCFrame * CFrame.new(commandButtonX, commandButtonTopY - commandButtonSpacing, -0.22),
		"TELE",
		"Open",
		"Teleport",
		Color3.fromRGB(119, 255, 203),
		Constants.Tags.TeleportButton
	)
	teleportButton:SetAttribute("RoomId", roomId)

	local fieldButtonModel, fieldButton = makeCompactPanelButton(
		controls,
		name .. "FieldButton",
		panelCFrame * CFrame.new(commandButtonX, commandButtonTopY - commandButtonSpacing * 2, -0.22),
		"FIELD",
		"Open",
		"Field Controls",
		Color3.fromRGB(185, 130, 255),
		Constants.Tags.FieldButton
	)
	fieldButton:SetAttribute("RoomId", roomId)

	controls.PrimaryPart = panel
	return {
		Model = controls,
		Panel = panel,
		ReferenceBook = referenceBook,
		LightSwitch = lightSwitch,
		ResetRoomButton = resetRoomButton,
		StoreButton = storeButtonModel,
		TeleportButton = teleportButtonModel,
		FieldButton = fieldButtonModel,
	}
end

local function makeCaveEntranceArea(roomFolder)
	local cave = makeModel(roomFolder, "CaveEntranceArea")

	local forestFloor = createPart(cave, "ForestFloor", Vector3.new(64, 1, 38), CFrame.new(-42, -0.25, 45), Color3.fromRGB(35, 64, 43), Enum.Material.Grass)
	forestFloor:SetAttribute("BaseCanCollide", true)
	forestFloor:SetAttribute("PrologueDescription", "Damp grass presses flat around you, as if you arrived all at once.")
	createSoundSourceAnchor(cave, "OutsideCaveSoundSource", CFrame.new(-56, 3.2, 45))
	local caveSpawn = createSpawnLocation(cave, "CaveEntranceSpawn", "CaveEntrance", CAVE_SPAWN_CFRAME, Color3.fromRGB(82, 156, 88), false)
	caveSpawn.Transparency = 1
	caveSpawn.CanQuery = false
	caveSpawn:SetAttribute("BaseTransparency", 1)
	caveSpawn:SetAttribute("PrologueInspectIgnore", true)

	local flashlightPickup = makeModel(cave, "StartingFlashlightPickup")
	flashlightPickup:SetAttribute("PrologueDescription", "A flashlight waits by the cave mouth. It feels like permission to look, not permission to touch anything else.")
	flashlightPickup:SetAttribute("ProloguePriority", 120)
	flashlightPickup:SetAttribute("TutorialId", "StartingFlashlightPickup")
	flashlightPickup:SetAttribute("TutorialHint", "Take the flashlight. Equip it from inventory, then press Action to turn it on or off.")
	flashlightPickup:SetAttribute("PrologueSafeNavigation", true)
	local flashlightStand = createPart(flashlightPickup, "FlashlightRockStand", Vector3.new(2.8, 0.7, 1.9), CFrame.new(-64.2, 0.52, 39.2) * CFrame.Angles(0, math.rad(-8), 0), Color3.fromRGB(70, 70, 66), Enum.Material.Slate)
	flashlightStand.CanCollide = false
	flashlightStand:SetAttribute("BaseCanCollide", false)
	local flashlightCFrame = CFrame.new(-64.2, 1.12, 39.2) * CFrame.Angles(0, math.rad(-20), math.rad(90))
	local flashlightBody = createPart(flashlightPickup, "FlashlightBody", Vector3.new(1.35, 0.34, 0.34), flashlightCFrame, Color3.fromRGB(41, 44, 48), Enum.Material.Metal)
	flashlightBody.Shape = Enum.PartType.Cylinder
	flashlightBody.CanCollide = false
	flashlightBody:SetAttribute("BaseCanCollide", false)
	local flashlightLens = createPart(flashlightPickup, "FlashlightLens", Vector3.new(0.12, 0.44, 0.44), flashlightCFrame * CFrame.new(-0.68, 0, 0), Color3.fromRGB(197, 232, 255), Enum.Material.Glass)
	flashlightLens.Shape = Enum.PartType.Cylinder
	flashlightLens.Transparency = 0.18
	flashlightLens.CanCollide = false
	flashlightLens:SetAttribute("BaseCanCollide", false)
	flashlightLens:SetAttribute("BaseTransparency", 0.18)
	local flashlightPrompt = createPrompt(flashlightBody, "Take", "Flashlight", 0)
	flashlightPrompt.MaxActivationDistance = 12
	flashlightPrompt.RequiresLineOfSight = false
	flashlightPrompt:SetAttribute("PrologueSafeNavigation", true)
	flashlightPrompt:SetAttribute("TutorialId", "StartingFlashlightPickup")
	flashlightPrompt:SetAttribute("TutorialHint", "Take the flashlight. Equip it from inventory, then press Action to turn it on or off.")
	flashlightPickup.PrimaryPart = flashlightBody
	tag(flashlightPickup, Constants.Tags.StartingFlashlight)

	for _, backdrop in ipairs({
		{ Name = "CaveNightBackdropEast", Size = Vector3.new(0.5, 27, 46), CFrame = CFrame.new(-9.7, 12.5, 45) },
		{ Name = "CaveNightBackdropWestLeft", Size = Vector3.new(0.5, 10.5, 9.8), CFrame = CFrame.new(-74.25, 5.0, 30.2) },
		{ Name = "CaveNightBackdropWestRight", Size = Vector3.new(0.5, 10.5, 9.8), CFrame = CFrame.new(-74.25, 5.0, 59.8) },
		{ Name = "CaveNightBackdropWestUpper", Size = Vector3.new(0.5, 17.5, 46), CFrame = CFrame.new(-74.25, 16.9, 45) },
		{ Name = "CaveNightBackdropNorth", Size = Vector3.new(65, 27, 0.5), CFrame = CFrame.new(-42, 12.5, 24.8) },
		{ Name = "CaveNightBackdropSouth", Size = Vector3.new(65, 27, 0.5), CFrame = CFrame.new(-42, 12.5, 65.2) },
		{ Name = "CaveNightBackdropCanopy", Size = Vector3.new(65, 0.5, 46), CFrame = CFrame.new(-42, 25.6, 45) },
	}) do
		local panel = createPart(cave, backdrop.Name, backdrop.Size, backdrop.CFrame, Color3.fromRGB(6, 12, 31), Enum.Material.SmoothPlastic)
		if backdrop.NoCollide then
			panel.CanCollide = false
			panel:SetAttribute("BaseCanCollide", false)
		else
			panel:SetAttribute("BaseCanCollide", true)
		end
	end

	for starIndex = 1, 78 do
		local side = ((starIndex - 1) % 4) + 1
		local starX = -36 - ((starIndex * 7) % 34)
		local starY = 17 + ((starIndex * 11) % 7)
		local starZ = 27 + ((starIndex * 13) % 36)
		local starCFrame = if side == 1
			then CFrame.new(-10.05, starY, starZ)
			elseif side == 2 then CFrame.new(starX, starY, 25.05)
			elseif side == 3 then CFrame.new(starX, starY, 64.95)
			else CFrame.new(starX, 25.28, starZ)
		local star = createPart(cave, "CaveNightStar" .. starIndex, Vector3.new(0.18 + (starIndex % 3) * 0.04, 0.18 + (starIndex % 3) * 0.04, 0.05), starCFrame, Color3.fromRGB(231, 246, 255), Enum.Material.Neon)
		star.CanCollide = false
		star:SetAttribute("BaseCanCollide", false)
	end

	for treeIndex, treeData in ipairs({
		{ X = -44, Z = 29, Height = 13, Crown = 5.7 },
		{ X = -50, Z = 62, Height = 16, Crown = 6.4 },
		{ X = -62, Z = 28, Height = 15, Crown = 6.1 },
		{ X = -66, Z = 61, Height = 12, Crown = 5.4 },
		{ X = -38, Z = 51, Height = 14, Crown = 5.9 },
	}) do
		local groundTopY = 0.25
		local trunkCenterY = groundTopY + treeData.Height / 2
		local trunkRotation = CFrame.Angles(0, 0, math.rad(90))
		local trunk = createPart(cave, "CaveForestTreeTrunk" .. treeIndex, Vector3.new(treeData.Height, 1.2, 1.2), CFrame.new(treeData.X, trunkCenterY, treeData.Z) * trunkRotation, Color3.fromRGB(82, 51, 31), Enum.Material.Wood)
		trunk.Shape = Enum.PartType.Cylinder
		trunk:SetAttribute("PrologueDescription", "A pine tree stands where you woke up. Its roots seem more certain than yours.")
		trunk:SetAttribute("ProloguePriority", 35)
		for bandIndex = 1, 4 do
			local bandY = groundTopY + bandIndex * treeData.Height / 5
			local barkBand = createPart(cave, ("CaveForestTreeBarkBand%d_%d"):format(treeIndex, bandIndex), Vector3.new(0.18, 1.34, 1.34), CFrame.new(treeData.X, bandY, treeData.Z) * trunkRotation, Color3.fromRGB(105, 67, 39), Enum.Material.Wood)
			barkBand.Shape = Enum.PartType.Cylinder
			barkBand.CanCollide = false
			barkBand:SetAttribute("BaseCanCollide", false)
		end
		for canopyIndex, offset in ipairs({
			Vector3.new(0, 0, 0),
			Vector3.new(-1.85, -0.9, -0.55),
			Vector3.new(1.6, -0.7, 0.7),
			Vector3.new(0.5, 0.85, -1.25),
			Vector3.new(-0.35, 1.25, 1.15),
		}) do
			local canopy = createPart(cave, ("CaveForestCanopy%d_%d"):format(treeIndex, canopyIndex), Vector3.new(treeData.Crown, treeData.Crown * 0.72, treeData.Crown), CFrame.new(Vector3.new(treeData.X, groundTopY + treeData.Height + 2.1, treeData.Z) + offset), Color3.fromRGB(22 + canopyIndex * 4, 76 + canopyIndex * 5, 45), Enum.Material.Grass)
			canopy.Shape = Enum.PartType.Ball
			canopy.CanCollide = false
			canopy:SetAttribute("BaseCanCollide", false)
		end
	end

	makeVictoryWalkway(cave)

	createPart(cave, "CaveMouthLeftRock", Vector3.new(2.4, 9.5, 6.6), CFrame.new(-70, 4.2, 34.3), Color3.fromRGB(72, 72, 68), Enum.Material.Slate)
	createPart(cave, "CaveMouthRightRock", Vector3.new(2.4, 9.5, 6.6), CFrame.new(-70, 4.2, 55.7), Color3.fromRGB(72, 72, 68), Enum.Material.Slate)
	createPart(cave, "CaveMouthTopRock", Vector3.new(2.8, 3.5, 22.4), CFrame.new(-70, 9.55, 45), Color3.fromRGB(64, 64, 61), Enum.Material.Slate)

	local seal = makeModel(cave, "CaveEntranceRockfallSeal")
	local sealBlock = createPart(seal, "RockfallBlocker", Vector3.new(0.9, 8.8, 18.8), CFrame.new(-74.4, 4.1, 45), Color3.fromRGB(55, 55, 52), Enum.Material.Slate)
	setCaveSealBaseline(sealBlock, 0, true)
	for rockIndex, rockData in ipairs({
		{ Y = 1.7, Z = 38.4, Size = Vector3.new(1.2, 2.6, 4.2) },
		{ Y = 3.6, Z = 45.2, Size = Vector3.new(1.25, 3.4, 5.2) },
		{ Y = 6.0, Z = 51.6, Size = Vector3.new(1.15, 2.7, 4.4) },
	}) do
		local rock = createPart(seal, "RockfallChunk" .. rockIndex, rockData.Size, CFrame.new(-73.8, rockData.Y, rockData.Z), Color3.fromRGB(68, 67, 62), Enum.Material.Slate)
		rock.Shape = Enum.PartType.Ball
		setCaveSealBaseline(rock, 0, true)
	end
	local sealKey = makeCaveKeyShape(seal, "RockfallExitKeyOutline", CFrame.new(-73.05, 5.1, 45) * CFrame.Angles(0, math.rad(90), 0), 1.08, Color3.fromRGB(255, 221, 84), Enum.Material.Neon)
	for _, part in ipairs(sealKey:GetDescendants()) do
		if part:IsA("BasePart") then
			setCaveSealBaseline(part, 0, false)
		end
	end
	tag(seal, Constants.Tags.CaveEntranceSeal)
	seal.PrimaryPart = sealBlock

	createPart(cave, "CaveEntryFloor", Vector3.new(36, 1, 22), CFrame.new(-84, -0.8, 45), Color3.fromRGB(54, 54, 51), Enum.Material.Slate)
	createPart(cave, "CaveEntryLeftWall", Vector3.new(38, 11.5, 1), CFrame.new(-84, 4.75, 32.6), Color3.fromRGB(42, 43, 42), Enum.Material.Slate)
	createPart(cave, "CaveEntryRightWall", Vector3.new(38, 11.5, 1), CFrame.new(-84, 4.75, 57.4), Color3.fromRGB(42, 43, 42), Enum.Material.Slate)
	createPart(cave, "CaveEntryCeiling", Vector3.new(38, 1, 25), CFrame.new(-84, 10.7, 45), Color3.fromRGB(35, 36, 35), Enum.Material.Slate)

	local warningSign = createPart(cave, "CaveFirstWarningSign", Vector3.new(8.2, 2.35, 0.26), CFrame.new(-84, 4.15, 56.58), Color3.fromRGB(251, 232, 113), Enum.Material.SmoothPlastic)
	warningSign:SetAttribute("PrologueDescription", "The sign is too clean for a cave. Someone expected visitors.")
	createDoubleSidedSurfaceText(warningSign, "CaveWarningText", "FEEL FREE TO LOOK AROUND,\nBUT TOUCH NOTHING.", Enum.NormalId.Front, Color3.fromRGB(29, 26, 20), Color3.fromRGB(251, 232, 113))

	createPart(cave, "CaveSlopeFloorA", Vector3.new(36, 1, 24), CFrame.new(-98, -3.1, 45) * CFrame.Angles(0, 0, math.rad(8)), Color3.fromRGB(48, 48, 46), Enum.Material.Slate)
	createPart(cave, "CaveSlopeWallALeft", Vector3.new(38, 13, 1), CFrame.new(-98, 2.4, 31.7) * CFrame.Angles(0, 0, math.rad(8)), Color3.fromRGB(36, 36, 36), Enum.Material.Slate)
	createPart(cave, "CaveSlopeWallARight", Vector3.new(38, 13, 1), CFrame.new(-98, 2.4, 58.3) * CFrame.Angles(0, 0, math.rad(8)), Color3.fromRGB(36, 36, 36), Enum.Material.Slate)
	createPart(cave, "CaveSlopeCeilingA", Vector3.new(40, 1, 29), CFrame.new(-98, 8.5, 45) * CFrame.Angles(0, 0, math.rad(8)), Color3.fromRGB(31, 31, 31), Enum.Material.Slate)
	createPart(cave, "CaveTransitionCeilingPatch", Vector3.new(36, 1, 36), CFrame.new(-107.2, 7.6, 43.6), Color3.fromRGB(30, 30, 30), Enum.Material.Slate)
	createPart(cave, "CaveTransitionBridgeFloor", Vector3.new(31, 1, 30), CFrame.new(-107.6, -5.8, 43), Color3.fromRGB(49, 49, 46), Enum.Material.Slate)
	createPart(cave, "CaveTurnFloor", Vector3.new(42, 1, 54), CFrame.new(-114, -6.9, 33), Color3.fromRGB(48, 48, 46), Enum.Material.Slate)
	createPart(cave, "CaveTurnLandingFloor", Vector3.new(34, 1, 31), CFrame.new(-108, -5.7, 45), Color3.fromRGB(50, 50, 47), Enum.Material.Slate)
	createPart(cave, "CaveTurnWallLeft", Vector3.new(1, 19, 57), CFrame.new(-136.5, 1.9, 33), Color3.fromRGB(37, 37, 36), Enum.Material.Slate)
	createPart(cave, "CaveTurnWallRightLower", Vector3.new(1, 19, 30), CFrame.new(-91.4, 1.9, 20), Color3.fromRGB(37, 37, 36), Enum.Material.Slate)
	createPart(cave, "CaveTurnRightOuterWallFarCap", Vector3.new(1, 19, 8), CFrame.new(-91.4, 1.9, 58), Color3.fromRGB(37, 37, 36), Enum.Material.Slate)
	createPart(cave, "CaveTurnEntrySideWall", Vector3.new(41, 19, 1), CFrame.new(-116, 1.9, 59.4), Color3.fromRGB(37, 37, 36), Enum.Material.Slate)
	createPart(cave, "CaveTurnCeiling", Vector3.new(50, 1, 64), CFrame.new(-113.5, 10.95, 33), Color3.fromRGB(32, 32, 32), Enum.Material.Slate)
	createPart(cave, "CaveTurnPocketRoomFloor", Vector3.new(15, 1, 16), CFrame.new(-84, -6.9, 44), Color3.fromRGB(47, 47, 45), Enum.Material.Slate)
	createPart(cave, "CaveTurnPocketRoomFarWall", Vector3.new(15, 19, 1), CFrame.new(-84, 1.9, 36), Color3.fromRGB(35, 35, 35), Enum.Material.Slate)
	createPart(cave, "CaveTurnPocketRoomCeiling", Vector3.new(15, 1, 16), CFrame.new(-84, 10.95, 44), Color3.fromRGB(29, 29, 30), Enum.Material.Slate)

	for lightIndex, position in ipairs({
		Vector3.new(-76, 8.65, 45),
		Vector3.new(-91, 5.5, 45),
		Vector3.new(-108, 3.4, 39.6),
		Vector3.new(-118, -0.45, 23.8),
		Vector3.new(-124, 0.4, -34),
		Vector3.new(-124, 0.4, -82),
	}) do
		makeCaveElectricLight(cave, "CaveElectricLight" .. lightIndex, position, lightIndex)
	end

	local cavernCenter = Vector3.new(-124, -9.75, 15)
	createSoundSourceAnchor(cave, "InsideCaveSoundSource", CFrame.new(cavernCenter + Vector3.new(0, 5.15, 0)))
	createPart(cave, "CavernFloor", Vector3.new(48, 1, 38), CFrame.new(cavernCenter), Color3.fromRGB(50, 50, 47), Enum.Material.Slate)
	createPart(cave, "CavernBackWallLeft", Vector3.new(15, 16, 1), CFrame.new(cavernCenter + Vector3.new(-16.5, 8, -19)), Color3.fromRGB(35, 35, 34), Enum.Material.Slate)
	createPart(cave, "CavernBackWallRight", Vector3.new(4, 16, 1), CFrame.new(cavernCenter + Vector3.new(22, 8, -19)), Color3.fromRGB(35, 35, 34), Enum.Material.Slate)
	createPart(cave, "CavernBackWallLeftClosure", Vector3.new(17.5, 16, 1), CFrame.new(cavernCenter + Vector3.new(-15.25, 8, -19)), Color3.fromRGB(35, 35, 34), Enum.Material.Slate)
	createPart(cave, "CavernBackWallRightClosure", Vector3.new(17.5, 16, 1), CFrame.new(cavernCenter + Vector3.new(15.25, 8, -19)), Color3.fromRGB(35, 35, 34), Enum.Material.Slate)
	createPart(cave, "CavernFrontWallLeft", Vector3.new(14, 16, 1), CFrame.new(cavernCenter + Vector3.new(-17, 8, 19)), Color3.fromRGB(35, 35, 34), Enum.Material.Slate)
	createPart(cave, "CavernFrontWallRight", Vector3.new(4, 16, 1), CFrame.new(cavernCenter + Vector3.new(22, 8, 19)), Color3.fromRGB(35, 35, 34), Enum.Material.Slate)
	createPart(cave, "CavernLeftWall", Vector3.new(1, 16, 38), CFrame.new(cavernCenter + Vector3.new(-24, 8, 0)), Color3.fromRGB(36, 36, 35), Enum.Material.Slate)
	createPart(cave, "CavernRightWall", Vector3.new(1, 16, 38), CFrame.new(cavernCenter + Vector3.new(24, 8, 0)), Color3.fromRGB(36, 36, 35), Enum.Material.Slate)
	createPart(cave, "CavernCeiling", Vector3.new(48, 1, 38), CFrame.new(cavernCenter + Vector3.new(0, 16, 0)), Color3.fromRGB(27, 28, 28), Enum.Material.Slate)

	for spikeIndex, spikeData in ipairs({
		{ X = -139, Z = 1, H = 5.4, D = 1.1, Down = false },
		{ X = -132, Z = 27, H = 4.4, D = 0.9, Down = false },
		{ X = -111, Z = 3, H = 5.8, D = 1.2, Down = false },
		{ X = -104, Z = 25, H = 3.8, D = 0.85, Down = false },
		{ X = -141, Z = 20, H = 5.6, D = 1.0, Down = true },
		{ X = -119, Z = -1, H = 4.8, D = 0.9, Down = true },
		{ X = -108, Z = 13, H = 6.2, D = 1.15, Down = true },
	}) do
		local y = if spikeData.Down then cavernCenter.Y + 15.5 else cavernCenter.Y + 0.55
		makeCaveSpike(cave, "CaveSpike" .. spikeIndex, Vector3.new(spikeData.X, y, spikeData.Z), spikeData.H, spikeData.D, spikeData.Down)
	end

	local stream = createPart(cave, "CavernRunningWater", Vector3.new(4.4, 0.18, 28), CFrame.new(-145.5, -9.05, 13), Color3.fromRGB(78, 174, 222), Enum.Material.Glass)
	stream.Transparency = 0.34
	stream:SetAttribute("BaseTransparency", stream.Transparency)
	stream:SetAttribute("PrologueDescription", "A thin stream runs through the cavern. The dripping is the only thing acting natural.")
	local waterLight = Instance.new("PointLight")
	waterLight.Name = "CavernWaterGlow"
	waterLight.Brightness = 0.75
	waterLight.Color = Color3.fromRGB(94, 205, 255)
	waterLight.Range = 18
	waterLight.Parent = stream
	mark(waterLight)
	for rippleIndex = 1, 6 do
		local ripple = createPart(cave, "CavernWaterRipple" .. rippleIndex, Vector3.new(3.4, 0.05, 0.22), CFrame.new(-145.5, -8.9, 0.5 + rippleIndex * 4), Color3.fromRGB(170, 233, 255), Enum.Material.Neon)
		ripple.Transparency = 0.36
		ripple.CanCollide = false
		ripple:SetAttribute("BaseCanCollide", false)
		ripple:SetAttribute("BaseTransparency", ripple.Transparency)
	end

	local deskModel = makeModel(cave, "CaveStrangeDesk")
	local deskTop = createPart(deskModel, "CaveDeskTop", Vector3.new(8.5, 0.5, 4), CFrame.new(-118, -7.15, 13), Color3.fromRGB(86, 54, 34), Enum.Material.Wood)
	deskTop:SetAttribute("PrologueDescription", "A desk waits under the light, placed with the confidence of a trap that knows it is obvious.")
	createPart(deskModel, "CaveDeskLegA", Vector3.new(0.45, 2.5, 0.45), CFrame.new(-121.5, -8.45, 11.45), Color3.fromRGB(66, 39, 25), Enum.Material.Wood)
	createPart(deskModel, "CaveDeskLegB", Vector3.new(0.45, 2.5, 0.45), CFrame.new(-114.5, -8.45, 11.45), Color3.fromRGB(66, 39, 25), Enum.Material.Wood)
	createPart(deskModel, "CaveDeskLegC", Vector3.new(0.45, 2.5, 0.45), CFrame.new(-121.5, -8.45, 14.55), Color3.fromRGB(66, 39, 25), Enum.Material.Wood)
	createPart(deskModel, "CaveDeskLegD", Vector3.new(0.45, 2.5, 0.45), CFrame.new(-114.5, -8.45, 14.55), Color3.fromRGB(66, 39, 25), Enum.Material.Wood)
	local deskSign = createPart(deskModel, "CaveDeskDoNotTouchSign", Vector3.new(5.8, 1.8, 0.24), CFrame.new(-118, -5.55, 10.75), Color3.fromRGB(251, 232, 113), Enum.Material.SmoothPlastic)
	createDoubleSidedSurfaceText(deskSign, "CaveDeskSignText", "DON'T\nTOUCH", Enum.NormalId.Front, Color3.fromRGB(29, 26, 20), Color3.fromRGB(251, 232, 113))
	local findKeySign = createPart(deskModel, "CaveFindKeySign", Vector3.new(7.4, 1.1, 0.2), CFrame.new(-118, -5.25, 15.12) * CFrame.Angles(0, math.rad(180), 0), Color3.fromRGB(255, 221, 84), Enum.Material.Neon)
	createDoubleSidedSurfaceText(findKeySign, "CaveFindKeyText", "FIND THIS KEY\nTO GET OUT", Enum.NormalId.Front, Color3.fromRGB(32, 24, 12), Color3.fromRGB(255, 221, 84))
	findKeySign.Transparency = 1
	findKeySign.CanCollide = false
	findKeySign:SetAttribute("BaseTransparency", 1)
	findKeySign:SetAttribute("BaseCanCollide", false)
	findKeySign:SetAttribute("ClosedTransparency", 0)
	findKeySign:SetAttribute("ClosedCanCollide", false)
	for _, descendant in ipairs(findKeySign:GetDescendants()) do
		if descendant:IsA("SurfaceGui") then
			descendant.Enabled = false
		end
	end
	tag(findKeySign, Constants.Tags.CaveLockdownReveal)
	makeCaveKeyShape(deskModel, "CaveExitKeyVisual", CFrame.new(-118, -6.68, 13) * CFrame.Angles(0, 0, math.rad(90)), 1.16, Color3.fromRGB(255, 221, 84), Enum.Material.Neon)
	local keyGlowPlate = createPart(deskModel, "CaveExitKeyGlowPlate", Vector3.new(4.8, 0.08, 2.4), CFrame.new(-118, -6.88, 13), Color3.fromRGB(255, 221, 84), Enum.Material.Neon)
	keyGlowPlate.Transparency = 0.55
	keyGlowPlate.CanCollide = false
	keyGlowPlate:SetAttribute("BaseTransparency", keyGlowPlate.Transparency)
	keyGlowPlate:SetAttribute("BaseCanCollide", false)
	local keyHitbox = createPart(deskModel, "CaveExitKey", Vector3.new(4.8, 0.35, 2.4), CFrame.new(-118, -6.58, 13), Color3.fromRGB(255, 221, 84), Enum.Material.Neon)
	keyHitbox.Transparency = 1
	keyHitbox.CanCollide = false
	keyHitbox:SetAttribute("BaseTransparency", 1)
	keyHitbox:SetAttribute("BaseCanCollide", false)
	keyHitbox:SetAttribute("PrologueDescription", "The key is real enough to matter and staged enough to worry you.")
	createPrompt(keyHitbox, "Take", "Exit Key", 0)
	tag(keyHitbox, Constants.Tags.CaveExitKey)
	deskModel.PrimaryPart = deskTop

	local spotlightAnchor = createPart(cave, "CaveDeskSpotlight", Vector3.new(1.1, 0.35, 1.1), CFrame.new(-118, 3.0, 13), Color3.fromRGB(255, 238, 158), Enum.Material.Neon)
	spotlightAnchor.Shape = Enum.PartType.Cylinder
	local spot = Instance.new("SpotLight")
	spot.Name = "DeskSpotlight"
	spot.Angle = 46
	spot.Brightness = 5
	spot.Color = Color3.fromRGB(255, 236, 166)
	spot.Range = 32
	spot.Face = Enum.NormalId.Bottom
	spot.Parent = spotlightAnchor
	mark(spot)

	for alarmIndex, position in ipairs({
		Vector3.new(-136, -1.4, 29),
		Vector3.new(-112, -1.4, 29),
		Vector3.new(-124, -3.1, -36),
		Vector3.new(-124, -3.1, -88),
	}) do
		local alarm = createPart(cave, "CavePoliceRotaryLight" .. alarmIndex, Vector3.new(1.55, 0.9, 1.55), CFrame.new(position), Color3.fromRGB(130, 8, 18), Enum.Material.Glass)
		alarm.Shape = Enum.PartType.Ball
		alarm.Transparency = 0.82
		alarm:SetAttribute("BaseTransparency", alarm.Transparency)
		alarm:SetAttribute("AlarmIndex", alarmIndex)
		local alarmLight = Instance.new("PointLight")
		alarmLight.Name = "CaveAlarmPointLight"
		alarmLight.Enabled = false
		alarmLight.Brightness = 0
		alarmLight.Color = Color3.fromRGB(255, 32, 50)
		alarmLight.Range = 22
		alarmLight.Parent = alarm
		mark(alarmLight)
		tag(alarm, Constants.Tags.CaveAlarmLight)
	end

	createPart(cave, "CaveTunnelMouthFloor", Vector3.new(13, 1, 9), CFrame.new(-124, -10.7, -8.5), Color3.fromRGB(44, 44, 42), Enum.Material.Slate)
	createPart(cave, "CaveTunnelMouthCeiling", Vector3.new(13, 1, 9), CFrame.new(-124, 2.55, -8.5), Color3.fromRGB(25, 25, 26), Enum.Material.Slate)
	createPart(cave, "CaveLongTunnelFloor", Vector3.new(11, 1, 116), CFrame.new(-124, -10.7, -62), Color3.fromRGB(42, 42, 41), Enum.Material.Slate)
	createPart(cave, "CaveLongTunnelLeftWall", Vector3.new(1, 13.8, 118), CFrame.new(-130, -3.85, -62), Color3.fromRGB(30, 31, 31), Enum.Material.Slate)
	createPart(cave, "CaveLongTunnelRightWall", Vector3.new(1, 13.8, 118), CFrame.new(-118, -3.85, -62), Color3.fromRGB(30, 31, 31), Enum.Material.Slate)
	createPart(cave, "CaveLongTunnelCeiling", Vector3.new(12, 1, 118), CFrame.new(-124, 2.55, -62), Color3.fromRGB(24, 24, 25), Enum.Material.Slate)

	for tickIndex = 1, 9 do
		local tick = createPart(cave, "CaveLongTunnelDistanceMarker" .. tickIndex, Vector3.new(0.1, 0.16, 2.4), CFrame.new(-117.4, -2.4, 0 - tickIndex * 12), Color3.fromRGB(92, 82, 68), Enum.Material.Neon)
		tick.Transparency = 0.28
		tick.CanCollide = false
		tick:SetAttribute("BaseCanCollide", false)
		tick:SetAttribute("BaseTransparency", tick.Transparency)
	end

	local keyDoor = createPart(cave, "CaveKeyDoor", Vector3.new(13.6, 10, 0.55), CFrame.new(-124, -5.65, -121.5), Color3.fromRGB(79, 92, 116), Enum.Material.Wood)
	keyDoor:SetAttribute("DestinationCFrame", CAVE_HALLWAY_RETURN_CFRAME)
	keyDoor:SetAttribute("PrologueDescription", "The door is too flat for the cave. Its frame looks installed, not carved.")
	keyDoor.CanCollide = false
	keyDoor:SetAttribute("BaseCanCollide", false)
	local keyDoorLabel = createSurfaceText(keyDoor, "CaveKeyDoorText", "", Enum.NormalId.Back, Color3.fromRGB(232, 245, 255), Color3.fromRGB(38, 48, 64))
	keyDoorLabel:SetAttribute("LockedText", "EXIT KEY\nREQUIRED")
	keyDoorLabel:SetAttribute("LockedTextColor3", Color3.fromRGB(255, 221, 84))
	keyDoorLabel:SetAttribute("LockedBackgroundColor3", Color3.fromRGB(58, 45, 36))
	makeCaveKeyShape(cave, "CaveDoorKeyOutline", CFrame.new(-124, -5.7, -121.1) * CFrame.Angles(0, math.rad(180), 0), 1.15, Color3.fromRGB(255, 221, 84), Enum.Material.Neon)
	local keyDoorPrompt = createPrompt(keyDoor, "Enter", "Door", 0.15)
	keyDoorPrompt:SetAttribute("LockedActionText", "Unlock")
	keyDoorPrompt:SetAttribute("LockedObjectText", "Huge Cave Door")
	tag(keyDoor, Constants.Tags.CaveKeyDoor)

	cave.PrimaryPart = forestFloor
	return cave
end

local function makeSecurityRoom(roomFolder)
	local room = makeModel(roomFolder, "SecurityRoom")
	local origin = SECURITY_ROOM_ORIGIN
	local width = 46
	local depth = 38
	local height = 16

	createPart(room, "SecurityFloor", Vector3.new(width, 1, depth), cframeAt(origin, 0, 0, 0), Color3.fromRGB(55, 60, 68), Enum.Material.Concrete)
	createPart(room, "SecurityCeiling", Vector3.new(width, 1, depth), cframeAt(origin, 0, height, 0), Color3.fromRGB(35, 39, 48), Enum.Material.Metal)
	createPart(room, "SecurityBackWall", Vector3.new(width, height, 1), cframeAt(origin, 0, height / 2, -depth / 2), Color3.fromRGB(28, 32, 40), Enum.Material.Metal)
	createPart(room, "SecurityFrontWall", Vector3.new(width, height, 1), cframeAt(origin, 0, height / 2, depth / 2), Color3.fromRGB(74, 80, 91), Enum.Material.SmoothPlastic)
	createPart(room, "SecurityLeftWall", Vector3.new(1, height, depth), cframeAt(origin, -width / 2, height / 2, 0), Color3.fromRGB(58, 64, 74), Enum.Material.SmoothPlastic)
	createPart(room, "SecurityRightWall", Vector3.new(1, height, depth), cframeAt(origin, width / 2, height / 2, 0), Color3.fromRGB(58, 64, 74), Enum.Material.SmoothPlastic)

	createSpawnLocation(room, "SecuritySpawn", "SecurityRoom", SECURITY_ROOM_SPAWN_CFRAME, Color3.fromRGB(119, 255, 203), false)

	local exitDoor = makeHallDoor(
		room,
		"SecurityExitDoor",
		Vector3.new(7, 7.8, 0.42),
		cframeAt(origin, 0, 4.4, depth / 2 - 0.55),
		Enum.NormalId.Front,
		"HALLWAY",
		SECURITY_HALLWAY_RETURN_CFRAME
	)
	exitDoor:SetAttribute("TravelMessage", "Security returns you to the hallway and keeps a copy of the paperwork.")

	local controls = makeRoomControlPanel(
		room,
		"SecurityInsideControlPanel",
		CFrame.new(origin + Vector3.new(-width / 2 + 0.58, 4.65, depth / 2 - 6.6), origin + Vector3.new(0, 4.65, depth / 2 - 6.6)),
		"SecurityRoom",
		"SECURITY",
		{
			IncludeReset = true,
			PanelLabel = "SECURITY CONTROLS",
			LightPromptObjectText = "Security Light Switch",
			LogText = "SECURITY\nLOG\nOPEN",
		}
	)

	local sign = createPart(room, "SecurityTitleSign", Vector3.new(15, 2.6, 0.32), cframeAt(origin, 0, 12.3, depth / 2 - 0.82), Color3.fromRGB(255, 221, 84), Enum.Material.Neon)
	createDoubleSidedSurfaceText(sign, "SecurityTitleText", "SECURITY\nPLEASE LOOK CASUAL", Enum.NormalId.Front, Color3.fromRGB(23, 24, 28), Color3.fromRGB(255, 221, 84))

	local caseStudyPanel = createPart(room, "SecurityCaseStudyAlphaPanel", Vector3.new(12.8, 5.4, 0.32), cframeAt(origin, -13.2, 7.5, depth / 2 - 0.84), Color3.fromRGB(16, 22, 29), Enum.Material.Glass)
	createSurfaceText(
		caseStudyPanel,
		"SecurityCaseStudyText",
		"SUBJECT CASE STUDY ALPHA\nAWAITING PLAYER FILE\nSECURITY CONTRIBUTION: 0%\nOBSERVATION: ACTIVE",
		Enum.NormalId.Front,
		Color3.fromRGB(119, 255, 203),
		Color3.fromRGB(16, 22, 29)
	)
	createPrompt(caseStudyPanel, "Load", "Subject Case Study Alpha", 0)
	tag(caseStudyPanel, Constants.Tags.SecurityConsole)

	for plateIndex, plateData in ipairs({
		{ X = -3.2, Z = depth / 2 - 10.4, Label = "BADGE" },
		{ X = 3.2, Z = depth / 2 - 10.4, Label = "WEIGHT" },
	}) do
		local plate = createPart(room, "SecurityPressurePlate" .. plateIndex, Vector3.new(4.4, 0.22, 3.0), cframeAt(origin, plateData.X, 0.62, plateData.Z), Color3.fromRGB(36, 42, 50), Enum.Material.Metal)
		plate:SetAttribute("PlateIndex", plateIndex)
		plate:SetAttribute("SecurityControlPlate", true)
		createSurfaceText(plate, "SecurityPressurePlateText", plateData.Label, Enum.NormalId.Top, Color3.fromRGB(119, 255, 203), Color3.fromRGB(36, 42, 50))
		tag(plate, Constants.Tags.SecurityPressurePlate)
	end

	local monitorWall = makeModel(room, "SecurityMonitorWall")
	local monitorCameraCFrame =
		CFrame.new(origin + Vector3.new(-18, 9.8, depth / 2 - 3.8), origin + Vector3.new(4, 3.2, -depth / 2 + 2.5))
	local specialIndex = 23
	local cameraFeeds = {
		[1] = "TV ROOM",
		[2] = "SNACK LAB",
		[3] = "ISLAND",
		[4] = "LIBRARY",
		[5] = "BOWLING",
		[6] = "SPACE",
		[7] = "SLEEPING",
		[8] = "HALLWAY",
		[9] = "CAVE",
		[10] = "ZIPLINE",
		[11] = "VOID",
		[12] = "MAINT.",
		[23] = "SECURITY\nYOU?",
	}

	local function makeSecurityMonitorSurface(screen, monitorIndex, feedName, mode, isSpecial)
		local gui = Instance.new("SurfaceGui")
		gui.Name = "SecurityMonitorSurfaceGui"
		gui.Face = Enum.NormalId.Back
		gui.LightInfluence = 0.1
		gui.PixelsPerStud = 60
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.Parent = screen

		local background = Instance.new("Frame")
		background.Name = "SecurityMonitorBackground"
		background.BackgroundColor3 = if mode == "Static" then Color3.fromRGB(15, 17, 21) else Color3.fromRGB(18, 32, 42)
		background.BorderSizePixel = 0
		background.Size = UDim2.fromScale(1, 1)
		background.Parent = gui

		if mode == "Test" then
			local colors = {
				Color3.fromRGB(255, 242, 90),
				Color3.fromRGB(92, 226, 255),
				Color3.fromRGB(96, 255, 145),
				Color3.fromRGB(255, 92, 144),
				Color3.fromRGB(150, 112, 255),
			}
			for barIndex, color in ipairs(colors) do
				local bar = Instance.new("Frame")
				bar.Name = "TestPatternBar" .. barIndex
				bar.BackgroundColor3 = color
				bar.BorderSizePixel = 0
				bar.Position = UDim2.fromScale((barIndex - 1) / #colors, 0.2)
				bar.Size = UDim2.fromScale(1 / #colors, 0.62)
				bar.Parent = background
			end
		elseif mode == "Static" then
			for staticIndex = 1, 14 do
				local stripe = Instance.new("Frame")
				stripe.Name = "StaticStripe" .. staticIndex
				local brightness = 52 + (staticIndex * 37) % 120
				stripe.BackgroundColor3 = Color3.fromRGB(brightness, brightness + 8, brightness + 14)
				stripe.BackgroundTransparency = 0.22 + (staticIndex % 3) * 0.16
				stripe.BorderSizePixel = 0
				stripe.Position = UDim2.fromScale(0, (staticIndex - 1) / 14)
				stripe.Size = UDim2.fromScale(1, 0.035 + (staticIndex % 4) * 0.015)
				stripe.Parent = background
			end
		end

		local label = Instance.new("TextLabel")
		label.Name = "SecurityMonitorText"
		label.BackgroundColor3 = isSpecial and Color3.fromRGB(76, 18, 32) or Color3.fromRGB(5, 12, 17)
		label.BackgroundTransparency = 0.08
		label.BorderSizePixel = 0
		label.Font = Enum.Font.GothamBlack
		label.Position = UDim2.fromScale(0.05, 0.05)
		label.Size = UDim2.fromScale(0.9, 0.38)
		label.Text = ("CAM %02d\n%s"):format(monitorIndex, feedName)
		label.TextColor3 = isSpecial and Color3.fromRGB(255, 235, 149) or Color3.fromRGB(119, 255, 203)
		label.TextScaled = true
		label.TextWrapped = true
		label.Parent = background
	end

	for row = 1, 4 do
		for column = 1, 8 do
			local monitorIndex = (row - 1) * 8 + column
			local x = -18.35 + (column - 1) * 5.25
			local y = 4.0 + (4 - row) * 2.85
			local screenCFrame = cframeAt(origin, x, y, -depth / 2 + 0.42)
			local frame = createPart(monitorWall, ("SecurityMonitor%02dFrame"):format(monitorIndex), Vector3.new(5.05, 2.7, 0.22), screenCFrame, Color3.fromRGB(11, 13, 18), Enum.Material.Metal)
			local screen = createPart(monitorWall, ("SecurityMonitor%02dScreen"):format(monitorIndex), Vector3.new(4.48, 2.16, 0.12), screenCFrame * CFrame.new(0, 0, 0.18), Color3.fromRGB(18, 32, 42), Enum.Material.Neon)
			local isSpecial = monitorIndex == specialIndex
			local feedName = cameraFeeds[monitorIndex]
			local mode = if feedName then "Room" elseif monitorIndex % 2 == 0 then "Test" else "Static"
			makeSecurityMonitorSurface(screen, monitorIndex, feedName or mode:upper(), mode, isSpecial)

			if isSpecial then
				screen.Name = "SecuritySpecialMonitorScreen"
				screen:SetAttribute("CameraCFrame", monitorCameraCFrame)
				screen:SetAttribute("CameraLabel", "CAM 23 - SECURITY ROOM")
				local prompt = createPrompt(screen, "Watch", "Suspicious Monitor", 0.1)
				prompt.MaxActivationDistance = 16
				tag(screen, Constants.Tags.SecurityMonitor)
			end

			local glow = Instance.new("SurfaceLight")
			glow.Name = "SecurityMonitorGlow"
			glow.Face = Enum.NormalId.Back
			glow.Brightness = if isSpecial then 1.5 else 0.75
			glow.Color = if isSpecial then Color3.fromRGB(255, 88, 128) else Color3.fromRGB(119, 255, 203)
			glow.Range = 9
			glow.Parent = screen
			mark(glow)

			frame.CanCollide = false
			screen.CanCollide = false
			frame:SetAttribute("BaseCanCollide", false)
			screen:SetAttribute("BaseCanCollide", false)
		end
	end
	monitorWall.PrimaryPart = monitorWall:FindFirstChildWhichIsA("BasePart", true)

	local desk = makeModel(room, "SecurityDesk")
	local desktop = createPart(desk, "SecurityDeskTop", Vector3.new(17, 0.55, 4.8), cframeAt(origin, 0, 2.25, 5.8), Color3.fromRGB(74, 49, 34), Enum.Material.Wood)
	createPart(desk, "SecurityDeskFront", Vector3.new(17.3, 2.5, 0.42), cframeAt(origin, 0, 1.25, 8.0), Color3.fromRGB(62, 43, 32), Enum.Material.Wood)
	for legX = -1, 1, 2 do
		for legZ = -1, 1, 2 do
			createPart(desk, ("SecurityDeskLeg_%d_%d"):format(legX, legZ), Vector3.new(0.5, 2.4, 0.5), cframeAt(origin, legX * 7.6, 1.15, 5.8 + legZ * 1.8), Color3.fromRGB(53, 36, 27), Enum.Material.Wood)
		end
	end

	local console = createPart(desk, "SecurityConsole", Vector3.new(5.2, 1.25, 2.2), cframeAt(origin, -4.6, 3.1, 5.4) * CFrame.Angles(math.rad(-10), 0, 0), Color3.fromRGB(30, 39, 50), Enum.Material.Metal)
	createSurfaceText(console, "SecurityConsoleText", "ALL CAMERAS\nPROBABLY FINE", Enum.NormalId.Top, Color3.fromRGB(119, 255, 203), Color3.fromRGB(30, 39, 50))
	createPrompt(console, "Scan", "Monitor Wall Console", 0)
	tag(console, Constants.Tags.SecurityConsole)

	local redPhoneBase = createPart(desk, "SecurityRedPhoneBase", Vector3.new(2.4, 0.52, 1.55), cframeAt(origin, 3.9, 2.78, 5.25), Color3.fromRGB(188, 24, 43), Enum.Material.SmoothPlastic)
	local redPhoneHandle = createPart(desk, "SecurityRedPhone", Vector3.new(2.85, 0.48, 0.56), cframeAt(origin, 3.9, 3.18, 5.25), Color3.fromRGB(232, 43, 62), Enum.Material.SmoothPlastic)
	createPrompt(redPhoneHandle, "Answer", "Red Phone", 0)
	tag(redPhoneHandle, Constants.Tags.SecurityRedPhone)
	redPhoneBase.CanCollide = false
	redPhoneHandle.CanCollide = false
	redPhoneBase:SetAttribute("BaseCanCollide", false)
	redPhoneHandle:SetAttribute("BaseCanCollide", false)

	local tapeDeck = createPart(desk, "SecurityTapeDeck", Vector3.new(3.8, 0.72, 2.2), cframeAt(origin, 8.0, 2.92, 5.55), Color3.fromRGB(38, 41, 48), Enum.Material.Metal)
	createSurfaceText(tapeDeck, "SecurityTapeText", "TAPE\n01: DO NOT ERASE", Enum.NormalId.Top, Color3.fromRGB(255, 221, 84), Color3.fromRGB(38, 41, 48))
	createPrompt(tapeDeck, "Review", "Chunky Tape Deck", 0)
	tag(tapeDeck, Constants.Tags.SecurityTapeDeck)

	makeBunkerPowerMeter(room, cframeAt(origin, width / 2 - 0.64, 6.7, 7.2), Enum.NormalId.Left)
	makeAtomicStarburst(room, "SecurityAtomicStarburst", cframeAt(origin, width / 2 - 0.58, 11.4, 3.8) * CFrame.Angles(0, math.rad(-90), 0), 0.74, ATOMIC_COLORS.Pink, ATOMIC_COLORS.Cream)
	makeAtomicBoomerang(room, "SecurityAtomicBoomerang", cframeAt(origin, -width / 2 + 0.58, 10.7, -7.4) * CFrame.Angles(0, math.rad(90), 0), 0.8, ATOMIC_COLORS.Orange)

	room.PrimaryPart = desktop
	return {
		Model = room,
		ExitDoor = exitDoor,
		LightSwitch = controls.LightSwitch,
		ResetRoomButton = controls.ResetRoomButton,
		ReferenceBook = controls.ReferenceBook,
	}
end

local function prepareSleepingReplacementTentAssetModel(model)
	local visualParts = {}

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("LuaSourceContainer")
			or descendant:IsA("Constraint")
			or descendant:IsA("BodyMover")
			or descendant:IsA("Humanoid")
		then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
			descendant:SetAttribute("SleepingReplacementTentCandidate", true)
			descendant:SetAttribute("BaseCanCollide", false)
			descendant:SetAttribute("BaseCanQuery", false)
			descendant:SetAttribute("BaseCanTouch", false)
			table.insert(visualParts, descendant)
		end
	end

	return visualParts
end

local function makeProceduralSleepingReplacementTent(parent, tentCFrame)
	local tent = makeModel(parent, "SleepingReplacementTentCandidate")
	tent:SetAttribute("CandidateReplacementFor", "SleepingBlanketFort")
	tent:SetAttribute("RoomId", "SleepingQuarters")
	tent:SetAttribute("SourceAssetId", SLEEPING_REPLACEMENT_TENT_ASSET_ID)
	tent:SetAttribute("SourceAssetUrl", ("https://create.roblox.com/store/asset/%d"):format(SLEEPING_REPLACEMENT_TENT_ASSET_ID))
	tent:SetAttribute("AssetFallbackUsed", true)

	local groundCloth = createPart(tent, "TentGroundCloth", Vector3.new(8.8, 0.14, 5.8), tentCFrame * CFrame.new(0, 0.07, 0), Color3.fromRGB(57, 67, 74), Enum.Material.Fabric)
	local leftPanel = createPart(tent, "TentLeftFabricPanel", Vector3.new(8.4, 0.24, 5.4), tentCFrame * CFrame.new(0, 1.45, -1.28) * CFrame.Angles(math.rad(-28), 0, 0), Color3.fromRGB(92, 132, 112), Enum.Material.Fabric)
	local rightPanel = createPart(tent, "TentRightFabricPanel", Vector3.new(8.4, 0.24, 5.4), tentCFrame * CFrame.new(0, 1.45, 1.28) * CFrame.Angles(math.rad(28), 0, 0), Color3.fromRGB(67, 102, 95), Enum.Material.Fabric)
	local ridgePole = createPart(tent, "TentRidgePole", Vector3.new(0.22, 8.8, 0.22), tentCFrame * CFrame.new(0, 2.85, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(118, 82, 55), Enum.Material.Wood)
	local frontTie = createPart(tent, "TentFrontTie", Vector3.new(0.18, 2.6, 0.18), tentCFrame * CFrame.new(4.35, 1.35, 0) * CFrame.Angles(0, 0, math.rad(10)), Color3.fromRGB(181, 121, 67), Enum.Material.Wood)
	local backTie = createPart(tent, "TentBackTie", Vector3.new(0.18, 2.6, 0.18), tentCFrame * CFrame.new(-4.35, 1.35, 0) * CFrame.Angles(0, 0, math.rad(-10)), Color3.fromRGB(181, 121, 67), Enum.Material.Wood)

	for _, part in ipairs({ groundCloth, leftPanel, rightPanel, ridgePole, frontTie, backTie }) do
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part:SetAttribute("SleepingReplacementTentCandidate", true)
		part:SetAttribute("BaseCanCollide", false)
		part:SetAttribute("BaseCanQuery", false)
		part:SetAttribute("BaseCanTouch", false)
	end

	tent.PrimaryPart = groundCloth
	return tent
end

local function makeSleepingReplacementTent(parent, tentCFrame)
	local tent = makeModel(parent, "SleepingReplacementTentCandidate")
	tent:SetAttribute("CandidateReplacementFor", "SleepingBlanketFort")
	tent:SetAttribute("RoomId", "SleepingQuarters")
	tent:SetAttribute("SourceAssetId", SLEEPING_REPLACEMENT_TENT_ASSET_ID)
	tent:SetAttribute("SourceAssetUrl", ("https://create.roblox.com/store/asset/%d"):format(SLEEPING_REPLACEMENT_TENT_ASSET_ID))

	local success, assetModel = pcall(AssetService.LoadAssetAsync, AssetService, SLEEPING_REPLACEMENT_TENT_ASSET_ID)
	if not success or not assetModel then
		warn(("[DON'T TOUCH IT] Could not load Sleeping replacement tent asset %d: %s"):format(SLEEPING_REPLACEMENT_TENT_ASSET_ID, tostring(assetModel)))
		tent:Destroy()
		return makeProceduralSleepingReplacementTent(parent, tentCFrame)
	end

	assetModel.Name = "PbrTentByArSolusAsset"
	assetModel.Parent = tent

	local visualParts = prepareSleepingReplacementTentAssetModel(assetModel)
	if #visualParts == 0 then
		warn(("[DON'T TOUCH IT] Sleeping replacement tent asset %d loaded without visible parts."):format(SLEEPING_REPLACEMENT_TENT_ASSET_ID))
		tent:Destroy()
		return makeProceduralSleepingReplacementTent(parent, tentCFrame)
	end

	local _, currentSize = assetModel:GetBoundingBox()
	local largestAxis = math.max(currentSize.X, currentSize.Y, currentSize.Z)
	if largestAxis > 0 then
		assetModel:ScaleTo(9.2 / largestAxis)
	end

	assetModel:PivotTo(tentCFrame)
	local boundsCFrame, boundsSize = assetModel:GetBoundingBox()
	local bottomY = boundsCFrame.Position.Y - boundsSize.Y / 2
	assetModel:PivotTo(assetModel:GetPivot() + Vector3.new(
		tentCFrame.Position.X - boundsCFrame.Position.X,
		tentCFrame.Position.Y - bottomY,
		tentCFrame.Position.Z - boundsCFrame.Position.Z
	))

	for _, part in ipairs(visualParts) do
		mark(part)
	end

	tent.PrimaryPart = visualParts[1]
	return tent
end

local function makeSleepingQuartersRoom(roomFolder)
	local room = makeModel(roomFolder, "SleepingQuartersRoom")
	local origin = SLEEPING_QUARTERS_ORIGIN
	local width = 64
	local depth = 278
	local height = 24

	createPart(room, "SleepingFloor", Vector3.new(width, 1, depth), cframeAt(origin, 0, 0, 0), Color3.fromRGB(87, 91, 102), Enum.Material.Concrete)
	createPart(room, "SleepingCeiling", Vector3.new(width, 1, depth), cframeAt(origin, 0, height, 0), Color3.fromRGB(57, 54, 65), Enum.Material.SmoothPlastic)
	createPart(room, "SleepingBackWall", Vector3.new(width, height, 1), cframeAt(origin, 0, height / 2, -depth / 2), Color3.fromRGB(91, 77, 96), Enum.Material.SmoothPlastic)
	createPart(room, "SleepingFrontWall", Vector3.new(width, height, 1), cframeAt(origin, 0, height / 2, depth / 2), Color3.fromRGB(98, 87, 103), Enum.Material.SmoothPlastic)
	local branchGapDepth = 28
	local observationGapDepth = 16
	local leftWallSegmentDepth = (depth - observationGapDepth) / 2
	local leftWallSegmentCenterZ = (observationGapDepth / 2 + depth / 2) / 2
	createPart(room, "SleepingLeftWallFront", Vector3.new(1, height, leftWallSegmentDepth), cframeAt(origin, -width / 2, height / 2, leftWallSegmentCenterZ), Color3.fromRGB(103, 84, 92), Enum.Material.SmoothPlastic)
	createPart(room, "SleepingLeftWallBack", Vector3.new(1, height, leftWallSegmentDepth), cframeAt(origin, -width / 2, height / 2, -leftWallSegmentCenterZ), Color3.fromRGB(103, 84, 92), Enum.Material.SmoothPlastic)
	local wallSegmentDepth = (depth - branchGapDepth) / 2
	local wallSegmentCenterZ = (branchGapDepth / 2 + depth / 2) / 2
	createPart(room, "SleepingRightWallFront", Vector3.new(1, height, wallSegmentDepth), cframeAt(origin, width / 2, height / 2, wallSegmentCenterZ - 5.5), Color3.fromRGB(103, 84, 92), Enum.Material.SmoothPlastic)
	createPart(room, "SleepingRightWallBack", Vector3.new(1, height, wallSegmentDepth), cframeAt(origin, width / 2, height / 2, -wallSegmentCenterZ + 5.5), Color3.fromRGB(103, 84, 92), Enum.Material.SmoothPlastic)

	createSpawnLocation(room, "SleepingQuartersSpawn", "SleepingQuarters", SLEEPING_QUARTERS_SPAWN_CFRAME, Color3.fromRGB(255, 142, 191), false)

	local exitDoor = makeHallDoor(
		room,
		"SleepingExitDoor",
		Vector3.new(7, 7.8, 0.42),
		cframeAt(origin, 0, 4.4, depth / 2 - 0.55),
		Enum.NormalId.Front,
		"HALLWAY",
		SLEEPING_HALLWAY_RETURN_CFRAME
	)
	exitDoor:SetAttribute("TravelMessage", "Back to the hallway. Somehow it feels less full of beds.")

	local topDownDoor = makeHallDoor(
		room,
		"SleepingTopDownArenaDoor",
		Vector3.new(8.4, 7.8, 0.42),
		cframeAt(origin, 0, 4.4, -depth / 2 + 0.55),
		Enum.NormalId.Back,
		"TRAINING\nARENA",
		TOP_DOWN_ARENA_SPAWN_CFRAME
	)
	topDownDoor:SetAttribute("RoomId", "TopDownArena")
	topDownDoor:SetAttribute("LockedDuringPrologue", true)
	topDownDoor:SetAttribute("PrologueLockedMessage", "The Training Arena is not awake yet.")
	topDownDoor:SetAttribute("UnlockDiscoveryId", Constants.Discoveries.TopDownEntered.Id)
	topDownDoor:SetAttribute("TravelMessage", "Training Arena unlocked. The ceiling has opinions about camera angles.")

	local controls = makeRoomControlPanel(
		room,
		"SleepingInsideControlPanel",
		CFrame.new(origin + Vector3.new(-width / 2 + 0.58, 4.65, depth / 2 - 7.0), origin + Vector3.new(0, 4.65, depth / 2 - 7.0)),
		"SleepingQuarters",
		"SLEEPING QUARTERS",
		{
			IncludeReset = true,
			PanelLabel = "SLEEP CONTROLS",
			LightPromptObjectText = "Sleeping Quarters Light Switch",
			LogText = "SLEEPING\nLOG\nOPEN",
		}
	)

	local title = createPart(room, "SleepingTitleSign", Vector3.new(18, 2.6, 0.32), cframeAt(origin, 0, 17.8, depth / 2 - 0.82), Color3.fromRGB(255, 202, 103), Enum.Material.Neon)
	createDoubleSidedSurfaceText(title, "SleepingTitleText", "SLEEPING QUARTERS\nBED COUNT: TOO MANY", Enum.NormalId.Front, Color3.fromRGB(35, 27, 38), Color3.fromRGB(255, 202, 103))

	createNoTouchClock(
		room,
		"SleepingWallClock",
		"SleepingQuarters",
		Vector3.new(6.8, 2.0, 0.25),
		CFrame.new(origin + Vector3.new(14.3, 12.6, depth / 2 - 0.66), origin + Vector3.new(0, 6, 0)),
		Enum.NormalId.Front
	)

	local function makeBunkLocker(bunk, sideName, sideSign, index, zOffset)
		local lockerIndex = if sideSign < 0 then index else 50 + index
		local lockerPosition = origin + Vector3.new(sideSign * 15.75, 1.04, zOffset - 2.12)
		local lockerCFrame = CFrame.new(lockerPosition, origin + Vector3.new(0, 1.04, zOffset - 2.12))
		local lockerColor = if lockerIndex % 2 == 0 then Color3.fromRGB(70, 91, 111) else Color3.fromRGB(84, 76, 104)
		local lockerOpenCFrame = lockerCFrame * CFrame.new(0, 0.58, 0.46) * CFrame.Angles(math.rad(64), 0, 0)
		local lockerOpenColor = Color3.fromRGB(119, 255, 203)
		local tray = createPart(
			bunk,
			sideName .. "BunkLockerTray" .. index,
			Vector3.new(3.08, 0.34, 1.52),
			lockerCFrame * CFrame.new(0, -0.27, 0),
			Color3.fromRGB(30, 35, 46),
			Enum.Material.Metal
		)
		tray.CanCollide = false
		tray:SetAttribute("BaseCanCollide", false)
		tray:SetAttribute("LockerKind", "BunkTray")
		tray:SetAttribute("LockerIndex", lockerIndex)

		local locker = createPart(
			bunk,
			sideName .. "BunkLocker" .. index,
			Vector3.new(3.0, 0.78, 1.42),
			lockerCFrame,
			lockerColor,
			Enum.Material.Metal
		)
		locker:SetAttribute("LockerKind", "Bunk")
		locker:SetAttribute("LockerIndex", lockerIndex)
		locker:SetAttribute("LockerTotal", 100)
		locker:SetAttribute("SleepingLockerClosedCFrame", lockerCFrame)
		locker:SetAttribute("SleepingLockerOpenCFrame", lockerOpenCFrame)
		locker:SetAttribute("SleepingLockerClosedColor", lockerColor)
		locker:SetAttribute("SleepingLockerOpenColor", lockerOpenColor)
		locker:SetAttribute("SleepingLockerOpen", false)
		createSurfaceText(locker, "SleepingBunkLockerText", ("CHEST\n#%02d"):format(lockerIndex), Enum.NormalId.Top, Color3.fromRGB(229, 246, 255), lockerColor)
		createPrompt(locker, "Open", ("Foot Chest %02d"):format(lockerIndex), 0)
		tag(locker, Constants.Tags.SleepingLocker)

		local handle = createPart(
			bunk,
			sideName .. "BunkLockerHandle" .. index,
			Vector3.new(0.16, 0.18, 0.92),
			lockerCFrame * CFrame.new(0.82, 0.43, -0.18),
			Color3.fromRGB(255, 221, 84),
			Enum.Material.Neon
		)
		handle.CanCollide = false
		handle:SetAttribute("BaseCanCollide", false)
		handle:SetAttribute("SleepingLockerHandle", true)
		handle:SetAttribute("LockerIndex", lockerIndex)
		handle:SetAttribute("SleepingLockerHandleOffset", lockerCFrame:ToObjectSpace(handle.CFrame))

		if lockerIndex == 100 then
			locker:SetAttribute("HasIdBadge", true)
			local badge = createPart(
				bunk,
				"SleepingIdBadge",
				Vector3.new(1.12, 0.1, 0.72),
				lockerCFrame * CFrame.new(0, -0.02, -0.12) * CFrame.Angles(math.rad(90), 0, math.rad(-7)),
				Color3.fromRGB(238, 245, 255),
				Enum.Material.SmoothPlastic
			)
			badge.Transparency = 1
			badge.CanCollide = false
			badge:SetAttribute("BaseTransparency", 1)
			badge:SetAttribute("BaseCanCollide", false)
			badge:SetAttribute("HiddenInLocker", true)
			local badgeLabel = createSurfaceText(badge, "SleepingIdBadgeText", "ID\nBADGE", Enum.NormalId.Top, Color3.fromRGB(28, 44, 62), Color3.fromRGB(238, 245, 255))
			if badgeLabel.Parent and badgeLabel.Parent:IsA("SurfaceGui") then
				badgeLabel.Parent.Enabled = false
				badgeLabel.Parent:SetAttribute("BaseEnabled", false)
			end
			local badgePrompt = createPrompt(badge, "Take", "ID Badge", 0)
			badgePrompt.Enabled = false
			badgePrompt:SetAttribute("BaseEnabled", false)
			tag(badge, Constants.Tags.SleepingIdBadge)
		end

		return locker
	end

	local function makeBunkBed(sideName, sideSign, index, zOffset)
		local bunk = makeModel(room, sideName .. "Bunk" .. index)
		local sideColor = if sideSign < 0 then Color3.fromRGB(255, 142, 191) else Color3.fromRGB(255, 163, 92)
		local frameColor = Color3.fromRGB(81, 59, 48)
		local blanketColor = if index % 3 == 0 then Color3.fromRGB(119, 255, 203) elseif index % 3 == 1 then Color3.fromRGB(255, 142, 191) else Color3.fromRGB(255, 202, 103)
		local centerX = sideSign * 22.8
		local baseCFrame = cframeAt(origin, centerX, 0, zOffset)

		local lowerFrame = createPart(bunk, "LowerFrame", Vector3.new(8.8, 0.32, 3.55), baseCFrame * CFrame.new(0, 1.05, 0), frameColor, Enum.Material.Wood)
		local lowerMattress = createPart(bunk, "LowerMattress", Vector3.new(8.05, 0.52, 3.05), baseCFrame * CFrame.new(0, 1.44, 0), sideColor, Enum.Material.Fabric)
		local upperFrame = createPart(bunk, "UpperFrame", Vector3.new(8.8, 0.32, 3.55), baseCFrame * CFrame.new(0, 4.45, 0), frameColor, Enum.Material.Wood)
		local upperMattress = createPart(bunk, "UpperMattress", Vector3.new(8.05, 0.52, 3.05), baseCFrame * CFrame.new(0, 4.84, 0), blanketColor, Enum.Material.Fabric)
		lowerMattress.CustomPhysicalProperties = PhysicalProperties.new(0.55, 0.8, 0.55, 1, 1)
		upperMattress.CustomPhysicalProperties = PhysicalProperties.new(0.55, 0.8, 0.55, 1, 1)
		tag(lowerMattress, Constants.Tags.SleepingMattress)
		tag(upperMattress, Constants.Tags.SleepingMattress)

		for _, offset in ipairs({
			Vector3.new(-4.25, 2.75, -1.55),
			Vector3.new(4.25, 2.75, -1.55),
			Vector3.new(-4.25, 2.75, 1.55),
			Vector3.new(4.25, 2.75, 1.55),
		}) do
			createPart(bunk, "BunkPost", Vector3.new(0.24, 4.35, 0.24), baseCFrame * CFrame.new(offset), frameColor, Enum.Material.Wood)
		end

		local ladder = createPart(bunk, "BunkLadder", Vector3.new(0.18, 3.4, 0.18), baseCFrame * CFrame.new(-3.95, 3.0, sideSign * 2.02) * CFrame.Angles(0, 0, math.rad(9 * sideSign)), Color3.fromRGB(158, 100, 61), Enum.Material.Wood)
		ladder.Shape = Enum.PartType.Cylinder
		for rung = 1, 4 do
			local rungPart = createPart(bunk, "BunkLadderRung" .. rung, Vector3.new(1.24, 0.12, 0.12), baseCFrame * CFrame.new(-3.95, 1.72 + rung * 0.64, sideSign * 2.02), Color3.fromRGB(181, 121, 67), Enum.Material.Wood)
			rungPart.CanCollide = false
			rungPart:SetAttribute("BaseCanCollide", false)
		end

		if sideSign < 0 and index == 37 then
			lowerMattress.Name = "CountableBunkMattress"
			lowerMattress:SetAttribute("BunkTotal", 100)
			createPrompt(lowerMattress, "Count", "Bunk 37 of Too Many", 0)
			tag(lowerMattress, Constants.Tags.SleepingBunk)
		end

		if index % 10 == 0 then
			local sign = createPart(bunk, sideName .. "BunkRowSign" .. index, Vector3.new(3.2, 1.05, 0.14), baseCFrame * CFrame.new(0, 7.05, -1.95), Color3.fromRGB(39, 44, 54), Enum.Material.Neon)
			createDoubleSidedSurfaceText(sign, "BunkRowText", ("BUNKS\n%d-%d"):format(index - 9, index), Enum.NormalId.Front, Color3.fromRGB(255, 242, 181), Color3.fromRGB(39, 44, 54))
		end

		makeBunkLocker(bunk, sideName, sideSign, index, zOffset)

		bunk.PrimaryPart = lowerFrame
		return bunk
	end

	for index = 1, 50 do
		local zOffset = depth / 2 - 18 - (index - 1) * 5.0
		if index < 23 or index > 28 then
			makeBunkBed("Left", -1, index, zOffset)
			makeBunkBed("Right", 1, index, zOffset)
		end
	end

	local junctionFloor = createPart(room, "SleepingMidpointJunctionFloor", Vector3.new(22, 0.18, branchGapDepth + 2), cframeAt(origin, width / 2 - 9.5, 0.62, 0), Color3.fromRGB(76, 84, 98), Enum.Material.Metal)
	junctionFloor:SetAttribute("CosmicSurface", true)
	local junctionTrimA = createPart(room, "SleepingMidpointJunctionTrimA", Vector3.new(0.24, 0.22, branchGapDepth + 1.4), cframeAt(origin, width / 2 - 20.8, 0.86, 0), Color3.fromRGB(119, 255, 203), Enum.Material.Neon)
	junctionTrimA.CanCollide = false
	junctionTrimA:SetAttribute("BaseCanCollide", false)
	local junctionTrimB = createPart(room, "SleepingMidpointJunctionTrimB", Vector3.new(0.24, 0.22, branchGapDepth + 1.4), cframeAt(origin, width / 2 - 0.8, 0.86, 0), Color3.fromRGB(255, 142, 191), Enum.Material.Neon)
	junctionTrimB.CanCollide = false
	junctionTrimB:SetAttribute("BaseCanCollide", false)
	local branchSign = createPart(room, "SleepingMidpointBranchSign", Vector3.new(0.28, 2.5, 10.8), cframeAt(origin, width / 2 - 0.72, 7.6, 0) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(255, 229, 161), Enum.Material.Neon)
	createDoubleSidedSurfaceText(branchSign, "SleepingBranchSignText", "INFIRMARY  /  GYM\nOCCUPANT MAINTENANCE", Enum.NormalId.Front, Color3.fromRGB(45, 36, 27), Color3.fromRGB(255, 229, 161))
	makeAtomicStarburst(room, "SleepingBranchAtomicStarburst", cframeAt(origin, width / 2 - 0.74, 12.6, 10.8) * CFrame.Angles(0, math.rad(-90), 0), 0.54, ATOMIC_COLORS.Cream, ATOMIC_COLORS.Pink)

	local alarmTable = createPart(room, "SleepingAlarmTable", Vector3.new(4.2, 1.0, 3.0), cframeAt(origin, 8.6, 1.0, depth / 2 - 13.5), Color3.fromRGB(99, 66, 43), Enum.Material.Wood)
	local alarm = createPart(room, "SleepingAlarmClock", Vector3.new(1.35, 1.0, 0.86), alarmTable.CFrame * CFrame.new(0, 0.95, -0.18), Color3.fromRGB(255, 202, 103), Enum.Material.Metal)
	createSurfaceText(alarm, "SleepingAlarmClockText", "12:00\nNOPE", Enum.NormalId.Front, Color3.fromRGB(43, 30, 39), Color3.fromRGB(255, 202, 103))
	createPrompt(alarm, "Snooze", "Alarm Clock", 0)
	tag(alarm, Constants.Tags.SleepingAlarmClock)

	local cleaningLockerModel = makeModel(room, "SleepingCleaningSuppliesLocker")
	local cleaningLockerCFrame = CFrame.new(
		origin + Vector3.new(width / 2 - 0.8, 3.9, depth / 2 - 14.5),
		origin + Vector3.new(0, 3.9, depth / 2 - 14.5)
	)
	local locker = createPart(cleaningLockerModel, "SleepingCleaningLockerDoor", Vector3.new(3.4, 6.8, 1.2), cleaningLockerCFrame, Color3.fromRGB(67, 87, 105), Enum.Material.Metal)
	locker:SetAttribute("LockerKind", "CleaningSupplies")
	createDoubleSidedSurfaceText(locker, "SleepingLockerText", "CLEANING\nSUPPLIES", Enum.NormalId.Front, Color3.fromRGB(229, 246, 255), Color3.fromRGB(67, 87, 105))
	createPrompt(locker, "Open", "Cleaning Supplies Locker", 0)
	tag(locker, Constants.Tags.SleepingLocker)

	local mopHandle = createPart(cleaningLockerModel, "CleaningLockerMopHandle", Vector3.new(0.16, 4.6, 0.16), cleaningLockerCFrame * CFrame.new(-0.9, -0.25, -0.82) * CFrame.Angles(0, 0, math.rad(-8)), Color3.fromRGB(179, 119, 67), Enum.Material.Wood)
	local mopHead = createPart(cleaningLockerModel, "CleaningLockerMopHead", Vector3.new(0.9, 0.5, 0.26), cleaningLockerCFrame * CFrame.new(-1.08, -2.5, -0.9), Color3.fromRGB(221, 224, 211), Enum.Material.Fabric)
	local broomHandle = createPart(cleaningLockerModel, "CleaningLockerBroomHandle", Vector3.new(0.14, 4.4, 0.14), cleaningLockerCFrame * CFrame.new(0.18, -0.25, -0.83) * CFrame.Angles(0, 0, math.rad(7)), Color3.fromRGB(168, 95, 54), Enum.Material.Wood)
	local broomHead = createPart(cleaningLockerModel, "CleaningLockerBroomHead", Vector3.new(1.0, 0.46, 0.24), cleaningLockerCFrame * CFrame.new(0.42, -2.45, -0.9), Color3.fromRGB(255, 202, 103), Enum.Material.Fabric)
	local bucket = createPart(cleaningLockerModel, "CleaningLockerWaterBucket", Vector3.new(1.05, 0.82, 1.05), cleaningLockerCFrame * CFrame.new(1.05, -2.55, -0.76), Color3.fromRGB(93, 217, 255), Enum.Material.Metal, "Part")
	bucket.Shape = Enum.PartType.Cylinder
	for _, content in ipairs({ mopHandle, mopHead, broomHandle, broomHead, bucket }) do
		content.Transparency = 1
		content.CanCollide = false
		content:SetAttribute("SleepingCleaningContent", true)
		content:SetAttribute("BaseTransparency", 1)
		content:SetAttribute("BaseCanCollide", false)
	end
	cleaningLockerModel.PrimaryPart = locker

	local dreamButtonBase = createPart(room, "SleepingDreamButtonPlate", Vector3.new(4.2, 2.4, 0.22), cframeAt(origin, -10.5, 5.2, -depth / 2 + 0.62), Color3.fromRGB(39, 44, 54), Enum.Material.Metal)
	createSurfaceText(dreamButtonBase, "SleepingDreamButtonLabel", "RESPONSIBLE\nDREAM BUTTON", Enum.NormalId.Back, Color3.fromRGB(119, 255, 203), Color3.fromRGB(39, 44, 54))
	local dreamButton = createPart(room, "SleepingDreamButton", Vector3.new(1.45, 0.34, 1.45), dreamButtonBase.CFrame * CFrame.new(0, -0.1, 0.24) * CFrame.Angles(math.rad(90), 0, 0), Color3.fromRGB(255, 72, 158), Enum.Material.Neon)
	dreamButton.Shape = Enum.PartType.Cylinder
	createPrompt(dreamButton, "Press", "Dream Button", 0)
	tag(dreamButton, Constants.Tags.SleepingDreamButton)

	local fort = makeModel(room, "SleepingBlanketFort")
	local fortCenter = cframeAt(origin, 0, 1.3, 12)
	local fortLeft = createPart(fort, "BlanketFortLeftWall", Vector3.new(6.2, 0.22, 4.2), fortCenter * CFrame.new(-1.8, 1.7, 0) * CFrame.Angles(0, 0, math.rad(26)), Color3.fromRGB(255, 142, 191), Enum.Material.Fabric)
	local fortRight = createPart(fort, "BlanketFortRightWall", Vector3.new(6.2, 0.22, 4.2), fortCenter * CFrame.new(1.8, 1.7, 0) * CFrame.Angles(0, 0, math.rad(-26)), Color3.fromRGB(119, 255, 203), Enum.Material.Fabric)
	local fortSign = createPart(fort, "BlanketFortSign", Vector3.new(4.2, 1.1, 0.18), fortCenter * CFrame.new(0, 2.2, -2.2), Color3.fromRGB(255, 232, 112), Enum.Material.SmoothPlastic)
	createSurfaceText(fortSign, "BlanketFortText", "FORT\nPERMIT PENDING", Enum.NormalId.Front, Color3.fromRGB(39, 34, 21), Color3.fromRGB(255, 232, 112))
	createPrompt(fortSign, "Inspect", "Blanket Fort", 0)
	tag(fortSign, Constants.Tags.SleepingBlanketFort)
	fortLeft.CanCollide = false
	fortRight.CanCollide = false
	fortLeft:SetAttribute("BaseCanCollide", false)
	fortRight:SetAttribute("BaseCanCollide", false)
	fort.PrimaryPart = fortSign

	makeSleepingReplacementTent(room, cframeAt(origin, 8.6, 0.56, 10.2) * CFrame.Angles(0, math.rad(-14), 0))

	local pillowPile = makeModel(room, "SleepingPillowPile")
	local pillowColors = {
		Color3.fromRGB(245, 248, 255),
		Color3.fromRGB(255, 202, 224),
		Color3.fromRGB(203, 255, 255),
	}
	local pillowPromptTarget = nil
	for pillowIndex = 1, 12 do
		local angle = math.rad(pillowIndex * 63)
		local radius = 0.4 + (pillowIndex % 4) * 0.42
		local pillow = createPart(
			pillowPile,
			"SleepingPillow" .. pillowIndex,
			Vector3.new(1.35, 0.42, 0.9),
			cframeAt(origin, math.cos(angle) * radius - 7, 1.04 + (pillowIndex % 3) * 0.2, math.sin(angle) * radius + 6) * CFrame.Angles(0, angle, math.rad((pillowIndex % 5) * 8)),
			pillowColors[((pillowIndex - 1) % #pillowColors) + 1],
			Enum.Material.Fabric
		)
		pillow.CanCollide = false
		pillow:SetAttribute("BaseCanCollide", false)
		pillowPromptTarget = pillowPromptTarget or pillow
	end
	createPrompt(pillowPromptTarget, "Fluff", "Pillow Pile", 0)
	tag(pillowPromptTarget, Constants.Tags.SleepingPillowPile)
	pillowPile.PrimaryPart = pillowPromptTarget

	for lightIndex = 1, 8 do
		local zOffset = depth / 2 - 24 - (lightIndex - 1) * 18
		local strip = createPart(room, "SleepingNeonGuideStrip" .. lightIndex, Vector3.new(0.18, 0.22, 7.2), cframeAt(origin, 0, height - 0.72, zOffset), BOWLING_COSMIC_COLORS[((lightIndex - 1) % #BOWLING_COSMIC_COLORS) + 1], Enum.Material.Neon)
		strip.CanCollide = false
		strip:SetAttribute("BaseCanCollide", false)
	end
	makeAtomicBoomerang(room, "SleepingAtomicBoomerang", cframeAt(origin, width / 2 - 0.58, 16.2, depth / 2 - 20) * CFrame.Angles(0, math.rad(-90), 0), 0.76, ATOMIC_COLORS.Orange)
	makeAtomicDiamondCluster(room, "SleepingAtomicDiamonds", cframeAt(origin, -width / 2 + 0.58, 15.8, -12) * CFrame.Angles(0, math.rad(90), 0), 0.66)

	room.PrimaryPart = title
	return {
		Model = room,
		ExitDoor = exitDoor,
		TopDownArenaDoor = topDownDoor,
		LightSwitch = controls.LightSwitch,
		ResetRoomButton = controls.ResetRoomButton,
		ReferenceBook = controls.ReferenceBook,
	}
end

local function makeSleepingMaintenanceBranch(roomFolder)
	local branch = makeModel(roomFolder, "SleepingMaintenanceBranch")
	local floorColor = Color3.fromRGB(61, 70, 84)
	local wallColor = Color3.fromRGB(70, 76, 91)
	local ceilingColor = Color3.fromRGB(42, 47, 58)
	local hallHeight = 12
	local branchCenterX = 146
	local branchLeftWallX = 134.4
	local branchRightWallX = 157.6
	local branchUsableWidth = branchRightWallX - branchLeftWallX - 0.6
	local branchConnectorNorthWallZ = -179.2
	local branchConnectorSouthWallZ = -196.8
	local connectorOpeningWallClearance = 0.4
	local infirmaryApproachNorthZ = -188
	local infirmaryDoorNorthEdgeZ = INFIRMARY_ORIGIN.Z - 6
	local infirmaryApproachLeftWallSouthZ = branchConnectorNorthWallZ + connectorOpeningWallClearance
	local infirmaryApproachLeftWallDepth = infirmaryDoorNorthEdgeZ - infirmaryApproachLeftWallSouthZ
	local infirmaryApproachLeftWallCenterZ = (infirmaryApproachLeftWallSouthZ + infirmaryDoorNorthEdgeZ) / 2
	local infirmaryApproachRightWallDepth = infirmaryDoorNorthEdgeZ - infirmaryApproachNorthZ
	local infirmaryApproachRightWallCenterZ = (infirmaryApproachNorthZ + infirmaryDoorNorthEdgeZ) / 2
	local connectorWallLeftEdgeX = 115
	local connectorWallRightEdgeX = branchLeftWallX - 0.8
	local connectorWallLength = connectorWallRightEdgeX - connectorWallLeftEdgeX
	local connectorWallCenterX = connectorWallLeftEdgeX + connectorWallLength / 2
	local gymRampWallThickness = 0.42
	local gymRampLeftWallX = connectorWallRightEdgeX + gymRampWallThickness / 2
	local gymEntranceWallX = GYM_ORIGIN.X - 28
	local gymEntranceNorthZ = GYM_ORIGIN.Z - 6
	local gymEntranceSouthZ = GYM_ORIGIN.Z + 6
	local gymRampSouthZ = -188
	local gymRampOpenTurnZ = gymEntranceSouthZ
	local gymRampLeftWallNorthZ = branchConnectorSouthWallZ - connectorOpeningWallClearance
	local gymRampLeftWallDepth = gymRampLeftWallNorthZ - gymEntranceNorthZ
	local gymRampLeftWallCenterZ = (gymEntranceNorthZ + gymRampLeftWallNorthZ) / 2
	local gymRampCeilingDepth = gymRampSouthZ - gymEntranceNorthZ
	local gymRampCeilingCenterZ = (gymEntranceNorthZ + gymRampSouthZ) / 2
	local gymRampRightWallDepth = gymRampSouthZ - gymRampOpenTurnZ
	local gymRampRightWallCenterZ = (gymRampOpenTurnZ + gymRampSouthZ) / 2
	local gymEntryReturnWallMinX = gymRampLeftWallX - gymRampWallThickness / 2
	local gymEntryReturnWallMaxX = gymEntranceWallX
	local gymEntryReturnWallLength = gymEntryReturnWallMaxX - gymEntryReturnWallMinX
	local gymEntryReturnWallCenterX = (gymEntryReturnWallMinX + gymEntryReturnWallMaxX) / 2
	local gymEntryLandingFloorMinX = gymRampLeftWallX + gymRampWallThickness / 2
	local gymEntryLandingFloorMaxX = gymEntranceWallX + 0.15
	local gymEntryLandingFloorWidth = gymEntryLandingFloorMaxX - gymEntryLandingFloorMinX
	local gymEntryLandingFloorCenterX = (gymEntryLandingFloorMinX + gymEntryLandingFloorMaxX) / 2

	createPart(branch, "BranchConnectorFloor", Vector3.new(34, 0.42, 18), CFrame.new(131, 0.38, -188), floorColor, Enum.Material.Metal)
	createPart(branch, "BranchConnectorCeiling", Vector3.new(34, 0.36, 18), CFrame.new(131, hallHeight, -188), ceilingColor, Enum.Material.Concrete)
	createPart(branch, "BranchConnectorNorthWall", Vector3.new(connectorWallLength, hallHeight, 0.42), CFrame.new(connectorWallCenterX, hallHeight / 2, branchConnectorNorthWallZ), wallColor, Enum.Material.SmoothPlastic)
	createPart(branch, "BranchConnectorSouthWall", Vector3.new(connectorWallLength, hallHeight, 0.42), CFrame.new(connectorWallCenterX, hallHeight / 2, branchConnectorSouthWallZ), wallColor, Enum.Material.SmoothPlastic)

	createPart(branch, "BranchJunctionFloor", Vector3.new(branchUsableWidth, 0.42, 72), CFrame.new(branchCenterX, 0.4, -189), floorColor, Enum.Material.Metal)
	createPart(branch, "BranchJunctionCeiling", Vector3.new(branchUsableWidth, 0.36, 42), CFrame.new(branchCenterX, hallHeight, -171), ceilingColor, Enum.Material.Concrete)
	createPart(branch, "InfirmaryApproachLeftWall", Vector3.new(0.75, hallHeight, 26.3), CFrame.new(branchLeftWallX, hallHeight / 2, -163.9), wallColor, Enum.Material.SmoothPlastic)
	createPart(branch, "InfirmaryApproachRightWall", Vector3.new(0.42, hallHeight, infirmaryApproachRightWallDepth), CFrame.new(branchRightWallX, hallHeight / 2, infirmaryApproachRightWallCenterZ), wallColor, Enum.Material.SmoothPlastic)
	createPart(branch, "InfirmaryEntryThresholdFloor", Vector3.new(10.2, 0.42, 7.2), CFrame.new(139.3, 0.42, -150.4), floorColor, Enum.Material.Metal)
	createPart(branch, "InfirmaryEntryOuterSafetyWall", Vector3.new(0.42, hallHeight, 7.8), CFrame.new(branchLeftWallX, hallHeight / 2, -150.1), wallColor, Enum.Material.SmoothPlastic)
	createPart(branch, "InfirmaryEntrySouthReturnWall", Vector3.new(9.4, hallHeight, 0.42), CFrame.new(139.1, hallHeight / 2, -147.35), wallColor, Enum.Material.SmoothPlastic)

	local stairCount = 8
	for stepIndex = 1, stairCount do
		local alpha = stepIndex / stairCount
		local y = 0.45 + alpha * 6
		local z = -194 - (stepIndex - 1) * 3.7
		createPart(
			branch,
			"GymRampStep" .. stepIndex,
			Vector3.new(branchUsableWidth - 0.4, 0.38, 3.5),
			CFrame.new(branchCenterX, y, z),
			Color3.fromRGB(70, 78, 94),
			Enum.Material.Metal
		)
	end
	createPart(branch, "GymEntrySideLandingFloor", Vector3.new(gymEntryLandingFloorWidth, 0.38, 8.4), CFrame.new(gymEntryLandingFloorCenterX, 6.45, gymEntranceNorthZ + 4.2), floorColor, Enum.Material.Metal)
	createPart(branch, "GymRampLeftWall", Vector3.new(gymRampWallThickness, 14, gymRampLeftWallDepth), CFrame.new(gymRampLeftWallX, 6.8, gymRampLeftWallCenterZ), wallColor, Enum.Material.SmoothPlastic)
	createPart(branch, "GymRampRightWall", Vector3.new(0.42, 14, gymRampRightWallDepth), CFrame.new(branchRightWallX, 6.8, gymRampRightWallCenterZ), wallColor, Enum.Material.SmoothPlastic)
	createPart(branch, "GymRampCeiling", Vector3.new(branchUsableWidth, 0.36, gymRampCeilingDepth), CFrame.new(branchCenterX, 16.8, gymRampCeilingCenterZ), ceilingColor, Enum.Material.Concrete)
	createPart(branch, "GymEntryNorthReturnWall", Vector3.new(gymEntryReturnWallLength, 14, 0.42), CFrame.new(gymEntryReturnWallCenterX, 6.8, gymEntranceNorthZ), wallColor, Enum.Material.SmoothPlastic)

	for lightIndex, data in ipairs({
		{ Position = Vector3.new(126, 8.7, -188), Color = Color3.fromRGB(119, 255, 203) },
		{ Position = Vector3.new(146, 8.7, -171), Color = Color3.fromRGB(255, 229, 161) },
		{ Position = Vector3.new(146, 12.2, -210), Color = Color3.fromRGB(255, 142, 191) },
	}) do
		local fixture = createPart(branch, "BranchAtomicIndicator" .. lightIndex, Vector3.new(1.15, 1.15, 1.15), CFrame.new(data.Position), data.Color, Enum.Material.Neon)
		fixture.Shape = Enum.PartType.Ball
		fixture.CanCollide = false
		fixture:SetAttribute("BaseCanCollide", false)
		local light = Instance.new("PointLight")
		light.Name = "BranchIndicatorLight"
		light.Brightness = 1.45
		light.Range = 15
		light.Color = data.Color
		light.Parent = fixture
		mark(light)
	end

	local sign = createPart(branch, "BranchDirectionSign", Vector3.new(0.28, 2.4, 12), CFrame.new(146, 7.5, -188) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(255, 229, 161), Enum.Material.Neon)
	createDoubleSidedSurfaceText(sign, "BranchDirectionSignText", "INFIRMARY  <-\nPHYSICAL CONDITIONING  ->", Enum.NormalId.Front, Color3.fromRGB(35, 28, 24), Color3.fromRGB(255, 229, 161))
	makeAtomicDiamondCluster(branch, "BranchAtomicDiamonds", CFrame.new(154.4, 8.2, -188) * CFrame.Angles(0, math.rad(-90), 0), 0.52)

	branch.PrimaryPart = branch:FindFirstChild("BranchConnectorFloor")
	return branch
end

local function makeInfirmaryRoom(roomFolder)
	local room = makeModel(roomFolder, "InfirmaryRoom")
	local origin = INFIRMARY_ORIGIN
	local width = 52
	local depth = 48
	local height = 17
	local wallColor = Color3.fromRGB(158, 175, 178)
	local trimColor = Color3.fromRGB(119, 255, 203)

	createPart(room, "InfirmaryFloor", Vector3.new(width, 1, depth), cframeAt(origin, 0, 0, 0), Color3.fromRGB(185, 194, 193), Enum.Material.SmoothPlastic)
	createPart(room, "InfirmaryCeiling", Vector3.new(width, 1, depth), cframeAt(origin, 0, height, 0), Color3.fromRGB(193, 200, 199), Enum.Material.SmoothPlastic)
	createPart(room, "InfirmaryNorthWall", Vector3.new(width, height, 1), cframeAt(origin, 0, height / 2, -depth / 2), wallColor, Enum.Material.SmoothPlastic)
	createPart(room, "InfirmarySouthWall", Vector3.new(width, height, 1), cframeAt(origin, 0, height / 2, depth / 2), wallColor, Enum.Material.SmoothPlastic)
	createPart(room, "InfirmaryEastWall", Vector3.new(1, height, depth), cframeAt(origin, width / 2, height / 2, 0), Color3.fromRGB(149, 165, 171), Enum.Material.SmoothPlastic)
	local westWallDepth = (depth - 12) / 2
	createPart(room, "InfirmaryWestWallNorth", Vector3.new(1, height, westWallDepth), cframeAt(origin, -width / 2, height / 2, -15), Color3.fromRGB(149, 165, 171), Enum.Material.SmoothPlastic)
	createPart(room, "InfirmaryWestWallSouth", Vector3.new(1, height, westWallDepth), cframeAt(origin, -width / 2, height / 2, 15), Color3.fromRGB(149, 165, 171), Enum.Material.SmoothPlastic)
	createPart(room, "InfirmaryDoorHeader", Vector3.new(1, height - 8.4, 12), cframeAt(origin, -width / 2, 12.8, 0), Color3.fromRGB(138, 155, 163), Enum.Material.SmoothPlastic)

	createSpawnLocation(room, "InfirmarySpawn", "Infirmary", INFIRMARY_SPAWN_CFRAME, Color3.fromRGB(119, 255, 203), false)
	local controls = makeRoomControlPanel(
		room,
		"InfirmaryInsideControlPanel",
		CFrame.new(origin + Vector3.new(-width / 2 + 0.58, 5.0, depth / 2 - 7.0), origin + Vector3.new(0, 5.0, depth / 2 - 7.0)),
		"Infirmary",
		"INFIRMARY",
		{
			IncludeReset = true,
			PanelLabel = "RECOVERY CONTROLS",
			LightPromptObjectText = "Infirmary Light Switch",
			LogText = "INFIRMARY\nLOG\nOPEN",
		}
	)

	local title = createPart(room, "InfirmaryTitleSign", Vector3.new(16, 2.3, 0.3), cframeAt(origin, 0, 12.8, depth / 2 - 0.72), trimColor, Enum.Material.Neon)
	createDoubleSidedSurfaceText(title, "InfirmaryTitleText", "INFIRMARY\nREMAIN FUNCTIONAL", Enum.NormalId.Front, Color3.fromRGB(20, 36, 39), trimColor)

	createNoTouchClock(
		room,
		"InfirmaryWallClock",
		"Infirmary",
		Vector3.new(6.2, 1.9, 0.24),
		cframeAt(origin, width / 2 - 0.62, 9.2, -6.5) * CFrame.Angles(0, math.rad(-90), 0),
		Enum.NormalId.Left
	)

	local recovery = makeModel(room, "PrimaryRecoveryBed")
	local recoveryBed = createPart(recovery, "InfirmaryRecoveryBed", Vector3.new(7.4, 0.7, 3.4), cframeAt(origin, 9.5, 1.35, 0), Color3.fromRGB(207, 217, 216), Enum.Material.SmoothPlastic)
	createPart(recovery, "RecoveryBedBase", Vector3.new(7.9, 0.55, 3.9), cframeAt(origin, 9.5, 0.78, 0), Color3.fromRGB(77, 91, 101), Enum.Material.Metal)
	createPart(recovery, "RecoveryPillow", Vector3.new(1.45, 0.35, 2.8), cframeAt(origin, 6.15, 1.92, 0), Color3.fromRGB(220, 223, 221), Enum.Material.Fabric)
	local recoveryPrompt = createPrompt(recoveryBed, "Inspect", "Recovery Bed", 0)
	recoveryPrompt.MaxActivationDistance = 12
	tag(recoveryBed, Constants.Tags.InfirmaryRecoveryBed)
	recovery.PrimaryPart = recoveryBed

	local ceilingLight = createPart(room, "RecoveryCeilingLight", Vector3.new(5.2, 0.22, 2.7), cframeAt(origin, 9.5, height - 1.1, 0), Color3.fromRGB(230, 222, 185), Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Name = "RecoveryBedLight"
	light.Brightness = 1.71
	light.Color = Color3.fromRGB(255, 244, 205)
	light.Range = 18
	light.Parent = ceilingLight
	mark(light)

	local monitor = createPart(room, "InfirmaryMonitor", Vector3.new(5.4, 3.2, 0.34), cframeAt(origin, 18.6, 4.8, -4.6) * CFrame.Angles(0, math.rad(-28), 0), Color3.fromRGB(18, 30, 33), Enum.Material.Metal)
	createSurfaceText(monitor, "InfirmaryMonitorText", "STATUS\nSTABILIZED\n?", Enum.NormalId.Front, Color3.fromRGB(119, 255, 203), Color3.fromRGB(18, 30, 33))
	createPrompt(monitor, "Read", "Patient Monitor", 0)
	tag(monitor, Constants.Tags.InfirmaryMonitor)

	for bedIndex, zOffset in ipairs({ -14, 14 }) do
		local bed = createPart(room, "InfirmarySideBed" .. bedIndex, Vector3.new(6.5, 0.6, 3.0), cframeAt(origin, -7.5, 1.25, zOffset), Color3.fromRGB(206, 215, 214), Enum.Material.SmoothPlastic)
		createPart(room, "InfirmarySideBedBase" .. bedIndex, Vector3.new(6.9, 0.5, 3.4), cframeAt(origin, -7.5, 0.76, zOffset), Color3.fromRGB(83, 94, 104), Enum.Material.Metal)
		local curtain = createPart(room, "InfirmaryPrivacyCurtain" .. bedIndex, Vector3.new(0.18, 5.2, 7.2), cframeAt(origin, -2.8, 4.1, zOffset), Color3.fromRGB(141, 229, 219), Enum.Material.Fabric)
		curtain.Transparency = 0.22
		curtain:SetAttribute("BaseTransparency", 0.22)
		bed:SetAttribute("InfirmarySideBed", bedIndex)
	end

	for cabinetIndex, data in ipairs({
		{ X = 19.8, Z = 13.2, Label = "STERILE\nENOUGH" },
		{ X = 20.2, Z = -14.0, Label = "CABINET\n03" },
	}) do
		local cabinet = createPart(room, "InfirmaryCabinet" .. cabinetIndex, Vector3.new(3.4, 5.8, 1.2), cframeAt(origin, data.X, 3.2, data.Z), Color3.fromRGB(194, 203, 206), Enum.Material.Metal)
		createSurfaceText(cabinet, "InfirmaryCabinetText", data.Label, Enum.NormalId.Front, Color3.fromRGB(64, 86, 92), Color3.fromRGB(194, 203, 206))
		createPrompt(cabinet, "Open", "Medical Cabinet", 0)
		tag(cabinet, Constants.Tags.InfirmaryCabinet)
	end

	local sink = createPart(room, "InfirmarySink", Vector3.new(4.6, 1.4, 2.2), cframeAt(origin, -18.8, 2.2, -15.8), Color3.fromRGB(203, 210, 211), Enum.Material.Metal)
	createPart(room, "InfirmaryFaucet", Vector3.new(0.34, 1.25, 0.34), cframeAt(origin, -18.8, 3.28, -16.7), Color3.fromRGB(148, 162, 170), Enum.Material.Metal)
	sink:SetAttribute("BunkerEnergyIgnored", true)

	local tray = makeModel(room, "InfirmaryNourishmentTray")
	local trayBase = createPart(tray, "InfirmarySnackTray", Vector3.new(3.6, 0.22, 1.8), cframeAt(origin, 4.6, 2.35, 3.6), Color3.fromRGB(196, 202, 203), Enum.Material.Metal)
	local cup = createPart(tray, "InfirmaryWaterCup", Vector3.new(0.72, 0.82, 0.72), trayBase.CFrame * CFrame.new(-0.9, 0.52, 0), Color3.fromRGB(134, 238, 255), Enum.Material.Glass)
	cup.Shape = Enum.PartType.Cylinder
	local ration = createPart(tray, "InfirmaryRationBar", Vector3.new(1.35, 0.28, 0.62), trayBase.CFrame * CFrame.new(0.75, 0.35, 0), Color3.fromRGB(255, 202, 103), Enum.Material.SmoothPlastic)
	createSurfaceText(ration, "RationText", "STABLE", Enum.NormalId.Top, Color3.fromRGB(64, 42, 26), Color3.fromRGB(255, 202, 103))
	createPrompt(trayBase, "Accept", "Stabilization Snack", 0)
	tag(trayBase, Constants.Tags.InfirmaryNourishment)
	tray.PrimaryPart = trayBase

	makeAtomicBoomerang(room, "InfirmaryAtomicBoomerang", cframeAt(origin, width / 2 - 0.58, 11.0, 11) * CFrame.Angles(0, math.rad(-90), 0), 0.62, ATOMIC_COLORS.Orange)
	makeAtomicStarburst(room, "InfirmaryAtomicStarburst", cframeAt(origin, -width / 2 + 0.58, 10.8, -10.2) * CFrame.Angles(0, math.rad(90), 0), 0.58, ATOMIC_COLORS.Cream, ATOMIC_COLORS.Pink)

	room.PrimaryPart = recoveryBed
	return {
		Model = room,
		LightSwitch = controls.LightSwitch,
		ResetRoomButton = controls.ResetRoomButton,
		ReferenceBook = controls.ReferenceBook,
		RecoveryBed = recoveryBed,
	}
end

local function makeGymRoom(roomFolder)
	local room = makeModel(roomFolder, "GymRoom")
	local origin = GYM_ORIGIN
	local width = 56
	local depth = 58
	local height = 20
	local wallColor = Color3.fromRGB(78, 67, 77)
	local floorColor = Color3.fromRGB(66, 76, 83)

	createPart(room, "GymFloor", Vector3.new(width, 1, depth), cframeAt(origin, 0, 0, 0), floorColor, Enum.Material.Concrete)
	createPart(room, "GymCeiling", Vector3.new(width, 1, depth), cframeAt(origin, 0, height, 0), Color3.fromRGB(45, 42, 52), Enum.Material.Concrete)
	createPart(room, "GymNorthWall", Vector3.new(width, height, 1), cframeAt(origin, 0, height / 2, -depth / 2), Color3.fromRGB(72, 58, 67), Enum.Material.SmoothPlastic)
	createPart(room, "GymSouthWall", Vector3.new(width, height, 1), cframeAt(origin, 0, height / 2, depth / 2), wallColor, Enum.Material.SmoothPlastic)
	createPart(room, "GymEastWall", Vector3.new(1, height, depth), cframeAt(origin, width / 2, height / 2, 0), Color3.fromRGB(70, 63, 79), Enum.Material.SmoothPlastic)
	local westSegmentDepth = (depth - 12) / 2
	createPart(room, "GymWestWallNorth", Vector3.new(1, height, westSegmentDepth), cframeAt(origin, -width / 2, height / 2, -17.5), Color3.fromRGB(70, 63, 79), Enum.Material.SmoothPlastic)
	createPart(room, "GymWestWallSouth", Vector3.new(1, height, westSegmentDepth), cframeAt(origin, -width / 2, height / 2, 17.5), Color3.fromRGB(70, 63, 79), Enum.Material.SmoothPlastic)
	createPart(room, "GymDoorHeader", Vector3.new(1, height - 8.4, 12), cframeAt(origin, -width / 2, 14.1, 0), Color3.fromRGB(64, 58, 74), Enum.Material.SmoothPlastic)

	createSpawnLocation(room, "GymSpawn", "Gym", GYM_SPAWN_CFRAME, Color3.fromRGB(255, 142, 191), false)
	local controls = makeRoomControlPanel(
		room,
		"GymInsideControlPanel",
		CFrame.new(origin + Vector3.new(-width / 2 + 0.58, 5.4, depth / 2 - 7.2), origin + Vector3.new(0, 5.4, depth / 2 - 7.2)),
		"Gym",
		"GYM",
		{
			IncludeReset = true,
			PanelLabel = "CONDITIONING CONTROLS",
			LightPromptObjectText = "Gym Light Switch",
			LogText = "GYM\nLOG\nOPEN",
		}
	)

	local title = createPart(room, "GymTitleSign", Vector3.new(18, 2.5, 0.3), cframeAt(origin, 0, 15.1, depth / 2 - 0.72), Color3.fromRGB(255, 142, 191), Enum.Material.Neon)
	createDoubleSidedSurfaceText(title, "GymTitleText", "PHYSICAL CONDITIONING\nFIT CITIZENS BUILD TOMORROW", Enum.NormalId.Front, Color3.fromRGB(39, 25, 33), Color3.fromRGB(255, 142, 191))
	createNoTouchClock(
		room,
		"GymWallClock",
		"Gym",
		Vector3.new(6.4, 1.9, 0.24),
		cframeAt(origin, width / 2 - 0.62, 11.0, -9.0) * CFrame.Angles(0, math.rad(-90), 0),
		Enum.NormalId.Left
	)

	for treadmillIndex, zOffset in ipairs({ -12, -5 }) do
		local treadmill = makeModel(room, "GymTreadmill" .. treadmillIndex)
		local base = createPart(treadmill, "TreadmillBase", Vector3.new(8.6, 0.42, 3.1), cframeAt(origin, -11.5, 1.0, zOffset), Color3.fromRGB(31, 35, 43), Enum.Material.Metal)
		createPart(treadmill, "TreadmillBelt", Vector3.new(7.4, 0.14, 2.2), cframeAt(origin, -11.5, 1.34, zOffset), Color3.fromRGB(12, 16, 18), Enum.Material.SmoothPlastic)
		local console = createPart(treadmill, "TreadmillConsole", Vector3.new(3.2, 1.25, 0.44), cframeAt(origin, -15.2, 2.6, zOffset), Color3.fromRGB(24, 35, 44), Enum.Material.Metal)
		createSurfaceText(console, "TreadmillText", "PACE\nACCEPTED", Enum.NormalId.Front, Color3.fromRGB(119, 255, 203), Color3.fromRGB(24, 35, 44))
		createPrompt(console, "Start", "Treadmill", 0)
		tag(console, Constants.Tags.GymTreadmill)
		treadmill.PrimaryPart = base
	end

	for bikeIndex, zOffset in ipairs({ 6, 13 }) do
		local bike = makeModel(room, "GymBike" .. bikeIndex)
		local wheelA = createPart(bike, "BikeWheelA", Vector3.new(2.0, 0.18, 2.0), cframeAt(origin, -13.4, 1.8, zOffset) * CFrame.Angles(math.rad(90), 0, 0), Color3.fromRGB(255, 229, 161), Enum.Material.Metal)
		wheelA.Shape = Enum.PartType.Cylinder
		local wheelB = createPart(bike, "BikeWheelB", Vector3.new(2.0, 0.18, 2.0), cframeAt(origin, -8.4, 1.8, zOffset) * CFrame.Angles(math.rad(90), 0, 0), Color3.fromRGB(255, 229, 161), Enum.Material.Metal)
		wheelB.Shape = Enum.PartType.Cylinder
		createBeamBetween(bike, "BikeFrame", Vector3.new(origin.X - 13.4, origin.Y + 2.3, origin.Z + zOffset), Vector3.new(origin.X - 8.4, origin.Y + 2.3, origin.Z + zOffset), 0.18, Color3.fromRGB(119, 255, 203), Enum.Material.Neon)
		local seat = createPart(bike, "BikeSeat", Vector3.new(1.8, 0.38, 1.2), cframeAt(origin, -10.9, 3.4, zOffset), Color3.fromRGB(39, 31, 34), Enum.Material.Fabric)
		createPrompt(seat, "Pedal", "Stationary Bike", 0)
		tag(seat, Constants.Tags.GymBike)
		bike.PrimaryPart = seat
	end

	local weightRack = makeModel(room, "GymWeightRack")
	local rack = createPart(weightRack, "GymWeightRackFrame", Vector3.new(8.8, 3.2, 0.42), cframeAt(origin, 14.5, 2.8, -14.5), Color3.fromRGB(38, 42, 50), Enum.Material.Metal)
	for weightIndex = 1, 6 do
		local weight = createPart(weightRack, "GymWeight" .. weightIndex, Vector3.new(1.0 + weightIndex * 0.11, 0.36, 1.0 + weightIndex * 0.11), rack.CFrame * CFrame.new(-3.6 + weightIndex * 1.2, -0.2 + (weightIndex % 2) * 0.9, -0.45), Color3.fromRGB(255, 134, 58), Enum.Material.Metal)
		weight.Shape = Enum.PartType.Cylinder
	end
	createPrompt(rack, "Lift", "Approved Mass Rack", 0)
	tag(rack, Constants.Tags.GymWeights)
	weightRack.PrimaryPart = rack

	local waterStation = createPart(room, "GymWaterStation", Vector3.new(3.4, 5.0, 1.1), cframeAt(origin, 20.5, 3.3, 13.5), Color3.fromRGB(62, 86, 98), Enum.Material.Metal)
	createSurfaceText(waterStation, "GymWaterText", "HYDRATE\nTHEN CONTINUE", Enum.NormalId.Front, Color3.fromRGB(203, 255, 255), Color3.fromRGB(62, 86, 98))
	createPrompt(waterStation, "Drink", "Recovery Water", 0)
	tag(waterStation, Constants.Tags.GymWaterStation)

	for matIndex, data in ipairs({
		{ X = 6, Z = -6, Color = Color3.fromRGB(119, 255, 203) },
		{ X = 8, Z = 7, Color = Color3.fromRGB(255, 202, 103) },
		{ X = 16, Z = 2, Color = Color3.fromRGB(255, 142, 191) },
	}) do
		local mat = createPart(room, "GymExerciseMat" .. matIndex, Vector3.new(7.2, 0.14, 3.2), cframeAt(origin, data.X, 1.08, data.Z) * CFrame.Angles(0, math.rad((matIndex - 2) * 10), 0), data.Color, Enum.Material.SmoothPlastic)
		mat:SetAttribute("CosmicSurface", true)
	end

	makeAtomicStarburst(room, "GymAtomicStarburst", cframeAt(origin, width / 2 - 0.58, 13.4, -15.5) * CFrame.Angles(0, math.rad(-90), 0), 0.72, ATOMIC_COLORS.Orange, ATOMIC_COLORS.Cream)
	makeAtomicBoomerang(room, "GymAtomicBoomerang", cframeAt(origin, -width / 2 + 0.58, 12.2, 14) * CFrame.Angles(0, math.rad(90), 0), 0.76, ATOMIC_COLORS.NeonPink)

	room.PrimaryPart = title
	return {
		Model = room,
		LightSwitch = controls.LightSwitch,
		ResetRoomButton = controls.ResetRoomButton,
		ReferenceBook = controls.ReferenceBook,
	}
end

local function makeTopDownArenaRoom(roomFolder)
	local room = makeModel(roomFolder, "TopDownArenaRoom")
	local origin = TOP_DOWN_ARENA_ORIGIN
	local width = 124
	local depth = 128
	local height = 24
	local floorColor = Color3.fromRGB(45, 68, 78)

	createPart(room, "TopDownArenaFloor", Vector3.new(width, 1, depth), cframeAt(origin, 0, 0, 0), floorColor, Enum.Material.Concrete)
	createPart(room, "TopDownArenaFrontWall", Vector3.new(width, height, 1), cframeAt(origin, 0, height / 2, depth / 2), Color3.fromRGB(41, 47, 61), Enum.Material.SmoothPlastic)
	createPart(room, "TopDownArenaBackWall", Vector3.new(width, height, 1), cframeAt(origin, 0, height / 2, -depth / 2), Color3.fromRGB(36, 47, 57), Enum.Material.SmoothPlastic)
	createPart(room, "TopDownArenaLeftWall", Vector3.new(1, height, depth), cframeAt(origin, -width / 2, height / 2, 0), Color3.fromRGB(50, 42, 64), Enum.Material.SmoothPlastic)
	createPart(room, "TopDownArenaRightWall", Vector3.new(1, height, depth), cframeAt(origin, width / 2, height / 2, 0), Color3.fromRGB(44, 55, 62), Enum.Material.SmoothPlastic)

	for beamIndex, zOffset in ipairs({ depth / 2 - 18, depth / 2 - 42, 0, -depth / 2 + 30 }) do
		local beam = createPart(room, "TopDownArenaOpenCeilingBeam" .. beamIndex, Vector3.new(width - 10, 0.38, 0.38), cframeAt(origin, 0, height + 1.1, zOffset), BOWLING_COSMIC_COLORS[((beamIndex - 1) % #BOWLING_COSMIC_COLORS) + 1], Enum.Material.Neon)
		beam.CanCollide = false
		beam:SetAttribute("BaseCanCollide", false)
	end

	createSpawnLocation(room, "TopDownArenaSpawn", "TopDownArena", TOP_DOWN_ARENA_SPAWN_CFRAME, Color3.fromRGB(93, 217, 255), false)
	local safetyFloor = createPart(room, "TopDownArenaSafetyNet", Vector3.new(width + 18, 1, depth + 18), cframeAt(origin, 0, -7, 0), Color3.fromRGB(93, 217, 255), Enum.Material.Neon)
	safetyFloor.Transparency = 0.86
	safetyFloor:SetAttribute("BaseTransparency", safetyFloor.Transparency)
	safetyFloor:SetAttribute("DestinationCFrame", TOP_DOWN_ARENA_SPAWN_CFRAME)

	local returnDoor = createPart(room, "TopDownSleepingReturnDoor", Vector3.new(8.4, 7.8, 0.42), cframeAt(origin, 0, 4.4, depth / 2 - 0.55), Color3.fromRGB(83, 64, 122), Enum.Material.Wood)
	returnDoor:SetAttribute("DestinationCFrame", TOP_DOWN_SLEEPING_RETURN_CFRAME)
	returnDoor:SetAttribute("DestinationName", "Sleeping Quarters")
	returnDoor:SetAttribute("TravelMessage", "Back to Sleeping Quarters. The camera climbs down like nothing happened.")
	createDoubleSidedSurfaceText(returnDoor, "TopDownReturnText", "SLEEPING\nQUARTERS", Enum.NormalId.Front, Color3.fromRGB(255, 235, 149), Color3.fromRGB(83, 64, 122))
	createPrompt(returnDoor, "Exit", "Sleeping Quarters", 0)
	tag(returnDoor, Constants.Tags.SecretRoomExit)

	local controls = makeRoomControlPanel(
		room,
		"TopDownInsideControlPanel",
		CFrame.new(origin + Vector3.new(-width / 2 + 0.58, 5.15, depth / 2 - 15), origin + Vector3.new(0, 5.15, depth / 2 - 15)),
		"TopDownArena",
		"TRAINING ARENA",
		{
			IncludeReset = true,
			PanelLabel = "ARENA CONTROLS",
			LightPromptObjectText = "Training Arena Light Switch",
			LogText = "TRAINING\nLOG\nOPEN",
		}
	)

	local title = createPart(room, "TopDownArenaTitleSign", Vector3.new(22, 2.7, 0.32), cframeAt(origin, 0, 13.6, depth / 2 - 0.82), Color3.fromRGB(93, 217, 255), Enum.Material.Neon)
	createDoubleSidedSurfaceText(title, "TopDownArenaTitleText", "TRAINING ARENA\nPLEASE THROW RESPONSIBLY", Enum.NormalId.Front, Color3.fromRGB(18, 24, 36), Color3.fromRGB(93, 217, 255))

	createNoTouchClock(
		room,
		"TopDownArenaWallClock",
		"TopDownArena",
		Vector3.new(7.8, 2.0, 0.25),
		cframeAt(origin, -21.5, 8.2, depth / 2 - 0.66),
		Enum.NormalId.Front
	)

	local cameraConsole = createPart(room, "TopDownCameraConsole", Vector3.new(5.2, 2.8, 0.78), cframeAt(origin, 12.5, 2.0, depth / 2 - 12), Color3.fromRGB(32, 37, 45), Enum.Material.Metal)
	createSurfaceText(cameraConsole, "TopDownCameraConsoleText", "CAMERA\nMODE", Enum.NormalId.Front, Color3.fromRGB(119, 255, 203), Color3.fromRGB(32, 37, 45))
	createPrompt(cameraConsole, "Toggle", "Arena Camera Console", 0)
	tag(cameraConsole, Constants.Tags.TopDownCameraConsole)

	local function makeScoreboard(name, xOffset, zOffset, face)
		local board = createPart(room, name, Vector3.new(0.32, 6.2, 12.5), cframeAt(origin, xOffset, 9.2, zOffset), Color3.fromRGB(18, 24, 36), Enum.Material.Metal)
		createSurfaceText(board, "TopDownScoreText", "ARENA ROUND\nREADY UP\nNORTH 0  SOUTH 0\nROUND 2:00", face, Color3.fromRGB(119, 255, 203), Color3.fromRGB(18, 24, 36))
		createPrompt(board, "Check", "Splash Scoreboard", 0)
		tag(board, Constants.Tags.TopDownScoreboard)
		return board
	end

	local scoreboard = makeScoreboard("TopDownScoreboardSE", width / 2 - 0.62, depth / 2 - 25, Enum.NormalId.Left)
	makeScoreboard("TopDownScoreboardNE", width / 2 - 0.62, -depth / 2 + 25, Enum.NormalId.Left)
	makeScoreboard("TopDownScoreboardSW", -width / 2 + 0.62, depth / 2 - 25, Enum.NormalId.Right)
	makeScoreboard("TopDownScoreboardNW", -width / 2 + 0.62, -depth / 2 + 25, Enum.NormalId.Right)

	for _, lineData in ipairs({
		{ Name = "CenterVertical", Size = Vector3.new(1.2, 0.08, depth - 22), Offset = Vector3.new(0, 0.62, -5), Color = Color3.fromRGB(119, 255, 203) },
		{ Name = "CenterHorizontal", Size = Vector3.new(width - 22, 0.08, 1.2), Offset = Vector3.new(0, 0.63, -5), Color = Color3.fromRGB(255, 202, 103) },
		{ Name = "FrontArcMarker", Size = Vector3.new(34, 0.1, 1.2), Offset = Vector3.new(0, 0.64, depth / 2 - 26), Color = Color3.fromRGB(255, 142, 191) },
		{ Name = "BackArcMarker", Size = Vector3.new(34, 0.1, 1.2), Offset = Vector3.new(0, 0.64, -depth / 2 + 26), Color = Color3.fromRGB(255, 142, 191) },
	}) do
		local line = createPart(room, "TopDownArena" .. lineData.Name, lineData.Size, cframeAt(origin, lineData.Offset.X, lineData.Offset.Y, lineData.Offset.Z), lineData.Color, Enum.Material.Neon)
		line.CanCollide = false
		line:SetAttribute("BaseCanCollide", false)
	end

	local outerRing = createPart(room, "TopDownTargetOuterRing", Vector3.new(30, 0.18, 30), cframeAt(origin, 0, 0.78, -10), Color3.fromRGB(93, 217, 255), Enum.Material.Neon)
	outerRing.Shape = Enum.PartType.Cylinder
	outerRing.CanCollide = false
	outerRing:SetAttribute("BaseCanCollide", false)
	local midRing = createPart(room, "TopDownTargetMiddleRing", Vector3.new(22, 0.2, 22), cframeAt(origin, 0, 0.9, -10), Color3.fromRGB(255, 232, 92), Enum.Material.Neon)
	midRing.Shape = Enum.PartType.Cylinder
	midRing.CanCollide = false
	midRing:SetAttribute("BaseCanCollide", false)
	local targetRing = createPart(room, "TopDownTargetRing", Vector3.new(12, 0.24, 12), cframeAt(origin, 0, 1.03, -10), Color3.fromRGB(255, 88, 128), Enum.Material.Neon)
	targetRing.Shape = Enum.PartType.Cylinder
	targetRing.CanCollide = false
	targetRing:SetAttribute("BaseCanCollide", false)
	targetRing:SetAttribute("ScoreRadius", 15)
	targetRing:SetAttribute("TargetPosition", origin + Vector3.new(0, 1.15, -10))
	createSurfaceText(targetRing, "TopDownTargetText", "POINTS", Enum.NormalId.Top, Color3.fromRGB(255, 246, 220), Color3.fromRGB(255, 88, 128))
	createPrompt(targetRing, "Inspect", "Big Point Ring", 0)
	tag(targetRing, Constants.Tags.TopDownTargetRing)

	local targetRail = createPart(room, "TopDownPracticeTargetRail", Vector3.new(52, 0.18, 0.24), cframeAt(origin, 0, 1.1, -42), Color3.fromRGB(255, 202, 103), Enum.Material.Neon)
	targetRail.CanCollide = false
	targetRail:SetAttribute("BaseCanCollide", false)
	local splashTarget = createPart(room, "TopDownPracticeTarget", Vector3.new(3.4, 4.6, 0.38), cframeAt(origin, -25, 3.45, -42), Color3.fromRGB(255, 142, 191), Enum.Material.SmoothPlastic)
	splashTarget:SetAttribute("TrackStartCFrame", cframeAt(origin, -25, 3.45, -42))
	splashTarget:SetAttribute("TrackEndCFrame", cframeAt(origin, 25, 3.45, -42))
	createSurfaceText(splashTarget, "TopDownPracticeTargetText", "PLAYER?\nTARGET", Enum.NormalId.Front, Color3.fromRGB(39, 30, 42), Color3.fromRGB(255, 142, 191))
	createPrompt(splashTarget, "Inspect", "Practice Splash Target", 0)
	tag(splashTarget, Constants.Tags.TopDownSplashTarget)
	local oppositeTargetRail = createPart(room, "TopDownOppositeTargetRail", Vector3.new(52, 0.18, 0.24), cframeAt(origin, 0, 1.1, 24), Color3.fromRGB(150, 112, 255), Enum.Material.Neon)
	oppositeTargetRail.CanCollide = false
	oppositeTargetRail:SetAttribute("BaseCanCollide", false)
	local oppositeTarget = createPart(room, "TopDownOppositePracticeTarget", Vector3.new(3.4, 4.6, 0.38), cframeAt(origin, 25, 3.45, 24) * CFrame.Angles(0, math.rad(180), 0), Color3.fromRGB(119, 255, 203), Enum.Material.SmoothPlastic)
	oppositeTarget:SetAttribute("TrackStartCFrame", cframeAt(origin, 25, 3.45, 24) * CFrame.Angles(0, math.rad(180), 0))
	oppositeTarget:SetAttribute("TrackEndCFrame", cframeAt(origin, -25, 3.45, 24) * CFrame.Angles(0, math.rad(180), 0))
	createSurfaceText(oppositeTarget, "TopDownOppositePracticeTargetText", "OTHER\nTARGET", Enum.NormalId.Back, Color3.fromRGB(18, 42, 38), Color3.fromRGB(119, 255, 203))
	createPrompt(oppositeTarget, "Inspect", "Opposite Splash Target", 0)
	tag(oppositeTarget, Constants.Tags.TopDownSplashTarget)

	local function makeReadyStation(teamId, teamLabel, zOffset, face, insideZ, color)
		local glass = createPart(room, "TopDown" .. teamId .. "ReadyGlass", Vector3.new(31, 5.6, 0.35), cframeAt(origin, 0, 3.7, zOffset), color, Enum.Material.Glass)
		glass.Transparency = 0.42
		glass:SetAttribute("BaseTransparency", glass.Transparency)
		createSurfaceText(glass, "TopDownReadyWallText", teamLabel .. "\nREADY WALL", face, Color3.fromRGB(18, 24, 36), color)

		local readyButton = createPart(room, "TopDown" .. teamId .. "ReadyButton", Vector3.new(5.8, 1.15, 0.62), cframeAt(origin, 0, 4.2, zOffset + insideZ * 0.62), color, Enum.Material.Neon)
		readyButton:SetAttribute("TopDownTeamId", teamId)
		createSurfaceText(readyButton, "TopDownReadyStatusText", "READY\n" .. teamLabel, face, Color3.fromRGB(18, 24, 36), color)
		createPrompt(readyButton, "Ready", teamLabel .. " Ready Station", 0)
		tag(readyButton, Constants.Tags.TopDownReadyButton)

		for _, option in ipairs({
			{ Seconds = 60, Label = "1 MIN", X = -9 },
			{ Seconds = 120, Label = "2 MIN", X = 0 },
			{ Seconds = 300, Label = "5 MIN", X = 9 },
		}) do
			local roundButton = createPart(room, "TopDown" .. teamId .. "Round" .. tostring(option.Seconds), Vector3.new(5.1, 0.9, 0.54), cframeAt(origin, option.X, 2.35, zOffset + insideZ * 0.62), Color3.fromRGB(32, 37, 45), Enum.Material.Metal)
			roundButton:SetAttribute("TopDownTeamId", teamId)
			roundButton:SetAttribute("RoundSeconds", option.Seconds)
			createSurfaceText(roundButton, "TopDownRoundOptionText", option.Label, face, color, Color3.fromRGB(32, 37, 45))
			createPrompt(roundButton, "Set", option.Label .. " Round", 0)
			tag(roundButton, Constants.Tags.TopDownRoundButton)
		end
	end

	makeReadyStation("South", "SOUTH", depth / 2 - 17, Enum.NormalId.Front, -1, Color3.fromRGB(255, 142, 191))
	makeReadyStation("North", "NORTH", -depth / 2 + 17, Enum.NormalId.Back, 1, Color3.fromRGB(119, 255, 203))

	local function makeBucket(name, xOffset, zOffset, label, isRefill, throwMode)
		local bucket = createPart(room, name, Vector3.new(3.1, 1.45, 3.1), cframeAt(origin, xOffset, 1.2, zOffset), Color3.fromRGB(93, 217, 255), Enum.Material.Metal)
		bucket.Shape = Enum.PartType.Cylinder
		bucket:SetAttribute("TargetPosition", origin + Vector3.new(0, 1.15, -10))
		bucket:SetAttribute("IsRefillBucket", isRefill == true)
		bucket:SetAttribute("ThrowMode", throwMode or "Auto")
		createSurfaceText(bucket, name .. "Text", label, Enum.NormalId.Top, Color3.fromRGB(18, 24, 36), Color3.fromRGB(93, 217, 255))
		createPrompt(bucket, isRefill and "Refill" or "Load", isRefill and "Refill Balloon Bucket" or "Water Balloon Bucket", 0)
		tag(bucket, Constants.Tags.TopDownWaterBalloonBucket)

		for balloonIndex = 1, 5 do
			local angle = math.rad(balloonIndex * 72)
			local balloon = createPart(
				room,
				name .. "Balloon" .. balloonIndex,
				Vector3.new(0.58, 0.58, 0.58),
				cframeAt(origin, xOffset + math.cos(angle) * 0.82, 2.16 + (balloonIndex % 2) * 0.15, zOffset + math.sin(angle) * 0.82),
				if balloonIndex % 2 == 0 then Color3.fromRGB(119, 255, 203) else Color3.fromRGB(255, 142, 191),
				Enum.Material.SmoothPlastic
			)
			balloon.Shape = Enum.PartType.Ball
			balloon.CanCollide = false
			balloon:SetAttribute("BaseCanCollide", false)
		end

		return bucket
	end

	makeBucket("TopDownFrontLeftBucket", -44, depth / 2 - 26, "LOB", false, "Ring")
	makeBucket("TopDownFrontRightBucket", 44, depth / 2 - 26, "SPLASH", false, "Splash")
	makeBucket("TopDownBackLeftBucket", -44, -depth / 2 + 28, "ARC", false, "Ring")
	makeBucket("TopDownBackRightBucket", 44, -depth / 2 + 28, "THROW", false, "Splash")
	makeBucket("TopDownRefillBucket", 0, depth / 2 - 32, "REFILL", true, "Auto")
	makeBucket("TopDownFarRefillBucket", 0, -depth / 2 + 32, "REFILL", true, "Auto")

	local pipe = createPart(room, "TopDownRefillPipe", Vector3.new(0.72, 8.4, 0.72), cframeAt(origin, 0, 7.0, depth / 2 - 32), Color3.fromRGB(119, 255, 203), Enum.Material.Neon)
	pipe.Shape = Enum.PartType.Cylinder
	pipe.CanCollide = false
	pipe:SetAttribute("BaseCanCollide", false)
	local drip = Instance.new("ParticleEmitter")
	drip.Name = "TopDownRefillDrip"
	drip.Color = ColorSequence.new(Color3.fromRGB(93, 217, 255))
	drip.Lifetime = NumberRange.new(0.8, 1.2)
	drip.Rate = 10
	drip.Speed = NumberRange.new(2, 4)
	drip.SpreadAngle = Vector2.new(8, 8)
	drip.Parent = pipe
	mark(drip)

	local farPipe = createPart(room, "TopDownFarRefillPipe", Vector3.new(0.72, 8.4, 0.72), cframeAt(origin, 0, 7.0, -depth / 2 + 32), Color3.fromRGB(119, 255, 203), Enum.Material.Neon)
	farPipe.Shape = Enum.PartType.Cylinder
	farPipe.CanCollide = false
	farPipe:SetAttribute("BaseCanCollide", false)
	local farDrip = Instance.new("ParticleEmitter")
	farDrip.Name = "TopDownFarRefillDrip"
	farDrip.Color = ColorSequence.new(Color3.fromRGB(93, 217, 255))
	farDrip.Lifetime = NumberRange.new(0.8, 1.2)
	farDrip.Rate = 10
	farDrip.Speed = NumberRange.new(2, 4)
	farDrip.SpreadAngle = Vector2.new(8, 8)
	farDrip.Parent = farPipe
	mark(farDrip)

	makeAtomicStarburst(room, "TopDownAtomicStarburst", cframeAt(origin, width / 2 - 0.58, 13.4, -18) * CFrame.Angles(0, math.rad(-90), 0), 0.9, ATOMIC_COLORS.Pink, ATOMIC_COLORS.Cream)
	makeAtomicBoomerang(room, "TopDownAtomicBoomerang", cframeAt(origin, -width / 2 + 0.58, 12.5, -34) * CFrame.Angles(0, math.rad(90), 0), 0.92, ATOMIC_COLORS.Orange)
	makeAtomicDiamondCluster(room, "TopDownAtomicDiamonds", cframeAt(origin, 24, 12.0, -depth / 2 + 0.62), 0.72)

	room.PrimaryPart = title
	return {
		Model = room,
		ExitDoor = returnDoor,
		LightSwitch = controls.LightSwitch,
		ResetRoomButton = controls.ResetRoomButton,
		ReferenceBook = controls.ReferenceBook,
		Scoreboard = scoreboard,
		TargetRing = targetRing,
		SafetyFloor = safetyFloor,
	}
end

local function makeHallway(roomFolder)
	local hallway = makeModel(roomFolder, "DoorHallway")

	createPart(hallway, "HallwayFloor", Vector3.new(13, 1, 56), CFrame.new(0, 0, 45), Color3.fromRGB(92, 101, 112), Enum.Material.Concrete)
	local hallwayLeftWall = createPart(hallway, "HallwayLeftWall", Vector3.new(1, 10, 56), CFrame.new(-6.5, 5, 45), Color3.fromRGB(150, 156, 168), Enum.Material.SmoothPlastic)
	local hallwayRightWall = createPart(hallway, "HallwayRightWall", Vector3.new(1, 10, 56), CFrame.new(6.5, 5, 45), Color3.fromRGB(150, 156, 168), Enum.Material.SmoothPlastic)
	applyTextureToFace(hallwayLeftWall, "HallwayLeftWallTexture", MAIN_HALLWAY_WALL_TEXTURE_ID, Enum.NormalId.Right, 8)
	applyTextureToFace(hallwayRightWall, "HallwayRightWallTexture", MAIN_HALLWAY_WALL_TEXTURE_ID, Enum.NormalId.Left, 8)
	createPart(hallway, "HallwayCeiling", Vector3.new(13, 1, 56), CFrame.new(0, 10, 45), Color3.fromRGB(116, 119, 128), Enum.Material.Concrete)
	createPart(hallway, "IslandApproachFloor", Vector3.new(9, 1, 48), CFrame.new(0, 0, 97), Color3.fromRGB(65, 84, 104), Enum.Material.Concrete)
	createPart(hallway, "IslandApproachLeftWallBeforeStair", Vector3.new(1, 9, 5.8), CFrame.new(-4.5, 4.5, 75.9), Color3.fromRGB(76, 103, 130), Enum.Material.SmoothPlastic)
	createPart(hallway, "IslandApproachLeftWallAfterStair", Vector3.new(1, 9, 35.8), CFrame.new(-4.5, 4.5, 103.1), Color3.fromRGB(76, 103, 130), Enum.Material.SmoothPlastic)
	createPart(hallway, "IslandApproachRightWall", Vector3.new(1, 9, 48), CFrame.new(4.5, 4.5, 97), Color3.fromRGB(76, 103, 130), Enum.Material.SmoothPlastic)
	createPart(hallway, "IslandApproachCeiling", Vector3.new(9, 1, 48), CFrame.new(0, 9.5, 97), Color3.fromRGB(41, 65, 91), Enum.Material.Concrete)
	createPart(hallway, "IslandApproachArchTop", Vector3.new(13, 2, 1), CFrame.new(0, 9, 73), Color3.fromRGB(150, 156, 168), Enum.Material.SmoothPlastic)
	createPart(hallway, "IslandApproachArchLeft", Vector3.new(2, 9, 1), CFrame.new(-5.5, 4.5, 73), Color3.fromRGB(150, 156, 168), Enum.Material.SmoothPlastic)
	createPart(hallway, "IslandApproachArchRight", Vector3.new(2, 9, 1), CFrame.new(5.5, 4.5, 73), Color3.fromRGB(150, 156, 168), Enum.Material.SmoothPlastic)
	local ziplineSightBlocker = createPart(hallway, "IslandApproachZiplineSightBlocker", Vector3.new(1.4, 54, 58), CFrame.new(5.75, 35, 101), Color3.fromRGB(41, 65, 91), Enum.Material.SmoothPlastic)
	ziplineSightBlocker.CanCollide = false
	ziplineSightBlocker:SetAttribute("BaseCanCollide", false)
	local ziplineOverheadBlocker = createPart(hallway, "IslandApproachOverheadSightBlocker", Vector3.new(10.4, 48, 58), CFrame.new(0, 34, 101), Color3.fromRGB(41, 65, 91), Enum.Material.SmoothPlastic)
	ziplineOverheadBlocker.CanCollide = false
	ziplineOverheadBlocker:SetAttribute("BaseCanCollide", false)

	local oceanSign = createPart(hallway, "IslandApproachSign", Vector3.new(7.2, 1.9, 0.3), CFrame.new(0, 8.15, 88), Color3.fromRGB(112, 222, 255), Enum.Material.SmoothPlastic)
	oceanSign.CanCollide = false
	oceanSign:SetAttribute("BaseCanCollide", false)
	createSurfaceText(oceanSign, "IslandApproachSignText", "LONG HALLWAY\nFROM A SHORT VACATION", Enum.NormalId.Back, Color3.fromRGB(18, 42, 54), Color3.fromRGB(112, 222, 255))
	createSurfaceText(oceanSign, "IslandApproachReturnText", "THIS WAY\nTO PARADISE", Enum.NormalId.Front, Color3.fromRGB(18, 42, 54), Color3.fromRGB(112, 222, 255))
	makeAtomicStarburst(hallway, "HallwayTVAtomicStarburst", CFrame.new(-5.95, 6.7, 30.4) * CFrame.Angles(0, math.rad(90), 0), 0.68, ATOMIC_COLORS.Pink, ATOMIC_COLORS.Orange)
	makeAtomicBoomerang(hallway, "HallwaySnackAtomicBoomerang", CFrame.new(5.95, 6.1, 34.8) * CFrame.Angles(0, math.rad(-90), 0), 0.72, ATOMIC_COLORS.Orange)
	makeAtomicDiamondCluster(hallway, "HallwayTinyAtomicDiamonds", CFrame.new(-5.95, 6.2, 53.5) * CFrame.Angles(0, math.rad(90), 0), 0.58)
	makeLowerTunnelBranch(hallway)
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
		"SecurityHallControlPanel",
		CFrame.new(5.88, 4.55, 66.6) * CFrame.Angles(0, math.rad(90), 0),
		"SecurityRoom",
		"SECURITY",
		{
			IncludeReset = false,
			PanelLabel = "SECURITY",
			LightPromptObjectText = "Security Door Light Switch",
			LogText = "SECURITY\nLOG\nOPEN",
		}
	)
	makeRoomControlPanel(
		hallway,
		"SleepingHallControlPanel",
		CFrame.new(-5.88, 4.55, 66.6) * CFrame.Angles(0, math.rad(-90), 0),
		"SleepingQuarters",
		"SLEEPING QUARTERS",
		{
			IncludeReset = false,
			PanelLabel = "SLEEPING",
			LightPromptObjectText = "Sleeping Quarters Door Light Switch",
			LogText = "SLEEPING\nLOG\nOPEN",
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

		local caveDoor = makeHallDoor(
			hallway,
			"CaveEntranceDoor",
			Vector3.new(0.45, 8.5, 6.5),
			CFrame.new(-5.95, 4.75, 45),
			Enum.NormalId.Right,
			"CAVE\nENTRYWAY",
			CAVE_HALLWAY_CAVE_RETURN_CFRAME
		)
		caveDoor:SetAttribute("UnlockDiscoveryId", Constants.Discoveries.CaveEntered.Id)
		caveDoor:SetAttribute("TravelMessage", "The entryway locks behind you.")
		caveDoor:SetAttribute("RequiresEndGameCompletion", true)
		caveDoor:SetAttribute("EndGameLockedMessage", "The cave entryway stays sealed until the bunker is finished with you.")
		caveDoor:SetAttribute("OneWayTrapAfterHallwayEntry", true)
		caveDoor:SetAttribute("OneWayLockedMessage", "The cave entryway already locked behind you. The hallway is your way forward now.")
		caveDoor:SetAttribute("TravelSoundId", Constants.AudioAssets.Prologue.LockdownDoorEchoId)
		caveDoor.CanCollide = false
		caveDoor:SetAttribute("BaseCanCollide", false)
		tag(caveDoor, Constants.Tags.CaveHallwayDoor)

	local securityDoor = makeHallDoor(
		hallway,
		"SecurityDoor",
		Vector3.new(0.45, 8.5, 6.5),
		CFrame.new(5.95, 4.75, 59),
		Enum.NormalId.Left,
		"SECURITY",
		SECURITY_ROOM_SPAWN_CFRAME,
		nil,
		"SecurityRoom"
	)
	securityDoor:SetAttribute("LockedDuringPrologue", true)
	securityDoor:SetAttribute("PrologueLockedMessage", "Security is dark. The door ignores you for now.")
	securityDoor:SetAttribute("UnlockDiscoveryId", Constants.Discoveries.SecurityEntered.Id)
	securityDoor:SetAttribute("TravelMessage", "Security unlocked. Try to look less monitored.")

	local sleepingDoor = makeHallDoor(
		hallway,
		"SleepingQuartersDoor",
		Vector3.new(0.45, 8.5, 6.5),
		CFrame.new(-5.95, 4.75, 59),
		Enum.NormalId.Right,
		"SLEEPING\nQUARTERS",
		SLEEPING_QUARTERS_SPAWN_CFRAME
	)
	sleepingDoor:SetAttribute("UnlockDiscoveryId", Constants.Discoveries.SleepingEntered.Id)
	sleepingDoor:SetAttribute("TravelMessage", "Sleeping Quarters unlocked. There are definitely enough beds.")

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
		SecurityDoor = securityDoor,
		SleepingDoor = sleepingDoor,
		IslandDoor = islandDoor,
	}
end

local function makeSnackDonutMount(parent, wallCFrame)
	local mount = createPart(parent, "DonutWallMount", Vector3.new(7.6, 7.6, 0.18), wallCFrame * CFrame.new(0, 0, 0.08), Color3.fromRGB(91, 55, 45), Enum.Material.SmoothPlastic)
	mount.Transparency = 0.28
	mount.CanCollide = false
	mount:SetAttribute("BaseTransparency", mount.Transparency)
	mount:SetAttribute("BaseCanCollide", false)
	return mount
end

local function makeStaticSnackWallDonut(parent, wallCFrame)
	local donut = makeModel(parent, "SnackLabWallDonut")
	makeSnackDonutMount(donut, wallCFrame)

	local visual = makeDecorPart(
		donut,
		"ObbySpinningDonutVisual",
		Vector3.new(1, 1, 1),
		wallCFrame * CFrame.new(0, 0, -0.58) * CFrame.Angles(math.rad(90), 0, math.rad(180)),
		Color3.fromRGB(255, 255, 255),
		Enum.Material.SmoothPlastic
	)
	visual.CanQuery = false
	visual.CanTouch = false
	visual:SetAttribute("BaseCanQuery", false)
	visual:SetAttribute("BaseCanTouch", false)
	visual:SetAttribute("SourceAssetId", SNACK_DONUT_ASSET_ID)
	visual:SetAttribute("SanitizedDecoration", true)

	local mesh = Instance.new("SpecialMesh")
	mesh.Name = "ObbySpinningDonutMesh"
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = SNACK_DONUT_MESH_ID
	mesh.TextureId = SNACK_DONUT_TEXTURE_ID
	mesh.Scale = Vector3.new(4.48, 4.48, 4.48)
	mesh.Parent = visual
	mark(mesh)

	donut.PrimaryPart = visual
	return donut
end

local function addSnackDonutHitbox(donut, wallCFrame)
	local hitbox = createPart(donut, "MassiveDonutHitbox", Vector3.new(7.8, 7.8, 1.2), wallCFrame * CFrame.new(0, 0, -0.58), Color3.fromRGB(255, 102, 176), Enum.Material.SmoothPlastic)
	hitbox.Transparency = 1
	hitbox.CanCollide = false
	hitbox:SetAttribute("BaseTransparency", 1)
	hitbox:SetAttribute("BaseCanCollide", false)
	createPrompt(hitbox, "Inspect", "Massive Donut", 0)
	tag(hitbox, Constants.Tags.SnackDonut)
	return hitbox
end

local function makeSnackWallDonut(parent)
	local center = SNACK_LAB_ORIGIN + Vector3.new(-7.8, 8.05, Constants.Room.Depth / 2 - 0.74)
	local wallCFrame = CFrame.new(center)
	local donut = makeStaticSnackWallDonut(parent, wallCFrame)

	addSnackDonutHitbox(donut, wallCFrame)
	return donut
end

local function makeSnackPopcornMachine(parent)
	local origin = SNACK_LAB_ORIGIN
	local popcorn = makeModel(parent, "SnackLabPopcornMachine")
	local baseCFrame = cframeAt(origin, -13.4, 0, -5.6) * CFrame.Angles(0, math.rad(180), 0)

	local cabinet = createPart(popcorn, "PopcornCabinet", Vector3.new(3.8, 2.8, 2.3), baseCFrame * CFrame.new(0, 1.55, 0), Color3.fromRGB(232, 50, 65), Enum.Material.Metal)
	createSurfaceText(cabinet, "PopcornCabinetText", "POPCORN", Enum.NormalId.Front, Color3.fromRGB(255, 242, 181), Color3.fromRGB(232, 50, 65))
	local glass = createPart(popcorn, "PopcornGlassCase", Vector3.new(3.65, 3.1, 2.15), baseCFrame * CFrame.new(0, 4.45, 0), Color3.fromRGB(196, 244, 255), Enum.Material.Glass)
	glass.Transparency = 0.48
	glass:SetAttribute("BaseTransparency", glass.Transparency)
	createPart(popcorn, "PopcornTop", Vector3.new(4.2, 0.42, 2.55), baseCFrame * CFrame.new(0, 6.22, 0), Color3.fromRGB(255, 232, 92), Enum.Material.Metal)
	createPart(popcorn, "PopcornKettle", Vector3.new(1.5, 0.9, 1.5), baseCFrame * CFrame.new(0, 5.45, -0.18), Color3.fromRGB(48, 55, 62), Enum.Material.Metal).Shape = Enum.PartType.Ball
	local tray = createPart(popcorn, "PopcornTray", Vector3.new(3.15, 0.34, 1.65), baseCFrame * CFrame.new(0, 3.05, 0.1), Color3.fromRGB(255, 242, 181), Enum.Material.SmoothPlastic)

	for kernelIndex = 1, 22 do
		local kernel = createPart(
			popcorn,
			"PopcornKernel" .. kernelIndex,
			Vector3.new(0.28, 0.22, 0.28),
			tray.CFrame * CFrame.new(-1.32 + (kernelIndex % 6) * 0.48, 0.22 + (kernelIndex % 4) * 0.05, -0.55 + math.floor((kernelIndex - 1) / 6) * 0.36),
			Color3.fromRGB(255, 238, 156),
			Enum.Material.SmoothPlastic
		)
		kernel.Shape = Enum.PartType.Ball
		kernel.CanCollide = false
		kernel:SetAttribute("BaseCanCollide", false)
	end

	local button = createPart(popcorn, "PopcornStartButton", Vector3.new(0.7, 0.28, 0.7), baseCFrame * CFrame.new(1.25, 2.95, -1.23) * CFrame.Angles(math.rad(90), 0, 0), Color3.fromRGB(119, 255, 203), Enum.Material.Neon)
	button.Shape = Enum.PartType.Cylinder
	createPrompt(button, "Pop", "Popcorn Machine", 0)
	tag(button, Constants.Tags.SnackPopcornMachine)

	popcorn.PrimaryPart = cabinet
	return popcorn
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
	createDoubleSidedSurfaceText(roomSign, "SnackLabSignText", "SNACK LAB", Enum.NormalId.Front, Color3.fromRGB(28, 27, 24), Color3.fromRGB(255, 232, 115))

	local snackControls = makeRoomControlPanel(
		room,
		"SnackLabInsideControlPanel",
		cframeAt(origin, -width / 2 + 0.58, 4.6, -1.1) * CFrame.Angles(0, math.rad(-90), 0),
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
	makeAtomicStarburst(room, "SnackLabAtomicStarburst", cframeAt(origin, 12.5, 8.5, -depth / 2 + 0.62), 0.78, ATOMIC_COLORS.NeonPink, ATOMIC_COLORS.Orange)
	makeAtomicBoomerang(room, "SnackLabAtomicBoomerang", cframeAt(origin, width / 2 - 0.58, 7.4, 8.2) * CFrame.Angles(0, math.rad(-90), 0), 0.82, ATOMIC_COLORS.Pink)
	makeAtomicDiamondCluster(room, "SnackLabAtomicDiamonds", cframeAt(origin, -7.2, 7.0, depth / 2 - 0.62) * CFrame.Angles(0, math.rad(180), 0), 0.62)
	makeSnackWallDonut(room)
	makeSnackPopcornMachine(room)

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
	createDoubleSidedSurfaceText(sign, "SnackButtonText", "DO NOT FEED THE ROOM", Enum.NormalId.Back, Color3.fromRGB(22, 23, 25), Color3.fromRGB(244, 248, 112))

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
	local fridgeOffset = Vector3.new(-4.25, 0, -5.55)
	local function fridgeCFrame(x, y, z)
		return cframeAt(origin, x + fridgeOffset.X, y, z + fridgeOffset.Z)
	end

	local body = createPart(fridge, "FridgeBody", Vector3.new(6.4, 9.2, 0.34), fridgeCFrame(-13, 4.9, -10.92), Color3.fromRGB(192, 203, 205), Enum.Material.Metal)
	createPart(fridge, "FridgeLeftWall", Vector3.new(0.36, 9.2, 4), fridgeCFrame(-16.02, 4.9, -8.95), Color3.fromRGB(192, 203, 205), Enum.Material.Metal)
	createPart(fridge, "FridgeRightWall", Vector3.new(0.36, 9.2, 4), fridgeCFrame(-9.98, 4.9, -8.95), Color3.fromRGB(192, 203, 205), Enum.Material.Metal)
	createPart(fridge, "FridgeTopCap", Vector3.new(6.4, 0.36, 4), fridgeCFrame(-13, 9.32, -8.95), Color3.fromRGB(192, 203, 205), Enum.Material.Metal)
	createPart(fridge, "FridgeBottomCap", Vector3.new(6.4, 0.36, 4), fridgeCFrame(-13, 0.48, -8.95), Color3.fromRGB(171, 185, 187), Enum.Material.Metal)

	local interior = makeModel(fridge, "FridgeInteriorDetails")
	createPart(interior, "FridgeInteriorBack", Vector3.new(5.45, 7.65, 0.22), fridgeCFrame(-13, 4.9, -10.62), Color3.fromRGB(55, 78, 92), Enum.Material.SmoothPlastic)
	createPart(interior, "FridgeInteriorLeft", Vector3.new(0.18, 7.65, 3.2), fridgeCFrame(-15.68, 4.9, -8.95), Color3.fromRGB(72, 95, 108), Enum.Material.SmoothPlastic)
	createPart(interior, "FridgeInteriorRight", Vector3.new(0.18, 7.65, 3.2), fridgeCFrame(-10.32, 4.9, -8.95), Color3.fromRGB(72, 95, 108), Enum.Material.SmoothPlastic)
	createPart(interior, "FridgeShelfTop", Vector3.new(5.1, 0.18, 2.85), fridgeCFrame(-13, 6.32, -8.95), Color3.fromRGB(167, 220, 230), Enum.Material.Glass).Transparency = 0.34
	createPart(interior, "FridgeShelfBottom", Vector3.new(5.1, 0.18, 2.85), fridgeCFrame(-13, 4.1, -8.95), Color3.fromRGB(167, 220, 230), Enum.Material.Glass).Transparency = 0.34
	createPart(interior, "FridgeShelfTopLip", Vector3.new(5.15, 0.24, 0.12), fridgeCFrame(-13, 6.45, -7.48), Color3.fromRGB(191, 225, 230), Enum.Material.Glass).Transparency = 0.22
	createPart(interior, "FridgeShelfBottomLip", Vector3.new(5.15, 0.24, 0.12), fridgeCFrame(-13, 4.23, -7.48), Color3.fromRGB(191, 225, 230), Enum.Material.Glass).Transparency = 0.22
	local crisper = createPart(interior, "FridgeCrisperDrawer", Vector3.new(4.85, 1.25, 2.65), fridgeCFrame(-13, 2.25, -8.95), Color3.fromRGB(167, 220, 230), Enum.Material.Glass)
	crisper.Transparency = 0.55
	local crisperFront = createPart(interior, "FridgeCrisperFront", Vector3.new(4.85, 1.12, 0.12), fridgeCFrame(-13, 2.25, -7.48), Color3.fromRGB(182, 225, 230), Enum.Material.Glass)
	crisperFront.Transparency = 0.32
	createSurfaceText(crisperFront, "CrisperText", "IDEAS\nCRISPER", Enum.NormalId.Front, Color3.fromRGB(36, 84, 92), Color3.fromRGB(182, 225, 230))
	local lightPanel = createPart(interior, "FridgeLightPanel", Vector3.new(1.4, 0.22, 0.18), fridgeCFrame(-13, 8.45, -7.55), Color3.fromRGB(230, 224, 176), Enum.Material.Neon)
	local fridgeLight = Instance.new("PointLight")
	fridgeLight.Name = "FridgeInteriorLight"
	fridgeLight.Brightness = 2.25
	fridgeLight.Color = Color3.fromRGB(210, 248, 255)
	fridgeLight.Range = 10
	fridgeLight.Parent = lightPanel
	mark(fridgeLight)

	local milk = createPart(interior, "FridgeMilkCarton", Vector3.new(0.95, 1.8, 0.9), fridgeCFrame(-14.45, 5.15, -9.05), Color3.fromRGB(221, 223, 225), Enum.Material.SmoothPlastic)
	createSurfaceText(milk, "MilkText", "MILK?", Enum.NormalId.Front, Color3.fromRGB(72, 118, 205), Color3.fromRGB(221, 223, 225))
	createPart(interior, "FridgeMilkCap", Vector3.new(0.34, 0.2, 0.34), fridgeCFrame(-14.1, 6.15, -8.72), Color3.fromRGB(72, 118, 205), Enum.Material.SmoothPlastic).Shape = Enum.PartType.Cylinder

	local eggTray = createPart(interior, "FridgeEggTray", Vector3.new(2.1, 0.18, 0.75), fridgeCFrame(-11.85, 6.58, -8.65), Color3.fromRGB(212, 203, 182), Enum.Material.SmoothPlastic)
	for eggIndex = 1, 6 do
		local egg = createPart(
			interior,
			"FridgeEgg" .. eggIndex,
			Vector3.new(0.32, 0.42, 0.32),
			eggTray.CFrame * CFrame.new(-0.85 + ((eggIndex - 1) % 3) * 0.58, 0.24, -0.18 + math.floor((eggIndex - 1) / 3) * 0.38),
			Color3.fromRGB(225, 221, 205),
			Enum.Material.SmoothPlastic
		)
		egg.Shape = Enum.PartType.Ball
	end

	for bottleIndex, bottleData in ipairs({
		{ X = -10.95, Y = 5.08, Z = -9.4, Color = Color3.fromRGB(255, 219, 86), Label = "MUSTARD" },
		{ X = -10.95, Y = 5.08, Z = -8.45, Color = Color3.fromRGB(221, 45, 58), Label = "KETCHUP" },
	}) do
		local bottle = createPart(interior, "FridgeBottle" .. bottleIndex, Vector3.new(0.5, 1.25, 0.5), fridgeCFrame(bottleData.X, bottleData.Y, bottleData.Z), bottleData.Color, Enum.Material.SmoothPlastic)
		bottle.Shape = Enum.PartType.Cylinder
		createPart(interior, "FridgeBottleCap" .. bottleIndex, Vector3.new(0.34, 0.18, 0.34), fridgeCFrame(bottleData.X, bottleData.Y + 0.7, bottleData.Z), Color3.fromRGB(221, 221, 218), Enum.Material.SmoothPlastic).Shape = Enum.PartType.Cylinder
		local label = createPart(interior, "FridgeBottleLabel" .. bottleIndex, Vector3.new(0.55, 0.42, 0.08), fridgeCFrame(bottleData.X, bottleData.Y, bottleData.Z + 0.28), Color3.fromRGB(230, 230, 221), Enum.Material.SmoothPlastic)
		createSurfaceText(label, "BottleLabelText", bottleData.Label, Enum.NormalId.Front, bottleData.Color, Color3.fromRGB(230, 230, 221))
	end
	hideFridgeContentAtBaseline(interior)

	local iceCube = createPart(fridge, "ColdIdeaIceCube", Vector3.new(1.4, 1.4, 1.4), fridgeCFrame(-13, 5.05, -7.55), Color3.fromRGB(134, 238, 255), Enum.Material.Ice)
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
	local pizzaSlice = createPart(pizza, "PizzaSlice", Vector3.new(2.3, 0.25, 1.45), fridgeCFrame(-14.3, 6.78, -7.75) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(246, 184, 85), Enum.Material.SmoothPlastic, "WedgePart")
	createPart(pizza, "PizzaCrust", Vector3.new(0.28, 0.32, 1.5), fridgeCFrame(-15.05, 6.79, -7.75), Color3.fromRGB(177, 103, 47), Enum.Material.SmoothPlastic)
	for index = 1, 4 do
		local topping = createPart(
			pizza,
			"Pepperoni",
			Vector3.new(0.28, 0.08, 0.28),
			fridgeCFrame(-14.35 + (index % 2) * 0.6, 6.96, -8.08 + math.floor((index - 1) / 2) * 0.55),
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
	local can = createPart(cola, "BloxyColaCan", Vector3.new(0.82, 1.55, 0.82), fridgeCFrame(-11.6, 4.85, -7.6), Color3.fromRGB(218, 40, 47), Enum.Material.Metal)
	can.Shape = Enum.PartType.Cylinder
	local canLabel = createPart(cola, "BloxyColaLabel", Vector3.new(0.9, 0.68, 0.08), fridgeCFrame(-11.6, 4.85, -7.16), Color3.fromRGB(245, 245, 242), Enum.Material.SmoothPlastic)
	createSurfaceText(canLabel, "BloxyColaText", "BLOXY\nCOLA", Enum.NormalId.Front, Color3.fromRGB(218, 40, 47), Color3.fromRGB(245, 245, 242))
	local colaPrompt = createPrompt(can, "Sip", "Bloxy Cola", 0)
	colaPrompt.Enabled = false
	colaPrompt:SetAttribute("BaseEnabled", false)
	tag(can, Constants.Tags.FridgeBloxyCola)
	cola.PrimaryPart = can
	hideFridgeContentAtBaseline(cola)

	local door = createPart(fridge, "FridgeDoor", Vector3.new(5.5, 8, 0.32), fridgeCFrame(-13, 4.9, -6.83), Color3.fromRGB(237, 246, 247), Enum.Material.Metal)
	createSurfaceText(door, "FridgeDoorText", "DO NOT OPEN", Enum.NormalId.Front, Color3.fromRGB(26, 35, 39), Color3.fromRGB(237, 246, 247))
	local doorPrompt = createPrompt(door, "Open", "Fridge", 0)
	doorPrompt.MaxActivationDistance = 13

	local secretButton = createPart(fridge, "SecretFridgeButton", Vector3.new(2.55, 1.2, 0.24), fridgeCFrame(-15.7, 4.85, -6.18), Color3.fromRGB(255, 72, 86), Enum.Material.Neon)
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
	local wallX = -6.7
	local wallZ = -14.45

	createPart(toaster, "ToasterCounter", Vector3.new(9, 2.2, 3.8), cframeAt(origin, wallX, 1.55, wallZ), Color3.fromRGB(134, 93, 63), Enum.Material.Wood)
	local body = createPart(toaster, "ToasterBody", Vector3.new(4.2, 2, 2.5), cframeAt(origin, wallX, 3.65, wallZ), Color3.fromRGB(194, 200, 207), Enum.Material.Metal)
	local slot = createPart(toaster, "ToasterSlot", Vector3.new(3.2, 0.18, 1.2), cframeAt(origin, wallX, 4.75, wallZ), Color3.fromRGB(34, 36, 40), Enum.Material.SmoothPlastic)
	createPrompt(body, "Toast", "Toaster", 0)
	tag(toaster, Constants.Tags.SnackToaster)

	toaster.PrimaryPart = body
	return toaster, slot
end

local function makeSnackSink(objectsFolder)
	local origin = SNACK_LAB_ORIGIN
	local sink = makeModel(objectsFolder, "Sink")
	local wallX = 5.3
	local wallZ = -14.45

	createPart(sink, "SinkCounter", Vector3.new(9, 2.2, 3.8), cframeAt(origin, wallX, 1.55, wallZ), Color3.fromRGB(122, 128, 132), Enum.Material.Metal)
	createPart(sink, "SinkBasinOuter", Vector3.new(5.2, 0.45, 2.8), cframeAt(origin, wallX, 2.93, wallZ), Color3.fromRGB(215, 224, 229), Enum.Material.Metal)
	createPart(sink, "SinkBasinDark", Vector3.new(4.1, 0.5, 1.8), cframeAt(origin, wallX, 3.02, wallZ), Color3.fromRGB(40, 55, 65), Enum.Material.SmoothPlastic)
	createPart(sink, "SinkWaterRest", Vector3.new(3.4, 0.08, 1.25), cframeAt(origin, wallX, 3.33, wallZ), Color3.fromRGB(72, 183, 238), Enum.Material.Glass)
	local faucetPost = createPart(sink, "FaucetPost", Vector3.new(0.42, 1.9, 0.42), cframeAt(origin, wallX, 4.05, wallZ - 1.22), Color3.fromRGB(216, 223, 226), Enum.Material.Metal)
	local faucetSpout = createPart(sink, "FaucetSpout", Vector3.new(0.42, 0.42, 1.65), cframeAt(origin, wallX, 4.78, wallZ - 0.55), Color3.fromRGB(216, 223, 226), Enum.Material.Metal)
	createPart(sink, "HotHandle", Vector3.new(0.7, 0.25, 0.7), cframeAt(origin, wallX - 1.35, 3.55, wallZ - 1.35), Color3.fromRGB(255, 80, 80), Enum.Material.Neon)
	createPart(sink, "ColdHandle", Vector3.new(0.7, 0.25, 0.7), cframeAt(origin, wallX + 1.35, 3.55, wallZ - 1.35), Color3.fromRGB(80, 160, 255), Enum.Material.Neon)
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
	local fruitOffset = Vector3.new(0, 0, 6.75)
	local function fruitCFrame(x, y, z)
		return cframeAt(origin, x + fruitOffset.X, y, z + fruitOffset.Z)
	end

	local tableTop = createPart(fruitBowl, "FruitTable", Vector3.new(7, 1.3, 4.4), fruitCFrame(1.5, 1.1, 7.5), Color3.fromRGB(119, 82, 55), Enum.Material.Wood)
	local bowl = createPart(fruitBowl, "Bowl", Vector3.new(4.7, 1.25, 4.7), fruitCFrame(1.5, 2.2, 7.5), Color3.fromRGB(255, 226, 122), Enum.Material.SmoothPlastic)
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

	makeRoundFruit("Apple", "Apple", fruitCFrame(0.55, 3.28, 7.05), Color3.fromRGB(216, 38, 52), Vector3.new(1.05, 1.0, 1.05))
	makeRoundFruit("Orange", "Orange", fruitCFrame(1.5, 3.35, 6.75), Color3.fromRGB(255, 134, 35), Vector3.new(1.0, 1.0, 1.0), Color3.fromRGB(68, 126, 55))
	makeRoundFruit("Lime", "Lime", fruitCFrame(2.45, 3.18, 7.15), Color3.fromRGB(70, 184, 76), Vector3.new(0.82, 0.78, 0.82), Color3.fromRGB(58, 116, 45))

	local lemon = makeModel(fruitBowl, "Lemon")
	local lemonPivot = fruitCFrame(2.3, 3.28, 8.05) * CFrame.Angles(0, 0, math.rad(-10))
	local lemonBody = createPart(lemon, "LemonBody", Vector3.new(1.25, 0.78, 0.78), lemonPivot, Color3.fromRGB(247, 226, 56), Enum.Material.SmoothPlastic)
	lemonBody.Shape = Enum.PartType.Ball
	local lemonTipA = createPart(lemon, "LemonTipA", Vector3.new(0.22, 0.28, 0.28), lemonPivot * CFrame.new(-0.65, 0, 0), Color3.fromRGB(239, 211, 49), Enum.Material.SmoothPlastic)
	lemonTipA.Shape = Enum.PartType.Ball
	local lemonTipB = createPart(lemon, "LemonTipB", Vector3.new(0.22, 0.28, 0.28), lemonPivot * CFrame.new(0.65, 0, 0), Color3.fromRGB(239, 211, 49), Enum.Material.SmoothPlastic)
	lemonTipB.Shape = Enum.PartType.Ball
	finishFruit(lemon, lemonBody, "Lemon")

	local banana = makeModel(fruitBowl, "Banana")
	local bananaPivot = fruitCFrame(0.75, 3.55, 8.15) * CFrame.Angles(0, math.rad(20), math.rad(-8))
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
	local grapePivot = fruitCFrame(1.45, 3.45, 8.4)
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
	createPart(loft, "LoftRoomFrontWall", Vector3.new(17, 7.5, 0.4), CFrame.new(center + Vector3.new(0, 18.45, 6.5)), Color3.fromRGB(50, 43, 54), Enum.Material.SmoothPlastic)
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

		local keyPedestal = createPart(loft, "LibraryTeleportKeyPedestal", Vector3.new(2.4, 0.8, 2.4), CFrame.new(center + Vector3.new(3.0, 15.42, -2.1)), Color3.fromRGB(36, 52, 70), Enum.Material.Metal)
		createSurfaceText(keyPedestal, "TeleportKeyPedestalText", "TELEPORT\nKEY", Enum.NormalId.Top, Color3.fromRGB(119, 255, 203), Color3.fromRGB(36, 52, 70))
		local keyCFrame = CFrame.new(center + Vector3.new(3.0, 16.45, -2.1)) * CFrame.Angles(0, math.rad(90), math.rad(90))
		local teleportKeyShaft = createPart(
			loft,
			"LibraryTeleportKey",
		Vector3.new(0.24, 1.7, 0.24),
		keyCFrame,
		Color3.fromRGB(119, 255, 203),
		Enum.Material.Neon
	)
		teleportKeyShaft.Shape = Enum.PartType.Cylinder
		teleportKeyShaft.CanCollide = false
		teleportKeyShaft:SetAttribute("BaseCanCollide", false)
		for _, keyPart in ipairs({
			createPart(loft, "LibraryTeleportKeyHead", Vector3.new(0.8, 0.14, 0.8), keyCFrame * CFrame.new(0, -0.95, 0), Color3.fromRGB(255, 221, 84), Enum.Material.Neon),
			createPart(loft, "LibraryTeleportKeyToothA", Vector3.new(0.18, 0.48, 0.18), keyCFrame * CFrame.new(0.28, 0.72, 0), Color3.fromRGB(255, 221, 84), Enum.Material.Neon),
			createPart(loft, "LibraryTeleportKeyToothB", Vector3.new(0.18, 0.32, 0.18), keyCFrame * CFrame.new(-0.22, 0.83, 0), Color3.fromRGB(255, 221, 84), Enum.Material.Neon),
		}) do
			keyPart.CanCollide = false
			keyPart:SetAttribute("BaseCanCollide", false)
		end
		createPrompt(teleportKeyShaft, "Take", "Teleport Key", 0)
		tag(teleportKeyShaft, Constants.Tags.LibraryTeleportKey)

	local rug = createPart(loft, "LoftReadingRug", Vector3.new(8.5, 0.08, 5.4), CFrame.new(center + Vector3.new(0, 15.04, -0.5)), Color3.fromRGB(122, 49, 85), Enum.Material.Fabric)
	rug:SetAttribute("BaseCanCollide", false)
	rug.CanCollide = false

	local returnDoor = createPart(loft, "LibraryLoftReturnDoor", Vector3.new(0.32, 5.2, 4.2), CFrame.new(center + Vector3.new(-8.26, 17.6, 2.2)), Color3.fromRGB(73, 91, 122), Enum.Material.Wood)
	returnDoor:SetAttribute("DestinationCFrame", LIBRARY_LOFT_RETURN_CFRAME)
	returnDoor:SetAttribute("DestinationName", "the Library loft ladder")
	createSurfaceText(returnDoor, "LoftReturnText", "DOWN\nTO LIBRARY", Enum.NormalId.Right, Color3.fromRGB(235, 245, 255), Color3.fromRGB(73, 91, 122))
	createPrompt(returnDoor, "Exit", "Library", 0)
	tag(returnDoor, Constants.Tags.SecretRoomExit)

	loft.PrimaryPart = returnDoor
	return loft
end

local function prepareLibraryRollingLadderAssetModel(assetModel)
	local visualParts = {}
	for _, descendant in ipairs(assetModel:GetDescendants()) do
		if descendant:IsA("LuaSourceContainer")
			or descendant:IsA("Constraint")
			or descendant:IsA("BodyMover")
			or descendant:IsA("Humanoid")
			or descendant:IsA("Animator")
			or descendant:IsA("Camera")
			or descendant:IsA("Tool") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
			descendant.Massless = true
			descendant:SetAttribute("LibraryRollingLadderVisual", true)
			descendant:SetAttribute("BaseCanCollide", false)
			descendant:SetAttribute("BaseCanQuery", false)
			descendant:SetAttribute("BaseCanTouch", false)
			table.insert(visualParts, descendant)
		end
	end

	return visualParts
end

local function makeProceduralLibraryRollingLadder(parent, ladderCFrame)
	local ladderVisual = makeModel(parent, "LibraryRollingLadderVisual")
	ladderVisual:SetAttribute("SourceAssetId", LIBRARY_ROLLING_LADDER_ASSET_ID)
	ladderVisual:SetAttribute("SourceAssetUrl", ("https://create.roblox.com/store/asset/%d"):format(LIBRARY_ROLLING_LADDER_ASSET_ID))
	ladderVisual:SetAttribute("AssetFallbackUsed", true)
	ladderVisual:SetAttribute("LibraryRollingLadderVisual", true)

	local wood = Color3.fromRGB(171, 112, 67)
	local rungColor = Color3.fromRGB(198, 146, 89)
	local leftRail = createPart(ladderVisual, "FallbackLeftRail", Vector3.new(0.22, 7.9, 0.22), ladderCFrame * CFrame.new(-0.45, 0, 0), wood, Enum.Material.Wood)
	local rightRail = createPart(ladderVisual, "FallbackRightRail", Vector3.new(0.22, 7.9, 0.22), ladderCFrame * CFrame.new(0.45, 0, 0), wood, Enum.Material.Wood)

	for index = 1, 7 do
		local y = -3.15 + index * 0.82
		local rung = createPart(ladderVisual, "FallbackRung" .. index, Vector3.new(1.15, 0.16, 0.18), ladderCFrame * CFrame.new(0, y, 0), rungColor, Enum.Material.Wood)
		rung.CanCollide = false
		rung.CanQuery = false
		rung.CanTouch = false
		rung:SetAttribute("BaseCanCollide", false)
		rung:SetAttribute("BaseCanQuery", false)
		rung:SetAttribute("BaseCanTouch", false)
	end

	for _, wheelX in ipairs({ -0.46, 0.46 }) do
		local wheel = createPart(ladderVisual, "FallbackWheel", Vector3.new(0.34, 0.34, 0.16), ladderCFrame * CFrame.new(wheelX, -3.9, 0.02) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(54, 43, 36), Enum.Material.Rubber)
		wheel.Shape = Enum.PartType.Cylinder
		wheel.CanCollide = false
		wheel.CanQuery = false
		wheel.CanTouch = false
		wheel:SetAttribute("BaseCanCollide", false)
		wheel:SetAttribute("BaseCanQuery", false)
		wheel:SetAttribute("BaseCanTouch", false)
	end

	for _, part in ipairs({ leftRail, rightRail }) do
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part:SetAttribute("BaseCanCollide", false)
		part:SetAttribute("BaseCanQuery", false)
		part:SetAttribute("BaseCanTouch", false)
	end

	ladderVisual.PrimaryPart = leftRail
	return ladderVisual
end

local function makeLibraryRollingLadderVisual(parent, ladderCFrame)
	local ladderVisual = makeModel(parent, "LibraryRollingLadderVisual")
	ladderVisual:SetAttribute("SourceAssetId", LIBRARY_ROLLING_LADDER_ASSET_ID)
	ladderVisual:SetAttribute("SourceAssetUrl", ("https://create.roblox.com/store/asset/%d"):format(LIBRARY_ROLLING_LADDER_ASSET_ID))
	ladderVisual:SetAttribute("AssetFallbackUsed", false)
	ladderVisual:SetAttribute("LibraryRollingLadderVisual", true)

	local success, assetModel = pcall(AssetService.LoadAssetAsync, AssetService, LIBRARY_ROLLING_LADDER_ASSET_ID)
	if not success or not assetModel then
		warn(("[DON'T TOUCH IT] Could not load Library rolling ladder asset %d: %s"):format(LIBRARY_ROLLING_LADDER_ASSET_ID, tostring(assetModel)))
		ladderVisual:Destroy()
		return makeProceduralLibraryRollingLadder(parent, ladderCFrame)
	end

	assetModel.Name = "EchelleFSAsset"
	assetModel.Parent = ladderVisual

	local visualParts = prepareLibraryRollingLadderAssetModel(assetModel)
	if #visualParts == 0 then
		warn(("[DON'T TOUCH IT] Library rolling ladder asset %d loaded without visible parts."):format(LIBRARY_ROLLING_LADDER_ASSET_ID))
		ladderVisual:Destroy()
		return makeProceduralLibraryRollingLadder(parent, ladderCFrame)
	end

	local _, currentSize = assetModel:GetBoundingBox()
	if currentSize.Y > 0 then
		assetModel:ScaleTo(7.8 / currentSize.Y)
	end

	assetModel:PivotTo(ladderCFrame)
	local boundsCFrame, boundsSize = assetModel:GetBoundingBox()
	local bottomY = boundsCFrame.Position.Y - boundsSize.Y / 2
	local targetBottomY = ladderCFrame.Position.Y - 3.8
	assetModel:PivotTo(assetModel:GetPivot() + Vector3.new(
		ladderCFrame.Position.X - boundsCFrame.Position.X,
		targetBottomY - bottomY,
		ladderCFrame.Position.Z - boundsCFrame.Position.Z
	))

	for _, part in ipairs(visualParts) do
		mark(part)
	end

	ladderVisual.PrimaryPart = visualParts[1]
	return ladderVisual
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
					local shelfBook = createPart(
						shelfModel,
						("Book_%d_%d"):format(row, bookIndex),
						Vector3.new(0.42, 1.05 + (bookIndex % 3) * 0.14, 0.38),
						base * CFrame.new(bookX, -3.05 + row * 1.55, 0.58),
						color,
						Enum.Material.SmoothPlastic
					)
					shelfBook.CanCollide = false
					shelfBook:SetAttribute("BaseCanCollide", false)
					if shelfIndex == 3 and row == 3 and bookIndex == 5 then
						shelfBook.Name = "LibraryLooseStormBook"
						shelfBook.Size = Vector3.new(0.52, 1.42, 0.46)
						shelfBook.Color = Color3.fromRGB(255, 91, 141)
						shelfBook.Material = Enum.Material.Neon
						createSurfaceText(shelfBook, "LooseBookText", "PULL", Enum.NormalId.Back, Color3.fromRGB(255, 245, 196), shelfBook.Color)
						createPrompt(shelfBook, "Pull", "Loose Book", 0)
						tag(shelfBook, Constants.Tags.LibraryBookStorm)
					end
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

	local ladderCFrame = cframeAt(origin, -12.8, 4.0, -9.2) * CFrame.Angles(0, 0, math.rad(-4))
	local ladder = createPart(room, "LibraryRollingLadder", Vector3.new(1.15, 7.6, 1.15), ladderCFrame, Color3.fromRGB(181, 121, 67), Enum.Material.Wood, "TrussPart")
	ladder.Transparency = 1
	ladder:SetAttribute("BaseTransparency", 1)
	makeLibraryRollingLadderVisual(ladder, ladderCFrame)
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

	makeAtomicBoomerang(room, "LibraryBackWallAtomicBoomerang", cframeAt(origin, -10.8, 11.2, -LIBRARY_DEPTH / 2 + 0.62), 0.78, ATOMIC_COLORS.Orange)
	makeAtomicStarburst(room, "LibraryRightWallAtomicStarburst", cframeAt(origin, LIBRARY_WIDTH / 2 - 0.58, 10.4, 8.8) * CFrame.Angles(0, math.rad(-90), 0), 0.68, ATOMIC_COLORS.Cream, ATOMIC_COLORS.Pink)
	makeAtomicDiamondCluster(room, "LibraryLoftAtomicDiamonds", cframeAt(origin, -2.8, 10.8, LIBRARY_DEPTH / 2 - 0.62) * CFrame.Angles(0, math.rad(180), 0), 0.56)
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

local function makeMaintenancePin(parent, name, baseCFrame, scale, motionIndex)
	scale = scale or 1
	local pinModel = makeModel(parent, name)
	local coreHeight = 2.55 * scale
	local coreDiameter = 0.58 * scale

	local core = createPart(
		pinModel,
		name .. "Core",
		Vector3.new(coreDiameter, coreHeight, coreDiameter),
		baseCFrame * CFrame.new(0, coreHeight / 2, 0),
		Color3.fromRGB(245, 244, 232),
		Enum.Material.SmoothPlastic
	)
	core.Shape = Enum.PartType.Cylinder
	core.Transparency = 1
	core.CanCollide = false
	core:SetAttribute("BaseTransparency", 1)
	core:SetAttribute("BaseCanCollide", false)
	pinModel.PrimaryPart = core

	local function addPiece(pieceName, size, yOffset, color)
		local piece = createPart(
			pinModel,
			name .. pieceName,
			size * scale,
			baseCFrame * CFrame.new(0, yOffset * scale, 0),
			color,
			Enum.Material.SmoothPlastic
		)
		piece.Shape = Enum.PartType.Ball
		piece.CanCollide = false
		piece:SetAttribute("BaseCanCollide", false)
		return piece
	end

	addPiece("Foot", Vector3.new(0.9, 0.28, 0.9), 0.14, Color3.fromRGB(248, 247, 237))
	addPiece("Belly", Vector3.new(0.98, 1.05, 0.98), 0.64, Color3.fromRGB(248, 247, 237))
	addPiece("Shoulder", Vector3.new(0.72, 0.78, 0.72), 1.34, Color3.fromRGB(248, 247, 237))
	addPiece("LowerStripe", Vector3.new(0.64, 0.11, 0.64), 1.65, Color3.fromRGB(220, 52, 67))
	addPiece("UpperStripe", Vector3.new(0.55, 0.11, 0.55), 1.82, Color3.fromRGB(220, 52, 67))
	addPiece("Neck", Vector3.new(0.42, 0.66, 0.42), 2.02, Color3.fromRGB(248, 247, 237))
	addPiece("Head", Vector3.new(0.54, 0.54, 0.54), 2.42, Color3.fromRGB(248, 247, 237))

	pinModel:SetAttribute("MaintenanceBasePivot", pinModel:GetPivot())
	pinModel:SetAttribute("MaintenanceMotionKind", "Pin")
	pinModel:SetAttribute("MaintenanceMotionIndex", motionIndex or 1)
	tag(pinModel, Constants.Tags.BowlingMaintenanceMover)
	return pinModel
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

local function createZiplineWarpCorridor(parent, pathPoints, options)
	local tunnel = makeModel(parent, "ZiplineParallaxWarpTunnel")
	local colors = {
		Color3.fromRGB(30, 54, 94),
		Color3.fromRGB(44, 18, 80),
		Color3.fromRGB(14, 72, 91),
		Color3.fromRGB(69, 36, 112),
	}
	options = options or {}
	local maxSegmentIndex = math.min(#pathPoints - 1, options.MaxSegmentIndex or (#pathPoints - 1))

	for index = 1, maxSegmentIndex do
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
	accessDoor:SetAttribute("UnlockDiscoveryId", Constants.Discoveries.TreetopZiplineEntered.Id)
	accessDoor:SetAttribute("TravelMessage", "Treetop Zipline unlocked. Please ignore how high up this is.")
	createSurfaceText(accessDoor, "TreetopAccessText", "TREE LINE\nZIPLINE", Enum.NormalId.Front, Color3.fromRGB(225, 255, 206), Color3.fromRGB(68, 105, 80))
	createPrompt(accessDoor, "Enter", "Treetop Zipline", 0)
	tag(accessDoor, Constants.Tags.SecretRoomExit)

	local platform = createPart(treetop, "TreetopPlatform", Vector3.new(24, 0.7, 18), CFrame.new(platformCenter), Color3.fromRGB(115, 78, 45), Enum.Material.WoodPlanks)
	platform:SetAttribute("CosmicSurface", true)
	createPart(treetop, "TreetopLeftRail", Vector3.new(0.35, 2.4, 16), CFrame.new(platformCenter + Vector3.new(-12, 1.4, 0)), Color3.fromRGB(78, 52, 34), Enum.Material.Wood)
	createPart(treetop, "TreetopRightRail", Vector3.new(0.35, 2.4, 16), CFrame.new(platformCenter + Vector3.new(12, 1.4, 0)), Color3.fromRGB(78, 52, 34), Enum.Material.Wood)
	createPart(treetop, "TreetopBackRail", Vector3.new(24, 2.4, 0.35), CFrame.new(platformCenter + Vector3.new(0, 1.4, 8)), Color3.fromRGB(78, 52, 34), Enum.Material.Wood)

	local sign = createPart(treetop, "TreetopZiplineSign", Vector3.new(9, 3, 0.28), CFrame.new(platformCenter + Vector3.new(0, 4.6, 7.5)), Color3.fromRGB(255, 232, 112), Enum.Material.Wood)
	createDoubleSidedSurfaceText(sign, "TreetopSignText", "ABOVE THE TREES\nISLAND ZIPLINE", Enum.NormalId.Front, Color3.fromRGB(42, 38, 24), Color3.fromRGB(255, 232, 112))
	makeAtomicStarburst(treetop, "TreetopLaunchAtomicStarburst", CFrame.new(platformCenter + Vector3.new(8.8, 5.7, 7.35)), 0.64, ATOMIC_COLORS.Pink, ATOMIC_COLORS.Cream)
	makeAtomicBoomerang(treetop, "TreetopLaunchAtomicBoomerang", CFrame.new(platformCenter + Vector3.new(-9.0, 5.0, 7.35)), 0.68, ATOMIC_COLORS.Orange)

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
	zipHandle:SetAttribute("EndCFrame", VOID_SPAWN_CFRAME)
	zipHandle:SetAttribute("AwardsIsland", false)
	zipHandle:SetAttribute("AwardsVoid", true)
	zipHandle:SetAttribute("RideMessage", "The zipline accepts your paperwork, then immediately loses it.")
	zipHandle:SetAttribute("ArrivalMessage", "Temporary stop: The Void. Please remain alarmed.")
	zipHandle:SetAttribute("PathPointCount", #ziplinePath)
	for index, point in ipairs(ziplinePath) do
		zipHandle:SetAttribute("PathPoint" .. index, point)
	end
	createPrompt(zipHandle, "Ride", "Zipline to The Void", 0.2)
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

local function makeVoidRoom(roomFolder)
	local room = makeModel(roomFolder, "VoidRoom")
	local origin = VOID_ORIGIN
	local width = 46
	local depth = 48
	local height = 24

	createPart(room, "VoidFloor", Vector3.new(width, 1, depth), cframeAt(origin, 0, 0, 0), Color3.fromRGB(13, 11, 25), Enum.Material.SmoothPlastic)
	createPart(room, "VoidCeiling", Vector3.new(width, 1, depth), cframeAt(origin, 0, height, 0), Color3.fromRGB(8, 6, 18), Enum.Material.SmoothPlastic)
	createPart(room, "VoidBackWall", Vector3.new(width, height, 1), cframeAt(origin, 0, height / 2, -depth / 2), Color3.fromRGB(11, 9, 24), Enum.Material.SmoothPlastic)
	createPart(room, "VoidFrontWall", Vector3.new(width, height, 1), cframeAt(origin, 0, height / 2, depth / 2), Color3.fromRGB(11, 9, 24), Enum.Material.SmoothPlastic)
	createPart(room, "VoidLeftWall", Vector3.new(1, height, depth), cframeAt(origin, -width / 2, height / 2, 0), Color3.fromRGB(10, 8, 22), Enum.Material.SmoothPlastic)
	createPart(room, "VoidRightWall", Vector3.new(1, height, depth), cframeAt(origin, width / 2, height / 2, 0), Color3.fromRGB(10, 8, 22), Enum.Material.SmoothPlastic)

	createSpawnLocation(room, "VoidSpawn", "Void", VOID_SPAWN_CFRAME, Color3.fromRGB(150, 112, 255), false)

	local controls = makeRoomControlPanel(
		room,
		"VoidInsideControlPanel",
		CFrame.new(origin + Vector3.new(-13.6, 5.4, 23.3), origin + Vector3.new(-13.6, 5.4, 0)),
		"Void",
		"VOID",
		{
			IncludeReset = true,
			PanelLabel = "VOID CONTROLS",
			LightPromptObjectText = "Void Light Switch",
			LogText = "VOID\nLOG\nOPEN",
		}
	)

	createNoTouchClock(
		room,
		"VoidClock",
		"Void",
		Vector3.new(7.2, 2.2, 0.28),
		CFrame.new(origin + Vector3.new(13.5, 8.8, 23.25), origin + Vector3.new(13.5, 6, 0)),
		Enum.NormalId.Front
	)

	local title = createPart(room, "VoidTitleSign", Vector3.new(16, 3.1, 0.28), cframeAt(origin, 0, 13.4, -23.25), Color3.fromRGB(29, 20, 60), Enum.Material.Neon)
	createDoubleSidedSurfaceText(title, "VoidTitleText", "THE VOID\nTEMPORARY STOP?", Enum.NormalId.Front, Color3.fromRGB(203, 255, 255), Color3.fromRGB(29, 20, 60))
	makeAtomicBoomerang(room, "VoidLeftWallAtomicBoomerang", cframeAt(origin, -width / 2 + 0.58, 12.6, 1.5) * CFrame.Angles(0, math.rad(90), 0), 1.0, ATOMIC_COLORS.NeonPink)
	makeAtomicDiamondCluster(room, "VoidRightWallAtomicDiamonds", cframeAt(origin, width / 2 - 0.58, 10.8, 9.0) * CFrame.Angles(0, math.rad(-90), 0), 0.9)

	for ringIndex = 1, 7 do
		local ringColor = BOWLING_COSMIC_COLORS[((ringIndex - 1) % #BOWLING_COSMIC_COLORS) + 1]
		local ringCenter = origin + Vector3.new(0, 7 + ringIndex * 1.15, -16 + ringIndex * 4.8)
		local ringCFrame = CFrame.new(ringCenter, ringCenter + Vector3.new(math.sin(ringIndex) * 0.8, 0.2, 1))
			* CFrame.Angles(0, 0, math.rad(ringIndex * 18))
		createZiplineFrame(room, "VoidMotionRing" .. ringIndex, ringCFrame, 13 + ringIndex * 2.4, 8 + ringIndex * 1.2, ringColor)
	end

	for dotIndex = 1, 22 do
		local angle = math.rad(dotIndex * 47)
		local radius = 10 + (dotIndex % 5) * 2.2
		local dot = createPart(
			room,
			"VoidDriftDot" .. dotIndex,
			Vector3.new(0.55 + (dotIndex % 3) * 0.18, 0.55 + (dotIndex % 3) * 0.18, 0.55 + (dotIndex % 3) * 0.18),
			cframeAt(origin, math.cos(angle) * radius, 6 + (dotIndex % 8) * 1.7, math.sin(angle) * radius),
			BOWLING_COSMIC_COLORS[((dotIndex - 1) % #BOWLING_COSMIC_COLORS) + 1],
			Enum.Material.Neon
		)
		dot.Shape = Enum.PartType.Ball
		dot.CanCollide = false
		dot:SetAttribute("BaseCanCollide", false)
		dot:SetAttribute("VoidDriftDot", true)
	end

	local reverseConsole = createPart(room, "VoidReverseConsole", Vector3.new(6.6, 3.2, 0.45), cframeAt(origin, -15.5, 4.2, -13.5) * CFrame.Angles(0, math.rad(24), 0), Color3.fromRGB(44, 23, 84), Enum.Material.Metal)
	createSurfaceText(reverseConsole, "VoidReverseText", "REVERSE\nDIRECTIONS", Enum.NormalId.Front, Color3.fromRGB(119, 255, 203), Color3.fromRGB(44, 23, 84))
	createPrompt(reverseConsole, "Reverse", "Direction Disagreement Console", 0)
	tag(reverseConsole, Constants.Tags.VoidReverseConsole)

	local gravityOrb = createPart(room, "VoidGravityOrb", Vector3.new(3.5, 3.5, 3.5), cframeAt(origin, 0, 7.3, -4), Color3.fromRGB(119, 255, 203), Enum.Material.Neon)
	gravityOrb.Shape = Enum.PartType.Ball
	createPrompt(gravityOrb, "Flip", "Gravity That Changed Its Mind", 0)
	tag(gravityOrb, Constants.Tags.VoidGravityOrb)

	local echoButton = createPart(room, "VoidEchoButton", Vector3.new(2.8, 0.75, 2.8), cframeAt(origin, 10.5, 3.1, -11.5), Color3.fromRGB(255, 88, 128), Enum.Material.Neon)
	echoButton.Shape = Enum.PartType.Ball
	createPrompt(echoButton, "Press", "Listening Button", 0)
	tag(echoButton, Constants.Tags.VoidEchoButton)

	local rayPedestal = createPart(room, "VoidFreezeRayPedestal", Vector3.new(5, 1.2, 3.4), cframeAt(origin, 12.5, 1.1, 9.5), Color3.fromRGB(34, 45, 68), Enum.Material.Metal)
	createSurfaceText(rayPedestal, "VoidPrizeText", "PRIZE\nMAY CHILL", Enum.NormalId.Front, Color3.fromRGB(203, 255, 255), Color3.fromRGB(34, 45, 68))
	local rayCenter = origin + Vector3.new(12.5, 2.55, 9.55)
	local freezeRay = createPart(room, "VoidFreezeRay", Vector3.new(0.62, 3.45, 0.62), CFrame.new(rayCenter + Vector3.new(0, 0, -0.72)) * CFrame.Angles(math.rad(90), 0, 0), Color3.fromRGB(55, 179, 255), Enum.Material.Neon)
	freezeRay.Shape = Enum.PartType.Cylinder
	freezeRay.CanCollide = false
	freezeRay:SetAttribute("BaseCanCollide", false)
	local rayBody = createPart(room, "VoidFreezeRayBody", Vector3.new(1.45, 0.92, 1.22), CFrame.new(rayCenter + Vector3.new(0, -0.03, 0.7)), Color3.fromRGB(36, 116, 210), Enum.Material.Metal)
	local rearBubble = createPart(room, "VoidFreezeRayRearBubble", Vector3.new(1.05, 1.05, 1.05), CFrame.new(rayCenter + Vector3.new(0, 0.02, 1.46)), Color3.fromRGB(84, 219, 255), Enum.Material.Glass)
	rearBubble.Shape = Enum.PartType.Ball
	local grip = createPart(room, "VoidFreezeRayGrip", Vector3.new(0.58, 1.55, 0.5), CFrame.new(rayCenter + Vector3.new(0, -1.0, 0.86)) * CFrame.Angles(math.rad(-14), 0, 0), Color3.fromRGB(21, 59, 111), Enum.Material.Metal)
	local gripPommel = createPart(room, "VoidFreezeRayGripPommel", Vector3.new(0.82, 0.26, 0.66), CFrame.new(rayCenter + Vector3.new(0, -1.78, 1.03)) * CFrame.Angles(math.rad(-14), 0, 0), Color3.fromRGB(18, 42, 78), Enum.Material.Metal)
	local triggerGuard = createPart(room, "VoidFreezeRayTriggerGuard", Vector3.new(0.16, 0.62, 0.9), CFrame.new(rayCenter + Vector3.new(0, -0.56, 0.08)) * CFrame.Angles(math.rad(18), 0, 0), Color3.fromRGB(178, 230, 255), Enum.Material.Metal)
	local trigger = createPart(room, "VoidFreezeRayTrigger", Vector3.new(0.2, 0.42, 0.24), CFrame.new(rayCenter + Vector3.new(0, -0.62, 0.34)) * CFrame.Angles(math.rad(-18), 0, 0), Color3.fromRGB(8, 20, 42), Enum.Material.Metal)
	local muzzleRing = createPart(room, "VoidFreezeRayMuzzleRing", Vector3.new(0.98, 0.32, 0.98), CFrame.new(rayCenter + Vector3.new(0, 0, -2.52)) * CFrame.Angles(math.rad(90), 0, 0), Color3.fromRGB(181, 236, 255), Enum.Material.Metal)
	muzzleRing.Shape = Enum.PartType.Cylinder
	local rearRing = createPart(room, "VoidFreezeRayRearRing", Vector3.new(0.9, 0.28, 0.9), CFrame.new(rayCenter + Vector3.new(0, 0, -0.02)) * CFrame.Angles(math.rad(90), 0, 0), Color3.fromRGB(145, 225, 255), Enum.Material.Metal)
	rearRing.Shape = Enum.PartType.Cylinder
	local topFin = createPart(room, "VoidFreezeRayTopFin", Vector3.new(0.2, 0.78, 0.92), CFrame.new(rayCenter + Vector3.new(0, 0.74, 0.36)) * CFrame.Angles(math.rad(-18), 0, 0), Color3.fromRGB(98, 204, 255), Enum.Material.Neon)
	local antennaStem = createPart(room, "VoidFreezeRayAntennaStem", Vector3.new(0.14, 0.72, 0.14), CFrame.new(rayCenter + Vector3.new(0, 1.08, 1.12)) * CFrame.Angles(math.rad(16), 0, 0), Color3.fromRGB(181, 236, 255), Enum.Material.Metal)
	antennaStem.Shape = Enum.PartType.Cylinder
	local antennaOrb = createPart(room, "VoidFreezeRayAntennaOrb", Vector3.new(0.34, 0.34, 0.34), CFrame.new(rayCenter + Vector3.new(0, 1.45, 1.0)), Color3.fromRGB(120, 255, 255), Enum.Material.Neon)
	antennaOrb.Shape = Enum.PartType.Ball
	local freezeTip = createPart(room, "VoidFreezeRayTip", Vector3.new(0.76, 0.76, 0.76), CFrame.new(rayCenter + Vector3.new(0, 0, -2.78)), Color3.fromRGB(230, 255, 255), Enum.Material.Neon)
	freezeTip.Shape = Enum.PartType.Ball
	for _, rayPart in ipairs({ rayBody, rearBubble, grip, gripPommel, triggerGuard, trigger, muzzleRing, rearRing, topFin, antennaStem, antennaOrb, freezeTip }) do
		rayPart.CanCollide = false
		rayPart:SetAttribute("BaseCanCollide", false)
	end
	createPrompt(freezeRay, "Take", "Freeze Ray Prototype", 0)
	tag(freezeRay, Constants.Tags.VoidFreezeRay)

	local ziplinePath = VOID_ZIPLINE_PATH_POINTS
	local ziplineStart = ziplinePath[1]
	local ziplineEnd = ziplinePath[#ziplinePath]
	local visibleZiplineSegmentCount = 3
	createZiplineWarpCorridor(room, ziplinePath, {
		MaxSegmentIndex = visibleZiplineSegmentCount,
	})
	for segmentIndex = 1, math.min(#ziplinePath - 1, visibleZiplineSegmentCount) do
		local startPoint = ziplinePath[segmentIndex]
		local endPoint = ziplinePath[segmentIndex + 1]
		createBeamBetween(room, "VoidZiplineCable" .. segmentIndex, startPoint, endPoint, 0.22, Color3.fromRGB(24, 27, 34), Enum.Material.Metal)
		createBeamBetween(room, "VoidZiplineGlow" .. segmentIndex, startPoint + Vector3.new(0, -0.34, 0), endPoint + Vector3.new(0, -0.34, 0), 0.08, BOWLING_COSMIC_COLORS[((segmentIndex - 1) % #BOWLING_COSMIC_COLORS) + 1], Enum.Material.Neon)
	end

	local continueHandle = createPart(room, "VoidZiplineHandle", Vector3.new(2.2, 0.42, 1.1), CFrame.new(ziplineStart + Vector3.new(0, -1.6, 0), ziplineEnd), Color3.fromRGB(255, 214, 96), Enum.Material.Metal)
	continueHandle:SetAttribute("StartCFrame", CFrame.new(ziplineStart + Vector3.new(0, -3, 3), ziplineEnd))
	continueHandle:SetAttribute("EndCFrame", TREETOP_ZIPLINE_END_CFRAME)
	continueHandle:SetAttribute("AwardsIsland", true)
	continueHandle:SetAttribute("AwardsVoid", false)
	continueHandle:SetAttribute("RideMessage", "The Void resumes the zipline like nothing unusual happened.")
	continueHandle:SetAttribute("ArrivalMessage", "The island receives you after a completely normal detour.")
	continueHandle:SetAttribute("PathPointCount", #ziplinePath)
	for index, point in ipairs(ziplinePath) do
		continueHandle:SetAttribute("PathPoint" .. index, point)
	end
	createPrompt(continueHandle, "Ride", "Zipline to Island", 0.2)
	tag(continueHandle, Constants.Tags.TreetopZipline)

	local returnDoor = createPart(room, "VoidBowlingReturnDoor", Vector3.new(5.8, 7.2, 0.34), cframeAt(origin, -18, 4.2, 22.75), Color3.fromRGB(73, 91, 122), Enum.Material.Wood)
	returnDoor:SetAttribute("DestinationCFrame", BOWLING_MAINTENANCE_CFRAME)
	returnDoor:SetAttribute("DestinationName", "the bowling alley")
	createSurfaceText(returnDoor, "VoidReturnText", "BACK TO\nBOWLING", Enum.NormalId.Front, Color3.fromRGB(235, 245, 255), Color3.fromRGB(73, 91, 122))
	createPrompt(returnDoor, "Exit", "Bowling Alley", 0)
	tag(returnDoor, Constants.Tags.SecretRoomExit)

	room.PrimaryPart = gravityOrb
	return {
		Model = room,
		LightSwitch = controls.LightSwitch,
		ResetRoomButton = controls.ResetRoomButton,
		ReferenceBook = controls.ReferenceBook,
	}
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
		CFrame.new(origin + Vector3.new(13.2, 4.6, 48.85), origin + Vector3.new(13.2, 4.6, 0)),
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
	makeAtomicStarburst(room, "BowlingLeftWallAtomicStarburst", cframeAt(origin, -width / 2 + 0.58, 10.8, 8.0) * CFrame.Angles(0, math.rad(90), 0), 0.82, ATOMIC_COLORS.Pink, ATOMIC_COLORS.Orange)
	makeAtomicBoomerang(room, "BowlingRightWallAtomicBoomerang", cframeAt(origin, width / 2 - 0.58, 9.8, -10.8) * CFrame.Angles(0, math.rad(-90), 0), 0.82, ATOMIC_COLORS.Orange)

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

	local pinMachineWidth = 32.2
	local machinery = createPart(room, "BowlingPinMachine", Vector3.new(pinMachineWidth, 14.2, 5.6), CFrame.new(origin + Vector3.new(0, 7.35, -34.2)), Color3.fromRGB(48, 52, 63), Enum.Material.Metal)
	createSurfaceText(machinery, "PinMachineText", "PIN MACHINE\nDO NOT ENTER", Enum.NormalId.Front, Color3.fromRGB(255, 235, 149), Color3.fromRGB(48, 52, 63))
	local machineCap = createPart(room, "BowlingPinMachineCap", Vector3.new(pinMachineWidth, 1.2, 6.6), CFrame.new(origin + Vector3.new(0, 14.9, -34.2)), Color3.fromRGB(33, 36, 46), Enum.Material.Metal)
	machineCap:SetAttribute("CosmicSurface", true)

	local maintenanceDoor = createPart(
		room,
		"BowlingMaintenanceDoor",
		Vector3.new(6.2, 7.6, 0.35),
		CFrame.new(origin + Vector3.new(1.2, 4.25, -49.35)) * CFrame.Angles(0, math.rad(180), 0),
		Color3.fromRGB(91, 95, 107),
		Enum.Material.Metal
	)
	maintenanceDoor:SetAttribute("DestinationCFrame", BOWLING_MAINTENANCE_ROOM_CFRAME)
	createSurfaceText(maintenanceDoor, "MaintenanceDoorText", "MAINTENANCE\nROOM", Enum.NormalId.Front, Color3.fromRGB(255, 235, 149), Color3.fromRGB(91, 95, 107))
	createPrompt(maintenanceDoor, "Enter", "Maintenance Room", 0)
	tag(maintenanceDoor, Constants.Tags.BowlingMaintenanceDoor)

	local maintenanceOrigin = origin + Vector3.new(-7, 0, -63)
	local maintenanceWidth = 20
	local maintenanceDepth = 20
	local maintenanceHeight = 12
	local function maintenanceCFrame(x, y, z)
		return CFrame.new(maintenanceOrigin + Vector3.new(x, y, z))
	end

	createPart(room, "MaintenanceFloor", Vector3.new(maintenanceWidth, 1, maintenanceDepth), maintenanceCFrame(0, 0, 0), Color3.fromRGB(55, 58, 66), Enum.Material.Concrete)
	createPart(room, "MaintenanceBackWall", Vector3.new(maintenanceWidth, maintenanceHeight, 1), maintenanceCFrame(0, maintenanceHeight / 2, -maintenanceDepth / 2), Color3.fromRGB(43, 45, 54), Enum.Material.SmoothPlastic)
	createPart(room, "MaintenanceFrontWall", Vector3.new(maintenanceWidth, maintenanceHeight, 1), maintenanceCFrame(0, maintenanceHeight / 2, maintenanceDepth / 2), Color3.fromRGB(43, 45, 54), Enum.Material.SmoothPlastic)
	createPart(room, "MaintenanceLeftWall", Vector3.new(1, maintenanceHeight, maintenanceDepth), maintenanceCFrame(-maintenanceWidth / 2, maintenanceHeight / 2, 0), Color3.fromRGB(37, 39, 48), Enum.Material.SmoothPlastic)
	createPart(room, "MaintenanceRightWall", Vector3.new(1, maintenanceHeight, maintenanceDepth), maintenanceCFrame(maintenanceWidth / 2, maintenanceHeight / 2, 0), Color3.fromRGB(37, 39, 48), Enum.Material.SmoothPlastic)
	createPart(room, "MaintenanceCeiling", Vector3.new(maintenanceWidth, 1, maintenanceDepth), maintenanceCFrame(0, maintenanceHeight, 0), Color3.fromRGB(27, 29, 38), Enum.Material.Concrete)

	local maintenanceExitDoor = createPart(
		room,
		"MaintenanceBowlingExitDoor",
		Vector3.new(6.2, 7.2, 0.34),
		CFrame.new(maintenanceOrigin + Vector3.new(0, 4.15, maintenanceDepth / 2 - 0.62), maintenanceOrigin + Vector3.new(0, 4.15, 0)),
		Color3.fromRGB(73, 91, 122),
		Enum.Material.Wood
	)
	maintenanceExitDoor:SetAttribute("DestinationCFrame", BOWLING_MAINTENANCE_CFRAME)
	maintenanceExitDoor:SetAttribute("DestinationName", "the bowling alley")
	createSurfaceText(maintenanceExitDoor, "MaintenanceExitText", "BOWLING\nALLEY", Enum.NormalId.Front, Color3.fromRGB(235, 245, 255), Color3.fromRGB(73, 91, 122))
	createPrompt(maintenanceExitDoor, "Exit", "Bowling Alley", 0)
	tag(maintenanceExitDoor, Constants.Tags.SecretRoomExit)

	local roomSign = createPart(room, "MaintenanceRoomSign", Vector3.new(10, 1.7, 0.24), maintenanceCFrame(0, 9.4, maintenanceDepth / 2 - 0.92), Color3.fromRGB(255, 235, 149), Enum.Material.Neon)
	createDoubleSidedSurfaceText(roomSign, "MaintenanceRoomSignText", "PIN WORKSHOP\nAUTHORIZED TOUCHING?", Enum.NormalId.Front, Color3.fromRGB(34, 34, 40), Color3.fromRGB(255, 235, 149))
	makeAtomicDiamondCluster(room, "MaintenanceAtomicDiamonds", maintenanceCFrame(-maintenanceWidth / 2 + 0.58, 8.1, 5.3) * CFrame.Angles(0, math.rad(90), 0), 0.58)

	local conveyor = createPart(room, "MaintenanceConveyor", Vector3.new(15.8, 0.34, 2.3), maintenanceCFrame(0, 1.2, -1.8), Color3.fromRGB(34, 38, 48), Enum.Material.Metal)
	conveyor:SetAttribute("CosmicSurface", true)
	for rollerIndex = 1, 7 do
		local roller = createPart(room, "MaintenanceRoller" .. rollerIndex, Vector3.new(0.38, 1.95, 0.38), maintenanceCFrame(-6 + (rollerIndex - 1) * 2, 1.42, -1.8) * CFrame.Angles(math.rad(90), 0, 0), Color3.fromRGB(91, 95, 107), Enum.Material.Metal)
		roller.Shape = Enum.PartType.Cylinder
	end

	for ballIndex, ballData in ipairs({
		{ Offset = Vector3.new(-6.2, 2.1, -1.8), Color = Color3.fromRGB(84, 154, 255) },
		{ Offset = Vector3.new(-2.0, 2.1, -1.8), Color = Color3.fromRGB(255, 88, 128) },
		{ Offset = Vector3.new(2.2, 2.1, -1.8), Color = Color3.fromRGB(150, 112, 255) },
		{ Offset = Vector3.new(6.1, 2.1, -1.8), Color = Color3.fromRGB(119, 255, 203) },
	}) do
		local ball = createPart(room, "MaintenanceBallMover" .. ballIndex, Vector3.new(1.55, 1.55, 1.55), CFrame.new(maintenanceOrigin + ballData.Offset), ballData.Color, Enum.Material.SmoothPlastic)
		ball.Shape = Enum.PartType.Ball
		ball.CanCollide = false
		ball:SetAttribute("BaseCanCollide", false)
		ball:SetAttribute("MaintenanceMotionKind", "Ball")
		ball:SetAttribute("MaintenanceMotionIndex", ballIndex)
		tag(ball, Constants.Tags.BowlingMaintenanceMover)
	end

	for pinIndex, pinX in ipairs({ -6.3, -3.1, 0.1, 3.3, 6.5 }) do
		makeMaintenancePin(room, "MaintenancePinMover" .. pinIndex, CFrame.new(maintenanceOrigin + Vector3.new(pinX, 1.38, 2.45)), 0.78, pinIndex + 4)
	end

	local partsCrate = createPart(room, "MaintenancePartsCrate", Vector3.new(4.5, 2.4, 3.2), maintenanceCFrame(-6.4, 1.7, 6.0), Color3.fromRGB(91, 58, 38), Enum.Material.WoodPlanks)
	createSurfaceText(partsCrate, "MaintenancePartsText", "SPARE\nPIN FEELINGS", Enum.NormalId.Front, Color3.fromRGB(255, 235, 149), Color3.fromRGB(91, 58, 38))

	local lever = createPart(room, "PinsetterResetLever", Vector3.new(0.55, 3.2, 0.55), maintenanceCFrame(6.6, 3.1, 5.9) * CFrame.Angles(0, 0, math.rad(-18)), Color3.fromRGB(255, 214, 96), Enum.Material.Metal)
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
	createDoubleSidedSurfaceText(sign, "SecretRoomSignText", "THE LIBRARY\nPLEASE TOUCH QUIETLY", Enum.NormalId.Front, Color3.fromRGB(36, 27, 42), Color3.fromRGB(255, 226, 102))

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
		CFrame.new(origin + Vector3.new(-width / 2 + 5.4, 4.6, depth / 2 - 0.9), origin + Vector3.new(-width / 2 + 5.4, 4.6, 0)),
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
	local climbTrussBaseSize = Vector3.new(1.35, trunkHeight + 0.8, 1.35)
	local climbTrussSize = climbTrussBaseSize * 1.3
	local climbTrussBottomOffset = trunkHeight / 2 - climbTrussBaseSize.Y / 2
	local climbTruss = createPart(
		tree,
		"PalmClimbTruss",
		climbTrussSize,
		baseCFrame * CFrame.new(0, climbTrussBottomOffset + climbTrussSize.Y / 2, 0),
		Color3.fromRGB(99, 64, 38),
		Enum.Material.Wood,
		"TrussPart"
	)
	climbTruss.Transparency = 1
	climbTruss.CastShadow = false
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

	createDoubleSidedSurfaceText(board, name .. "Text", text, Enum.NormalId.Front, Color3.fromRGB(42, 37, 24), Color3.fromRGB(255, 238, 139))
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
			{ Position = Vector3.new(18.2, 1.0, -8.8), Yaw = 38 },
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
			wood:SetAttribute("IslandPickupBaseCFrame", wood.CFrame)
			createPrompt(wood, "Collect", "Scrap Wood", 0)
			tag(wood, Constants.Tags.IslandScrapWood)
		end

		for rockIndex, data in ipairs({
			{ Position = Vector3.new(-18.5, 1.02, 5.8), Size = Vector3.new(0.95, 0.55, 0.82) },
			{ Position = Vector3.new(16.8, 1.02, 2.6), Size = Vector3.new(0.82, 0.5, 0.7) },
			{ Position = Vector3.new(-6.7, 1.02, 18.3), Size = Vector3.new(0.88, 0.48, 0.72) },
			{ Position = Vector3.new(11.2, 1.02, 17.2), Size = Vector3.new(0.72, 0.44, 0.66), RespawnOnly = true },
		}) do
			local rock = createPart(
				objects,
				"IslandCollectibleRock" .. rockIndex,
				data.Size,
				cframeAt(origin, data.Position.X, data.Position.Y, data.Position.Z) * CFrame.Angles(0, math.rad(rockIndex * 37), math.rad((rockIndex % 3 - 1) * 8)),
				Color3.fromRGB(116, 113, 102),
				Enum.Material.Slate
			)
			rock.Shape = Enum.PartType.Ball
			rock:SetAttribute("RockId", "rock_" .. rockIndex)
			rock:SetAttribute("RespawnOnly", data.RespawnOnly == true)
			if data.RespawnOnly then
				rock.Transparency = 1
				rock.CanCollide = false
				rock:SetAttribute("BaseTransparency", 1)
				rock:SetAttribute("BaseCanCollide", false)
				local prompt = createPrompt(rock, "Collect", "Beach Rock", 0)
				prompt.Enabled = false
				prompt:SetAttribute("BaseEnabled", false)
			else
				createPrompt(rock, "Collect", "Beach Rock", 0)
			end
			tag(rock, Constants.Tags.IslandRock)
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

	for stickIndex = 1, 4 do
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
	local fireLight = Instance.new("PointLight")
	fireLight.Name = "IslandCampfireLight"
	fireLight.Brightness = 0
	fireLight.Color = Color3.fromRGB(255, 150, 72)
	fireLight.Enabled = false
	fireLight.Range = 0
	fireLight.Shadows = true
	fireLight:SetAttribute("IslandFireLight", true)
	fireLight.Parent = fireEmitter
	mark(fireLight)

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
		local shovelCFrame = cframeAt(origin, 3.8, 2.55, 7.1) * CFrame.Angles(math.rad(-68), math.rad(8), math.rad(-38))
		local handle = createPart(shovel, "ShovelHandle", Vector3.new(0.26, 3.85, 0.26), shovelCFrame, Color3.fromRGB(113, 71, 39), Enum.Material.Wood)
		handle:SetAttribute("ShovelPiece", "Handle")
		createPart(shovel, "ShovelGrip", Vector3.new(1.32, 0.22, 0.28), shovelCFrame * CFrame.new(0, 2.04, 0), Color3.fromRGB(84, 51, 30), Enum.Material.Wood):SetAttribute("ShovelPiece", "Grip")
		createPart(shovel, "ShovelGripBack", Vector3.new(0.26, 0.56, 0.26), shovelCFrame * CFrame.new(0, 1.78, 0), Color3.fromRGB(84, 51, 30), Enum.Material.Wood):SetAttribute("ShovelPiece", "GripBack")
		createPart(shovel, "ShovelBladeCollar", Vector3.new(0.72, 0.3, 0.34), shovelCFrame * CFrame.new(0, -1.96, 0), Color3.fromRGB(137, 143, 148), Enum.Material.Metal):SetAttribute("ShovelPiece", "Collar")
		createPart(shovel, "ShovelBladeNeck", Vector3.new(0.36, 0.5, 0.3), shovelCFrame * CFrame.new(0, -2.28, 0), Color3.fromRGB(163, 169, 174), Enum.Material.Metal):SetAttribute("ShovelPiece", "Neck")
		createPart(shovel, "ShovelBlade", Vector3.new(1.35, 1.45, 0.24), shovelCFrame * CFrame.new(0, -2.76, 0), Color3.fromRGB(191, 197, 201), Enum.Material.Metal, "WedgePart"):SetAttribute("ShovelPiece", "Blade")
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
	makeAtomicStarburst(room, "SpaceStationAtomicStarburst", cframeAt(origin, -width / 2 + 0.58, 11.2, 5.8) * CFrame.Angles(0, math.rad(90), 0), 0.68, ATOMIC_COLORS.Pink, ATOMIC_COLORS.Cream)
	makeAtomicBoomerang(room, "SpaceStationAtomicBoomerang", cframeAt(origin, width / 2 - 0.58, 12.1, -1.2) * CFrame.Angles(0, math.rad(-90), 0), 0.7, ATOMIC_COLORS.Orange)

	local returnDoor = createPart(room, "SpaceStationReturnDoor", Vector3.new(6.6, 7.4, 0.36), cframeAt(origin, 0, 4.2, depth / 2 - 0.55), Color3.fromRGB(67, 92, 126), Enum.Material.Metal)
	returnDoor:SetAttribute("DestinationCFrame", ISLAND_SPAWN_CFRAME)
	returnDoor:SetAttribute("DestinationName", "the island")
	createSurfaceText(returnDoor, "SpaceStationReturnText", "AIRLOCK\nTO ISLAND", Enum.NormalId.Front, Color3.fromRGB(231, 247, 255), Color3.fromRGB(67, 92, 126))
	createPrompt(returnDoor, "Cycle", "Airlock to Island", 0)
	tag(returnDoor, Constants.Tags.SecretRoomExit)

	local controls = makeRoomControlPanel(
		room,
		"SpaceStationInsideControlPanel",
		CFrame.new(origin + Vector3.new(-12.4, 4.75, depth / 2 - 0.9), origin + Vector3.new(-12.4, 4.75, 0)),
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
	local drumstickMeat = createPart(room, "SpaceFoodDrumstickMeat", Vector3.new(0.82, 0.72, 0.82), cframeAt(origin, -13.98, 3.78, 2.72), Color3.fromRGB(205, 106, 50), Enum.Material.SmoothPlastic)
	drumstickMeat.Shape = Enum.PartType.Ball
	drumstickMeat:SetAttribute("FoodOutput", true)
	local drumstickBone = createPart(room, "SpaceFoodDrumstickBone", Vector3.new(1.1, 0.2, 0.2), cframeAt(origin, -13.32, 3.72, 2.72), Color3.fromRGB(245, 232, 201), Enum.Material.SmoothPlastic)
	drumstickBone:SetAttribute("FoodOutput", true)
	local foodTube = createPart(room, "SpaceFoodTube", Vector3.new(0.42, 0.42, 1.15), cframeAt(origin, -13.7, 3.63, 2.18) * CFrame.Angles(math.rad(12), math.rad(18), 0), Color3.fromRGB(119, 255, 203), Enum.Material.Metal)
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
		CFrame.new(6.35, 4.7, Constants.Room.Depth / 2 - 0.62),
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
	makeAtomicStarburst(roomFolder, "TVRoomAtomicStarburst", CFrame.new(13.2, 13.6, -Constants.Room.Depth / 2 + 0.62), 0.92, ATOMIC_COLORS.Pink, ATOMIC_COLORS.Orange)
	makeAtomicBoomerang(roomFolder, "TVRoomLeftWallAtomicBoomerang", CFrame.new(-Constants.Room.Width / 2 + 0.58, 10.6, -3.2) * CFrame.Angles(0, math.rad(90), 0), 0.9, ATOMIC_COLORS.Orange)
	makeAtomicDiamondCluster(roomFolder, "TVRoomRightWallAtomicDiamonds", CFrame.new(Constants.Room.Width / 2 - 0.58, 11.5, -6.8) * CFrame.Angles(0, math.rad(-90), 0), 0.68)
	local caveEntrance = makeCaveEntranceArea(roomFolder)
	local securityRoom = makeSecurityRoom(roomFolder)
	local sleepingQuarters = makeSleepingQuartersRoom(roomFolder)
	local sleepingMaintenanceBranch = makeSleepingMaintenanceBranch(roomFolder)
	local infirmary = makeInfirmaryRoom(roomFolder)
	local gym = makeGymRoom(roomFolder)
	local topDownArena = makeTopDownArenaRoom(roomFolder)
	local hallway = makeHallway(roomFolder)
	local snackLab = makeSnackLabShell(roomFolder)
	local islandRoom = makeIslandRoom(roomFolder)
	local tvSecretRoom = makeTVSecretRoom(roomFolder)
	local bowlingAlley = makeBowlingAlley(roomFolder)
	local voidRoom = makeVoidRoom(roomFolder)
	local spaceStation = makeSpaceStationRoom(roomFolder)
	local observationNetwork = makeObservationSuites(roomFolder)
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
	if topDownArena.SafetyFloor then
		connectSafetyFloor(topDownArena.SafetyFloor)
	end
	ResetService.CaptureRoots(roomFolder, objectsFolder)

	return {
		Room = roomFolder,
		InteractiveObjects = objectsFolder,
		RecoveryFloor = recoveryFloor,
		UnderfloorChamber = underfloorChamber,
		ExitDoor = exitDoor,
		CaveEntrance = caveEntrance,
		SecurityRoom = securityRoom,
		SleepingQuarters = sleepingQuarters,
		SleepingMaintenanceBranch = sleepingMaintenanceBranch,
		Infirmary = infirmary,
		Gym = gym,
		TopDownArena = topDownArena,
		ResetRoomButton = resetRoomButton,
		TVInsideLog = tvInsideLog,
		Hallway = hallway,
		TVSecretRoom = tvSecretRoom,
		BowlingAlley = bowlingAlley,
		SpaceStation = spaceStation,
		ObservationNetwork = observationNetwork,
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
