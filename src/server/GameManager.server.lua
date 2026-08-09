local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local DiscoveryService = require(script.Parent:WaitForChild("DiscoveryService"))
local EventManager = require(script.Parent:WaitForChild("EventManager"))
local InteractionService = require(script.Parent:WaitForChild("InteractionService"))
local RemoteService = require(script.Parent:WaitForChild("RemoteService"))
local ResetService = require(script.Parent:WaitForChild("ResetService"))
local RoomBuilder = require(script.Parent:WaitForChild("RoomBuilder"))

workspace.Gravity = Constants.NormalGravity
RemoteService.Initialize()

local roomReferences = RoomBuilder.Build()
local discoveryService = DiscoveryService.new()
discoveryService:Initialize()

local eventManager = EventManager.new(discoveryService, ResetService, roomReferences)
local interactionService = InteractionService.new(eventManager, discoveryService, ResetService)
interactionService:Initialize()

print("[DON'T TOUCH IT] Prototype initialized.")

