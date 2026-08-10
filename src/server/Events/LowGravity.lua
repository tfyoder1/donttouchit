local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

return {
	Id = "low_gravity",
	Name = "Low Gravity",
	Weight = 0,
	StartMessage = "Gravity just got very negotiable.",

	Run = function(context)
		local existingOptic = Lighting:FindFirstChild("LowGravityOptic")
		local existingBloom = Lighting:FindFirstChild("LowGravityBloom")
		if existingOptic then
			existingOptic:Destroy()
		end
		if existingBloom then
			existingBloom:Destroy()
		end

		local colorCorrection = Instance.new("ColorCorrectionEffect")
		colorCorrection.Name = "LowGravityOptic"
		colorCorrection.Brightness = 0.06
		colorCorrection.Contrast = 0.18
		colorCorrection.Saturation = 0.38
		colorCorrection.TintColor = Color3.fromRGB(154, 218, 255)
		colorCorrection.Parent = Lighting
		CollectionService:AddTag(colorCorrection, Constants.Tags.TemporaryObject)

		local bloom = Instance.new("BloomEffect")
		bloom.Name = "LowGravityBloom"
		bloom.Intensity = 0.45
		bloom.Size = 32
		bloom.Threshold = 1.2
		bloom.Parent = Lighting
		CollectionService:AddTag(bloom, Constants.Tags.TemporaryObject)

		workspace.Gravity = 45
		context.DiscoveryService:UnlockForAll(Constants.Discoveries.LowGravity.Id)

		task.spawn(function()
			local index = 0
			while colorCorrection.Parent and bloom.Parent do
				index += 1
				local color = index % 2 == 0 and Color3.fromRGB(142, 210, 255) or Color3.fromRGB(218, 156, 255)
				Lighting.Ambient = color
				Lighting.OutdoorAmbient = color:Lerp(Color3.fromRGB(255, 255, 255), 0.2)
				Lighting.ColorShift_Top = color
				Lighting.Brightness = 2.4
				colorCorrection.TintColor = color
				task.wait(0.5)
			end
		end)

		if context.BroadcastMessage then
			context.BroadcastMessage("Low gravity will keep misbehaving until someone presses RESET ROOM.")
		end

		task.wait(1)
	end,
}
