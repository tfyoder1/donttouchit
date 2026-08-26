local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local UiLayerController = require(script.Parent:WaitForChild("UiLayerController"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local referenceBookRemote = remotes:WaitForChild(Constants.Remotes.ReferenceBook)
local hintPackRemote = remotes:WaitForChild(Constants.Remotes.HintPackRequest)

local gui = Instance.new("ScreenGui")
gui.Name = "DontTouchItRoomMenuOverlay"
gui.IgnoreGuiInset = false
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
UiLayerController.ApplyRole(gui, "RoomMenu")
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")
pcall(function()
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
end)

local shade = Instance.new("TextButton")
shade.Name = "Shade"
shade.AutoButtonColor = false
shade.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
shade.BackgroundTransparency = 0.45
shade.BorderSizePixel = 0
shade.Size = UDim2.fromScale(1, 1)
shade.Text = ""
shade.Modal = true
shade.ZIndex = 1
shade.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = Color3.fromRGB(24, 27, 33)
panel.BackgroundTransparency = 0.04
panel.BorderSizePixel = 0
panel.Position = UDim2.fromScale(0.5, 0.52)
panel.Size = UDim2.new(0.9, 0, 0.82, 0)
panel.ZIndex = 2
panel.Parent = gui

local panelConstraint = Instance.new("UISizeConstraint")
panelConstraint.MaxSize = Vector2.new(620, 520)
panelConstraint.MinSize = Vector2.new(300, 280)
panelConstraint.Parent = panel

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 8)
panelCorner.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.Position = UDim2.fromOffset(16, 12)
title.Size = UDim2.new(1, -86, 0, 34)
title.TextColor3 = Color3.fromRGB(255, 242, 181)
title.TextScaled = true
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 3
title.Parent = panel

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(62, 66, 78)
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBlack
closeButton.Position = UDim2.new(1, -12, 0, 12)
closeButton.Size = UDim2.fromOffset(54, 42)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextScaled = true
closeButton.ZIndex = 4
closeButton.Parent = panel

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeButton

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.GothamSemibold
subtitle.Position = UDim2.fromOffset(16, 52)
subtitle.Size = UDim2.new(1, -32, 0, 48)
subtitle.TextColor3 = Color3.fromRGB(220, 235, 245)
subtitle.TextScaled = true
subtitle.TextWrapped = true
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.ZIndex = 3
subtitle.Parent = panel

local list = Instance.new("ScrollingFrame")
list.Name = "List"
list.BackgroundColor3 = Color3.fromRGB(16, 18, 23)
list.BackgroundTransparency = 0.08
list.BorderSizePixel = 0
list.Position = UDim2.fromOffset(16, 108)
list.Size = UDim2.new(1, -32, 1, -124)
list.ScrollBarThickness = 6
list.CanvasSize = UDim2.fromOffset(0, 0)
list.ZIndex = 3
list.Parent = panel

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 6)
listCorner.Parent = list

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 7)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 8)
padding.PaddingBottom = UDim.new(0, 8)
padding.PaddingLeft = UDim.new(0, 8)
padding.PaddingRight = UDim.new(0, 8)
padding.Parent = list

local activeRoomId = nil

local function close()
	gui.Enabled = false
	closeButton.Modal = false
	if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(gui) then
		GuiService.SelectedObject = nil
	end
end

local function clearRows()
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function sendAction(action, extra)
	if not activeRoomId then
		return
	end

	local payload = {
		Action = action,
		RoomId = activeRoomId,
	}
	if extra then
		for key, value in pairs(extra) do
			payload[key] = value
		end
	end
	hintPackRemote:FireServer(payload)
end

local function makeRow(text, order, onActivated)
	local row
	if onActivated then
		row = Instance.new("TextButton")
		row.AutoButtonColor = true
	else
		row = Instance.new("TextLabel")
	end

	row.Name = onActivated and "ActionRow" or "InfoRow"
	row.BackgroundColor3 = onActivated and Color3.fromRGB(38, 64, 72) or Color3.fromRGB(38, 42, 50)
	row.BackgroundTransparency = 0.06
	row.BorderSizePixel = 0
	row.Font = Enum.Font.GothamBold
	row.LayoutOrder = order
	row.Size = UDim2.new(1, 0, 0, 42)
	row.Text = text
	row.TextColor3 = Color3.fromRGB(232, 242, 250)
	row.TextScaled = true
	row.TextWrapped = true
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.ZIndex = 4
	row.Parent = list

	local rowPadding = Instance.new("UIPadding")
	rowPadding.PaddingLeft = UDim.new(0, 10)
	rowPadding.PaddingRight = UDim.new(0, 10)
	rowPadding.Parent = row

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 5)
	rowCorner.Parent = row

	if onActivated then
		row.Activated:Connect(onActivated)
	end

	return row
end

local function render(payload)
	if typeof(payload) ~= "table" then
		return
	end

	activeRoomId = payload.RoomId
	local mode = payload.Mode or "Log"
	clearRows()

	if mode == "Store" then
		title.Text = (payload.RoomName or "Room") .. " Rewards"
		subtitle.Text = payload.StatusText or "Rewards and clue tools."
		makeRow("Free Hint", 1, function()
			sendAction("FreeHint")
		end)
		makeRow("Trade hints for clue", 2, function()
			sendAction("UseHint")
		end)
		makeRow("Trade clues for reveal", 3, function()
			sendAction("RevealHint")
		end)
		makeRow("Buy / test hint pack", 4, function()
			sendAction("BuyPack")
		end)
	elseif mode == "Teleport" then
		title.Text = "Teleport Key"
		subtitle.Text = payload.StatusText or "Choose an opened room."
		for index, room in ipairs(payload.TeleportRooms or {}) do
			makeRow(room.Name or room.RoomId or "Room", index, function()
				sendAction("TeleportRoom", {
					TargetRoomId = room.RoomId,
				})
				close()
			end)
		end
		if #(payload.TeleportRooms or {}) == 0 then
			makeRow("No opened rooms yet.", 1)
		end
	elseif mode == "Field" then
		title.Text = "Field Controls"
		subtitle.Text = payload.StatusText or "Temporary field adjustments."
		for index, fieldControl in ipairs(payload.FieldControls or {}) do
			makeRow(("%s  |  %s"):format(fieldControl.Name or fieldControl.Id or "Field", fieldControl.Description or ""), index, function()
				sendAction("FieldEffect", {
					EffectId = fieldControl.Id,
				})
				close()
			end)
		end
		if #(payload.FieldControls or {}) == 0 then
			makeRow("No field controls are wired yet.", 1)
		end
	else
		title.Text = (payload.RoomName or "Room") .. " Log"
		subtitle.Text = ("%d / %d found. Hints: %d | Clues: %d"):format(
			payload.Count or 0,
			payload.Total or 0,
			payload.Hints or 0,
			payload.Clues or 0
		)
		for index, entry in ipairs(payload.Discoveries or {}) do
			local prefix = entry.Unlocked and "[x] " or "[?] "
			if entry.Secret then
				prefix = "[secret] "
			elseif entry.Revealed then
				prefix = "Location shown: "
			elseif entry.Clued then
				prefix = "Clue: "
			end
			makeRow(prefix .. (entry.Name or "???"), index)
		end
		if #(payload.Discoveries or {}) == 0 then
			makeRow("No discoveries listed for this room.", 1)
		end
	end

	list.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 20)
	gui.Enabled = true
	closeButton.Modal = true
	GuiService.SelectedObject = closeButton
end

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	list.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 20)
end)

closeButton.Activated:Connect(close)
shade.Activated:Connect(close)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not gui.Enabled then
		return
	end

	if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
		close()
	end
end)

referenceBookRemote.OnClientEvent:Connect(render)
