local BLUE = 2
local RED = 1

local function randomPick(t, count)
    if #t <= count then
        return t
    end
    local output = {}
    local selected = {}
    for _ = 1, count do
        local i
        repeat
            i = math.random(#t)
        until not selected[i]
        table.insert(output, t[i])
        selected[i] = true
    end
    return output
end

local supplyTargetMenu
EscalationManager.addPlayerSupportItem('supplies', 'Resupply friendly Zone', 500, function()
    if supplyTargetMenu then
        return 'Choose zone to supply from F10 menu'
    end

    supplyTargetMenu = EscalationManager.showZoneTargetingMenu('Select zone to resupply', function(zone)
        if zone.side ~= BLUE then
            return zone.name .. ' is not friendly for supplying'
        end
        if not zone:upgrade() then
            return zone.name .. ' is already max level'
        end
        supplyTargetMenu = nil
    end, BLUE)

    trigger.action.outTextForCoalition(BLUE, 'Supplies are prepared. Choose zone from F10 menu', 10)
end)

local smokeTargetMenu = nil
EscalationManager.addPlayerSupportItem('smoke', 'Smoke markers', 50, function(sender)
    if smokeTargetMenu then
        return 'Choose target zone from F10 menu'
    end

    smokeTargetMenu = EscalationManager.showZoneTargetingMenu('Select smoke marker target', function(zone)
        if zone.side ~= RED then
            return zone.name .. ' is not hostile for deploying smoke marker'
        end

        local groups = zone:getCurrentGroups()
        local units = {}
        for _, groupname in ipairs(groups) do
            local gr = Group.getByName(groupname)
            if gr then
                for _, unit in ipairs(gr:getUnits()) do
                    table.insert(units, unit)
                end
            end
        end

        local targets = randomPick(units, 5)

        for _, unit in ipairs(targets) do
            trigger.action.smoke(unit:getPoint(), trigger.smokeColor.Red)
        end

        trigger.action.outTextForCoalition(BLUE, 'Targets marked with RED smoke at ' .. zone.name, 10)

        smokeTargetMenu = nil
    end, RED)

    trigger.action.outTextForCoalition(BLUE, 'Smoke marker is prepared. Choose zone from F10 menu', 10)
end)

local jtacTargetMenu = nil
EscalationManager.addPlayerSupportItem('jtac', 'Deploy JTAC', 100, function(sender)
    if jtacTargetMenu then
        return 'Choose JTAC target zone from F10 menu'
    end

    jtacTargetMenu = EscalationManager.showZoneTargetingMenu('Select JTAC deployment zone', function(zone)
        if zone.side ~= RED then
            return zone.name .. ' is not hostile for deploying JTAC'
        end
        local jtac = JTAC:new(zone.name)
        jtac:init()
        jtacTargetMenu = nil
    end, RED)

    trigger.action.outTextForCoalition(BLUE, 'JTAC drone is prepared. Choose zone from F10 menu', 10)
end)

local capData = {
    ["coalitionId"] = 2,
    ["country"] = "usa",
    ["units"] = {
        [1] = {
            ["alt"] = 7620,
            ["heading"] = 0,
            ["alt_type"] = "BARO",
            ["skill"] = "High",
            ["type"] = "F-15C",
            ["y"] = 0,
            ["x"] = 0,
            ["payload"] = {
                ["pylons"] = {
                    [1] = {
                        ["CLSID"] = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}"
                    },
                    [2] = {
                        ["CLSID"] = "{E1F29B21-F291-4589-9FD8-3272EEC69506}"
                    },
                    [3] = {
                        ["CLSID"] = "{AIM-9P5}"
                    },
                    [4] = {
                        ["CLSID"] = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}"
                    },
                    [5] = {
                        ["CLSID"] = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}"
                    },
                    [6] = {
                        ["CLSID"] = "{E1F29B21-F291-4589-9FD8-3272EEC69506}"
                    },
                    [7] = {
                        ["CLSID"] = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}"
                    },
                    [8] = {
                        ["CLSID"] = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}"
                    },
                    [9] = {
                        ["CLSID"] = "{AIM-9P5}"
                    },
                    [10] = {
                        ["CLSID"] = "{E1F29B21-F291-4589-9FD8-3272EEC69506}"
                    },
                    [11] = {
                        ["CLSID"] = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}"
                    }
                },
                ["fuel"] = "6103",
                ["flare"] = 60,
                ["chaff"] = 120,
                ["gun"] = 100
            },
            ["speed"] = 257
        },
        [2] = {
            ["alt"] = 7620,
            ["heading"] = 0,
            ["alt_type"] = "BARO",
            ["skill"] = "High",
            ["type"] = "F-15C",
            ["y"] = 40,
            ["x"] = 40,
            ["payload"] = {
                ["pylons"] = {
                    [1] = {
                        ["CLSID"] = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}"
                    },
                    [2] = {
                        ["CLSID"] = "{E1F29B21-F291-4589-9FD8-3272EEC69506}"
                    },
                    [3] = {
                        ["CLSID"] = "{AIM-9P5}"
                    },
                    [4] = {
                        ["CLSID"] = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}"
                    },
                    [5] = {
                        ["CLSID"] = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}"
                    },
                    [6] = {
                        ["CLSID"] = "{E1F29B21-F291-4589-9FD8-3272EEC69506}"
                    },
                    [7] = {
                        ["CLSID"] = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}"
                    },
                    [8] = {
                        ["CLSID"] = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}"
                    },
                    [9] = {
                        ["CLSID"] = "{AIM-9P5}"
                    },
                    [10] = {
                        ["CLSID"] = "{E1F29B21-F291-4589-9FD8-3272EEC69506}"
                    },
                    [11] = {
                        ["CLSID"] = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}"
                    }
                },
                ["fuel"] = "6103",
                ["flare"] = 60,
                ["chaff"] = 120,
                ["gun"] = 100
            },
            ["speed"] = 257
        }
    },
    ["countryId"] = 2,
    ["radioSet"] = false,
    ["hidden"] = false,
    ["category"] = "plane",
    ["coalition"] = "blue",
    ["startTime"] = 0,
    ["task"] = "CAP",
    ["uncontrolled"] = false
}

local capTargetMenu = nil
EscalationManager.addPlayerSupportItem('cap', 'Deploy CAP', 300, function(sender)
    if capTargetMenu then
        return 'Choose CAP target zone from F10 menu'
    end

    capTargetMenu = EscalationManager.showZoneTargetingMenu('Select CAP deployment zone', function(zone)
        if zone.side ~= RED then
            return zone.name .. ' is not hostile to deploy CAP'
        end

        local group = EscalationManager.spawnFriendlyAirAsset(zone, capData)
        if not group then
            return 'Failed to deploy CAP to ' .. zone.name
        end
        local groupname = group:getName()

        timer.scheduleFunction(function()
            local gr = Group.getByName(groupname)
            if not gr then
                return
            end
            local ctr = gr:getController()
            ctr:setTask({
                id = 'EngageTargets',
                params = {
                    targetTypes = {'All'},
                    priority = 0
                }
            })
            ctr:pushTask({
                id = 'Orbit',
                params = {
                    pattern = 'Circle',
                    point = mist.utils.makeVec2(zone.point),
                    speed = 257,
                    altitude = 7620
                }
            })
        end, nil, timer.getTime() + 1)

        trigger.action.outTextForCoalition(BLUE, 'CAP flight is deployed to ' .. zone.name, 10)

        capTargetMenu = nil
    end)

    trigger.action.outTextForCoalition(BLUE, 'CAP flight is prepared. Choose zone from F10 menu', 10)
end)

local seadData = {
    ["coalitionId"] = 2,
    ["country"] = "usa",
    ["units"] = {
        [1] = {
            ["alt"] = 7620,
            ["heading"] = 0,
            ["alt_type"] = "BARO",
            ["skill"] = "High",
            ["type"] = "F-16C_50",
            ["x"] = 0,
            ["y"] = 0,
            ["payload"] = {
                ["pylons"] = {
                    [1] = {
                        ["CLSID"] = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}"
                    },
                    [2] = {
                        ["CLSID"] = "{5CE2FF2A-645A-4197-B48D-8720AC69394F}"
                    },
                    [3] = {
                        ["CLSID"] = "{B06DD79A-F21E-4EB9-BD9D-AB3844618C93}"
                    },
                    [4] = {
                        ["CLSID"] = "{B06DD79A-F21E-4EB9-BD9D-AB3844618C93}"
                    },
                    [5] = {
                        ["CLSID"] = "ALQ_184_Long"
                    },
                    [6] = {
                        ["CLSID"] = "{B06DD79A-F21E-4EB9-BD9D-AB3844618C93}"
                    },
                    [7] = {
                        ["CLSID"] = "{B06DD79A-F21E-4EB9-BD9D-AB3844618C93}"
                    },
                    [8] = {
                        ["CLSID"] = "{5CE2FF2A-645A-4197-B48D-8720AC69394F}"
                    },
                    [9] = {
                        ["CLSID"] = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}"
                    },
                    [10] = {
                        ["CLSID"] = "{AN_ASQ_213}"
                    },
                    [11] = {
                        ["CLSID"] = "{A111396E-D3E8-4b9c-8AC9-2432489304D5}"
                    }
                },
                ["fuel"] = 3249,
                ["flare"] = 60,
                ["ammo_type"] = 5,
                ["chaff"] = 60,
                ["gun"] = 100
            },
            ["speed"] = 257
        },
        [2] = {
            ["alt"] = 7620,
            ["heading"] = 0,
            ["alt_type"] = "BARO",
            ["skill"] = "High",
            ["type"] = "F-16C_50",
            ["x"] = 40,
            ["y"] = 40,
            ["payload"] = {
                ["pylons"] = {
                    [1] = {
                        ["CLSID"] = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}"
                    },
                    [2] = {
                        ["CLSID"] = "{5CE2FF2A-645A-4197-B48D-8720AC69394F}"
                    },
                    [3] = {
                        ["CLSID"] = "{B06DD79A-F21E-4EB9-BD9D-AB3844618C93}"
                    },
                    [4] = {
                        ["CLSID"] = "{B06DD79A-F21E-4EB9-BD9D-AB3844618C93}"
                    },
                    [5] = {
                        ["CLSID"] = "ALQ_184_Long"
                    },
                    [6] = {
                        ["CLSID"] = "{B06DD79A-F21E-4EB9-BD9D-AB3844618C93}"
                    },
                    [7] = {
                        ["CLSID"] = "{B06DD79A-F21E-4EB9-BD9D-AB3844618C93}"
                    },
                    [8] = {
                        ["CLSID"] = "{5CE2FF2A-645A-4197-B48D-8720AC69394F}"
                    },
                    [9] = {
                        ["CLSID"] = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}"
                    },
                    [10] = {
                        ["CLSID"] = "{AN_ASQ_213}"
                    },
                    [11] = {
                        ["CLSID"] = "{A111396E-D3E8-4b9c-8AC9-2432489304D5}"
                    }
                },
                ["fuel"] = 3249,
                ["flare"] = 60,
                ["ammo_type"] = 5,
                ["chaff"] = 60,
                ["gun"] = 100
            },
            ["speed"] = 257
        }
    },
    ["countryId"] = 2,
    ["radioSet"] = false,
    ["hidden"] = false,
    ["category"] = "plane",
    ["coalition"] = "blue",
    ["startTime"] = 0,
    ["task"] = "SEAD",
    ["uncontrolled"] = false
}

local seadTargetMenu = nil
EscalationManager.addPlayerSupportItem('sead', 'Deploy SEAD', 300, function(sender)
    if seadTargetMenu then
        return 'Choose SEAD target zone from F10 menu'
    end

    seadTargetMenu = EscalationManager.showZoneTargetingMenu('Select SEAD deployment zone', function(zone)
        if zone.side ~= RED then
            return zone.name .. ' is not hostile to deploy SEAD'
        end

        local group = EscalationManager.spawnFriendlyAirAsset(zone, seadData)
        if not group then
            return 'Failed to deploy SEAD to ' .. zone.name
        end
        local groupname = group:getName()

        timer.scheduleFunction(function()
            local gr = Group.getByName(groupname)
            if not gr then
                return
            end
            local ctr = gr:getController()
            ctr:setTask({
                id = 'EngageTargetsInZone',
                params = {
                    targetTypes = {'All'},
                    point = mist.utils.makeVec2(zone.point),
                    zoneRadius = zone.radius,
                    priority = 0
                }
            })
            ctr:pushTask({
                id = 'Orbit',
                params = {
                    pattern = 'Circle',
                    point = mist.utils.makeVec2(zone.point),
                    speed = 257,
                    altitude = 7620
                }
            })
        end, nil, timer.getTime() + 1)

        trigger.action.outTextForCoalition(BLUE, 'SEAD flight is deployed to ' .. zone.name, 10)

        seadTargetMenu = nil
    end, RED)

    trigger.action.outTextForCoalition(BLUE, 'SEAD flight is prepared. Choose zone from F10 menu', 10)
end)
