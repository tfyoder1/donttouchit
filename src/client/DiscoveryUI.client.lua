local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local discoveryRemote = remotes:WaitForChild(Constants.Remotes.DiscoveryUpdate)
local referenceBookRemote = remotes:WaitForChild(Constants.Remotes.ReferenceBook)
local hintPackRemote = remotes:WaitForChild(Constants.Remotes.HintPackRequest)
local systemMessageRemote = remotes:WaitForChild(Constants.Remotes.SystemMessage)

local gui = Instance.new("ScreenGui")
gui.Name = "DontTouchItUI"
gui.IgnoreGuiInset = false
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local title = Instance.new("TextLabel")
title.Name = "Title"
title.AnchorPoint = Vector2.new(0.5, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.Position = UDim2.new(0.5, 0, 0, 62)
title.Size = UDim2.new(0.82, 0, 0, 42)
title.Text = "DON'T TOUCH ANYTHING"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.TextStrokeColor3 = Color3.fromRGB(18, 18, 22)
title.TextStrokeTransparency = 0.25
title.Parent = gui

local titleSizeConstraint = Instance.new("UISizeConstraint")
titleSizeConstraint.MaxSize = Vector2.new(620, 42)
titleSizeConstraint.MinSize = Vector2.new(220, 32)
titleSizeConstraint.Parent = title

local counter = Instance.new("TextLabel")
counter.Name = "DiscoveryCounter"
counter.AnchorPoint = Vector2.new(1, 0)
counter.BackgroundColor3 = Color3.fromRGB(18, 20, 24)
counter.BackgroundTransparency = 0.18
counter.BorderSizePixel = 0
counter.Font = Enum.Font.GothamBold
counter.Position = UDim2.new(1, -18, 0, 18)
counter.Size = UDim2.fromOffset(330, 38)
counter.Text = ("Discoveries: 0 / %d"):format(Constants.TotalDiscoveries)
counter.TextColor3 = Color3.fromRGB(236, 246, 255)
counter.TextScaled = true
counter.Parent = gui

local counterCorner = Instance.new("UICorner")
counterCorner.CornerRadius = UDim.new(0, 6)
counterCorner.Parent = counter

local toast = Instance.new("TextLabel")
toast.Name = "DiscoveryToast"
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.BackgroundColor3 = Color3.fromRGB(255, 235, 120)
toast.BackgroundTransparency = 1
toast.BorderSizePixel = 0
toast.Font = Enum.Font.GothamBlack
toast.Position = UDim2.fromScale(0.5, 0.16)
toast.Size = UDim2.new(0.82, 0, 0, 72)
toast.Text = ""
toast.TextColor3 = Color3.fromRGB(24, 24, 28)
toast.TextScaled = true
toast.TextTransparency = 1
toast.Parent = gui

local toastSizeConstraint = Instance.new("UISizeConstraint")
toastSizeConstraint.MaxSize = Vector2.new(430, 72)
toastSizeConstraint.MinSize = Vector2.new(250, 60)
toastSizeConstraint.Parent = toast

local toastCorner = Instance.new("UICorner")
toastCorner.CornerRadius = UDim.new(0, 8)
toastCorner.Parent = toast

local message = Instance.new("TextLabel")
message.Name = "SystemMessage"
message.AnchorPoint = Vector2.new(0.5, 1)
message.BackgroundColor3 = Color3.fromRGB(18, 20, 24)
message.BackgroundTransparency = 1
message.BorderSizePixel = 0
message.Font = Enum.Font.GothamSemibold
message.Position = UDim2.new(0.5, 0, 1, -36)
message.Size = UDim2.new(0.88, 0, 0, 44)
message.Text = ""
message.TextColor3 = Color3.fromRGB(255, 255, 255)
message.TextScaled = true
message.TextTransparency = 1
message.Parent = gui

local messageSizeConstraint = Instance.new("UISizeConstraint")
messageSizeConstraint.MaxSize = Vector2.new(520, 44)
messageSizeConstraint.MinSize = Vector2.new(260, 36)
messageSizeConstraint.Parent = message

local messageCorner = Instance.new("UICorner")
messageCorner.CornerRadius = UDim.new(0, 6)
messageCorner.Parent = message

local bookPanel = Instance.new("Frame")
bookPanel.Name = "ReferenceBook"
bookPanel.AnchorPoint = Vector2.new(0.5, 0.5)
bookPanel.BackgroundColor3 = Color3.fromRGB(28, 30, 36)
bookPanel.BackgroundTransparency = 0.04
bookPanel.BorderSizePixel = 0
bookPanel.Position = UDim2.fromScale(0.5, 0.52)
bookPanel.Size = UDim2.fromOffset(440, 500)
bookPanel.Visible = false
bookPanel.Parent = gui

local bookPanelConstraint = Instance.new("UISizeConstraint")
bookPanelConstraint.MaxSize = Vector2.new(440, 500)
bookPanelConstraint.MinSize = Vector2.new(300, 360)
bookPanelConstraint.Parent = bookPanel

local bookCorner = Instance.new("UICorner")
bookCorner.CornerRadius = UDim.new(0, 8)
bookCorner.Parent = bookPanel

local bookTitle = Instance.new("TextLabel")
bookTitle.Name = "BookTitle"
bookTitle.BackgroundTransparency = 1
bookTitle.Font = Enum.Font.GothamBlack
bookTitle.Position = UDim2.fromOffset(18, 14)
bookTitle.Size = UDim2.new(1, -66, 0, 34)
bookTitle.Text = "Room Log"
bookTitle.TextColor3 = Color3.fromRGB(255, 242, 181)
bookTitle.TextScaled = true
bookTitle.TextXAlignment = Enum.TextXAlignment.Left
bookTitle.Parent = bookPanel

local closeBookButton = Instance.new("TextButton")
closeBookButton.Name = "CloseBook"
closeBookButton.AnchorPoint = Vector2.new(1, 0)
closeBookButton.BackgroundColor3 = Color3.fromRGB(62, 66, 78)
closeBookButton.BorderSizePixel = 0
closeBookButton.Font = Enum.Font.GothamBlack
closeBookButton.Position = UDim2.new(1, -12, 0, 12)
closeBookButton.Size = UDim2.fromOffset(36, 32)
closeBookButton.Text = "X"
closeBookButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBookButton.TextScaled = true
closeBookButton.Parent = bookPanel

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBookButton

local bookCount = Instance.new("TextLabel")
bookCount.Name = "BookCount"
bookCount.BackgroundTransparency = 1
bookCount.Font = Enum.Font.GothamBold
bookCount.Position = UDim2.fromOffset(18, 54)
bookCount.Size = UDim2.new(1, -36, 0, 26)
bookCount.Text = "0 / 0 found"
bookCount.TextColor3 = Color3.fromRGB(220, 235, 245)
bookCount.TextScaled = true
bookCount.TextXAlignment = Enum.TextXAlignment.Left
bookCount.Parent = bookPanel

local bookList = Instance.new("ScrollingFrame")
bookList.Name = "BookList"
bookList.BackgroundColor3 = Color3.fromRGB(18, 20, 24)
bookList.BackgroundTransparency = 0.16
bookList.BorderSizePixel = 0
bookList.CanvasSize = UDim2.fromOffset(0, 0)
bookList.ScrollBarThickness = 6
bookList.Position = UDim2.fromOffset(18, 90)
bookList.Size = UDim2.new(1, -36, 1, -222)
bookList.Parent = bookPanel

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 6)
listCorner.Parent = bookList

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = bookList

local listPadding = Instance.new("UIPadding")
listPadding.PaddingBottom = UDim.new(0, 8)
listPadding.PaddingLeft = UDim.new(0, 8)
listPadding.PaddingRight = UDim.new(0, 8)
listPadding.PaddingTop = UDim.new(0, 8)
listPadding.Parent = bookList

local hintCount = Instance.new("TextLabel")
hintCount.Name = "HintCount"
hintCount.BackgroundTransparency = 1
hintCount.Font = Enum.Font.GothamBold
hintCount.Position = UDim2.new(0, 18, 1, -122)
hintCount.Size = UDim2.new(1, -36, 0, 24)
hintCount.Text = "Hints: 0"
hintCount.TextColor3 = Color3.fromRGB(220, 235, 245)
hintCount.TextScaled = true
hintCount.TextXAlignment = Enum.TextXAlignment.Left
hintCount.Parent = bookPanel

local hintText = Instance.new("TextLabel")
hintText.Name = "HintText"
hintText.BackgroundColor3 = Color3.fromRGB(255, 242, 181)
hintText.BackgroundTransparency = 0.1
hintText.BorderSizePixel = 0
hintText.Font = Enum.Font.GothamSemibold
hintText.Position = UDim2.new(0, 18, 1, -94)
hintText.Size = UDim2.new(1, -36, 0, 40)
hintText.Text = ""
hintText.TextColor3 = Color3.fromRGB(28, 30, 36)
hintText.TextScaled = true
hintText.TextWrapped = true
hintText.Parent = bookPanel

local hintCorner = Instance.new("UICorner")
hintCorner.CornerRadius = UDim.new(0, 6)
hintCorner.Parent = hintText

local buyHintButton = Instance.new("TextButton")
buyHintButton.Name = "BuyHintPack"
buyHintButton.BackgroundColor3 = Color3.fromRGB(61, 217, 132)
buyHintButton.BorderSizePixel = 0
buyHintButton.Font = Enum.Font.GothamBlack
buyHintButton.Position = UDim2.new(0, 18, 1, -42)
buyHintButton.Size = UDim2.new(0.5, -24, 0, 30)
buyHintButton.Text = "10 Hints - 1 R$"
buyHintButton.TextColor3 = Color3.fromRGB(18, 45, 26)
buyHintButton.TextScaled = true
buyHintButton.Parent = bookPanel

local buyCorner = Instance.new("UICorner")
buyCorner.CornerRadius = UDim.new(0, 6)
buyCorner.Parent = buyHintButton

local useHintButton = Instance.new("TextButton")
useHintButton.Name = "UseHint"
useHintButton.BackgroundColor3 = Color3.fromRGB(84, 154, 255)
useHintButton.BorderSizePixel = 0
useHintButton.Font = Enum.Font.GothamBlack
useHintButton.Position = UDim2.new(0.5, 6, 1, -42)
useHintButton.Size = UDim2.new(0.5, -24, 0, 30)
useHintButton.Text = "Use Hint"
useHintButton.TextColor3 = Color3.fromRGB(16, 28, 48)
useHintButton.TextScaled = true
useHintButton.Parent = bookPanel

local useCorner = Instance.new("UICorner")
useCorner.CornerRadius = UDim.new(0, 6)
useCorner.Parent = useHintButton

local activeToastTween = nil
local activeMessageTween = nil
local toastSequence = 0
local messageSequence = 0
local activeBookRoomId = nil

local function tween(instance, duration, properties)
	local tweenObject = TweenService:Create(
		instance,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		properties
	)
	tweenObject:Play()
	return tweenObject
end

local function showDiscoveryToast(discoveryName)
	toastSequence += 1
	local currentSequence = toastSequence

	if activeToastTween then
		activeToastTween:Cancel()
	end

	toast.Text = "NEW DISCOVERY!\n" .. discoveryName
	toast.BackgroundTransparency = 0
	toast.TextTransparency = 0
	toast.Position = UDim2.fromScale(0.5, 0.14)

	tween(toast, 0.18, {
		Position = UDim2.fromScale(0.5, 0.16),
	})

	task.delay(2.4, function()
		if toastSequence ~= currentSequence then
			return
		end

		activeToastTween = tween(toast, 0.3, {
			BackgroundTransparency = 1,
			TextTransparency = 1,
		})
	end)
end

local function showSystemMessage(text)
	messageSequence += 1
	local currentSequence = messageSequence

	if activeMessageTween then
		activeMessageTween:Cancel()
	end

	message.Text = text
	message.BackgroundTransparency = 0.18
	message.TextTransparency = 0

	task.delay(2.8, function()
		if messageSequence ~= currentSequence then
			return
		end

		activeMessageTween = tween(message, 0.25, {
			BackgroundTransparency = 1,
			TextTransparency = 1,
		})
	end)
end

local function updateCounter(payload)
	if typeof(payload.Rooms) == "table" and #payload.Rooms > 0 then
		local roomText = {}

		for _, room in ipairs(payload.Rooms) do
			table.insert(roomText, ("%s %d/%d"):format(room.Name or "Room", room.Count or 0, room.Total or 0))
		end

		counter.Text = table.concat(roomText, " | ")
		return
	end

	counter.Text = ("Discoveries: %d / %d"):format(payload.Count or 0, payload.Total or Constants.TotalDiscoveries)
end

local function clearBookList()
	for _, child in ipairs(bookList:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
end

local function renderReferenceBook(payload)
	if typeof(payload) ~= "table" then
		return
	end

	activeBookRoomId = payload.RoomId
	bookPanel.Visible = true
	bookTitle.Text = (payload.RoomName or "Room") .. " Log"
	bookCount.Text = ("%d / %d found"):format(payload.Count or 0, payload.Total or 0)
	hintCount.Text = ("Hints: %d"):format(payload.Hints or 0)
	hintText.Text = payload.HintText or payload.StatusText or ""
	hintText.Visible = hintText.Text ~= ""

	clearBookList()

	for index, entry in ipairs(payload.Discoveries or {}) do
		local row = Instance.new("TextLabel")
		row.Name = "DiscoveryRow"
		row.BackgroundColor3 = entry.Unlocked and Color3.fromRGB(44, 70, 52) or Color3.fromRGB(40, 43, 50)
		row.BackgroundTransparency = 0.08
		row.BorderSizePixel = 0
		row.Font = Enum.Font.GothamBold
		row.LayoutOrder = index
		row.Size = UDim2.new(1, 0, 0, 30)
		row.Text = (entry.Unlocked and "[x] " or "[?] ") .. (entry.Name or "???")
		row.TextColor3 = entry.Unlocked and Color3.fromRGB(205, 255, 218) or Color3.fromRGB(225, 230, 238)
		row.TextScaled = true
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Parent = bookList

		local rowPadding = Instance.new("UIPadding")
		rowPadding.PaddingLeft = UDim.new(0, 8)
		rowPadding.PaddingRight = UDim.new(0, 8)
		rowPadding.Parent = row

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 5)
		rowCorner.Parent = row
	end

	bookList.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + 16)
end

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	bookList.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + 16)
end)

closeBookButton.MouseButton1Click:Connect(function()
	bookPanel.Visible = false
end)

buyHintButton.MouseButton1Click:Connect(function()
	if activeBookRoomId then
		hintPackRemote:FireServer({
			Action = "BuyPack",
			RoomId = activeBookRoomId,
		})
	end
end)

useHintButton.MouseButton1Click:Connect(function()
	if activeBookRoomId then
		hintPackRemote:FireServer({
			Action = "UseHint",
			RoomId = activeBookRoomId,
		})
	end
end)

discoveryRemote.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end

	updateCounter(payload)

	if payload.Type == "Unlocked" and payload.Name then
		showDiscoveryToast(payload.Name)
	end
end)

referenceBookRemote.OnClientEvent:Connect(renderReferenceBook)

systemMessageRemote.OnClientEvent:Connect(function(text)
	if typeof(text) == "string" and text ~= "" then
		showSystemMessage(text)
	end
end)
