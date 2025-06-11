--!strict
-- Rank Script


---------- Services ----------

local Players = game:GetService("Players")
local ReplicatedStorage = script.Parent.Parent.Parent:FindFirstChild("ReplicatedStorage") or game:GetService("ReplicatedStorage")
local ServerStorage = script.Parent.Parent.Parent:FindFirstChild("ServerStorage") or game:GetService("ServerStorage")


---------- Imports ----------

local RankThresholds = require(ReplicatedStorage.RankThresholds)

local LeaderstatsModule = require(ServerStorage.LeaderstatsModule)

local DSModule = require(ServerStorage.DataStoreModule)
local DSTypes = DSModule.DSTypes


---------- Instances ----------

local BadgeEvents = ServerStorage.BadgeEvents
local BadgeBindableFunction = BadgeEvents.BadgeBindableFunction

local RankEvents = ServerStorage.RankEvents
local RankBindableFunction = RankEvents.RankBindableFunction


---------- Variables ----------

local badgeTierIds = RankThresholds.badgeTierIds
local rankThresholds = RankThresholds.rankThresholds

local testedPlayerRank: {[number]: number} = {}


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

local function getRank_fromBadges(player: Player)
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

local function testAndGetRank(player: Player)
	local rank = getRank_fromBadges(player)
	testedPlayerRank[player.UserId] = rank
	return rank
end

local function getTestedRank(player: Player)
	return testedPlayerRank[player.UserId]
end


---------- Event functions ----------

local function onRankInvoke(mode: string, ...)
	if mode == "TestAndGetPlayerRank" then
		return testAndGetRank(...)
	elseif mode == "GetPlayerTestedRank" then
		return getTestedRank(...)
	end
end

local function onPlayerAdded(player: Player)
	-- Retrieve tested rank
	local testedRank = DSModule.getData(DSTypes.DSName.TestedRank, player)
	testedPlayerRank[player.UserId] = testedRank
	LeaderstatsModule.setData(player, "Rank", testedRank)
end

local function onPlayerRemoving(player: Player)
	-- Store tested rank & remove from table
	local testedRank = testedPlayerRank[player.UserId]
	DSModule.setData(DSTypes.DSName.TestedRank, player, testedRank)
	testedPlayerRank[player.UserId] = nil
end


---------- Calling / connecting functions ----------

RankBindableFunction.OnInvoke = onRankInvoke

local initialPlayers = Players:GetPlayers()
task.defer(function()
	for _, player in initialPlayers do
		onPlayerAdded(player)
	end
end)
Players.PlayerAdded:Connect(onPlayerAdded)

Players.PlayerRemoving:Connect(onPlayerRemoving)
