--!strict

-- Hiker's Hall Main


---------- Services ----------

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
end

table.freeze(Constants)


---------- Globals ----------

local Globals = {}
Globals.dataStoreReader = DataStoreReader.new()
Globals.userId_displayed = {} :: {[number]: true?}
Globals.rank_count = {} :: {[string]: number}
Globals.loadedUsersCount = 0

---------- Local functions ----------

local updateHikerHall
local resolveUserRank
local getPlayerNameFromUserId


----- Hiker hall -----

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
    local playerName = getPlayerNameFromUserId(userId)
    name_textLabel.Text = playerName
    Globals.rank_count[rank] = (Globals.rank_count[rank] or 0) + 1
    screenUis.title_textLabel.Text = `{rank} Hikers ({Globals.rank_count[rank]})`

    -- Show entry
    entryFrame.Name = `{playerName}_Frame`
    entryFrame.Parent = screenUis.scrollingFrame

    -- Update loaded users
    Globals.loadedUsersCount += 1
end

getPlayerNameFromUserId = function(userId: number)
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


----- Main -----

local function main()
    Globals.loadedUsersCount = 0

    -- Read data
    task.defer(function()
        Globals.dataStoreReader:readDataStore("TestedRank")
    end)

    -- Update hiker's hall
    task.defer(function()
        while not Globals.dataStoreReader:getIsFinishedReading() do
            updateHikerHall()
            task.wait(5)
        end
        updateHikerHall()
    end)

    -- Update loading state
    task.defer(function()
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


---------- Calling function ----------

main()
