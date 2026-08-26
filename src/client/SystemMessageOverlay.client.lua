local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local UiLayerController = require(script.Parent:WaitForChild("UiLayerController"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local systemMessageRemote = remotes:WaitForChild(Constants.Remotes.SystemMessage)

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
message.Parent = gui

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MaxSize = Vector2.new(720, 76)
sizeConstraint.MinSize = Vector2.new(280, 44)
sizeConstraint.Parent = message

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = message

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

systemMessageRemote.OnClientEvent:Connect(function(text)
	if typeof(text) == "string" and text ~= "" then
		show(text)
	end
end)
