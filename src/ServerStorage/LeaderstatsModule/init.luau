--!strict
-- Leaderstats Module Script


---------- Validate environment ----------

local RunService = game:GetService("RunService")
if not RunService:IsServer() then
	warn(`[Leaderstats Module]: Module should only be required from the server!`)
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
		ValueType: "StringValue" | "IntValue" | "BoolValue" | "NumberValue",
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

local function getLeaderstats(player: Player): Instance
	local leaderstats = player:WaitForChild("leaderstats", 5)
	local result
	if leaderstats then
		result = leaderstats
	else
		print(`Leaderstats isn't initialized for Player {player.UserId}!`)
		result = setPlayerDefaultLeaderstats(player)
	end
	return result
end

local function getStatInstance(player: Player, statName: string): ValueBase & {Value: string | number | boolean}
	local leaderstats = getLeaderstats(player)
	local stat = leaderstats:FindFirstChild(statName)
	local result
	if stat and stat:IsA("ValueBase") then
		result = stat
	else
		warn(`[Leaderstats Module]: No '{statName}' of type ValueBase found in leaderstats!'`)
		result = Instance.new("IntValue")
	end
	return result :: ValueBase & {Value: any}
end


---------- Local functions ----------

local function initializeLeaderstats(initialStats: InitialStats)
	for statName, valueInfo in initialStats do
		local valueObject = Instance.new(valueInfo.ValueType) :: ValueBase & {Value: string | number | boolean}
		valueObject.Name = statName
		valueObject.Value = valueInfo.DefaultValue
		valueObject.Parent = DefaultLeaderstatsFolder
	end
end

local function setData(player: Player, statName: string, value: any)
	if value == nil then
		return
	end
	local stat = getStatInstance(player, statName)
	local success, result = pcall(function()
		stat.Value = value
	end)
	if not success then
		print(result)
	end
end

local function getData(player: Player, statName: string): any
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
