--!strict
-- Menu Script


---------- Services ----------

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")


---------- Imports ----------

local RankThresholds = require(ReplicatedStorage:WaitForChild("RankThresholds"))

local BadgeModules = ReplicatedStorage:WaitForChild("BadgeModules")
local BadgeInfo = require(BadgeModules.BadgeInfo)


---------- Instances ----------

local MenuEvents = ReplicatedStorage.MenuEvents
local GameInfoBindable = MenuEvents.GameInfoBindable

local LocalPlayer = Players.LocalPlayer

local PlayerGui = LocalPlayer.PlayerGui


---------- Gui instances ----------

local GameInfo_ScreenGui: ScreenGui = PlayerGui:WaitForChild("GameInfo_ScreenGui")
local GameInfo_UIScale: UIScale = GameInfo_ScreenGui.UIScale

local GameInfo_Frame: Frame = GameInfo_ScreenGui.GameInfo_Frame
local PlaceName_TextLabel: TextLabel = GameInfo_Frame.PlaceName_TextLabel
local Thumbnail_ImageLabel: ImageLabel = GameInfo_Frame.Thumbnail_ImageLabel
local BadgeName_TextLabel: TextLabel = GameInfo_Frame.BadgeName_TextLabel
local Play_TextButton: TextButton = GameInfo_Frame.Play_TextButton
local Exit_ImageButton: ImageButton = GameInfo_Frame.Exit_ImageButton


---------- Variables ----------

local badgePlaceId = RankThresholds.badgePlaceId

local cachedPlaceIdName: {[number]: string} = {}

local targetPlaceId = 0

local displayedBadgeId = nil


---------- Helper functions ----------

local function getPlaceName(placeId: number)
	-- Check cached
	if cachedPlaceIdName[placeId] then
		return cachedPlaceIdName[placeId]
	end

	-- Get product info
	local success, result = pcall(function()
		return MarketplaceService:GetProductInfo(placeId)
	end)

	-- Validate success
	if not success then
		print(result)
		return nil
	end

	-- Cache result
	cachedPlaceIdName[placeId] = result.Name

	-- Return place name
	return result.Name
end


---------- Local functions ----------

local function showBadgeInfo(badgeId: number, badgeInfo: BadgeInfo.BadgeInfo)
	-- Get place id
	local placeId = badgePlaceId[tostring(badgeId)]
	targetPlaceId = placeId

	-- Get & validate place name
	local placeName = getPlaceName(placeId)
	if not placeName then
		return
	end

	-- Set game info
	PlaceName_TextLabel.Text = placeName
	Thumbnail_ImageLabel.Image = `rbxthumb://type=GameThumbnail&id={placeId}&w=768&h=432`
	BadgeName_TextLabel.Text = badgeInfo.Name

	-- Show game info
	GameInfo_ScreenGui.Enabled = true
end

local function onToggleShowBadgeInfo(badgeId: number, badgeInfo: BadgeInfo.BadgeInfo)
	-- Check if badge id already displayed
	if GameInfo_ScreenGui.Enabled and badgeId == displayedBadgeId then
		-- Hide badge info
		displayedBadgeId = nil
		GameInfo_ScreenGui.Enabled = false
		return
	end

	-- Show badge info
	showBadgeInfo(badgeId, badgeInfo)

	-- Store displayed badge id
	displayedBadgeId = badgeId
end


---------- Event functions ----------

local function onGameInfoEvent(mode: string, ...)
	if mode == "ToggleShowBadgeInfo" then
		onToggleShowBadgeInfo(...)
	end
end


---------- Set up functions ----------

local function setUpGameInfo()
	GameInfo_ScreenGui.Enabled = false
end


---------- Calling / connecting functions ----------

GameInfoBindable.Event:Connect(onGameInfoEvent)

Play_TextButton.Activated:Connect(function()
	TeleportService:Teleport(targetPlaceId, LocalPlayer)
end)

Exit_ImageButton.Activated:Connect(function()
	GameInfo_ScreenGui.Enabled = false
end)

RunService.Heartbeat:Connect(function()
	-- Scale ui
	local scale = GameInfo_ScreenGui.AbsoluteSize.Y / 320
	GameInfo_UIScale.Scale = scale
end)

setUpGameInfo()
