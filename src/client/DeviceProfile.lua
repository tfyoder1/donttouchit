local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local DeviceProfile = {}

local function getViewport()
	local camera = Workspace.CurrentCamera
	if camera then
		return camera.ViewportSize
	end

	return Vector2.new(1024, 768)
end

local function getPreferredInputName()
	local ok, preferredInput = pcall(function()
		return UserInputService.PreferredInput
	end)

	if ok and preferredInput then
		return preferredInput.Name
	end

	return ""
end

function DeviceProfile.Get()
	local viewport = getViewport()
	local shortSide = math.min(viewport.X, viewport.Y)
	local longSide = math.max(viewport.X, viewport.Y)
	local touch = UserInputService.TouchEnabled
	local keyboard = UserInputService.KeyboardEnabled
	local mouse = UserInputService.MouseEnabled
	local gamepad = UserInputService.GamepadEnabled
	local preferredInputName = getPreferredInputName()
	local gamepadFirst = preferredInputName == "Gamepad"
	local phone = touch and shortSide <= 720 and longSide <= 1500
	local tablet = touch and not phone
	local console = gamepadFirst or (gamepad and not touch and not keyboard and not mouse)
	local name = "Desktop"

	if phone then
		name = "Phone"
	elseif tablet then
		name = "Tablet"
	elseif console then
		name = "Gamepad"
	end

	return {
		Name = name,
		IsPhone = phone,
		IsTablet = tablet,
		IsTouch = touch,
		IsGamepad = console,
		IsDesktop = name == "Desktop",
		Viewport = viewport,
		ShortSide = shortSide,
		LongSide = longSide,
	}
end

function DeviceProfile.Bind(callback)
	local connections = {}

	local function fire()
		callback(DeviceProfile.Get())
	end

	table.insert(connections, UserInputService.LastInputTypeChanged:Connect(fire))
	table.insert(connections, Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		fire()
		local camera = Workspace.CurrentCamera
		if camera then
			table.insert(connections, camera:GetPropertyChangedSignal("ViewportSize"):Connect(fire))
		end
	end))

	local camera = Workspace.CurrentCamera
	if camera then
		table.insert(connections, camera:GetPropertyChangedSignal("ViewportSize"):Connect(fire))
	end

	fire()

	return function()
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
	end
end

return DeviceProfile
