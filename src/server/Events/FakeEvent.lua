local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

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

local function makeTemporaryPart(folder, name, size, cframe, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.Neon
	part.Parent = folder
	CollectionService:AddTag(part, Constants.Tags.TemporaryObject)
	return part
end

local function spawnGlowRing(folder, name, cframe, color, targetSize, delaySeconds)
	task.delay(delaySeconds or 0, function()
		if not folder.Parent then
			return
		end

		local ring = makeTemporaryPart(folder, name, Vector3.new(1, 0.08, 1), cframe, color, Enum.Material.Neon)
		ring.Anchored = true
		ring.Shape = Enum.PartType.Cylinder
		ring.Transparency = 0.35
		local tween = TweenService:Create(
			ring,
			TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Size = targetSize,
				Transparency = 1,
			}
		)
		tween:Play()
		Debris:AddItem(ring, 1.1)
	end)
end

local function spawnConfetti()
	local folder = Instance.new("Folder")
	folder.Name = "TemporaryDelayedSurpriseConfetti"
	folder.Parent = workspace
	CollectionService:AddTag(folder, Constants.Tags.TemporaryObject)

	local random = Random.new()
	local roomCenter = Vector3.new(0, Constants.Room.TVHeight * 0.45, 0)
	local corners = {
		Vector3.new(-Constants.Room.Width / 2 + 2, Constants.Room.TVHeight - 5, -Constants.Room.Depth / 2 + 2),
		Vector3.new(Constants.Room.Width / 2 - 2, Constants.Room.TVHeight - 5, -Constants.Room.Depth / 2 + 2),
		Vector3.new(-Constants.Room.Width / 2 + 2, Constants.Room.TVHeight - 5, Constants.Room.Depth / 2 - 2),
		Vector3.new(Constants.Room.Width / 2 - 2, Constants.Room.TVHeight - 5, Constants.Room.Depth / 2 - 2),
	}

	spawnGlowRing(folder, "SurpriseFloorGlow", CFrame.new(0, 0.18, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(102, 255, 166), Vector3.new(0.08, 42, 42), 0)
	spawnGlowRing(folder, "SurpriseCeilingGlow", CFrame.new(0, Constants.Room.TVHeight - 1, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(218, 108, 255), Vector3.new(0.08, 34, 34), 0.18)
	spawnGlowRing(folder, "SurpriseSecondFloorGlow", CFrame.new(0, 0.22, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(84, 180, 255), Vector3.new(0.08, 56, 56), 0.28)

	for _, corner in ipairs(corners) do
		local directionToCenter = (roomCenter - corner).Unit
		for index = 1, 14 do
			local color = CONFETTI_COLORS[((index - 1) % #CONFETTI_COLORS) + 1]
			local streamer = makeTemporaryPart(
				folder,
				"CornerStreamer",
				Vector3.new(random:NextNumber(0.12, 0.22), 0.08, random:NextNumber(1.4, 2.6)),
				CFrame.new(corner + directionToCenter * (index * 0.12)) * CFrame.Angles(
					random:NextNumber(0, math.pi),
					random:NextNumber(0, math.pi),
					random:NextNumber(0, math.pi)
				),
				color,
				Enum.Material.Neon
			)
			streamer.AssemblyLinearVelocity = directionToCenter * random:NextNumber(30, 46)
				+ Vector3.new(0, random:NextNumber(14, 28), 0)
			streamer.AssemblyAngularVelocity = Vector3.new(
				random:NextNumber(-9, 9),
				random:NextNumber(-14, 14),
				random:NextNumber(-9, 9)
			)
			Debris:AddItem(streamer, random:NextNumber(7, Constants.Confetti.DurationSeconds))
		end
	end

	for index = 1, 120 do
		local color = CONFETTI_COLORS[random:NextInteger(1, #CONFETTI_COLORS)]
		local spawnPosition = roomCenter + Vector3.new(
			random:NextNumber(-4, 4),
			random:NextNumber(-1.5, 1.5),
			random:NextNumber(-4, 4)
		)
		local confetti = makeTemporaryPart(
			folder,
			"SurpriseConfetti",
			Vector3.new(random:NextNumber(0.12, 0.34), 0.045, random:NextNumber(0.12, 0.38)),
			CFrame.new(spawnPosition) * CFrame.Angles(
				random:NextNumber(0, math.pi),
				random:NextNumber(0, math.pi),
				random:NextNumber(0, math.pi)
			),
			color,
			Enum.Material.Neon
		)
		local radial = Vector3.new(random:NextNumber(-1, 1), random:NextNumber(0.35, 1), random:NextNumber(-1, 1)).Unit
		confetti.AssemblyLinearVelocity = radial * random:NextNumber(20, 48) + Vector3.new(0, random:NextNumber(18, 36), 0)
		confetti.AssemblyAngularVelocity = Vector3.new(
			random:NextNumber(-18, 18),
			random:NextNumber(-18, 18),
			random:NextNumber(-18, 18)
		)
		Debris:AddItem(confetti, random:NextNumber(6, Constants.Confetti.DurationSeconds))
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
