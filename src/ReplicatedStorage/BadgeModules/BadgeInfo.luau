--!strict
-- Badge Info Module Script


---------- Module ----------

local BadgeInfo = {}


---------- Services ----------

local BadgeService = game:GetService("BadgeService")


---------- Types ----------

export type BadgeInfo = {
	Name: string,
	Description: string,
	IconImageId: number,
	IsEnabled: boolean
}


---------- Local functions ----------

local function getBadgeInfo(badgeId: number): BadgeInfo?
	-- Get info in protected call
	local success, result = pcall(function()
		return BadgeService:GetBadgeInfoAsync(badgeId)
	end)

	-- Return result
	if not success then
		print(result)
		return nil
	end
	return result
end


---------- Module functions ----------

BadgeInfo.getBadgeInfo = getBadgeInfo


---------- Return module ----------

return BadgeInfo
