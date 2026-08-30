--!strict

-- Server Main


---------- Imports ----------

local DataMigration = require(script.Parent:WaitForChild("DataMigration"):WaitForChild("Main"))


---------- Local functions ----------

----- Main -----

local function main()
    DataMigration.start()
end


---------- Calling function ----------

main()
