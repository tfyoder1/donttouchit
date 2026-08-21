local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local UiLayerController = require(script.Parent:WaitForChild("UiLayerController"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local tutorialPreferencesRemote = remotes:WaitForChild(Constants.Remotes.TutorialPreferences)

local gui = Instance.new("ScreenGui")
gui.Name = "DontTouchItTutorialHints"
UiLayerController.ApplyRole(gui, "Tutorial")
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
shade.Active = false
shade.Selectable = false
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
panel.Active = false
panel.Selectable = false
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

local controlsRow = Instance.new("Frame")
controlsRow.Name = "ControlsRow"
controlsRow.BackgroundTransparency = 1
controlsRow.BorderSizePixel = 0
controlsRow.Position = UDim2.new(0, 24, 1, -50)
controlsRow.Size = UDim2.new(1, -48, 0, 34)
controlsRow.ZIndex = 3
controlsRow.Parent = panel

local dontShowButton = Instance.new("TextButton")
dontShowButton.Name = "DontShowAgain"
dontShowButton.BackgroundColor3 = Color3.fromRGB(20, 27, 35)
dontShowButton.BackgroundTransparency = 0.04
dontShowButton.BorderSizePixel = 0
dontShowButton.Font = Enum.Font.GothamBold
dontShowButton.Position = UDim2.fromScale(0, 0)
dontShowButton.Size = UDim2.new(1, -84, 1, 0)
dontShowButton.TextColor3 = Color3.fromRGB(218, 234, 244)
dontShowButton.TextSize = 14
dontShowButton.TextWrapped = true
dontShowButton.TextXAlignment = Enum.TextXAlignment.Left
dontShowButton.ZIndex = 4
dontShowButton.Parent = controlsRow

local dontShowPadding = Instance.new("UIPadding")
dontShowPadding.PaddingLeft = UDim.new(0, 10)
dontShowPadding.PaddingRight = UDim.new(0, 8)
dontShowPadding.Parent = dontShowButton

local dontShowCorner = Instance.new("UICorner")
dontShowCorner.CornerRadius = UDim.new(0, 6)
dontShowCorner.Parent = dontShowButton

local dontShowStroke = Instance.new("UIStroke")
dontShowStroke.Color = Color3.fromRGB(97, 231, 184)
dontShowStroke.Thickness = 1
dontShowStroke.Transparency = 0.34
dontShowStroke.Parent = dontShowButton

local okButton = Instance.new("TextButton")
okButton.Name = "OK"
okButton.AnchorPoint = Vector2.new(1, 0)
okButton.BackgroundColor3 = Color3.fromRGB(114, 255, 207)
okButton.BorderSizePixel = 0
okButton.Font = Enum.Font.GothamBlack
okButton.Position = UDim2.fromScale(1, 0)
okButton.Size = UDim2.new(0, 72, 1, 0)
okButton.Text = "OK"
okButton.TextColor3 = Color3.fromRGB(7, 28, 25)
okButton.TextSize = 16
okButton.ZIndex = 4
okButton.Parent = controlsRow

local okCorner = Instance.new("UICorner")
okCorner.CornerRadius = UDim.new(0, 6)
okCorner.Parent = okButton

local activePrompt = nil
local activeTween = nil
local shadeTween = nil
local activePromptConnections = {}
local viewportConnection = nil
local activeTutorialId = nil
local tutorialsEnabled = true
local completedTutorials = {}
local dontShowAgainSelected = true

local DEFAULT_FOOTER_TEXT = "Use the nearby prompt to continue."
local TUTORIALS_ENABLED_ATTRIBUTE = "DontTouchItTutorialsEnabled"

local function sanitizeLocalTutorialId(value)
	if typeof(value) ~= "string" then
		return nil
	end

	local tutorialId = string.sub(value, 1, 96)
	tutorialId = string.gsub(tutorialId, "[^%w%._%-:/]", "_")
	if tutorialId == "" then
		return nil
	end

	return tutorialId
end

local function updateDontShowButton()
	local prefix = dontShowAgainSelected and "[x]" or "[ ]"
	dontShowButton.Text = prefix .. " Don't show this again"
	dontShowButton.BackgroundColor3 = dontShowAgainSelected and Color3.fromRGB(20, 37, 33) or Color3.fromRGB(28, 32, 40)
	dontShowStroke.Color = dontShowAgainSelected and Color3.fromRGB(97, 231, 184) or Color3.fromRGB(114, 132, 148)
	dontShowStroke.Transparency = dontShowAgainSelected and 0.24 or 0.44
end

local function getViewportSize()
	local camera = workspace.CurrentCamera
	if camera then
		return camera.ViewportSize
	end

	return gui.AbsoluteSize
end

local function usesTouchToastLayout()
	return UserInputService.TouchEnabled
end

local function getPromptFooterText(prompt)
	if usesTouchToastLayout() and prompt then
		local actionText = prompt.ActionText
		if typeof(actionText) == "string" and actionText ~= "" then
			return string.format("Tap %s to continue.", actionText)
		end

		return "Tap the prompt to continue."
	end

	return DEFAULT_FOOTER_TEXT
end

local function applyPanelLayout()
	local viewport = getViewportSize()
	local compactTouch = usesTouchToastLayout()
	local phoneLike = compactTouch and math.min(viewport.X, viewport.Y) <= 700

	if compactTouch then
		panel.AnchorPoint = Vector2.new(0.5, 0)
		panel.Position = UDim2.new(0.5, 0, 0, phoneLike and 58 or 74)
		panel.Size = UDim2.new(phoneLike and 0.54 or 0.52, 0, 0, phoneLike and 164 or 174)
		sizeConstraint.MinSize = Vector2.new(phoneLike and 320 or 340, phoneLike and 148 or 156)
		sizeConstraint.MaxSize = Vector2.new(phoneLike and 460 or 540, phoneLike and 168 or 180)

		accent.Position = UDim2.new(0, 16, 0, 35)
		accent.Size = UDim2.new(1, -32, 0, 2)

		title.TextSize = phoneLike and 16 or 18
		title.Position = UDim2.new(0, 16, 0, 8)
		title.Size = UDim2.new(1, -32, 0, 24)

		body.TextSize = phoneLike and 15 or 17
		body.Position = UDim2.new(0, 16, 0, 44)
		body.Size = UDim2.new(1, -32, 1, -96)

		footer.TextSize = phoneLike and 11 or 12
		footer.Position = UDim2.new(0, 16, 1, -50)
		footer.Size = UDim2.new(1, -32, 0, 16)

		controlsRow.Position = UDim2.new(0, 16, 1, -32)
		controlsRow.Size = UDim2.new(1, -32, 0, 26)
		dontShowButton.Size = UDim2.new(1, -64, 1, 0)
		dontShowButton.TextSize = phoneLike and 11 or 12
		okButton.Size = UDim2.new(0, 56, 1, 0)
		okButton.TextSize = 13
	else
		panel.AnchorPoint = Vector2.new(0.5, 0.5)
		panel.Position = UDim2.new(0.5, 0, 0.38, 0)
		panel.Size = UDim2.new(0.64, 0, 0, 206)
		sizeConstraint.MinSize = Vector2.new(360, 184)
		sizeConstraint.MaxSize = Vector2.new(680, 224)

		accent.Position = UDim2.new(0, 22, 0, 46)
		accent.Size = UDim2.new(1, -44, 0, 2)

		title.TextSize = 22
		title.Position = UDim2.new(0, 24, 0, 15)
		title.Size = UDim2.new(1, -48, 0, 28)

		body.TextSize = 21
		body.Position = UDim2.new(0, 24, 0, 64)
		body.Size = UDim2.new(1, -48, 1, -128)

		footer.TextSize = 14
		footer.Position = UDim2.new(0, 24, 1, -76)
		footer.Size = UDim2.new(1, -48, 0, 18)

		controlsRow.Position = UDim2.new(0, 24, 1, -50)
		controlsRow.Size = UDim2.new(1, -48, 0, 34)
		dontShowButton.Size = UDim2.new(1, -84, 1, 0)
		dontShowButton.TextSize = 14
		okButton.Size = UDim2.new(0, 72, 1, 0)
		okButton.TextSize = 16
	end
end

local function getShadeTargetTransparency()
	if usesTouchToastLayout() then
		return 1
	end

	return 0.52
end

local function handleViewportChanged()
	if activePrompt or panel.Visible then
		applyPanelLayout()
	end
end

local function bindViewportListener()
	if viewportConnection then
		viewportConnection:Disconnect()
		viewportConnection = nil
	end

	local camera = workspace.CurrentCamera
	if camera then
		viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(handleViewportChanged)
	end
end

local function disconnectActivePromptConnections()
	for _, connection in ipairs(activePromptConnections) do
		connection:Disconnect()
	end
	table.clear(activePromptConnections)
end

local function getRootPart()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function getPromptPosition(prompt)
	local parent = prompt and prompt.Parent
	if not parent then
		return nil
	end

	if parent:IsA("Attachment") then
		return parent.WorldPosition
	elseif parent:IsA("BasePart") then
		return parent.Position
	elseif parent:IsA("Model") then
		return parent:GetPivot().Position
	end

	return nil
end

local function isPromptStillRelevant(prompt)
	if not prompt or not prompt.Parent or prompt.Enabled == false then
		return false
	end

	local rootPart = getRootPart()
	local promptPosition = getPromptPosition(prompt)
	if not rootPart or not promptPosition then
		return true
	end

	return (rootPart.Position - promptPosition).Magnitude <= (prompt.MaxActivationDistance + 6)
end

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

local function findTutorialId(prompt, hint)
	local current = prompt
	while current and current ~= workspace do
		local tutorialId = sanitizeLocalTutorialId(current:GetAttribute("TutorialId"))
		if tutorialId then
			return tutorialId
		end
		current = current.Parent
	end

	local promptPath = prompt and prompt:GetFullName() or "UnknownPrompt"
	local actionText = prompt and prompt.ActionText or "Prompt"
	local fallback = ("%s:%s:%s"):format(actionText, promptPath, hint or "")
	return sanitizeLocalTutorialId(fallback)
end

local function shouldShowTutorial(tutorialId)
	if not tutorialsEnabled then
		return false
	end
	if tutorialId and completedTutorials[tutorialId] == true then
		return false
	end
	return true
end

local function completeTutorial(tutorialId)
	tutorialId = sanitizeLocalTutorialId(tutorialId)
	if not tutorialId or completedTutorials[tutorialId] == true then
		return
	end

	completedTutorials[tutorialId] = true
	tutorialPreferencesRemote:FireServer({
		Action = "Complete",
		TutorialId = tutorialId,
	})
end

local function completeActiveTutorialIfSelected()
	if dontShowAgainSelected and activeTutorialId then
		completeTutorial(activeTutorialId)
	end
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
		applyPanelLayout()

		local shadeTargetTransparency = getShadeTargetTransparency()
		local showShade = shadeTargetTransparency < 1
		shade.Visible = showShade
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
			BackgroundTransparency = shadeTargetTransparency,
		})
		if showShade then
			shadeTween:Play()
		end
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

local function hideHint(prompt)
	if activePrompt ~= prompt then
		return
	end

	activePrompt = nil
	activeTutorialId = nil
	disconnectActivePromptConnections()
	setPanelVisible(false)
end

local function watchActivePrompt(prompt)
	table.insert(activePromptConnections, prompt.AncestryChanged:Connect(function()
		if activePrompt == prompt and not prompt:IsDescendantOf(workspace) then
			hideHint(prompt)
		end
	end))

	table.insert(activePromptConnections, prompt:GetPropertyChangedSignal("Enabled"):Connect(function()
		if activePrompt == prompt and prompt.Enabled == false then
			hideHint(prompt)
		end
	end))

	local lastCheck = 0
	table.insert(activePromptConnections, RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now - lastCheck < 0.2 then
			return
		end

		lastCheck = now
		if activePrompt == prompt and not isPromptStillRelevant(prompt) then
			hideHint(prompt)
		end
	end))
end

local function showHint(prompt, hint, tutorialId)
	disconnectActivePromptConnections()
	activePrompt = prompt
	activeTutorialId = tutorialId
	dontShowAgainSelected = true
	body.Text = hint
	footer.Text = getPromptFooterText(prompt)
	updateDontShowButton()
	watchActivePrompt(prompt)
	setPanelVisible(true)
end

local function hideActiveHint()
	if activePrompt then
		hideHint(activePrompt)
	end
end

bindViewportListener()

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindViewportListener)
UserInputService.LastInputTypeChanged:Connect(handleViewportChanged)

dontShowButton.Activated:Connect(function()
	dontShowAgainSelected = not dontShowAgainSelected
	updateDontShowButton()
end)

okButton.Activated:Connect(function()
	completeActiveTutorialIfSelected()
	hideActiveHint()
end)

tutorialPreferencesRemote.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end

	if payload.Action == "Loaded" or payload.Action == "Completed" then
		tutorialsEnabled = payload.TutorialsEnabled ~= false
		playerGui:SetAttribute(TUTORIALS_ENABLED_ATTRIBUTE, tutorialsEnabled)

		if typeof(payload.Completed) == "table" then
			completedTutorials = {}
			for key, value in pairs(payload.Completed) do
				local tutorialId = sanitizeLocalTutorialId(key)
				if tutorialId and value == true then
					completedTutorials[tutorialId] = true
				end
			end
		elseif typeof(payload.TutorialId) == "string" then
			local tutorialId = sanitizeLocalTutorialId(payload.TutorialId)
			if tutorialId then
				completedTutorials[tutorialId] = true
			end
		end

		if activeTutorialId and (not tutorialsEnabled or completedTutorials[activeTutorialId] == true) then
			hideActiveHint()
		end
	end
end)

playerGui:GetAttributeChangedSignal(TUTORIALS_ENABLED_ATTRIBUTE):Connect(function()
	local enabledAttribute = playerGui:GetAttribute(TUTORIALS_ENABLED_ATTRIBUTE)
	if typeof(enabledAttribute) ~= "boolean" then
		return
	end

	tutorialsEnabled = enabledAttribute
	if not tutorialsEnabled then
		hideActiveHint()
	end
end)

ProximityPromptService.PromptShown:Connect(function(prompt)
	local hint = findHint(prompt)
	if hint then
		local tutorialId = findTutorialId(prompt, hint)
		if shouldShowTutorial(tutorialId) then
			showHint(prompt, hint, tutorialId)
		end
	end
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	if activePrompt == prompt then
		completeActiveTutorialIfSelected()
		hideHint(prompt)
	end
end)

ProximityPromptService.PromptHidden:Connect(hideHint)

tutorialPreferencesRemote:FireServer({
	Action = "Request",
})
