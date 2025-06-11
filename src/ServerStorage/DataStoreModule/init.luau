--!strict
-- DataStore Module Script


---------- Validate environment ----------

local RunService = game:GetService("RunService")
if not RunService:IsServer() then
	return {}
end


---------- Module ----------

local DataStoreModule = {}


---------- Services ----------

local DataStoreService = game:GetService("DataStoreService")


---------- Imports ----------

local DSTypes = require(script.DataStoreTypes)


---------- Variables ----------

local MAX_TRIALS = 5


---------- Helper functions ----------

local function getPlayerKey(player: Player)
	return `User_{player.UserId}`
end


---------- Local functions ----------

local function getDataStore(name: DSTypes.DSName)
	local dataStore = DataStoreService:GetDataStore(name)
	return dataStore
end

local function setData(name: DSTypes.DSName, player: Player, value: any)
	local dataStore = getDataStore(name)
	local key = getPlayerKey(player)

	-- Set data
	local success, result
	local trials = 0
	while not success and trials < MAX_TRIALS do
		success, result = pcall(function()
			dataStore:SetAsync(key, value)
		end)
		trials += 1
	end

	-- Print error result if failed
	if not success then
		print(result)
	end
end

local function getData(name: DSTypes.DSName, player: Player)
	local dataStore = getDataStore(name)
	local key = getPlayerKey(player)

	-- Get data
	local success, result
	local trials = 0
	while not success and trials < MAX_TRIALS do
		success, result = pcall(function()
			return dataStore:GetAsync(key)
		end)
		trials += 1
	end

	-- Validate success
	if not success then
		print(result)
		return nil
	end

	-- Return result
	return result
end


---------- Module variables  ----------

DataStoreModule.DSTypes = DSTypes


---------- Module functions ----------

DataStoreModule.setData = setData
DataStoreModule.getData = getData


---------- Return module ----------

return DataStoreModule
