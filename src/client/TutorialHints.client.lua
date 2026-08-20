local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "DontTouchItTutorialHints"
gui.DisplayOrder = 170
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
pcall(function()
	gui.ScreenInsets = Enum.ScreenInsets.None
end)
gui.Parent = playerGui

local shade = Instance.new("Frame")
shade.Name = "ModalShade"
shade.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
shade.BackgroundTransparency = 1
shade.BorderSizePixel = 0
shade.Size = UDim2.fromScale(1, 1)
shade.Visible = false
shade.ZIndex = 1
shade.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "HintPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.new(0.5, 0, 0.38, 0)
panel.Size = UDim2.new(0.64, 0, 0, 156)
panel.BackgroundColor3 = Color3.fromRGB(8, 12, 18)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Visible = false
panel.ZIndex = 2
panel.Parent = gui

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(360, 132)
sizeConstraint.MaxSize = Vector2.new(680, 172)
sizeConstraint.Parent = panel

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(129, 230, 255)
stroke.Thickness = 2
stroke.Transparency = 0.24
stroke.Parent = panel

local accent = Instance.new("Frame")
accent.Name = "AccentLine"
accent.BackgroundColor3 = Color3.fromRGB(114, 255, 207)
accent.BorderSizePixel = 0
accent.Position = UDim2.new(0, 22, 0, 46)
accent.Size = UDim2.new(1, -44, 0, 2)
accent.ZIndex = 3
accent.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.Text = "Tutorial"
title.TextColor3 = Color3.fromRGB(198, 250, 232)
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left
title.Position = UDim2.new(0, 24, 0, 15)
title.Size = UDim2.new(1, -48, 0, 28)
title.ZIndex = 3
title.Parent = panel

local body = Instance.new("TextLabel")
body.Name = "Body"
body.BackgroundTransparency = 1
body.Font = Enum.Font.GothamSemibold
body.TextColor3 = Color3.fromRGB(235, 243, 255)
body.TextSize = 23
body.TextWrapped = true
body.TextXAlignment = Enum.TextXAlignment.Left
body.TextYAlignment = Enum.TextYAlignment.Top
body.Position = UDim2.new(0, 24, 0, 64)
body.Size = UDim2.new(1, -48, 1, -78)
body.ZIndex = 3
body.Parent = panel

local footer = Instance.new("TextLabel")
footer.Name = "Footer"
footer.BackgroundTransparency = 1
footer.Font = Enum.Font.GothamMedium
footer.Text = "Use the nearby prompt to continue."
footer.TextColor3 = Color3.fromRGB(154, 210, 229)
footer.TextSize = 14
footer.TextXAlignment = Enum.TextXAlignment.Right
footer.Position = UDim2.new(0, 24, 1, -28)
footer.Size = UDim2.new(1, -48, 0, 18)
footer.ZIndex = 3
footer.Parent = panel

local activePrompt = nil
local activeTween = nil
local shadeTween = nil

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
	if shadeTween then
		shadeTween:Cancel()
		shadeTween = nil
	end

	if visible then
		shade.Visible = true
		panel.Visible = true
		shade.BackgroundTransparency = 1
		panel.BackgroundTransparency = 1
		title.TextTransparency = 1
		body.TextTransparency = 1
		footer.TextTransparency = 1
		accent.BackgroundTransparency = 1
		stroke.Transparency = 1
		activeTween = TweenService:Create(panel, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.08,
		})
		shadeTween = TweenService:Create(shade, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.52,
		})
		shadeTween:Play()
		activeTween:Play()
		TweenService:Create(title, TweenInfo.new(0.16), { TextTransparency = 0 }):Play()
		TweenService:Create(body, TweenInfo.new(0.16), { TextTransparency = 0 }):Play()
		TweenService:Create(footer, TweenInfo.new(0.16), { TextTransparency = 0 }):Play()
		TweenService:Create(accent, TweenInfo.new(0.16), { BackgroundTransparency = 0 }):Play()
		TweenService:Create(stroke, TweenInfo.new(0.16), { Transparency = 0.24 }):Play()
	else
		activeTween = TweenService:Create(panel, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1,
		})
		shadeTween = TweenService:Create(shade, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1,
		})
		TweenService:Create(title, TweenInfo.new(0.12), { TextTransparency = 1 }):Play()
		TweenService:Create(body, TweenInfo.new(0.12), { TextTransparency = 1 }):Play()
		TweenService:Create(footer, TweenInfo.new(0.12), { TextTransparency = 1 }):Play()
		TweenService:Create(accent, TweenInfo.new(0.12), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(stroke, TweenInfo.new(0.12), { Transparency = 1 }):Play()
		activeTween.Completed:Connect(function()
			if not activePrompt then
				panel.Visible = false
				shade.Visible = false
			end
		end)
		shadeTween:Play()
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
