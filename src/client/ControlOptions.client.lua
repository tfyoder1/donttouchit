local TouchControls = require(script.Parent:WaitForChild("TouchControls"))

TouchControls.RegisterInfo({
	Id = "Move",
	Label = "Move",
	Order = 1,
	Desktop = "WASD / arrows",
	Xbox = "Left stick",
	Touch = "Thumbstick",
})

TouchControls.RegisterInfo({
	Id = "Camera",
	Label = "Camera",
	Order = 2,
	Desktop = "Mouse",
	Xbox = "Right stick",
	Touch = "Drag screen",
})

TouchControls.RegisterInfo({
	Id = "Jump",
	Label = "Jump",
	Order = 3,
	Desktop = "Space",
	Xbox = "A",
	Touch = "Jump",
})

TouchControls.RegisterInfo({
	Id = "Interact",
	Label = "Interact",
	Order = 4,
	Desktop = "E",
	Xbox = "X",
	Touch = "Tap prompt",
})

TouchControls.StartOptionsPanel()
