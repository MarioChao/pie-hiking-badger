--!strict
-- Rank Thresholds Module Script


---------- Validate environment ----------

local RunService = game:GetService("RunService")

if RunService:IsClient() then
	local RankThreshold_RemoteFunction = script:WaitForChild("RankThreshold_RemoteFunction")
	return RankThreshold_RemoteFunction:InvokeServer("Get Rank Thresholds")
end


---------- Types ----------

type BadgeTierInfo = {
	badgeId: number,
	tier: number,
}

type MinBadgeCondition = {
	badgeTier: number,
	minimumBadges: number,
}

type RankThreshold = {
	rankTitle: string,
	conditions: {MinBadgeCondition},
}

type RankThresholds = {
	badgeTierInfos: {BadgeTierInfo},
	badgeTierIds: {{number}},
	rankThresholds: {RankThreshold},
	rankPriority: {[string]: number},
}


---------- Return module ----------

return require(106825359403933) :: RankThresholds
