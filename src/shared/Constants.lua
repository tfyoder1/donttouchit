local Constants = {}

Constants.BuildVersion = "0.5.44"
Constants.GameIntro = "Feel free to look around. Just don't touch anything... especially the things that look like buttons."
Constants.NormalGravity = 196.2
Constants.SpaceStationGravity = 24
Constants.EventDuration = 10
Constants.EventCooldown = 2.5

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
	IslandFireRing = "DontTouchIt_IslandFireRing",
	IslandHiddenSkyBlock = "DontTouchIt_IslandHiddenSkyBlock",
	IslandSpaceLadder = "DontTouchIt_IslandSpaceLadder",
	FloorSection = "DontTouchIt_FloorSection",
	ObjectRainObject = "DontTouchIt_ObjectRainObject",
	TemporaryObject = "DontTouchIt_TemporaryObject",
	LibraryBook = "DontTouchIt_LibraryBook",
	LibraryShelf = "DontTouchIt_LibraryShelf",
	LibraryLamp = "DontTouchIt_LibraryLamp",
	LibraryGlobe = "DontTouchIt_LibraryGlobe",
	LibraryCatalog = "DontTouchIt_LibraryCatalog",
	LibraryLadder = "DontTouchIt_LibraryLadder",
	LibraryLoftDoor = "DontTouchIt_LibraryLoftDoor",
	LibraryTopShelfKey = "DontTouchIt_LibraryTopShelfKey",
	LibraryBookcaseDoor = "DontTouchIt_LibraryBookcaseDoor",
	BowlingLaneButton = "DontTouchIt_BowlingLaneButton",
	BowlingPin = "DontTouchIt_BowlingPin",
	BowlingCosmicSwitch = "DontTouchIt_BowlingCosmicSwitch",
	BowlingDiscoBall = "DontTouchIt_BowlingDiscoBall",
	BowlingMaintenanceDoor = "DontTouchIt_BowlingMaintenanceDoor",
	BowlingResetLever = "DontTouchIt_BowlingResetLever",
	BowlingShoeRack = "DontTouchIt_BowlingShoeRack",
	BowlingScoreboard = "DontTouchIt_BowlingScoreboard",
	BowlingGutter = "DontTouchIt_BowlingGutter",
	BowlingBallReturn = "DontTouchIt_BowlingBallReturn",
	TreetopZipline = "DontTouchIt_TreetopZipline",
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
}

Constants.Hallway = {
	Id = "Hallway",
	Name = "Hallway",
	UnlockedRoomCount = 1,
	TotalRoomCount = 4,
	UnlockDiscoveryFraction = 0.5,
	Zone = {
		Min = Vector3.new(-7.75, -3, Constants.Room.Depth / 2 - 0.5),
		Max = Vector3.new(7.75, 13, 124),
	},
	SpawnCFrame = CFrame.new(0, 3, 27),
}

Constants.DataStore = {
	Name = "DontTouchItPrototype_v1",
	FeedbackName = "DontTouchItFeedback_v1",
	AutosaveSeconds = 45,
	RetryCount = 3,
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

Constants.RoomPlay = {
	HintIntervalSeconds = 300,
	HintsPerInterval = 5,
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
		Hint = "The red button has a reliable bad idea every eighth accepted press.",
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
		Name = "Started the Tiny Appliance",
		Hint = "The timer on the table is not just decoration.",
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
}

Constants.RoomDiscoveryOrder = {
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
		Constants.Discoveries.LibraryLamp.Id,
		Constants.Discoveries.LibraryGlobe.Id,
		Constants.Discoveries.LibraryCatalog.Id,
		Constants.Discoveries.LibraryLadder.Id,
		Constants.Discoveries.LibraryLoft.Id,
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
	"SnackLab",
	"Island",
}

Constants.DiscoveryRoomOrder = {
	"TVRoom",
	"SnackLab",
	"Island",
	"Library",
	"BowlingAlley",
	"SpaceStation",
}

Constants.RoomResumeDiscoveries = {
	Library = Constants.Discoveries.LibraryEntered.Id,
	BowlingAlley = Constants.Discoveries.BowlingEntered.Id,
	SpaceStation = Constants.Discoveries.SpaceStationEntered.Id,
}

Constants.Rooms = {
	TVRoom = {
		Id = "TVRoom",
		Name = "TV Room",
		DiscoveryOrder = Constants.RoomDiscoveryOrder.TVRoom,
		NoTouchDiscoveryId = Constants.Discoveries.TVRoomNoTouch.Id,
		SpawnCFrame = CFrame.new(0, 3, 11),
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
		SpawnCFrame = CFrame.new(37, 3, 54),
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
		SpawnCFrame = CFrame.new(Vector3.new(92, 83, 164), Vector3.new(92, 83, 150)),
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
			Max = Vector3.new(6, 30, -26),
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
}

Constants.RoomUnlockRules = {
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
	[Constants.Discoveries.LibraryLamp.Id] = Constants.Tags.LibraryLamp,
	[Constants.Discoveries.LibraryGlobe.Id] = Constants.Tags.LibraryGlobe,
	[Constants.Discoveries.LibraryCatalog.Id] = Constants.Tags.LibraryCatalog,
	[Constants.Discoveries.LibraryLadder.Id] = Constants.Tags.LibraryLadder,
	[Constants.Discoveries.LibraryLoft.Id] = Constants.Tags.LibraryLoftDoor,
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

return Constants
