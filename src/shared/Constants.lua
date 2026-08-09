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
	SystemMessage = "SystemMessage",
}

Constants.Tags = {
	MainButton = "DontTouchIt_MainButton",
	Couch = "DontTouchIt_Couch",
	FloorLamp = "DontTouchIt_FloorLamp",
	Squishy = "DontTouchIt_Squishy",
	Television = "DontTouchIt_Television",
	ExitDoor = "DontTouchIt_ExitDoor",
	HallDoor = "DontTouchIt_HallDoor",
	SnackButton = "DontTouchIt_SnackButton",
	SnackFridge = "DontTouchIt_SnackFridge",
	SnackToaster = "DontTouchIt_SnackToaster",
	SnackSink = "DontTouchIt_SnackSink",
	SnackMixer = "DontTouchIt_SnackMixer",
	FloorSection = "DontTouchIt_FloorSection",
	TemporaryObject = "DontTouchIt_TemporaryObject",
}

Constants.Discoveries = {
	PressedButton = {
		Id = "pressed_button",
		Name = "Pressed The Button",
	},
	LowGravity = {
		Id = "low_gravity",
		Name = "Experienced Low Gravity",
	},
	TinyPlayers = {
		Id = "tiny_players",
		Name = "Became Tiny",
	},
	GiantPlayer = {
		Id = "giant_player",
		Name = "Saw a Giant Player",
	},
	ObjectRain = {
		Id = "object_rain",
		Name = "Survived Object Rain",
	},
	DelayedSurprise = {
		Id = "delayed_surprise",
		Name = "Found the Delayed Surprise",
	},
	RodeCouch = {
		Id = "rode_couch",
		Name = "Rode the Couch",
	},
	AnnoyedLamp = {
		Id = "annoyed_lamp",
		Name = "Annoyed the Lamp",
	},
	OverSquished = {
		Id = "over_squished",
		Name = "Over-Squished the Squishy",
	},
	AngeredTelevision = {
		Id = "angered_television",
		Name = "Angered the Television",
	},
	PressedSnackButton = {
		Id = "pressed_snack_button",
		Name = "Pressed the Snack Lab Button",
	},
	OpenedFridge = {
		Id = "opened_fridge",
		Name = "Opened the Fridge",
	},
	SuspiciousToast = {
		Id = "suspicious_toast",
		Name = "Made Suspicious Toast",
	},
	AngrySink = {
		Id = "angry_sink",
		Name = "Annoyed the Sink",
	},
	MixedCloud = {
		Id = "mixed_cloud",
		Name = "Mixed the Cloud",
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
		Constants.Discoveries.RodeCouch.Id,
		Constants.Discoveries.AnnoyedLamp.Id,
		Constants.Discoveries.OverSquished.Id,
		Constants.Discoveries.AngeredTelevision.Id,
	},
	SnackLab = {
		Constants.Discoveries.PressedSnackButton.Id,
		Constants.Discoveries.OpenedFridge.Id,
		Constants.Discoveries.SuspiciousToast.Id,
		Constants.Discoveries.AngrySink.Id,
		Constants.Discoveries.MixedCloud.Id,
	},
}

Constants.RoomCompletionOrder = {
	TVRoom = {
		Constants.Discoveries.PressedButton.Id,
		Constants.Discoveries.RodeCouch.Id,
		Constants.Discoveries.AnnoyedLamp.Id,
		Constants.Discoveries.OverSquished.Id,
		Constants.Discoveries.AngeredTelevision.Id,
	},
}

Constants.DiscoveryOrder = {
	Constants.Discoveries.PressedButton.Id,
	Constants.Discoveries.LowGravity.Id,
	Constants.Discoveries.TinyPlayers.Id,
	Constants.Discoveries.GiantPlayer.Id,
	Constants.Discoveries.ObjectRain.Id,
	Constants.Discoveries.DelayedSurprise.Id,
	Constants.Discoveries.RodeCouch.Id,
	Constants.Discoveries.AnnoyedLamp.Id,
	Constants.Discoveries.OverSquished.Id,
	Constants.Discoveries.AngeredTelevision.Id,
	Constants.Discoveries.PressedSnackButton.Id,
	Constants.Discoveries.OpenedFridge.Id,
	Constants.Discoveries.SuspiciousToast.Id,
	Constants.Discoveries.AngrySink.Id,
	Constants.Discoveries.MixedCloud.Id,
}

Constants.TotalDiscoveries = #Constants.DiscoveryOrder

local discoveryById = {}

for _, discovery in pairs(Constants.Discoveries) do
	discoveryById[discovery.Id] = discovery
end

function Constants.GetDiscovery(discoveryId)
	return discoveryById[discoveryId]
end

return Constants
