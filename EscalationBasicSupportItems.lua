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
        return 'Choose zone from F10 menu'
    end

    supplyTargetMenu = EscalationManager.showZoneTargetingMenu('Select zone to resupply', function(zone)
        if zone.side == BLUE then
            if not zone:upgrade() then
                return zone.name .. ' is already max level'
            end
        else
            return zone.name .. ' is not friendly'
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
        if zone.side == RED then
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
        else
            return zone.name .. ' is not hostile'
        end
        smokeTargetMenu = nil
    end, RED)

    trigger.action.outTextForCoalition(BLUE, 'Smoke marker is prepared. Choose zone from F10 menu', 10)
end)

local jtacTargetMenu = nil
EscalationManager.addPlayerSupportItem('jtac', 'Deploy JTAC', 100, function(sender)
    if jtacTargetMenu then
        return 'Choose target zone from F10 menu'
    end

    jtacTargetMenu = EscalationManager.showZoneTargetingMenu('Select JTAC deployment zone', function(zone)
        if zone.side == RED then
            local jtac = JTAC:new(zone.name)
            jtac:init()
        else
            return zone.name .. ' is not hostile'
        end
        jtacTargetMenu = nil
    end, RED)

    trigger.action.outTextForCoalition(BLUE, 'JTAC drone is prepared. Choose zone from F10 menu', 10)
end)

EscalationManager.refreshPlayerSupportItemsMenu()
