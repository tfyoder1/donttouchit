local Debris = game:GetService("Debris")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

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
local feedbackRemote = remotes:WaitForChild(Constants.Remotes.FeedbackRequest)
local DEV_DISMISS_START_ATTRIBUTE = "DontTouchItDevDismissedStartIntro"
local SYSTEM_MESSAGE_MIN_DURATION = 5.5
local SYSTEM_MESSAGE_MAX_DURATION = 9
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "DontTouchItUI"
gui.IgnoreGuiInset = false
gui.ResetOnSpawn = false
gui.Parent = playerGui

local function isStartOverlayDismissedForDevSession()
	return gui:GetAttribute(DEV_DISMISS_START_ATTRIBUTE) == true or playerGui:GetAttribute(DEV_DISMISS_START_ATTRIBUTE) == true
end

local title = Instance.new("TextLabel")
title.Name = "Title"
title.AnchorPoint = Vector2.new(0.5, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.Position = UDim2.new(0.5, 0, 0, 28)
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

local totalProgressPanel = Instance.new("Frame")
totalProgressPanel.Name = "TotalDiscoveryProgress"
totalProgressPanel.AnchorPoint = Vector2.new(0.5, 0)
totalProgressPanel.BackgroundColor3 = Color3.fromRGB(18, 20, 24)
totalProgressPanel.BackgroundTransparency = 0.14
totalProgressPanel.BorderSizePixel = 0
totalProgressPanel.Position = UDim2.new(0.5, 0, 0, 74)
totalProgressPanel.Size = UDim2.new(0.9, 0, 0, 42)
totalProgressPanel.Parent = gui

local totalProgressPanelConstraint = Instance.new("UISizeConstraint")
totalProgressPanelConstraint.MaxSize = Vector2.new(720, 42)
totalProgressPanelConstraint.MinSize = Vector2.new(300, 38)
totalProgressPanelConstraint.Parent = totalProgressPanel

local totalProgressCorner = Instance.new("UICorner")
totalProgressCorner.CornerRadius = UDim.new(0, 8)
totalProgressCorner.Parent = totalProgressPanel

local totalProgressLabel = Instance.new("TextLabel")
totalProgressLabel.Name = "TotalProgressLabel"
totalProgressLabel.BackgroundTransparency = 1
totalProgressLabel.Font = Enum.Font.GothamBlack
totalProgressLabel.Position = UDim2.fromOffset(12, 2)
totalProgressLabel.Size = UDim2.new(1, -24, 0, 24)
totalProgressLabel.Text = "Touched 0 / 0 things that asked nicely."
totalProgressLabel.TextColor3 = Color3.fromRGB(236, 246, 255)
totalProgressLabel.TextScaled = true
totalProgressLabel.TextWrapped = true
totalProgressLabel.Parent = totalProgressPanel

local totalProgressTrack = Instance.new("Frame")
totalProgressTrack.Name = "TotalProgressTrack"
totalProgressTrack.BackgroundColor3 = Color3.fromRGB(42, 47, 56)
totalProgressTrack.BorderSizePixel = 0
totalProgressTrack.Position = UDim2.new(0, 12, 1, -12)
totalProgressTrack.Size = UDim2.new(1, -24, 0, 6)
totalProgressTrack.Parent = totalProgressPanel

local totalProgressTrackCorner = Instance.new("UICorner")
totalProgressTrackCorner.CornerRadius = UDim.new(0, 3)
totalProgressTrackCorner.Parent = totalProgressTrack

local totalProgressFill = Instance.new("Frame")
totalProgressFill.Name = "TotalProgressFill"
totalProgressFill.BackgroundColor3 = Color3.fromRGB(255, 221, 84)
totalProgressFill.BorderSizePixel = 0
totalProgressFill.Size = UDim2.fromScale(0, 1)
totalProgressFill.Parent = totalProgressTrack

local totalProgressFillCorner = Instance.new("UICorner")
totalProgressFillCorner.CornerRadius = UDim.new(0, 3)
totalProgressFillCorner.Parent = totalProgressFill

local counter = Instance.new("TextLabel")
counter.Name = "DiscoveryCounter"
counter.AnchorPoint = Vector2.new(0, 0)
counter.BackgroundColor3 = Color3.fromRGB(18, 20, 24)
counter.BackgroundTransparency = 0.18
counter.BorderSizePixel = 0
counter.Font = Enum.Font.GothamBold
counter.Position = UDim2.new(0, 18, 0, 126)
counter.Size = UDim2.fromOffset(280, 38)
counter.Text = "Finding room..."
counter.TextColor3 = Color3.fromRGB(236, 246, 255)
counter.TextScaled = true
counter.Parent = gui

local counterCorner = Instance.new("UICorner")
counterCorner.CornerRadius = UDim.new(0, 6)
counterCorner.Parent = counter

local noTouchPanel = Instance.new("Frame")
noTouchPanel.Name = "NoTouchProgress"
noTouchPanel.AnchorPoint = Vector2.new(0, 0)
noTouchPanel.BackgroundColor3 = Color3.fromRGB(18, 20, 24)
noTouchPanel.BackgroundTransparency = 0.18
noTouchPanel.BorderSizePixel = 0
noTouchPanel.Position = UDim2.new(0, 18, 0, 170)
noTouchPanel.Size = UDim2.fromOffset(280, 56)
noTouchPanel.Visible = false
noTouchPanel.Parent = gui

local noTouchCorner = Instance.new("UICorner")
noTouchCorner.CornerRadius = UDim.new(0, 6)
noTouchCorner.Parent = noTouchPanel

local noTouchLabel = Instance.new("TextLabel")
noTouchLabel.Name = "NoTouchLabel"
noTouchLabel.BackgroundTransparency = 1
noTouchLabel.Font = Enum.Font.GothamBold
noTouchLabel.Position = UDim2.fromOffset(10, 4)
noTouchLabel.Size = UDim2.new(1, -20, 0, 28)
noTouchLabel.Text = "No interaction: 0.0 / 2.0 min"
noTouchLabel.TextColor3 = Color3.fromRGB(236, 246, 255)
noTouchLabel.TextScaled = true
noTouchLabel.TextXAlignment = Enum.TextXAlignment.Left
noTouchLabel.Parent = noTouchPanel

local noTouchTrack = Instance.new("Frame")
noTouchTrack.Name = "NoTouchTrack"
noTouchTrack.BackgroundColor3 = Color3.fromRGB(42, 47, 56)
noTouchTrack.BorderSizePixel = 0
noTouchTrack.Position = UDim2.fromOffset(10, 38)
noTouchTrack.Size = UDim2.new(1, -20, 0, 10)
noTouchTrack.Parent = noTouchPanel

local noTouchTrackCorner = Instance.new("UICorner")
noTouchTrackCorner.CornerRadius = UDim.new(0, 5)
noTouchTrackCorner.Parent = noTouchTrack

local noTouchFill = Instance.new("Frame")
noTouchFill.Name = "NoTouchFill"
noTouchFill.BackgroundColor3 = Color3.fromRGB(255, 221, 84)
noTouchFill.BorderSizePixel = 0
noTouchFill.Size = UDim2.fromScale(0, 1)
noTouchFill.Parent = noTouchTrack

local noTouchFillCorner = Instance.new("UICorner")
noTouchFillCorner.CornerRadius = UDim.new(0, 5)
noTouchFillCorner.Parent = noTouchFill

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
message.Position = UDim2.new(0.5, 0, 1, -118)
message.Size = UDim2.new(0.88, 0, 0, 72)
message.Text = ""
message.TextColor3 = Color3.fromRGB(255, 255, 255)
message.TextScaled = true
message.TextWrapped = true
message.TextTransparency = 1
message.Parent = gui

local messageSizeConstraint = Instance.new("UISizeConstraint")
messageSizeConstraint.MaxSize = Vector2.new(620, 72)
messageSizeConstraint.MinSize = Vector2.new(280, 44)
messageSizeConstraint.Parent = message

local messageCorner = Instance.new("UICorner")
messageCorner.CornerRadius = UDim.new(0, 6)
messageCorner.Parent = message

local function updateMessagePosition()
	local bottomOffset = 118
	if UserInputService.TouchEnabled then
		bottomOffset = 152
	elseif UserInputService.GamepadEnabled then
		bottomOffset = 132
	end

	local camera = workspace.CurrentCamera
	if camera and camera.ViewportSize.Y < 560 then
		bottomOffset = math.max(96, bottomOffset - 22)
	end

	message.Position = UDim2.new(0.5, 0, 1, -bottomOffset)
end

updateMessagePosition()
UserInputService.LastInputTypeChanged:Connect(updateMessagePosition)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(updateMessagePosition)
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateMessagePosition)
end

local bookPanel = Instance.new("Frame")
bookPanel.Name = "ReferenceBook"
bookPanel.AnchorPoint = Vector2.new(0.5, 0.5)
bookPanel.BackgroundColor3 = Color3.fromRGB(28, 30, 36)
bookPanel.BackgroundTransparency = 0.04
bookPanel.BorderSizePixel = 0
bookPanel.Position = UDim2.fromScale(0.5, 0.52)
bookPanel.Size = UDim2.new(0.9, 0, 0.84, 0)
bookPanel.Visible = false
bookPanel.Active = true
bookPanel.Parent = gui

local bookPanelConstraint = Instance.new("UISizeConstraint")
bookPanelConstraint.MaxSize = Vector2.new(620, 520)
bookPanelConstraint.MinSize = Vector2.new(300, 300)
bookPanelConstraint.Parent = bookPanel

local bookCorner = Instance.new("UICorner")
bookCorner.CornerRadius = UDim.new(0, 8)
bookCorner.Parent = bookPanel

local bookTitle = Instance.new("TextLabel")
bookTitle.Name = "BookTitle"
bookTitle.BackgroundTransparency = 1
bookTitle.Font = Enum.Font.GothamBlack
bookTitle.Position = UDim2.fromOffset(18, 14)
bookTitle.Size = UDim2.new(1, -92, 0, 32)
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
closeBookButton.Size = UDim2.fromOffset(52, 46)
closeBookButton.Text = "X"
closeBookButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBookButton.TextScaled = true
closeBookButton.Modal = false
closeBookButton.Parent = bookPanel

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBookButton

local bookCount = Instance.new("TextLabel")
bookCount.Name = "BookCount"
bookCount.BackgroundTransparency = 1
bookCount.Font = Enum.Font.GothamBold
bookCount.Position = UDim2.fromOffset(18, 50)
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
bookList.Position = UDim2.fromOffset(18, 334)
bookList.Size = UDim2.new(1, -36, 1, -352)
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

local hintTray = Instance.new("Frame")
hintTray.Name = "HintTray"
hintTray.BackgroundColor3 = Color3.fromRGB(18, 20, 24)
hintTray.BackgroundTransparency = 0.08
hintTray.BorderSizePixel = 0
hintTray.Position = UDim2.fromOffset(18, 84)
hintTray.Size = UDim2.new(1, -36, 0, 238)
hintTray.Parent = bookPanel

local hintTrayCorner = Instance.new("UICorner")
hintTrayCorner.CornerRadius = UDim.new(0, 6)
hintTrayCorner.Parent = hintTray

local hintTrayPadding = Instance.new("UIPadding")
hintTrayPadding.PaddingBottom = UDim.new(0, 8)
hintTrayPadding.PaddingLeft = UDim.new(0, 10)
hintTrayPadding.PaddingRight = UDim.new(0, 10)
hintTrayPadding.PaddingTop = UDim.new(0, 8)
hintTrayPadding.Parent = hintTray

local hintCount = Instance.new("TextLabel")
hintCount.Name = "HintCount"
hintCount.BackgroundTransparency = 1
hintCount.Font = Enum.Font.GothamBold
hintCount.Position = UDim2.fromOffset(10, 6)
hintCount.Size = UDim2.new(1, -20, 0, 22)
hintCount.Text = "Hints: 0"
hintCount.TextColor3 = Color3.fromRGB(220, 235, 245)
hintCount.TextScaled = true
hintCount.TextXAlignment = Enum.TextXAlignment.Left
hintCount.Parent = hintTray

local hintText = Instance.new("TextLabel")
hintText.Name = "HintText"
hintText.BackgroundColor3 = Color3.fromRGB(255, 242, 181)
hintText.BackgroundTransparency = 0.1
hintText.BorderSizePixel = 0
hintText.Font = Enum.Font.GothamSemibold
hintText.Position = UDim2.fromOffset(10, 32)
hintText.Size = UDim2.new(1, -20, 0, 34)
hintText.Text = ""
hintText.TextColor3 = Color3.fromRGB(28, 30, 36)
hintText.TextScaled = true
hintText.TextWrapped = true
hintText.Parent = hintTray

local hintCorner = Instance.new("UICorner")
hintCorner.CornerRadius = UDim.new(0, 6)
hintCorner.Parent = hintText

local buyHintButton = Instance.new("TextButton")
buyHintButton.Name = "FreeHint"
buyHintButton.BackgroundColor3 = Color3.fromRGB(61, 217, 132)
buyHintButton.BorderSizePixel = 0
buyHintButton.Font = Enum.Font.GothamBlack
buyHintButton.Position = UDim2.new(0, 10, 0, 70)
buyHintButton.Size = UDim2.new(0.5, -15, 0, 36)
buyHintButton.Text = "Free\nHint"
buyHintButton.TextColor3 = Color3.fromRGB(18, 45, 26)
buyHintButton.TextScaled = true
buyHintButton.TextWrapped = true
buyHintButton.Parent = hintTray

local buyCorner = Instance.new("UICorner")
buyCorner.CornerRadius = UDim.new(0, 6)
buyCorner.Parent = buyHintButton

local useHintButton = Instance.new("TextButton")
useHintButton.Name = "Clue"
useHintButton.BackgroundColor3 = Color3.fromRGB(84, 154, 255)
useHintButton.BorderSizePixel = 0
useHintButton.Font = Enum.Font.GothamBlack
useHintButton.Position = UDim2.new(0, 10, 0, 112)
useHintButton.Size = UDim2.new(0.5, -15, 0, 36)
useHintButton.Text = if Constants.NoTouch.ClueProductId > 0
	then ("Clue\n%d R$"):format(Constants.NoTouch.ClueRobux)
	else ("Clue\n%d hints"):format(Constants.NoTouch.ClueHintCost)
useHintButton.TextColor3 = Color3.fromRGB(16, 28, 48)
useHintButton.TextScaled = true
useHintButton.TextWrapped = true
useHintButton.Parent = hintTray

local useCorner = Instance.new("UICorner")
useCorner.CornerRadius = UDim.new(0, 6)
useCorner.Parent = useHintButton

local buyPackButton = Instance.new("TextButton")
buyPackButton.Name = "BuyPack"
buyPackButton.BackgroundColor3 = Color3.fromRGB(35, 93, 58)
buyPackButton.BorderSizePixel = 0
buyPackButton.Font = Enum.Font.GothamBlack
buyPackButton.Position = UDim2.new(0.5, 5, 0, 70)
buyPackButton.Size = UDim2.new(0.5, -15, 0, 36)
buyPackButton.Text = if Constants.NoTouch.HintPackProductId > 0
	then ("Buy Hints\n%d R$"):format(Constants.NoTouch.HintPackRobux)
	else "Buy Hints\nFree"
buyPackButton.TextColor3 = Color3.fromRGB(214, 255, 226)
buyPackButton.TextScaled = true
buyPackButton.TextWrapped = true
buyPackButton.Parent = hintTray

local buyPackCorner = Instance.new("UICorner")
buyPackCorner.CornerRadius = UDim.new(0, 6)
buyPackCorner.Parent = buyPackButton

local revealHintButton = Instance.new("TextButton")
revealHintButton.Name = "Reveal"
revealHintButton.BackgroundColor3 = Color3.fromRGB(255, 198, 82)
revealHintButton.BorderSizePixel = 0
revealHintButton.Font = Enum.Font.GothamBlack
revealHintButton.Position = UDim2.new(0, 10, 0, 154)
revealHintButton.Size = UDim2.new(0.5, -15, 0, 36)
revealHintButton.Text = if Constants.NoTouch.RevealProductId > 0
	then ("Reveal\n%d R$"):format(Constants.NoTouch.RevealRobux)
	else ("Reveal\n%d clues"):format(Constants.NoTouch.RevealClueCost)
revealHintButton.TextColor3 = Color3.fromRGB(57, 38, 4)
revealHintButton.TextScaled = true
revealHintButton.TextWrapped = true
revealHintButton.Parent = hintTray

local revealCorner = Instance.new("UICorner")
revealCorner.CornerRadius = UDim.new(0, 6)
revealCorner.Parent = revealHintButton

local buyClueButton = Instance.new("TextButton")
buyClueButton.Name = "BuyClue"
buyClueButton.BackgroundColor3 = Color3.fromRGB(38, 78, 133)
buyClueButton.BorderSizePixel = 0
buyClueButton.Font = Enum.Font.GothamBlack
buyClueButton.Position = UDim2.new(0.5, 5, 0, 112)
buyClueButton.Size = UDim2.new(0.5, -15, 0, 36)
buyClueButton.Text = if Constants.NoTouch.ClueProductId > 0
	then ("Buy Clue\n%d R$"):format(Constants.NoTouch.ClueRobux)
	else "Buy Clue\nFree"
buyClueButton.TextColor3 = Color3.fromRGB(218, 236, 255)
buyClueButton.TextScaled = true
buyClueButton.TextWrapped = true
buyClueButton.Parent = hintTray

local buyClueCorner = Instance.new("UICorner")
buyClueCorner.CornerRadius = UDim.new(0, 6)
buyClueCorner.Parent = buyClueButton

local buyRevealButton = Instance.new("TextButton")
buyRevealButton.Name = "BuyReveal"
buyRevealButton.BackgroundColor3 = Color3.fromRGB(124, 87, 32)
buyRevealButton.BorderSizePixel = 0
buyRevealButton.Font = Enum.Font.GothamBlack
buyRevealButton.Position = UDim2.new(0.5, 5, 0, 154)
buyRevealButton.Size = UDim2.new(0.5, -15, 0, 36)
buyRevealButton.Text = if Constants.NoTouch.RevealProductId > 0
	then ("Buy Reveal\n%d R$"):format(Constants.NoTouch.RevealRobux)
	else "Buy Reveal\nFree"
buyRevealButton.TextColor3 = Color3.fromRGB(255, 238, 196)
buyRevealButton.TextScaled = true
buyRevealButton.TextWrapped = true
buyRevealButton.Parent = hintTray

local buyRevealCorner = Instance.new("UICorner")
buyRevealCorner.CornerRadius = UDim.new(0, 6)
buyRevealCorner.Parent = buyRevealButton

local secretDoorButton = Instance.new("TextButton")
secretDoorButton.Name = "SecretDoorReveal"
secretDoorButton.BackgroundColor3 = Color3.fromRGB(150, 112, 255)
secretDoorButton.BorderSizePixel = 0
secretDoorButton.Font = Enum.Font.GothamBlack
secretDoorButton.Position = UDim2.new(0.5, 5, 0, 196)
secretDoorButton.Size = UDim2.new(0.5, -15, 0, 36)
secretDoorButton.Text = "Secret\nDoor"
secretDoorButton.TextColor3 = Color3.fromRGB(242, 236, 255)
secretDoorButton.TextScaled = true
secretDoorButton.TextWrapped = true
secretDoorButton.Visible = false
secretDoorButton.Parent = hintTray

local secretDoorCorner = Instance.new("UICorner")
secretDoorCorner.CornerRadius = UDim.new(0, 6)
secretDoorCorner.Parent = secretDoorButton

local feedbackButton = Instance.new("TextButton")
feedbackButton.Name = "Feedback"
feedbackButton.BackgroundColor3 = Color3.fromRGB(15, 52, 34)
feedbackButton.BorderSizePixel = 0
feedbackButton.Font = Enum.Font.GothamBlack
feedbackButton.Position = UDim2.new(0, 10, 0, 196)
feedbackButton.Size = UDim2.new(0.5, -15, 0, 36)
feedbackButton.Text = "Feedback / Request"
feedbackButton.TextColor3 = Color3.fromRGB(136, 255, 178)
feedbackButton.TextScaled = true
feedbackButton.Parent = hintTray

local feedbackButtonCorner = Instance.new("UICorner")
feedbackButtonCorner.CornerRadius = UDim.new(0, 6)
feedbackButtonCorner.Parent = feedbackButton

local feedbackPanel = Instance.new("Frame")
feedbackPanel.Name = "FeedbackPanel"
feedbackPanel.BackgroundColor3 = Color3.fromRGB(5, 12, 9)
feedbackPanel.BackgroundTransparency = 0.02
feedbackPanel.BorderSizePixel = 0
feedbackPanel.Position = UDim2.fromOffset(18, 84)
feedbackPanel.Size = UDim2.new(1, -36, 0, 238)
feedbackPanel.Visible = false
feedbackPanel.Active = true
feedbackPanel.ZIndex = 30
feedbackPanel.Parent = bookPanel

local feedbackPanelCorner = Instance.new("UICorner")
feedbackPanelCorner.CornerRadius = UDim.new(0, 6)
feedbackPanelCorner.Parent = feedbackPanel

local feedbackTitle = Instance.new("TextLabel")
feedbackTitle.Name = "FeedbackTitle"
feedbackTitle.BackgroundTransparency = 1
feedbackTitle.Font = Enum.Font.GothamBlack
feedbackTitle.Position = UDim2.fromOffset(12, 8)
feedbackTitle.Size = UDim2.new(1, -96, 0, 30)
feedbackTitle.Text = "Feedback"
feedbackTitle.TextColor3 = Color3.fromRGB(86, 255, 150)
feedbackTitle.TextScaled = true
feedbackTitle.TextXAlignment = Enum.TextXAlignment.Left
feedbackTitle.ZIndex = 31
feedbackTitle.Parent = feedbackPanel

local closeFeedbackButton = Instance.new("TextButton")
closeFeedbackButton.Name = "CloseFeedback"
closeFeedbackButton.AnchorPoint = Vector2.new(1, 0)
closeFeedbackButton.BackgroundColor3 = Color3.fromRGB(34, 44, 52)
closeFeedbackButton.BorderSizePixel = 0
closeFeedbackButton.Font = Enum.Font.GothamBlack
closeFeedbackButton.Position = UDim2.new(1, -10, 0, 8)
closeFeedbackButton.Size = UDim2.fromOffset(72, 30)
closeFeedbackButton.Text = "Done"
closeFeedbackButton.TextColor3 = Color3.fromRGB(220, 235, 245)
closeFeedbackButton.TextScaled = true
closeFeedbackButton.ZIndex = 31
closeFeedbackButton.Parent = feedbackPanel

local closeFeedbackCorner = Instance.new("UICorner")
closeFeedbackCorner.CornerRadius = UDim.new(0, 6)
closeFeedbackCorner.Parent = closeFeedbackButton

local feedbackBody = Instance.new("TextLabel")
feedbackBody.Name = "FeedbackBody"
feedbackBody.BackgroundTransparency = 1
feedbackBody.Font = Enum.Font.GothamSemibold
feedbackBody.Position = UDim2.fromOffset(12, 42)
feedbackBody.Size = UDim2.new(1, -24, 0, 32)
feedbackBody.Text = "Send a quick tagged report for this room."
feedbackBody.TextColor3 = Color3.fromRGB(202, 244, 214)
feedbackBody.TextScaled = true
feedbackBody.TextWrapped = true
feedbackBody.TextXAlignment = Enum.TextXAlignment.Left
feedbackBody.ZIndex = 31
feedbackBody.Parent = feedbackPanel

local feedbackStatus = Instance.new("TextLabel")
feedbackStatus.Name = "FeedbackStatus"
feedbackStatus.BackgroundTransparency = 1
feedbackStatus.Font = Enum.Font.GothamBold
feedbackStatus.Position = UDim2.fromOffset(12, 202)
feedbackStatus.Size = UDim2.new(1, -24, 0, 26)
feedbackStatus.Text = ""
feedbackStatus.TextColor3 = Color3.fromRGB(136, 255, 178)
feedbackStatus.TextScaled = true
feedbackStatus.TextWrapped = true
feedbackStatus.TextXAlignment = Enum.TextXAlignment.Left
feedbackStatus.ZIndex = 31
feedbackStatus.Parent = feedbackPanel

local feedbackCategoryButtons = {}
for index, category in ipairs(Constants.Feedback.Categories or {}) do
	local column = (index - 1) % 2
	local row = math.floor((index - 1) / 2)
	local categoryButton = Instance.new("TextButton")
	categoryButton.Name = "Feedback_" .. category.Id
	categoryButton.BackgroundColor3 = Color3.fromRGB(16, 55, 36)
	categoryButton.BorderSizePixel = 0
	categoryButton.Font = Enum.Font.GothamBlack
	categoryButton.Position = UDim2.new(column * 0.5, 10 + column * 5, 0, 78 + row * 40)
	categoryButton.Size = UDim2.new(0.5, -15, 0, 34)
	categoryButton.Text = category.Label
	categoryButton.TextColor3 = Color3.fromRGB(136, 255, 178)
	categoryButton.TextScaled = true
	categoryButton.TextWrapped = true
	categoryButton.ZIndex = 31
	categoryButton.Parent = feedbackPanel

	local categoryCorner = Instance.new("UICorner")
	categoryCorner.CornerRadius = UDim.new(0, 6)
	categoryCorner.Parent = categoryButton

	table.insert(feedbackCategoryButtons, {
		Button = categoryButton,
		CategoryId = category.Id,
	})
end

local startOverlay = Instance.new("Frame")
startOverlay.Name = "StartChoiceOverlay"
startOverlay.BackgroundColor3 = Color3.fromRGB(8, 10, 14)
startOverlay.BackgroundTransparency = 0.28
startOverlay.BorderSizePixel = 0
startOverlay.Size = UDim2.fromScale(1, 1)
startOverlay.Visible = false
startOverlay.Active = true
startOverlay.ZIndex = 20
startOverlay.Parent = gui

local startPanel = Instance.new("Frame")
startPanel.Name = "StartChoicePanel"
startPanel.AnchorPoint = Vector2.new(0.5, 0.5)
startPanel.BackgroundColor3 = Color3.fromRGB(24, 27, 34)
startPanel.BackgroundTransparency = 0.04
startPanel.BorderSizePixel = 0
startPanel.Position = UDim2.fromScale(0.5, 0.52)
startPanel.Size = UDim2.new(0.92, 0, 0.84, 0)
startPanel.ZIndex = 21
startPanel.Parent = startOverlay

local startPanelConstraint = Instance.new("UISizeConstraint")
startPanelConstraint.MaxSize = Vector2.new(520, 520)
startPanelConstraint.MinSize = Vector2.new(320, 390)
startPanelConstraint.Parent = startPanel

local startCorner = Instance.new("UICorner")
startCorner.CornerRadius = UDim.new(0, 8)
startCorner.Parent = startPanel

local startTitle = Instance.new("TextLabel")
startTitle.Name = "StartTitle"
startTitle.BackgroundTransparency = 1
startTitle.Font = Enum.Font.GothamBlack
startTitle.Position = UDim2.fromOffset(18, 18)
startTitle.Size = UDim2.new(1, -36, 0, 36)
startTitle.Text = "DON'T TOUCH IT"
startTitle.TextColor3 = Color3.fromRGB(255, 242, 181)
startTitle.TextScaled = true
startTitle.ZIndex = 22
startTitle.Parent = startPanel

local startIntro = Instance.new("TextLabel")
startIntro.Name = "StartIntro"
startIntro.BackgroundTransparency = 1
startIntro.Font = Enum.Font.GothamSemibold
startIntro.Position = UDim2.fromOffset(24, 62)
startIntro.Size = UDim2.new(1, -48, 0, 66)
startIntro.Text = Constants.GameIntro
startIntro.TextColor3 = Color3.fromRGB(224, 236, 245)
startIntro.TextScaled = true
startIntro.TextWrapped = true
startIntro.ZIndex = 22
startIntro.Parent = startPanel

local startSubtitle = Instance.new("TextLabel")
startSubtitle.Name = "StartSubtitle"
startSubtitle.BackgroundTransparency = 1
startSubtitle.Font = Enum.Font.GothamSemibold
startSubtitle.Position = UDim2.fromOffset(24, 132)
startSubtitle.Size = UDim2.new(1, -48, 0, 38)
startSubtitle.Text = ""
startSubtitle.TextColor3 = Color3.fromRGB(224, 236, 245)
startSubtitle.TextScaled = true
startSubtitle.TextWrapped = true
startSubtitle.ZIndex = 22
startSubtitle.Parent = startPanel

local startRoomTitle = Instance.new("TextLabel")
startRoomTitle.Name = "StartRoomTitle"
startRoomTitle.BackgroundTransparency = 1
startRoomTitle.Font = Enum.Font.GothamBlack
startRoomTitle.Position = UDim2.fromOffset(24, 178)
startRoomTitle.Size = UDim2.new(1, -48, 0, 22)
startRoomTitle.Text = "Choose Unlocked Room"
startRoomTitle.TextColor3 = Color3.fromRGB(255, 242, 181)
startRoomTitle.TextScaled = true
startRoomTitle.TextXAlignment = Enum.TextXAlignment.Left
startRoomTitle.ZIndex = 22
startRoomTitle.Parent = startPanel

local startRoomList = Instance.new("ScrollingFrame")
startRoomList.Name = "StartRoomList"
startRoomList.BackgroundColor3 = Color3.fromRGB(16, 19, 26)
startRoomList.BackgroundTransparency = 0.1
startRoomList.BorderSizePixel = 0
startRoomList.Position = UDim2.fromOffset(24, 204)
startRoomList.Size = UDim2.new(1, -48, 1, -326)
startRoomList.CanvasSize = UDim2.fromOffset(0, 0)
startRoomList.ScrollBarThickness = 6
startRoomList.ScrollingDirection = Enum.ScrollingDirection.Y
startRoomList.ZIndex = 22
startRoomList.Parent = startPanel

local startRoomListCorner = Instance.new("UICorner")
startRoomListCorner.CornerRadius = UDim.new(0, 6)
startRoomListCorner.Parent = startRoomList

local startRoomPadding = Instance.new("UIPadding")
startRoomPadding.PaddingTop = UDim.new(0, 8)
startRoomPadding.PaddingBottom = UDim.new(0, 8)
startRoomPadding.PaddingLeft = UDim.new(0, 8)
startRoomPadding.PaddingRight = UDim.new(0, 8)
startRoomPadding.Parent = startRoomList

local startRoomLayout = Instance.new("UIListLayout")
startRoomLayout.Padding = UDim.new(0, 6)
startRoomLayout.SortOrder = Enum.SortOrder.LayoutOrder
startRoomLayout.Parent = startRoomList

startRoomLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	startRoomList.CanvasSize = UDim2.fromOffset(0, startRoomLayout.AbsoluteContentSize.Y + 16)
end)

local startVersion = Instance.new("TextLabel")
startVersion.Name = "Version"
startVersion.AnchorPoint = Vector2.new(1, 1)
startVersion.BackgroundTransparency = 1
startVersion.Font = Enum.Font.GothamBold
startVersion.Position = UDim2.new(1, -12, 1, -8)
startVersion.Size = UDim2.fromOffset(120, 18)
startVersion.Text = "v" .. tostring(Constants.BuildVersion or "dev")
startVersion.TextColor3 = Color3.fromRGB(150, 160, 175)
startVersion.TextScaled = true
startVersion.TextXAlignment = Enum.TextXAlignment.Right
startVersion.ZIndex = 22
startVersion.Parent = startPanel

local continueButton = Instance.new("TextButton")
continueButton.Name = "ContinueButton"
continueButton.BackgroundColor3 = Color3.fromRGB(61, 217, 132)
continueButton.BorderSizePixel = 0
continueButton.Font = Enum.Font.GothamBlack
continueButton.Position = UDim2.new(0, 24, 1, -104)
continueButton.Size = UDim2.new(1, -48, 0, 38)
continueButton.Text = "Continue"
continueButton.TextColor3 = Color3.fromRGB(14, 40, 24)
continueButton.TextScaled = true
continueButton.Modal = false
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
restartButton.Position = UDim2.new(0, 24, 1, -58)
restartButton.Size = UDim2.new(1, -48, 0, 34)
restartButton.Text = "Start Over"
restartButton.TextColor3 = Color3.fromRGB(14, 27, 46)
restartButton.TextScaled = true
restartButton.Modal = false
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
local activeSecretDoorAction = "RevealSecretDoor"
local currentStatusType = nil
local currentStatusRoomId = nil
local pendingStartOptions = nil
local sessionStartIntroText = nil
local startRoomButtons = {}
local overlayMouseDepth = 0
local previousMouseBehavior = nil
local previousMouseIconEnabled = nil
local previousSelectedObject = nil

local START_INTRO_LINES = {
	"%s, our records show you touched %d / %d things that were doing an excellent job not being touched.",
	"Welcome back, %s. You have touched %d of %d objects that specifically requested distance.",
	"%s has touched %d / %d suspicious objects so far. Bold. Incorrect, but bold.",
	"Official audit: %s touched %d out of %d things they should not have touched at all.",
	"%s, the room says you touched %d / %d forbidden things. The room is pretending everything is fine.",
	"Current evidence: %s touched %d of %d objects marked by common sense as probably a bad idea.",
}

local TOTAL_PROGRESS_LINES = {
	"Touched %d / %d things. The furniture is taking notes.",
	"Tapped %d / %d forbidden items. Excellent curiosity, questionable restraint.",
	"%d / %d objects have received your personal attention.",
	"You touched %d / %d things that were clearly enjoying their quiet time.",
	"%d / %d do-not-touch items have been thoroughly misunderstood.",
	"The room reports %d / %d touches and one raised eyebrow.",
	"%d / %d objects have entered the official oops ledger.",
	"You discovered %d / %d reasons the sign was probably serious.",
	"%d / %d things were minding their business until just now.",
	"Touched %d / %d items. The warning label sighs politely.",
	"%d / %d objects have been promoted to evidence.",
	"You poked %d / %d possibilities. Science is complicated.",
	"%d / %d items now know what your interact button feels like.",
	"Discovery tally: %d / %d touches the room specifically did not request.",
	"%d / %d objects were asked a very hands-on question.",
	"You have bothered %d / %d perfectly suspicious objects.",
	"%d / %d things have learned you are not great at ignoring them.",
	"The no-touch scoreboard says %d / %d. It is blinking slowly.",
	"%d / %d objects have been touched for reasons still under review.",
	"You pressed onward through %d / %d bad ideas.",
	"%d / %d items have filed a tiny complaint.",
	"Touched %d / %d things. The room appreciates your honesty.",
	"%d / %d discoveries found by not following directions very carefully.",
	"You interacted with %d / %d objects labeled by vibes alone.",
	"%d / %d items have been added to the 'well, that happened' list.",
	"The room counted %d / %d touches and adjusted its expectations.",
	"%d / %d things have been personally inspected against advice.",
	"You found %d / %d ways to make the room nervous.",
	"%d / %d objects are no longer innocent bystanders.",
	"Touched %d / %d things. The sign remains undefeated.",
	"%d / %d questionable choices have become measurable progress.",
	"The room whispers %d / %d and hides the nice plates.",
	"%d / %d items have received unexpected customer service.",
	"You activated %d / %d things that were hoping for retirement.",
	"%d / %d objects have joined the touch report.",
	"Current mischief reading: %d / %d.",
	"%d / %d items have been gently accused of being interactive.",
	"You found %d / %d things the game hoped you would ignore.",
	"%d / %d objects have been handled with maximum curiosity.",
	"Touched %d / %d. The room is updating its safety poster.",
	"%d / %d discoveries unlocked by extremely suspicious helpfulness.",
	"You gave %d / %d objects a reason to make noises.",
	"%d / %d things are now part of the official touching history.",
	"The walls observed %d / %d touches and said nothing.",
	"%d / %d items have been explored with brave uncertainty.",
	"You interacted with %d / %d things that looked too interesting.",
	"%d / %d objects have moved from 'maybe' to 'definitely touched'.",
	"Touch report: %d / %d. The room requests a clipboard.",
	"%d / %d suspicious objects have been responsibly irresponsible.",
	"You uncovered %d / %d things by doing the exact tempting thing.",
	"%d / %d items have been added to the button-adjacent database.",
	"Touched %d / %d things. The carpet is pretending not to judge.",
	"%d / %d discoveries found through enthusiastic rule testing.",
	"You investigated %d / %d no-touch suggestions.",
	"%d / %d objects have been politely startled.",
	"The room has counted %d / %d touches and one dramatic pause.",
	"%d / %d things have been contacted by your curiosity department.",
	"You have touched %d / %d objects that looked touchable on purpose.",
	"%d / %d items are now in the 'probably should not have' column.",
	"Touched %d / %d things. The warning sign is still pointing.",
	"%d / %d discoveries unlocked. The room blames the buttons.",
	"You found %d / %d ways to make ordinary items suspicious.",
	"%d / %d objects have been nudged into doing something weird.",
	"The official count is %d / %d touches. Very official. Very worried.",
	"%d / %d items have been encouraged to reveal their secrets.",
	"You touched %d / %d things and somehow this is progress.",
	"%d / %d do-not-touch candidates have been interviewed.",
	"The room counted %d / %d discoveries and locked eyes with the exit.",
	"%d / %d objects have been promoted from decoration to incident.",
	"You found %d / %d excellent reasons to keep looking around.",
	"%d / %d items have received the classic player inspection.",
	"Touched %d / %d. The room is practicing deep breaths.",
	"%d / %d discoveries logged by carefully ignoring the title.",
	"You interacted with %d / %d things that had suspicious body language.",
	"%d / %d objects have been placed in the evidence snack tray.",
	"The no-touch committee records %d / %d touches.",
	"%d / %d items have become part of today's lesson.",
	"You discovered %d / %d things by following the sparkle of bad ideas.",
	"%d / %d objects have been asked to explain themselves.",
	"Touched %d / %d. The room says it saw everything.",
	"%d / %d discoveries found. The title is doing its best.",
	"You have touched %d / %d things that were almost certainly not homework.",
	"%d / %d objects have joined the grand tour of questionable choices.",
}

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

	task.delay(3, function()
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

	local duration = math.clamp(4.5 + #text / 35, SYSTEM_MESSAGE_MIN_DURATION, SYSTEM_MESSAGE_MAX_DURATION)
	task.delay(duration, function()
		if messageSequence ~= currentSequence then
			return
		end

		activeMessageTween = tween(message, 0.25, {
			BackgroundTransparency = 1,
			TextTransparency = 1,
		})
	end)
end

local function getIntroName()
	if player.DisplayName and player.DisplayName ~= "" then
		return player.DisplayName
	end

	return player.Name
end

local function formatRandomStartIntro(payload)
	local count = payload.DiscoveryCount or 0
	local total = payload.TotalDiscoveries or Constants.TotalDiscoveries
	local template = START_INTRO_LINES[math.random(1, #START_INTRO_LINES)]
	return template:format(getIntroName(), count, total)
end

local function setStartIntro(payload)
	if not sessionStartIntroText then
		sessionStartIntroText = formatRandomStartIntro(payload)
	end

	startIntro.Text = sessionStartIntroText
end

local function formatTotalProgressText(count, total)
	count = math.max(0, math.floor(tonumber(count) or 0))
	total = math.max(1, math.floor(tonumber(total) or Constants.TotalDiscoveries or 1))

	if count <= 0 then
		return ("Touched 0 / %d things. Perfect record, suspiciously early."):format(total)
	end

	local template = TOTAL_PROGRESS_LINES[((count - 1) % #TOTAL_PROGRESS_LINES) + 1]
	return template:format(count, total)
end

local function updateTotalProgress(payload)
	payload = payload or {}
	local total = math.max(1, math.floor(tonumber(payload.TotalDiscoveries or payload.Total or Constants.TotalDiscoveries) or 1))
	local count = math.clamp(math.floor(tonumber(payload.DiscoveryCount or payload.Count) or 0), 0, total)
	local ratio = math.clamp(count / total, 0, 1)

	totalProgressLabel.Text = formatTotalProgressText(count, total)
	totalProgressFill.Size = UDim2.fromScale(ratio, 1)
	totalProgressFill.BackgroundColor3 = if ratio >= 1
		then Color3.fromRGB(119, 255, 203)
		elseif ratio >= 0.5
		then Color3.fromRGB(255, 198, 82)
		else Color3.fromRGB(255, 221, 84)
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
		local elapsed = math.max(0, payload.NoTouchElapsed or 0)
		local target = math.max(1, payload.NoTouchTarget or Constants.NoTouch.AccomplishmentSeconds)
		local totalPlay = math.max(0, payload.TotalPlaySeconds or 0)
		local ratio = math.clamp(elapsed / target, 0, 1)
		noTouchPanel.Visible = true
		noTouchFill.Size = UDim2.fromScale(ratio, 1)
		noTouchLabel.Text = ("Still: %.1f / %.1f min  Room: %.1f min"):format(elapsed / 60, target / 60, totalPlay / 60)
	else
		counter.Text = ""
		noTouchPanel.Visible = false
	end

	if payload.Type == "Hallway" then
		noTouchPanel.Visible = false
	end
end

local function setOverlayMouse(active, selectedObject)
	if active then
		if overlayMouseDepth == 0 then
			previousMouseBehavior = UserInputService.MouseBehavior
			previousMouseIconEnabled = UserInputService.MouseIconEnabled
			previousSelectedObject = GuiService.SelectedObject
		end

		overlayMouseDepth += 1
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		GuiService.SelectedObject = selectedObject
		return
	end

	overlayMouseDepth = math.max(0, overlayMouseDepth - 1)
	if overlayMouseDepth > 0 then
		return
	end

	UserInputService.MouseBehavior = previousMouseBehavior or Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = previousMouseIconEnabled ~= false
	GuiService.SelectedObject = previousSelectedObject
	previousMouseBehavior = nil
	previousMouseIconEnabled = nil
	previousSelectedObject = nil
end

local function closeReferenceBook()
	if not bookPanel.Visible then
		return
	end

	bookPanel.Visible = false
	feedbackPanel.Visible = false
	closeBookButton.Modal = false
	setOverlayMouse(false)
end

local function sendStartChoice(action, roomId)
	startOverlay.Visible = false
	continueButton.Modal = false
	restartButton.Modal = false
	setOverlayMouse(false)
	pendingStartOptions = nil
	local request = {
		Action = action,
	}

	if roomId then
		request.RoomId = roomId
	end

	sessionStartRemote:FireServer(request)
end

local function clearStartRoomChoices()
	for _, button in ipairs(startRoomButtons) do
		button:Destroy()
	end

	startRoomButtons = {}
end

local function renderStartRoomChoices(payload)
	clearStartRoomChoices()

	local rooms = payload.UnlockedRooms
	if typeof(rooms) ~= "table" or #rooms == 0 then
		startRoomTitle.Visible = false
		startRoomList.Visible = false
		return
	end

	startRoomTitle.Visible = true
	startRoomList.Visible = true

	for index, room in ipairs(rooms) do
		if typeof(room) ~= "table" or typeof(room.RoomId) ~= "string" then
			continue
		end

		local roomButton = Instance.new("TextButton")
		roomButton.Name = "StartRoomButton"
		roomButton.BackgroundColor3 = room.IsResumeRoom and Color3.fromRGB(61, 217, 132) or Color3.fromRGB(40, 45, 56)
		roomButton.BorderSizePixel = 0
		roomButton.Font = Enum.Font.GothamBlack
		roomButton.LayoutOrder = index
		roomButton.Size = UDim2.new(1, 0, 0, 36)
		roomButton.Text = room.IsResumeRoom and ("%s  |  Last"):format(room.Name or "Room") or (room.Name or "Room")
		roomButton.TextColor3 = room.IsResumeRoom and Color3.fromRGB(14, 40, 24) or Color3.fromRGB(224, 236, 245)
		roomButton.TextScaled = true
		roomButton.TextWrapped = true
		roomButton.ZIndex = 23
		roomButton.Parent = startRoomList

		local roomCorner = Instance.new("UICorner")
		roomCorner.CornerRadius = UDim.new(0, 5)
		roomCorner.Parent = roomButton

		local targetRoomId = room.RoomId
		roomButton.MouseButton1Click:Connect(function()
			sendStartChoice("Room", targetRoomId)
		end)

		table.insert(startRoomButtons, roomButton)
	end

	startRoomList.CanvasSize = UDim2.fromOffset(0, startRoomLayout.AbsoluteContentSize.Y + 16)
end

local function renderStartOptions(payload)
	if typeof(payload) ~= "table" or payload.Action ~= "Show" then
		return
	end

	if isStartOverlayDismissedForDevSession() then
		pendingStartOptions = nil
		startOverlay.Visible = false
		continueButton.Modal = false
		restartButton.Modal = false
		setOverlayMouse(false)
		return
	end

	pendingStartOptions = payload
	startOverlay.Visible = true
	continueButton.Modal = true
	restartButton.Modal = true
	setOverlayMouse(true, continueButton)
	setStartIntro(payload)
	updateTotalProgress(payload)
	startSubtitle.Text = ("Book: %d / %d found    Hints: %d    Clues: %d"):format(
		payload.DiscoveryCount or 0,
		payload.TotalDiscoveries or Constants.TotalDiscoveries,
		payload.Hints or 0,
		payload.Clues or 0
	)
	startVersion.Text = "v" .. tostring(payload.BuildVersion or Constants.BuildVersion or "dev")
	renderStartRoomChoices(payload)

	if payload.HasProgress then
		continueButton.Text = ("Continue: %s"):format(payload.ResumeRoomName or "TV Room")
		restartButton.Visible = true
	else
		continueButton.Text = "Enter TV Room"
		restartButton.Visible = false
	end
end

gui:GetAttributeChangedSignal(DEV_DISMISS_START_ATTRIBUTE):Connect(function()
	if isStartOverlayDismissedForDevSession() then
		pendingStartOptions = nil
		startOverlay.Visible = false
		continueButton.Modal = false
		restartButton.Modal = false
		setOverlayMouse(false)
	end
end)

playerGui:GetAttributeChangedSignal(DEV_DISMISS_START_ATTRIBUTE):Connect(function()
	if isStartOverlayDismissedForDevSession() then
		pendingStartOptions = nil
		startOverlay.Visible = false
		continueButton.Modal = false
		restartButton.Modal = false
		setOverlayMouse(false)
	end
end)

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

	local wasVisible = bookPanel.Visible
	activeBookRoomId = payload.RoomId
	bookPanel.Visible = true
	feedbackPanel.Visible = false
	if not wasVisible then
		closeBookButton.Modal = true
		setOverlayMouse(true, closeBookButton)
	end
	bookTitle.Text = (payload.RoomName or "Room") .. " Log"
	bookCount.Text = ("%d / %d found"):format(payload.Count or 0, payload.Total or 0)
	local secretDoor = payload.SecretDoor
	local keyText = ""
	if secretDoor then
		keyText = secretDoor.HasKey and (" | Key: %s"):format(secretDoor.KeyName or "yes") or " | Key: no"
	end
	hintCount.Text = ("Hints: %d | Clues: %d%s"):format(payload.Hints or 0, payload.Clues or 0, keyText)
	hintText.Text = payload.HintText
		or payload.StatusText
		or "Free hint, trade 5 hints for a clue, or trade 3 clues for a reveal."
	hintText.Visible = true
	buyHintButton.Text = "Free\nHint"
	if (Constants.NoTouch.ClueProductId or 0) > 0 then
		buyClueButton.Text = ("Buy Clue\n%d R$"):format(Constants.NoTouch.ClueRobux or 0)
	else
		buyClueButton.Text = "Buy Clue\nFree"
	end
	useHintButton.Text = ("Trade\n%d hints"):format(payload.ClueHintCost or Constants.NoTouch.ClueHintCost or 5)
	if (Constants.NoTouch.HintPackProductId or 0) > 0 then
		buyPackButton.Text = ("Buy Hints\n%d R$"):format(Constants.NoTouch.HintPackRobux or 0)
	else
		buyPackButton.Text = "Buy Hints\nFree"
	end
	if (Constants.NoTouch.RevealProductId or 0) > 0 then
		buyRevealButton.Text = ("Buy Reveal\n%d R$"):format(Constants.NoTouch.RevealRobux or 0)
	else
		buyRevealButton.Text = "Buy Reveal\nFree"
	end
	revealHintButton.Text = ("Trade\n%d clues"):format(payload.RevealClueCost or Constants.NoTouch.RevealClueCost or 3)
	secretDoorButton.Visible = secretDoor ~= nil
	feedbackButton.Size = secretDoor and UDim2.new(0.5, -15, 0, 36) or UDim2.new(1, -20, 0, 36)
	if secretDoor then
		activeSecretDoorAction = "RevealSecretDoor"
		if secretDoor.CanOpen then
			secretDoorButton.Text = "Library\nReady"
			secretDoorButton.BackgroundColor3 = Color3.fromRGB(61, 217, 132)
			secretDoorButton.TextColor3 = Color3.fromRGB(14, 40, 24)
		elseif secretDoor.RoomComplete and secretDoor.HasKey == false then
			activeSecretDoorAction = "BuySecretKey"
			secretDoorButton.Text = ("Key\n%d clues"):format(secretDoor.KeyClueCost or Constants.NoTouch.SecretKeyClueCost or Constants.NoTouch.RevealClueCost or 3)
			secretDoorButton.BackgroundColor3 = Color3.fromRGB(255, 198, 82)
			secretDoorButton.TextColor3 = Color3.fromRGB(57, 38, 4)
		elseif secretDoor.Visible then
			secretDoorButton.Text = "Library\nOutlined"
			secretDoorButton.BackgroundColor3 = Color3.fromRGB(61, 217, 132)
			secretDoorButton.TextColor3 = Color3.fromRGB(14, 40, 24)
		elseif (secretDoor.RevealProductId or 0) > 0 then
			secretDoorButton.Text = ("Library\n%d R$"):format(secretDoor.RevealRobux or 0)
			secretDoorButton.BackgroundColor3 = Color3.fromRGB(150, 112, 255)
			secretDoorButton.TextColor3 = Color3.fromRGB(242, 236, 255)
		else
			secretDoorButton.Text = ("Library\n%d hints"):format(secretDoor.RevealHintCost or 0)
			secretDoorButton.BackgroundColor3 = Color3.fromRGB(150, 112, 255)
			secretDoorButton.TextColor3 = Color3.fromRGB(242, 236, 255)
		end
	end

	clearBookList()

	for index, entry in ipairs(payload.Discoveries or {}) do
		local isSecret = entry.Secret == true
		local isRevealed = entry.Revealed == true
		local isClued = entry.Clued == true
		local rowText = "[?] " .. (entry.Name or "???")
		local rowBackground = Color3.fromRGB(40, 43, 50)
		local rowTextColor = Color3.fromRGB(225, 230, 238)

		if isSecret then
			rowText = "[secret] " .. (entry.Name or "???")
			rowBackground = Color3.fromRGB(88, 66, 24)
			rowTextColor = Color3.fromRGB(255, 232, 143)
		elseif entry.Unlocked then
			rowText = "[x] " .. (entry.Name or "???")
			rowBackground = Color3.fromRGB(44, 70, 52)
			rowTextColor = Color3.fromRGB(205, 255, 218)
		elseif isRevealed then
			rowText = "Location shown: " .. (entry.Name or "???")
			rowBackground = Color3.fromRGB(88, 66, 24)
			rowTextColor = Color3.fromRGB(255, 232, 143)
		elseif isClued then
			rowText = "Clue: " .. (entry.Name or "???")
			rowBackground = Color3.fromRGB(36, 58, 76)
			rowTextColor = Color3.fromRGB(190, 226, 255)
		end

		local row = Instance.new("TextLabel")
		row.Name = "DiscoveryRow"
		row.BackgroundColor3 = rowBackground
		row.BackgroundTransparency = 0.08
		row.BorderSizePixel = 0
		row.Font = Enum.Font.GothamBold
		row.LayoutOrder = index
		row.Size = UDim2.new(1, 0, 0, 38)
		row.Text = rowText
		row.TextColor3 = rowTextColor
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

closeBookButton.MouseButton1Click:Connect(closeReferenceBook)

continueButton.MouseButton1Click:Connect(function()
	sendStartChoice("Resume")
end)

restartButton.MouseButton1Click:Connect(function()
	sendStartChoice("Restart")
end)

buyHintButton.MouseButton1Click:Connect(function()
	if activeBookRoomId then
		hintPackRemote:FireServer({
			Action = "FreeHint",
			RoomId = activeBookRoomId,
		})
	end
end)

buyPackButton.MouseButton1Click:Connect(function()
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
			Action = "Clue",
			RoomId = activeBookRoomId,
		})
	end
end)

buyClueButton.MouseButton1Click:Connect(function()
	if activeBookRoomId then
		hintPackRemote:FireServer({
			Action = "BuyClue",
			RoomId = activeBookRoomId,
		})
	end
end)

revealHintButton.MouseButton1Click:Connect(function()
	if activeBookRoomId then
		hintPackRemote:FireServer({
			Action = "Reveal",
			RoomId = activeBookRoomId,
		})
	end
end)

buyRevealButton.MouseButton1Click:Connect(function()
	if activeBookRoomId then
		hintPackRemote:FireServer({
			Action = "BuyReveal",
			RoomId = activeBookRoomId,
		})
	end
end)

secretDoorButton.MouseButton1Click:Connect(function()
	if activeBookRoomId then
		hintPackRemote:FireServer({
			Action = activeSecretDoorAction,
			RoomId = activeBookRoomId,
		})
	end
end)

feedbackButton.MouseButton1Click:Connect(function()
	feedbackStatus.Text = ""
	feedbackPanel.Visible = true
	local firstButton = feedbackCategoryButtons[1] and feedbackCategoryButtons[1].Button
	if firstButton then
		GuiService.SelectedObject = firstButton
	end
end)

closeFeedbackButton.MouseButton1Click:Connect(function()
	feedbackPanel.Visible = false
	GuiService.SelectedObject = feedbackButton
end)

for _, entry in ipairs(feedbackCategoryButtons) do
	entry.Button.MouseButton1Click:Connect(function()
		if not activeBookRoomId then
			return
		end

		feedbackStatus.Text = "Sending..."
		feedbackRemote:FireServer({
			Category = entry.CategoryId,
			RoomId = activeBookRoomId,
		})
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if bookPanel.Visible and (input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB) then
		if feedbackPanel.Visible then
			feedbackPanel.Visible = false
			GuiService.SelectedObject = feedbackButton
		else
			closeReferenceBook()
		end
	elseif startOverlay.Visible and input.KeyCode == Enum.KeyCode.ButtonA then
		if GuiService.SelectedObject and GuiService.SelectedObject ~= continueButton then
			return
		end

		sendStartChoice("Resume")
	end
end)

discoveryRemote.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end

	updateCounter(payload)
	updateTotalProgress(payload)

	if payload.Type == "Unlocked" and payload.Name then
		showDiscoveryToast(payload.Name)
	end
end)

updateTotalProgress({
	Count = 0,
	Total = Constants.TotalDiscoveries,
})

referenceBookRemote.OnClientEvent:Connect(renderReferenceBook)
sessionStartRemote.OnClientEvent:Connect(renderStartOptions)
roomStatusRemote.OnClientEvent:Connect(updateRoomStatus)
sparkleRemote.OnClientEvent:Connect(showSparkleHint)
feedbackRemote.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end

	local text = tostring(payload.Message or "")
	if text == "" then
		return
	end

	feedbackStatus.Text = text
	hintText.Text = text
	showSystemMessage(text)
end)

systemMessageRemote.OnClientEvent:Connect(function(text)
	if typeof(text) == "string" and text ~= "" then
		showSystemMessage(text)
	end
end)
