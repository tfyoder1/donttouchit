local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local SIGNAL_BAND_ATTRIBUTE = "DontTouchItSignalBandEquipped"
local TARGET_ROOM_ID = Constants.Prologue.ContainmentRoomId or "TVRoom"

local originalStateByInstance = {}

local function isPostInfirmaryDoor(instance)
	return instance
		and instance:IsA("BasePart")
		and instance:GetAttribute("RoomId") == TARGET_ROOM_ID
		and instance:GetAttribute("RemoveAfterSignalBand") == true
end

local function rememberState(instance)
	if originalStateByInstance[instance] then
		return
	end

	originalStateByInstance[instance] = {
		CanCollide = instance.CanCollide,
		CanQuery = instance.CanQuery,
		CanTouch = instance.CanTouch,
		LocalTransparencyModifier = instance.LocalTransparencyModifier,
		Prompts = {},
		Guis = {},
	}

	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") then
			originalStateByInstance[instance].Prompts[descendant] = descendant.Enabled
		elseif descendant:IsA("SurfaceGui") or descendant:IsA("BillboardGui") then
			originalStateByInstance[instance].Guis[descendant] = descendant.Enabled
		end
	end
end

local function applyRemovedState(instance)
	rememberState(instance)

	instance.CanCollide = false
	instance.CanQuery = false
	instance.CanTouch = false
	instance.LocalTransparencyModifier = 1

	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") then
			descendant.Enabled = false
		elseif descendant:IsA("SurfaceGui") or descendant:IsA("BillboardGui") then
			descendant.Enabled = false
		end
	end
end

local function restoreState(instance)
	local state = originalStateByInstance[instance]
	if not state then
		return
	end

	instance.CanCollide = state.CanCollide
	instance.CanQuery = state.CanQuery
	instance.CanTouch = state.CanTouch
	instance.LocalTransparencyModifier = state.LocalTransparencyModifier or 0

	for gui, enabled in pairs(state.Guis) do
		if gui.Parent then
			gui.Enabled = enabled
		end
	end

	for prompt, enabled in pairs(state.Prompts) do
		if prompt.Parent then
			prompt.Enabled = enabled
		end
	end
end

local function updateDoor(instance)
	if not isPostInfirmaryDoor(instance) then
		return
	end

	if player:GetAttribute(SIGNAL_BAND_ATTRIBUTE) == true then
		applyRemovedState(instance)
	else
		restoreState(instance)
	end
end

local function updateAllDoors()
	for _, instance in ipairs(CollectionService:GetTagged(Constants.Tags.ExitDoor)) do
		updateDoor(instance)
	end
end

CollectionService:GetInstanceAddedSignal(Constants.Tags.ExitDoor):Connect(function(instance)
	task.defer(updateDoor, instance)
end)

player:GetAttributeChangedSignal(SIGNAL_BAND_ATTRIBUTE):Connect(updateAllDoors)
task.defer(updateAllDoors)
