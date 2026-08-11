local DevToolsConfig = {}

-- Server-only whitelist. Keep this module out of ReplicatedStorage.
DevToolsConfig.AllowedUserIds = {
	[74299698] = true, -- tfyoder01
}

function DevToolsConfig.IsAuthorized(playerOrUserId)
	local userId = playerOrUserId
	if typeof(playerOrUserId) == "Instance" then
		userId = playerOrUserId.UserId
	end

	return typeof(userId) == "number" and DevToolsConfig.AllowedUserIds[userId] == true
end

return DevToolsConfig
