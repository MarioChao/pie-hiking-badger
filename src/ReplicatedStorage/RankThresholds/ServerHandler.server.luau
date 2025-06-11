--!strict
-- Server Handler Script


---------- Instances ----------

local RankThreshold_RemoteFunction = script.Parent.RankThreshold_RemoteFunction


---------- Imports ----------

local RankThresholds = require(script.Parent)


---------- Event functions ----------

local function onRankThresholdServerInvoke(player: Player, mode: string, ...)
	if mode == "Get Rank Thresholds" then
		return RankThresholds
	end
	return nil
end


---------- Calling / connecting functions ----------

RankThreshold_RemoteFunction.OnServerInvoke = onRankThresholdServerInvoke
