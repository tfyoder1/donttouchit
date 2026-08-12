local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local RemoteService = require(script.Parent:WaitForChild("RemoteService"))

local RoomProgressService = {}
RoomProgressService.__index = RoomProgressService

local function getRootPart(player)
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function teleportPlayer(player, destinationCFrame)
	local rootPart = getRootPart(player)
	if not rootPart and player and player.Parent then
		player.CharacterAdded:Wait()
		task.wait(0.1)
		rootPart = getRootPart(player)
	end

	if not rootPart or typeof(destinationCFrame) ~= "CFrame" then
		return
	end

	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
	rootPart.CFrame = destinationCFrame
end

local function positionInZone(position, zone)
	if not zone or not zone.Min or not zone.Max then
		return false
	end

	return position.X >= zone.Min.X
		and position.X <= zone.Max.X
		and position.Y >= zone.Min.Y
		and position.Y <= zone.Max.Y
		and position.Z >= zone.Min.Z
		and position.Z <= zone.Max.Z
end

function RoomProgressService.new(discoveryService)
	local self = setmetatable({}, RoomProgressService)
	self.discoveryService = discoveryService
	self.referenceBookRemote = RemoteService.GetRemote(Constants.Remotes.ReferenceBook)
	self.hintPackRemote = RemoteService.GetRemote(Constants.Remotes.HintPackRequest)
	self.sessionStartRemote = RemoteService.GetRemote(Constants.Remotes.SessionStart)
	self.systemMessageRemote = RemoteService.GetRemote(Constants.Remotes.SystemMessage)
	self.roomStatusRemote = RemoteService.GetRemote(Constants.Remotes.RoomStatus)
	self.sparkleRemote = RemoteService.GetRemote(Constants.Remotes.SparkleHint)
	self.stateByUserId = {}
	self.pendingHintPurchaseByUserId = {}
	return self
end

function RoomProgressService:Initialize()
	local function setupPlayer(player)
		self:_getState(player)

		player.CharacterAdded:Connect(function()
			task.delay(0.8, function()
				if player.Parent then
					self:_sendStartOptions(player)
				end
			end)
		end)

		task.delay(1, function()
			if player.Parent then
				self:_sendStartOptions(player)
			end
		end)
	end

	Players.PlayerAdded:Connect(setupPlayer)

	Players.PlayerRemoving:Connect(function(player)
		self.stateByUserId[player.UserId] = nil
		self.pendingHintPurchaseByUserId[player.UserId] = nil
	end)

	self.sessionStartRemote.OnServerEvent:Connect(function(player, payload)
		self:_handleSessionStart(player, payload)
	end)

	self.hintPackRemote.OnServerEvent:Connect(function(player, payload)
		self:_handleHintRequest(player, payload)
	end)

	self:_installReceiptHandler()

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	task.spawn(function()
		while true do
			self:_tick(os.clock())
			task.wait(1)
		end
	end)
end

function RoomProgressService:_getState(player)
	local state = self.stateByUserId[player.UserId]

	if not state then
		local now = os.clock()
		state = {
			CurrentRoomId = nil,
			TimerStartedAt = now,
			PlayStartedAt = now,
			LastRoomTickAt = nil,
			RoomPlaySecondsByRoomId = {},
			RoomPlayRewardsByRoomId = {},
			SparkleStateByRoomId = {},
			StartOptionsSent = false,
			StartChoiceHandled = false,
			TwoMinuteAwarded = {},
			BonusAwarded = {},
		}
		self.stateByUserId[player.UserId] = state
	end

	return state
end

function RoomProgressService:GetRoomForPlayer(player)
	local rootPart = getRootPart(player)
	if not rootPart then
		return nil
	end

	for _, roomId in ipairs(Constants.DiscoveryRoomOrder or Constants.RoomOrder) do
		local room = Constants.GetRoom(roomId)
		if room and positionInZone(rootPart.Position, room.Zone) then
			return roomId
		end
	end

	return nil
end

function RoomProgressService:GetAreaForPlayer(player)
	local rootPart = getRootPart(player)
	if not rootPart then
		return nil
	end

	if positionInZone(rootPart.Position, Constants.Hallway.Zone) then
		return Constants.Hallway.Id
	end

	return self:GetRoomForPlayer(player)
end

function RoomProgressService:RecordInteraction(player)
	if not player or not player.Parent then
		return
	end

	local state = self:_getState(player)
	state.TimerStartedAt = os.clock()
end

function RoomProgressService:ShowReferenceBook(player, roomId, extra)
	local snapshot = self.discoveryService:GetRoomSnapshot(player, roomId)
	if not snapshot then
		return
	end

	if extra then
		for key, value in pairs(extra) do
			snapshot[key] = value
		end
	end

	self.referenceBookRemote:FireClient(player, snapshot)
end

function RoomProgressService:_sendStartOptions(player)
	local state = self:_getState(player)
	if state.StartOptionsSent then
		return
	end

	if not self.discoveryService:IsLoaded(player) then
		task.delay(0.5, function()
			if player.Parent then
				self:_sendStartOptions(player)
			end
		end)
		return
	end

	state.StartOptionsSent = true

	local resumeRoomId = self.discoveryService:GetLastUnlockedRoomId(player)
	local resumeRoom = Constants.GetRoom(resumeRoomId)
	local discoveryCount = self.discoveryService:GetDiscoveryCount(player)
	local hintCount = self.discoveryService:GetHintCount(player)
	local clueCount = self.discoveryService:GetClueCount(player)

	self.sessionStartRemote:FireClient(player, {
		Action = "Show",
		HasProgress = discoveryCount > 0 or hintCount > 0 or clueCount > 0 or resumeRoomId ~= Constants.RoomOrder[1],
		ResumeRoomId = resumeRoomId,
		ResumeRoomName = resumeRoom and resumeRoom.Name or "TV Room",
		DiscoveryCount = discoveryCount,
		TotalDiscoveries = Constants.TotalDiscoveries,
		Hints = hintCount,
		Clues = clueCount,
		BuildVersion = Constants.BuildVersion,
		IntroText = Constants.GameIntro,
	})
end

function RoomProgressService:_handleSessionStart(player, payload)
	if typeof(payload) ~= "table" then
		return
	end

	local action = payload.Action
	local roomId = Constants.RoomOrder[1]
	local message = "Starting from the TV Room. The book remembers what you found."

	if action == "Resume" then
		roomId = self.discoveryService:GetLastUnlockedRoomId(player)
		local room = Constants.GetRoom(roomId)
		message = ("Returning to %s. Try to look innocent."):format(room and room.Name or "the room")
	elseif action ~= "Restart" then
		return
	end

	local state = self:_getState(player)
	state.StartChoiceHandled = true
	state.TimerStartedAt = os.clock()

	teleportPlayer(player, Constants.GetRoomSpawnCFrame(roomId))
	self.systemMessageRemote:FireClient(player, message)
end

function RoomProgressService:_tick(now)
	local spaceStationOccupied = false

	for _, player in ipairs(Players:GetPlayers()) do
		self:_tickPlayer(player, now)
		if self:GetRoomForPlayer(player) == "SpaceStation" then
			spaceStationOccupied = true
		end
	end

	if spaceStationOccupied then
		workspace.Gravity = Constants.SpaceStationGravity or 24
	elseif workspace.Gravity == (Constants.SpaceStationGravity or 24) then
		workspace.Gravity = Constants.NormalGravity
	end
end

function RoomProgressService:_tickPlayer(player, now)
	local roomId = self:GetRoomForPlayer(player)
	local state = self:_getState(player)

	if not roomId then
		state.CurrentRoomId = nil
		state.TimerStartedAt = now
		state.LastRoomTickAt = nil
		self:_sendRoomStatus(player, now)
		return
	end

	if state.CurrentRoomId ~= roomId then
		state.CurrentRoomId = roomId
		state.TimerStartedAt = now
		state.LastRoomTickAt = now
		state.SparkleStateByRoomId[roomId] = {
			NextSparkleAt = now + Constants.Sparkle.FirstDelaySeconds,
		}

		if roomId == "Island" then
			self.discoveryService:Unlock(player, Constants.Discoveries.ReachedIsland.Id)
		elseif roomId == "SpaceStation" then
			self.discoveryService:Unlock(player, Constants.Discoveries.SpaceStationEntered.Id)
		end
	else
		local delta = math.max(0, now - (state.LastRoomTickAt or now))
		state.RoomPlaySecondsByRoomId[roomId] = (state.RoomPlaySecondsByRoomId[roomId] or 0) + delta
		state.LastRoomTickAt = now
	end

	local room = Constants.GetRoom(roomId)
	if not room then
		self:_sendRoomStatus(player, now)
		return
	end

	local elapsed = now - state.TimerStartedAt
	local totalPlay = state.RoomPlaySecondsByRoomId[roomId] or 0
	self:_tickRoomPlayRewards(player, roomId, totalPlay, state)
	self:_sendRoomStatus(player, now)
	self:_updateNoTouchWorldClocks(roomId, elapsed, totalPlay)

	if room.NoTouchDiscoveryId
		and elapsed >= Constants.NoTouch.AccomplishmentSeconds
		and not state.TwoMinuteAwarded[roomId]
	then
		state.TwoMinuteAwarded[roomId] = true
		self.discoveryService:Unlock(player, room.NoTouchDiscoveryId)
		self.systemMessageRemote:FireClient(player, "Well done, you didn't touch anything for a while!")
	end

	if elapsed >= Constants.NoTouch.BonusSeconds and not state.BonusAwarded[roomId] then
		state.BonusAwarded[roomId] = true
		self.discoveryService:GrantHints(player, Constants.NoTouch.BonusHintCount)
		self.systemMessageRemote:FireClient(player, "Super bonus: 10 free hints for impressive restraint.")
	end

	self:_tickSparkle(player, roomId, now, state)
end

function RoomProgressService:_sendRoomStatus(player, now)
	local areaId = self:GetAreaForPlayer(player)

	if areaId == Constants.Hallway.Id then
		self.roomStatusRemote:FireClient(player, {
			Type = "Hallway",
			Name = Constants.Hallway.Name,
			UnlockedRooms = self.discoveryService:GetUnlockedRoomCount(player),
			TotalRooms = Constants.Hallway.TotalRoomCount,
		})
		return
	end

	if areaId then
		local snapshot = self.discoveryService:GetRoomSnapshot(player, areaId)
		if snapshot then
			local state = self:_getState(player)
			local elapsed = 0
			if state.CurrentRoomId == areaId then
				elapsed = math.max(0, (now or os.clock()) - state.TimerStartedAt)
			end

			self.roomStatusRemote:FireClient(player, {
				Type = "Room",
				RoomId = snapshot.RoomId,
				RoomName = snapshot.RoomName,
				Count = snapshot.Count,
				Total = snapshot.Total,
				NoTouchElapsed = elapsed,
				NoTouchTarget = Constants.NoTouch.AccomplishmentSeconds,
				TotalPlaySeconds = state.RoomPlaySecondsByRoomId[areaId] or 0,
			})
			return
		end
	end

	self.roomStatusRemote:FireClient(player, {
		Type = "None",
	})
end

function RoomProgressService:_tickRoomPlayRewards(player, roomId, totalPlay, state)
	local earnedCount = math.floor(totalPlay / Constants.RoomPlay.HintIntervalSeconds)
	local awardedCount = state.RoomPlayRewardsByRoomId[roomId] or 0

	if earnedCount <= awardedCount then
		return
	end

	local rewardCount = earnedCount - awardedCount
	local hintTotal = rewardCount * Constants.RoomPlay.HintsPerInterval
	state.RoomPlayRewardsByRoomId[roomId] = earnedCount
	self.discoveryService:GrantHints(player, hintTotal)

	local room = Constants.GetRoom(roomId)
	self.systemMessageRemote:FireClient(
		player,
		("Room time bonus: %d free hint%s for staying in %s."):format(
			hintTotal,
			hintTotal == 1 and "" or "s",
			room and room.Name or "the room"
		)
	)
end

function RoomProgressService:_updateNoTouchWorldClocks(roomId, elapsed, totalPlay)
	local text = ("Still %.1f / %.1fm\nRoom %.1fm"):format(
		elapsed / 60,
		Constants.NoTouch.AccomplishmentSeconds / 60,
		totalPlay / 60
	)

	for _, clock in ipairs(CollectionService:GetTagged(Constants.Tags.NoTouchClock)) do
		if clock:GetAttribute("RoomId") == roomId then
			local label = clock:FindFirstChild("ClockText", true)
			if label and label:IsA("TextLabel") then
				label.Text = text
			end
		end
	end
end

function RoomProgressService:_tickSparkle(player, roomId, now, state)
	local sparkleState = state.SparkleStateByRoomId[roomId]
	if not sparkleState then
		sparkleState = {
			NextSparkleAt = now + Constants.Sparkle.FirstDelaySeconds,
		}
		state.SparkleStateByRoomId[roomId] = sparkleState
	end

	if now < sparkleState.NextSparkleAt then
		return
	end

	sparkleState.NextSparkleAt = now + Constants.Sparkle.IntervalSeconds

	local _, targetTag = self.discoveryService:GetNextPendingHighlight(player, roomId)
	if not targetTag then
		return
	end

	local target = self:_findHighlightTarget(targetTag)
	if not target then
		return
	end

	self.sparkleRemote:FireClient(player, {
		Target = target,
		Duration = Constants.Sparkle.DurationSeconds,
	})
end

function RoomProgressService:_findHighlightTarget(targetTag)
	for _, instance in ipairs(CollectionService:GetTagged(targetTag)) do
		if instance and instance.Parent then
			return instance
		end
	end

	return nil
end

function RoomProgressService:_handleHintRequest(player, payload)
	if typeof(payload) ~= "table" then
		return
	end

	local action = payload.Action
	local roomId = payload.RoomId

	if action == "BuyPack" then
		self:_requestHintPack(player, roomId)
	elseif action == "FreeHint" then
		local hintText, errorText = self.discoveryService:GetFreeHint(player, roomId)
		self:_showHintResult(player, roomId, hintText, errorText)
	elseif action == "BuyClue" then
		self:_requestCluePurchase(player, roomId)
	elseif action == "Clue" or action == "PaidHint" or action == "UseHint" then
		self:_requestClue(player, roomId)
	elseif action == "BuyReveal" then
		self:_requestDiscoveryRevealPurchase(player, roomId)
	elseif action == "Reveal" or action == "FullReveal" then
		self:_requestDiscoveryReveal(player, roomId)
	elseif action == "RevealSecretDoor" then
		self:_requestSecretDoorReveal(player, roomId)
	elseif action == "BuySecretKey" then
		self:_requestSecretKey(player, roomId)
	end
end

function RoomProgressService:_showHintResult(player, roomId, hintText, errorText)
	local messageText = hintText or errorText or "No hint available."

	self:ShowReferenceBook(player, roomId, {
		HintText = hintText,
		StatusText = errorText,
	})
	self.systemMessageRemote:FireClient(player, messageText)
end

function RoomProgressService:_promptHintProduct(player, roomId, productId, action)
	self.pendingHintPurchaseByUserId[player.UserId] = {
		Action = action,
		RoomId = roomId,
		ProductId = productId,
	}

	local ok = pcall(function()
		MarketplaceService:PromptProductPurchase(player, productId)
	end)

	if not ok then
		self.pendingHintPurchaseByUserId[player.UserId] = nil
		self.systemMessageRemote:FireClient(player, "That hint purchase is not ready in this test build.")
	end
end

function RoomProgressService:_requestClue(player, roomId)
	local productId = Constants.NoTouch.ClueProductId
	if not productId or productId <= 0 then
		productId = Constants.NoTouch.PaidHintProductId
	end

	if productId and productId > 0 then
		self:_promptHintProduct(player, roomId, productId, "Clue")
		return
	end

	local hintText, errorText = self.discoveryService:UseClue(player, roomId, Constants.NoTouch.ClueHintCost)
	self:_showHintResult(player, roomId, hintText, errorText)
end

function RoomProgressService:_requestCluePurchase(player, roomId)
	local productId = Constants.NoTouch.ClueProductId
	if not productId or productId <= 0 then
		productId = Constants.NoTouch.PaidHintProductId
	end

	if productId and productId > 0 then
		self:_promptHintProduct(player, roomId, productId, "Clue")
		return
	end

	local hintText, errorText = self.discoveryService:UseClue(player, roomId, 0, true)
	self:_showHintResult(
		player,
		roomId,
		hintText,
		errorText or "Prototype clue purchase added. Currently free; no Robux charged."
	)
end

function RoomProgressService:_requestDiscoveryReveal(player, roomId)
	local productId = Constants.NoTouch.RevealProductId
	if not productId or productId <= 0 then
		productId = Constants.NoTouch.FullRevealProductId
	end

	if productId and productId > 0 then
		self:_promptHintProduct(player, roomId, productId, "Reveal")
		return
	end

	local revealText, targetTag, errorText = self.discoveryService:UseLocationReveal(player, roomId, Constants.NoTouch.RevealClueCost)
	self:_showHintResult(player, roomId, revealText, errorText)

	if revealText and targetTag then
		local target = self:_findHighlightTarget(targetTag)
		if target then
			self.sparkleRemote:FireClient(player, {
				Target = target,
				Duration = math.max(Constants.Sparkle.DurationSeconds, 8),
			})
		end
	end
end

function RoomProgressService:_requestDiscoveryRevealPurchase(player, roomId)
	local productId = Constants.NoTouch.RevealProductId
	if not productId or productId <= 0 then
		productId = Constants.NoTouch.FullRevealProductId
	end

	if productId and productId > 0 then
		self:_promptHintProduct(player, roomId, productId, "Reveal")
		return
	end

	local revealText, targetTag, errorText = self.discoveryService:UseLocationReveal(player, roomId, 0, true)
	self:_showHintResult(
		player,
		roomId,
		revealText,
		errorText or "Prototype reveal purchase added. Currently free; no Robux charged."
	)

	if revealText and targetTag then
		local target = self:_findHighlightTarget(targetTag)
		if target then
			self.sparkleRemote:FireClient(player, {
				Target = target,
				Duration = math.max(Constants.Sparkle.DurationSeconds, 8),
			})
		end
	end
end

function RoomProgressService:_requestHintPack(player, roomId)
	local productId = Constants.NoTouch.HintPackProductId

	if productId and productId > 0 then
		local ok = pcall(function()
			MarketplaceService:PromptProductPurchase(player, productId)
		end)

		if not ok then
			self.systemMessageRemote:FireClient(player, "Hint purchase is not ready in this test build.")
		end
		return
	end

	self.discoveryService:GrantHints(player, Constants.NoTouch.HintPackSize)
	self:ShowReferenceBook(player, roomId, {
		StatusText = ("Prototype hint pack added: %d hints. Currently free; no Robux charged."):format(Constants.NoTouch.HintPackSize),
	})
	self.systemMessageRemote:FireClient(player, "Prototype hint pack added: 10 hints. Currently free; no Robux charged.")
end

function RoomProgressService:_requestSecretDoorReveal(player, roomId)
	local config = Constants.SecretDoors and Constants.SecretDoors[roomId]
	if not config then
		self:_showHintResult(player, roomId, nil, "This room does not have a secret door yet.")
		return
	end

	if self.discoveryService:CanSeeSecretDoor(player, roomId) then
		self:_showHintResult(player, roomId, nil, "The Library outline is already visible. Finish the room, then bring the key.")
		return
	end

	local productId = config.RevealProductId
	if productId and productId > 0 then
		self:_promptHintProduct(player, roomId, productId, "SecretDoorReveal")
		return
	end

	local cost = math.max(0, config.RevealHintCost or 0)
	local ok, errorText = self.discoveryService:SpendHints(player, cost)
	if not ok then
		self:_showHintResult(
			player,
			roomId,
			nil,
			("Library outline reveal needs %d hints, or you can complete the room normally for free."):format(cost)
		)
		return
	end

	self.discoveryService:RevealSecretDoor(player, roomId, "Library outline revealed early. Finish the room to activate it.")
	self:ShowReferenceBook(player, roomId, {
		StatusText = ("Library outline revealed for %d hints. Finish the room, then bring the Library Key."):format(cost),
	})
end

function RoomProgressService:_requestSecretKey(player, roomId)
	local config = Constants.SecretDoors and Constants.SecretDoors[roomId]
	if not config then
		self:_showHintResult(player, roomId, nil, "This room does not have a Library key yet.")
		return
	end

	if self.discoveryService:HasSecretKey(player, roomId) then
		self:_showHintResult(player, roomId, nil, "You already have the Library Key.")
		return
	end

	if not self.discoveryService:IsRoomComplete(player, roomId) then
		self:_showHintResult(player, roomId, nil, "Finish the room before rushing the Library Key.")
		return
	end

	local cost = math.max(0, Constants.NoTouch.SecretKeyClueCost or Constants.NoTouch.RevealClueCost or 3)
	local ok = self.discoveryService:SpendClues(player, cost)
	if not ok then
		self:_showHintResult(player, roomId, nil, ("Library Key rush needs %d clues."):format(cost))
		return
	end

	self.discoveryService:GrantSecretKey(player, roomId, "Library Key purchased for one reveal's worth of clues.")
	self:ShowReferenceBook(player, roomId, {
		StatusText = ("Library Key purchased for %d clues."):format(cost),
	})
end

function RoomProgressService:_installReceiptHandler()
	local hintPackProductId = Constants.NoTouch.HintPackProductId
	local paidHintProductId = Constants.NoTouch.ClueProductId
	if not paidHintProductId or paidHintProductId <= 0 then
		paidHintProductId = Constants.NoTouch.PaidHintProductId
	end
	local fullRevealProductId = Constants.NoTouch.RevealProductId
	if not fullRevealProductId or fullRevealProductId <= 0 then
		fullRevealProductId = Constants.NoTouch.FullRevealProductId
	end
	local secretDoorProductById = {}

	for roomId, config in pairs(Constants.SecretDoors or {}) do
		local productId = config.RevealProductId
		if productId and productId > 0 then
			secretDoorProductById[productId] = roomId
		end
	end

	if (not hintPackProductId or hintPackProductId <= 0)
		and (not paidHintProductId or paidHintProductId <= 0)
		and (not fullRevealProductId or fullRevealProductId <= 0)
		and next(secretDoorProductById) == nil
	then
		return
	end

	local previousProcessReceipt = MarketplaceService.ProcessReceipt

	MarketplaceService.ProcessReceipt = function(receiptInfo)
		if receiptInfo.ProductId == hintPackProductId then
			local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
			if not player then
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end

			self.discoveryService:GrantHints(player, Constants.NoTouch.HintPackSize)
			self.systemMessageRemote:FireClient(player, "Hint pack added: 10 hints.")
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		if receiptInfo.ProductId == paidHintProductId or receiptInfo.ProductId == fullRevealProductId then
			local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
			if not player then
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end

			local pending = self.pendingHintPurchaseByUserId[player.UserId]
			self.pendingHintPurchaseByUserId[player.UserId] = nil

			if not pending or pending.ProductId ~= receiptInfo.ProductId then
				self.systemMessageRemote:FireClient(player, "Hint purchase completed, but the room log lost its place.")
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end

			local hintText = nil
			local errorText = nil
			if pending.Action == "Reveal" or pending.Action == "FullReveal" then
				local targetTag = nil
				hintText, targetTag, errorText = self.discoveryService:UseLocationReveal(player, pending.RoomId, 0, true)
				if hintText and targetTag then
					local target = self:_findHighlightTarget(targetTag)
					if target then
						self.sparkleRemote:FireClient(player, {
							Target = target,
							Duration = math.max(Constants.Sparkle.DurationSeconds, 8),
						})
					end
				end
			else
				hintText, errorText = self.discoveryService:UseClue(player, pending.RoomId, 0, true)
			end

			self:_showHintResult(player, pending.RoomId, hintText, errorText)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		local secretDoorRoomId = secretDoorProductById[receiptInfo.ProductId]
		if secretDoorRoomId then
			local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
			if not player then
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end

			self.discoveryService:RevealSecretDoor(player, secretDoorRoomId, "Library outline revealed early. Finish the room to activate it.")
			self:ShowReferenceBook(player, secretDoorRoomId, {
				StatusText = "Library outline revealed. Finish the room, then bring the Library Key.",
			})
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		if previousProcessReceipt then
			return previousProcessReceipt(receiptInfo)
		end

		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

return RoomProgressService
