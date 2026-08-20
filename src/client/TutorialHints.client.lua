local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "DontTouchItTutorialHints"
gui.DisplayOrder = 170
gui.IgnoreGuiInset = false
gui.ResetOnSpawn = false
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "HintPanel"
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0, 84)
panel.Size = UDim2.new(0, 520, 0, 82)
panel.BackgroundColor3 = Color3.fromRGB(8, 12, 18)
panel.BackgroundTransparency = 0.12
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(129, 230, 255)
stroke.Thickness = 1
stroke.Transparency = 0.35
stroke.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.Text = "Tutorial"
title.TextColor3 = Color3.fromRGB(198, 250, 232)
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Position = UDim2.new(0, 18, 0, 10)
title.Size = UDim2.new(1, -36, 0, 20)
title.Parent = panel

local body = Instance.new("TextLabel")
body.Name = "Body"
body.BackgroundTransparency = 1
body.Font = Enum.Font.GothamSemibold
body.TextColor3 = Color3.fromRGB(235, 243, 255)
body.TextSize = 18
body.TextWrapped = true
body.TextXAlignment = Enum.TextXAlignment.Left
body.TextYAlignment = Enum.TextYAlignment.Top
body.Position = UDim2.new(0, 18, 0, 35)
body.Size = UDim2.new(1, -36, 0, 40)
body.Parent = panel

local activePrompt = nil
local activeTween = nil

local function findHint(prompt)
	local current = prompt
	while current and current ~= workspace do
		local hint = current:GetAttribute("TutorialHint")
		if typeof(hint) == "string" and hint ~= "" then
			return hint
		end
		current = current.Parent
	end

	return nil
end

local function setPanelVisible(visible)
	if activeTween then
		activeTween:Cancel()
		activeTween = nil
	end

	if visible then
		panel.Visible = true
		panel.BackgroundTransparency = 1
		title.TextTransparency = 1
		body.TextTransparency = 1
		stroke.Transparency = 1
		activeTween = TweenService:Create(panel, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.12,
		})
		activeTween:Play()
		TweenService:Create(title, TweenInfo.new(0.16), { TextTransparency = 0 }):Play()
		TweenService:Create(body, TweenInfo.new(0.16), { TextTransparency = 0 }):Play()
		TweenService:Create(stroke, TweenInfo.new(0.16), { Transparency = 0.35 }):Play()
	else
		activeTween = TweenService:Create(panel, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1,
		})
		TweenService:Create(title, TweenInfo.new(0.12), { TextTransparency = 1 }):Play()
		TweenService:Create(body, TweenInfo.new(0.12), { TextTransparency = 1 }):Play()
		TweenService:Create(stroke, TweenInfo.new(0.12), { Transparency = 1 }):Play()
		activeTween.Completed:Connect(function()
			if not activePrompt then
				panel.Visible = false
			end
		end)
		activeTween:Play()
	end
end

local function showHint(prompt, hint)
	activePrompt = prompt
	body.Text = hint
	setPanelVisible(true)
end

local function hideHint(prompt)
	if activePrompt ~= prompt then
		return
	end

	activePrompt = nil
	setPanelVisible(false)
end

ProximityPromptService.PromptShown:Connect(function(prompt)
	local hint = findHint(prompt)
	if hint then
		showHint(prompt, hint)
	end
end)

ProximityPromptService.PromptHidden:Connect(hideHint)
