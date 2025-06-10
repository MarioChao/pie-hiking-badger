--!strict
-- Rank Script


---------- Services ----------

local ReplicatedStorage = script.Parent.Parent.Parent:FindFirstChild("ReplicatedStorage") or game:GetService("ReplicatedStorage")
local ServerStorage = script.Parent.Parent.Parent:FindFirstChild("ServerStorage") or game:GetService("ServerStorage")


---------- Imports ----------

local RankThresholds = require(ReplicatedStorage.RankThresholds)


---------- Instances ----------

local BadgeEvents = ServerStorage.BadgeEvents
local BadgeBindableFunction = BadgeEvents.BadgeBindableFunction


local RankEvents = ServerStorage.RankEvents
local RankBindableFunction = RankEvents.RankBindableFunction


---------- Variables ----------

local badgeTierIds = RankThresholds.badgeTierIds
local rankThresholds = RankThresholds.rankThresholds


---------- Local functions ----------

local function countBadges(player: Player, badgeIds: {number})
	local checkResult = BadgeBindableFunction:Invoke("CheckPlayerBadges", player, badgeIds)
	local count = 0
	for _, isAwarded in checkResult do
		if isAwarded then
			count += 1
		end
	end
	return count
end

local function getRank(player: Player)
	for _, rankThreshold in rankThresholds do
		-- Check conditions
		local conditionMet = true
		for _, condition in rankThreshold.conditions do
			-- Validate minimum badges
			if countBadges(player, badgeTierIds[condition.badgeTier]) < condition.minimumBadges then
				conditionMet = false
				break
			end
		end

		-- Validate condition met
		if not conditionMet then
			continue
		end

		-- Return title
		return rankThreshold.rankTitle
	end
	return "???"
end


---------- Event functions ----------

local function onRankInvoke(mode: string, ...)
	if mode == "GetPlayerRank" then
		return getRank(...)
	end
end


---------- Calling / connecting functions ----------

RankBindableFunction.OnInvoke = onRankInvoke
