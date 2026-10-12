--!strict

-- Give Rank Badge Main


---------- Services ----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")


---------- Imports ----------

local RankThresholds = require(ReplicatedStorage:WaitForChild("RankThresholds"))

type RankBadge = {
	[string]: {
		badgeId: number,
		badgeName: string,
	}
}

local RankBadge: RankBadge = require(script.Parent:WaitForChild("rank-badge"))

local _Modules = ReplicatedStorage:WaitForChild("Modules")
local BadgeUtil = require(_Modules:WaitForChild("BadgeUtil"))
local BelovedRemote = require(_Modules:WaitForChild("BelovedRemote"))


---------- Constants ----------

local Constants = {}

do
	local RankEvents = ServerStorage.RankEvents
	Constants.rankBindableFunction = RankEvents.RankBindableFunction
end

Constants.rankPriority = RankThresholds.rankPriority

table.freeze(Constants)


---------- Globals ----------

local Globals = {}

Globals.userRankString_throttled = {} :: {[string]: true?}


---------- Local functions ----------

local throttle
local onGiveBadgeWithRank

throttle = function<K>(sourceTable: {[K]: boolean?}, key: K, delay_seconds: number): boolean
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

onGiveBadgeWithRank = function(player: Player, rank: string)
	-- Throttle
	local throttleSuccess = throttle(Globals.userRankString_throttled, `{player.UserId}_{rank}`, 1)
	if not throttleSuccess then
		return
	end

	-- Get player rank
	local playerActualRank = Constants.rankBindableFunction:Invoke("GetPlayerTestedRank", player)

	-- Validate rank priority
	if not (Constants.rankPriority[playerActualRank] and Constants.rankPriority[rank]) then
		return
	end
	if not (Constants.rankPriority[playerActualRank] >= Constants.rankPriority[rank]) then
		return
	end

	-- Grant badge
	local badgeId = RankBadge[rank].badgeId
	local badgeName = RankBadge[rank].badgeName
	BadgeUtil.awardBadgeLoop(player, badgeId, badgeName)
end


---------- Module ----------

local Module = {}


----- Module fields -----

function Module.start()
	BelovedRemote.connect_toServer("GiveBadgeWithRank", onGiveBadgeWithRank)
end


---------- Return module ----------

table.freeze(Module)
return Module
