local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BunkerEnergyService = require(script.Parent:WaitForChild("BunkerEnergyService"))
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local DevToolsService = require(script.Parent:WaitForChild("DevToolsService"))
local DiscoveryService = require(script.Parent:WaitForChild("DiscoveryService"))
local EventManager = require(script.Parent:WaitForChild("EventManager"))
local FeedbackService = require(script.Parent:WaitForChild("FeedbackService"))
local InteractionService = require(script.Parent:WaitForChild("InteractionService"))
local LocationPingService = require(script.Parent:WaitForChild("LocationPingService"))
local MovementAuthorityService = require(script.Parent:WaitForChild("MovementAuthorityService"))
local ModerationService = require(script.Parent:WaitForChild("ModerationService"))
local PermissionService = require(script.Parent:WaitForChild("PermissionService"))
local RemoteService = require(script.Parent:WaitForChild("RemoteService"))
local ResetService = require(script.Parent:WaitForChild("ResetService"))
local RoomProgressService = require(script.Parent:WaitForChild("RoomProgressService"))
local RoomBuilder = require(script.Parent:WaitForChild("RoomBuilder"))
local UiLayoutService = require(script.Parent:WaitForChild("UiLayoutService"))
local VictoryBrickService = require(script.Parent:WaitForChild("VictoryBrickService"))

workspace.Gravity = Constants.NormalGravity
RemoteService.Initialize()

local roomReferences = RoomBuilder.Build()
local permissionService = PermissionService.new()
permissionService:Initialize()

local moderationService = ModerationService.new(permissionService)
moderationService:Initialize()

local discoveryService = DiscoveryService.new()
discoveryService:Initialize()

local roomProgressService = RoomProgressService.new(discoveryService)
roomProgressService:Initialize()

local movementAuthorityService = MovementAuthorityService.new()
movementAuthorityService:Initialize()
roomProgressService:SetMovementAuthorityService(movementAuthorityService)

local locationPingService = LocationPingService.new()
locationPingService:Initialize()

local uiLayoutService = UiLayoutService.new()
uiLayoutService:Initialize()

local bunkerEnergyService = BunkerEnergyService.new(discoveryService, movementAuthorityService)
bunkerEnergyService:Initialize()

local victoryBrickService = VictoryBrickService.new(discoveryService)
victoryBrickService:Initialize()

local feedbackOk, feedbackServiceOrError = pcall(function()
	local feedbackService = FeedbackService.new(roomProgressService)
	feedbackService:Initialize()
	return feedbackService
end)
if not feedbackOk then
	warn(("[DON'T TOUCH IT] Feedback service did not start: %s"):format(tostring(feedbackServiceOrError)))
end

local eventManager = EventManager.new(discoveryService, ResetService, roomReferences, roomProgressService, bunkerEnergyService)
local interactionService =
	InteractionService.new(eventManager, discoveryService, ResetService, roomProgressService, movementAuthorityService, bunkerEnergyService, victoryBrickService)
interactionService:Initialize()

local devToolsService =
	DevToolsService.new(
		discoveryService,
		roomProgressService,
		eventManager,
		ResetService,
		interactionService,
		movementAuthorityService,
		bunkerEnergyService,
		permissionService,
		moderationService
	)
devToolsService:Initialize()

print("[DON'T TOUCH IT] Prototype initialized.")
