--!strict

-- Combined User Info


---------- Imports ----------

local DSModule = require(script.Parent:WaitForChild("DataStoreModule"))


---------- Types ----------

export type PlayerInfo = {
    rank: string,
    username: string,
}


---------- Module ----------

local Module = {}


----- Module fields -----

function Module.getUserKeyGroup(userId: number)
    local key = userId % 64
    return `mod64_{key}`
end

function Module.getUserMapKeyString(userId: number)
    return `_{userId}`
end

function Module.updateUserInfo(userId: number, newPlayerInfo: PlayerInfo)
    local keyGroup = Module.getUserKeyGroup(userId)
    local mapKey = Module.getUserMapKeyString(userId)
    DSModule.updateData_key(DSModule.DSTypes.DSName.CombinedUserInfo, keyGroup, function(oldValue, dataStoreKeyInfo: DataStoreKeyInfo?)
        -- Validate different
        local oldPlayerInfo = oldValue and oldValue[mapKey]
        if oldPlayerInfo then
            if oldPlayerInfo.rank == newPlayerInfo.rank and oldPlayerInfo.username == newPlayerInfo.username then
                print("[Combined User Info]: Repeated, ignore saving.")
                return nil
            end
        end

        -- Return updated
        local newValue = oldValue or {}
        newValue[mapKey] = newPlayerInfo
        print("[Combined User Info]: New, start saving.")
        return newValue
    end)
end

function Module.updateUserInfoBatched(userInfoList: {{userId: number, playerInfo: PlayerInfo}})
    local keyGroups_isExist = {}
    for _, userInfo in userInfoList do
        keyGroups_isExist[Module.getUserKeyGroup(userInfo.userId)] = true
    end
    for keyGroup, _ in keyGroups_isExist do
        DSModule.updateData_key(DSModule.DSTypes.DSName.CombinedUserInfo, keyGroup, function(oldValue, dataStoreKeyInfo: DataStoreKeyInfo?)
            -- Return updated
            local newValue = oldValue or {}
            for _, userInfo in userInfoList do
                -- Validate matching key group
                if keyGroup ~= Module.getUserKeyGroup(userInfo.userId) then
                    continue
                end

                -- Overwrite
                local mapKey = Module.getUserMapKeyString(userInfo.userId)
                newValue[mapKey] = userInfo.playerInfo
            end
            print(`[Combined User Info]: New batch for '{keyGroup}', start saving.`)
            return newValue
        end)
    end
end

function Module.clearData()
    for i = 1, 64 do
        print(`[Combined User Info]: Clearing data for '{i}'.`)
        local keyGroup = Module.getUserKeyGroup(i)
        DSModule.updateData_key(DSModule.DSTypes.DSName.CombinedUserInfo, keyGroup, function(oldValue, dataStoreKeyInfo: DataStoreKeyInfo?)
            return {}
        end)
    end
end


---------- Return module ----------

table.freeze(Module)
return Module
