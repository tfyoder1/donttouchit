local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local discoveryRemote = remotes:WaitForChild(Constants.Remotes.DiscoveryUpdate)
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
counter.Size = UDim2.fromOffset(190, 38)
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

local activeToastTween = nil
local activeMessageTween = nil
local toastSequence = 0
local messageSequence = 0

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

discoveryRemote.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end

	counter.Text = ("Discoveries: %d / %d"):format(payload.Count or 0, payload.Total or Constants.TotalDiscoveries)

	if payload.Type == "Unlocked" and payload.Name then
		showDiscoveryToast(payload.Name)
	end
end)

systemMessageRemote.OnClientEvent:Connect(function(text)
	if typeof(text) == "string" and text ~= "" then
		showSystemMessage(text)
	end
end)
