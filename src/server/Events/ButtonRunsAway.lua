local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local function tweenModel(model, targetPivot, duration)
	local pivotValue = Instance.new("CFrameValue")
	pivotValue.Value = model:GetPivot()

	local connection = pivotValue:GetPropertyChangedSignal("Value"):Connect(function()
		if model.Parent then
			model:PivotTo(pivotValue.Value)
		end
	end)

	local tween = TweenService:Create(
		pivotValue,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Value = targetPivot }
	)

	tween:Play()
	tween.Completed:Wait()
	connection:Disconnect()
	pivotValue:Destroy()
end

return {
	Id = "button_runs_away",
	Name = "Button Runs Away",
	Weight = 1,
	StartMessage = "The button has reconsidered its career.",

	Run = function(context)
		local pedestal = context.RoomReferences.Pedestal
		if not pedestal or not pedestal.Parent then
			task.wait(1)
			return
		end

		local basePivot = pedestal:GetPivot()
		local buttonPosition = basePivot.Position
		local direction = Vector3.new(1, 0, 0)

		local character = context.TriggeringPlayer and context.TriggeringPlayer.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")

		if rootPart then
			local away = buttonPosition - rootPart.Position
			local flatAway = Vector3.new(away.X, 0, away.Z)

			if flatAway.Magnitude > 0.1 then
				direction = flatAway.Unit
			end
		end

		local targetPivot = basePivot + direction * 10
		tweenModel(pedestal, targetPivot, 0.75)
		task.wait(math.max(1, Constants.EventDuration - 3))
		tweenModel(pedestal, basePivot, 0.9)
	end,
}

