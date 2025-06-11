--!strict
-- Initialize Leaderstats Script


---------- Services ----------

local ServerStorage = game:GetService("ServerStorage")


---------- Imports ----------

local LeaderstatsModule = require(ServerStorage.LeaderstatsModule)


---------- Variables ----------

local initialStats: LeaderstatsModule.InitialStats = {
	["Rank"] = {
		ValueType = LeaderstatsModule.ValueType.StringValue,
		DefaultValue = "none"
	}
}


---------- Calling / connecting functions ----------

LeaderstatsModule.initialize(initialStats)
