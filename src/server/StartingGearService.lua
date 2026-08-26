local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local StartingGearService = {}
StartingGearService.__index = StartingGearService

local FLASHLIGHT_TOOL_NAME = "Flashlight"
local FLASHLIGHT_ATTRIBUTE = "DontTouchItFlashlight"
local FLASHLIGHT_OWNED_ATTRIBUTE = "DontTouchItHasFlashlight"
local PICKUP_CONNECTED_ATTRIBUTE = "DontTouchItFlashlightPickupConnected"

local function getBackpack(player)
	return player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack", 2)
end

local function playerHasFlashlight(player)
	local function checkContainer(container)
		if not container then
			return false
		end

		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("Tool") and child:GetAttribute(FLASHLIGHT_ATTRIBUTE) == true then
				return true
			end
		end

		return false
	end

	return checkContainer(player.Character) or checkContainer(player:FindFirstChildOfClass("Backpack"))
end

local function getEquippedFlashlight(player)
	local character = player and player.Character
	if not character then
		return nil
	end

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") and child:GetAttribute(FLASHLIGHT_ATTRIBUTE) == true then
			return child
		end
	end

	return nil
end

local function findFlashlightTool(player)
	local character = player and player.Character
	if character then
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Tool") and child:GetAttribute(FLASHLIGHT_ATTRIBUTE) == true then
				return child, character
			end
		end
	end

	local backpack = player and player:FindFirstChildOfClass("Backpack")
	if backpack then
		for _, child in ipairs(backpack:GetChildren()) do
			if child:IsA("Tool") and child:GetAttribute(FLASHLIGHT_ATTRIBUTE) == true then
				return child, backpack
			end
		end
	end

	return nil, nil
end

local function setFlashlightEnabled(tool, enabled)
	tool:SetAttribute("FlashlightOn", enabled)

	local handle = tool:FindFirstChild("Handle")
	if not handle then
		return
	end

	for _, descendant in ipairs(handle:GetDescendants()) do
		if descendant:IsA("Light") then
			descendant.Enabled = enabled
		elseif descendant:IsA("Beam") then
			descendant.Enabled = enabled
		end
	end
end

local function createFlashlightTool()
	local tool = Instance.new("Tool")
	tool.Name = FLASHLIGHT_TOOL_NAME
	tool.ToolTip = "Use Action to turn the light on or off."
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool:SetAttribute(FLASHLIGHT_ATTRIBUTE, true)
	tool:SetAttribute("DontTouchItUsableTool", true)
	tool:SetAttribute("FlashlightOn", false)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Anchored = false
	handle.CanCollide = false
	handle.Massless = true
	handle.Material = Enum.Material.Metal
	handle.Color = Color3.fromRGB(42, 45, 48)
	handle.Size = Vector3.new(0.42, 0.42, 1.35)
	handle.Shape = Enum.PartType.Cylinder
	handle.Parent = tool

	local lens = Instance.new("Part")
	lens.Name = "FlashlightLens"
	lens.Anchored = false
	lens.CanCollide = false
	lens.Massless = true
	lens.Material = Enum.Material.Glass
	lens.Color = Color3.fromRGB(194, 231, 255)
	lens.Transparency = 0.18
	lens.Size = Vector3.new(0.48, 0.48, 0.1)
	lens.Shape = Enum.PartType.Cylinder
	lens.CFrame = handle.CFrame * CFrame.new(0, 0, -0.72)
	lens.Parent = tool

	local lensWeld = Instance.new("WeldConstraint")
	lensWeld.Name = "FlashlightLensWeld"
	lensWeld.Part0 = handle
	lensWeld.Part1 = lens
	lensWeld.Parent = lens

	local beam = Instance.new("SpotLight")
	beam.Name = "FlashlightBeam"
	beam.Angle = 62
	beam.Brightness = 7.5
	beam.Color = Color3.fromRGB(218, 238, 255)
	beam.Enabled = false
	beam.Face = Enum.NormalId.Front
	beam.Range = 70
	beam.Shadows = false
	beam.Parent = handle

	local spill = Instance.new("PointLight")
	spill.Name = "FlashlightSpill"
	spill.Brightness = 1.1
	spill.Color = Color3.fromRGB(178, 214, 255)
	spill.Enabled = false
	spill.Range = 18
	spill.Shadows = false
	spill.Parent = handle

	tool.Grip = CFrame.new(0, -0.08, -0.45) * CFrame.Angles(0, math.rad(90), 0)

	tool.Activated:Connect(function()
		if tool.Enabled == false then
			return
		end

		setFlashlightEnabled(tool, tool:GetAttribute("FlashlightOn") ~= true)
	end)

	return tool
end

function StartingGearService.new()
	return setmetatable({}, StartingGearService)
end

function StartingGearService:_grantFlashlight(player)
	if not player or not player.Parent or playerHasFlashlight(player) then
		return
	end

	local backpack = getBackpack(player)
	if not backpack then
		return
	end

	createFlashlightTool().Parent = backpack
end

function StartingGearService:GrantFlashlight(player)
	if not player or not player.Parent then
		return
	end

	player:SetAttribute(FLASHLIGHT_OWNED_ATTRIBUTE, true)
	self:_grantFlashlight(player)
end

function StartingGearService:_toggleEquippedFlashlight(player)
	local tool = getEquippedFlashlight(player)
	if not tool then
		local container
		tool, container = findFlashlightTool(player)
		local character = player and player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if tool and container and container:IsA("Backpack") and humanoid then
			humanoid:EquipTool(tool)
			tool = getEquippedFlashlight(player) or tool
		end
	end

	if not tool or tool.Enabled == false then
		return
	end

	setFlashlightEnabled(tool, tool:GetAttribute("FlashlightOn") ~= true)
end

function StartingGearService:_sendSystemMessage(player, text)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local remote = remotes and remotes:FindFirstChild(Constants.Remotes.SystemMessage)
	if remote then
		remote:FireClient(player, text)
	end
end

function StartingGearService:_wireFlashlightPickup(instance)
	if not instance or instance:GetAttribute(PICKUP_CONNECTED_ATTRIBUTE) == true then
		return
	end

	local prompt = if instance:IsA("ProximityPrompt") then instance else instance:FindFirstChildWhichIsA("ProximityPrompt", true)
	if not prompt then
		return
	end

	instance:SetAttribute(PICKUP_CONNECTED_ATTRIBUTE, true)
	prompt.Triggered:Connect(function(player)
		local alreadyHadFlashlight = playerHasFlashlight(player) or player:GetAttribute(FLASHLIGHT_OWNED_ATTRIBUTE) == true
		self:GrantFlashlight(player)

		if alreadyHadFlashlight then
			self:_sendSystemMessage(player, "You already have the flashlight. Equip it, then press Action to turn it on or off.")
		else
			self:_sendSystemMessage(player, "Flashlight added. Equip it from inventory, then press Action to turn it on or off.")
		end
	end)
end

function StartingGearService:Initialize()
	local function setupPlayer(player)
		player.CharacterAdded:Connect(function()
			task.delay(0.25, function()
				if player:GetAttribute(FLASHLIGHT_OWNED_ATTRIBUTE) == true then
					self:_grantFlashlight(player)
				end
			end)
		end)
	end

	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	for _, instance in ipairs(CollectionService:GetTagged(Constants.Tags.StartingFlashlight)) do
		self:_wireFlashlightPickup(instance)
	end

	CollectionService:GetInstanceAddedSignal(Constants.Tags.StartingFlashlight):Connect(function(instance)
		self:_wireFlashlightPickup(instance)
	end)

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local inventoryActionRemote = remotes:WaitForChild(Constants.Remotes.InventoryAction)
	inventoryActionRemote.OnServerEvent:Connect(function(player, payload)
		if typeof(payload) ~= "table" or payload.Action ~= "ToggleFlashlight" then
			return
		end

		self:_toggleEquippedFlashlight(player)
	end)
end

return StartingGearService
