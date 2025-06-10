--!strict
-- Badge Script


---------- Services ----------

local ServerStorage = script.Parent.Parent.Parent:FindFirstChild("ServerStorage") or game:GetService("ServerStorage")


---------- Imports ----------

local BadgeScripts = script.Parent
local BadgeAward = require(BadgeScripts.BadgeAward)
local CachedBadgeCheck = require(BadgeScripts.BadgeCheck.CachedBadgeCheck)


---------- Instances ----------

local BadgeEvents = ServerStorage.BadgeEvents
local BadgeBindable = BadgeEvents.BadgeBindable
local BadgeBindableFunction = BadgeEvents.BadgeBindableFunction


---------- Local functions ----------

local function onAwardBadge(player: Player, badgeId: number, badgeName: string)
	BadgeAward.resolveAwardBadge(player, badgeId, badgeName)
end

local function onCheckPlayerBadges(player: Player, badgeIds: {number})
	return CachedBadgeCheck.userHasBadges(player.UserId, badgeIds)
end

local function onCheckPlayerBadge(player: Player, badgeId: number)
	return onCheckPlayerBadges(player, {badgeId})
end


---------- Event functions ----------

local function onBadgeEvent(mode: string, ...)
	if mode == "AwardBadge" then
		onAwardBadge(...)
	end
end

local function onBadgeInvoke(mode: string, ...)
	if mode == "CheckPlayerBadges" then
		return onCheckPlayerBadges(...)
	elseif mode == "CheckPlayerBadge" then
		return onCheckPlayerBadge(...)
	end
end


---------- Calling / connecting functions ----------

BadgeBindable.Event:Connect(onBadgeEvent)
BadgeBindableFunction.OnInvoke = onBadgeInvoke
