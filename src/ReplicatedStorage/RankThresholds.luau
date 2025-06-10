--!strict
-- Rank Thresholds Module Script


---------- Types ----------

type MinBadgeCondition = {
	badgeTier: number,
	minimumBadges: number
}

type RankThreshold = {
	rankTitle: string,
	conditions: {MinBadgeCondition}
}

type RankThresholds = {
	badgeTierIds: {{number}},
	rankThresholds: {RankThreshold}
}


---------- Return module ----------

return require(106825359403933) :: RankThresholds
