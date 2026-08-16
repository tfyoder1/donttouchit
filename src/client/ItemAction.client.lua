local Players = game:GetService("Players")

local player = Players.LocalPlayer
local TouchControls = require(script.Parent:WaitForChild("TouchControls"))

local actionControl = nil
local characterConnections = {}

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
		actionControl:SetEnabled(getEquippedUsableTool() ~= nil)
	end
end

local function activateEquippedTool()
	local tool = getEquippedUsableTool()
	if not tool then
		updateActionButton()
		return
	end

	tool:Activate()
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
