local Constants = {}

Constants.NormalGravity = 196.2
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
}

Constants.Tags = {
	MainButton = "DontTouchIt_MainButton",
	LightSwitch = "DontTouchIt_LightSwitch",
	Couch = "DontTouchIt_Couch",
	FloorLamp = "DontTouchIt_FloorLamp",
	Squishy = "DontTouchIt_Squishy",
	Television = "DontTouchIt_Television",
	Appliance = "DontTouchIt_Appliance",
	ExitDoor = "DontTouchIt_ExitDoor",
	HallDoor = "DontTouchIt_HallDoor",
	ReferenceBook = "DontTouchIt_ReferenceBook",
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
	FridgePizza = "DontTouchIt_FridgePizza",
	FridgeBloxyCola = "DontTouchIt_FridgeBloxyCola",
	SecretFridgeButton = "DontTouchIt_SecretFridgeButton",
	IslandExit = "DontTouchIt_IslandExit",
	IslandShovel = "DontTouchIt_IslandShovel",
	IslandTreasure = "DontTouchIt_IslandTreasure",
	IslandBloxyCola = "DontTouchIt_IslandBloxyCola",
	FloorSection = "DontTouchIt_FloorSection",
	ObjectRainObject = "DontTouchIt_ObjectRainObject",
	TemporaryObject = "DontTouchIt_TemporaryObject",
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
	AutosaveSeconds = 45,
	RetryCount = 3,
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
	HintsPerInterval = 1,
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
		Name = "Met the Door Shark",
		Hint = "Try to leave the island before finding enough island discoveries.",
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
	IslandNoTouch = {
		Id = "island_no_touch",
		Name = "Left the Island Alone",
		Hint = "Stand on the island for two minutes without interacting with anything.",
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
		Constants.Discoveries.DugTreasure.Id,
		Constants.Discoveries.OpenedTreasure.Id,
		Constants.Discoveries.IslandBloxyCola.Id,
		Constants.Discoveries.IslandNoTouch.Id,
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
		SpawnCFrame = CFrame.new(0, 3, 132),
		Zone = {
			Min = Vector3.new(-55, -3, 126),
			Max = Vector3.new(55, 28, 192),
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
	[Constants.Discoveries.GiantPlayer.Id] = Constants.Tags.LightSwitch,
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
	[Constants.Discoveries.DugTreasure.Id] = Constants.Tags.IslandShovel,
	[Constants.Discoveries.OpenedTreasure.Id] = Constants.Tags.IslandTreasure,
	[Constants.Discoveries.IslandBloxyCola.Id] = Constants.Tags.IslandBloxyCola,
}

Constants.NoTouch = {
	AccomplishmentSeconds = 120,
	BonusSeconds = 900,
	BonusHintCount = 10,
	HintPackSize = 10,
	HintPackRobux = 1,
	HintPackProductId = 0,
}

Constants.DiscoveryOrder = {}

for _, roomId in ipairs(Constants.RoomOrder) do
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
