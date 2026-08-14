local PlayerScale = {}
local activeScalesByUserId = {}

local SCALE_VALUE_NAMES = {
	"BodyDepthScale",
	"BodyHeightScale",
	"BodyWidthScale",
	"HeadScale",
}

local function getCharacter(player)
	local character = player.Character
	if character and character.Parent then
		return character
	end

	return nil
end

function PlayerScale.Apply(player, scaleMultiplier)
	local character = getCharacter(player)
	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end

	local snapshot = {
		Character = character,
		Humanoid = humanoid,
		Values = {},
		ModelScale = nil,
		UsedBodyScaleValues = false,
	}

	for _, valueName in ipairs(SCALE_VALUE_NAMES) do
		local value = humanoid:FindFirstChild(valueName)

		if value and value:IsA("NumberValue") then
			snapshot.Values[valueName] = value.Value
			value.Value = value.Value * scaleMultiplier
			snapshot.UsedBodyScaleValues = true
		end
	end

	if not snapshot.UsedBodyScaleValues and character.GetScale and character.ScaleTo then
		snapshot.ModelScale = character:GetScale()
		character:ScaleTo(snapshot.ModelScale * scaleMultiplier)
	end

	return snapshot
end

function PlayerScale.Restore(snapshot)
	if not snapshot or not snapshot.Character or not snapshot.Character.Parent then
		return
	end

	local humanoid = snapshot.Humanoid
	if not humanoid or not humanoid.Parent then
		return
	end

	if snapshot.UsedBodyScaleValues then
		for valueName, originalValue in pairs(snapshot.Values) do
			local value = humanoid:FindFirstChild(valueName)
			if value and value:IsA("NumberValue") then
				value.Value = originalValue
			end
		end
	elseif snapshot.ModelScale and snapshot.Character.ScaleTo then
		snapshot.Character:ScaleTo(snapshot.ModelScale)
	end
end

function PlayerScale.RestoreActive(player)
	if not player then
		return
	end

	local active = activeScalesByUserId[player.UserId]
	if not active then
		return
	end

	activeScalesByUserId[player.UserId] = nil
	PlayerScale.Restore(active.Snapshot)
end

function PlayerScale.RestoreAllActive()
	for userId, active in pairs(activeScalesByUserId) do
		activeScalesByUserId[userId] = nil
		PlayerScale.Restore(active.Snapshot)
	end
end

function PlayerScale.ApplyTemporary(player, scaleMultiplier, duration)
	if not player then
		return nil
	end

	PlayerScale.RestoreActive(player)

	local snapshot = PlayerScale.Apply(player, scaleMultiplier)
	if not snapshot then
		return nil
	end

	local token = {}
	activeScalesByUserId[player.UserId] = {
		Snapshot = snapshot,
		Token = token,
	}

	task.delay(math.max(0.1, duration or 10), function()
		local active = activeScalesByUserId[player.UserId]
		if active and active.Token == token then
			PlayerScale.RestoreActive(player)
		end
	end)

	return snapshot
end

return PlayerScale
