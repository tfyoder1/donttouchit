local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local CONFETTI_COLORS = {
	Color3.fromRGB(255, 84, 84),
	Color3.fromRGB(255, 221, 84),
	Color3.fromRGB(84, 180, 255),
	Color3.fromRGB(102, 255, 166),
	Color3.fromRGB(218, 108, 255),
}

local function playSound(position, soundId, volume, playbackSpeed)
	local speaker = Instance.new("Part")
	speaker.Name = "TemporaryPartySound"
	speaker.Anchored = true
	speaker.CanCollide = false
	speaker.Transparency = 1
	speaker.Size = Vector3.new(1, 1, 1)
	speaker.CFrame = CFrame.new(position)
	speaker.Parent = workspace
	CollectionService:AddTag(speaker, Constants.Tags.TemporaryObject)

	local sound = Instance.new("Sound")
	sound.Name = "PartySound"
	sound.SoundId = soundId
	sound.Volume = volume or 0.8
	sound.PlaybackSpeed = playbackSpeed or 1
	sound.RollOffMaxDistance = 70
	sound.Parent = speaker
	sound:Play()

	Debris:AddItem(speaker, 3)
end

local function spawnConfetti()
	local folder = Instance.new("Folder")
	folder.Name = "TemporaryCornerConfetti"
	folder.Parent = workspace
	CollectionService:AddTag(folder, Constants.Tags.TemporaryObject)

	local random = Random.new()
	local corners = {
		Vector3.new(-Constants.Room.Width / 2 + 2, Constants.Room.TVHeight - 5, -Constants.Room.Depth / 2 + 2),
		Vector3.new(Constants.Room.Width / 2 - 2, Constants.Room.TVHeight - 5, -Constants.Room.Depth / 2 + 2),
		Vector3.new(-Constants.Room.Width / 2 + 2, Constants.Room.TVHeight - 5, Constants.Room.Depth / 2 - 2),
		Vector3.new(Constants.Room.Width / 2 - 2, Constants.Room.TVHeight - 5, Constants.Room.Depth / 2 - 2),
	}

	for _, corner in ipairs(corners) do
		for _ = 1, 42 do
			local confetti = Instance.new("Part")
			confetti.Name = "CornerConfetti"
			confetti.Anchored = false
			confetti.CanCollide = false
			confetti.Size = Vector3.new(random:NextNumber(0.15, 0.42), 0.06, random:NextNumber(0.15, 0.42))
			confetti.Color = CONFETTI_COLORS[random:NextInteger(1, #CONFETTI_COLORS)]
			confetti.Material = Enum.Material.Neon
			confetti.CFrame = CFrame.new(corner) * CFrame.Angles(
				random:NextNumber(0, math.pi),
				random:NextNumber(0, math.pi),
				random:NextNumber(0, math.pi)
			)
			confetti.Parent = folder
			CollectionService:AddTag(confetti, Constants.Tags.TemporaryObject)

			local inward = (Vector3.new(0, Constants.Room.TVHeight - 2, 0) - corner).Unit
			confetti.AssemblyLinearVelocity = inward * random:NextNumber(38, 58)
				+ Vector3.new(0, random:NextNumber(28, 45), 0)
			confetti.AssemblyAngularVelocity = Vector3.new(
				random:NextNumber(-12, 12),
				random:NextNumber(-12, 12),
				random:NextNumber(-12, 12)
			)
			Debris:AddItem(confetti, Constants.Confetti.DurationSeconds)
		end
	end

	Debris:AddItem(folder, Constants.Confetti.DurationSeconds + 1)
end

local function launchPlayer(player)
	local character = player and player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")

	if not rootPart then
		return
	end

	rootPart.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity + Vector3.new(0, 80, 0)
end

return {
	Id = "fake_event",
	Name = "Fake Event",
	Weight = 1,
	StartMessage = "See? Nothing happened.",

	Run = function(context)
		for seconds = 5, 1, -1 do
			context.BroadcastMessage(("Delayed surprise in %d..."):format(seconds))
			playSound(Vector3.new(0, 6, 0), "rbxasset://sounds/electronicpingshort.wav", 0.65, 0.75 + seconds * 0.08)
			task.wait(1)
		end

		context.BroadcastMessage("Okay, one festive thing happened.")
		spawnConfetti()
		playSound(Vector3.new(0, 6, 0), "rbxasset://sounds/snap.wav", 0.95, 0.82)
		playSound(Vector3.new(-10, 5, -10), "rbxasset://sounds/electronicpingshort.wav", 0.75, 0.42)
		playSound(Vector3.new(10, 5, 10), "rbxasset://sounds/electronicpingshort.wav", 0.75, 1.75)
		Lighting.Brightness = 6
		Lighting.Ambient = Color3.fromRGB(255, 120, 220)
		task.wait(0.3)
		Lighting.Brightness = 1
		Lighting.Ambient = Color3.fromRGB(90, 220, 255)

		launchPlayer(context.TriggeringPlayer)
		context.DiscoveryService:Unlock(context.TriggeringPlayer, Constants.Discoveries.DelayedSurprise.Id)

		task.wait(math.max(1, Constants.EventDuration - 5))
	end,
}
