local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local UiLayerController = require(script.Parent:WaitForChild("UiLayerController"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local systemMessageRemote = remotes:WaitForChild(Constants.Remotes.SystemMessage)
local acknowledgedMessageRemote = remotes:WaitForChild(Constants.Remotes.AcknowledgedMessage)

local gui = Instance.new("ScreenGui")
gui.Name = "DontTouchItSystemMessageOverlay"
gui.IgnoreGuiInset = false
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = UiLayerController.DisplayOrder.Emergency
gui.Parent = player:WaitForChild("PlayerGui")
pcall(function()
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
end)

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
message.ZIndex = 1000
message.Parent = gui

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MaxSize = Vector2.new(720, 76)
sizeConstraint.MinSize = Vector2.new(280, 44)
sizeConstraint.Parent = message

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = message

local modalShade = Instance.new("TextButton")
modalShade.Name = "AcknowledgedMessageShade"
modalShade.AutoButtonColor = false
modalShade.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
modalShade.BackgroundTransparency = 1
modalShade.BorderSizePixel = 0
modalShade.Position = UDim2.fromScale(0, 0)
modalShade.Selectable = false
modalShade.Size = UDim2.fromScale(1, 1)
modalShade.Text = ""
modalShade.Visible = false
modalShade.ZIndex = 1010
modalShade.Parent = gui

local modalPanel = Instance.new("Frame")
modalPanel.Name = "AcknowledgedMessagePanel"
modalPanel.AnchorPoint = Vector2.new(0.5, 0.5)
modalPanel.BackgroundColor3 = Color3.fromRGB(18, 20, 24)
modalPanel.BackgroundTransparency = 0.06
modalPanel.BorderSizePixel = 0
modalPanel.Position = UDim2.fromScale(0.5, 0.52)
modalPanel.Size = UDim2.new(0.72, 0, 0, 170)
modalPanel.Visible = false
modalPanel.ZIndex = 1011
modalPanel.Parent = gui

local modalSize = Instance.new("UISizeConstraint")
modalSize.MaxSize = Vector2.new(560, 190)
modalSize.MinSize = Vector2.new(300, 136)
modalSize.Parent = modalPanel

local modalCorner = Instance.new("UICorner")
modalCorner.CornerRadius = UDim.new(0, 8)
modalCorner.Parent = modalPanel

local modalStroke = Instance.new("UIStroke")
modalStroke.Color = Color3.fromRGB(155, 245, 255)
modalStroke.Transparency = 0.36
modalStroke.Thickness = 1
modalStroke.Parent = modalPanel

local modalPadding = Instance.new("UIPadding")
modalPadding.PaddingBottom = UDim.new(0, 14)
modalPadding.PaddingLeft = UDim.new(0, 18)
modalPadding.PaddingRight = UDim.new(0, 18)
modalPadding.PaddingTop = UDim.new(0, 14)
modalPadding.Parent = modalPanel

local modalTitle = Instance.new("TextLabel")
modalTitle.Name = "Title"
modalTitle.BackgroundTransparency = 1
modalTitle.Font = Enum.Font.GothamBold
modalTitle.Position = UDim2.fromScale(0, 0)
modalTitle.Size = UDim2.new(1, 0, 0, 26)
modalTitle.Text = ""
modalTitle.TextColor3 = Color3.fromRGB(245, 250, 255)
modalTitle.TextScaled = true
modalTitle.TextWrapped = true
modalTitle.TextXAlignment = Enum.TextXAlignment.Left
modalTitle.ZIndex = 1012
modalTitle.Parent = modalPanel

local titleConstraint = Instance.new("UITextSizeConstraint")
titleConstraint.MaxTextSize = 20
titleConstraint.MinTextSize = 12
titleConstraint.Parent = modalTitle

local modalBody = Instance.new("TextLabel")
modalBody.Name = "Body"
modalBody.BackgroundTransparency = 1
modalBody.Font = Enum.Font.Gotham
modalBody.Position = UDim2.new(0, 0, 0, 38)
modalBody.Size = UDim2.new(1, 0, 1, -92)
modalBody.Text = ""
modalBody.TextColor3 = Color3.fromRGB(232, 238, 245)
modalBody.TextScaled = true
modalBody.TextWrapped = true
modalBody.TextXAlignment = Enum.TextXAlignment.Left
modalBody.TextYAlignment = Enum.TextYAlignment.Top
modalBody.ZIndex = 1012
modalBody.Parent = modalPanel

local bodyConstraint = Instance.new("UITextSizeConstraint")
bodyConstraint.MaxTextSize = 17
bodyConstraint.MinTextSize = 11
bodyConstraint.Parent = modalBody

local okButton = Instance.new("TextButton")
okButton.Name = "OKButton"
okButton.AnchorPoint = Vector2.new(1, 1)
okButton.BackgroundColor3 = Color3.fromRGB(86, 160, 255)
okButton.BorderSizePixel = 0
okButton.Font = Enum.Font.GothamBold
okButton.Position = UDim2.fromScale(1, 1)
okButton.Size = UDim2.new(0, 118, 0, 40)
okButton.Text = "OK"
okButton.TextColor3 = Color3.fromRGB(10, 16, 22)
okButton.TextScaled = true
okButton.ZIndex = 1012
okButton.Parent = modalPanel

local okCorner = Instance.new("UICorner")
okCorner.CornerRadius = UDim.new(0, 7)
okCorner.Parent = okButton

local okConstraint = Instance.new("UITextSizeConstraint")
okConstraint.MaxTextSize = 18
okConstraint.MinTextSize = 12
okConstraint.Parent = okButton

local activeTween = nil
local sequence = 0

local function tween(properties, duration)
	if activeTween then
		activeTween:Cancel()
	end

	activeTween = TweenService:Create(
		message,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		properties
	)
	activeTween:Play()
end

local function show(text)
	sequence += 1
	local currentSequence = sequence

	gui.Enabled = true
	message.Text = text
	message.BackgroundTransparency = 0.18
	message.TextTransparency = 0

	local duration = math.clamp(4.5 + #text / 35, 5.5, 9)
	task.delay(duration, function()
		if sequence ~= currentSequence then
			return
		end

		tween({
			BackgroundTransparency = 1,
			TextTransparency = 1,
		}, 0.25)
	end)
end

local function hideAcknowledged()
	modalShade.Visible = false
	modalPanel.Visible = false
end

local function showAcknowledged(payload)
	if typeof(payload) ~= "table" then
		return
	end

	local text = payload.Text
	if typeof(text) ~= "string" or text == "" then
		return
	end

	gui.Enabled = true
	modalTitle.Text = if typeof(payload.Title) == "string" and payload.Title ~= "" then payload.Title else "Notice"
	modalBody.Text = text
	okButton.Text = if typeof(payload.ButtonText) == "string" and payload.ButtonText ~= "" then payload.ButtonText else "OK"
	modalShade.BackgroundTransparency = 0.58
	modalShade.Visible = true
	modalPanel.Visible = true
end

okButton.Activated:Connect(hideAcknowledged)
modalShade.Activated:Connect(function()
end)

systemMessageRemote.OnClientEvent:Connect(function(text)
	if typeof(text) == "string" and text ~= "" then
		show(text)
	end
end)

acknowledgedMessageRemote.OnClientEvent:Connect(showAcknowledged)
