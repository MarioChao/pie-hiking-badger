--!strict
-- DataStore Types Module Script

---------- Types ----------

local DSName = {
	TestedRank = "TestedRank"
}
export type DSName = typeof(DSName)


---------- Module ----------

local DataStoreTypes = {
	DSName = DSName
}

table.freeze(DataStoreTypes)


---------- Return module ----------

return DataStoreTypes
