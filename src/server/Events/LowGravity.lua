local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

return {
	Id = "low_gravity",
	Name = "Low Gravity",
	Weight = 0,
	StartMessage = "Gravity just got very negotiable.",

	Run = function(context)
		local oldLighting = {
			Ambient = Lighting.Ambient,
			Brightness = Lighting.Brightness,
			ColorShift_Top = Lighting.ColorShift_Top,
			ColorShift_Bottom = Lighting.ColorShift_Bottom,
			OutdoorAmbient = Lighting.OutdoorAmbient,
		}
		local colorCorrection = Instance.new("ColorCorrectionEffect")
		colorCorrection.Name = "LowGravityOptic"
		colorCorrection.Brightness = 0.06
		colorCorrection.Contrast = 0.18
		colorCorrection.Saturation = 0.38
		colorCorrection.TintColor = Color3.fromRGB(154, 218, 255)
		colorCorrection.Parent = Lighting

		local bloom = Instance.new("BloomEffect")
		bloom.Name = "LowGravityBloom"
		bloom.Intensity = 0.45
		bloom.Size = 32
		bloom.Threshold = 1.2
		bloom.Parent = Lighting

		workspace.Gravity = 45
		context.DiscoveryService:UnlockForAll(Constants.Discoveries.LowGravity.Id)
		for index = 1, Constants.EventDuration * 2 do
			local color = index % 2 == 0 and Color3.fromRGB(142, 210, 255) or Color3.fromRGB(218, 156, 255)
			Lighting.Ambient = color
			Lighting.OutdoorAmbient = color:Lerp(Color3.fromRGB(255, 255, 255), 0.2)
			Lighting.ColorShift_Top = color
			Lighting.Brightness = 2.4
			colorCorrection.TintColor = color
			task.wait(0.5)
		end

		workspace.Gravity = Constants.NormalGravity
		colorCorrection:Destroy()
		bloom:Destroy()

		for propertyName, value in pairs(oldLighting) do
			Lighting[propertyName] = value
		end
	end,
}
