--!strict

-- DataStore Types


---------- Types ----------

local DSName = {
	CombinedUserInfo = "CombinedUserInfo" :: DSName,
	TestedRank = "TestedRank" :: DSName,
}

export type DSName = "CombinedUserInfo" | "TestedRank"


---------- Module ----------

local DataStoreTypes = {
	DSName = DSName,
}


---------- Return module ----------

table.freeze(DataStoreTypes)
return DataStoreTypes
