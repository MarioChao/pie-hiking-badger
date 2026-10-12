--!strict

-- Menu Script


---------- Services ----------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")


---------- Imports ----------

local _Modules = ReplicatedStorage:WaitForChild("Modules")
local BadgeUtil = require(_Modules:WaitForChild("BadgeUtil"))
local BelovedRemote = require(_Modules:WaitForChild("BelovedRemote"))

local AutoUIScale = require(script.Parent:WaitForChild("AutoUIScale"))

local RankThresholds = require(ReplicatedStorage:WaitForChild("RankThresholds"))

type RankBadge = {
	[string]: {
		badgeId: number,
		badgeName: string,
	}
}

type BadgeFrameInfo = {
	badgeId: string,
	frame: TextButton,
	defaultIndex: number,
	tier: number,
	creator: string,
	gameName: string,
	badgeName: string,
	description: string,
}


---------- Constants ----------

local Constants = {}

do
	local MenuEvents = ReplicatedStorage:WaitForChild("MenuEvents")
	Constants.menuRemote = MenuEvents.MenuRemote
	Constants.gameInfoBindable = MenuEvents.GameInfoBindable
end

Constants.localPlayer = Players.LocalPlayer
Constants.playerGui = Constants.localPlayer.PlayerGui

Constants.rankPriority = RankThresholds.rankPriority

Constants.sortTypes = {"Default", "+ Tier", "- Tier", "+ Name", "- Name"}
Constants.showTypes = {"All", "Owned", "Not Owned"}


----- Gui instances -----

do
	local screenUis = {}
	screenUis.menu_ScreenGui = Constants.playerGui:WaitForChild("Menu_ScreenGui") :: ScreenGui
	screenUis.screenGui_uiScale = screenUis.menu_ScreenGui:WaitForChild("UIScale") :: UIScale
	screenUis.menu_Frame = screenUis.menu_ScreenGui:WaitForChild("Menu_Frame") :: Frame

	screenUis.exit_ImageButton = screenUis.menu_Frame:WaitForChild("Exit_ImageButton") :: ImageButton

	screenUis.buttons_Frame = screenUis.menu_Frame:WaitForChild("Buttons_Frame") :: Frame
	screenUis.buttons_ScrollingFrame = screenUis.buttons_Frame:WaitForChild("Buttons_ScrollingFrame") :: Frame
	screenUis.subdocks_Frame = screenUis.menu_Frame:WaitForChild("Subdocks_Frame") :: Frame

	-- Challenges dock
	screenUis.challenges_Frame = screenUis.subdocks_Frame:WaitForChild("Challenges_Frame") :: Frame
	screenUis.badges_ScrollingFrame = screenUis.challenges_Frame:WaitForChild("Badges_ScrollingFrame") :: ScrollingFrame
	screenUis.templateBadge_FrameButton = screenUis.badges_ScrollingFrame:WaitForChild("TemplateBadge_FrameButton") :: TextButton

	-- Challenges: filters
	screenUis.filters_ScrollingFrame = screenUis.challenges_Frame:WaitForChild("Filters_ScrollingFrame") :: ScrollingFrame
	screenUis.search_TextBox = screenUis.filters_ScrollingFrame:WaitForChild("Search_TextBox") :: TextBox
	screenUis.sort_Frame = screenUis.filters_ScrollingFrame:WaitForChild("Sort_Frame") :: Frame
	screenUis.sortType_TextButton = screenUis.sort_Frame:WaitForChild("SortType_TextButton") :: TextButton
	screenUis.show_Frame = screenUis.filters_ScrollingFrame:WaitForChild("Show_Frame") :: Frame
	screenUis.showType_TextButton = screenUis.show_Frame:WaitForChild("ShowType_TextButton") :: TextButton

	-- Awards dock
	screenUis.awards_Frame = screenUis.subdocks_Frame:WaitForChild("Awards_Frame") :: Frame
	screenUis.awards_ScrollingFrame = screenUis.awards_Frame:WaitForChild("Awards_ScrollingFrame") :: ScrollingFrame
	screenUis.templateAward_Frame = screenUis.awards_ScrollingFrame:WaitForChild("TemplateAward_Frame") :: Frame

	-- Stats dock
	screenUis.stats_Frame = screenUis.subdocks_Frame:WaitForChild("Stats_Frame") :: Frame
	screenUis.stats_ScrollingFrame = screenUis.stats_Frame:WaitForChild("Stats_ScrollingFrame") :: ScrollingFrame
	screenUis.templateStat_Frame = screenUis.stats_ScrollingFrame:WaitForChild("TemplateStat_Frame") :: Frame

	-- Ranks info dock
	screenUis.ranksInfo_Frame = screenUis.subdocks_Frame:WaitForChild("RanksInfo_Frame") :: Frame
	screenUis.ranksInfo_ScrollingFrame = screenUis.ranksInfo_Frame:WaitForChild("RanksInfo_ScrollingFrame") :: ScrollingFrame
	screenUis.templateRankInfo_Frame = screenUis.ranksInfo_ScrollingFrame:WaitForChild("TemplateRankInfo_Frame") :: Frame

	table.freeze(screenUis)
	Constants.screenUis = screenUis
end

table.freeze(Constants)


---------- Globals ----------

local Globals = {}

Globals.badgeId_isOwned = {} :: {[string]: boolean}
Globals.badgeId_info = {} :: {[string]: typeof(BadgeUtil.BadgeInfo.getBadgeInfo(0))}

Globals.tierOwnedBadgesCount = {} :: {number}

Globals.rankAwardFrame = {} :: {[string]: Frame}

Globals.badgeId_frameInfo = {} :: {[string]: BadgeFrameInfo}
Globals.sortTypeIndex = 1
Globals.showTypeIndex = 1
Globals.badgeId_alphabeticalIndex = {} :: {[string]: number}

Globals.setUpStates = {} :: {[string]: true?}

local playerRank


---------- Local functions ----------

local getIsRankReached
local setButtonClaimable
local checkAllBadges
local checkBadges
local getIsStringMatchesPlain

local getLayoutOrder
local setScreenGuiAutoScale

local showSubdock
local setUpMenuButtons
local setUpBadgesScrollingFrame
local _refreshBadgeFramesLayoutOrder
local _setUpFilteringBadges
local setUpAwardsScrollingFrame
local setUpStatsScrollingFrame
local setUpRanksInfoScrollingFrame

local onUpdateRank
local onMenuClientEvent

local setUpMenu


----- Helper -----

getIsRankReached = function(rank: string)
	if not (Constants.rankPriority[playerRank] and Constants.rankPriority[rank]) then
		return false
	end
	if not (Constants.rankPriority[playerRank] >= Constants.rankPriority[rank]) then
		return false
	end
	return true
end

setButtonClaimable = function(textButton: TextButton, canClaim: boolean)
	if canClaim then
		textButton.Interactable = true
		textButton.BackgroundColor3 = textButton:GetAttribute("EnabledColor") :: Color3
	else
		textButton.Interactable = false
		textButton.BackgroundColor3 = textButton:GetAttribute("DisabledColor") :: Color3
	end
end

checkAllBadges = function(player: Player)
	local allBadgeIds = {}
	for _, badgeIds in RankThresholds.badgeTierIds do
		for _, badgeId in badgeIds do
			table.insert(allBadgeIds, badgeId)
		end
	end
	BadgeUtil.CachedBadgeCheck.checkUserHasBadges(player.UserId, allBadgeIds)
end

checkBadges = function()
	-- Check all badges
	checkAllBadges(Constants.localPlayer)

	-- Go through badges
	for tier, badgeIds in RankThresholds.badgeTierIds do
		repeat
			-- Initialize table
			local uncachedBadgeIds: {number} = {}

			-- Check badges
			local checkResult = BadgeUtil.CachedBadgeCheck.checkUserHasBadges(Constants.localPlayer.UserId, badgeIds)

			-- Check results
			for _, badgeId in badgeIds do
				-- Check result available
				if checkResult[badgeId] == nil then
					table.insert(uncachedBadgeIds, badgeId)
					continue
				end

				-- Set owned
				Globals.badgeId_isOwned[tostring(badgeId)] = checkResult[badgeId] :: boolean

				-- Increment badges count
				if checkResult[badgeId] then
					if not Globals.tierOwnedBadgesCount[tier] then
						Globals.tierOwnedBadgesCount[tier] = 0
					end
					Globals.tierOwnedBadgesCount[tier] += 1
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

getIsStringMatchesPlain = function(string: string, pattern: string)
	local _, pcallResult = pcall(function()
		return string.find(string, pattern, 1, true) ~= nil
	end)
	return pcallResult == true
end


----- Gui helpers -----

getLayoutOrder = function(sortTypeIndex: number, frameInfo: BadgeFrameInfo)
	if sortTypeIndex == 1 then
		return frameInfo.defaultIndex
	elseif sortTypeIndex == 2 then
		return frameInfo.defaultIndex + frameInfo.tier * 1000
	elseif sortTypeIndex == 3 then
		return -(frameInfo.defaultIndex + frameInfo.tier * 1000)
	elseif sortTypeIndex == 4 then
		return Globals.badgeId_alphabeticalIndex[frameInfo.badgeId] or 0
	else
		return -(Globals.badgeId_alphabeticalIndex[frameInfo.badgeId] or 0)
	end
end

-- function adapted from the pie hiking plugin
setScreenGuiAutoScale = function()
	local uiScale = Constants.screenUis.screenGui_uiScale
	local unitSize = (function()
		local result
		local value = uiScale:GetAttribute("UnitSize")
		if typeof(value) == "Vector2" then
			result = value
		else
			warn(`[Menu]: No 'UnitSize' attribute (type 'Vector2') found for '{uiScale}'.`)
			result = Vector2.new(1000, 600)
		end
		return result
	end)()
	local scaleRange = (function()
		local result
		local value = uiScale:GetAttribute("ScaleRange")
		if typeof(value) == "NumberRange" then
			result = value
		else
			warn(`[Menu]: No 'ScaleRange' attribute (type 'NumberRange') found for '{uiScale}'.`)
			result = NumberRange.new(0.6, 1)
		end
		return result
	end)()
	AutoUIScale.setScreenGuiAutoScale(Constants.screenUis.menu_ScreenGui, uiScale, unitSize, scaleRange)
end


----- Docks -----

showSubdock = function(subdockName: string)
	for _, frame in Constants.screenUis.subdocks_Frame:GetChildren() do
		if frame:IsA("Frame") then
			frame.Visible = false
		end
	end
	local subdock = Constants.screenUis.subdocks_Frame:FindFirstChild(`{subdockName}_Frame`)
	if subdock and subdock:IsA("Frame") then
		subdock.Visible = true
	end
end

setUpMenuButtons = function()
	for _, button in Constants.screenUis.buttons_ScrollingFrame:GetChildren() do
		-- Validate button
		if not button:IsA("TextButton") then
			continue
		end

		-- Get name
		local name = string.sub(button.Name, 1, (string.find(button.Name, "_TextButton", 0, true) or 1) - 1)

		-- Set up button
		button.Activated:Connect(function()
			showSubdock(name)
		end)
	end
end

setUpBadgesScrollingFrame = function()
	-- Get template attributes
	local ownedColor: Color3 = Constants.screenUis.templateBadge_FrameButton:GetAttribute("OwnedColor") :: Color3
	local unownedColor: Color3 = Constants.screenUis.templateBadge_FrameButton:GetAttribute("UnownedColor") :: Color3

	-- Hide template
	Constants.screenUis.templateBadge_FrameButton.Visible = false

	-- Initialize badge frame infos
	Globals.badgeId_frameInfo = {}

	-- Determine badge default indexes
	local badgeId_defaultIndex = {} :: {[string]: number}
	for index, badgeTierInfo in RankThresholds.badgeTierInfos do
		badgeId_defaultIndex[tostring(badgeTierInfo.badgeId)] = index
	end

	-- Create preliminary frames for each badge
	for _, tierInfo in RankThresholds.badgeTierInfos do
		-- Clone frame
		local badgeFrame = Constants.screenUis.templateBadge_FrameButton:Clone()

		-- Get child instances
		local icon_ImageLabel: ImageLabel = badgeFrame:FindFirstChild("Icon_ImageLabel") :: ImageLabel
		local details_Frame: Frame = badgeFrame:FindFirstChild("Details_Frame") :: Frame
		local name_TextLabel: TextLabel = details_Frame:FindFirstChild("Name_TextLabel") :: TextLabel
		local description_TextLabel: TextLabel = details_Frame:FindFirstChild("Description_TextLabel") :: TextLabel
		local tier_TextLabel: TextLabel = details_Frame:FindFirstChild("Tier_TextLabel") :: TextLabel

		-- Set preliminary badge info
		icon_ImageLabel.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
		name_TextLabel.Text = tierInfo.badgeName
		description_TextLabel.Text = "..."
		tier_TextLabel.Text = `Tier {tierInfo.tier}`

		-- Store preliminary badge frame info
		local badgeId = tierInfo.badgeId
		local badgeIdStr = tostring(tierInfo.badgeId)
		Globals.badgeId_frameInfo[badgeIdStr] = {
			badgeId = badgeIdStr,
			frame = badgeFrame,
			defaultIndex = badgeId_defaultIndex[badgeIdStr],
			tier = tierInfo.tier,
			creator = RankThresholds.badgeId_tierInfo[badgeIdStr].creator,
			gameName = RankThresholds.badgeId_tierInfo[badgeIdStr].gameName,
			badgeName = tierInfo.badgeName,
			description = "...",
		}

		-- Set frame properties
		task.defer(function()
			while Globals.badgeId_isOwned[badgeIdStr] == nil do
				task.wait(1)
			end

			-- Set color & visibility
			if Globals.badgeId_isOwned[badgeIdStr] then
				badgeFrame.BackgroundColor3 = ownedColor
				badgeFrame.Visible = Globals.showTypeIndex ~= 3
			elseif Globals.badgeId_isOwned[badgeIdStr] == false then
				badgeFrame.BackgroundColor3 = unownedColor
				badgeFrame.Visible = Globals.showTypeIndex ~= 2
			end
		end)
		badgeFrame.Name = `Badge_{badgeId}_Frame`
		badgeFrame.Visible = true

		-- Set layout order
		badgeFrame.LayoutOrder = getLayoutOrder(Globals.sortTypeIndex, Globals.badgeId_frameInfo[badgeIdStr])

		-- Set clicked connection
		badgeFrame.Activated:Connect(function()
			if Globals.badgeId_info[badgeIdStr] then
				Constants.gameInfoBindable:Fire("ToggleShowBadgeInfo", badgeId, Globals.badgeId_info[badgeIdStr])
			else
				Constants.gameInfoBindable:Fire("ToggleShowBadgeInfo", badgeId, {Name = tierInfo.badgeName})
			end
		end)

		-- Set parent
		badgeFrame.Parent = Constants.screenUis.badges_ScrollingFrame
	end

	-- Set preliminary alphabetic index for badge ids
	do
		local badgeIdTable = {}
		for badgeId, frameInfo in Globals.badgeId_frameInfo do
			table.insert(badgeIdTable, {badgeId = badgeId, badgeNameLower = string.lower(frameInfo.badgeName)})
		end
		table.sort(badgeIdTable, function(a, b)
			return a.badgeNameLower < b.badgeNameLower
		end)
		for index, badge in badgeIdTable do
			Globals.badgeId_alphabeticalIndex[badge.badgeId] = index
		end
	end
	print(`[Menu]: Finished adding all badges (preliminary).`)

	-- Go through badges to set fetched info
	for tier, badgeIds in RankThresholds.badgeTierIds do
		-- Create badge frames
		local badgeFrames: {TextButton} = {}
		local count = 0
		for _index, badgeId in badgeIds do
			task.defer(function()
				-- Get index
				local tierIndex = _index

				-- Get frame
				local badgeIdStr = tostring(badgeId)
				local badgeFrame = Globals.badgeId_frameInfo[badgeIdStr].frame

				-- Get badge info
				local badgeInfo
				while true do
					badgeInfo = BadgeUtil.BadgeInfo.getBadgeInfo(badgeId)
					if badgeInfo and next(badgeInfo) then
						break
					else
						print(`[Menu]: Failed to get badge info of badge '{badgeId}'! Retrying...`)
						task.wait(3)
					end
				end
				if not (badgeInfo and next(badgeInfo)) then
					print(`[Menu]: Failed to get badge info of badge '{badgeId}'!`)
					return
				end

				-- Store badge info
				Globals.badgeId_info[badgeIdStr] = badgeInfo

				-- Store badge frame
				badgeFrames[tierIndex] = badgeFrame
				count += 1
			end)
		end

		-- Wait until all badges are looked through
		while count < #badgeIds do
			RunService.Heartbeat:Wait()
		end

		-- Update badge frames
		for index = 1, #badgeIds do
			-- Validate badge frame & info
			local badgeIdStr = tostring(badgeIds[index])
			local badgeFrame = badgeFrames[index]
			local badgeInfo = Globals.badgeId_info[badgeIdStr]
			if not (badgeFrame and badgeInfo) then
				warn(`[Menu]: Invalid badge frame or badge info for badge '{badgeIdStr}'.`)
				continue
			end

			-- Update badge frame info
			local frameInfo = Globals.badgeId_frameInfo[badgeIdStr]
			frameInfo.badgeName = badgeInfo.Name
			frameInfo.description = badgeInfo.Description

			-- Get child instances
			local icon_ImageLabel: ImageLabel = badgeFrame:FindFirstChild("Icon_ImageLabel") :: ImageLabel
			local details_Frame: Frame = badgeFrame:FindFirstChild("Details_Frame") :: Frame
			local name_TextLabel: TextLabel = details_Frame:FindFirstChild("Name_TextLabel") :: TextLabel
			local description_TextLabel: TextLabel = details_Frame:FindFirstChild("Description_TextLabel") :: TextLabel

			-- Set badge info
			icon_ImageLabel.Image = `rbxassetid://{badgeInfo.IconImageId}`
			name_TextLabel.Text = badgeInfo.Name
			description_TextLabel.Text = badgeInfo.Description
		end

		-- Update alphabetic index for badge ids
		do
			local badgeIdTable = {}
			for badgeId, frameInfo in Globals.badgeId_frameInfo do
				table.insert(badgeIdTable, {badgeId = badgeId, badgeNameLower = string.lower(frameInfo.badgeName)})
			end
			table.sort(badgeIdTable, function(a, b)
				return a.badgeNameLower < b.badgeNameLower
			end)
			for index, badge in badgeIdTable do
				Globals.badgeId_alphabeticalIndex[badge.badgeId] = index
			end
		end

		-- Refresh layout order
		_refreshBadgeFramesLayoutOrder()
	end
	print(`[Menu]: Finished loading all badges.`)
end

_refreshBadgeFramesLayoutOrder = function()
	local sortTypeIndex = Globals.sortTypeIndex
	for badgeId, frameInfo in Globals.badgeId_frameInfo do
		frameInfo.frame.LayoutOrder = getLayoutOrder(sortTypeIndex, frameInfo)
	end
end

_setUpFilteringBadges = function()
	-- Ensure function only runs once
	if Globals.setUpStates['_setUpFilteringBadges'] then
		return
	end
	Globals.setUpStates['_setUpFilteringBadges'] = true

	-- Set up sort & show type buttons
	Constants.screenUis.sortType_TextButton.Text = Constants.sortTypes[Globals.sortTypeIndex]
	Constants.screenUis.showType_TextButton.Text = Constants.showTypes[Globals.showTypeIndex]
	Constants.screenUis.sortType_TextButton.Activated:Connect(function()
		-- Cycle sort type
		Globals.sortTypeIndex %= #Constants.sortTypes
		Globals.sortTypeIndex += 1
		Constants.screenUis.sortType_TextButton.Text = Constants.sortTypes[Globals.sortTypeIndex]

		-- Sort badges
		_refreshBadgeFramesLayoutOrder()
	end)
	Constants.screenUis.showType_TextButton.Activated:Connect(function()
		-- Cycle show type
		Globals.showTypeIndex %= #Constants.showTypes
		Globals.showTypeIndex += 1
		Constants.screenUis.showType_TextButton.Text = Constants.showTypes[Globals.showTypeIndex]
	end)

	-- Show/hide filter loop
	local previousFilter = {} :: {filterText: string?, showTypeIndex: number?}
	RunService.Heartbeat:Connect(function()
		-- Get filter state
		local filterText = string.lower(Constants.screenUis.search_TextBox.Text)

		-- Validate different filter state
		if (
			filterText == previousFilter.filterText
			and Globals.showTypeIndex == previousFilter.showTypeIndex
		) then
			return
		end

		-- Update previous state
		previousFilter.filterText = filterText
		previousFilter.showTypeIndex = Globals.showTypeIndex

		-- Update filter
		for badgeId, frameInfo in Globals.badgeId_frameInfo do
			-- Check if badge passes show filter
			local isShowing = false
			if Globals.showTypeIndex == 1 then
				isShowing = true
			elseif Globals.showTypeIndex == 2 then
				isShowing = Globals.badgeId_isOwned[badgeId]
			else
				isShowing = Globals.badgeId_isOwned[badgeId] == false
			end

			-- Check if badge passes search filter
			local isSearchSuccessful = false
			if isShowing then
				if filterText == "" then
					isSearchSuccessful = true
				else
					isSearchSuccessful = isSearchSuccessful or getIsStringMatchesPlain(string.lower(frameInfo.creator), filterText)
					isSearchSuccessful = isSearchSuccessful or getIsStringMatchesPlain(string.lower(frameInfo.gameName), filterText)
					isSearchSuccessful = isSearchSuccessful or getIsStringMatchesPlain(string.lower(frameInfo.badgeName), filterText)
					isSearchSuccessful = isSearchSuccessful or getIsStringMatchesPlain(string.lower(frameInfo.description), filterText)
					isSearchSuccessful = isSearchSuccessful or getIsStringMatchesPlain(string.lower(`tier {frameInfo.tier}`), filterText)
				end
			end

			-- Set visibility
			frameInfo.frame.Visible = isShowing and isSearchSuccessful
		end
	end)
end

setUpAwardsScrollingFrame = function()
	-- Hide template
	Constants.screenUis.templateAward_Frame.Visible = false

	-- Initialize frame table
	Globals.rankAwardFrame = {}

	-- Go through ranks
	for index = #RankThresholds.rankThresholds, 1, -1 do
		-- Get rank
		local rank = RankThresholds.rankThresholds[index].rankTitle

		-- Clone frame
		local awardFrame = Constants.screenUis.templateAward_Frame:Clone()
		Globals.rankAwardFrame[rank] = awardFrame

		-- Get child instances
		local claim_TextButton: TextButton = awardFrame:FindFirstChild("Claim_TextButton") :: TextButton
		local title_TextLabel: TextLabel = awardFrame:FindFirstChild("Title_TextLabel") :: TextLabel

		-- Set award info
		title_TextLabel.Text = `Reach {rank} rank.`

		-- Set button data
		local isRankReached = getIsRankReached(rank)
		setButtonClaimable(claim_TextButton, isRankReached)
		claim_TextButton.Activated:Connect(function()
			BelovedRemote.fire_toServer("GiveBadgeWithRank", rank)
		end)

		-- Set frame properties
		awardFrame.Name = `Award_{index}_Frame`
		awardFrame.Visible = true
		awardFrame.Parent = Constants.screenUis.awards_ScrollingFrame
	end
end

setUpStatsScrollingFrame = function()
	-- Hide template
	Constants.screenUis.templateStat_Frame.Visible = false

	-- Go through tiers
	for tier, badgeIds in RankThresholds.badgeTierIds do
		-- Validate non-empty badge ids
		if #badgeIds == 0 then
			continue
		end

		-- Clone frame
		local statFrame = Constants.screenUis.templateStat_Frame:Clone()

		-- Get child instances
		local title_TextLabel: TextLabel = statFrame:FindFirstChild("Title_TextLabel") :: TextLabel
		local info_Frame: Frame = statFrame:FindFirstChild("Info_Frame") :: Frame
		local info_TextLabel: TextLabel = info_Frame:FindFirstChild("Info_TextLabel") :: TextLabel

		-- Set stat info
		title_TextLabel.Text = `Tier {tier}`
		task.defer(function()
			while true do
				local ownedCount = Globals.tierOwnedBadgesCount[tier] or 0
				local infoText = `{ownedCount}/{#badgeIds}`
				infoText ..= ` ({math.round(ownedCount / #badgeIds * 100)}%)`
				info_TextLabel.Text = infoText
				task.wait(1)
			end
		end)

		-- Set frame properties
		statFrame.Name = `Stat_{tier}_Frame`
		statFrame.Visible = true
		statFrame.Parent = Constants.screenUis.stats_ScrollingFrame
	end
end

setUpRanksInfoScrollingFrame = function()
	-- Hide template
	Constants.screenUis.templateRankInfo_Frame.Visible = false

	-- Go through ranks
	for index = #RankThresholds.rankThresholds, 1, -1 do
		-- Get rank
		local rankThresholdsInfo = RankThresholds.rankThresholds[index]
		local rank = rankThresholdsInfo.rankTitle

		-- Clone frame
		local rankInfoFrame = Constants.screenUis.templateRankInfo_Frame:Clone()

		-- Get child instances
		local rankTitle_TextLabel: TextLabel = rankInfoFrame:FindFirstChild("RankTitle_TextLabel") :: TextLabel
		local info_TextLabel: TextLabel = rankInfoFrame:FindFirstChild("Info_TextLabel") :: TextLabel

		-- Set info
		rankTitle_TextLabel.Text = `{rank}`
		task.defer(function()
			while true do
				local infoText = ""
				for conditionIndex = #rankThresholdsInfo.conditions, 1, -1 do
					-- Newline between each tier
					if infoText ~= "" then
						infoText ..= "\n"
					end

					-- Store condition info
					local conditionInfo = rankThresholdsInfo.conditions[conditionIndex]
					local tier = conditionInfo.badgeTier
					local minimumBadges = conditionInfo.minimumBadges
					local ownedCount = math.min(Globals.tierOwnedBadgesCount[tier] or 0, minimumBadges)
					infoText ..= `Tier {tier} - `
					infoText ..= `{ownedCount}/{minimumBadges}`
				end
				if infoText == "" then
					infoText = "None"
				end
				info_TextLabel.Text = infoText
				task.wait(1)
			end
		end)

		-- Set frame properties
		rankInfoFrame.Name = `RankInfo_{index}_Frame`
		rankInfoFrame.Visible = true
		rankInfoFrame.Parent = Constants.screenUis.ranksInfo_ScrollingFrame
	end
end


----- Events -----

onUpdateRank = function(newRank: string)
	-- Store rank
	playerRank = newRank

	-- Validate rank
	if not playerRank then
		return
	end

	-- Modify award frames
	for rank, awardFrame in Globals.rankAwardFrame do
		-- Check rank reached
		local isRankReached = getIsRankReached(rank)

		-- Modify gui
		local claim_TextButton: TextButton = awardFrame:FindFirstChild("Claim_TextButton") :: TextButton
		setButtonClaimable(claim_TextButton, isRankReached)
	end
end

onMenuClientEvent = function(mode: string, ...)
	if mode == "UpdateRank" then
		onUpdateRank(...)
	end
end


----- Set up -----

setUpMenu = function()
	Constants.screenUis.menu_ScreenGui.Enabled = false
	showSubdock("Challenges")
	task.defer(setUpMenuButtons)
	task.defer(checkBadges)
	task.defer(setUpBadgesScrollingFrame)
	task.defer(_setUpFilteringBadges)
	task.defer(setUpAwardsScrollingFrame)
	task.defer(setUpStatsScrollingFrame)
	task.defer(setUpRanksInfoScrollingFrame)
	task.defer(setScreenGuiAutoScale)
end


---------- Calling / connecting functions ----------

Constants.menuRemote.OnClientEvent:Connect(onMenuClientEvent)

Constants.screenUis.exit_ImageButton.Activated:Connect(function()
	Constants.screenUis.menu_ScreenGui.Enabled = false
end)

setUpMenu()
