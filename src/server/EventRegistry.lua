local Events = script.Parent:WaitForChild("Events")

return {
	require(Events:WaitForChild("LowGravity")),
	require(Events:WaitForChild("TinyPlayers")),
	require(Events:WaitForChild("GiantPlayer")),
	require(Events:WaitForChild("ObjectRain")),
	require(Events:WaitForChild("FloorGone")),
	require(Events:WaitForChild("ButtonRunsAway")),
	require(Events:WaitForChild("FakeEvent")),
}
