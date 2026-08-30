--!strict

-- DataStore Module Script


---------- Validate environment ----------

local RunService = game:GetService("RunService")
if not RunService:IsServer() then
	warn(`[Data Store Module]: Module should only be required from the server!`)
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

local function setData_key(name: DSTypes.DSName, key: string, value: any)
	local dataStore = getDataStore(name)

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

local function updateData_key(
	name: DSTypes.DSName, key: string,
	transformFunction: (oldValue: any, dataStoreKeyInfo: DataStoreKeyInfo?) -> (any, {number}?, {any}?)
)
	local dataStore = getDataStore(name)

	-- Update data
	local success, result
	local trials = 0
	while not success and trials < MAX_TRIALS do
		success, result = pcall(function()
			return dataStore:UpdateAsync(key, transformFunction)
		end)
		trials += 1
	end

	-- Print error result if failed
	if not success then
		print(result)
	end
end

local function getData_key(name: DSTypes.DSName, key: string)
	local dataStore = getDataStore(name)

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

local function setData_player(name: DSTypes.DSName, player: Player, value: any)
	local key = getPlayerKey(player)
	setData_key(name, key, value)
end

local function getData_player(name: DSTypes.DSName, player: Player)
	local key = getPlayerKey(player)
	return getData_key(name, key)
end


---------- Module variables  ----------

DataStoreModule.DSTypes = DSTypes


---------- Module functions ----------

DataStoreModule.setData_player = setData_player
DataStoreModule.getData_player = getData_player

DataStoreModule.setData_key = setData_key
DataStoreModule.getData_key = getData_key
DataStoreModule.updateData_key = updateData_key


---------- Return module ----------

table.freeze(DataStoreModule)
return DataStoreModule
