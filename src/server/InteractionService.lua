local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local RemoteService = require(script.Parent:WaitForChild("RemoteService"))

local InteractionService = {}
InteractionService.__index = InteractionService

local function getPrompt(root)
	if root:IsA("ProximityPrompt") then
		return root
	end

	if root:IsA("BasePart") then
		return root:FindFirstChildOfClass("ProximityPrompt")
	end

	return root:FindFirstChild("InteractPrompt", true)
end

local function getHumanoid(player)
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

local function getRootPart(player)
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function teleportPlayer(player, destinationCFrame)
	local rootPart = getRootPart(player)
	if not rootPart or typeof(destinationCFrame) ~= "CFrame" then
		return
	end

	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
	rootPart.CFrame = destinationCFrame
end

local function tweenPart(part, duration, properties, easingStyle, easingDirection)
	local tween = TweenService:Create(
		part,
		TweenInfo.new(duration, easingStyle or Enum.EasingStyle.Quad, easingDirection or Enum.EasingDirection.Out),
		properties
	)
	tween:Play()
	return tween
end

local function tweenModel(model, targetPivot, duration)
	local pivotValue = Instance.new("CFrameValue")
	pivotValue.Value = model:GetPivot()

	local connection = pivotValue:GetPropertyChangedSignal("Value"):Connect(function()
		if model.Parent then
			model:PivotTo(pivotValue.Value)
		end
	end)

	local tween = TweenService:Create(
		pivotValue,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		{ Value = targetPivot }
	)

	tween:Play()
	tween.Completed:Wait()
	connection:Disconnect()
	pivotValue:Destroy()
end

function InteractionService.new(eventManager, discoveryService, resetService, roomProgressService)
	local self = setmetatable({}, InteractionService)
	self.eventManager = eventManager
	self.discoveryService = discoveryService
	self.resetService = resetService
	self.roomProgressService = roomProgressService
	self.systemMessageRemote = RemoteService.GetRemote(Constants.Remotes.SystemMessage)
	self.connectedPrompts = {}
	self.couchRiding = {}
	self.lampState = {}
	self.squishyState = {}
	self.tvState = {}
	self.applianceState = {}
	self.exitUnlocked = false
	self.underfloorReturnState = {}
	self.snackButtonState = {}
	self.fridgeState = {}
	self.toasterState = {}
	self.sinkState = {}
	self.mixerState = {}
	self.snackRackState = {}
	self.fruitBowlState = {}
	return self
end

function InteractionService:Initialize()
	if self.discoveryService.DiscoveryUnlocked then
		self.discoveryService.DiscoveryUnlocked:Connect(function(player)
			self:_checkExitUnlock(player)
		end)
	end

	self:_connectTagged(Constants.Tags.MainButton, function(instance)
		self:_wireMainButton(instance)
	end)

	self:_connectTagged(Constants.Tags.Couch, function(instance)
		self:_wireCouch(instance)
	end)

	self:_connectTagged(Constants.Tags.FloorLamp, function(instance)
		self:_wireLamp(instance)
	end)

	self:_connectTagged(Constants.Tags.Squishy, function(instance)
		self:_wireSquishy(instance)
	end)

	self:_connectTagged(Constants.Tags.Television, function(instance)
		self:_wireTelevision(instance)
	end)

	self:_connectTagged(Constants.Tags.Appliance, function(instance)
		self:_wireAppliance(instance)
	end)

	self:_connectTagged(Constants.Tags.ExitDoor, function(instance)
		self:_wireExitDoor(instance)
	end)

	self:_connectTagged(Constants.Tags.HallDoor, function(instance)
		self:_wireHallDoor(instance)
	end)

	self:_connectTagged(Constants.Tags.ReferenceBook, function(instance)
		self:_wireReferenceBook(instance)
	end)

	self:_connectTagged(Constants.Tags.UnderfloorReturn, function(instance)
		self:_wireUnderfloorReturn(instance)
	end)

	self:_connectTagged(Constants.Tags.SnackButton, function(instance)
		self:_wireSnackButton(instance)
	end)

	self:_connectTagged(Constants.Tags.SnackFridge, function(instance)
		self:_wireSnackFridge(instance)
	end)

	self:_connectTagged(Constants.Tags.SnackToaster, function(instance)
		self:_wireSnackToaster(instance)
	end)

	self:_connectTagged(Constants.Tags.SnackSink, function(instance)
		self:_wireSnackSink(instance)
	end)

	self:_connectTagged(Constants.Tags.SnackMixer, function(instance)
		self:_wireSnackMixer(instance)
	end)

	self:_connectTagged(Constants.Tags.SnackRack, function(instance)
		self:_wireSnackRack(instance)
	end)

	self:_connectTagged(Constants.Tags.FruitBowl, function(instance)
		self:_wireFruitBowl(instance)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		self:_checkExitUnlock(player)
	end
end

function InteractionService:_connectTagged(tagName, wireCallback)
	for _, instance in ipairs(CollectionService:GetTagged(tagName)) do
		wireCallback(instance)
	end

	CollectionService:GetInstanceAddedSignal(tagName):Connect(wireCallback)
end

function InteractionService:_connectPrompt(prompt, callback)
	if not prompt or self.connectedPrompts[prompt] then
		return
	end

	self.connectedPrompts[prompt] = true
	prompt.Triggered:Connect(function(player)
		if self.roomProgressService then
			self.roomProgressService:RecordInteraction(player)
		end

		callback(player)
	end)
end

function InteractionService:_wireMainButton(button)
	local prompt = getPrompt(button)

	self:_connectPrompt(prompt, function(player)
		self.eventManager:TriggerRandom(player)
	end)
end

function InteractionService:_wireUnderfloorReturn(instance)
	local prompt = getPrompt(instance)

	self:_connectPrompt(prompt, function(player)
		local destinationCFrame = instance:GetAttribute("DestinationCFrame") or CFrame.new(0, 5, 10)
		self.discoveryService:Unlock(player, Constants.Discoveries.EscapedUnderfloor.Id)
		self.systemMessageRemote:FireClient(player, "The room underside sent you back upstairs.")
		teleportPlayer(player, destinationCFrame)
	end)
end

function InteractionService:_wireReferenceBook(bookPart)
	local prompt = getPrompt(bookPart)

	self:_connectPrompt(prompt, function(player)
		local roomId = bookPart:GetAttribute("RoomId") or "TVRoom"
		if self.roomProgressService then
			self.roomProgressService:ShowReferenceBook(player, roomId)
		end
	end)
end

function InteractionService:_wireAppliance(appliance)
	local prompt = getPrompt(appliance)
	local body = appliance:FindFirstChild("ApplianceBody", true)
	local door = appliance:FindFirstChild("ApplianceDoor", true)
	local textLabel = appliance:FindFirstChild("ApplianceText", true)

	self.applianceState[appliance] = self.applianceState[appliance] or {
		Reacting = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.applianceState[appliance]
		if not state or state.Reacting then
			return
		end

		state.Reacting = true
		if prompt then
			prompt.Enabled = false
		end

		self.discoveryService:Unlock(player, Constants.Discoveries.RanAppliance.Id)
		self.systemMessageRemote:FireClient(player, "The tiny appliance is reheating time.")

		for seconds = 3, 1, -1 do
			if textLabel and textLabel:IsA("TextLabel") then
				textLabel.Text = ("00:0%d"):format(seconds)
				textLabel.TextColor3 = seconds % 2 == 0 and Color3.fromRGB(255, 235, 119) or Color3.fromRGB(109, 255, 177)
			end

			if door and door:IsA("BasePart") then
				door.Color = seconds % 2 == 0 and Color3.fromRGB(58, 32, 42) or Color3.fromRGB(32, 45, 47)
			end

			task.wait(0.45)
		end

		if textLabel and textLabel:IsA("TextLabel") then
			textLabel.Text = "DING?"
			textLabel.TextColor3 = Color3.fromRGB(255, 94, 94)
		end

		if body and body:IsA("BasePart") then
			local pulseTween = tweenPart(body, 0.18, {
				Color = Color3.fromRGB(255, 214, 107),
			}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			pulseTween.Completed:Wait()
		end

		local spark = Instance.new("Part")
		spark.Name = "TinyApplianceSpark"
		spark.Anchored = true
		spark.CanCollide = false
		spark.Shape = Enum.PartType.Ball
		spark.Size = Vector3.new(0.8, 0.8, 0.8)
		spark.Color = Color3.fromRGB(109, 255, 177)
		spark.Material = Enum.Material.Neon
		spark.CFrame = (door and door.CFrame or appliance:GetPivot()) + Vector3.new(0, 1.5, -0.2)
		spark.Parent = workspace
		CollectionService:AddTag(spark, Constants.Tags.TemporaryObject)
		Debris:AddItem(spark, 2)

		task.wait(0.7)
		self.resetService.RestoreInstance(appliance)

		if prompt then
			prompt.Enabled = true
		end
		state.Reacting = false
	end)
end

function InteractionService:_wireCouch(couch)
	local prompt = getPrompt(couch)
	local seat = couch:FindFirstChild("CouchSeat", true)

	self:_connectPrompt(prompt, function(player)
		local humanoid = getHumanoid(player)
		if not humanoid or not seat or self.couchRiding[couch] then
			return
		end

		seat:Sit(humanoid)
		self.systemMessageRemote:FireClient(player, "The couch seems comfortable. Too comfortable.")

		task.delay(3, function()
			if seat.Parent and seat.Occupant == humanoid and not self.couchRiding[couch] then
				self:_rideCouch(couch, seat, player, prompt)
			end
		end)
	end)
end

function InteractionService:_rideCouch(couch, seat, player, prompt)
	self.couchRiding[couch] = true
	if prompt then
		prompt.Enabled = false
	end

	local direction = couch:GetAttribute("RideDirection") or Vector3.new(1, 0, 0)
	if direction.Magnitude < 0.1 then
		direction = Vector3.new(1, 0, 0)
	end

	local startPivot = couch:GetPivot()
	local targetPivot = startPivot + direction.Unit * 11

	self.discoveryService:Unlock(player, Constants.Discoveries.RodeCouch.Id)
	self.systemMessageRemote:FireClient(player, "The couch has entered traffic.")

	tweenModel(couch, targetPivot, 1.5)
	task.wait(1)
	tweenModel(couch, startPivot, 1.25)

	local humanoid = seat.Occupant
	if humanoid then
		humanoid.Sit = false
	end

	self.resetService.RestoreInstance(couch)
	if prompt then
		prompt.Enabled = true
	end
	self.couchRiding[couch] = nil
end

function InteractionService:_wireLamp(lamp)
	local prompt = getPrompt(lamp)
	local shade = lamp:FindFirstChild("LampShade", true)
	local light = lamp:FindFirstChild("LampLight", true)

	self.lampState[lamp] = self.lampState[lamp] or {
		ToggleCount = 0,
		Reacting = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.lampState[lamp]
		if not state or state.Reacting or not shade or not light then
			return
		end

		state.ToggleCount += 1
		light.Enabled = not light.Enabled
		shade.Material = light.Enabled and Enum.Material.Neon or Enum.Material.SmoothPlastic
		shade.Color = light.Enabled and Color3.fromRGB(255, 245, 151) or Color3.fromRGB(255, 231, 125)

		if state.ToggleCount >= 5 then
			state.ToggleCount = 0
			self:_lampSecret(lamp, shade, light, player, state)
		end
	end)
end

function InteractionService:_lampSecret(lamp, shade, light, player, state)
	state.Reacting = true
	self.discoveryService:Unlock(player, Constants.Discoveries.AnnoyedLamp.Id)
	self.systemMessageRemote:FireClient(player, "The lamp has opinions now.")

	local originalSize = shade.Size
	local originalCFrame = shade.CFrame
	local originalBrightness = light.Brightness
	local originalRange = light.Range
	local oldLighting = {
		Ambient = Lighting.Ambient,
		Brightness = Lighting.Brightness,
	}

	light.Enabled = true
	light.Brightness = 8
	light.Range = 35
	tweenPart(shade, 0.35, {
		Size = originalSize * 1.6,
		CFrame = originalCFrame + Vector3.new(0, 0.35, 0),
	}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	for index = 1, 6 do
		Lighting.Brightness = index % 2 == 0 and 1.5 or 5
		Lighting.Ambient = index % 2 == 0 and Color3.fromRGB(180, 220, 255) or Color3.fromRGB(255, 170, 90)
		task.wait(0.16)
	end

	task.wait(1)
	Lighting.Ambient = oldLighting.Ambient
	Lighting.Brightness = oldLighting.Brightness
	light.Brightness = originalBrightness
	light.Range = originalRange

	local restoreTween = tweenPart(shade, 0.35, {
		Size = originalSize,
		CFrame = originalCFrame,
	}, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	restoreTween.Completed:Wait()

	self.resetService.RestoreInstance(lamp)
	state.Reacting = false
end

function InteractionService:_wireSquishy(squishy)
	local prompt = getPrompt(squishy)

	self.squishyState[squishy] = self.squishyState[squishy] or {
		SqueezeCountByUserId = {},
		Reacting = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.squishyState[squishy]
		if not state or state.Reacting then
			return
		end

		state.Reacting = true
		if prompt then
			prompt.Enabled = false
		end

		state.SqueezeCountByUserId[player.UserId] = (state.SqueezeCountByUserId[player.UserId] or 0) + 1
		self:_squishOnce(squishy)

		if state.SqueezeCountByUserId[player.UserId] >= 10 then
			state.SqueezeCountByUserId[player.UserId] = 0
			self:_squishySecret(squishy, player)
		end

		if prompt then
			prompt.Enabled = true
		end
		state.Reacting = false
	end)
end

function InteractionService:_squishOnce(squishy)
	local originalSize = squishy:GetAttribute("BaseSize") or squishy.Size
	local originalCFrame = squishy:GetAttribute("BaseCFrame") or squishy.CFrame
	local squishedSize = Vector3.new(originalSize.X * 1.25, math.max(0.35, originalSize.Y * 0.35), originalSize.Z * 1.25)
	local yOffset = -(originalSize.Y - squishedSize.Y) / 2

	local downTween = tweenPart(squishy, 0.12, {
		Size = squishedSize,
		CFrame = originalCFrame + Vector3.new(0, yOffset, 0),
	}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	downTween.Completed:Wait()

	local upTween = tweenPart(squishy, 0.2, {
		Size = originalSize,
		CFrame = originalCFrame,
	}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	upTween.Completed:Wait()
end

function InteractionService:_squishySecret(squishy, player)
	self.discoveryService:Unlock(player, Constants.Discoveries.OverSquished.Id)
	self.systemMessageRemote:FireClient(player, "The squishy has achieved bigness.")

	local originalSize = squishy:GetAttribute("BaseSize") or squishy.Size
	local originalCFrame = squishy:GetAttribute("BaseCFrame") or squishy.CFrame
	local hugeSize = originalSize * 3.2
	local yOffset = (hugeSize.Y - originalSize.Y) / 2

	local growTween = tweenPart(squishy, 0.45, {
		Size = hugeSize,
		CFrame = originalCFrame + Vector3.new(0, yOffset, 0),
	}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	growTween.Completed:Wait()

	task.wait(3)
	self.resetService.RestoreInstance(squishy)
end

function InteractionService:_wireTelevision(tv)
	local prompt = getPrompt(tv)
	local screen = tv:FindFirstChild("TVScreen", true)
	local textLabel = tv:FindFirstChild("TVText", true)

	self.tvState[tv] = self.tvState[tv] or {
		PressCount = 0,
		Reacting = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.tvState[tv]
		if not state or state.Reacting or not screen or not textLabel then
			return
		end

		state.PressCount += 1
		self:_cycleTelevision(screen, textLabel, state.PressCount)

		if state.PressCount >= 4 then
			state.PressCount = 0
			self:_televisionSecret(tv, screen, textLabel, player, state)
		end
	end)
end

function InteractionService:_cycleTelevision(screen, textLabel, pressCount)
	local staticMessages = {
		"STATIC",
		"CHANNEL 0",
		"PLEASE STOP",
	}

	textLabel.Text = staticMessages[((pressCount - 1) % #staticMessages) + 1]
	screen.Color = Color3.fromRGB(40 + pressCount * 20, 55, 80 + pressCount * 25)
end

function InteractionService:_televisionSecret(tv, screen, textLabel, player, state)
	state.Reacting = true
	self.discoveryService:Unlock(player, Constants.Discoveries.AngeredTelevision.Id)
	self.systemMessageRemote:FireClient(player, "The television noticed you.")

	textLabel.Text = "STOP PRESSING BUTTONS."
	textLabel.TextColor3 = Color3.fromRGB(255, 60, 70)
	screen.Color = Color3.fromRGB(255, 255, 255)
	task.wait(0.15)
	screen.Color = Color3.fromRGB(40, 10, 18)
	task.wait(2.5)

	self.resetService.RestoreInstance(tv)
	state.Reacting = false
end

function InteractionService:_persistResetBaseline(root)
	if not root then
		return
	end

	local descendants = root:GetDescendants()
	table.insert(descendants, root)

	for _, instance in ipairs(descendants) do
		self.resetService.MarkBaseline(instance)
	end
end

function InteractionService:_checkExitUnlock(player)
	if self.exitUnlocked or not player then
		return
	end

	if not self.discoveryService:HasAll(player, Constants.RoomCompletionOrder.TVRoom) then
		return
	end

	self.exitUnlocked = true

	for _, door in ipairs(CollectionService:GetTagged(Constants.Tags.ExitDoor)) do
		self:_unlockExitDoor(door)
	end

	self.systemMessageRemote:FireAllClients("TV Room complete. The entrance has changed its mind.")
end

function InteractionService:_wireExitDoor(door)
	if self.exitUnlocked then
		self:_unlockExitDoor(door)
	end

	local prompt = getPrompt(door)
	self:_connectPrompt(prompt, function(player)
		if not self.exitUnlocked then
			self.systemMessageRemote:FireClient(player, "It still says ENTRANCE. The room is waiting for every discovery.")
			return
		end

		teleportPlayer(player, door:GetAttribute("DestinationCFrame"))
		self.systemMessageRemote:FireClient(player, "The hallway smells like choices.")
	end)
end

function InteractionService:_unlockExitDoor(door)
	if not door or not door:IsA("BasePart") then
		return
	end

	door.CanCollide = false
	door.Transparency = 0.48
	door.Color = Color3.fromRGB(61, 217, 132)
	door.Material = Enum.Material.Neon

	local prompt = getPrompt(door)
	if prompt then
		prompt.ActionText = "Exit"
		prompt.ObjectText = "Hallway"
		prompt.Enabled = true
	end

	local textLabel = door:FindFirstChild("DoorText", true)
	if textLabel and textLabel:IsA("TextLabel") then
		textLabel.Text = "EXIT"
		textLabel.TextColor3 = Color3.fromRGB(18, 45, 26)
		textLabel.BackgroundColor3 = Color3.fromRGB(122, 255, 177)
	end

	self:_persistResetBaseline(door)
end

function InteractionService:_wireHallDoor(door)
	local prompt = getPrompt(door)

	self:_connectPrompt(prompt, function(player)
		local lockedMessage = door:GetAttribute("LockedMessage")
		if lockedMessage then
			self.systemMessageRemote:FireClient(player, lockedMessage)
			return
		end

		local destinationCFrame = door:GetAttribute("DestinationCFrame")
		if typeof(destinationCFrame) ~= "CFrame" then
			self.systemMessageRemote:FireClient(player, "This door forgot where it goes.")
			return
		end

		teleportPlayer(player, destinationCFrame)
	end)
end

function InteractionService:_wireSnackButton(button)
	local prompt = getPrompt(button)

	self.snackButtonState[button] = self.snackButtonState[button] or {
		Reacting = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.snackButtonState[button]
		if not state or state.Reacting then
			return
		end

		state.Reacting = true
		self.discoveryService:Unlock(player, Constants.Discoveries.PressedSnackButton.Id)
		self.systemMessageRemote:FireClient(player, "The Snack Lab accepts your terrible application.")

		local originalColor = button.Color
		local baseCFrame = button:GetAttribute("BaseCFrame") or button.CFrame
		local downTween = tweenPart(button, 0.12, {
			Color = Color3.fromRGB(255, 90, 80),
			CFrame = baseCFrame + Vector3.new(0, -0.22, 0),
		})
		downTween.Completed:Wait()

		task.wait(0.35)
		local upTween = tweenPart(button, 0.18, {
			Color = originalColor,
			CFrame = baseCFrame,
		})
		upTween.Completed:Wait()

		state.Reacting = false
	end)
end

function InteractionService:_wireSnackFridge(fridge)
	local prompt = getPrompt(fridge)
	local door = fridge:FindFirstChild("FridgeDoor", true)
	local textLabel = fridge:FindFirstChild("FridgeDoorText", true)
	local iceCube = fridge:FindFirstChild("ColdIdeaIceCube", true)

	self.fridgeState[fridge] = self.fridgeState[fridge] or {
		Reacting = false,
		Opened = false,
		IceSpinToken = nil,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.fridgeState[fridge]
		if not state or state.Reacting or not door then
			return
		end

		state.Reacting = true
		state.Opened = not state.Opened
		self.discoveryService:Unlock(player, Constants.Discoveries.OpenedFridge.Id)

		if state.Opened then
			self.systemMessageRemote:FireClient(player, "The fridge contains one cold idea.")
			if textLabel and textLabel:IsA("TextLabel") then
				textLabel.Text = "TOO LATE"
				textLabel.TextColor3 = Color3.fromRGB(25, 34, 39)
				textLabel.BackgroundColor3 = Color3.fromRGB(172, 242, 255)
			end
			tweenPart(door, 0.35, {
				CFrame = (door:GetAttribute("BaseCFrame") or door.CFrame) + Vector3.new(-2.7, 0, 0.9),
				Color = Color3.fromRGB(172, 242, 255),
			}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

			if iceCube and iceCube:IsA("BasePart") then
				local token = {}
				state.IceSpinToken = token
				local baseCFrame = iceCube:GetAttribute("BaseCFrame") or iceCube.CFrame

				task.spawn(function()
					for index = 1, 18 do
						if state.IceSpinToken ~= token or not iceCube.Parent then
							return
						end

						local floatOffset = Vector3.new(0, math.sin(index * 0.8) * 0.22, 0)
						local spinTween = tweenPart(iceCube, 0.22, {
							CFrame = (baseCFrame + floatOffset) * CFrame.Angles(math.rad(index * 22), math.rad(index * 35), math.rad(index * 18)),
							Transparency = 0.12,
						}, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
						spinTween.Completed:Wait()
					end
				end)
			end
		else
			state.IceSpinToken = nil
			self.resetService.RestoreInstance(fridge)
		end

		task.wait(0.4)
		state.Reacting = false
	end)
end

function InteractionService:_wireSnackToaster(toaster)
	local prompt = getPrompt(toaster)
	local slot = toaster:FindFirstChild("ToasterSlot", true)

	self.toasterState[toaster] = self.toasterState[toaster] or {
		Reacting = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.toasterState[toaster]
		if not state or state.Reacting then
			return
		end

		state.Reacting = true
		self.discoveryService:Unlock(player, Constants.Discoveries.SuspiciousToast.Id)
		self.systemMessageRemote:FireClient(player, "That toast is achieving escape velocity.")

		local toastModel = Instance.new("Model")
		toastModel.Name = "SuspiciousToast"
		toastModel.Parent = workspace
		CollectionService:AddTag(toastModel, Constants.Tags.TemporaryObject)

		local toast = Instance.new("Part")
		toast.Name = "ToastSlice"
		toast.Anchored = false
		toast.Size = Vector3.new(2.2, 1.55, 0.26)
		toast.Color = Color3.fromRGB(241, 190, 102)
		toast.Material = Enum.Material.SmoothPlastic
		toast.CFrame = slot and slot.CFrame + Vector3.new(0, 1.45, 0) or toaster:GetPivot() + Vector3.new(0, 5, 0)
		toast.Parent = toastModel
		toastModel.PrimaryPart = toast

		local crustData = {
			{ Name = "TopCrust", Size = Vector3.new(2.25, 0.24, 0.3), Offset = Vector3.new(0, 0.68, 0) },
			{ Name = "LeftCrust", Size = Vector3.new(0.22, 1.42, 0.3), Offset = Vector3.new(-1.05, 0, 0) },
			{ Name = "RightCrust", Size = Vector3.new(0.22, 1.42, 0.3), Offset = Vector3.new(1.05, 0, 0) },
		}

		for _, data in ipairs(crustData) do
			local crust = Instance.new("Part")
			crust.Name = data.Name
			crust.Anchored = false
			crust.Size = data.Size
			crust.Color = Color3.fromRGB(153, 92, 45)
			crust.Material = Enum.Material.SmoothPlastic
			crust.CFrame = toast.CFrame * CFrame.new(data.Offset.X, data.Offset.Y, data.Offset.Z)
			crust.Parent = toastModel

			local weld = Instance.new("WeldConstraint")
			weld.Part0 = toast
			weld.Part1 = crust
			weld.Parent = crust
		end

		CollectionService:AddTag(toast, Constants.Tags.TemporaryObject)
		toast.AssemblyLinearVelocity = Vector3.new(0, 72, 0)
		toast.AssemblyAngularVelocity = Vector3.new(8, 2, 12)
		Debris:AddItem(toastModel, 6)

		task.wait(0.45)
		state.Reacting = false
	end)
end

function InteractionService:_wireSnackSink(sink)
	local prompt = getPrompt(sink)
	local faucet = sink:FindFirstChild("FaucetSpout", true) or sink:FindFirstChild("FaucetPost", true)

	self.sinkState[sink] = self.sinkState[sink] or {
		CountByUserId = {},
		Reacting = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.sinkState[sink]
		if not state or state.Reacting then
			return
		end

		state.CountByUserId[player.UserId] = (state.CountByUserId[player.UserId] or 0) + 1

		if state.CountByUserId[player.UserId] < 3 then
			self.systemMessageRemote:FireClient(player, "The sink gurgles politely.")
			return
		end

		state.CountByUserId[player.UserId] = 0
		state.Reacting = true
		self.discoveryService:Unlock(player, Constants.Discoveries.AngrySink.Id)
		self.systemMessageRemote:FireClient(player, "The sink has entered geyser mode.")

		for index = 1, 5 do
			local water = Instance.new("Part")
			water.Name = "SnackSinkWater"
			water.Anchored = true
			water.CanCollide = false
			water.Size = Vector3.new(0.55 + index * 0.18, 3 + index * 0.65, 0.55 + index * 0.18)
			water.Color = Color3.fromRGB(75, 190, 255)
			water.Material = Enum.Material.Neon
			water.Transparency = 0.18
			water.CFrame = (faucet and faucet.CFrame or sink:GetPivot()) + Vector3.new(0, 1.2 + index * 0.5, 0)
			water.Parent = workspace
			CollectionService:AddTag(water, Constants.Tags.TemporaryObject)
			Debris:AddItem(water, 1.2)
			task.wait(0.12)
		end

		task.wait(0.6)
		state.Reacting = false
	end)
end

function InteractionService:_wireSnackMixer(mixer)
	local prompt = getPrompt(mixer)
	local bowl = mixer:FindFirstChild("MixerBowl", true)
	local beaterLeft = mixer:FindFirstChild("BeaterLeft", true)
	local beaterRight = mixer:FindFirstChild("BeaterRight", true)

	self.mixerState[mixer] = self.mixerState[mixer] or {
		Reacting = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.mixerState[mixer]
		if not state or state.Reacting or not bowl then
			return
		end

		state.Reacting = true
		self.discoveryService:Unlock(player, Constants.Discoveries.MixedCloud.Id)
		self.systemMessageRemote:FireClient(player, "The mixer invented weather.")

		local originalColor = bowl.Color
		bowl.Material = Enum.Material.Neon
		bowl.Color = Color3.fromRGB(190, 255, 235)

		for index = 1, 7 do
			if beaterLeft and beaterLeft:IsA("BasePart") then
				beaterLeft.CFrame = (beaterLeft:GetAttribute("BaseCFrame") or beaterLeft.CFrame) * CFrame.Angles(0, math.rad(index * 65), 0)
			end

			if beaterRight and beaterRight:IsA("BasePart") then
				beaterRight.CFrame = (beaterRight:GetAttribute("BaseCFrame") or beaterRight.CFrame) * CFrame.Angles(0, math.rad(-index * 65), 0)
			end

			local cloud = Instance.new("Part")
			cloud.Name = "MixerCloud"
			cloud.Anchored = true
			cloud.CanCollide = false
			cloud.Shape = Enum.PartType.Ball
			cloud.Size = Vector3.new(1.5, 1.5, 1.5) * (0.75 + index * 0.1)
			cloud.Color = Color3.fromRGB(238, 245, 255)
			cloud.Material = Enum.Material.Neon
			cloud.Transparency = 0.18
			cloud.CFrame = bowl.CFrame + Vector3.new(math.sin(index) * 1.8, 1.5 + index * 0.45, math.cos(index) * 1.8)
			cloud.Parent = workspace
			CollectionService:AddTag(cloud, Constants.Tags.TemporaryObject)
			Debris:AddItem(cloud, 3)
			task.wait(0.12)
		end

		task.wait(1)
		self.resetService.RestoreInstance(mixer)
		bowl.Material = Enum.Material.Glass
		bowl.Color = originalColor
		state.Reacting = false
	end)
end

function InteractionService:_wireSnackRack(rack)
	local prompt = getPrompt(rack)

	self.snackRackState[rack] = self.snackRackState[rack] or {
		Reacting = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.snackRackState[rack]
		if not state or state.Reacting then
			return
		end

		state.Reacting = true
		self.discoveryService:Unlock(player, Constants.Discoveries.SnackRack.Id)
		self.systemMessageRemote:FireClient(player, "The snack rack audited your snack intentions.")

		local packs = {}
		for _, descendant in ipairs(rack:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant:GetAttribute("IsSnackPack") then
				table.insert(packs, descendant)
			end
		end

		for index, pack in ipairs(packs) do
			local baseCFrame = pack:GetAttribute("BaseCFrame") or pack.CFrame
			local offset = Vector3.new(0, 0.15 + (index % 3) * 0.08, 0.22)
			tweenPart(pack, 0.12, {
				CFrame = baseCFrame + offset,
				Color = Color3.fromRGB(255, 255, 255),
			}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

			task.delay(0.2, function()
				if pack.Parent then
					self.resetService.RestoreInstance(pack)
				end
			end)
		end

		task.wait(0.6)
		state.Reacting = false
	end)
end

function InteractionService:_wireFruitBowl(fruitBowl)
	local prompt = getPrompt(fruitBowl)

	self.fruitBowlState[fruitBowl] = self.fruitBowlState[fruitBowl] or {
		Reacting = false,
	}

	self:_connectPrompt(prompt, function(player)
		local state = self.fruitBowlState[fruitBowl]
		if not state or state.Reacting then
			return
		end

		state.Reacting = true
		self.discoveryService:Unlock(player, Constants.Discoveries.LivingFruit.Id)
		self.systemMessageRemote:FireClient(player, "The fruit bowl has become self-aware.")

		local fruit = {}
		for _, descendant in ipairs(fruitBowl:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant:GetAttribute("IsFruit") then
				table.insert(fruit, descendant)
			end
		end

		for index, piece in ipairs(fruit) do
			task.spawn(function()
				local baseCFrame = piece:GetAttribute("BaseCFrame") or piece.CFrame
				local jumpTween = tweenPart(piece, 0.22, {
					CFrame = baseCFrame + Vector3.new(0, 1.2 + index * 0.15, 0),
				}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				jumpTween.Completed:Wait()

				local spinTween = tweenPart(piece, 0.28, {
					CFrame = baseCFrame * CFrame.Angles(math.rad(0), math.rad(180 + index * 25), math.rad(0)),
				}, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
				spinTween.Completed:Wait()

				if piece.Parent then
					self.resetService.RestoreInstance(piece)
				end
			end)
		end

		task.wait(0.9)
		state.Reacting = false
	end)
end

return InteractionService
