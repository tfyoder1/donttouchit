local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local RemoteService = {}

local function getRemoteFolder()
	local folder = ReplicatedStorage:FindFirstChild("Remotes")

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end

	return folder
end

function RemoteService.GetRemote(remoteName)
	local folder = getRemoteFolder()
	local remote = folder:FindFirstChild(remoteName)

	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = remoteName
		remote.Parent = folder
	end

	return remote
end

function RemoteService.Initialize()
	for _, remoteName in pairs(Constants.Remotes) do
		RemoteService.GetRemote(remoteName)
	end
end

return RemoteService

