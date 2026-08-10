local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local discoveryRemote = remotes:WaitForChild(Constants.Remotes.DiscoveryUpdate)
local referenceBookRemote = remotes:WaitForChild(Constants.Remotes.ReferenceBook)
local hintPackRemote = remotes:WaitForChild(Constants.Remotes.HintPackRequest)
local sessionStartRemote = remotes:WaitForChild(Constants.Remotes.SessionStart)
local systemMessageRemote = remotes:WaitForChild(Constants.Remotes.SystemMessage)
local roomStatusRemote = remotes:WaitForChild(Constants.Remotes.RoomStatus)
local sparkleRemote = remotes:WaitForChild(Constants.Remotes.SparkleHint)

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
counter.Position = UDim2.new(1, -18, 0, 96)
counter.Size = UDim2.fromOffset(280, 38)
counter.Text = "Finding room..."
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

local startOverlay = Instance.new("Frame")
startOverlay.Name = "StartChoiceOverlay"
startOverlay.BackgroundColor3 = Color3.fromRGB(8, 10, 14)
startOverlay.BackgroundTransparency = 0.28
startOverlay.BorderSizePixel = 0
startOverlay.Size = UDim2.fromScale(1, 1)
startOverlay.Visible = false
startOverlay.ZIndex = 20
startOverlay.Parent = gui

local startPanel = Instance.new("Frame")
startPanel.Name = "StartChoicePanel"
startPanel.AnchorPoint = Vector2.new(0.5, 0.5)
startPanel.BackgroundColor3 = Color3.fromRGB(24, 27, 34)
startPanel.BackgroundTransparency = 0.04
startPanel.BorderSizePixel = 0
startPanel.Position = UDim2.fromScale(0.5, 0.52)
startPanel.Size = UDim2.fromOffset(420, 246)
startPanel.ZIndex = 21
startPanel.Parent = startOverlay

local startPanelConstraint = Instance.new("UISizeConstraint")
startPanelConstraint.MaxSize = Vector2.new(420, 246)
startPanelConstraint.MinSize = Vector2.new(300, 220)
startPanelConstraint.Parent = startPanel

local startCorner = Instance.new("UICorner")
startCorner.CornerRadius = UDim.new(0, 8)
startCorner.Parent = startPanel

local startTitle = Instance.new("TextLabel")
startTitle.Name = "StartTitle"
startTitle.BackgroundTransparency = 1
startTitle.Font = Enum.Font.GothamBlack
startTitle.Position = UDim2.fromOffset(18, 18)
startTitle.Size = UDim2.new(1, -36, 0, 42)
startTitle.Text = "DON'T TOUCH IT"
startTitle.TextColor3 = Color3.fromRGB(255, 242, 181)
startTitle.TextScaled = true
startTitle.ZIndex = 22
startTitle.Parent = startPanel

local startSubtitle = Instance.new("TextLabel")
startSubtitle.Name = "StartSubtitle"
startSubtitle.BackgroundTransparency = 1
startSubtitle.Font = Enum.Font.GothamSemibold
startSubtitle.Position = UDim2.fromOffset(24, 70)
startSubtitle.Size = UDim2.new(1, -48, 0, 44)
startSubtitle.Text = ""
startSubtitle.TextColor3 = Color3.fromRGB(224, 236, 245)
startSubtitle.TextScaled = true
startSubtitle.TextWrapped = true
startSubtitle.ZIndex = 22
startSubtitle.Parent = startPanel

local continueButton = Instance.new("TextButton")
continueButton.Name = "ContinueButton"
continueButton.BackgroundColor3 = Color3.fromRGB(61, 217, 132)
continueButton.BorderSizePixel = 0
continueButton.Font = Enum.Font.GothamBlack
continueButton.Position = UDim2.new(0, 24, 1, -106)
continueButton.Size = UDim2.new(1, -48, 0, 42)
continueButton.Text = "Continue"
continueButton.TextColor3 = Color3.fromRGB(14, 40, 24)
continueButton.TextScaled = true
continueButton.ZIndex = 22
continueButton.Parent = startPanel

local continueCorner = Instance.new("UICorner")
continueCorner.CornerRadius = UDim.new(0, 6)
continueCorner.Parent = continueButton

local restartButton = Instance.new("TextButton")
restartButton.Name = "RestartButton"
restartButton.BackgroundColor3 = Color3.fromRGB(84, 154, 255)
restartButton.BorderSizePixel = 0
restartButton.Font = Enum.Font.GothamBlack
restartButton.Position = UDim2.new(0, 24, 1, -54)
restartButton.Size = UDim2.new(1, -48, 0, 34)
restartButton.Text = "Start Over"
restartButton.TextColor3 = Color3.fromRGB(14, 27, 46)
restartButton.TextScaled = true
restartButton.ZIndex = 22
restartButton.Parent = startPanel

local restartCorner = Instance.new("UICorner")
restartCorner.CornerRadius = UDim.new(0, 6)
restartCorner.Parent = restartButton

local activeToastTween = nil
local activeMessageTween = nil
local toastSequence = 0
local messageSequence = 0
local activeBookRoomId = nil
local currentStatusType = nil
local currentStatusRoomId = nil
local pendingStartOptions = nil

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
	if currentStatusType == "Hallway" then
		return
	end

	if currentStatusType == "Room" and currentStatusRoomId and typeof(payload.Rooms) == "table" then
		for _, room in ipairs(payload.Rooms) do
			if room.RoomId == currentStatusRoomId then
				counter.Text = ("%s: %d / %d"):format(room.Name or "Room", room.Count or 0, room.Total or 0)
				return
			end
		end
	end

	counter.Text = ("Discoveries: %d / %d"):format(payload.Count or 0, payload.Total or Constants.TotalDiscoveries)
end

local function updateRoomStatus(payload)
	if typeof(payload) ~= "table" then
		return
	end

	currentStatusType = payload.Type
	currentStatusRoomId = payload.RoomId

	if payload.Type == "Hallway" then
		counter.Text = ("%s: %d / %d rooms unlocked"):format(
			payload.Name or "Hallway",
			payload.UnlockedRooms or 0,
			payload.TotalRooms or 0
		)
	elseif payload.Type == "Room" then
		counter.Text = ("%s: %d / %d"):format(
			payload.RoomName or "Room",
			payload.Count or 0,
			payload.Total or 0
		)
	else
		counter.Text = ""
	end
end

local function sendStartChoice(action)
	startOverlay.Visible = false
	pendingStartOptions = nil
	sessionStartRemote:FireServer({
		Action = action,
	})
end

local function renderStartOptions(payload)
	if typeof(payload) ~= "table" or payload.Action ~= "Show" then
		return
	end

	pendingStartOptions = payload
	startOverlay.Visible = true
	startSubtitle.Text = ("Book: %d / %d found    Hints: %d"):format(
		payload.DiscoveryCount or 0,
		payload.TotalDiscoveries or Constants.TotalDiscoveries,
		payload.Hints or 0
	)

	if payload.HasProgress then
		continueButton.Text = ("Continue: %s"):format(payload.ResumeRoomName or "TV Room")
		restartButton.Visible = true
	else
		continueButton.Text = "Enter TV Room"
		restartButton.Visible = false
	end
end

local function getSparklePart(target)
	if not target then
		return nil
	end

	if target:IsA("BasePart") then
		return target
	end

	if target:IsA("Model") then
		return target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart", true)
	end

	return target:FindFirstChildWhichIsA("BasePart", true)
end

local function showSparkleHint(payload)
	if typeof(payload) ~= "table" then
		return
	end

	local target = payload.Target
	if typeof(target) ~= "Instance" or not target:IsDescendantOf(workspace) then
		return
	end

	local duration = payload.Duration or Constants.Sparkle.DurationSeconds
	local part = getSparklePart(target)

	local highlight = Instance.new("Highlight")
	highlight.Name = "PendingDiscoveryHighlight"
	highlight.Adornee = target
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = Color3.fromRGB(255, 242, 125)
	highlight.FillTransparency = 0.35
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.OutlineTransparency = 0.05
	highlight.Parent = target

	local pulseOut = tween(highlight, 0.35, {
		FillTransparency = 0.68,
		OutlineTransparency = 0.22,
	})
	pulseOut.Completed:Connect(function()
		if highlight.Parent then
			tween(highlight, 0.35, {
				FillTransparency = 0.25,
				OutlineTransparency = 0.02,
			})
		end
	end)

	if part then
		local sparkles = Instance.new("Sparkles")
		sparkles.Name = "PendingDiscoverySparkles"
		sparkles.SparkleColor = Color3.fromRGB(255, 242, 125)
		sparkles.Parent = part
		Debris:AddItem(sparkles, duration)
	end

	Debris:AddItem(highlight, duration)
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

continueButton.MouseButton1Click:Connect(function()
	sendStartChoice("Resume")
end)

restartButton.MouseButton1Click:Connect(function()
	sendStartChoice("Restart")
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
sessionStartRemote.OnClientEvent:Connect(renderStartOptions)
roomStatusRemote.OnClientEvent:Connect(updateRoomStatus)
sparkleRemote.OnClientEvent:Connect(showSparkleHint)

systemMessageRemote.OnClientEvent:Connect(function(text)
	if typeof(text) == "string" and text ~= "" then
		showSystemMessage(text)
	end
end)
