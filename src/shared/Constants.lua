local Constants = {}

Constants.NormalGravity = 196.2
Constants.EventDuration = 10
Constants.EventCooldown = 2.5

Constants.Room = {
	Width = 42,
	Depth = 34,
	Height = 16,
	FloorY = 0,
	RecoveryY = -18,
}

Constants.Remotes = {
	DiscoveryUpdate = "DiscoveryUpdate",
	ReferenceBook = "ReferenceBook",
	HintPackRequest = "HintPackRequest",
	SystemMessage = "SystemMessage",
}

Constants.Tags = {
	MainButton = "DontTouchIt_MainButton",
	Couch = "DontTouchIt_Couch",
	FloorLamp = "DontTouchIt_FloorLamp",
	Squishy = "DontTouchIt_Squishy",
	Television = "DontTouchIt_Television",
	Appliance = "DontTouchIt_Appliance",
	ExitDoor = "DontTouchIt_ExitDoor",
	HallDoor = "DontTouchIt_HallDoor",
	ReferenceBook = "DontTouchIt_ReferenceBook",
	UnderfloorReturn = "DontTouchIt_UnderfloorReturn",
	SnackButton = "DontTouchIt_SnackButton",
	SnackFridge = "DontTouchIt_SnackFridge",
	SnackToaster = "DontTouchIt_SnackToaster",
	SnackSink = "DontTouchIt_SnackSink",
	SnackMixer = "DontTouchIt_SnackMixer",
	SnackRack = "DontTouchIt_SnackRack",
	FruitBowl = "DontTouchIt_FruitBowl",
	FloorSection = "DontTouchIt_FloorSection",
	TemporaryObject = "DontTouchIt_TemporaryObject",
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
		Hint = "Keep testing the red button until gravity loses the argument.",
	},
	TinyPlayers = {
		Id = "tiny_players",
		Name = "Became Tiny",
		Hint = "The red button can make everyone unusually small.",
	},
	GiantPlayer = {
		Id = "giant_player",
		Name = "Saw a Giant Player",
		Hint = "The red button can pick one player for a growth spurt.",
	},
	ObjectRain = {
		Id = "object_rain",
		Name = "Survived Object Rain",
		Hint = "The red button can make the ceiling drop things.",
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
		Constants.Discoveries.SuspiciousToast.Id,
		Constants.Discoveries.AngrySink.Id,
		Constants.Discoveries.MixedCloud.Id,
		Constants.Discoveries.SnackRack.Id,
		Constants.Discoveries.LivingFruit.Id,
		Constants.Discoveries.SnackLabNoTouch.Id,
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
}

Constants.Rooms = {
	TVRoom = {
		Id = "TVRoom",
		Name = "TV Room",
		DiscoveryOrder = Constants.RoomDiscoveryOrder.TVRoom,
		NoTouchDiscoveryId = Constants.Discoveries.TVRoomNoTouch.Id,
		Zone = {
			Min = Vector3.new(-Constants.Room.Width / 2, Constants.Room.RecoveryY - 3, -Constants.Room.Depth / 2),
			Max = Vector3.new(Constants.Room.Width / 2, Constants.Room.Height + 2, Constants.Room.Depth / 2),
		},
	},
	SnackLab = {
		Id = "SnackLab",
		Name = "Snack Lab",
		DiscoveryOrder = Constants.RoomDiscoveryOrder.SnackLab,
		NoTouchDiscoveryId = Constants.Discoveries.SnackLabNoTouch.Id,
		Zone = {
			Min = Vector3.new(48 - Constants.Room.Width / 2, -3, 44 - Constants.Room.Depth / 2),
			Max = Vector3.new(48 + Constants.Room.Width / 2, Constants.Room.Height + 2, 44 + Constants.Room.Depth / 2),
		},
	},
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

return Constants
