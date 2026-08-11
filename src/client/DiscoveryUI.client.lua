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

local counter = Instance.new("TextLabel")
counter.Name = "DiscoveryCounter"
counter.AnchorPoint = Vector2.new(0, 0)
counter.BackgroundColor3 = Color3.fromRGB(18, 20, 24)
counter.BackgroundTransparency = 0.18
counter.BorderSizePixel = 0
counter.Font = Enum.Font.GothamBold
counter.Position = UDim2.new(0, 18, 0, 96)
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
noTouchPanel.Position = UDim2.new(0, 18, 0, 140)
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
bookList.Position = UDim2.fromOffset(18, 294)
bookList.Size = UDim2.new(1, -36, 1, -312)
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
hintTray.Size = UDim2.new(1, -36, 0, 198)
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
useHintButton.Position = UDim2.new(0.5, 5, 0, 70)
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

local revealHintButton = Instance.new("TextButton")
revealHintButton.Name = "Reveal"
revealHintButton.BackgroundColor3 = Color3.fromRGB(255, 198, 82)
revealHintButton.BorderSizePixel = 0
revealHintButton.Font = Enum.Font.GothamBlack
revealHintButton.Position = UDim2.new(0, 10, 0, 112)
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

local secretDoorButton = Instance.new("TextButton")
secretDoorButton.Name = "SecretDoorReveal"
secretDoorButton.BackgroundColor3 = Color3.fromRGB(150, 112, 255)
secretDoorButton.BorderSizePixel = 0
secretDoorButton.Font = Enum.Font.GothamBlack
secretDoorButton.Position = UDim2.new(0.5, 5, 0, 112)
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
feedbackButton.Position = UDim2.new(0, 10, 0, 154)
feedbackButton.Size = UDim2.new(1, -20, 0, 34)
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
startPanel.Size = UDim2.new(0.9, 0, 0.78, 0)
startPanel.ZIndex = 21
startPanel.Parent = startOverlay

local startPanelConstraint = Instance.new("UISizeConstraint")
startPanelConstraint.MaxSize = Vector2.new(460, 312)
startPanelConstraint.MinSize = Vector2.new(300, 270)
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
startIntro.Size = UDim2.new(1, -48, 0, 74)
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
startSubtitle.Position = UDim2.fromOffset(24, 142)
startSubtitle.Size = UDim2.new(1, -48, 0, 42)
startSubtitle.Text = ""
startSubtitle.TextColor3 = Color3.fromRGB(224, 236, 245)
startSubtitle.TextScaled = true
startSubtitle.TextWrapped = true
startSubtitle.ZIndex = 22
startSubtitle.Parent = startPanel

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
continueButton.Position = UDim2.new(0, 24, 1, -112)
continueButton.Size = UDim2.new(1, -48, 0, 42)
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
restartButton.Position = UDim2.new(0, 24, 1, -62)
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
local overlayMouseDepth = 0
local previousMouseBehavior = nil
local previousMouseIconEnabled = nil
local previousSelectedObject = nil

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

local function sendStartChoice(action)
	startOverlay.Visible = false
	continueButton.Modal = false
	restartButton.Modal = false
	setOverlayMouse(false)
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
	continueButton.Modal = true
	restartButton.Modal = true
	setOverlayMouse(true, continueButton)
	startIntro.Text = payload.IntroText or Constants.GameIntro
	startSubtitle.Text = ("Book: %d / %d found    Hints: %d    Clues: %d"):format(
		payload.DiscoveryCount or 0,
		payload.TotalDiscoveries or Constants.TotalDiscoveries,
		payload.Hints or 0,
		payload.Clues or 0
	)
	startVersion.Text = "v" .. tostring(payload.BuildVersion or Constants.BuildVersion or "dev")

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
	if (Constants.NoTouch.ClueProductId or 0) > 0 then
		useHintButton.Text = ("Clue\n%d R$"):format(Constants.NoTouch.ClueRobux or 0)
	else
		useHintButton.Text = ("Clue\n%d hints"):format(payload.ClueHintCost or Constants.NoTouch.ClueHintCost or 5)
	end
	if (Constants.NoTouch.RevealProductId or 0) > 0 then
		revealHintButton.Text = ("Reveal\n%d R$"):format(Constants.NoTouch.RevealRobux or 0)
	else
		revealHintButton.Text = ("Reveal\n%d clues"):format(payload.RevealClueCost or Constants.NoTouch.RevealClueCost or 3)
	end
	secretDoorButton.Visible = secretDoor ~= nil
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

useHintButton.MouseButton1Click:Connect(function()
	if activeBookRoomId then
		hintPackRemote:FireServer({
			Action = "Clue",
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
		sendStartChoice("Resume")
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
