local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local HOVER_CHECK_INTERVAL = 0.05
local MODEL_PROMPT_MAX_TARGET_DISTANCE = 2.4
local PROMPT_EXTRA_REACH = 1.5

local gui = Instance.new("ScreenGui")
gui.Name = "MouseHoverPromptUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local hoverButton = Instance.new("TextButton")
hoverButton.Name = "HoverPromptButton"
hoverButton.AnchorPoint = Vector2.new(0, 0)
hoverButton.AutoButtonColor = true
hoverButton.BackgroundColor3 = Color3.fromRGB(22, 25, 30)
hoverButton.BackgroundTransparency = 0.08
hoverButton.BorderSizePixel = 0
hoverButton.Font = Enum.Font.GothamBold
hoverButton.Position = UDim2.fromOffset(0, 0)
hoverButton.Size = UDim2.fromOffset(178, 48)
hoverButton.Text = ""
hoverButton.TextColor3 = Color3.fromRGB(246, 250, 255)
hoverButton.TextScaled = true
hoverButton.TextWrapped = true
hoverButton.Visible = false
hoverButton.Parent = gui

local hoverCorner = Instance.new("UICorner")
hoverCorner.CornerRadius = UDim.new(0, 8)
hoverCorner.Parent = hoverButton

local currentPrompt = nil
local lastHoverCheck = 0
local lastActivationAt = 0

local function isMouseKeyboardInput(inputType)
	return inputType == Enum.UserInputType.MouseMovement
		or inputType == Enum.UserInputType.MouseButton1
		or inputType == Enum.UserInputType.MouseButton2
		or inputType == Enum.UserInputType.MouseWheel
		or inputType == Enum.UserInputType.Keyboard
end

local usingMouseKeyboard = isMouseKeyboardInput(UserInputService:GetLastInputType())

UserInputService.LastInputTypeChanged:Connect(function(inputType)
	usingMouseKeyboard = isMouseKeyboardInput(inputType)
end)

local function getRootPart()
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
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

local function isPromptInReach(prompt)
	if not prompt or not prompt.Enabled then
		return false
	end

	local rootPart = getRootPart()
	local promptPosition = getPromptPosition(prompt)
	if not rootPart or not promptPosition then
		return false
	end

	return (rootPart.Position - promptPosition).Magnitude <= prompt.MaxActivationDistance + PROMPT_EXTRA_REACH
end

local function getDirectPrompt(instance)
	if not instance then
		return nil
	end

	if instance:IsA("ProximityPrompt") then
		return instance
	end

	return instance:FindFirstChildOfClass("ProximityPrompt")
end

local function getClosestPromptInModel(model, targetPosition)
	local closestPrompt = nil
	local closestDistance = MODEL_PROMPT_MAX_TARGET_DISTANCE

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") then
			local promptPosition = getPromptPosition(descendant)
			if promptPosition then
				local distance = (promptPosition - targetPosition).Magnitude
				if distance <= closestDistance then
					closestDistance = distance
					closestPrompt = descendant
				end
			end
		end
	end

	return closestPrompt
end

local function findHoverPrompt(target)
	if not target then
		return nil
	end

	local directPrompt = getDirectPrompt(target)
	if directPrompt then
		return directPrompt
	end

	local targetPosition = target:IsA("BasePart") and target.Position or nil
	local current = target.Parent

	while current and current ~= workspace do
		if current:IsA("Model") then
			if current:GetAttribute("StrictPromptTargets") then
				return getClosestPromptInModel(current, targetPosition)
			end

			if targetPosition then
				local modelPrompt = getClosestPromptInModel(current, targetPosition)
				if modelPrompt then
					return modelPrompt
				end
			end

			return getDirectPrompt(current)
		elseif current:IsA("BasePart") then
			local prompt = getDirectPrompt(current)
			if prompt then
				return prompt
			end
		elseif current:IsA("Folder") then
			return nil
		end

		current = current.Parent
	end

	return nil
end

local function setCurrentPrompt(prompt)
	if prompt and isPromptInReach(prompt) then
		currentPrompt = prompt
	else
		currentPrompt = nil
	end
end

local function activateCurrentPrompt()
	local prompt = currentPrompt
	if not prompt or not isPromptInReach(prompt) then
		return
	end

	local now = os.clock()
	if now - lastActivationAt < 0.2 then
		return
	end
	lastActivationAt = now

	prompt:InputHoldBegin()
	task.delay(math.max(prompt.HoldDuration, 0) + 0.05, function()
		if prompt.Parent then
			prompt:InputHoldEnd()
		end
	end)
end

local function updateHoverButton()
	if not currentPrompt then
		hoverButton.Visible = false
		return
	end

	local mouseLocation = UserInputService:GetMouseLocation()
	hoverButton.Position = UDim2.fromOffset(mouseLocation.X + 18, mouseLocation.Y + 16)
	hoverButton.Text = ("%s\n%s"):format(
		currentPrompt.ActionText ~= "" and currentPrompt.ActionText or "Interact",
		currentPrompt.ObjectText ~= "" and currentPrompt.ObjectText or "Object"
	)
	hoverButton.Visible = true
end

hoverButton.MouseButton1Click:Connect(activateCurrentPrompt)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end

	activateCurrentPrompt()
end)

RunService.RenderStepped:Connect(function()
	if not usingMouseKeyboard or UserInputService:GetFocusedTextBox() then
		currentPrompt = nil
		hoverButton.Visible = false
		return
	end

	local now = os.clock()
	if now - lastHoverCheck >= HOVER_CHECK_INTERVAL then
		lastHoverCheck = now
		setCurrentPrompt(findHoverPrompt(mouse.Target))
	end

	updateHoverButton()
end)
