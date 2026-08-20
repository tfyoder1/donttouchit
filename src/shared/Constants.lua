local Constants = {}

Constants.BuildVersion = "0.5.216"
Constants.GameIntro = "You wake up in the forest with no memory of arriving. There is a cave ahead, and the lights inside are already on."
Constants.TitleStoryLines = {
	Default = {
		"The lights were already on.\nSome doors remember being opened.\nThe quiet things are not asleep.",
		"The cave was waiting with a room behind it.\nThe room was waiting with a screen.\nThe screen was not surprised to see you.",
		"Someone left the bunker running.\nSomeone left the rules unfinished.\nSomeone forgot to explain why.",
	},
	ByRoom = {
		CaveEntrance = {
			"The forest keeps poor records.\nThe cave keeps better ones.\nYour footsteps are already in both.",
			"The entrance looks newly made.\nThe moss disagrees.\nThe lights inside do not flicker.",
		},
		TVRoom = {
			"The lights were already on.\nSome doors remember being opened.\nThe quiet things are not asleep.",
			"The television knows the room by name.\nThe room knows yours by absence.\nNothing here likes being first.",
		},
		SnackLab = {
			"The food machines are too cheerful.\nThe labels are too specific.\nThe hunger is not entirely yours.",
			"Something learned comfort from a vending machine.\nSomething learned jokes from a warning sign.\nSomething is still practicing.",
		},
		Security = {
			"The cameras do not watch every room.\nOnly the rooms that watch back.\nSecurity is a kind of conversation.",
			"Power moves through the bunker like breath.\nScreens blink before anyone touches them.\nSome alarms sound almost relieved.",
		},
		SleepingQuarters = {
			"The beds were made for people.\nThe lockers were made for secrets.\nThe dreams were made somewhere else.",
			"The bunks are quiet.\nThe pillows remember weight.\nThe night shift never ended.",
		},
		Infirmary = {
			"The infirmary is clean enough to worry about.\nThe machines know how to wait.\nRecovery is not the same as rescue.",
			"White walls, steady beeps, careful drawers.\nSomeone prepared for injuries.\nSomeone prepared for returns.",
		},
		Library = {
			"The books are shelved in the wrong order.\nThe wrong order is the clue.\nThe clue does not want to be solved yet.",
			"The library has more exits than doors.\nSome pages remember being rooms.\nSome rooms remember being ideas.",
		},
		BowlingAlley = {
			"The lanes are polished like a ritual.\nThe pins stand back up too politely.\nThe music knows when to pretend.",
			"Recreation survived the emergency.\nThat may be worse than the emergency.\nThe ball return hums anyway.",
		},
		SpaceStation = {
			"The stars are close enough to be furniture.\nGravity has a local opinion.\nThe map is less certain than it looks.",
			"The station is not above the bunker.\nAbove is only a setting.\nSettings can be changed.",
		},
		VoidRoom = {
			"The dark room is not empty.\nEmpty would be simpler.\nThis place prefers complicated silences.",
			"The walls stop making promises here.\nThe floor negotiates.\nThe air waits for instructions.",
		},
	},
	Progressive = {
		{
			MinDiscoveries = 20,
			Lines = {
				"You have opened enough doors to be noticed.\nThe bunker has started choosing its words.\nIt still refuses to explain them.",
				"The rooms are no longer introductions.\nThey are evidence.\nThe evidence is rearranging itself.",
			},
		},
		{
			MinDiscoveries = 50,
			Lines = {
				"The bunker is larger than its walls.\nSome spaces are folded carefully.\nSome are folded in a hurry.",
				"Energy, matter, gravity, space.\nThe systems have names.\nThe names are not the systems.",
			},
		},
		{
			MinDiscoveries = 90,
			Lines = {
				"The rooms may not be rooms.\nThe map may not be a map.\nThe exit may be listening.",
				"The deeper chamber is not hidden.\nIt is pretending every other room is real first.",
			},
		},
	},
}
Constants.NormalGravity = 196.2
Constants.SpaceStationGravity = 24
Constants.EventDuration = 10
Constants.EventCooldown = 2.5
Constants.SizeTransformDuration = 24
Constants.SizeTransformCameraDuration = 3

Constants.Room = {
	Width = 42,
	Depth = 34,
	Height = 16,
	TVHeight = 24,
	FloorY = 0,
	RecoveryY = -18,
}

Constants.Remotes = {
	DiscoveryUpdate = "DiscoveryUpdate",
	ReferenceBook = "ReferenceBook",
	HintPackRequest = "HintPackRequest",
	SessionStart = "SessionStart",
	SystemMessage = "SystemMessage",
	RoomStatus = "RoomStatus",
	SparkleHint = "SparkleHint",
	SnackEffect = "SnackEffect",
	FeedbackRequest = "FeedbackRequest",
	DevTools = "DevTools",
	MovementAuthority = "MovementAuthority",
	VoidEffect = "VoidEffect",
	SecurityCamera = "SecurityCamera",
	Prologue = "Prologue",
	TopDownArena = "TopDownArena",
	NourishmentRecovery = "NourishmentRecovery",
	TransformCamera = "TransformCamera",
	LocalAudio = "LocalAudio",
	LocationPing = "LocationPing",
	InventoryAction = "InventoryAction",
	UiLayout = "UiLayout",
}

Constants.Tags = {
	MainButton = "DontTouchIt_MainButton",
	LightSwitch = "DontTouchIt_LightSwitch",
	TVLightSwitch = "DontTouchIt_TVLightSwitch",
	Couch = "DontTouchIt_Couch",
	FloorLamp = "DontTouchIt_FloorLamp",
	Squishy = "DontTouchIt_Squishy",
	Television = "DontTouchIt_Television",
	Appliance = "DontTouchIt_Appliance",
	ExitDoor = "DontTouchIt_ExitDoor",
	HallDoor = "DontTouchIt_HallDoor",
	ReferenceBook = "DontTouchIt_ReferenceBook",
	StoreButton = "DontTouchIt_StoreButton",
	TeleportButton = "DontTouchIt_TeleportButton",
	FieldButton = "DontTouchIt_FieldButton",
	SecretRoomDoor = "DontTouchIt_SecretRoomDoor",
	SecretRoomExit = "DontTouchIt_SecretRoomExit",
	ResetRoomButton = "DontTouchIt_ResetRoomButton",
	NoTouchClock = "DontTouchIt_NoTouchClock",
	UnderfloorReturn = "DontTouchIt_UnderfloorReturn",
	SnackButton = "DontTouchIt_SnackButton",
	SnackFridge = "DontTouchIt_SnackFridge",
	SnackToaster = "DontTouchIt_SnackToaster",
	SnackSink = "DontTouchIt_SnackSink",
	SnackMixer = "DontTouchIt_SnackMixer",
	SnackRack = "DontTouchIt_SnackRack",
	SnackPack = "DontTouchIt_SnackPack",
	SnackDonut = "DontTouchIt_SnackDonut",
	SnackPopcornMachine = "DontTouchIt_SnackPopcornMachine",
	FruitBowl = "DontTouchIt_FruitBowl",
	SnackCeilingFan = "DontTouchIt_SnackCeilingFan",
	LooseFruit = "DontTouchIt_LooseFruit",
	FridgePizza = "DontTouchIt_FridgePizza",
	FridgeBloxyCola = "DontTouchIt_FridgeBloxyCola",
	SecretFridgeButton = "DontTouchIt_SecretFridgeButton",
	IslandExit = "DontTouchIt_IslandExit",
	IslandSharkSign = "DontTouchIt_IslandSharkSign",
	IslandJellyfishSign = "DontTouchIt_IslandJellyfishSign",
	IslandShovel = "DontTouchIt_IslandShovel",
	IslandTreasure = "DontTouchIt_IslandTreasure",
	IslandBloxyCola = "DontTouchIt_IslandBloxyCola",
	IslandCoconut = "DontTouchIt_IslandCoconut",
	IslandCoconutTree = "DontTouchIt_IslandCoconutTree",
	IslandScrapWood = "DontTouchIt_IslandScrapWood",
	IslandRock = "DontTouchIt_IslandRock",
	IslandFireRing = "DontTouchIt_IslandFireRing",
	IslandHiddenSkyBlock = "DontTouchIt_IslandHiddenSkyBlock",
	IslandSpaceLadder = "DontTouchIt_IslandSpaceLadder",
	FloorSection = "DontTouchIt_FloorSection",
	ObjectRainObject = "DontTouchIt_ObjectRainObject",
	TemporaryObject = "DontTouchIt_TemporaryObject",
	LibraryBook = "DontTouchIt_LibraryBook",
	LibraryShelf = "DontTouchIt_LibraryShelf",
	LibraryBookStorm = "DontTouchIt_LibraryBookStorm",
	LibraryLamp = "DontTouchIt_LibraryLamp",
	LibraryGlobe = "DontTouchIt_LibraryGlobe",
	LibraryCatalog = "DontTouchIt_LibraryCatalog",
	LibraryLadder = "DontTouchIt_LibraryLadder",
	LibraryLoftDoor = "DontTouchIt_LibraryLoftDoor",
	LibraryTeleportKey = "DontTouchIt_LibraryTeleportKey",
	LibraryTopShelfKey = "DontTouchIt_LibraryTopShelfKey",
	LibraryBookcaseDoor = "DontTouchIt_LibraryBookcaseDoor",
	BowlingLaneButton = "DontTouchIt_BowlingLaneButton",
	BowlingPin = "DontTouchIt_BowlingPin",
	BowlingCosmicSwitch = "DontTouchIt_BowlingCosmicSwitch",
	BowlingDiscoBall = "DontTouchIt_BowlingDiscoBall",
	BowlingMaintenanceDoor = "DontTouchIt_BowlingMaintenanceDoor",
	BowlingMaintenanceMover = "DontTouchIt_BowlingMaintenanceMover",
	BowlingResetLever = "DontTouchIt_BowlingResetLever",
	BowlingShoeRack = "DontTouchIt_BowlingShoeRack",
	BowlingScoreboard = "DontTouchIt_BowlingScoreboard",
	BowlingGutter = "DontTouchIt_BowlingGutter",
	BowlingBallReturn = "DontTouchIt_BowlingBallReturn",
	TreetopZipline = "DontTouchIt_TreetopZipline",
	VoidReverseConsole = "DontTouchIt_VoidReverseConsole",
	VoidGravityOrb = "DontTouchIt_VoidGravityOrb",
	VoidEchoButton = "DontTouchIt_VoidEchoButton",
	VoidFreezeRay = "DontTouchIt_VoidFreezeRay",
	SpaceStationAirlock = "DontTouchIt_SpaceStationAirlock",
	SpaceStationGravityDial = "DontTouchIt_SpaceStationGravityDial",
	SpaceStationObservationWindow = "DontTouchIt_SpaceStationObservationWindow",
	SpaceStationCommsPanel = "DontTouchIt_SpaceStationCommsPanel",
	SpaceStationFoodPrinter = "DontTouchIt_SpaceStationFoodPrinter",
	SpaceStationSuit = "DontTouchIt_SpaceStationSuit",
	SpaceStationStarMap = "DontTouchIt_SpaceStationStarMap",
	SpaceStationPlantPod = "DontTouchIt_SpaceStationPlantPod",
	SpaceStationMeteorButton = "DontTouchIt_SpaceStationMeteorButton",
	SpaceStationEscapePod = "DontTouchIt_SpaceStationEscapePod",
	CaveLight = "DontTouchIt_CaveLight",
	CaveEntranceSeal = "DontTouchIt_CaveEntranceSeal",
	CaveLockdownReveal = "DontTouchIt_CaveLockdownReveal",
	CaveExitKey = "DontTouchIt_CaveExitKey",
	CaveKeyDoor = "DontTouchIt_CaveKeyDoor",
	CaveAlarmLight = "DontTouchIt_CaveAlarmLight",
	CaveHallwayDoor = "DontTouchIt_CaveHallwayDoor",
	LowerTunnelBlastDoor = "DontTouchIt_LowerTunnelBlastDoor",
	ContributorDuckStand = "DontTouchIt_ContributorDuckStand",
	VictoryBrickStand = "DontTouchIt_VictoryBrickStand",
	VictoryBrick = "DontTouchIt_VictoryBrick",
	VictoryBrickBorder = "DontTouchIt_VictoryBrickBorder",
	SecurityMonitor = "DontTouchIt_SecurityMonitor",
	SecurityConsole = "DontTouchIt_SecurityConsole",
	SecurityRedPhone = "DontTouchIt_SecurityRedPhone",
	SecurityTapeDeck = "DontTouchIt_SecurityTapeDeck",
	SecurityPressurePlate = "DontTouchIt_SecurityPressurePlate",
	BunkerPowerMeter = "DontTouchIt_BunkerPowerMeter",
	ObservationMirror = "DontTouchIt_ObservationMirror",
	SleepingBunk = "DontTouchIt_SleepingBunk",
	SleepingMattress = "DontTouchIt_SleepingMattress",
	SleepingAlarmClock = "DontTouchIt_SleepingAlarmClock",
	SleepingLocker = "DontTouchIt_SleepingLocker",
	SleepingDreamButton = "DontTouchIt_SleepingDreamButton",
	SleepingBlanketFort = "DontTouchIt_SleepingBlanketFort",
	SleepingPillowPile = "DontTouchIt_SleepingPillowPile",
	SleepingIdBadge = "DontTouchIt_SleepingIdBadge",
	InfirmaryRecoveryBed = "DontTouchIt_InfirmaryRecoveryBed",
	InfirmaryMonitor = "DontTouchIt_InfirmaryMonitor",
	InfirmaryCabinet = "DontTouchIt_InfirmaryCabinet",
	InfirmaryNourishment = "DontTouchIt_InfirmaryNourishment",
	GymTreadmill = "DontTouchIt_GymTreadmill",
	GymBike = "DontTouchIt_GymBike",
	GymWeights = "DontTouchIt_GymWeights",
	GymWaterStation = "DontTouchIt_GymWaterStation",
	TopDownCameraConsole = "DontTouchIt_TopDownCameraConsole",
	TopDownWaterBalloonBucket = "DontTouchIt_TopDownWaterBalloonBucket",
	TopDownTargetRing = "DontTouchIt_TopDownTargetRing",
	TopDownSplashTarget = "DontTouchIt_TopDownSplashTarget",
	TopDownScoreboard = "DontTouchIt_TopDownScoreboard",
}

Constants.Hallway = {
	Id = "Hallway",
	Name = "Hallway",
	UnlockedRoomCount = 1,
	TotalRoomCount = 9,
	UnlockDiscoveryFraction = 0.5,
	Zone = {
		Min = Vector3.new(-35, -13, Constants.Room.Depth / 2 - 0.5),
		Max = Vector3.new(7.75, 13, 124),
	},
	SpawnCFrame = CFrame.new(Vector3.new(0, 3, 27), Vector3.new(0, 3, 42)),
}

Constants.NamedPlaces = {
	Hallway = {
		Id = "Hallway",
		Name = "Main Hallway",
		SpawnCFrame = CFrame.new(Vector3.new(0, 3, 27), Vector3.new(0, 3, 42)),
	},
	VictoryWalkway = {
		Id = "VictoryWalkway",
		Name = "Victory Walkway",
		SpawnCFrame = CFrame.new(Vector3.new(-61, 3, 45), Vector3.new(-48, 3, 45)),
	},
	ObservationSecurity = {
		Id = "ObservationSecurity",
		Name = "OBS-SEC-01: Security Observation",
		SpawnCFrame = CFrame.new(Vector3.new(112, 3, -28), Vector3.new(105, 3, -28)),
		TeleportGroup = "Observation",
		RequiresDiscoveryId = "security_observation_mirror",
	},
	ObservationTVRoom = {
		Id = "ObservationTVRoom",
		Name = "OBS-TV-01: TV Room Observation",
		SpawnCFrame = CFrame.new(Vector3.new(-31, 3, 0), Vector3.new(-21, 3, 0)),
		TeleportGroup = "Observation",
		RequiresDiscoveryId = "security_observation_mirror",
	},
	ObservationSnackLab = {
		Id = "ObservationSnackLab",
		Name = "OBS-SNK-01: Snack Lab Observation",
		SpawnCFrame = CFrame.new(Vector3.new(75, 3, 44), Vector3.new(69, 3, 44)),
		TeleportGroup = "Observation",
		RequiresDiscoveryId = "security_observation_mirror",
	},
	ObservationIsland = {
		Id = "ObservationIsland",
		Name = "OBS-ISL-01: Island Observation",
		SpawnCFrame = CFrame.new(Vector3.new(-64, 3, 160), Vector3.new(-55, 3, 160)),
		TeleportGroup = "Observation",
		RequiresDiscoveryId = "security_observation_mirror",
	},
	ObservationLibrary = {
		Id = "ObservationLibrary",
		Name = "OBS-LIB-01: Library Observation",
		SpawnCFrame = CFrame.new(Vector3.new(-38, 3, -45), Vector3.new(-32, 3, -45)),
		TeleportGroup = "Observation",
		RequiresDiscoveryId = "security_observation_mirror",
	},
	ObservationBowling = {
		Id = "ObservationBowling",
		Name = "OBS-BOWL-01: Bowling Observation",
		SpawnCFrame = CFrame.new(Vector3.new(-46, 3, -132), Vector3.new(-38, 3, -132)),
		TeleportGroup = "Observation",
		RequiresDiscoveryId = "security_observation_mirror",
	},
	ObservationSleeping = {
		Id = "ObservationSleeping",
		Name = "OBS-SLEEP-01: Sleeping Observation",
		SpawnCFrame = CFrame.new(Vector3.new(45, 3, -188), Vector3.new(50, 3, -188)),
		TeleportGroup = "Observation",
		RequiresDiscoveryId = "security_observation_mirror",
	},
	ObservationTopDown = {
		Id = "ObservationTopDown",
		Name = "OBS-TRAIN-01: Training Observation",
		SpawnCFrame = CFrame.new(Vector3.new(154, 5, -398), Vector3.new(146, 5, -398)),
		TeleportGroup = "Observation",
		RequiresDiscoveryId = "security_observation_mirror",
	},
	ObservationCave = {
		Id = "ObservationCave",
		Name = "OBS-CAVE-01: Cave Observation",
		SpawnCFrame = CFrame.new(Vector3.new(-88, 3, 68), Vector3.new(-88, 3, 58)),
		TeleportGroup = "Observation",
		RequiresDiscoveryId = "security_observation_mirror",
	},
	ObservationVoid = {
		Id = "ObservationVoid",
		Name = "OBS-VOID-01: Void Observation",
		SpawnCFrame = CFrame.new(Vector3.new(-120, 47, -28), Vector3.new(-110, 47, -28)),
		TeleportGroup = "Observation",
		RequiresDiscoveryId = "security_observation_mirror",
	},
	ObservationSpace = {
		Id = "ObservationSpace",
		Name = "OBS-SPACE-01: Space Observation",
		SpawnCFrame = CFrame.new(Vector3.new(122, 84, 150), Vector3.new(116, 84, 150)),
		TeleportGroup = "Observation",
		RequiresDiscoveryId = "security_observation_mirror",
	},
	ObservationTreetop = {
		Id = "ObservationTreetop",
		Name = "OBS-ZIP-01: Zipline Observation",
		SpawnCFrame = CFrame.new(Vector3.new(-30, 31, -220), Vector3.new(-14, 31, -220)),
		TeleportGroup = "Observation",
		RequiresDiscoveryId = "security_observation_mirror",
	},
}

Constants.DataStore = {
	Name = "DontTouchItPrototype_v1",
	FeedbackName = "DontTouchItFeedback_v1",
	VictoryBricksName = "DontTouchItVictoryBricks_v1",
	VictoryBricksKey = "victory_brick_registry",
	AdminRolesName = "DontTouchItAdminRoles_v1",
	ModerationName = "DontTouchItModeration_v1",
	AdminAuditName = "DontTouchItAdminAudit_v1",
	UiLayoutName = "DontTouchItUiLayout_v1",
	AutosaveSeconds = 45,
	RetryCount = 3,
}

Constants.AdminRoles = {
	Owner = "Owner",
	Developer = "Developer",
	Tester = "Tester",
	Founder = "Founder",
	Player = "Player",
}

Constants.AdminRoleOrder = {
	Constants.AdminRoles.Player,
	Constants.AdminRoles.Tester,
	Constants.AdminRoles.Developer,
	Constants.AdminRoles.Founder,
}

Constants.AdminCapabilities = {
	DEV_FULL = "DEV_FULL",
	DEV_ROOM_TESTING = "DEV_ROOM_TESTING",
	DEV_ECONOMY_TESTING = "DEV_ECONOMY_TESTING",
	DEV_SURVEILLANCE = "DEV_SURVEILLANCE",
	DEV_BUNKER_ENERGY = "DEV_BUNKER_ENERGY",
	TEST_ROOM_TELEPORT = "TEST_ROOM_TELEPORT",
	TEST_ROOM_STATE = "TEST_ROOM_STATE",
	TEST_BUILD_ACCESS = "TEST_BUILD_ACCESS",
	TEST_BUILD_ACCESS_MANAGEMENT = "TEST_BUILD_ACCESS_MANAGEMENT",
	ROLE_MANAGEMENT = "ROLE_MANAGEMENT",
	FOUNDER_RECOGNITION = "FOUNDER_RECOGNITION",
	MOD_WARN_PLAYER = "MOD_WARN_PLAYER",
	MOD_BAN_24H = "MOD_BAN_24H",
	MOD_VIEW_HISTORY = "MOD_VIEW_HISTORY",
	MOD_REMOVE_BAN = "MOD_REMOVE_BAN",
}

Constants.AdminCapabilityOrder = {
	"DEV_FULL",
	"DEV_ROOM_TESTING",
	"DEV_ECONOMY_TESTING",
	"DEV_SURVEILLANCE",
	"DEV_BUNKER_ENERGY",
	"TEST_ROOM_TELEPORT",
	"TEST_ROOM_STATE",
	"TEST_BUILD_ACCESS",
	"TEST_BUILD_ACCESS_MANAGEMENT",
	"ROLE_MANAGEMENT",
	"FOUNDER_RECOGNITION",
	"MOD_WARN_PLAYER",
	"MOD_BAN_24H",
	"MOD_VIEW_HISTORY",
	"MOD_REMOVE_BAN",
}

Constants.DeveloperDefaultCapabilities = {
	"DEV_FULL",
	"DEV_ROOM_TESTING",
	"DEV_ECONOMY_TESTING",
	"DEV_SURVEILLANCE",
	"DEV_BUNKER_ENERGY",
	"TEST_ROOM_TELEPORT",
	"TEST_ROOM_STATE",
	"TEST_BUILD_ACCESS",
	"MOD_WARN_PLAYER",
	"MOD_BAN_24H",
	"MOD_VIEW_HISTORY",
}

Constants.TesterDefaultCapabilities = {
	"TEST_ROOM_TELEPORT",
	"TEST_ROOM_STATE",
	"TEST_BUILD_ACCESS",
}

Constants.ModerationReasons = {
	HARASSMENT = "Harassment",
	ABUSIVE_BEHAVIOR = "Abusive behavior",
	DISRUPTION = "Disrupting other players",
	EXPLOIT_SUSPICION = "Exploit suspicion",
	INAPPROPRIATE_CONDUCT = "Inappropriate conduct",
	SPAM = "Spam",
	OTHER = "Other",
}

Constants.ModerationReasonOrder = {
	"HARASSMENT",
	"ABUSIVE_BEHAVIOR",
	"DISRUPTION",
	"EXPLOIT_SUSPICION",
	"INAPPROPRIATE_CONDUCT",
	"SPAM",
	"OTHER",
}

Constants.VictoryWalkway = {
	CavePriorityPosition = Vector3.new(-46, 0, 55),
	EmptyBrickText = "FUTURE\nWINNER",
	DeluxeTextPrefix = "DELUXE",
	StandardBrickColorA = Color3.fromRGB(180, 96, 62),
	StandardBrickColorB = Color3.fromRGB(124, 72, 48),
	SignedBrickColor = Color3.fromRGB(154, 82, 56),
	DeluxeBrickColor = Color3.fromRGB(132, 82, 46),
	GoldBorderColor = Color3.fromRGB(255, 213, 83),
}

Constants.Feedback = {
	CooldownSeconds = 20,
	Categories = {
		{
			Id = "bug",
			Label = "Bug",
		},
		{
			Id = "idea",
			Label = "Idea",
		},
		{
			Id = "stuck",
			Label = "Stuck",
		},
		{
			Id = "mobile",
			Label = "Mobile issue",
		},
		{
			Id = "controller",
			Label = "Controller issue",
		},
		{
			Id = "more",
			Label = "More like this",
		},
	},
}

Constants.Sparkle = {
	FirstDelaySeconds = 600,
	IntervalSeconds = 60,
	DurationSeconds = 4,
}

Constants.Confetti = {
	DurationSeconds = 90,
}

Constants.Prologue = {
	StartRoomId = "CaveEntrance",
	ContainmentRoomId = "TVRoom",
	CountdownSeconds = 3,
	LightSpinUpSeconds = 30,
	FlashlightRange = 58,
	InspectRange = 34,
	InspectIntervalSeconds = 0.18,
	InspectMovementThreshold = 0.85,
	InspectLookThresholdDegrees = 10,
	InspectStillResampleSeconds = 4.5,
	InspectCandidateSpreadPixels = 32,
	InspectMaxCandidates = 5,
	DarkLighting = {
		Ambient = Color3.fromRGB(1, 2, 5),
		OutdoorAmbient = Color3.fromRGB(0, 0, 0),
		Brightness = 0.05,
		ClockTime = 0,
		FogStart = 16,
		FogEnd = 120,
		FogColor = Color3.fromRGB(4, 6, 12),
	},
}

Constants.AudioAssets = {
	Interface = {
		ControlPanelInteractionId = "rbxassetid://112555741154994",
		MenuMoveSoundId = "rbxassetid://121855518963050",
		MenuMoveVolume = 0.18,
	},
	Events = {
		ObjectRainCollectId = "rbxassetid://98585875176475",
	},
	Inventory = {
		RockDropSoundIds = {
			"rbxassetid://9125869797",
			"rbxassetid://9118587698",
		},
		RockDropVolume = 0.62,
	},
	Music = {
		IntroMusicId = "rbxassetid://138890398994853",
		EndingCreditsId = "rbxassetid://139436746292079",
	},
	Television = {
		StaticId = "rbxassetid://140708560546036",
		TestToneId = "rbxassetid://99709938803492",
		PleaseStopId = "rbxassetid://72577143736585",
	},
	Bowling = {
		CosmicActiveAttribute = "DontTouchItBowlingCosmicActive",
		CosmicMusicAttribute = "DontTouchItBowlingCosmicMusicId",
		CosmicMusicIds = {
			"rbxassetid://9038367768",
			"rbxassetid://87335378694883",
			"rbxassetid://137370718943178",
			"rbxassetid://140712674948564",
		},
		CosmicMusicVolume = 0.35,
		CosmicMusicFadeSeconds = 1.5,
		StrikeSoundIds = {
			"rbxassetid://4692687595",
			"rbxassetid://128237818020429",
		},
		StrikeVolume = 0.72,
	},
	BunkerEnergy = {
		ShutdownSoundId = "rbxassetid://1842440874",
		ShutdownSoundVolume = 0.58,
	},
	RoomAmbience = {
		TVRoom = {
			SoundId = "rbxassetid://1836487465",
			Volume = 0.08,
			FadeSeconds = 1.5,
			ContainmentIntro = {
				SoundId = "rbxassetid://9045322527",
				Volume = 0.08,
				FadeSeconds = 1.5,
				StartDelayBufferSeconds = 0.2,
			},
		},
		Library = {
			SoundId = "rbxassetid://92072185175546",
			Volume = 0.043,
			FadeSeconds = 1.5,
		},
	},
	Footsteps = {
		Volume = 0.37,
		RollOffMaxDistance = 18,
		MinIntervalSeconds = 0.24,
		MaxIntervalSeconds = 0.48,
		AreaOrder = {
			"LibraryLoft",
			"BowlingMaintenance",
		},
		TaggedParts = {
			[Constants.Tags.VictoryBrick] = "rbxassetid://82615619091463",
		},
		Areas = {
			LibraryLoft = {
				SoundId = "rbxassetid://18642905583",
				Zone = {
					Min = Vector3.new(-23, 12, -52),
					Max = Vector3.new(-5, 24, -38),
				},
			},
			BowlingMaintenance = {
				SoundId = "rbxassetid://18642905583",
				Zone = {
					Min = Vector3.new(-31, -3, -205),
					Max = Vector3.new(-11, 16, -185),
				},
			},
		},
		Rooms = {
			TVRoom = "rbxassetid://99669343610628",
			CaveEntrance = "rbxassetid://18640165054",
			TopDownArena = "rbxassetid://140596208736991",
			Island = "rbxassetid://123746536034323",
			SpaceStation = "rbxassetid://140355631752127",
			Library = "rbxassetid://137500783092459",
			BowlingAlley = "rbxassetid://137500783092459",
		},
		Materials = {
			Grass = "rbxassetid://135446324303740",
			LeafyGrass = "rbxassetid://135446324303740",
			Sand = "rbxassetid://123746536034323",
			Fabric = "rbxassetid://140596208736991",
			Wood = "rbxassetid://137500783092459",
			WoodPlanks = "rbxassetid://137500783092459",
			Metal = "rbxassetid://18642905583",
			DiamondPlate = "rbxassetid://18642905583",
			CorrodedMetal = "rbxassetid://18642905583",
			Concrete = "rbxassetid://140355631752127",
			Plastic = "rbxassetid://99669343610628",
			SmoothPlastic = "rbxassetid://99669343610628",
		},
	},
	Prologue = {
		OutsideCaveAmbienceId = "rbxassetid://9112764573",
		InsideCaveAmbienceId = "rbxassetid://9112775414",
		FirstTouchAlarmId = "rbxassetid://9113865831",
		ComputerBootUpId = "rbxassetid://115995638665948",
		LockdownId = "rbxassetid://9116570823",
		LockdownDoorEchoId = "rbxassetid://9116581685",
		DripIds = {},
		CreakIds = {},
	},
}

Constants.BunkerEnergy = {
	MinimumVisualPower = 0.12,
	NeonDimBlend = 0.72,
	NeonExtraTransparency = 0.22,
	LightMinimumPower = 0.18,
	InitialWorldPowerCharge = 0,
	WorldPowerChargeCapacity = 28,
	WorldPowerDecaySeconds = 420,
	WorldPowerExponent = 0.68,
	WorldPowerPulseSeconds = 2.8,
	ActivityPowerPerInteraction = 0.35,
	ActivityPowerPerDiscovery = 1.15,
	PlayerActivityPerInteraction = 0.095,
	PlayerActivityPerDiscovery = 0.18,
	PlayerActivityPerFruit = 0.16,
	PlayerActivityDecaySeconds = 210,
	PersonalProgressLightBonus = 0.12,
	MaxPersonalLightBonus = 0.34,
	MaxSessionPowerBonus = 0.22,
	MaxSpeedPenalty = 0.22,
	ProgressSpeedPenalty = 0.04,
	MinimumSpeedScale = 0.66,
	InitialPlayerEnergy = 1,
	PassiveDrainPerSecond = 0.00018,
	BunkerDrainPerSecond = 0.00105,
	BunkerHungerExponent = 1.2,
	BunkerHungerProgressWeight = 0.58,
	BunkerHungerUnderfedWeight = 0.78,
	BunkerPlayerDrainHungerThreshold = 0.34,
	SubsystemMinimumPower = 0.14,
	SubsystemWeakPower = 0.38,
	SubsystemFullPower = 0.72,
	CosmicMinimumPower = 0.2,
	CosmicWeakPower = 0.5,
	WalkingDrainPerStud = 0.000018,
	WalkingDrainHungerMultiplier = 0.7,
	MaxTrackedWalkDistancePerUpdate = 80,
	InteractionEnergyCost = 0.009,
	DiscoveryEnergyCost = 0.014,
	LowEnergyWarningThreshold = 0.24,
	LowEnergyWarningCooldownSeconds = 36,
	PassOutThreshold = 0.025,
	PassOutCriticalSeconds = 8,
	RecoveryEnergyBaseline = 0.46,
	RecoveryFadeOutSeconds = 2.1,
	RecoveryBlackSeconds = 2,
	RecoveryFadeInSeconds = 2.2,
	RecoveryBeepSoundId = "rbxassetid://93825496198148",
	RecoveryBeepVolume = 0.3,
	RecoveryBeepMovingVolume = 0.16,
	InactivityEnticementHungerThreshold = 0.64,
	InactivityEnticementCooldownSeconds = 85,
	FruitEnergyRestore = 0.32,
	MatterEnergyRestore = 0.18,
	PopcornEnergyRestore = 0.12,
	ColaEnergyRestore = 0.24,
	MaxPocketEnergyItems = 5,
	EnergyReserveStackLimit = 10,
	FruitRecoverySeconds = 150,
	FruitSpeedRelief = 0.11,
	FruitPowerBonus = 2.2,
	MatterReclaimPowerPerPart = 0.018,
	UpdateIntervalSeconds = 4,
}

Constants.MatterConversion = {
	DecayColor = Color3.fromRGB(42, 43, 42),
	DecayLeadSeconds = 22,
	DecayDurationSeconds = 14,
	DecayMinimumDelaySeconds = 8,
	ObjectRainDecayDelaySeconds = 150,
	ObjectRainAbsorbDelaySeconds = 285,
	ObjectRainAbsorbDurationSeconds = 3.4,
}

Constants.RoomPlay = {
	HintIntervalSeconds = 300,
	HintsPerInterval = 5,
}

Constants.FieldControls = {
	{
		Id = "LowGravity",
		Name = "Low Gravity",
		Description = "Gravity becomes negotiable until RESET.",
		RequiresDiscoveryId = "low_gravity",
	},
	{
		Id = "TinyPlayer",
		Name = "Tiny Player",
		Description = "Make yourself travel-size for a short while.",
		RequiresDiscoveryId = "tiny_players",
	},
	{
		Id = "GiantPlayer",
		Name = "Giant Player",
		Description = "Make yourself problem-size for a short while.",
		RequiresDiscoveryId = "giant_player",
	},
}

Constants.FloorPressMessages = {
	[1] = "The floor files a complaint: 1 / 5.",
	[2] = "The floor is now taking this personally: 2 / 5.",
	[3] = "A sensible floor would ignore you. This one cannot: 3 / 5.",
	[4] = "The floor is one press away from a dramatic career change: 4 / 5.",
}

Constants.Discoveries = {
	PressedButton = {
		Id = "pressed_button",
		Name = "Pressed The Button",
		Hint = "The huge red button is the obvious bad idea.",
	},
	LowGravity = {
		Id = "low_gravity",
		Name = "Experienced Low Gravity",
		Hint = "The floor only gives up on gravity after five presses.",
	},
	TinyPlayers = {
		Id = "tiny_players",
		Name = "Became Tiny",
		Hint = "The red button can make everyone unusually small.",
	},
	GiantPlayer = {
		Id = "giant_player",
		Name = "Saw a Giant Player",
		Hint = "Cycle the light switch back on a few times.",
	},
	ObjectRain = {
		Id = "object_rain",
		Name = "Survived Object Rain",
		Hint = "The red button eventually runs out of better ideas.",
	},
	DelayedSurprise = {
		Id = "delayed_surprise",
		Name = "Found the Delayed Surprise",
		Hint = "Sometimes the red button pretends nothing happened. Wait a little.",
	},
	EscapedUnderfloor = {
		Id = "escaped_underfloor",
		Name = "Escaped the Floor Basement",
		Hint = "When the floor opens, fall carefully and use the glowing return controls below.",
	},
	RanAppliance = {
		Id = "ran_appliance",
		Name = "Started the Microwave",
		Hint = "The microwave on the wall-side table is not just decoration.",
	},
	RodeCouch = {
		Id = "rode_couch",
		Name = "Rode the Couch",
		Hint = "Sit on the couch and give it a few seconds to make a choice.",
	},
	AnnoyedLamp = {
		Id = "annoyed_lamp",
		Name = "Annoyed the Lamp",
		Hint = "Toggle the floor lamp until it gets tired of you.",
	},
	OverSquished = {
		Id = "over_squished",
		Name = "Over-Squished the Squishy",
		Hint = "The squishy only reveals its secret after repeated squeezing.",
	},
	AngeredTelevision = {
		Id = "angered_television",
		Name = "Angered the Television",
		Hint = "Power the TV more times than a reasonable person would.",
	},
	TVRoomNoTouch = {
		Id = "tv_room_no_touch",
		Name = "Left the TV Room Alone",
		Hint = "Stand in the TV Room for two minutes without interacting with anything.",
	},
	PressedSnackButton = {
		Id = "pressed_snack_button",
		Name = "Pressed the Snack Lab Button",
		Hint = "The blue Snack Lab button is also making poor choices.",
	},
	OpenedFridge = {
		Id = "opened_fridge",
		Name = "Opened the Fridge",
		Hint = "Open the fridge and look for the cool idea.",
	},
	FridgePizza = {
		Id = "fridge_pizza",
		Name = "Found Fridge Pizza",
		Hint = "Open the fridge and inspect the pizza inside.",
	},
	FridgeBloxyCola = {
		Id = "fridge_bloxy_cola",
		Name = "Found Fridge Bloxy Cola",
		Hint = "Open the fridge and try the cola inside.",
	},
	SecretFridgeButton = {
		Id = "secret_fridge_button",
		Name = "Pressed the Secret Fridge Button",
		Hint = "Open the fridge and check the inside of the door.",
	},
	SuspiciousToast = {
		Id = "suspicious_toast",
		Name = "Made Suspicious Toast",
		Hint = "Use the toaster. The toast is lighter than expected.",
	},
	AngrySink = {
		Id = "angry_sink",
		Name = "Annoyed the Sink",
		Hint = "Turn the sink a few times.",
	},
	MixedCloud = {
		Id = "mixed_cloud",
		Name = "Mixed the Cloud",
		Hint = "The mixer is more interested in weather than batter.",
	},
	SnackRack = {
		Id = "snack_rack",
		Name = "Checked the Snack Rack",
		Hint = "Inspect the colorful snack shelf in the Snack Lab.",
	},
	SnackDonut = {
		Id = "snack_wall_donut",
		Name = "Admired the Wall Donut",
		Hint = "The Snack Lab has one snack too large for any plate.",
	},
	SnackPopcorn = {
		Id = "snack_popcorn_machine",
		Name = "Started the Popcorn Machine",
		Hint = "The popcorn machine near the Snack Lab wall is not just for decoration.",
	},
	HeardSnackSound = {
		Id = "heard_snack_sound",
		Name = "Heard a Snack Sound",
		Hint = "The snack packs are not just decorative. Try one directly.",
	},
	AllSnackSounds = {
		Id = "all_snack_sounds",
		Name = "Sampled Every Snack",
		Hint = "Every snack pack on the rack has something to say.",
	},
	LivingFruit = {
		Id = "living_fruit",
		Name = "Woke the Fruit Bowl",
		Hint = "Try the fruit bowl before it tries anything first.",
	},
	SnackLabNoTouch = {
		Id = "snack_lab_no_touch",
		Name = "Left the Snack Lab Alone",
		Hint = "Stand in the Snack Lab for two minutes without interacting with anything.",
	},
	RainBasement = {
		Id = "rain_basement",
		Name = "Moved the Rain Downstairs",
		Hint = "This secret is not listed in the room log.",
	},
	ReachedIsland = {
		Id = "reached_island",
		Name = "Reached the Island",
		Hint = "Take the long hallway from the main hall.",
	},
	SharkBounce = {
		Id = "shark_bounce",
		Name = "Survived the Shark Attack",
		Hint = "Walk toward the ocean edge three times. The hallway door is not the dangerous exit.",
	},
	ReadSharkWarning = {
		Id = "read_shark_warning",
		Name = "Read the Shark Warning",
		Hint = "Read the shark warning near the island shore more than once.",
	},
	ReadJellyfishWarning = {
		Id = "read_jellyfish_warning",
		Name = "Read the Jellyfish Warning",
		Hint = "Read the jellyfish warning near the island shore more than once.",
	},
	DugTreasure = {
		Id = "dug_treasure",
		Name = "Dug Up Treasure",
		Hint = "Use the shovel on the island.",
	},
	OpenedTreasure = {
		Id = "opened_treasure",
		Name = "Opened the Treasure Box",
		Hint = "After digging, open the treasure box.",
	},
	IslandBloxyCola = {
		Id = "island_bloxy_cola",
		Name = "Found Island Bloxy Cola",
		Hint = "Open the treasure box and try the cola.",
	},
	IslandCoconutCrab = {
		Id = "island_coconut_crab",
		Name = "Met the Coconut Crab",
		Hint = "Inspect the ground coconut near the back-left side of the island.",
	},
	IslandDroppedCoconut = {
		Id = "island_dropped_coconut",
		Name = "Convinced a Palm Tree",
		Hint = "One palm tree has two coconuts and might respond to a shake.",
	},
	IslandDriftwood = {
		Id = "island_driftwood",
		Name = "Collected Driftwood",
		Hint = "Look near the island edges for scraps of wood.",
	},
	IslandCollectedRock = {
		Id = "island_collected_rock",
		Name = "Collected a Very Official Rock",
		Hint = "The small beach rocks are portable, which is probably a clue.",
	},
	IslandCampfire = {
		Id = "island_campfire",
		Name = "Lit the Campfire",
		Hint = "Bring driftwood to the rock ring near the center of the island.",
	},
	IslandSeagulls = {
		Id = "island_seagulls",
		Name = "Summoned Seagulls",
		Hint = "Inspect the quieter ground coconut near the right side of the island.",
	},
	IslandNoTouch = {
		Id = "island_no_touch",
		Name = "Left the Island Alone",
		Hint = "Stand on the island for two minutes without interacting with anything.",
	},
	SpaceStationEntered = {
		Id = "space_station_entered",
		Name = "Reached the Space Station",
		Hint = "Climb a palm tree, bonk the hidden block above it, then use the ladder upward.",
	},
	SpaceStationAirlock = {
		Id = "space_station_airlock",
		Name = "Questioned the Airlock",
		Hint = "Start near the door. Space doors always have opinions.",
	},
	SpaceStationGravityDial = {
		Id = "space_station_gravity_dial",
		Name = "Adjusted the Gravity Dial",
		Hint = "Look for the dial that claims gravity has settings.",
	},
	SpaceStationObservationWindow = {
		Id = "space_station_observation_window",
		Name = "Stared Into Space",
		Hint = "Look through the big station window and let the star field drift.",
	},
	SpaceStationCommsPanel = {
		Id = "space_station_comms_panel",
		Name = "Pinged Mission Control",
		Hint = "The comms panel would love to send one extremely unhelpful message.",
	},
	SpaceStationFoodPrinter = {
		Id = "space_station_food_printer",
		Name = "Printed Space Food",
		Hint = "Use the food printer and watch the tray on top.",
	},
	SpaceStationSuit = {
		Id = "space_station_suit",
		Name = "Inspected the Space Suit",
		Hint = "The suit locker is prepared for someone shaped roughly like trouble.",
	},
	SpaceStationStarMap = {
		Id = "space_station_star_map",
		Name = "Rearranged the Star Map",
		Hint = "Use the control panel below the floating star map.",
	},
	SpaceStationPlantPod = {
		Id = "space_station_plant_pod",
		Name = "Watered the Space Plant",
		Hint = "Even in orbit, somebody forgot to water the plant.",
	},
	SpaceStationMeteorButton = {
		Id = "space_station_meteor_button",
		Name = "Requested a Meteor",
		Hint = "A red button in space is somehow even less reassuring.",
	},
	SpaceStationEscapePod = {
		Id = "space_station_escape_pod",
		Name = "Tested the Escape Pod",
		Hint = "The escape pod is not a toy, which is exactly what a toy would say.",
	},
	SpaceStationNoTouch = {
		Id = "space_station_no_touch",
		Name = "Left Orbit Alone",
		Hint = "Stand in the Space Station for two minutes without interacting with anything.",
	},
	LibraryEntered = {
		Id = "library_entered",
		Name = "Entered the Library",
		Hint = "Open the Library from the TV Room with the Library Key.",
	},
	LibraryForbiddenBook = {
		Id = "library_forbidden_book",
		Name = "Read the Book That Sighed",
		Hint = "One book on the Library table does not want to be opened.",
	},
	LibraryShushedShelf = {
		Id = "library_shushed_shelf",
		Name = "Got Shushed by a Shelf",
		Hint = "A tall Library shelf reacts if inspected directly.",
	},
	LibraryBookStorm = {
		Id = "library_book_storm",
		Name = "Started a Book Storm",
		Hint = "A suspiciously loose Library book may object to being shelved.",
	},
	LibraryLamp = {
		Id = "library_lamp",
		Name = "Turned On the Reading Lamp",
		Hint = "The desk lamp in the Library is waiting for a reader.",
	},
	LibraryGlobe = {
		Id = "library_globe",
		Name = "Spun the Wrong Globe",
		Hint = "The Library globe is not entirely committed to geography.",
	},
	LibraryCatalog = {
		Id = "library_catalog",
		Name = "Opened the Card Catalog",
		Hint = "Check the tiny drawers near the Library shelves.",
	},
	LibraryLadder = {
		Id = "library_ladder",
		Name = "Found the Rolling Ladder",
		Hint = "The tall shelves have a ladder on a track.",
	},
	LibraryLoft = {
		Id = "library_loft",
		Name = "Reached the Loft Door",
		Hint = "The loft door is visible above the Library, but the ladder makes it reachable.",
	},
	LibraryTeleportKey = {
		Id = "library_teleport_key",
		Name = "Found the Teleport Key",
		Hint = "Search the Library loft shelves for a key that prefers fast travel.",
	},
	LibraryBowlingKey = {
		Id = "library_bowling_key",
		Name = "Found the Bowling Key",
		Hint = "Use the Library ladder and check the top shelves along the outside wall.",
	},
	LibraryBookcaseDoor = {
		Id = "library_bookcase_door",
		Name = "Opened the Bookcase Door",
		Hint = "A bookcase in the Library swings open after you find the Bowling Key.",
	},
	LibraryNoTouch = {
		Id = "library_no_touch",
		Name = "Left the Library Alone",
		Hint = "Stand in the Library for two minutes without interacting with anything.",
	},
	BowlingEntered = {
		Id = "bowling_entered",
		Name = "Entered the Bowling Alley",
		Hint = "Open the secret bookcase in the Library.",
	},
	BowlingFirstBall = {
		Id = "bowling_first_ball",
		Name = "Rolled the First Ball",
		Hint = "Use one of the lane buttons near the ball returns.",
	},
	BowlingPinsHit = {
		Id = "bowling_pins_hit",
		Name = "Hit the Pins",
		Hint = "A bowling ball must reach the pins at the far end.",
	},
	BowlingStrike = {
		Id = "bowling_strike",
		Name = "Almost Bowled a Strike",
		Hint = "Knock down enough pins with one roll.",
	},
	BowlingGutter = {
		Id = "bowling_gutter",
		Name = "Inspected the Gutter",
		Hint = "The lane gutters are suspiciously proud of their job.",
	},
	BowlingCosmic = {
		Id = "bowling_cosmic",
		Name = "Started Cosmic Bowling",
		Hint = "Use the light switch near the Bowling Alley entrance.",
	},
	BowlingDiscoBall = {
		Id = "bowling_disco_ball",
		Name = "Questioned the Disco Ball",
		Hint = "Cosmic bowling has a disco ball near the ceiling.",
	},
	BowlingMaintenance = {
		Id = "bowling_maintenance",
		Name = "Found the Maintenance Room",
		Hint = "Look behind the pin machinery at the far end of the lanes.",
	},
	BowlingResetLever = {
		Id = "bowling_reset_lever",
		Name = "Pulled the Pinsetter Lever",
		Hint = "The maintenance room has a reset lever.",
	},
	BowlingShoes = {
		Id = "bowling_shoes",
		Name = "Ignored the Shoe Policy",
		Hint = "Inspect the shoe rack near the Bowling Alley entrance.",
	},
	BowlingScoreboard = {
		Id = "bowling_scoreboard",
		Name = "Read the Scoreboard",
		Hint = "The scoreboard is more judgmental than mathematical.",
	},
	BowlingBallReturn = {
		Id = "bowling_ball_return",
		Name = "Pressed the Ball Return",
		Hint = "The ball return has its own button near the lanes.",
	},
	BowlingNoTouch = {
		Id = "bowling_no_touch",
		Name = "Left the Bowling Alley Alone",
		Hint = "Stand in the Bowling Alley for two minutes without interacting with anything.",
	},
	TreetopZiplineEntered = {
		Id = "treetop_zipline_entered",
		Name = "Reached the Treetop Zipline",
		Hint = "Look behind the bowling pin machinery for a very vertical shortcut.",
	},
	VoidEntered = {
		Id = "void_entered",
		Name = "Stopped in the Void",
		Hint = "Ride the treetop zipline. It has started making unscheduled stops.",
	},
	VoidReverseControls = {
		Id = "void_reverse_controls",
		Name = "Walked Wrong on Purpose",
		Hint = "The Void has a console that disagrees with directions.",
	},
	VoidGravityFlip = {
		Id = "void_gravity_flip",
		Name = "Flipped Void Gravity",
		Hint = "Touch the floating gravity orb in the Void.",
	},
	VoidEcho = {
		Id = "void_echo",
		Name = "Heard the Void Answer",
		Hint = "Press the button that looks like it is listening.",
	},
	VoidFreezeRay = {
		Id = "void_freeze_ray",
		Name = "Claimed the Freeze Ray",
		Hint = "The Void keeps one questionable prize near the exit.",
	},
	VoidNoTouch = {
		Id = "void_no_touch",
		Name = "Left the Void Alone",
		Hint = "Stand in the Void for two minutes without interacting with anything. The Void takes this personally.",
	},
	CaveEntered = {
		Id = "cave_entered",
		Name = "Found the Lit Cave",
		Hint = "Start at the cave entrance and follow the suspicious electric glow.",
	},
	CaveFirstLight = {
		Id = "cave_first_light",
		Name = "Touched the First Cave Light",
		Hint = "The first electric light inside the cave seems unusually important.",
	},
	CaveChangedLights = {
		Id = "cave_changed_lights",
		Name = "Changed the Cave Lights",
		Hint = "The cave lights are absolutely interactive, which is not comforting.",
	},
	CaveExitKey = {
		Id = "cave_exit_key",
		Name = "Took the Exit Key",
		Hint = "The desk in the cavern has a key under a very unambiguous sign.",
	},
	CaveOpenedDoor = {
		Id = "cave_opened_door",
		Name = "Opened the Cave Door",
		Hint = "The long tunnel ends at a door shaped like the key from the desk.",
	},
	LowerTunnelBlastDoor = {
		Id = "lower_tunnel_blast_door",
		Name = "Found the Lower Blast Doors",
		Hint = "Before paradise, look for the open stairwell down to the duck pond tunnel.",
	},
	SecurityEntered = {
		Id = "security_entered",
		Name = "Entered Security",
		Hint = "The hallway has a door marked Security.",
	},
	SecurityMonitorWall = {
		Id = "security_monitor_wall",
		Name = "Noticed the Monitor Wall",
		Hint = "Inspect the giant wall of screens in Security.",
	},
	SecurityCameraView = {
		Id = "security_camera_view",
		Name = "Watched Yourself Watching",
		Hint = "One monitor in Security does more than display static.",
	},
	SecurityBunkerEnergy = {
		Id = "security_bunker_energy",
		Name = "Checked Bunker Energy",
		Hint = "Inspect the bunker power meter in Security.",
	},
	SecurityScreenButton = {
		Id = "security_screen_button",
		Name = "Pressed the Screen-Only Button",
		Hint = "Use the Security monitor view and look for a button that only appears on the screen.",
	},
	SecurityRedPhone = {
		Id = "security_red_phone",
		Name = "Picked Up the Red Phone",
		Hint = "Security desks tend to have phones for extremely normal emergencies.",
	},
	SecurityTapeDeck = {
		Id = "security_tape_deck",
		Name = "Reviewed the Tape",
		Hint = "The Security room stores footage in a suspiciously chunky machine.",
	},
	SecurityObservationMirror = {
		Id = "security_observation_mirror",
		Name = "Found the Observation Glass",
		Hint = "Security has one mirror that is much too interested in both sides.",
	},
	SleepingEntered = {
		Id = "sleeping_entered",
		Name = "Entered Sleeping Quarters",
		Hint = "The hallway has a door marked Sleeping Quarters.",
	},
	SleepingCountedBunks = {
		Id = "sleeping_counted_bunks",
		Name = "Counted Too Many Bunks",
		Hint = "One of the bunk beds is practically begging to be counted.",
	},
	SleepingAlarmClock = {
		Id = "sleeping_alarm_clock",
		Name = "Snoozed the Wrong Alarm",
		Hint = "The tiny alarm clock near the entrance is not enjoying its job.",
	},
	SleepingLocker = {
		Id = "sleeping_locker",
		Name = "Opened the Cleaning Supplies Locker",
		Hint = "There is a wall locker in Sleeping Quarters with suspiciously tidy equipment.",
	},
	SleepingAllLockers = {
		Id = "sleeping_all_lockers",
		Name = "Checked Every Bunk Locker",
		Hint = "The little lockers between the bunks each want a quick inspection.",
	},
	SleepingDreamButton = {
		Id = "sleeping_dream_button",
		Name = "Pressed the Dream Button",
		Hint = "Find the button that promises absolutely responsible dreaming.",
	},
	SleepingBlanketFort = {
		Id = "sleeping_blanket_fort",
		Name = "Inspected the Blanket Fort",
		Hint = "One bunk has developed architecture.",
	},
	SleepingPillowPile = {
		Id = "sleeping_pillow_pile",
		Name = "Disturbed the Pillow Pile",
		Hint = "The pillow pile is not structural, probably.",
	},
	SleepingIdBadge = {
		Id = "sleeping_id_badge",
		Name = "Found the ID Badge",
		Hint = "Sleeping Quarters has one badge left behind by someone who wanted doors to stop asking questions.",
	},
	SleepingNoTouch = {
		Id = "sleeping_no_touch",
		Name = "Left the Sleeping Quarters Alone",
		Hint = "Stand in Sleeping Quarters for two minutes without interacting with anything.",
	},
	InfirmaryEntered = {
		Id = "infirmary_entered",
		Name = "Found the Infirmary",
		Hint = "Sleeping Quarters has a midpoint branch that does not look newly installed.",
	},
	InfirmaryRecoveryBed = {
		Id = "infirmary_recovery_bed",
		Name = "Inspected the Recovery Bed",
		Hint = "The primary medical bed is set apart from the others, as if it expects company.",
	},
	InfirmaryMonitor = {
		Id = "infirmary_monitor",
		Name = "Read the Patient Monitor",
		Hint = "The old monitor near the recovery bed knows more about your condition than it should.",
	},
	InfirmaryCabinet = {
		Id = "infirmary_cabinet",
		Name = "Opened the Neatest Cabinet",
		Hint = "One Infirmary cabinet is unusually well stocked for a place this old.",
	},
	InfirmaryNourishment = {
		Id = "infirmary_nourishment",
		Name = "Accepted Stabilization Snack",
		Hint = "There is food and water near the recovery bed, left where a waking person would see it.",
	},
	InfirmaryNoTouch = {
		Id = "infirmary_no_touch",
		Name = "Left the Infirmary Alone",
		Hint = "Stand in the Infirmary for two minutes without interacting with anything.",
	},
	GymEntered = {
		Id = "gym_entered",
		Name = "Found Physical Conditioning",
		Hint = "The Sleeping Quarters midpoint branch also leads upward toward a room with exercise equipment.",
	},
	GymTreadmill = {
		Id = "gym_treadmill",
		Name = "Tested Tomorrow's Treadmill",
		Hint = "The Gym treadmill looks like it tracks more than distance.",
	},
	GymBike = {
		Id = "gym_bike",
		Name = "Pedaled for the System",
		Hint = "The stationary bike has cables that disappear into the wall.",
	},
	GymWeights = {
		Id = "gym_weights",
		Name = "Lifted Approved Mass",
		Hint = "The free weights are arranged like someone still checks inventory.",
	},
	GymWaterStation = {
		Id = "gym_water_station",
		Name = "Used the Recovery Fountain",
		Hint = "The Gym water station is clean enough to be suspicious.",
	},
	GymNoTouch = {
		Id = "gym_no_touch",
		Name = "Left the Gym Alone",
		Hint = "Stand in the Gym for two minutes without interacting with anything.",
	},
	TopDownEntered = {
		Id = "top_down_entered",
		Name = "Entered the Training Arena",
		Hint = "Go through the arena door at the back of Sleeping Quarters.",
	},
	TopDownCamera = {
		Id = "top_down_camera",
		Name = "Looked From Above",
		Hint = "The arena changes your view from above. The camera console explains itself if inspected.",
	},
	TopDownWaterBalloon = {
		Id = "top_down_water_balloon",
		Name = "Threw a Water Balloon",
		Hint = "Use one of the water balloon buckets around the Training Arena.",
	},
	TopDownRingScore = {
		Id = "top_down_ring_score",
		Name = "Lobbed One Into the Ring",
		Hint = "If nobody else is nearby, a water balloon bucket lobs toward the big target ring.",
	},
	TopDownPlayerSplash = {
		Id = "top_down_player_splash",
		Name = "Splashed a Moving Target",
		Hint = "Use a water balloon bucket while another player or the practice target is inside the arena.",
	},
	TopDownBucketRefill = {
		Id = "top_down_bucket_refill",
		Name = "Trusted the Refill Bucket",
		Hint = "The bucket near the glowing pipe has extra water balloons and very little supervision.",
	},
	TopDownScoreboard = {
		Id = "top_down_scoreboard",
		Name = "Checked the Splash Score",
		Hint = "The arena scoreboard is keeping track of questionable accuracy.",
	},
	TopDownNoTouch = {
		Id = "top_down_no_touch",
		Name = "Left the Arena Alone",
		Hint = "Stand in the Training Arena for two minutes without interacting with anything.",
	},
}

Constants.RoomDiscoveryOrder = {
	CaveEntrance = {
		Constants.Discoveries.CaveEntered.Id,
		Constants.Discoveries.CaveFirstLight.Id,
		Constants.Discoveries.CaveChangedLights.Id,
		Constants.Discoveries.CaveExitKey.Id,
		Constants.Discoveries.CaveOpenedDoor.Id,
		Constants.Discoveries.LowerTunnelBlastDoor.Id,
	},
	SecurityRoom = {
		Constants.Discoveries.SecurityEntered.Id,
		Constants.Discoveries.SecurityMonitorWall.Id,
		Constants.Discoveries.SecurityCameraView.Id,
		Constants.Discoveries.SecurityBunkerEnergy.Id,
		Constants.Discoveries.SecurityScreenButton.Id,
		Constants.Discoveries.SecurityRedPhone.Id,
		Constants.Discoveries.SecurityTapeDeck.Id,
		Constants.Discoveries.SecurityObservationMirror.Id,
	},
	SleepingQuarters = {
		Constants.Discoveries.SleepingEntered.Id,
		Constants.Discoveries.SleepingCountedBunks.Id,
		Constants.Discoveries.SleepingAlarmClock.Id,
		Constants.Discoveries.SleepingLocker.Id,
		Constants.Discoveries.SleepingAllLockers.Id,
		Constants.Discoveries.SleepingDreamButton.Id,
		Constants.Discoveries.SleepingBlanketFort.Id,
		Constants.Discoveries.SleepingPillowPile.Id,
		Constants.Discoveries.SleepingIdBadge.Id,
		Constants.Discoveries.SleepingNoTouch.Id,
	},
	Infirmary = {
		Constants.Discoveries.InfirmaryEntered.Id,
		Constants.Discoveries.InfirmaryRecoveryBed.Id,
		Constants.Discoveries.InfirmaryMonitor.Id,
		Constants.Discoveries.InfirmaryCabinet.Id,
		Constants.Discoveries.InfirmaryNourishment.Id,
		Constants.Discoveries.InfirmaryNoTouch.Id,
	},
	Gym = {
		Constants.Discoveries.GymEntered.Id,
		Constants.Discoveries.GymTreadmill.Id,
		Constants.Discoveries.GymBike.Id,
		Constants.Discoveries.GymWeights.Id,
		Constants.Discoveries.GymWaterStation.Id,
		Constants.Discoveries.GymNoTouch.Id,
	},
	TopDownArena = {
		Constants.Discoveries.TopDownEntered.Id,
		Constants.Discoveries.TopDownCamera.Id,
		Constants.Discoveries.TopDownWaterBalloon.Id,
		Constants.Discoveries.TopDownRingScore.Id,
		Constants.Discoveries.TopDownPlayerSplash.Id,
		Constants.Discoveries.TopDownBucketRefill.Id,
		Constants.Discoveries.TopDownScoreboard.Id,
		Constants.Discoveries.TopDownNoTouch.Id,
	},
	TVRoom = {
		Constants.Discoveries.PressedButton.Id,
		Constants.Discoveries.LowGravity.Id,
		Constants.Discoveries.TinyPlayers.Id,
		Constants.Discoveries.GiantPlayer.Id,
		Constants.Discoveries.ObjectRain.Id,
		Constants.Discoveries.DelayedSurprise.Id,
		Constants.Discoveries.EscapedUnderfloor.Id,
		Constants.Discoveries.RanAppliance.Id,
		Constants.Discoveries.RodeCouch.Id,
		Constants.Discoveries.AnnoyedLamp.Id,
		Constants.Discoveries.OverSquished.Id,
		Constants.Discoveries.AngeredTelevision.Id,
		Constants.Discoveries.TVRoomNoTouch.Id,
	},
	SnackLab = {
		Constants.Discoveries.PressedSnackButton.Id,
		Constants.Discoveries.OpenedFridge.Id,
		Constants.Discoveries.FridgePizza.Id,
		Constants.Discoveries.FridgeBloxyCola.Id,
		Constants.Discoveries.SecretFridgeButton.Id,
		Constants.Discoveries.SuspiciousToast.Id,
		Constants.Discoveries.AngrySink.Id,
		Constants.Discoveries.MixedCloud.Id,
		Constants.Discoveries.SnackRack.Id,
		Constants.Discoveries.SnackDonut.Id,
		Constants.Discoveries.SnackPopcorn.Id,
		Constants.Discoveries.HeardSnackSound.Id,
		Constants.Discoveries.AllSnackSounds.Id,
		Constants.Discoveries.LivingFruit.Id,
		Constants.Discoveries.SnackLabNoTouch.Id,
	},
	Island = {
		Constants.Discoveries.ReachedIsland.Id,
		Constants.Discoveries.SharkBounce.Id,
		Constants.Discoveries.ReadSharkWarning.Id,
		Constants.Discoveries.ReadJellyfishWarning.Id,
		Constants.Discoveries.DugTreasure.Id,
		Constants.Discoveries.OpenedTreasure.Id,
		Constants.Discoveries.IslandBloxyCola.Id,
		Constants.Discoveries.IslandCoconutCrab.Id,
		Constants.Discoveries.IslandDroppedCoconut.Id,
		Constants.Discoveries.IslandDriftwood.Id,
		Constants.Discoveries.IslandCollectedRock.Id,
		Constants.Discoveries.IslandCampfire.Id,
		Constants.Discoveries.IslandSeagulls.Id,
		Constants.Discoveries.IslandNoTouch.Id,
	},
	SpaceStation = {
		Constants.Discoveries.SpaceStationAirlock.Id,
		Constants.Discoveries.SpaceStationGravityDial.Id,
		Constants.Discoveries.SpaceStationObservationWindow.Id,
		Constants.Discoveries.SpaceStationCommsPanel.Id,
		Constants.Discoveries.SpaceStationFoodPrinter.Id,
		Constants.Discoveries.SpaceStationSuit.Id,
		Constants.Discoveries.SpaceStationStarMap.Id,
		Constants.Discoveries.SpaceStationPlantPod.Id,
		Constants.Discoveries.SpaceStationMeteorButton.Id,
		Constants.Discoveries.SpaceStationEscapePod.Id,
		Constants.Discoveries.SpaceStationNoTouch.Id,
	},
	Library = {
		Constants.Discoveries.LibraryEntered.Id,
		Constants.Discoveries.LibraryForbiddenBook.Id,
		Constants.Discoveries.LibraryShushedShelf.Id,
		Constants.Discoveries.LibraryBookStorm.Id,
		Constants.Discoveries.LibraryLamp.Id,
		Constants.Discoveries.LibraryGlobe.Id,
		Constants.Discoveries.LibraryCatalog.Id,
		Constants.Discoveries.LibraryLadder.Id,
		Constants.Discoveries.LibraryLoft.Id,
		Constants.Discoveries.LibraryTeleportKey.Id,
		Constants.Discoveries.LibraryBowlingKey.Id,
		Constants.Discoveries.LibraryBookcaseDoor.Id,
		Constants.Discoveries.LibraryNoTouch.Id,
	},
	BowlingAlley = {
		Constants.Discoveries.BowlingEntered.Id,
		Constants.Discoveries.BowlingFirstBall.Id,
		Constants.Discoveries.BowlingPinsHit.Id,
		Constants.Discoveries.BowlingStrike.Id,
		Constants.Discoveries.BowlingGutter.Id,
		Constants.Discoveries.BowlingCosmic.Id,
		Constants.Discoveries.BowlingDiscoBall.Id,
		Constants.Discoveries.BowlingMaintenance.Id,
		Constants.Discoveries.BowlingResetLever.Id,
		Constants.Discoveries.BowlingShoes.Id,
		Constants.Discoveries.BowlingScoreboard.Id,
		Constants.Discoveries.BowlingBallReturn.Id,
		Constants.Discoveries.BowlingNoTouch.Id,
	},
	TreetopZipline = {
		Constants.Discoveries.TreetopZiplineEntered.Id,
	},
	Void = {
		Constants.Discoveries.VoidEntered.Id,
		Constants.Discoveries.VoidReverseControls.Id,
		Constants.Discoveries.VoidGravityFlip.Id,
		Constants.Discoveries.VoidEcho.Id,
		Constants.Discoveries.VoidFreezeRay.Id,
		Constants.Discoveries.VoidNoTouch.Id,
	},
}

Constants.SecretDiscoveries = {
	[Constants.Discoveries.RainBasement.Id] = {
		RoomId = "TVRoom",
		PrizeHints = 5,
		PrizeMessage = "Secret prize: +5 hints for relocating the rain.",
		PrizeSecretKeyRoomId = "TVRoom",
		PrizeSecretKeyMessage = "Secret prize: Library Key added to your inventory.",
	},
}

Constants.SecretDoors = {
	TVRoom = {
		Id = "tv_room_secret_door",
		RoomId = "TVRoom",
		Name = "Library",
		KeyId = "tv_secret_key",
		KeyName = "Library Key",
		EntryDiscoveryId = Constants.Discoveries.LibraryEntered.Id,
		AutoGrantOnComplete = true,
		AutoGrantMessage = "TV Room complete: Library Key added to your inventory.",
		RevealHintCost = 5,
		RevealRobux = 5,
		RevealProductId = 0,
	},
}

Constants.SecretDiscoveryOrderByRoom = {
	TVRoom = {
		Constants.Discoveries.RainBasement.Id,
	},
}

Constants.RoomCompletionOrder = {
	TVRoom = {
		Constants.Discoveries.PressedButton.Id,
		Constants.Discoveries.RanAppliance.Id,
		Constants.Discoveries.RodeCouch.Id,
		Constants.Discoveries.AnnoyedLamp.Id,
		Constants.Discoveries.OverSquished.Id,
		Constants.Discoveries.AngeredTelevision.Id,
	},
}

Constants.RoomOrder = {
	"TVRoom",
	"CaveEntrance",
	"SecurityRoom",
	"SleepingQuarters",
	"Infirmary",
	"Gym",
	"TopDownArena",
	"SnackLab",
	"Island",
}

Constants.DiscoveryRoomOrder = {
	"CaveEntrance",
	"SecurityRoom",
	"SleepingQuarters",
	"Infirmary",
	"Gym",
	"TopDownArena",
	"TVRoom",
	"SnackLab",
	"Island",
	"Library",
	"BowlingAlley",
	"TreetopZipline",
	"Void",
	"SpaceStation",
}

Constants.RoomDetectionOrder = {
	"SecurityRoom",
	"SleepingQuarters",
	"Infirmary",
	"Gym",
	"TopDownArena",
	"Library",
	"TVRoom",
	"SnackLab",
	"Island",
	"TreetopZipline",
	"BowlingAlley",
	"Void",
	"SpaceStation",
	"CaveEntrance",
}

Constants.RoomResumeDiscoveries = {
	CaveEntrance = Constants.Discoveries.CaveEntered.Id,
	SecurityRoom = Constants.Discoveries.SecurityEntered.Id,
	SleepingQuarters = Constants.Discoveries.SleepingEntered.Id,
	Infirmary = Constants.Discoveries.InfirmaryEntered.Id,
	Gym = Constants.Discoveries.GymEntered.Id,
	TopDownArena = Constants.Discoveries.TopDownEntered.Id,
	Library = Constants.Discoveries.LibraryEntered.Id,
	BowlingAlley = Constants.Discoveries.BowlingEntered.Id,
	TreetopZipline = Constants.Discoveries.TreetopZiplineEntered.Id,
	Void = Constants.Discoveries.VoidEntered.Id,
	SpaceStation = Constants.Discoveries.SpaceStationEntered.Id,
}

Constants.Rooms = {
	CaveEntrance = {
		Id = "CaveEntrance",
		Name = "Cave Entrance",
		DiscoveryOrder = Constants.RoomDiscoveryOrder.CaveEntrance,
		SpawnCFrame = CFrame.new(Vector3.new(-56.5, 5.2, 45), Vector3.new(-46.8, 5.2, 45)),
		Zone = {
			Min = Vector3.new(-155, -28, -155),
			Max = Vector3.new(-10, 18, 70),
		},
	},
	SecurityRoom = {
		Id = "SecurityRoom",
		Name = "Security",
		DiscoveryOrder = Constants.RoomDiscoveryOrder.SecurityRoom,
		SpawnCFrame = CFrame.new(Vector3.new(82, 3, -15), Vector3.new(82, 3, -44)),
		Zone = {
			Min = Vector3.new(56, -3, -48),
			Max = Vector3.new(108, 22, -8),
		},
	},
	SleepingQuarters = {
		Id = "SleepingQuarters",
		Name = "Sleeping Quarters",
		DiscoveryOrder = Constants.RoomDiscoveryOrder.SleepingQuarters,
		NoTouchDiscoveryId = Constants.Discoveries.SleepingNoTouch.Id,
		SpawnCFrame = CFrame.new(Vector3.new(82, 4.2, -58), Vector3.new(82, 4.2, -122)),
		Zone = {
			Min = Vector3.new(48, -3, -331),
			Max = Vector3.new(116, 34, -48),
		},
	},
	Infirmary = {
		Id = "Infirmary",
		Name = "Infirmary",
		DiscoveryOrder = Constants.RoomDiscoveryOrder.Infirmary,
		NoTouchDiscoveryId = Constants.Discoveries.InfirmaryNoTouch.Id,
		SpawnCFrame = CFrame.new(Vector3.new(157, 4.2, -154), Vector3.new(180, 4.2, -154)),
		Zone = {
			Min = Vector3.new(124, -3, -181),
			Max = Vector3.new(204, 25, -122),
		},
	},
	Gym = {
		Id = "Gym",
		Name = "Gym",
		DiscoveryOrder = Constants.RoomDiscoveryOrder.Gym,
		NoTouchDiscoveryId = Constants.Discoveries.GymNoTouch.Id,
		SpawnCFrame = CFrame.new(Vector3.new(157, 10.2, -224), Vector3.new(180, 10.2, -224)),
		Zone = {
			Min = Vector3.new(124, 1, -264),
			Max = Vector3.new(206, 36, -188),
		},
	},
	TopDownArena = {
		Id = "TopDownArena",
		Name = "Training Arena",
		DiscoveryOrder = Constants.RoomDiscoveryOrder.TopDownArena,
		NoTouchDiscoveryId = Constants.Discoveries.TopDownNoTouch.Id,
		SpawnCFrame = CFrame.new(Vector3.new(82, 5, -382), Vector3.new(82, 5, -436)),
		Zone = {
			Min = Vector3.new(18, -3, -466),
			Max = Vector3.new(146, 44, -330),
		},
	},
	TVRoom = {
		Id = "TVRoom",
		Name = "TV Room",
		DiscoveryOrder = Constants.RoomDiscoveryOrder.TVRoom,
		NoTouchDiscoveryId = Constants.Discoveries.TVRoomNoTouch.Id,
		SpawnCFrame = CFrame.new(Vector3.new(0, 3, 11), Vector3.new(0, 3, 0)),
		Zone = {
			Min = Vector3.new(-Constants.Room.Width / 2, Constants.Room.RecoveryY - 3, -Constants.Room.Depth / 2),
			Max = Vector3.new(Constants.Room.Width / 2, Constants.Room.TVHeight + 2, Constants.Room.Depth / 2),
		},
	},
	SnackLab = {
		Id = "SnackLab",
		Name = "Snack Lab",
		DiscoveryOrder = Constants.RoomDiscoveryOrder.SnackLab,
		NoTouchDiscoveryId = Constants.Discoveries.SnackLabNoTouch.Id,
		SpawnCFrame = CFrame.new(Vector3.new(37, 3, 54), Vector3.new(48, 3, 44)),
		Zone = {
			Min = Vector3.new(48 - Constants.Room.Width / 2, -3, 44 - Constants.Room.Depth / 2),
			Max = Vector3.new(48 + Constants.Room.Width / 2, Constants.Room.Height + 2, 44 + Constants.Room.Depth / 2),
		},
	},
	Island = {
		Id = "Island",
		Name = "Island",
		DiscoveryOrder = Constants.RoomDiscoveryOrder.Island,
		NoTouchDiscoveryId = Constants.Discoveries.IslandNoTouch.Id,
		SpawnCFrame = CFrame.new(Vector3.new(0, 3, 143), Vector3.new(0, 3, 154)),
		Zone = {
			Min = Vector3.new(-55, -3, 126),
			Max = Vector3.new(55, 28, 192),
		},
	},
	SpaceStation = {
		Id = "SpaceStation",
		Name = "Space Station",
		DiscoveryOrder = Constants.RoomDiscoveryOrder.SpaceStation,
		NoTouchDiscoveryId = Constants.Discoveries.SpaceStationNoTouch.Id,
		SpawnCFrame = CFrame.new(Vector3.new(92, 84, 150), Vector3.new(92, 84, 140)),
		Zone = {
			Min = Vector3.new(66, 76, 126),
			Max = Vector3.new(118, 106, 176),
		},
	},
	Library = {
		Id = "Library",
		Name = "Library",
		DiscoveryOrder = Constants.RoomDiscoveryOrder.Library,
		NoTouchDiscoveryId = Constants.Discoveries.LibraryNoTouch.Id,
		SpawnCFrame = CFrame.new(Vector3.new(-14, 3, -29), Vector3.new(-14, 3, -45)),
		Zone = {
			Min = Vector3.new(-34, -3, -64),
			Max = Vector3.new(6, 30, -12),
		},
	},
	BowlingAlley = {
		Id = "BowlingAlley",
		Name = "Bowling Alley",
		DiscoveryOrder = Constants.RoomDiscoveryOrder.BowlingAlley,
		NoTouchDiscoveryId = Constants.Discoveries.BowlingNoTouch.Id,
		SpawnCFrame = CFrame.new(-14, 3, -84),
		Zone = {
			Min = Vector3.new(-36, -3, -252),
			Max = Vector3.new(8, 42, -80),
		},
	},
	TreetopZipline = {
		Id = "TreetopZipline",
		Name = "Treetop Zipline",
		DiscoveryOrder = Constants.RoomDiscoveryOrder.TreetopZipline,
		SpawnCFrame = CFrame.new(Vector3.new(-14, 29, -220), Vector3.new(-7, 29, -240)),
		Zone = {
			Min = Vector3.new(-40, 20, -250),
			Max = Vector3.new(12, 80, -190),
		},
	},
	Void = {
		Id = "Void",
		Name = "The Void",
		DiscoveryOrder = Constants.RoomDiscoveryOrder.Void,
		NoTouchDiscoveryId = Constants.Discoveries.VoidNoTouch.Id,
		SpawnCFrame = CFrame.new(Vector3.new(-92, 47, -28), Vector3.new(-92, 47, -42)),
		Zone = {
			Min = Vector3.new(-120, 32, -58),
			Max = Vector3.new(-64, 74, 2),
		},
	},
}

for _, room in pairs(Constants.Rooms) do
	if room.TesterAccessible == nil then
		room.TesterAccessible = true
	end
	if room.TesterStatePresets == nil then
		room.TesterStatePresets = {
			"Fresh",
			"Midway",
			"Completed",
		}
	end
end

Constants.RoomUnlockRules = {
	SecurityRoom = {
		RequiredRoomId = "SleepingQuarters",
		Fraction = Constants.Hallway.UnlockDiscoveryFraction,
	},
	TopDownArena = {
		RequiredRoomId = "SleepingQuarters",
		Fraction = Constants.Hallway.UnlockDiscoveryFraction,
	},
	SnackLab = {
		RequiredRoomId = "TVRoom",
		Fraction = Constants.Hallway.UnlockDiscoveryFraction,
	},
	Island = {
		RequiredRoomId = "SnackLab",
		Fraction = Constants.Hallway.UnlockDiscoveryFraction,
	},
}

Constants.DiscoveryHighlightTargets = {
	[Constants.Discoveries.PressedButton.Id] = Constants.Tags.MainButton,
	[Constants.Discoveries.LowGravity.Id] = Constants.Tags.FloorSection,
	[Constants.Discoveries.TinyPlayers.Id] = Constants.Tags.MainButton,
	[Constants.Discoveries.GiantPlayer.Id] = Constants.Tags.TVLightSwitch,
	[Constants.Discoveries.ObjectRain.Id] = Constants.Tags.MainButton,
	[Constants.Discoveries.DelayedSurprise.Id] = Constants.Tags.MainButton,
	[Constants.Discoveries.EscapedUnderfloor.Id] = Constants.Tags.UnderfloorReturn,
	[Constants.Discoveries.RanAppliance.Id] = Constants.Tags.Appliance,
	[Constants.Discoveries.RodeCouch.Id] = Constants.Tags.Couch,
	[Constants.Discoveries.AnnoyedLamp.Id] = Constants.Tags.FloorLamp,
	[Constants.Discoveries.OverSquished.Id] = Constants.Tags.Squishy,
	[Constants.Discoveries.AngeredTelevision.Id] = Constants.Tags.Television,
	[Constants.Discoveries.PressedSnackButton.Id] = Constants.Tags.SnackButton,
	[Constants.Discoveries.OpenedFridge.Id] = Constants.Tags.SnackFridge,
	[Constants.Discoveries.FridgePizza.Id] = Constants.Tags.FridgePizza,
	[Constants.Discoveries.FridgeBloxyCola.Id] = Constants.Tags.FridgeBloxyCola,
	[Constants.Discoveries.SecretFridgeButton.Id] = Constants.Tags.SecretFridgeButton,
	[Constants.Discoveries.SuspiciousToast.Id] = Constants.Tags.SnackToaster,
	[Constants.Discoveries.AngrySink.Id] = Constants.Tags.SnackSink,
	[Constants.Discoveries.MixedCloud.Id] = Constants.Tags.SnackMixer,
	[Constants.Discoveries.SnackRack.Id] = Constants.Tags.SnackRack,
	[Constants.Discoveries.SnackDonut.Id] = Constants.Tags.SnackDonut,
	[Constants.Discoveries.SnackPopcorn.Id] = Constants.Tags.SnackPopcornMachine,
	[Constants.Discoveries.HeardSnackSound.Id] = Constants.Tags.SnackPack,
	[Constants.Discoveries.AllSnackSounds.Id] = Constants.Tags.SnackPack,
	[Constants.Discoveries.LivingFruit.Id] = Constants.Tags.FruitBowl,
	[Constants.Discoveries.ReachedIsland.Id] = Constants.Tags.IslandExit,
	[Constants.Discoveries.SharkBounce.Id] = Constants.Tags.IslandExit,
	[Constants.Discoveries.ReadSharkWarning.Id] = Constants.Tags.IslandSharkSign,
	[Constants.Discoveries.ReadJellyfishWarning.Id] = Constants.Tags.IslandJellyfishSign,
	[Constants.Discoveries.DugTreasure.Id] = Constants.Tags.IslandShovel,
	[Constants.Discoveries.OpenedTreasure.Id] = Constants.Tags.IslandTreasure,
	[Constants.Discoveries.IslandBloxyCola.Id] = Constants.Tags.IslandBloxyCola,
	[Constants.Discoveries.IslandCoconutCrab.Id] = Constants.Tags.IslandCoconut,
	[Constants.Discoveries.IslandDroppedCoconut.Id] = Constants.Tags.IslandCoconutTree,
	[Constants.Discoveries.IslandDriftwood.Id] = Constants.Tags.IslandScrapWood,
	[Constants.Discoveries.IslandCollectedRock.Id] = Constants.Tags.IslandRock,
	[Constants.Discoveries.IslandCampfire.Id] = Constants.Tags.IslandFireRing,
	[Constants.Discoveries.IslandSeagulls.Id] = Constants.Tags.IslandCoconut,
	[Constants.Discoveries.SpaceStationAirlock.Id] = Constants.Tags.SpaceStationAirlock,
	[Constants.Discoveries.SpaceStationGravityDial.Id] = Constants.Tags.SpaceStationGravityDial,
	[Constants.Discoveries.SpaceStationObservationWindow.Id] = Constants.Tags.SpaceStationObservationWindow,
	[Constants.Discoveries.SpaceStationCommsPanel.Id] = Constants.Tags.SpaceStationCommsPanel,
	[Constants.Discoveries.SpaceStationFoodPrinter.Id] = Constants.Tags.SpaceStationFoodPrinter,
	[Constants.Discoveries.SpaceStationSuit.Id] = Constants.Tags.SpaceStationSuit,
	[Constants.Discoveries.SpaceStationStarMap.Id] = Constants.Tags.SpaceStationStarMap,
	[Constants.Discoveries.SpaceStationPlantPod.Id] = Constants.Tags.SpaceStationPlantPod,
	[Constants.Discoveries.SpaceStationMeteorButton.Id] = Constants.Tags.SpaceStationMeteorButton,
	[Constants.Discoveries.SpaceStationEscapePod.Id] = Constants.Tags.SpaceStationEscapePod,
	[Constants.Discoveries.LibraryEntered.Id] = Constants.Tags.SecretRoomDoor,
	[Constants.Discoveries.LibraryForbiddenBook.Id] = Constants.Tags.LibraryBook,
	[Constants.Discoveries.LibraryShushedShelf.Id] = Constants.Tags.LibraryShelf,
	[Constants.Discoveries.LibraryBookStorm.Id] = Constants.Tags.LibraryBookStorm,
	[Constants.Discoveries.LibraryLamp.Id] = Constants.Tags.LibraryLamp,
	[Constants.Discoveries.LibraryGlobe.Id] = Constants.Tags.LibraryGlobe,
	[Constants.Discoveries.LibraryCatalog.Id] = Constants.Tags.LibraryCatalog,
	[Constants.Discoveries.LibraryLadder.Id] = Constants.Tags.LibraryLadder,
	[Constants.Discoveries.LibraryLoft.Id] = Constants.Tags.LibraryLoftDoor,
	[Constants.Discoveries.LibraryTeleportKey.Id] = Constants.Tags.LibraryTeleportKey,
	[Constants.Discoveries.LibraryBowlingKey.Id] = Constants.Tags.LibraryTopShelfKey,
	[Constants.Discoveries.LibraryBookcaseDoor.Id] = Constants.Tags.LibraryBookcaseDoor,
	[Constants.Discoveries.BowlingEntered.Id] = Constants.Tags.LibraryBookcaseDoor,
	[Constants.Discoveries.BowlingFirstBall.Id] = Constants.Tags.BowlingLaneButton,
	[Constants.Discoveries.BowlingPinsHit.Id] = Constants.Tags.BowlingPin,
	[Constants.Discoveries.BowlingStrike.Id] = Constants.Tags.BowlingPin,
	[Constants.Discoveries.BowlingGutter.Id] = Constants.Tags.BowlingGutter,
	[Constants.Discoveries.BowlingCosmic.Id] = Constants.Tags.BowlingCosmicSwitch,
	[Constants.Discoveries.BowlingDiscoBall.Id] = Constants.Tags.BowlingDiscoBall,
	[Constants.Discoveries.BowlingMaintenance.Id] = Constants.Tags.BowlingMaintenanceDoor,
	[Constants.Discoveries.BowlingResetLever.Id] = Constants.Tags.BowlingResetLever,
	[Constants.Discoveries.BowlingShoes.Id] = Constants.Tags.BowlingShoeRack,
	[Constants.Discoveries.BowlingScoreboard.Id] = Constants.Tags.BowlingScoreboard,
	[Constants.Discoveries.BowlingBallReturn.Id] = Constants.Tags.BowlingBallReturn,
	[Constants.Discoveries.TreetopZiplineEntered.Id] = Constants.Tags.SecretRoomExit,
	[Constants.Discoveries.VoidEntered.Id] = Constants.Tags.TreetopZipline,
	[Constants.Discoveries.VoidReverseControls.Id] = Constants.Tags.VoidReverseConsole,
	[Constants.Discoveries.VoidGravityFlip.Id] = Constants.Tags.VoidGravityOrb,
	[Constants.Discoveries.VoidEcho.Id] = Constants.Tags.VoidEchoButton,
	[Constants.Discoveries.VoidFreezeRay.Id] = Constants.Tags.VoidFreezeRay,
	[Constants.Discoveries.CaveEntered.Id] = Constants.Tags.CaveHallwayDoor,
	[Constants.Discoveries.CaveFirstLight.Id] = Constants.Tags.CaveLight,
	[Constants.Discoveries.CaveChangedLights.Id] = Constants.Tags.CaveLight,
	[Constants.Discoveries.CaveExitKey.Id] = Constants.Tags.CaveExitKey,
	[Constants.Discoveries.CaveOpenedDoor.Id] = Constants.Tags.CaveKeyDoor,
	[Constants.Discoveries.LowerTunnelBlastDoor.Id] = Constants.Tags.LowerTunnelBlastDoor,
	[Constants.Discoveries.SecurityEntered.Id] = Constants.Tags.HallDoor,
	[Constants.Discoveries.SecurityMonitorWall.Id] = Constants.Tags.SecurityMonitor,
	[Constants.Discoveries.SecurityCameraView.Id] = Constants.Tags.SecurityMonitor,
	[Constants.Discoveries.SecurityBunkerEnergy.Id] = Constants.Tags.BunkerPowerMeter,
	[Constants.Discoveries.SecurityScreenButton.Id] = Constants.Tags.SecurityMonitor,
	[Constants.Discoveries.SecurityRedPhone.Id] = Constants.Tags.SecurityRedPhone,
	[Constants.Discoveries.SecurityTapeDeck.Id] = Constants.Tags.SecurityTapeDeck,
	[Constants.Discoveries.SecurityObservationMirror.Id] = Constants.Tags.ObservationMirror,
	[Constants.Discoveries.SleepingEntered.Id] = Constants.Tags.HallDoor,
	[Constants.Discoveries.SleepingCountedBunks.Id] = Constants.Tags.SleepingBunk,
	[Constants.Discoveries.SleepingAlarmClock.Id] = Constants.Tags.SleepingAlarmClock,
	[Constants.Discoveries.SleepingLocker.Id] = Constants.Tags.SleepingLocker,
	[Constants.Discoveries.SleepingAllLockers.Id] = Constants.Tags.SleepingLocker,
	[Constants.Discoveries.SleepingDreamButton.Id] = Constants.Tags.SleepingDreamButton,
	[Constants.Discoveries.SleepingBlanketFort.Id] = Constants.Tags.SleepingBlanketFort,
	[Constants.Discoveries.SleepingPillowPile.Id] = Constants.Tags.SleepingPillowPile,
	[Constants.Discoveries.SleepingIdBadge.Id] = Constants.Tags.SleepingIdBadge,
	[Constants.Discoveries.InfirmaryEntered.Id] = Constants.Tags.InfirmaryRecoveryBed,
	[Constants.Discoveries.InfirmaryRecoveryBed.Id] = Constants.Tags.InfirmaryRecoveryBed,
	[Constants.Discoveries.InfirmaryMonitor.Id] = Constants.Tags.InfirmaryMonitor,
	[Constants.Discoveries.InfirmaryCabinet.Id] = Constants.Tags.InfirmaryCabinet,
	[Constants.Discoveries.InfirmaryNourishment.Id] = Constants.Tags.InfirmaryNourishment,
	[Constants.Discoveries.GymEntered.Id] = Constants.Tags.GymTreadmill,
	[Constants.Discoveries.GymTreadmill.Id] = Constants.Tags.GymTreadmill,
	[Constants.Discoveries.GymBike.Id] = Constants.Tags.GymBike,
	[Constants.Discoveries.GymWeights.Id] = Constants.Tags.GymWeights,
	[Constants.Discoveries.GymWaterStation.Id] = Constants.Tags.GymWaterStation,
	[Constants.Discoveries.TopDownEntered.Id] = Constants.Tags.HallDoor,
	[Constants.Discoveries.TopDownCamera.Id] = Constants.Tags.TopDownCameraConsole,
	[Constants.Discoveries.TopDownWaterBalloon.Id] = Constants.Tags.TopDownWaterBalloonBucket,
	[Constants.Discoveries.TopDownRingScore.Id] = Constants.Tags.TopDownTargetRing,
	[Constants.Discoveries.TopDownPlayerSplash.Id] = Constants.Tags.TopDownSplashTarget,
	[Constants.Discoveries.TopDownBucketRefill.Id] = Constants.Tags.TopDownWaterBalloonBucket,
	[Constants.Discoveries.TopDownScoreboard.Id] = Constants.Tags.TopDownScoreboard,
}

Constants.NoTouch = {
	AccomplishmentSeconds = 120,
	BonusSeconds = 900,
	BonusHintCount = 10,
	HintPackSize = 10,
	HintPackRobux = 1,
	HintPackProductId = 0,
	PaidHintRobux = 1,
	PaidHintProductId = 0,
	FullRevealRobux = 3,
	FullRevealHintCost = 3,
	FullRevealProductId = 0,
	ClueHintCost = 5,
	ClueRobux = 1,
	ClueProductId = 0,
	RevealClueCost = 3,
	RevealRobux = 3,
	RevealProductId = 0,
	SecretKeyClueCost = 3,
	TeleportKeyClueCost = 3,
	TeleportKeyRobux = 5,
	DuckFounderRobux = 80000,
	DuckFounderProductId = 0,
	VictoryBrickRobux = 8000,
	VictoryBrickProductId = 0,
}

Constants.DiscoveryOrder = {}

for _, roomId in ipairs(Constants.DiscoveryRoomOrder or Constants.RoomOrder) do
	for _, discoveryId in ipairs(Constants.RoomDiscoveryOrder[roomId]) do
		table.insert(Constants.DiscoveryOrder, discoveryId)
	end
end

Constants.TotalDiscoveries = #Constants.DiscoveryOrder

local discoveryById = {}

for _, discovery in pairs(Constants.Discoveries) do
	discoveryById[discovery.Id] = discovery
end

function Constants.GetDiscovery(discoveryId)
	return discoveryById[discoveryId]
end

function Constants.GetRoom(roomId)
	return Constants.Rooms[roomId]
end

function Constants.GetNamedPlace(placeId)
	return Constants.NamedPlaces[placeId]
end

function Constants.GetRoomUnlockRequirement(roomId)
	local rule = Constants.RoomUnlockRules[roomId]
	if not rule then
		return nil
	end

	local requiredRoom = Constants.GetRoom(rule.RequiredRoomId)
	if not requiredRoom then
		return nil
	end

	return rule.RequiredRoomId, math.ceil(#requiredRoom.DiscoveryOrder * rule.Fraction)
end

function Constants.GetRoomSpawnCFrame(roomId)
	local room = Constants.GetRoom(roomId)
	if room and room.SpawnCFrame then
		return room.SpawnCFrame
	end

	return Constants.Rooms.TVRoom.SpawnCFrame
end

function Constants.GetNamedPlaceCFrame(placeId)
	local place = Constants.NamedPlaces[placeId]
	if place and place.SpawnCFrame then
		return place.SpawnCFrame
	end

	return Constants.Hallway.SpawnCFrame
end

return Constants
