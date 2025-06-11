--!strict
-- Rank Script


---------- Services ----------

local ReplicatedStorage = script.Parent.Parent.Parent:FindFirstChild("ReplicatedStorage") or game:GetService("ReplicatedStorage")
local ServerStorage = script.Parent.Parent.Parent:FindFirstChild("ServerStorage") or game:GetService("ServerStorage")


---------- Imports ----------

local RankThresholds = require(ReplicatedStorage.RankThresholds)

type RankBadge = {
	[string]: {
		badgeId: number,
		badgeName: string,
	}
}

local RankBadge: RankBadge = require(script.Parent["rank-badge"])


---------- Instances ----------

local GiveRankBadgeEvents = ReplicatedStorage.GiveRankBadgeEvents
local GiveRankBadgeRemote = GiveRankBadgeEvents.GiveRankBadgeRemote

local BadgeEvents = ServerStorage.BadgeEvents
local BadgeBindable = BadgeEvents.BadgeBindable

local RankEvents = ServerStorage.RankEvents
local RankBindableFunction = RankEvents.RankBindableFunction


---------- Variables ----------

local rankIndex: {[string]: number} = {}

local userIdThrottleTable: {[number]: boolean} = {}


---------- Helper functions ----------

local function throttle<K>(sourceTable: {[K]: boolean}, key: K, delay_seconds: number): boolean
	-- Check if throttled
	if sourceTable[key] then
		return false
	end

	-- Throttle
	sourceTable[key] = true
	task.delay(delay_seconds, function()
		sourceTable[key] = nil
	end)
	return true
end


---------- Local functions ----------

local function onGiveBadgeWithRank(player: Player, rank: string)
	-- Throttle
	local throttleSuccess = throttle(userIdThrottleTable, player.UserId, 1)
	if not throttleSuccess then
		return
	end

	-- Validate player rank
	local playerActualRank = RankBindableFunction:Invoke("GetPlayerTestedRank", player)
	if not (rankIndex[playerActualRank] <= rankIndex[rank]) then
		return
	end

	-- Grant badge
	local badgeId = RankBadge[rank].badgeId
	local badgeName = RankBadge[rank].badgeName
	BadgeBindable:Fire("AwardBadge", player, badgeId, badgeName)
end


---------- Set up functions ----------

local function setUpRankPriority()
	for index, rankThreshold in RankThresholds.rankThresholds do
		rankIndex[rankThreshold.rankTitle] = index
	end
end


---------- Event functions ----------

local function onGiveRankBadgeServerEvent(client: Player, mode: string, ...)
	if mode == "GiveBadgeWithRank" then
		return onGiveBadgeWithRank(client, ...)
	end
end


---------- Calling / connecting functions ----------

setUpRankPriority()

GiveRankBadgeRemote.OnServerEvent:Connect(onGiveRankBadgeServerEvent)
