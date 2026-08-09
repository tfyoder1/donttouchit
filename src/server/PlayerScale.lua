local PlayerScale = {}

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

return PlayerScale
