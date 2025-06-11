--!strict
-- Preload Script


---------- Services ----------

local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


---------- Imports ----------

local RankThresholds = require(ReplicatedStorage:WaitForChild("RankThresholds"))


---------- Local functions ----------

local function preloadPlaceThumbnails()
	-- Get place ids
	local placeIdHashTable = {}
	for _, placeId in RankThresholds.badgePlaceId do
		placeIdHashTable[placeId] = true
	end

	-- Preload place thumbnails
	local assets = {}
	for placeId, _ in placeIdHashTable do
		local imageLabel = Instance.new("ImageLabel")
		imageLabel.Image = `rbxthumb://type=GameThumbnail&id={placeId}&w=256&h=144`
		table.insert(assets, imageLabel)
	end
	ContentProvider:PreloadAsync(assets)

	-- Remove assets
	for _, asset in assets do
		Debris:AddItem(asset, 0)
	end
	table.clear(assets)
end


---------- Callng / connecting functions ----------

preloadPlaceThumbnails()
