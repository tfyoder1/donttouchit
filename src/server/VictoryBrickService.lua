local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local RemoteService = require(script.Parent:WaitForChild("RemoteService"))

local VictoryBrickService = {}
VictoryBrickService.__index = VictoryBrickService

local STANDARD_TIER = "Standard"
local DELUXE_TIER = "Deluxe"

local function now()
	return os.time()
end

local function cleanName(value)
	local text = tostring(value or ""):gsub("[%c\r\n\t]", " "):gsub("%s+", " ")
	text = text:match("^%s*(.-)%s*$") or ""
	if text == "" then
		return "Anonymous Winner"
	end

	return string.sub(text, 1, 28)
end

local function formatBrickText(record)
	if not record then
		return Constants.VictoryWalkway.EmptyBrickText or "FUTURE\nWINNER"
	end

	local displayName = cleanName(record.DisplayName or record.Username)
	if record.Tier == DELUXE_TIER then
		return ("%s\n%s"):format(Constants.VictoryWalkway.DeluxeTextPrefix or "DELUXE", displayName)
	end

	return displayName
end

local function getSlotDistance(slot)
	local cavePosition = Constants.VictoryWalkway.CavePriorityPosition or Vector3.new(-46, 0, 55)
	local position = slot.Part.Position
	return (Vector3.new(position.X, 0, position.Z) - Vector3.new(cavePosition.X, 0, cavePosition.Z)).Magnitude
end

function VictoryBrickService.new(discoveryService)
	local self = setmetatable({}, VictoryBrickService)
	self.discoveryService = discoveryService
	self.systemMessageRemote = RemoteService.GetRemote(Constants.Remotes.SystemMessage)
	self.records = {}
	self.loaded = false
	self.dataStore = nil
	self.saveQueued = false
	self.slots = {}
	self.pendingDeluxeByUserId = {}

	local ok, dataStore = pcall(function()
		return DataStoreService:GetDataStore(Constants.DataStore.VictoryBricksName or "DontTouchItVictoryBricks_v1")
	end)
	if ok then
		self.dataStore = dataStore
	else
		warn(("[DON'T TOUCH IT] Victory brick DataStore unavailable: %s"):format(tostring(dataStore)))
	end

	return self
end

function VictoryBrickService:Initialize()
	self:_captureSlots()
	self:_load()
	self:_applyLayout()
	self:_installReceiptHandler()
end

function VictoryBrickService:_captureSlots()
	local borderBySlotIndex = {}
	for _, border in ipairs(CollectionService:GetTagged(Constants.Tags.VictoryBrickBorder)) do
		if border:IsA("BasePart") then
			local slotIndex = border:GetAttribute("VictoryBrickSlotIndex")
			if typeof(slotIndex) == "number" then
				borderBySlotIndex[slotIndex] = borderBySlotIndex[slotIndex] or {}
				table.insert(borderBySlotIndex[slotIndex], border)
			end
		end
	end

	local slots = {}
	for _, brick in ipairs(CollectionService:GetTagged(Constants.Tags.VictoryBrick)) do
		if brick:IsA("BasePart") then
			local slotIndex = brick:GetAttribute("VictoryBrickSlotIndex") or #slots + 1
			table.insert(slots, {
				SlotIndex = slotIndex,
				Part = brick,
				Label = brick:FindFirstChild("VictoryBrickText", true),
				Borders = borderBySlotIndex[slotIndex] or {},
			})
		end
	end

	table.sort(slots, function(left, right)
		local leftDistance = getSlotDistance(left)
		local rightDistance = getSlotDistance(right)
		if math.abs(leftDistance - rightDistance) < 0.001 then
			return left.SlotIndex < right.SlotIndex
		end

		return leftDistance < rightDistance
	end)

	self.slots = slots
end

function VictoryBrickService:_sanitizeRecord(record)
	if typeof(record) ~= "table" or typeof(record.UserId) ~= "number" then
		return nil
	end

	local tier = record.Tier == DELUXE_TIER and DELUXE_TIER or STANDARD_TIER
	return {
		UserId = record.UserId,
		Username = cleanName(record.Username),
		DisplayName = cleanName(record.DisplayName),
		Tier = tier,
		PreferredSlotIndex = if typeof(record.PreferredSlotIndex) == "number" then math.floor(record.PreferredSlotIndex) else nil,
		CreatedAt = if typeof(record.CreatedAt) == "number" then record.CreatedAt else now(),
		UpdatedAt = if typeof(record.UpdatedAt) == "number" then record.UpdatedAt else now(),
	}
end

function VictoryBrickService:_load()
	table.clear(self.records)

	if not self.dataStore then
		self.loaded = true
		return
	end

	local ok, data = pcall(function()
		return self.dataStore:GetAsync(Constants.DataStore.VictoryBricksKey or "victory_brick_registry")
	end)

	if not ok then
		warn(("[DON'T TOUCH IT] Could not load victory bricks: %s"):format(tostring(data)))
		self.loaded = true
		return
	end

	local rawRecords = if typeof(data) == "table" and typeof(data.Records) == "table" then data.Records else data
	if typeof(rawRecords) == "table" then
		for _, rawRecord in ipairs(rawRecords) do
			local record = self:_sanitizeRecord(rawRecord)
			if record then
				self.records[record.UserId] = record
			end
		end
	end

	self.loaded = true
end

function VictoryBrickService:_buildRecordList()
	local records = {}
	for _, record in pairs(self.records) do
		table.insert(records, table.clone(record))
	end

	table.sort(records, function(left, right)
		if left.Tier ~= right.Tier then
			return left.Tier == DELUXE_TIER
		end

		if left.Tier == DELUXE_TIER then
			return (left.CreatedAt or 0) < (right.CreatedAt or 0)
		end

		return (left.CreatedAt or 0) > (right.CreatedAt or 0)
	end)

	return records
end

function VictoryBrickService:_queueSave()
	if self.saveQueued or not self.dataStore then
		return
	end

	self.saveQueued = true
	task.delay(0.5, function()
		self.saveQueued = false
		local data = {
			Version = 1,
			UpdatedAt = now(),
			Records = self:_buildRecordList(),
		}

		local ok, errorMessage = pcall(function()
			self.dataStore:SetAsync(Constants.DataStore.VictoryBricksKey or "victory_brick_registry", data)
		end)
		if not ok then
			warn(("[DON'T TOUCH IT] Could not save victory bricks: %s"):format(tostring(errorMessage)))
		end
	end)
end

function VictoryBrickService:_resetBrick(slot)
	local part = slot.Part
	if not part or not part.Parent then
		return
	end

	local baseColor = part:GetAttribute("BaseColor")
	if baseColor then
		part.Color = baseColor
	elseif slot.SlotIndex % 2 == 0 then
		part.Color = Constants.VictoryWalkway.StandardBrickColorA or Color3.fromRGB(180, 96, 62)
	else
		part.Color = Constants.VictoryWalkway.StandardBrickColorB or Color3.fromRGB(124, 72, 48)
	end

	if slot.Label and slot.Label:IsA("TextLabel") then
		slot.Label.Text = Constants.VictoryWalkway.EmptyBrickText or "FUTURE\nWINNER"
		slot.Label.TextColor3 = Color3.fromRGB(255, 226, 174)
		slot.Label.BackgroundColor3 = part.Color
	end

	for _, border in ipairs(slot.Borders) do
		if border.Parent then
			border.Transparency = 1
		end
	end

	part:SetAttribute("VictoryBrickUserId", nil)
	part:SetAttribute("VictoryBrickTier", nil)
	part:SetAttribute("VictoryBrickDisplayName", nil)
end

function VictoryBrickService:_applyRecordToSlot(slot, record)
	local part = slot.Part
	if not part or not part.Parent then
		return
	end

	local isDeluxe = record.Tier == DELUXE_TIER
	part.Color = if isDeluxe
		then (Constants.VictoryWalkway.DeluxeBrickColor or Color3.fromRGB(132, 82, 46))
		else (Constants.VictoryWalkway.SignedBrickColor or Color3.fromRGB(154, 82, 56))

	if slot.Label and slot.Label:IsA("TextLabel") then
		slot.Label.Text = formatBrickText(record)
		slot.Label.TextColor3 = if isDeluxe then Color3.fromRGB(255, 239, 165) else Color3.fromRGB(255, 226, 174)
		slot.Label.BackgroundColor3 = part.Color
	end

	for _, border in ipairs(slot.Borders) do
		if border.Parent then
			border.Transparency = isDeluxe and 0.04 or 1
		end
	end

	part:SetAttribute("VictoryBrickUserId", record.UserId)
	part:SetAttribute("VictoryBrickTier", record.Tier)
	part:SetAttribute("VictoryBrickDisplayName", cleanName(record.DisplayName or record.Username))
end

function VictoryBrickService:_takeSlotByIndex(availableSlots, requestedSlotIndex)
	if not requestedSlotIndex then
		return nil
	end

	for index, slot in ipairs(availableSlots) do
		if slot.SlotIndex == requestedSlotIndex then
			return table.remove(availableSlots, index)
		end
	end

	return nil
end

function VictoryBrickService:_applyFixedBricks(availableSlots)
	local fixedBricks = Constants.VictoryWalkway.FixedBricks
	if typeof(fixedBricks) ~= "table" then
		return
	end

	for _, fixedBrick in ipairs(fixedBricks) do
		if typeof(fixedBrick) == "table" then
			local slot = self:_takeSlotByIndex(availableSlots, fixedBrick.SlotIndex)
			if slot then
				self:_applyRecordToSlot(slot, {
					Username = fixedBrick.Username,
					DisplayName = fixedBrick.DisplayName or fixedBrick.Username,
					Tier = fixedBrick.Tier == DELUXE_TIER and DELUXE_TIER or STANDARD_TIER,
				})
			end
		end
	end
end

function VictoryBrickService:_applyLayout()
	if #self.slots == 0 then
		self:_captureSlots()
	end

	for _, slot in ipairs(self.slots) do
		self:_resetBrick(slot)
	end

	local availableSlots = table.clone(self.slots)
	self:_applyFixedBricks(availableSlots)
	local records = self:_buildRecordList()
	local standardRecords = {}

	for _, record in ipairs(records) do
		if record.Tier == DELUXE_TIER then
			local slot = self:_takeSlotByIndex(availableSlots, record.PreferredSlotIndex) or table.remove(availableSlots, 1)
			if slot then
				self:_applyRecordToSlot(slot, record)
			end
		else
			table.insert(standardRecords, record)
		end
	end

	table.sort(standardRecords, function(left, right)
		return (left.CreatedAt or 0) > (right.CreatedAt or 0)
	end)

	for _, record in ipairs(standardRecords) do
		local slot = table.remove(availableSlots, 1)
		if not slot then
			break
		end
		self:_applyRecordToSlot(slot, record)
	end
end

function VictoryBrickService:_getPlayerRecord(player)
	return player and self.records[player.UserId]
end

function VictoryBrickService:_isEligible(player)
	if not player or not player.Parent or not self.discoveryService then
		return false
	end

	if self.discoveryService:IsDevOverrideActive(player) then
		return false
	end

	return self.discoveryService:GetDiscoveryCount(player) >= (Constants.TotalDiscoveries or 1)
end

function VictoryBrickService:SignStandard(player)
	if not self:_isEligible(player) then
		return false, "Victory bricks unlock after finishing the game on normal progress."
	end

	local current = self:_getPlayerRecord(player)
	if current and current.Tier == DELUXE_TIER then
		current.DisplayName = cleanName(player.DisplayName or player.Name)
		current.Username = cleanName(player.Name)
		current.UpdatedAt = now()
		self:_applyLayout()
		self:_queueSave()
		return true, "Your deluxe victory brick is already on the walkway."
	end

	local createdAt = current and current.CreatedAt or now()
	self.records[player.UserId] = {
		UserId = player.UserId,
		Username = cleanName(player.Name),
		DisplayName = cleanName(player.DisplayName or player.Name),
		Tier = STANDARD_TIER,
		CreatedAt = createdAt,
		UpdatedAt = now(),
	}

	self:_applyLayout()
	self:_queueSave()
	return true, "Standard victory brick signed. New standard bricks stay near the cave until newer winners arrive."
end

function VictoryBrickService:GrantDeluxe(player, preferredSlotIndex)
	if not self:_isEligible(player) then
		return false, "Deluxe bricks still require normal completion first."
	end

	local current = self:_getPlayerRecord(player)
	local createdAt = current and current.CreatedAt or now()
	self.records[player.UserId] = {
		UserId = player.UserId,
		Username = cleanName(player.Name),
		DisplayName = cleanName(player.DisplayName or player.Name),
		Tier = DELUXE_TIER,
		PreferredSlotIndex = if typeof(preferredSlotIndex) == "number" then math.floor(preferredSlotIndex) else nil,
		CreatedAt = createdAt,
		UpdatedAt = now(),
	}

	self:_applyLayout()
	self:_queueSave()
	return true, "Deluxe victory brick placed with gold border priority."
end

function VictoryBrickService:PromptDeluxePurchase(player, preferredSlotIndex)
	if not self:_isEligible(player) then
		return false, "Finish the game normally first, then pick a deluxe brick spot."
	end

	local productId = Constants.NoTouch.VictoryBrickProductId or 0
	if productId <= 0 then
		return false, "Deluxe brick spot choice is staged. Add the product ID later to activate the purchase."
	end

	self.pendingDeluxeByUserId[player.UserId] = {
		SlotIndex = preferredSlotIndex,
		RequestedAt = now(),
	}
	MarketplaceService:PromptProductPurchase(player, productId)
	return true, "Choose confirmed. Roblox purchase prompt opened for the deluxe brick."
end

function VictoryBrickService:_installReceiptHandler()
	local productId = Constants.NoTouch.VictoryBrickProductId or 0
	if productId <= 0 then
		return
	end

	local previousProcessReceipt = MarketplaceService.ProcessReceipt
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		if receiptInfo.ProductId == productId then
			local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
			if not player then
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end

			local pending = self.pendingDeluxeByUserId[player.UserId]
			self.pendingDeluxeByUserId[player.UserId] = nil
			local ok, message = self:GrantDeluxe(player, pending and pending.SlotIndex or nil)
			if not message then
				message = if ok then "Deluxe victory brick placed." else "Deluxe brick purchase completed, but placement needs a normal completion check."
			end
			self.systemMessageRemote:FireClient(player, message)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		if previousProcessReceipt then
			return previousProcessReceipt(receiptInfo)
		end

		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

return VictoryBrickService
