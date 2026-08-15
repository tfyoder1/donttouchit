local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SPLASH_GUI_NAME = "DontTouchItTitleSplash"
local ADVANCE_ATTRIBUTE = "DontTouchItTitleSplashAdvanceNonce"
local READY_ATTRIBUTE = "DontTouchItTitleSplashMenuReady"
local sessionStartRemote = nil

local splashGui = Instance.new("ScreenGui")
splashGui.Name = SPLASH_GUI_NAME
splashGui.DisplayOrder = 210
splashGui.IgnoreGuiInset = true
splashGui.ResetOnSpawn = false
splashGui.Parent = playerGui

pcall(function()
	splashGui.ScreenInsets = Enum.ScreenInsets.None
end)

local root = Instance.new("Frame")
root.Name = "SplashRoot"
root.Active = true
root.BackgroundColor3 = Color3.fromRGB(7, 9, 13)
root.BackgroundTransparency = 0.1
root.BorderSizePixel = 0
root.Size = UDim2.fromScale(1, 1)
root.Parent = splashGui

local backdropGradient = Instance.new("UIGradient")
backdropGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(7, 9, 13)),
	ColorSequenceKeypoint.new(0.45, Color3.fromRGB(15, 19, 28)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(7, 9, 13)),
})
backdropGradient.Rotation = 90
backdropGradient.Parent = root

local topShadow = Instance.new("Frame")
topShadow.Name = "TopShadow"
topShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
topShadow.BackgroundTransparency = 0.18
topShadow.BorderSizePixel = 0
topShadow.Size = UDim2.new(1, 0, 0, 96)
topShadow.Parent = root

local bottomShadow = Instance.new("Frame")
bottomShadow.Name = "BottomShadow"
bottomShadow.AnchorPoint = Vector2.new(0, 1)
bottomShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
bottomShadow.BackgroundTransparency = 0.35
bottomShadow.BorderSizePixel = 0
bottomShadow.Position = UDim2.fromScale(0, 1)
bottomShadow.Size = UDim2.new(1, 0, 0, 92)
bottomShadow.Parent = root

local contentGroup = Instance.new("Frame")
contentGroup.Name = "Content"
contentGroup.AnchorPoint = Vector2.new(0.5, 0.5)
contentGroup.BackgroundTransparency = 1
contentGroup.Position = UDim2.fromScale(0.5, 0.5)
contentGroup.Size = UDim2.new(0.92, 0, 0.78, 0)
contentGroup.Parent = root

local glowLine = Instance.new("Frame")
glowLine.Name = "GlowLine"
glowLine.AnchorPoint = Vector2.new(0.5, 0.5)
glowLine.BackgroundColor3 = Color3.fromRGB(255, 242, 181)
glowLine.BackgroundTransparency = 0.72
glowLine.BorderSizePixel = 0
glowLine.Position = UDim2.fromScale(0.5, 0.25)
glowLine.Size = UDim2.new(0.34, 0, 0, 2)
glowLine.Parent = contentGroup

local title = Instance.new("TextLabel")
title.Name = "Title"
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.Position = UDim2.fromScale(0.5, 0.34)
title.Size = UDim2.new(0.82, 0, 0, 52)
title.Text = "DON'T TOUCH IT"
title.TextColor3 = Color3.fromRGB(255, 242, 181)
title.TextScaled = false
title.TextSize = 42
title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
title.TextStrokeTransparency = 0.25
title.TextWrapped = true
title.Parent = contentGroup

local story = Instance.new("TextLabel")
story.Name = "Story"
story.AnchorPoint = Vector2.new(0.5, 0.5)
story.BackgroundTransparency = 1
story.Font = Enum.Font.GothamSemibold
story.Position = UDim2.fromScale(0.5, 0.52)
story.Size = UDim2.new(0.74, 0, 0, 72)
story.Text = "The lights were already on.\nSome doors remember being opened.\nThe quiet things are not asleep."
story.TextColor3 = Color3.fromRGB(220, 232, 244)
story.TextScaled = false
story.TextSize = 24
story.TextWrapped = true
story.Parent = contentGroup

local prompt = Instance.new("TextLabel")
prompt.Name = "Prompt"
prompt.AnchorPoint = Vector2.new(0.5, 0.5)
prompt.BackgroundTransparency = 1
prompt.Font = Enum.Font.GothamSemibold
prompt.Position = UDim2.fromScale(0.5, 0.73)
prompt.Size = UDim2.new(0.82, 0, 0, 34)
prompt.Text = "Tap, click, or press any button"
prompt.TextColor3 = Color3.fromRGB(190, 204, 220)
prompt.TextScaled = false
prompt.TextSize = 21
prompt.TextWrapped = true
prompt.Parent = contentGroup

local menuFrame = Instance.new("Frame")
menuFrame.Name = "Menu"
menuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
menuFrame.BackgroundTransparency = 1
menuFrame.Position = UDim2.fromScale(0.5, 0.78)
menuFrame.Size = UDim2.new(0.72, 0, 0, 52)
menuFrame.Visible = false
menuFrame.Parent = contentGroup

local menuLayout = Instance.new("UIListLayout")
menuLayout.FillDirection = Enum.FillDirection.Horizontal
menuLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
menuLayout.Padding = UDim.new(0, 12)
menuLayout.SortOrder = Enum.SortOrder.LayoutOrder
menuLayout.VerticalAlignment = Enum.VerticalAlignment.Center
menuLayout.Parent = menuFrame

local function makeMenuButton(name, text, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.AutoButtonColor = true
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBlack
	button.Size = UDim2.new(0.5, -8, 0, 42)
	button.Text = text
	button.TextColor3 = Color3.fromRGB(14, 24, 30)
	button.TextScaled = false
	button.TextSize = 26
	button.TextWrapped = true
	button.Parent = menuFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	return button
end

local continueButton = makeMenuButton("ContinueButton", "Continue", Color3.fromRGB(61, 217, 132))
local restartButton = makeMenuButton("RestartButton", "Start Over", Color3.fromRGB(84, 154, 255))

local advanced = false
local choiceSent = false
local topbarRestoreRequested = false
local splashBlur = nil

local function setTopbarEnabled(enabled)
	pcall(function()
		StarterGui:SetCore("TopbarEnabled", enabled == true)
	end)
end

local function hideTopbarDuringSplash()
	for attempt = 1, 12 do
		if not splashGui.Parent or topbarRestoreRequested then
			return
		end

		setTopbarEnabled(false)
		task.wait(0.25)
	end
end

local function restoreTopbar()
	if topbarRestoreRequested then
		return
	end

	topbarRestoreRequested = true
	setTopbarEnabled(true)
	task.delay(0.25, function()
		setTopbarEnabled(true)
	end)
	task.delay(1, function()
		setTopbarEnabled(true)
	end)
end

local function enableSplashBlur()
	splashBlur = Instance.new("BlurEffect")
	splashBlur.Name = "DontTouchItTitleSplashBlur"
	splashBlur.Size = 0
	splashBlur.Parent = Lighting
	TweenService:Create(
		splashBlur,
		TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = 12 }
	):Play()
end

local function restoreSplashBlur()
	local blur = splashBlur
	splashBlur = nil
	if not blur or not blur.Parent then
		return
	end

	local blurTween = TweenService:Create(
		blur,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = 0 }
	)
	blurTween:Play()
	blurTween.Completed:Connect(function()
		if blur.Parent then
			blur:Destroy()
		end
	end)
end

local function applyLayout()
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local landscape = viewport.X > viewport.Y
	local compact = math.min(viewport.X, viewport.Y) < 520

	if landscape and compact then
		contentGroup.Size = UDim2.new(0.82, 0, 0.82, 0)

		title.Position = UDim2.fromScale(0.5, 0.31)
		title.Size = UDim2.new(0.8, 0, 0, 44)
		title.TextSize = 34

		story.Position = UDim2.fromScale(0.5, 0.48)
		story.Size = UDim2.new(0.7, 0, 0, 62)
		story.TextSize = 20

		prompt.Position = UDim2.fromScale(0.5, 0.72)
		prompt.TextSize = 18

		menuFrame.Position = UDim2.fromScale(0.5, 0.78)
		menuFrame.Size = UDim2.new(0.72, 0, 0, 44)
		continueButton.Size = UDim2.new(0.5, -8, 0, 40)
		restartButton.Size = UDim2.new(0.5, -8, 0, 40)
		continueButton.TextSize = 24
		restartButton.TextSize = 24
	else
		contentGroup.Size = UDim2.new(0.92, 0, 0.78, 0)

		title.Position = UDim2.fromScale(0.5, 0.34)
		title.Size = UDim2.new(0.82, 0, 0, 52)
		title.TextSize = 42

		story.Position = UDim2.fromScale(0.5, 0.52)
		story.Size = UDim2.new(0.74, 0, 0, 72)
		story.TextSize = 24

		prompt.Position = UDim2.fromScale(0.5, 0.73)
		prompt.TextSize = 21

		menuFrame.Position = UDim2.fromScale(0.5, 0.78)
		menuFrame.Size = UDim2.new(0.72, 0, 0, 52)
		continueButton.Size = UDim2.new(0.5, -8, 0, 42)
		restartButton.Size = UDim2.new(0.5, -8, 0, 42)
		continueButton.TextSize = 26
		restartButton.TextSize = 26
	end
end

task.spawn(function()
	hideTopbarDuringSplash()
end)

enableSplashBlur()

task.spawn(function()
	while splashGui.Parent and not advanced do
		TweenService:Create(
			prompt,
			TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{ TextTransparency = 0.28 }
		):Play()
		task.wait(0.75)
		TweenService:Create(
			prompt,
			TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{ TextTransparency = 0 }
		):Play()
		task.wait(0.75)
	end
end)

task.spawn(function()
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 20)
	if remotes then
		local remote = remotes:WaitForChild("SessionStart", 20)
		if remote and remote:IsA("RemoteEvent") then
			sessionStartRemote = remote
		end
	end
end)

local function fadeAndDestroy()
	if not splashGui.Parent then
		return
	end

	restoreTopbar()
	restoreSplashBlur()
	local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(root, tweenInfo, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(glowLine, tweenInfo, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(topShadow, tweenInfo, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(bottomShadow, tweenInfo, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(title, tweenInfo, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	TweenService:Create(story, tweenInfo, { TextTransparency = 1 }):Play()
	for _, child in ipairs(menuFrame:GetChildren()) do
		if child:IsA("TextButton") then
			TweenService:Create(child, tweenInfo, { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
		end
	end
	local promptTween = TweenService:Create(prompt, tweenInfo, { TextTransparency = 1 })
	promptTween:Play()
	promptTween.Completed:Connect(function()
		if splashGui.Parent then
			splashGui:Destroy()
		end
	end)
end

local function requestStartMenu()
	if advanced then
		return
	end

	advanced = true
	prompt.Visible = false
	menuFrame.Visible = true
	playerGui:SetAttribute(READY_ATTRIBUTE, false)
	playerGui:SetAttribute(ADVANCE_ATTRIBUTE, (tonumber(playerGui:GetAttribute(ADVANCE_ATTRIBUTE)) or 0) + 1)
end

local function sendStartChoice(action)
	if choiceSent then
		return
	end

	if not sessionStartRemote then
		prompt.Visible = true
		prompt.Text = "Still loading menu..."
		task.delay(0.35, function()
			if splashGui.Parent and not choiceSent then
				sendStartChoice(action)
			end
		end)
		return
	end

	choiceSent = true
	sessionStartRemote:FireServer({
		Action = action,
	})
	fadeAndDestroy()
end

continueButton.Activated:Connect(function()
	sendStartChoice("Resume")
end)

restartButton.Activated:Connect(function()
	sendStartChoice("Restart")
end)

root.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Gamepad1
	then
		requestStartMenu()
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed and input.UserInputType ~= Enum.UserInputType.Gamepad1 then
		return
	end

	if input.UserInputType == Enum.UserInputType.Keyboard
		or input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.Gamepad1
	then
		requestStartMenu()
	end
end)

playerGui:GetAttributeChangedSignal(READY_ATTRIBUTE):Connect(function()
	if advanced and playerGui:GetAttribute(READY_ATTRIBUTE) == true then
		fadeAndDestroy()
	end
end)

applyLayout()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(applyLayout)
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyLayout)
end
