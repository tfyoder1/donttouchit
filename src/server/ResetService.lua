local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local PlayerScale = require(script.Parent:WaitForChild("PlayerScale"))

local ResetService = {}

local trackedRoots = {}
local lightingBaseline = nil

local BASE_ATTRIBUTES = {
	CFrame = "BaseCFrame",
	Size = "BaseSize",
	Color = "BaseColor",
	Transparency = "BaseTransparency",
	CanCollide = "BaseCanCollide",
	CanQuery = "BaseCanQuery",
	CanTouch = "BaseCanTouch",
	Anchored = "BaseAnchored",
	Material = "BaseMaterial",
}

local function getMaterialByName(materialName)
	for _, material in ipairs(Enum.Material:GetEnumItems()) do
		if material.Name == materialName then
			return material
		end
	end

	return nil
end

function ResetService.MarkBaseline(instance)
	if instance:IsA("BasePart") then
		instance:SetAttribute(BASE_ATTRIBUTES.CFrame, instance.CFrame)
		instance:SetAttribute(BASE_ATTRIBUTES.Size, instance.Size)
		instance:SetAttribute(BASE_ATTRIBUTES.Color, instance.Color)
		instance:SetAttribute(BASE_ATTRIBUTES.Transparency, instance.Transparency)
		instance:SetAttribute(BASE_ATTRIBUTES.CanCollide, instance.CanCollide)
		instance:SetAttribute(BASE_ATTRIBUTES.CanQuery, instance.CanQuery)
		instance:SetAttribute(BASE_ATTRIBUTES.CanTouch, instance.CanTouch)
		instance:SetAttribute(BASE_ATTRIBUTES.Anchored, instance.Anchored)
		instance:SetAttribute(BASE_ATTRIBUTES.Material, instance.Material.Name)
	elseif instance:IsA("PointLight") or instance:IsA("SpotLight") or instance:IsA("SurfaceLight") then
		instance:SetAttribute("BaseEnabled", instance.Enabled)
		instance:SetAttribute("BaseBrightness", instance.Brightness)
		instance:SetAttribute("BaseColor", instance.Color)
		instance:SetAttribute("BaseRange", instance.Range)
	elseif instance:IsA("ProximityPrompt") then
		instance:SetAttribute("BaseEnabled", instance.Enabled)
		instance:SetAttribute("BaseActionText", instance.ActionText)
		instance:SetAttribute("BaseObjectText", instance.ObjectText)
	elseif instance:IsA("SurfaceGui") then
		instance:SetAttribute("BaseEnabled", instance.Enabled)
	elseif instance:IsA("TextLabel") then
		instance:SetAttribute("BaseText", instance.Text)
		instance:SetAttribute("BaseTextColor3", instance.TextColor3)
		instance:SetAttribute("BaseBackgroundColor3", instance.BackgroundColor3)
	end
end

local function restorePart(part)
	local baseCFrame = part:GetAttribute(BASE_ATTRIBUTES.CFrame)

	if baseCFrame then
		part.CFrame = baseCFrame
	end

	local baseSize = part:GetAttribute(BASE_ATTRIBUTES.Size)
	if baseSize then
		part.Size = baseSize
	end

	local baseColor = part:GetAttribute(BASE_ATTRIBUTES.Color)
	if baseColor then
		part.Color = baseColor
	end

	local baseTransparency = part:GetAttribute(BASE_ATTRIBUTES.Transparency)
	if baseTransparency ~= nil then
		part.Transparency = baseTransparency
	end

	local baseCanCollide = part:GetAttribute(BASE_ATTRIBUTES.CanCollide)
	if baseCanCollide ~= nil then
		part.CanCollide = baseCanCollide
	end

	local baseCanQuery = part:GetAttribute(BASE_ATTRIBUTES.CanQuery)
	if baseCanQuery ~= nil then
		part.CanQuery = baseCanQuery
	end

	local baseCanTouch = part:GetAttribute(BASE_ATTRIBUTES.CanTouch)
	if baseCanTouch ~= nil then
		part.CanTouch = baseCanTouch
	end

	local baseAnchored = part:GetAttribute(BASE_ATTRIBUTES.Anchored)
	if baseAnchored ~= nil then
		part.Anchored = baseAnchored
	end

	local baseMaterial = part:GetAttribute(BASE_ATTRIBUTES.Material)
	local material = baseMaterial and getMaterialByName(baseMaterial)
	if material then
		part.Material = material
	end
end

local function restoreLight(light)
	local baseEnabled = light:GetAttribute("BaseEnabled")
	if baseEnabled ~= nil then
		light.Enabled = baseEnabled
	end

	local baseBrightness = light:GetAttribute("BaseBrightness")
	if baseBrightness then
		light.Brightness = baseBrightness
	end

	local baseColor = light:GetAttribute("BaseColor")
	if baseColor then
		light.Color = baseColor
	end

	local baseRange = light:GetAttribute("BaseRange")
	if baseRange then
		light.Range = baseRange
	end
end

local function restorePrompt(prompt)
	local baseEnabled = prompt:GetAttribute("BaseEnabled")
	if baseEnabled ~= nil then
		prompt.Enabled = baseEnabled
	end

	local baseActionText = prompt:GetAttribute("BaseActionText")
	if baseActionText then
		prompt.ActionText = baseActionText
	end

	local baseObjectText = prompt:GetAttribute("BaseObjectText")
	if baseObjectText then
		prompt.ObjectText = baseObjectText
	end
end

local function restoreTextLabel(textLabel)
	local baseText = textLabel:GetAttribute("BaseText")
	if baseText then
		textLabel.Text = baseText
	end

	local baseTextColor = textLabel:GetAttribute("BaseTextColor3")
	if baseTextColor then
		textLabel.TextColor3 = baseTextColor
	end

	local baseBackgroundColor = textLabel:GetAttribute("BaseBackgroundColor3")
	if baseBackgroundColor then
		textLabel.BackgroundColor3 = baseBackgroundColor
	end
end

local function restoreSurfaceGui(surfaceGui)
	local baseEnabled = surfaceGui:GetAttribute("BaseEnabled")
	if baseEnabled ~= nil then
		surfaceGui.Enabled = baseEnabled
	end
end

function ResetService.RestoreInstance(root)
	if not root then
		return
	end

	local descendants = root:GetDescendants()
	table.insert(descendants, root)

	for _, instance in ipairs(descendants) do
		if instance:IsA("BasePart") then
			restorePart(instance)
		elseif instance:IsA("PointLight") or instance:IsA("SpotLight") or instance:IsA("SurfaceLight") then
			restoreLight(instance)
		elseif instance:IsA("ProximityPrompt") then
			restorePrompt(instance)
		elseif instance:IsA("SurfaceGui") then
			restoreSurfaceGui(instance)
		elseif instance:IsA("TextLabel") then
			restoreTextLabel(instance)
		end
	end
end

function ResetService.CaptureRoots(...)
	trackedRoots = { ... }
	lightingBaseline = {
		Ambient = Lighting.Ambient,
		Brightness = Lighting.Brightness,
		ClockTime = Lighting.ClockTime,
		ColorShift_Bottom = Lighting.ColorShift_Bottom,
		ColorShift_Top = Lighting.ColorShift_Top,
		OutdoorAmbient = Lighting.OutdoorAmbient,
	}
end

function ResetService.RestoreLighting()
	if not lightingBaseline then
		return
	end

	for propertyName, value in pairs(lightingBaseline) do
		Lighting[propertyName] = value
	end
end

function ResetService.RestoreAll()
	workspace.Gravity = Constants.NormalGravity
	ResetService.RestoreLighting()
	PlayerScale.RestoreAllActive()

	for _, temporaryObject in ipairs(CollectionService:GetTagged(Constants.Tags.TemporaryObject)) do
		if temporaryObject and temporaryObject.Parent then
			temporaryObject:Destroy()
		end
	end

	for _, root in ipairs(trackedRoots) do
		ResetService.RestoreInstance(root)
	end
end

return ResetService
