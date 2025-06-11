--!strict
-- Leaderstats Module Script


---------- Validate environment ----------

local RunService = game:GetService("RunService")
if not RunService:IsServer() then
	return {}
end


---------- Module ----------

local LeaderstatsModule = {}


---------- Services ----------

local Players = game:GetService("Players")


---------- Types ----------

local ValueType = {
	StringValue = "StringValue",
	IntValue = "IntValue",
	BoolValue = "BoolValue",
	NumberValue = "NumberValue",
}

table.freeze(ValueType)

export type InitialStats = {
	[string]: {
		ValueType: typeof(ValueType),
		DefaultValue: any,
	}
}


---------- Instances ----------

local DefaultLeaderstatsFolder = Instance.new("Folder")


---------- Helper functions ----------

local function setPlayerDefaultLeaderstats(player: Player)
	local leaderstats = DefaultLeaderstatsFolder:Clone()
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	return leaderstats
end

local function getLeaderstats(player: Player)
	local leaderstats = player:WaitForChild("leaderstats", 5)
	if not leaderstats then
		print(`Leaderstats isn't initialized for Player {player.UserId}!`)
		leaderstats = setPlayerDefaultLeaderstats(player)
	end
	return leaderstats
end

local function getStatInstance(player: Player, statName: string)
	local leaderstats = getLeaderstats(player)
	local stat = leaderstats:FindFirstChild(statName)
	return stat
end


---------- Local functions ----------

local function initializeLeaderstats(initialStats: InitialStats)
	for statName, valueInfo in initialStats do
		local valueObject = Instance.new(valueInfo.ValueType)
		valueObject.Name = statName
		valueObject.Value = valueInfo.DefaultValue
		valueObject.Parent = DefaultLeaderstatsFolder
	end
end

local function setData(player: Player, statName: string, value: any)
	local stat = getStatInstance(player, statName)
	local success, result = pcall(function()
		stat.Value = value
	end)
	if not success then
		print(result)
	end
end

local function getData(player: Player, statName: string)
	local stat = getStatInstance(player, statName)
	local success, result = pcall(function()
		return stat.Value
	end)
	if not success then
		print(result)
		return nil
	end
	return result
end


---------- Event functions  ----------

local function onPlayerAdded(player: Player)
	setPlayerDefaultLeaderstats(player)
end


---------- Calling / connecting functions  ----------

local initialPlayers = Players:GetPlayers()
task.defer(function()
	for _, player in initialPlayers do
		onPlayerAdded(player)
	end
end)
Players.PlayerAdded:Connect(onPlayerAdded)


---------- Module variables  ----------

LeaderstatsModule.ValueType = ValueType


---------- Module functions ----------

LeaderstatsModule.initialize = initializeLeaderstats

LeaderstatsModule.setData = setData
LeaderstatsModule.getData = getData


---------- Return module ----------

return LeaderstatsModule
