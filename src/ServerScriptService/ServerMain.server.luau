--!strict

-- Server Main


---------- Imports ----------

local DataMigration = require(script.Parent:WaitForChild("DataMigration"):WaitForChild("Main"))
local GiveRankBadge = require(script.Parent:WaitForChild("GiveRankBadge"):WaitForChild("Main"))


---------- Local functions ----------

----- Main -----

local function main()
    -- DataMigration.start()
    GiveRankBadge.start()
end


---------- Calling function ----------

main()
