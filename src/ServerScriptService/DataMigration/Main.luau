--!strict

-- Data Migration Main


---------- Services ----------

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

---------- Imports ----------

local _ServerModules = ServerScriptService:WaitForChild("Modules")
local DataStoreReader = require(_ServerModules:WaitForChild("DataStoreReader"))

local CombinedUserInfo = require(ServerStorage:WaitForChild("CombinedUserInfo"))


---------- Constants ----------

local Constants = {}

Constants.dataStoreReader = DataStoreReader.new()
Constants.newDataStoreReader = DataStoreReader.new()

Constants.maxUsernameTrials = 5

Constants.nullUsername = "~null~"

table.freeze(Constants)


---------- Local function ----------

local getPlayerNameFromUserId_raw

local readDataStore
local readNewDataStore
local migrateDataStore
local clearNewDataStore
local getNullPlayerUserIds
local updateDataStore


----- Get player name -----

getPlayerNameFromUserId_raw = function(userId: number)
    local success, result
    local trials = 0
    repeat
        success, result = pcall(function()
            return Players:GetNameFromUserIdAsync(userId)
        end)
        if not success then
            task.wait(1)
        end
        trials += 1
    until success or trials >= Constants.maxUsernameTrials
    return success, result
end


----- Data store -----

readDataStore = function()
    task.defer(function()
        Constants.dataStoreReader:readDataStore("TestedRank")
    end)
    local startTime = time()
    while not Constants.dataStoreReader:getIsFinishedReading() do
        print(`[Data Migration]: Reading data. {math.round((time() - startTime) * 100) / 100} s`)
        task.wait(1)
    end
end

readNewDataStore = function()
    task.defer(function()
        Constants.newDataStoreReader:readDataStore("CombinedUserInfo")
    end)
    local startTime = time()
    while not Constants.newDataStoreReader:getIsFinishedReading() do
        print(`[Data Migration]: Reading new data. {math.round((time() - startTime) * 100) / 100} s`)
        task.wait(1)
    end
end

migrateDataStore = function()
    local data = Constants.dataStoreReader:getCurrentData()
    local newData = Constants.newDataStoreReader:getCurrentData()
    local userId_isMigrated = {} :: {[number]: true?}

    -- Print read info
    do
        local count = 0
        for _, _ in data do
            count += 1
        end
        local count2 = 0
        for _, _ in newData do
            count2 += 1
        end
        print(`[Data Migration]: Old data ({count}).`)
        print(`[Data Migration]: New data ({count2}).`)
    end

    -- Get already migrated
    do
        for _, userInfoMap in newData do
            for key, userInfo in userInfoMap do
                local userId = tonumber(string.match(key, "%d+"))
                if userId then
                    userId_isMigrated[userId] = true
                else
                    warn(`[Data Migration]: User id not found in '{key}'.`)
                end
            end
        end
    end

    -- Prepare to migrate data
    local userInfoList = {} :: {{userId: number, playerInfo: CombinedUserInfo.PlayerInfo}}
    for key, rank in data do
        local userId = tonumber(string.match(key, "%d+"))

        -- Validate user id
        if not userId then
            warn(`[Data Migration]: User id not found in '{key}'.`)
            continue
        end

        -- Check migrated
        if userId_isMigrated[userId] then
            continue
        end

        -- Get username
        print(`[Data Migration]: Getting username for '{userId}'.`)
        local success, username = getPlayerNameFromUserId_raw(userId)
        if not success then
            warn(`[Data Migration]: Username failed to get for '{userId}'. Using {Constants.nullUsername} instead.`)
            username = Constants.nullUsername
        end

        -- Store info
        local playerInfo = {
            rank = tostring(rank),
            username = username,
        } :: CombinedUserInfo.PlayerInfo
        table.insert(userInfoList, {userId = userId, playerInfo = playerInfo})
    end

    -- Migrate data
    print(`[Data Migration]: Migrating '{#userInfoList}' data.`)
    CombinedUserInfo.updateUserInfoBatched(userInfoList)
end

clearNewDataStore = function()
    CombinedUserInfo.clearData()
end

getNullPlayerUserIds = function()
    local newData = Constants.newDataStoreReader:getCurrentData()
    local nullUserIds = {}
    for _, userInfoMap in newData do
        for key, userInfo in userInfoMap do
            if userInfo.username == "<null>" then
                local userId = tonumber(string.match(key, "%d+"))
                if userId then
                    table.insert(nullUserIds, userId)
                else
                    warn(`[Data Migration]: User id not found in '{key}'.`)
                end
            end
        end
    end
    return nullUserIds
end

updateDataStore = function(userIds: {number})
    local data = Constants.dataStoreReader:getCurrentData()
    local userInfoList = {} :: {{userId: number, playerInfo: CombinedUserInfo.PlayerInfo}}
    for _, userId in userIds do
        -- Get rank
        local privateKey = `User_{userId}`
        local rank = data[privateKey]

        -- Get username
        print(`[Data Migration]: Getting username for '{userId}'.`)
        local success, username = getPlayerNameFromUserId_raw(userId)
        if not success then
            warn(`[Data Migration]: Username failed to get for '{userId}'. Using {Constants.nullUsername} instead.`)
            username = Constants.nullUsername
        end

        -- Store info
        local playerInfo = {
            rank = tostring(rank),
            username = username,
        } :: CombinedUserInfo.PlayerInfo
        table.insert(userInfoList, {userId = userId, playerInfo = playerInfo})
    end

    -- Update data
    print(`[Data Migration]: Updating data.`)
    CombinedUserInfo.updateUserInfoBatched(userInfoList)
    print("[Data Migration]: Done updating.")
end


----- Main -----

local function main()
    -- clearNewDataStore()

    -- readDataStore()
    -- readNewDataStore()
    -- migrateDataStore()

    -- readDataStore()
    -- readNewDataStore()
    -- print(getNullPlayerUserIds())
    -- updateDataStore(getNullPlayerUserIds())
end


---------- Module ----------

local Module = {}


----- Module fields -----

function Module.start()
    main()
end


---------- Return module ----------

table.freeze(Module)
return Module
