local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local TouchControls = require(script.Parent:WaitForChild("TouchControls"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local inventoryRemote = remotes:WaitForChild(Constants.Remotes.InventoryAction)
local hintPackRemote = remotes:WaitForChild(Constants.Remotes.HintPackRequest)

local CONSUMABLE_HOLD_SECONDS = 0.45
local FLASHLIGHT_ATTRIBUTE = "DontTouchItFlashlight"
local CONSUMABLE_PROMPT_NAMES = {
	DroppedEnergyPocketPrompt = true,
	DroppedEnergyUsePrompt = true,
	LooseFruitEatPrompt = true,
	LooseFruitPocketPrompt = true,
}
local PANEL_MENU_PROMPTS = {
	["TV Room Log"] = "Log",
	["Rewards & Store"] = "Store",
	Teleport = "Teleport",
	["Field Controls"] = "Field",
}

local actionControl = nil
local characterConnections = {}
local shownConsumablePrompts = {}
local shownGenericPrompts = {}
local touchPressToken = 0
local touchPressActive = false
local touchHoldConsumed = false
local lastHoldConsumedAt = 0

local function isConsumablePrompt(prompt)
	return prompt
		and prompt:IsA("ProximityPrompt")
		and prompt.Enabled ~= false
		and CONSUMABLE_PROMPT_NAMES[prompt.Name] == true
end

local function getPromptRoot(prompt)
	local parent = prompt and prompt.Parent
	if not parent then
		return nil
	end

	return parent
end

local function getRootPart()
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function getPromptPosition(prompt)
	local parent = prompt and prompt.Parent
	if not parent then
		return nil
	end

	if parent:IsA("Attachment") then
		return parent.WorldPosition
	elseif parent:IsA("BasePart") then
		return parent.Position
	elseif parent:IsA("Model") then
		return parent:GetPivot().Position
	end

	return nil
end

local function isPromptInReach(prompt)
	if not prompt or not prompt:IsA("ProximityPrompt") or prompt.Enabled == false then
		return false
	end

	local rootPart = getRootPart()
	local promptPosition = getPromptPosition(prompt)
	if not rootPart or not promptPosition then
		return false
	end

	return (rootPart.Position - promptPosition).Magnitude <= prompt.MaxActivationDistance + 1.5
end

local function findSiblingPrompt(prompt, preferredNames)
	local root = getPromptRoot(prompt)
	if not root then
		return nil
	end

	for _, name in ipairs(preferredNames) do
		local sibling = root:FindFirstChild(name)
		if isConsumablePrompt(sibling) then
			return sibling
		end
	end

	return nil
end

local function getCurrentConsumablePrompts()
	for prompt in pairs(shownConsumablePrompts) do
		if not isConsumablePrompt(prompt) then
			shownConsumablePrompts[prompt] = nil
		end
	end

	for prompt in pairs(shownConsumablePrompts) do
		local pocketPrompt = findSiblingPrompt(prompt, {
			"DroppedEnergyPocketPrompt",
			"LooseFruitPocketPrompt",
		})
		local usePrompt = findSiblingPrompt(prompt, {
			"DroppedEnergyUsePrompt",
			"LooseFruitEatPrompt",
		})
		if pocketPrompt and usePrompt then
			return pocketPrompt, usePrompt
		end
	end

	return nil, nil
end

local function getCurrentGenericPrompt()
	local rootPart = getRootPart()
	local closestPrompt = nil
	local closestDistance = math.huge

	for prompt in pairs(shownGenericPrompts) do
		if not isPromptInReach(prompt) or isConsumablePrompt(prompt) then
			shownGenericPrompts[prompt] = nil
		elseif rootPart then
			local promptPosition = getPromptPosition(prompt)
			local distance = promptPosition and (rootPart.Position - promptPosition).Magnitude or math.huge
			if distance < closestDistance then
				closestDistance = distance
				closestPrompt = prompt
			end
		end
	end

	return closestPrompt
end

local function getAncestorRoomId(instance)
	local current = instance
	while current and current ~= workspace do
		local roomId = current:GetAttribute("RoomId")
		if typeof(roomId) == "string" and roomId ~= "" then
			return roomId
		end
		current = current.Parent
	end

	return nil
end

local function getPanelMenuMode(prompt)
	if not prompt or not prompt:IsA("ProximityPrompt") then
		return nil
	end

	local objectText = tostring(prompt.ObjectText or "")
	local mode = PANEL_MENU_PROMPTS[objectText]
	if mode then
		return mode
	end

	if string.find(objectText, " Log", 1, true) then
		return "Log"
	end

	return nil
end

local function activatePrompt(prompt)
	if not isPromptInReach(prompt) then
		return false
	end

	prompt:InputHoldBegin()
	task.delay(math.max(prompt.HoldDuration, 0) + 0.05, function()
		if prompt.Parent then
			prompt:InputHoldEnd()
		end
	end)
	return true
end

local function isUsableTool(tool)
	return tool
		and tool:IsA("Tool")
		and tool.Enabled ~= false
		and (
			tool:GetAttribute("VoidFreezeRay") == true
			or tool:GetAttribute("DontTouchItEnergyReserve") == true
			or tool:GetAttribute("DontTouchItUsableTool") == true
		)
end

local function getEquippedUsableTool()
	local character = player.Character
	if not character then
		return nil
	end

	for _, child in ipairs(character:GetChildren()) do
		if isUsableTool(child) then
			return child
		end
	end

	return nil
end

local function updateActionButton()
	if actionControl and actionControl.SetEnabled then
		local pocketPrompt, usePrompt = getCurrentConsumablePrompts()
		actionControl:SetEnabled(getCurrentGenericPrompt() ~= nil or getEquippedUsableTool() ~= nil or (pocketPrompt ~= nil and usePrompt ~= nil))
	end
end

local function activateEquippedTool()
	if os.clock() - lastHoldConsumedAt < 0.25 then
		return
	end

	local genericPrompt = getCurrentGenericPrompt()
	local panelMode = getPanelMenuMode(genericPrompt)
	if panelMode then
		hintPackRemote:FireServer({
			Action = "OpenRoomMenu",
			Mode = panelMode,
			RoomId = getAncestorRoomId(genericPrompt),
		})
		task.defer(updateActionButton)
		return
	end

	if genericPrompt and activatePrompt(genericPrompt) then
		task.defer(updateActionButton)
		return
	end

	local pocketPrompt = getCurrentConsumablePrompts()
	if pocketPrompt and not getEquippedUsableTool() then
		if activatePrompt(pocketPrompt) then
			task.defer(updateActionButton)
		end
		return
	end

	local tool = getEquippedUsableTool()
	if not tool then
		updateActionButton()
		return
	end

	if tool:GetAttribute(FLASHLIGHT_ATTRIBUTE) == true then
		inventoryRemote:FireServer({
			Action = "ToggleFlashlight",
		})
		return
	end

	tool:Activate()
end

local function beginTouchAction()
	if getEquippedUsableTool() then
		return
	end

	local _, usePrompt = getCurrentConsumablePrompts()
	if not usePrompt then
		return
	end

	touchPressToken += 1
	local token = touchPressToken
	touchPressActive = true
	touchHoldConsumed = false

	task.delay(CONSUMABLE_HOLD_SECONDS, function()
		if token ~= touchPressToken or not touchPressActive or touchHoldConsumed then
			return
		end

		local _, currentUsePrompt = getCurrentConsumablePrompts()
		if currentUsePrompt and activatePrompt(currentUsePrompt) then
			touchHoldConsumed = true
			lastHoldConsumedAt = os.clock()
			task.defer(updateActionButton)
		end
	end)
end

local function endTouchAction()
	touchPressActive = false
end

local function disconnectCharacterConnections()
	for _, connection in ipairs(characterConnections) do
		connection:Disconnect()
	end
	table.clear(characterConnections)
end

local function watchCharacter(character)
	disconnectCharacterConnections()
	if not character then
		updateActionButton()
		return
	end

	table.insert(characterConnections, character.ChildAdded:Connect(function()
		task.defer(updateActionButton)
	end))
	table.insert(characterConnections, character.ChildRemoved:Connect(function()
		task.defer(updateActionButton)
	end))
	task.defer(updateActionButton)
end

actionControl = TouchControls.RegisterAction({
	Id = "Action",
	Label = "Action / Use",
	Text = "Action",
	Order = 35,
	Desktop = "Tool activate",
	Xbox = "Tool activate",
	Touch = "Action button",
	Position = UDim2.new(0, 660, 0, 278),
	TextColor = Color3.fromRGB(250, 248, 255),
	StrokeColor = Color3.fromRGB(245, 245, 255),
	Enabled = getEquippedUsableTool() ~= nil,
	OnBegan = beginTouchAction,
	OnEnded = endTouchAction,
	OnActivated = activateEquippedTool,
})

watchCharacter(player.Character)
player.CharacterAdded:Connect(watchCharacter)
player.CharacterRemoving:Connect(function()
	disconnectCharacterConnections()
	task.defer(updateActionButton)
end)

local backpack = player:FindFirstChildOfClass("Backpack")
if backpack then
	backpack.ChildAdded:Connect(updateActionButton)
	backpack.ChildRemoved:Connect(updateActionButton)
end

player.ChildAdded:Connect(function(child)
	if child:IsA("Backpack") then
		child.ChildAdded:Connect(updateActionButton)
		child.ChildRemoved:Connect(updateActionButton)
		task.defer(updateActionButton)
	end
end)

ProximityPromptService.PromptShown:Connect(function(prompt)
	if prompt and prompt:IsA("ProximityPrompt") and prompt.Enabled ~= false then
		shownGenericPrompts[prompt] = true
	end
	if isConsumablePrompt(prompt) then
		shownConsumablePrompts[prompt] = true
	end
	updateActionButton()
end)

ProximityPromptService.PromptHidden:Connect(function(prompt)
	if shownGenericPrompts[prompt] then
		shownGenericPrompts[prompt] = nil
	end
	if shownConsumablePrompts[prompt] then
		shownConsumablePrompts[prompt] = nil
	end
	updateActionButton()
end)
