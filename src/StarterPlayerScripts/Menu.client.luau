--!strict
-- Menu Script


---------- Services ----------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")


---------- Imports ----------

local BadgeInfo = require(ReplicatedStorage.BadgeModules.BadgeInfo)
local CachedBadgeCheck = require(ReplicatedStorage.BadgeModules.BadgeCheck.CachedBadgeCheck)

local RankTresholds = require(ReplicatedStorage.RankThresholds)

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

local LocalPlayer = Players.LocalPlayer

local PlayerGui = LocalPlayer.PlayerGui


---------- GUI instances ----------

local Game_ScreenGui: ScreenGui = PlayerGui:WaitForChild("Game_ScreenGui")
local Menu_TextButton: TextButton = Game_ScreenGui.Menu_TextButton

local Menu_ScreenGui: ScreenGui = PlayerGui:WaitForChild("Menu_ScreenGui")
local Menu_Frame: Frame = Menu_ScreenGui.Menu_Frame

local Buttons_Frame: Frame = Menu_Frame.Buttons_Frame
local Subdocks_Frame: Frame = Menu_Frame.Subdocks_Frame

local Challenges_Frame: Frame = Subdocks_Frame.Challenges_Frame
local Badges_ScrollingFrame: ScrollingFrame = Challenges_Frame.Badges_ScrollingFrame
local TemplateBadge_Frame: Frame = Badges_ScrollingFrame.TemplateBadge_Frame

local Awards_Frame: Frame = Subdocks_Frame.Awards_Frame
local Awards_ScrollingFrame: ScrollingFrame = Awards_Frame.Awards_ScrollingFrame
local TemplateAward_Frame: Frame = Awards_ScrollingFrame.TemplateAward_Frame


---------- Variables ----------

local rankPriority = RankTresholds.rankPriority

local rankAwardFrame: {[string]: Frame}

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
	for _, button in Buttons_Frame:GetChildren() do
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
	local ownedColor: Color3 = TemplateBadge_Frame:GetAttribute("OwnedColor")
	local unownedColor: Color3 = TemplateBadge_Frame:GetAttribute("UnownedColor")

	-- Hide template
	TemplateBadge_Frame.Visible = false

	-- Initialize table
	local uncachedBadgeIds: {number} = {}

	-- Go through badges
	for tier, badgeIds in RankTresholds.badgeTierIds do
		repeat
			-- Check badges
			local checkResult = CachedBadgeCheck.userHasBadges(LocalPlayer.UserId, badgeIds)
			for _, badgeId in badgeIds do
				-- Check result available
				if checkResult[badgeId] == nil then
					table.insert(uncachedBadgeIds, badgeId)
					continue
				end

				-- Clone frame
				local badgeFrame = TemplateBadge_Frame:Clone()

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

				-- Set badge info
				icon_ImageLabel.Image = `rbxassetid://{badgeInfo.IconImageId}`
				name_TextLabel.Text = badgeInfo.Name
				description_TextLabel.Text = badgeInfo.Description
				tier_TextLabel.Text = `Tier {tier}`

				-- Set frame properties
				if checkResult[badgeId] then
					badgeFrame.BackgroundColor3 = ownedColor
				elseif checkResult[badgeId] == false then
					badgeFrame.BackgroundColor3 = unownedColor
				end
				badgeFrame.Name = `Badge_{badgeId}_Frame`
				badgeFrame.Visible = true
				badgeFrame.Parent = Badges_ScrollingFrame
			end

			-- Replace badge ids with uncached
			badgeIds = uncachedBadgeIds
			if #uncachedBadgeIds > 0 then
				print("Some badges not checked!")
				print(uncachedBadgeIds)
				RunService.Heartbeat:Wait()
			end
		until #uncachedBadgeIds == 0
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

local function onMenuActivated()
	Menu_ScreenGui.Enabled = not Menu_ScreenGui.Enabled
end

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
	task.defer(setUpBadgesScrollingFrame)
	task.defer(setUpAwardsScrollingFrame)
end


---------- Calling / connecting functions ----------

Menu_TextButton.Activated:Connect(onMenuActivated)

MenuRemote.OnClientEvent:Connect(onMenuClientEvent)

setUpMenu()
