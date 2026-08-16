local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local TouchControls = require(script.Parent:WaitForChild("TouchControls"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local inventoryRemote = remotes:WaitForChild(Constants.Remotes.InventoryAction)

local DROP_ACTION = "DontTouchItDropEquippedItem"
local DROP_GAMEPAD_KEY = Enum.KeyCode.ButtonB
local DROP_KEYBOARD_KEY = Enum.KeyCode.Backspace
local GAMEPAD_HOLD_SECONDS = 0.65
local CLIENT_DROP_COOLDOWN = 0.25

local lastDropAt = 0
local holdToken = 0
local characterConnections = {}
local dropControl = nil

local function getEquippedDroppableTool()
	local character = player.Character
	if not character then
		return nil
	end

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool")
			and (child:GetAttribute("DontTouchItPocketItem") == true or child:GetAttribute("DontTouchItEnergyReserve") == true)
		then
			return child
		end
	end

	return nil
end

local function isBlockingUiOpen()
	if UserInputService:GetFocusedTextBox() then
		return true
	end

	if playerGui:FindFirstChild("DontTouchItSecurityCamera") then
		return true
	end

	local ui = playerGui:FindFirstChild("DontTouchItUI")
	if not ui then
		return false
	end

	local referenceBook = ui:FindFirstChild("ReferenceBook")
	if referenceBook and referenceBook.Visible then
		return true
	end

	local startOverlay = ui:FindFirstChild("StartChoiceOverlay")
	if startOverlay and startOverlay.Visible then
		return true
	end

	return false
end

local function updateDropButtonVisibility()
	if dropControl then
		local enabled = getEquippedDroppableTool() ~= nil
		dropControl:SetVisible(true)
		dropControl:SetEnabled(enabled)
	end
end

local function requestDrop()
	if isBlockingUiOpen() or not getEquippedDroppableTool() then
		updateDropButtonVisibility()
		return
	end

	local now = os.clock()
	if now - lastDropAt < CLIENT_DROP_COOLDOWN then
		return
	end
	lastDropAt = now

	inventoryRemote:FireServer({
		Action = "DropEquipped",
	})
end

local function cancelGamepadHold()
	holdToken += 1
end

local function beginGamepadHold()
	holdToken += 1
	local token = holdToken
	task.delay(GAMEPAD_HOLD_SECONDS, function()
		if token ~= holdToken then
			return
		end
		requestDrop()
	end)
end

local function handleDropAction(_, inputState, inputObject)
	local isGamepadDrop = inputObject and inputObject.KeyCode == DROP_GAMEPAD_KEY

	if inputState == Enum.UserInputState.Begin then
		if isGamepadDrop then
			beginGamepadHold()
			return Enum.ContextActionResult.Pass
		end

		requestDrop()
		return Enum.ContextActionResult.Sink
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		if isGamepadDrop then
			cancelGamepadHold()
			return Enum.ContextActionResult.Pass
		end
	end

	return if isGamepadDrop then Enum.ContextActionResult.Pass else Enum.ContextActionResult.Sink
end

local function disconnectCharacterConnections()
	for _, connection in ipairs(characterConnections) do
		connection:Disconnect()
	end
	characterConnections = {}
end

local function watchCharacter(character)
	disconnectCharacterConnections()
	if not character then
		updateDropButtonVisibility()
		return
	end

	table.insert(characterConnections, character.ChildAdded:Connect(function()
		task.defer(updateDropButtonVisibility)
	end))
	table.insert(characterConnections, character.ChildRemoved:Connect(function()
		task.defer(updateDropButtonVisibility)
	end))
	task.defer(updateDropButtonVisibility)
end

local function setupTouchDropButton()
	dropControl = TouchControls.RegisterAction({
		Id = "Drop",
		Label = "Drop",
		Text = "Drop",
		Order = 40,
		Desktop = "Backspace",
		Xbox = "Hold B",
		Touch = "Drop button",
		Position = UDim2.new(0, 626, 0, 320),
		TextColor = Color3.fromRGB(255, 235, 194),
		StrokeColor = Color3.fromRGB(255, 211, 102),
		Enabled = getEquippedDroppableTool() ~= nil,
		OnActivated = requestDrop,
	})
	updateDropButtonVisibility()
end

ContextActionService:UnbindAction(DROP_ACTION)
ContextActionService:BindAction(DROP_ACTION, handleDropAction, false, DROP_KEYBOARD_KEY, DROP_GAMEPAD_KEY)

pcall(function()
	ContextActionService:SetTitle(DROP_ACTION, "Drop")
	ContextActionService:SetPosition(DROP_ACTION, UDim2.fromScale(0.58, 0.42))
end)

setupTouchDropButton()

watchCharacter(player.Character)
player.CharacterAdded:Connect(watchCharacter)
player.CharacterRemoving:Connect(function()
	cancelGamepadHold()
	watchCharacter(nil)
end)
