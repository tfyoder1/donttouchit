local UiLayerController = {}

UiLayerController.GuiNames = {
	CoreHud = "DontTouchItCoreHud",
	DiscoveryUI = "DontTouchItUI",
	DevTools = "DontTouchItDevTools",
	TitleSplash = "DontTouchItTitleSplash",
	TouchControls = "DontTouchItTouchControls",
	ControlOptions = "DontTouchItControlOptions",
}

UiLayerController.DisplayOrder = {
	Background = 10,
	CoreHud = 35,
	DevTools = 100,
	Tutorial = 120,
	TouchControls = 145,
	ControlOptions = 155,
	RoomMenu = 170,
	DevFlyControls = 172,
	StartOverlay = 180,
	TitleSplash = 210,
	Emergency = 250,
}

function UiLayerController.ApplyRole(gui, role)
	if not gui then
		return
	end

	gui:SetAttribute("DontTouchItUiLayerRole", role)
	gui.DisplayOrder = UiLayerController.DisplayOrder[role] or UiLayerController.DisplayOrder.Background
end

function UiLayerController.IsTitleSplashVisible(playerGui)
	local splashGui = playerGui and playerGui:FindFirstChild(UiLayerController.GuiNames.TitleSplash)
	return splashGui and splashGui:IsA("ScreenGui") and splashGui.Enabled ~= false
end

function UiLayerController.SetRoomMenuOpen(gui, open)
	if not gui then
		return
	end

	gui.Enabled = true
	UiLayerController.ApplyRole(gui, open and "RoomMenu" or "Background")
	gui:SetAttribute("DontTouchItRoomMenuOpen", open == true)
end

function UiLayerController.SetStartOverlayOpen(gui, open)
	if not gui then
		return
	end

	gui.Enabled = true
	UiLayerController.ApplyRole(gui, open and "StartOverlay" or "Background")
end

function UiLayerController.SetTitleSuppressed(gui, suppressed)
	if gui then
		gui:SetAttribute("GameplayHudSuppressed", suppressed == true)
	end
end

return UiLayerController
