--!strict

-- Server Handler Script


---------- Constants ----------

local Constants = {}

Constants.rankThreshold_RemoteFunction = script.Parent:WaitForChild("RankThreshold_RemoteFunction")

table.freeze(Constants)


---------- Imports ----------

local RankThresholds = require(script.Parent)


---------- Local functions ----------

local function onRankThresholdServerInvoke(player: Player, mode: string, ...)
	if mode == "Get Rank Thresholds" then
		return RankThresholds
	end
	return nil
end


----- Main -----

local function main()
	Constants.rankThreshold_RemoteFunction.OnServerInvoke = onRankThresholdServerInvoke
end


---------- Calling function ----------

main()
