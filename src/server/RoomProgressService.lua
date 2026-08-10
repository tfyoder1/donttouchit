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
	self.systemMessageRemote = RemoteService.GetRemote(Constants.Remotes.SystemMessage)
	self.roomStatusRemote = RemoteService.GetRemote(Constants.Remotes.RoomStatus)
	self.stateByUserId = {}
	return self
end

function RoomProgressService:Initialize()
	Players.PlayerRemoving:Connect(function(player)
		self.stateByUserId[player.UserId] = nil
	end)

	self.hintPackRemote.OnServerEvent:Connect(function(player, payload)
		self:_handleHintRequest(player, payload)
	end)

	self:_installReceiptHandler()

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
		state = {
			CurrentRoomId = nil,
			TimerStartedAt = os.clock(),
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

	for _, roomId in ipairs(Constants.RoomOrder) do
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

function RoomProgressService:_tick(now)
	for _, player in ipairs(Players:GetPlayers()) do
		self:_tickPlayer(player, now)
	end
end

function RoomProgressService:_tickPlayer(player, now)
	self:_sendRoomStatus(player)

	local roomId = self:GetRoomForPlayer(player)
	local state = self:_getState(player)

	if not roomId then
		state.CurrentRoomId = nil
		state.TimerStartedAt = now
		return
	end

	if state.CurrentRoomId ~= roomId then
		state.CurrentRoomId = roomId
		state.TimerStartedAt = now
	end

	local room = Constants.GetRoom(roomId)
	if not room then
		return
	end

	local elapsed = now - state.TimerStartedAt

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
end

function RoomProgressService:_sendRoomStatus(player)
	local areaId = self:GetAreaForPlayer(player)

	if areaId == Constants.Hallway.Id then
		self.roomStatusRemote:FireClient(player, {
			Type = "Hallway",
			Name = Constants.Hallway.Name,
			UnlockedRooms = Constants.Hallway.UnlockedRoomCount,
			TotalRooms = Constants.Hallway.TotalRoomCount,
		})
		return
	end

	if areaId then
		local snapshot = self.discoveryService:GetRoomSnapshot(player, areaId)
		if snapshot then
			self.roomStatusRemote:FireClient(player, {
				Type = "Room",
				RoomId = snapshot.RoomId,
				RoomName = snapshot.RoomName,
				Count = snapshot.Count,
				Total = snapshot.Total,
			})
			return
		end
	end

	self.roomStatusRemote:FireClient(player, {
		Type = "None",
	})
end

function RoomProgressService:_handleHintRequest(player, payload)
	if typeof(payload) ~= "table" then
		return
	end

	local action = payload.Action
	local roomId = payload.RoomId

	if action == "BuyPack" then
		self:_requestHintPack(player, roomId)
	elseif action == "UseHint" then
		local hintText, errorText = self.discoveryService:UseHint(player, roomId)
		local messageText = hintText or errorText or "No hint available."

		self:ShowReferenceBook(player, roomId, {
			HintText = hintText,
			StatusText = errorText,
		})
		self.systemMessageRemote:FireClient(player, messageText)
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
		StatusText = ("Prototype hint pack added: %d hints."):format(Constants.NoTouch.HintPackSize),
	})
	self.systemMessageRemote:FireClient(player, "Prototype hint pack added: 10 hints.")
end

function RoomProgressService:_installReceiptHandler()
	local productId = Constants.NoTouch.HintPackProductId
	if not productId or productId <= 0 then
		return
	end

	local previousProcessReceipt = MarketplaceService.ProcessReceipt

	MarketplaceService.ProcessReceipt = function(receiptInfo)
		if receiptInfo.ProductId == productId then
			local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
			if not player then
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end

			self.discoveryService:GrantHints(player, Constants.NoTouch.HintPackSize)
			self.systemMessageRemote:FireClient(player, "Hint pack added: 10 hints.")
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		if previousProcessReceipt then
			return previousProcessReceipt(receiptInfo)
		end

		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

return RoomProgressService
