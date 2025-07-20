--!strict
-- Badge Award Module Script


---------- Module ----------

local BadgeAward = {}


---------- Services ----------

local BadgeService = game:GetService("BadgeService")
local RunService = game:GetService("RunService")


---------- Types ----------

type BadgeInfo = {
	Name: string,
	Description: string,
	IconImageId: number,
	IsEnabled: boolean
}


---------- Variables ----------

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


---------- Badge functions ----------

local function getBadgeInfo(badgeId: number): BadgeInfo?
	-- Get info in protected call
	local success, result = pcall(function()
		return BadgeService:GetBadgeInfoAsync(badgeId)
	end)

	-- Return result
	if not success then
		return nil
	end
	return result
end

local function awardBadge(player: Player, badgeId: number): boolean
	-- Award badge in protected call
	local success, result = pcall(function()
		return BadgeService:AwardBadge(player.UserId, badgeId)
	end)

	-- Validate sucess
	if not success then
		return false
	end

	-- Return award result
	return result
end


---------- Local functions ----------

local function resolveAwardBadge(player: Player, badgeId: number, badgeName: string)
	-- Throttle check
	if not throttle(userIdThrottleTable, player.UserId, 3) then
		return
	end

	-- Validate badge
	local badgeInfo = getBadgeInfo(badgeId)
	if not (badgeInfo and badgeInfo.IsEnabled) then
		warn(`Badge {badgeId}: '{badgeName}' not available!`)
		return
	end
	if badgeInfo.Name ~= badgeName then
		warn(`Badge name doesn't match! '{badgeInfo.Name}' | '{badgeName}'`)
		return
	end

	-- Award badge
	if RunService:IsStudio() then
		print(`[Mock Badge Award]: {player.Name} won "{badgeInfo.Name}" award.`)
	else
		awardBadge(player, badgeId)
	end
end


---------- Module functions ----------

BadgeAward.resolveAwardBadge = resolveAwardBadge


---------- Return module ----------

return BadgeAward
