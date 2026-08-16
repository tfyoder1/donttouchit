local DevToolsConfig = {}

-- Server-only root authority. Keep this module out of ReplicatedStorage.
DevToolsConfig.OwnerUserIds = {
	[74299698] = true, -- tfyoder01
}

-- Legacy name preserved for older call sites. Root owners are always allowed.
DevToolsConfig.AllowedUserIds = {
	[74299698] = true, -- tfyoder01
}

-- Capability overrides let Developers receive or lose moderation/tester-management powers
-- without changing persistent role records.
DevToolsConfig.DeveloperCapabilityOverrides = {
	MOD_WARN_PLAYER = true,
	MOD_BAN_24H = true,
	MOD_VIEW_HISTORY = true,
	MOD_REMOVE_BAN = false,
	ROLE_MANAGEMENT = false,
	TEST_BUILD_ACCESS_MANAGEMENT = false,
}

function DevToolsConfig.IsAuthorized(playerOrUserId)
	local userId = playerOrUserId
	if typeof(playerOrUserId) == "Instance" then
		userId = playerOrUserId.UserId
	end

	return typeof(userId) == "number"
		and (DevToolsConfig.OwnerUserIds[userId] == true or DevToolsConfig.AllowedUserIds[userId] == true)
end

return DevToolsConfig
