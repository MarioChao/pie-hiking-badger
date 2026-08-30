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

local clearHikerHall
local updateHikerHall
local resolveUserRank
local refreshHikerHall


----- Time -----

getSecondsUntilNextHour = function()
    local unixTimestamp = DateTime.now().UnixTimestamp
    return 3600 - unixTimestamp % 3600
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
    local data = Globals.dataStoreReader:getCurrentData() :: {[string]: {[string]: {rank: string, username: string}}}
    for _, userInfoMap in data do
        for key, userInfo in userInfoMap do
            local userId = tonumber(string.match(key, "%d+"))
            local rank = userInfo.rank
            local username = userInfo.username
            if userId and rank then
                resolveUserRank(userId, rank, username)
            end
        end
    end
end

resolveUserRank = function(userId: number, rank: string, username: string)
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
    local playerName = username
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
            Globals.dataStoreReader:readDataStore("CombinedUserInfo")
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
        print(`[Hiker Hall]: Read {Globals.dataStoreReader._keySize} keys.`)

        -- Count players
        local totalPlayers = 0
        for _, userInfoMap in Globals.dataStoreReader:getCurrentData() do
            for _, _ in userInfoMap do
                totalPlayers += 1
            end
        end
        print(`[Hiker Hall]: Total players: {totalPlayers}`)

        -- Load players
        while Globals.loadedUsersCount < totalPlayers do
            local phase = (time() - startTime) * Constants.loadingDotSpeed // 1 % 4
            local prefix = "Loading users" .. string.rep(".", phase)
            local loadedCount = Globals.loadedUsersCount
            Constants.loadingUis.loading_textLabel.Text = `{prefix} ({loadedCount}/{totalPlayers})`
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
