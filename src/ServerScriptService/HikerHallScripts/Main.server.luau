--!strict

-- Hiker's Hall Main


---------- Services ----------

local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")


---------- Imports ----------

local RankThresholds = require(ReplicatedStorage:WaitForChild("RankThresholds"))

local _ServerModules = ServerScriptService:WaitForChild("Modules")
local DataStoreReader = require(_ServerModules:WaitForChild("DataStoreReader"))


---------- Constants ----------

local Constants = {}

Constants.memoryStoreHashMap = MemoryStoreService:GetHashMap("UserId_PlayerName")
Constants.memoryStoreStates = {
    waitForData = "_WaitForData",
}
Constants.memoryStoreRetryTime = 2
Constants.memoryStoreFetchTime = 32

Constants.hikerInfoFolder = workspace:WaitForChild("_Workspace"):WaitForChild("HikerInfo") :: Folder

Constants.avatarImageLabelName = "Avatar_ImageLabel"
Constants.nameTextLabelName = "Name_TextLabel"
Constants.entryFrame_attributeName = "IsPlayerEntry"

Constants.loadingDotSpeed = 2

do
    local defaultGui

    -- Get default screen gui
    do
        local rank_beginner = Constants.hikerInfoFolder:WaitForChild("Rank_Beginner")
        defaultGui = rank_beginner:FindFirstChildWhichIsA("LayerCollector") :: LayerCollector
        defaultGui.Parent = nil
    end

    -- Create rank screen guis
    local function createHikeInfoScreenUIs(parent: Instance)
        local result = {}
        result.layerCollector = defaultGui:Clone()
        result.scrollingFrame = result.layerCollector:WaitForChild("ScrollingFrame")
        result.templateEntry_frame = result.scrollingFrame:WaitForChild("TemplateEntry_Frame")
        result.templateEntry_frame.Parent = nil
        result.title_textLabel = result.layerCollector:WaitForChild("Title_TextLabel") :: TextLabel
        return result
    end
    Constants.rank_screenUis = {}
    for _, rankThreshold in RankThresholds.rankThresholds do
        local rankTitle = rankThreshold.rankTitle
        local rankPart = Constants.hikerInfoFolder:WaitForChild(`Rank_{rankTitle}`)
        local rankScreenUis = createHikeInfoScreenUIs(rankPart)
        rankScreenUis.title_textLabel.Text = `{rankTitle} Hikers`
        rankScreenUis.layerCollector.Parent = rankPart
        Constants.rank_screenUis[rankTitle] = rankScreenUis
    end

    -- Get loading gui
    local loadingUis = {}
    local loadingPart = Constants.hikerInfoFolder:WaitForChild("LoadingPart")
    loadingUis.layerCollector = loadingPart:FindFirstChildWhichIsA("LayerCollector") :: LayerCollector
    loadingUis.loading_textLabel = loadingUis.layerCollector:WaitForChild("Loading_TextLabel") :: TextLabel

    Constants.loadingUis = loadingUis

    -- Get refresh gui
    local refreshUis = {}
    local refreshTimePart = Constants.hikerInfoFolder:WaitForChild("RefreshTimePart")
    refreshUis.layerCollector = refreshTimePart:FindFirstChildWhichIsA("LayerCollector") :: LayerCollector
    refreshUis.refreshTime_textLabel = refreshUis.layerCollector:WaitForChild("RefreshTime_TextLabel") :: TextLabel

    Constants.refreshUis = refreshUis
end

table.freeze(Constants)


---------- Globals ----------

local Globals = {}
Globals.dataStoreReader = DataStoreReader.new()
Globals.userId_displayed = {} :: {[number]: true?}
Globals.rank_count = {} :: {[string]: number}
Globals.loadedUsersCount = 0
Globals.key_thread = {} :: {[string]: thread?}


---------- Local functions ----------

local getSecondsUntilNextHour
local waitAndGetValueFromMemoryStoreHashMap
local setMemoryStoreValue

local getPlayerNameFromUserId_raw
local cached_getPlayerNameFromUserId

local clearHikerHall
local updateHikerHall
local resolveUserRank
local refreshHikerHall


----- Memory store -----

getSecondsUntilNextHour = function()
    local unixTimestamp = DateTime.now().UnixTimestamp
    return 3600 - unixTimestamp % 3600
end

waitAndGetValueFromMemoryStoreHashMap = function(memoryStoreHashMap: MemoryStoreHashMap, key: string)
    local success, pcallResult
    while true do
        success, pcallResult = pcall(function()
            return memoryStoreHashMap:GetAsync(key)
        end)
        local isWaiting = false
        if success and pcallResult then
            isWaiting = (pcallResult == Constants.memoryStoreStates.waitForData)
        end
        if not (success and (not isWaiting)) then
            task.wait(Constants.memoryStoreRetryTime)
        else
            break
        end
    end
    return success, pcallResult
end

setMemoryStoreValue = function(memoryStoreHashMap: MemoryStoreHashMap, key: string, value: any, expirationTimeFn: () -> number)
    local success
    repeat
        success = pcall(function()
            memoryStoreHashMap:SetAsync(key, value, expirationTimeFn())
        end)
        if not success then
            task.wait(Constants.memoryStoreRetryTime)
        end
    until success
end


----- Get player name -----

getPlayerNameFromUserId_raw = function(userId: number)
    local success, result
    repeat
        success, result = pcall(function()
            return Players:GetNameFromUserIdAsync(userId)
        end)
        if not success then
            task.wait(5)
        end
    until success
    return result
end

cached_getPlayerNameFromUserId = function(userId: number)
    local memoryStoreHashMap = Constants.memoryStoreHashMap
    local key = `User_{userId}`
    local result

    -- Get from memory store
    local success, pcallResult = waitAndGetValueFromMemoryStoreHashMap(memoryStoreHashMap, key)

    -- Check memory store or get from data store
    if success and pcallResult then
        result = pcallResult
    end

    -- If invalid, get from data store
    if not (success and result) then
        setMemoryStoreValue(
            memoryStoreHashMap,
            key, Constants.memoryStoreStates.waitForData, function() return Constants.memoryStoreFetchTime end
        )
        success, result = pcall(function()
            return getPlayerNameFromUserId_raw(userId)
        end)
        if success then
            setMemoryStoreValue(
                memoryStoreHashMap,
                key, result, getSecondsUntilNextHour
            )
        end
    end

    -- Return result
    return success, result
end


----- Hiker hall -----

clearHikerHall = function()
    local userIds = {}
    for userId, _ in Globals.userId_displayed do
        table.insert(userIds, userId)
    end
    for _, userId in userIds do
        Globals.userId_displayed[userId] = nil
    end
    for rank, screenUis in Constants.rank_screenUis do
        for _, child in screenUis.scrollingFrame:GetChildren() do
            if child:GetAttribute(Constants.entryFrame_attributeName) == true then
                child:Destroy()
            end
        end
        Globals.rank_count[rank] = 0
    end
    Globals.loadedUsersCount = 0
end

updateHikerHall = function()
    local data = Globals.dataStoreReader:getCurrentData() :: {[string]: string}
    for key, value in data do
        local userId = tonumber(string.match(key, "%d+"))
        local rank = tostring(value)
        if userId and value then
            resolveUserRank(userId, rank)
        end
    end
end

resolveUserRank = function(userId: number, rank: string)
    if Globals.userId_displayed[userId] then
        return
    end
    Globals.userId_displayed[userId] = true

    -- Create new entry
    local screenUis = Constants.rank_screenUis[rank]
    local entryFrame = screenUis.templateEntry_frame:Clone()
    local avatar_imageLabel = entryFrame:FindFirstChild(Constants.avatarImageLabelName) :: ImageLabel
    local name_textLabel = entryFrame:FindFirstChild(Constants.nameTextLabelName) :: TextLabel

    -- Fill in entry information
    avatar_imageLabel.Image = `rbxthumb://type=AvatarBust&id={userId}&w=100&h=100`
    local success, playerName
    repeat
        success, playerName = cached_getPlayerNameFromUserId(userId)
        if not success then
            task.wait()
        end
    until success
    name_textLabel.Text = playerName
    Globals.rank_count[rank] = (Globals.rank_count[rank] or 0) + 1
    screenUis.title_textLabel.Text = `{rank} Hikers ({Globals.rank_count[rank]})`

    -- Show entry
    entryFrame.Name = `{playerName}_Frame`
    entryFrame:SetAttribute(Constants.entryFrame_attributeName, true)
    entryFrame.Parent = screenUis.scrollingFrame

    -- Update loaded users
    Globals.loadedUsersCount += 1
end

refreshHikerHall = function()
    -- Create new reader
    Globals.dataStoreReader = DataStoreReader.new()

    -- Update hiker's hall
    local threadKey = "UpdateHall"
    if Globals.key_thread[threadKey] then
        task.cancel(Globals.key_thread[threadKey] :: thread)
    end
    Globals.key_thread[threadKey] = task.defer(function()
        -- Read data
        task.defer(function()
            Globals.dataStoreReader:readDataStore("TestedRank")
        end)
        clearHikerHall()

        -- Update hiker's hall
        while not Globals.dataStoreReader:getIsFinishedReading() do
            updateHikerHall()
            task.wait(1)
        end
        updateHikerHall()
    end)

    -- Update loading state
    threadKey = "UpdateLoadingState"
    if Globals.key_thread[threadKey] then
        task.cancel(Globals.key_thread[threadKey] :: thread)
    end
    Globals.key_thread[threadKey] = task.defer(function()
        -- Load data store
        local startTime = time()
        local keySize
        while not Globals.dataStoreReader:getIsFinishedReading() do
            local phase = (time() - startTime) * Constants.loadingDotSpeed // 1 % 4
            local prefix = "Loading data store" .. string.rep(".", phase)
            local loadedCount = Globals.dataStoreReader._completedCount
            keySize = Globals.dataStoreReader._keySize
            Constants.loadingUis.loading_textLabel.Text = `{prefix} ({loadedCount}/{keySize})`
            task.wait()
        end

        -- Load players
        keySize = Globals.dataStoreReader._keySize
        while Globals.loadedUsersCount < keySize do
            local phase = (time() - startTime) * Constants.loadingDotSpeed // 1 % 4
            local prefix = "Loading users" .. string.rep(".", phase)
            local loadedCount = Globals.loadedUsersCount
            Constants.loadingUis.loading_textLabel.Text = `{prefix} ({loadedCount}/{keySize})`
            task.wait()
        end
        Constants.loadingUis.loading_textLabel.Text = `Hall of Hikers ({Globals.loadedUsersCount})`
    end)
end


----- Main -----

local function main()
    -- Update every full hour
    task.defer(function()
        local currentSecondsUntilNextHour = getSecondsUntilNextHour()
        local prevSecondsUntilNextHour = currentSecondsUntilNextHour
        local isFirstTime = true

        while true do
            currentSecondsUntilNextHour = getSecondsUntilNextHour()
            local isNextHour = currentSecondsUntilNextHour > prevSecondsUntilNextHour
            if isNextHour or isFirstTime then
                if isFirstTime then
                    isFirstTime = false
                else
                    task.wait(3)
                end

                refreshHikerHall()
            end
            prevSecondsUntilNextHour = currentSecondsUntilNextHour
            task.wait(1)
        end
    end)

    -- Display refresh time
    task.defer(function()
        while true do
            local refreshTime = getSecondsUntilNextHour()
            local refreshTimeString = ""

            -- Seconds
            refreshTimeString = string.format("%02d", refreshTime % 60) .. refreshTimeString

            -- Minutes
            refreshTime = refreshTime // 60
            refreshTimeString = string.format("%02d:", refreshTime % 60) .. refreshTimeString

            -- Hours
            refreshTime = refreshTime // 60
            if refreshTime > 0 then
                refreshTimeString = string.format("%02d:", refreshTime % 60) .. refreshTimeString
            end

            -- Display refresh time
            Constants.refreshUis.refreshTime_textLabel.Text = `Refreshes in {refreshTimeString}`
            task.wait()
        end
    end)
end


---------- Calling function ----------

main()
