local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local TouchControls = require(script.Parent:WaitForChild("TouchControls"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local pingRemote = remotes:WaitForChild(Constants.Remotes.LocationPing)

local PING_ACTION = "DontTouchItLocationPing"
local PING_RANGE = 320
local CLIENT_COOLDOWN_SECONDS = 0.35
local PING_LIFETIME_SECONDS = 5.5
local PING_FOLDER_NAME = "DontTouchItLocationPings"

local lastPingAt = 0

local function getRootPart()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function getPingFolder()
	local folder = Workspace:FindFirstChild(PING_FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = PING_FOLDER_NAME
		folder.Parent = Workspace
	end
	return folder
end

local function sanitizeLabel(value)
	local text = tostring(value or "")
	text = text:gsub("DontTouchIt", "")
	text = text:gsub("([a-z])([A-Z])", "%1 %2")
	text = text:gsub("[%c\r\n\t_]+", " ")
	text = text:gsub("%s+", " ")
	text = text:match("^%s*(.-)%s*$") or ""
	if text == "" then
		return "here"
	end
	if #text > 42 then
		text = text:sub(1, 41) .. "."
	end
	return text
end

local function getPromptLabel(instance)
	local current = instance
	local steps = 0
	while current and current ~= Workspace and steps < 5 do
		if current:IsA("BasePart") then
			local prompt = current:FindFirstChildWhichIsA("ProximityPrompt")
			if prompt then
				if prompt.ObjectText and prompt.ObjectText ~= "" then
					return sanitizeLabel(prompt.ObjectText)
				end
				if prompt.ActionText and prompt.ActionText ~= "" then
					return sanitizeLabel(prompt.ActionText)
				end
			end
		end
		current = current.Parent
		steps += 1
	end
	return nil
end

local function getInstanceLabel(instance)
	if not instance then
		return "here"
	end

	local promptLabel = getPromptLabel(instance)
	if promptLabel then
		return promptLabel
	end

	if instance:IsA("BasePart") then
		if instance.Name:find("Floor") or instance.Name:find("Wall") or instance.Name:find("Ceiling") then
			return "here"
		end
		return sanitizeLabel(instance.Name)
	end

	local ancestorModel = instance:FindFirstAncestorOfClass("Model")
	if ancestorModel and ancestorModel ~= player.Character then
		return sanitizeLabel(ancestorModel.Name)
	end

	return "here"
end

local function getRaycastParams()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude = {}
	if player.Character then
		table.insert(exclude, player.Character)
	end

	local pingFolder = Workspace:FindFirstChild(PING_FOLDER_NAME)
	if pingFolder then
		table.insert(exclude, pingFolder)
	end

	params.FilterDescendantsInstances = exclude
	params.IgnoreWater = false
	return params
end

local function getPingTarget()
	local camera = Workspace.CurrentCamera
	if not camera then
		local rootPart = getRootPart()
		if not rootPart then
			return nil
		end
		return rootPart.Position + rootPart.CFrame.LookVector * 18, "here"
	end

	local viewport = camera.ViewportSize
	local ray = camera:ViewportPointToRay(viewport.X * 0.5, viewport.Y * 0.5)
	local result = Workspace:Raycast(ray.Origin, ray.Direction * PING_RANGE, getRaycastParams())
	if result then
		return result.Position, getInstanceLabel(result.Instance)
	end

	local rootPart = getRootPart()
	if rootPart then
		return rootPart.Position + rootPart.CFrame.LookVector * 24, "here"
	end

	return ray.Origin + ray.Direction * 24, "here"
end

local function isBlockingUiOpen()
	local ui = playerGui:FindFirstChild("DontTouchItUI")
	if not ui then
		return false
	end

	local referenceBook = ui:FindFirstChild("ReferenceBook")
	if referenceBook and referenceBook.Visible then
		return true
	end

	local startOverlay = ui:FindFirstChild("StartChoiceOverlay")
	if startOverlay and startOverlay.Visible then
		return true
	end

	return false
end

local function sendPing()
	local now = os.clock()
	if now - lastPingAt < CLIENT_COOLDOWN_SECONDS then
		return
	end

	if UserInputService:GetFocusedTextBox() or isBlockingUiOpen() then
		return
	end

	local position, targetName = getPingTarget()
	if not position then
		return
	end

	lastPingAt = now
	pingRemote:FireServer({
		Action = "Ping",
		Position = position,
		TargetName = targetName,
	})
end

local function formatPingText(payload)
	local senderName = sanitizeLabel(payload.SenderName or "Player")
	local targetName = sanitizeLabel(payload.TargetName or "here")
	return ("%s: %s"):format(senderName, targetName)
end

local function showPing(payload)
	if typeof(payload) ~= "table" or payload.Action ~= "Show" or typeof(payload.Position) ~= "Vector3" then
		return
	end

	local folder = getPingFolder()
	local isLocalPlayer = payload.SenderUserId == player.UserId
	local color = if isLocalPlayer then Color3.fromRGB(119, 255, 203) else Color3.fromRGB(255, 229, 161)
	local marker = Instance.new("Part")
	marker.Name = "DontTouchItLocationPing"
	marker.Shape = Enum.PartType.Ball
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanQuery = false
	marker.CanTouch = false
	marker.Material = Enum.Material.Neon
	marker.Color = color
	marker.Size = Vector3.new(0.68, 0.68, 0.68)
	marker.CFrame = CFrame.new(payload.Position + Vector3.new(0, 0.55, 0))
	marker.Parent = folder

	local light = Instance.new("PointLight")
	light.Name = "PingLight"
	light.Brightness = 1.7
	light.Range = 12
	light.Color = color
	light.Parent = marker

	local label = Instance.new("BillboardGui")
	label.Name = "PingLabel"
	label.Adornee = marker
	label.AlwaysOnTop = true
	label.LightInfluence = 0
	label.MaxDistance = 260
	label.Size = UDim2.fromOffset(190, 50)
	label.StudsOffsetWorldSpace = Vector3.new(0, 2.1, 0)
	label.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	label.Parent = marker

	local text = Instance.new("TextLabel")
	text.BackgroundColor3 = Color3.fromRGB(10, 14, 18)
	text.BackgroundTransparency = 0.08
	text.BorderSizePixel = 0
	text.Font = Enum.Font.GothamBlack
	text.Size = UDim2.fromScale(1, 1)
	text.Text = formatPingText(payload)
	text.TextColor3 = color
	text.TextScaled = true
	text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	text.TextStrokeTransparency = 0.2
	text.TextWrapped = true
	text.Parent = label

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = text

	task.delay(math.max(0.1, PING_LIFETIME_SECONDS - 0.8), function()
		if not marker.Parent then
			return
		end

		TweenService:Create(marker, TweenInfo.new(0.65, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			Transparency = 1,
			Size = Vector3.new(0.18, 0.18, 0.18),
		}):Play()
		TweenService:Create(light, TweenInfo.new(0.65, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			Brightness = 0,
		}):Play()
		TweenService:Create(text, TweenInfo.new(0.65, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1,
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		}):Play()
	end)

	task.delay(PING_LIFETIME_SECONDS, function()
		if marker.Parent then
			marker:Destroy()
		end
	end)
end

local function setupTouchPingButton()
	TouchControls.RegisterAction({
		Id = "Ping",
		Label = "Ping",
		Text = "Ping",
		Order = 30,
		Desktop = "G",
		Xbox = "D-pad left",
		Touch = "Ping button",
		Position = UDim2.new(1, -170, 1, -176),
		TextColor = Color3.fromRGB(216, 245, 255),
		StrokeColor = Color3.fromRGB(102, 217, 255),
		OnActivated = sendPing,
	})
end

ContextActionService:UnbindAction(PING_ACTION)
ContextActionService:BindAction(PING_ACTION, function(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Sink
	end

	sendPing()
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.DPadLeft, Enum.KeyCode.G)

pcall(function()
	ContextActionService:SetTitle(PING_ACTION, "Ping")
	ContextActionService:SetPosition(PING_ACTION, UDim2.fromScale(0.72, 0.42))
end)

setupTouchPingButton()

pingRemote.OnClientEvent:Connect(showPing)
