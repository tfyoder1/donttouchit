local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local DiscoveryService = require(script.Parent:WaitForChild("DiscoveryService"))
local EventManager = require(script.Parent:WaitForChild("EventManager"))
local FeedbackService = require(script.Parent:WaitForChild("FeedbackService"))
local InteractionService = require(script.Parent:WaitForChild("InteractionService"))
local RemoteService = require(script.Parent:WaitForChild("RemoteService"))
local ResetService = require(script.Parent:WaitForChild("ResetService"))
local RoomProgressService = require(script.Parent:WaitForChild("RoomProgressService"))
local RoomBuilder = require(script.Parent:WaitForChild("RoomBuilder"))

workspace.Gravity = Constants.NormalGravity
RemoteService.Initialize()

local roomReferences = RoomBuilder.Build()
local discoveryService = DiscoveryService.new()
discoveryService:Initialize()

local roomProgressService = RoomProgressService.new(discoveryService)
roomProgressService:Initialize()

local feedbackService = FeedbackService.new(roomProgressService)
feedbackService:Initialize()

local eventManager = EventManager.new(discoveryService, ResetService, roomReferences, roomProgressService)
local interactionService = InteractionService.new(eventManager, discoveryService, ResetService, roomProgressService)
interactionService:Initialize()

print("[DON'T TOUCH IT] Prototype initialized.")
