--!strict

-- Rank Script


---------- Services ----------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")


---------- Imports ----------

local RankThresholds = require(ReplicatedStorage:WaitForChild("RankThresholds"))

local LeaderstatsModule = require(ServerStorage:WaitForChild("LeaderstatsModule"))

local CombinedUserInfo = require(ServerStorage:WaitForChild("CombinedUserInfo"))
local DSModule = require(ServerStorage:WaitForChild("DataStoreModule"))
local DSTypes = DSModule.DSTypes


---------- Constants ----------

local Constants = {}

do
	local _BadgeEvents = ServerStorage.BadgeEvents
	Constants.badgeBindableFunction = _BadgeEvents.BadgeBindableFunction
end

do
	local _RankEvents = ServerStorage.RankEvents
	Constants.rankBindableFunction = _RankEvents.RankBindableFunction
end

do
	local _MenuEvents = ReplicatedStorage.MenuEvents
	Constants.menuRemote = _MenuEvents.MenuRemote
end

Constants.badgeTierIds = RankThresholds.badgeTierIds
Constants.rankThresholds = RankThresholds.rankThresholds

table.freeze(Constants)


---------- Globals ----------

local Globals = {}

Globals.testedPlayerRank = {} :: {[number]: string?}


---------- Local functions ----------

local checkAllBadges
local countBadges
local getRank_fromBadges
local testAndGetRank
local getTestedRank

local onPlayerAdded
local onPlayerRemoving


----- Rank check -----

checkAllBadges = function(player: Player)
	local allBadgeIds = {}
	for _, badgeIds in Constants.badgeTierIds do
		for _, badgeId in badgeIds do
			table.insert(allBadgeIds, badgeId)
		end
	end
	Constants.badgeBindableFunction:Invoke("CheckPlayerBadges", player, allBadgeIds)
end

countBadges = function(player: Player, badgeIds: {number})
	local checkResult = Constants.badgeBindableFunction:Invoke("CheckPlayerBadges", player, badgeIds)
	local count = 0
	for _, isAwarded in checkResult do
		if isAwarded then
			count += 1
		end
	end
	return count
end

getRank_fromBadges = function(player: Player)
	-- Check all badges
	checkAllBadges(player)

	-- Check rank badges
	for _, rankThreshold in Constants.rankThresholds do
		-- Check conditions
		local conditionMet = true
		for _, condition in rankThreshold.conditions do
			-- Validate minimum badges
			if countBadges(player, Constants.badgeTierIds[condition.badgeTier]) < condition.minimumBadges then
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

testAndGetRank = function(player: Player)
	local rank = getRank_fromBadges(player)
	Globals.testedPlayerRank[player.UserId] = rank
	return rank
end

getTestedRank = function(player: Player)
	return Globals.testedPlayerRank[player.UserId]
end


----- Player -----

onPlayerAdded = function(player: Player)
	-- Retrieve tested rank
	local testedRank = DSModule.getData_player(DSTypes.DSName.TestedRank, player)
	Globals.testedPlayerRank[player.UserId] = testedRank
	LeaderstatsModule.setData(player, "Rank", testedRank)
	Constants.menuRemote:FireClient(player, "UpdateRank", testedRank)
end

onPlayerRemoving = function(player: Player)
	-- Store tested rank
	local testedRank = Globals.testedPlayerRank[player.UserId]
	if testedRank then
		DSModule.setData_player(DSTypes.DSName.TestedRank, player, testedRank)
		CombinedUserInfo.updateUserInfo(player.UserId, {
			rank = testedRank,
			username = player.Name,
		})
	end

	-- Remove from table
	Globals.testedPlayerRank[player.UserId] = nil
end


----- Main -----

local function main()
	Constants.rankBindableFunction.OnInvoke = function(mode: string, ...): any
		if mode == "TestAndGetPlayerRank" then
			return testAndGetRank(...)
		elseif mode == "GetPlayerTestedRank" then
			return getTestedRank(...)
		end
		return nil
	end

	local initialPlayers = Players:GetPlayers()
	task.defer(function()
		for _, player in initialPlayers do
			onPlayerAdded(player)
		end
	end)
	Players.PlayerAdded:Connect(onPlayerAdded)

	Players.PlayerRemoving:Connect(onPlayerRemoving)
end


---------- Calling function ----------

main()
