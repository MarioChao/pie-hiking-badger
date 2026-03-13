--!strict
-- Badge Script


---------- Services ----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = script.Parent.Parent.Parent:FindFirstChild("ServerStorage") or game:GetService("ServerStorage")


---------- Imports ----------

local _Modules = ReplicatedStorage:WaitForChild("Modules")
local BadgeUtil = require(_Modules:WaitForChild("BadgeUtil"))


---------- Instances ----------

local BadgeEvents = ServerStorage.BadgeEvents
local BadgeBindable = BadgeEvents.BadgeBindable
local BadgeBindableFunction = BadgeEvents.BadgeBindableFunction


---------- Local functions ----------

local function onAwardBadge(player: Player, badgeId: number, badgeName: string)
	BadgeUtil.awardBadgeLoop(player, badgeId, badgeName)
end

local function onCheckPlayerBadges(player: Player, badgeIds: {number})
	return BadgeUtil.CachedBadgeCheck.checkUserHasBadges(player.UserId, badgeIds)
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
	return {}
end


---------- Calling / connecting functions ----------

BadgeBindable.Event:Connect(onBadgeEvent)
BadgeBindableFunction.OnInvoke = onBadgeInvoke
