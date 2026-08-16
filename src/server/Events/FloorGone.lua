local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local function shuffledCopy(list)
	local copy = table.clone(list)
	local random = Random.new()

	for index = #copy, 2, -1 do
		local swapIndex = random:NextInteger(1, index)
		copy[index], copy[swapIndex] = copy[swapIndex], copy[index]
	end

	return copy
end

return {
	Id = "floor_gone",
	Name = "Floor Gone",
	Weight = 1,
	StartMessage = "The floor would like some personal space.",

	Run = function()
		local floorSections = shuffledCopy(CollectionService:GetTagged(Constants.Tags.FloorSection))
		local sectionsToHide = math.min(7, #floorSections)

		for index = 1, sectionsToHide do
			local section = floorSections[index]
			if section and section.Parent and section:GetAttribute("FloorGoneProtected") ~= true then
				section.Transparency = 1
				section.CanCollide = false
			end
		end

		task.wait(Constants.EventDuration)
	end,
}
