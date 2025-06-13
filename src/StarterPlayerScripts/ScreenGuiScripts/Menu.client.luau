--!strict
-- Menu Script


---------- Services ----------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")


---------- Imports ----------

local BadgeModules = ReplicatedStorage:WaitForChild("BadgeModules")
local BadgeInfo = require(BadgeModules.BadgeInfo)
local CachedBadgeCheck = require(BadgeModules.BadgeCheck.CachedBadgeCheck)

local RankTresholds = require(ReplicatedStorage:WaitForChild("RankThresholds"))

type RankBadge = {
	[string]: {
		badgeId: number,
		badgeName: string,
	}
}


---------- Instances ----------

local GiveRankBadgeEvents = ReplicatedStorage:WaitForChild("GiveRankBadgeEvents")
local GiveRankBadgeRemote = GiveRankBadgeEvents.GiveRankBadgeRemote

local MenuEvents = ReplicatedStorage:WaitForChild("MenuEvents")
local MenuRemote = MenuEvents.MenuRemote
local GameInfoBindable = MenuEvents.GameInfoBindable

local LocalPlayer = Players.LocalPlayer

local PlayerGui = LocalPlayer.PlayerGui


---------- Gui instances ----------

local Menu_ScreenGui: ScreenGui = PlayerGui:WaitForChild("Menu_ScreenGui")
local Menu_Frame: Frame = Menu_ScreenGui.Menu_Frame

local Exit_ImageButton: ImageButton = Menu_Frame.Exit_ImageButton

local Buttons_Frame: Frame = Menu_Frame.Buttons_Frame
local Buttons_ScrollingFrame: Frame = Buttons_Frame.Buttons_ScrollingFrame
local Subdocks_Frame: Frame = Menu_Frame.Subdocks_Frame

local Challenges_Frame: Frame = Subdocks_Frame.Challenges_Frame
local Badges_ScrollingFrame: ScrollingFrame = Challenges_Frame.Badges_ScrollingFrame
local TemplateBadge_FrameButton: TextButton = Badges_ScrollingFrame.TemplateBadge_FrameButton

local Awards_Frame: Frame = Subdocks_Frame.Awards_Frame
local Awards_ScrollingFrame: ScrollingFrame = Awards_Frame.Awards_ScrollingFrame
local TemplateAward_Frame: Frame = Awards_ScrollingFrame.TemplateAward_Frame

local Stats_Frame: Frame = Subdocks_Frame.Stats_Frame
local Stats_ScrollingFrame: ScrollingFrame = Stats_Frame.Stats_ScrollingFrame
local TemplateStat_Frame: Frame = Stats_ScrollingFrame.TemplateStat_Frame


---------- Variables ----------

local rankPriority = RankTresholds.rankPriority

local badgeIdOwned: {[number]: boolean} = {}
local badgeIdInfo: {[number]: BadgeInfo.BadgeInfo} = {}

local tierOwnedBadgesCount: {number} = {}

local rankAwardFrame: {[string]: Frame} = {}

local playerRank


---------- Helper functions ----------

local function getIsRankReached(rank: string)
	if not (rankPriority[playerRank] and rankPriority[rank]) then
		return false
	end
	if not (rankPriority[playerRank] >= rankPriority[rank]) then
		return false
	end
	return true
end

local function setButtonClaimable(textButton: TextButton, canClaim: boolean)
	if canClaim then
		textButton.Interactable = true
		textButton.BackgroundColor3 = textButton:GetAttribute("EnabledColor")
	else
		textButton.Interactable = false
		textButton.BackgroundColor3 = textButton:GetAttribute("DisabledColor")
	end
end

local function checkBadges()
	-- Go through badges
	for tier, badgeIds in RankTresholds.badgeTierIds do
		repeat
			-- Initialize table
			local uncachedBadgeIds: {number} = {}

			-- Check badges
			local checkResult = CachedBadgeCheck.userHasBadges(LocalPlayer.UserId, badgeIds)

			-- Check results
			for _, badgeId in badgeIds do
				-- Check result available
				if checkResult[badgeId] == nil then
					table.insert(uncachedBadgeIds, badgeId)
					continue
				end

				-- Set owned
				badgeIdOwned[badgeId] = checkResult[badgeId]

				-- Increment badges count
				if checkResult[badgeId] then
					if not tierOwnedBadgesCount[tier] then
						tierOwnedBadgesCount[tier] = 0
					end
					tierOwnedBadgesCount[tier] += 1
				end
			end

			-- Replace badge ids with uncached
			badgeIds = uncachedBadgeIds
			if #uncachedBadgeIds > 0 then
				print("Some badges not checked!")
				task.wait(10)
			end
		until #uncachedBadgeIds == 0
	end
end


---------- Local functions ----------

local function showSubdock(subdockName: string)
	for _, frame in Subdocks_Frame:GetChildren() do
		frame.Visible = false
	end
	local subdock = Subdocks_Frame:FindFirstChild(`{subdockName}_Frame`)
	if subdock then
		subdock.Visible = true
	end
end

local function setUpMenuButtons()
	for _, button in Buttons_ScrollingFrame:GetChildren() do
		-- Validate button
		if not button:IsA("TextButton") then
			continue
		end

		-- Get name
		local name = string.sub(button.Name, 1, string.find(button.Name, "_TextButton", 0, true) - 1)

		-- Set up button
		button.Activated:Connect(function()
			showSubdock(name)
		end)
	end
end

local function setUpBadgesScrollingFrame()
	-- Get template attributes
	local ownedColor: Color3 = TemplateBadge_FrameButton:GetAttribute("OwnedColor")
	local unownedColor: Color3 = TemplateBadge_FrameButton:GetAttribute("UnownedColor")

	-- Hide template
	TemplateBadge_FrameButton.Visible = false

	-- Go through badges
	for tier, badgeIds in RankTresholds.badgeTierIds do
		-- Create badge frames
		local badgeFrames: {TextButton} = {}
		local count = 0
		for _index, badgeId in badgeIds do
			task.defer(function()
				-- Get index
				local index = _index

				-- Clone frame
				local badgeFrame = TemplateBadge_FrameButton:Clone()

				-- Get child instances
				local icon_ImageLabel: ImageLabel = badgeFrame.Icon_ImageLabel
				local details_Frame: Frame = badgeFrame.Details_Frame
				local name_TextLabel: TextLabel = details_Frame.Name_TextLabel
				local description_TextLabel: TextLabel = details_Frame.Description_TextLabel
				local tier_TextLabel: TextLabel = details_Frame.Tier_TextLabel

				-- Get badge info
				local badgeInfo = BadgeInfo.getBadgeInfo(badgeId)
				if not badgeInfo then
					print(`Failed to get badge info of badge {badgeId}!`)
				end
				badgeIdInfo[badgeId] = badgeInfo

				-- Set badge info
				icon_ImageLabel.Image = `rbxassetid://{badgeInfo.IconImageId}`
				name_TextLabel.Text = badgeInfo.Name
				description_TextLabel.Text = badgeInfo.Description
				tier_TextLabel.Text = `Tier {tier}`

				-- Set frame properties
				task.defer(function()
					while badgeIdOwned[badgeId] == nil do
						task.wait(1)
					end
					if badgeIdOwned[badgeId] then
						badgeFrame.BackgroundColor3 = ownedColor
					elseif badgeIdOwned[badgeId] == false then
						badgeFrame.BackgroundColor3 = unownedColor
					end
				end)
				badgeFrame.Name = `Badge_{badgeId}_Frame`
				badgeFrame.Visible = true

				-- Store badge frame
				badgeFrames[index] = badgeFrame
				count += 1
			end)
		end

		-- Wait until all badges are looked through
		while count < #badgeIds do
			RunService.Heartbeat:Wait()
		end

		-- Go through badge frames
		for index = 1, #badgeIds do
			-- Validate badge frame
			local badgeFrame = badgeFrames[index]
			if not badgeFrame then
				continue
			end

			-- Set clicked connection
			local badgeId = badgeIds[index]
			badgeFrame.Activated:Connect(function()
				GameInfoBindable:Fire("ToggleShowBadgeInfo", badgeId, badgeIdInfo[badgeId])
			end)

			-- Set parent
			badgeFrame.Parent = Badges_ScrollingFrame
		end
	end
end

local function setUpAwardsScrollingFrame()
	-- Hide template
	TemplateAward_Frame.Visible = false

	-- Initialize frame table
	rankAwardFrame = {}

	-- Go through ranks
	for index = #RankTresholds.rankThresholds, 1, -1 do
		-- Get rank
		local rank = RankTresholds.rankThresholds[index].rankTitle

		-- Clone frame
		local awardFrame = TemplateAward_Frame:Clone()
		rankAwardFrame[rank] = awardFrame

		-- Get child instances
		local claim_TextButton: TextButton = awardFrame.Claim_TextButton
		local title_TextLabel: TextLabel = awardFrame.Title_TextLabel

		-- Set award info
		title_TextLabel.Text = `Reach {rank} rank.`

		-- Set button data
		local isRankReached = getIsRankReached(rank)
		setButtonClaimable(claim_TextButton, isRankReached)
		claim_TextButton.Activated:Connect(function()
			GiveRankBadgeRemote:FireServer("GiveBadgeWithRank", rank)
		end)

		-- Set frame properties
		awardFrame.Name = `Award_{index}_Frame`
		awardFrame.Visible = true
		awardFrame.Parent = Awards_ScrollingFrame
	end
end

local function setUpStatsScrollingFrame()
	-- Hide template
	TemplateStat_Frame.Visible = false

	-- Go through tiers
	for tier, badgeIds in RankTresholds.badgeTierIds do
		-- Validate non-empty badge ids
		if #badgeIds == 0 then
			continue
		end

		-- Clone frame
		local statFrame = TemplateStat_Frame:Clone()

		-- Get child instances
		local title_TextLabel: TextLabel = statFrame.Title_TextLabel
		local info_Frame: Frame = statFrame.Info_Frame
		local info_TextLabel: TextLabel = info_Frame.Info_TextLabel

		-- Set stat info
		title_TextLabel.Text = `Tier {tier}`
		task.defer(function()
			while true do
				info_TextLabel.Text = `{tierOwnedBadgesCount[tier] or 0}/{#badgeIds}`
				task.wait(1)
			end
		end)

		-- Set frame properties
		statFrame.Name = `Stat_{tier}_Frame`
		statFrame.Visible = true
		statFrame.Parent = Stats_ScrollingFrame
	end
end


---------- Event connected functions ----------

local function onUpdateRank(newRank: string)
	-- Store rank
	playerRank = newRank

	-- Validate rank
	if not playerRank then
		return
	end

	-- Modify award frames
	for rank, awardFrame in rankAwardFrame do
		-- Check rank reached
		local isRankReached = getIsRankReached(rank)

		-- Modify gui
		local claim_TextButton: TextButton = awardFrame.Claim_TextButton
		setButtonClaimable(claim_TextButton, isRankReached)
	end
end


---------- Event functions ----------

local function onMenuClientEvent(mode: string, ...)
	if mode == "UpdateRank" then
		onUpdateRank(...)
	end
end


---------- Set up functions ----------

local function setUpMenu()
	Menu_ScreenGui.Enabled = false
	showSubdock("Challenges")
	task.defer(setUpMenuButtons)
	task.defer(checkBadges)
	task.defer(setUpBadgesScrollingFrame)
	task.defer(setUpAwardsScrollingFrame)
	task.defer(setUpStatsScrollingFrame)
end


---------- Calling / connecting functions ----------

MenuRemote.OnClientEvent:Connect(onMenuClientEvent)

Exit_ImageButton.Activated:Connect(function()
	Menu_ScreenGui.Enabled = false
end)

setUpMenu()
