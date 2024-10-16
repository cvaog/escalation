local BLUE = 2
local RED = 1
local MINUTE = 60

local function debugLog(text)
    trigger.action.outText('DEBUG: ' .. tostring(text), 5)
end

local function concat(...)
    local output = {}
    for _, t in ipairs(arg) do
        if t then
            for _, v in ipairs(t) do
                table.insert(output, v)
            end
        end
    end
    return output
end

local function contains(t, i)
    for _, v in ipairs(t) do
        if v == i then
            return true
        end
    end
    return false
end

local function split(inputstr, sep)
    if sep == nil then
        sep = '%s'
    end
    local t = {}
    for str in string.gmatch(inputstr, '([^' .. sep .. ']+)') do
        table.insert(t, str)
    end
    return t
end

local function hasGroupSam(group)
    for _, unit in ipairs(group:getUnits()) do
        if unit.hasAttribute then
            if initiator:hasAttribute('SAM SR') or initiator:hasAttribute('SAM TR') or initiator:hasAttribute('SAM LL') then
                return true
            end
        end
    end
    return false
end

local function getPlayerCount()
    return #coalition.getPlayers(BLUE)
end

local function getBearing(fromvec, tovec)
    local fx = fromvec.x
    local fy = fromvec.z

    local tx = tovec.x
    local ty = tovec.z

    local brg = math.atan2(ty - fy, tx - fx)
    if brg < 0 then
        brg = brg + 2 * math.pi
    end

    brg = brg * 180 / math.pi
    return brg
end

local function getAGL(object)
    local pt = object:getPoint()
    return pt.y - land.getHeight({
        x = pt.x,
        y = pt.z
    })
end

local function isGroupInZone(group, zone)
    for _, unit in ipairs(group:getUnits()) do
        if unit and unit:getLife() >= 1 and not zone:isInside(unit:getPoint()) then
            return false
        end
    end

    return true
end

local function isUnitLanded(unit, ignoreSpeed)
    return not unit:inAir() and (ignoreSpeed or mist.vec.mag(unit:getVelocity()) < 1)
end

local function isGroupLanded(group, ignoreSpeed)
    for _, unit in pairs(group:getUnits()) do
        if unit:getLife() >= 1 and not isUnitLanded(unit, ignoreSpeed) then
            return false
        end
    end

    return true
end

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

local function tableKeep(t, fnKeep)
    local j, n = 1, #t;

    for i = 1, n do
        if (fnKeep(t, i, j)) then
            -- Move i's kept value to j's position, if it's not already there.
            if (i ~= j) then
                t[j] = t[i];
                t[i] = nil;
            end
            j = j + 1; -- Increment position of where we'll place the next kept value.
        else
            t[i] = nil;
        end
    end

    return t;
end

local function saveTable(filename, variablename, data)
    if not io then
        return
    end

    local str = variablename .. ' = ' .. mist.utils.oneLineSerialize(data)

    local file = io.open(filename, 'w')
    file:write(str)
    file:close()
end

local function loadTable(filename)
    if not lfs then
        return
    end

    if lfs.attributes(filename) then
        dofile(filename)
    end
end

local zoneTextBackgroundColor = {0.7, 0.7, 0.7, 0.7}
local neutralZoneTextColor = {0, 0, 0, 0.9}
local neutralZoneAreaColor = {0.7, 0.7, 0.7, 0.3}
local blueZoneTextColor = {0, 0, 1, 0.9}
local blueZoneAreaColor = {0, 0, 1, 0.3}
local redZoneTextColor = {1, 0, 0, 0.9}
local redZoneAreaColor = {1, 0, 0, 0.3}

EscalationManager = {}
do
    EscalationManager.zones = {}
    EscalationManager.zoneIndexTable = {}
    EscalationManager.connections = {}
    EscalationManager.connectionIndexTable = {}
    EscalationManager.activeDispatches = {
        [RED] = {},
        [BLUE] = {}
    }

    function EscalationManager.onEvent(event)
        if event.id == world.event.S_EVENT_BIRTH then
            if event.initiator and event.initiator.getGroup and event.initiator.getPoint and
                event.initiator.getPlayerName and event.initiator.getCoalition and event.initiator.getPoint and
                event.initiator.isExist and event.initiator:isExist() and Object.getCategory(event.initiator) ==
                Object.Category.UNIT and
                (Unit.getCategoryEx(event.initiator) == Unit.Category.AIRPLANE or Unit.getCategoryEx(event.initiator) ==
                    Unit.Category.HELICOPTER) then
                local pname = event.initiator:getPlayerName()
                if pname then
                    local pos = event.initiator:getPoint()
                    local zone = EscalationManager.getZoneByPoint(pos)
                    if zone and zone.side ~= event.initiator:getCoalition() then
                        local gr = event.initiator:getGroup()
                        if gr then
                            trigger.action.outTextForGroup(gr:getID(), 'Can not spawn in enemy/neutral zone', 5)
                            trigger.action.explosion(event.initiator:getPoint(), 5)
                            -- FIXME: crashes server
                            -- event.initiator:destroy()
                            -- for i, v in pairs(net.get_player_list()) do
                            --     if net.get_name(v) == pname then
                            --         net.send_chat_to('Can not spawn as ' .. gr:getName() .. ' in enemy/neutral zone', v)
                            --         net.force_player_slot(v, 0, '')
                            --         break
                            --     end
                            -- end
                        end
                    end
                end
            end
        end
    end

    function EscalationManager.saveFilePath()
        local filepath = 'Escalation_' .. env.mission.theatre .. '_save.lua'
        if lfs then
            local dir = lfs.writedir() .. 'Missions/Saves/'
            lfs.mkdir(dir)
            filepath = dir .. filepath
        end
        return filepath
    end

    function EscalationManager.writeSave()
        local states = {
            zones = {}
        }
        for _, zone in ipairs(EscalationManager.zones) do
            states.zones[zone.name] = {
                side = zone.side,
                level = zone.level,
                deadUnits = zone.deadUnits
            }
        end

        saveTable(EscalationManager.saveFilePath(), 'EscalationPersistance', states)
    end

    function EscalationManager.loadSave()
        loadTable(EscalationManager.saveFilePath())
        if EscalationPersistance then
            if EscalationPersistance.zones then
                for zonename, zonedata in pairs(EscalationPersistance.zones) do
                    local zone = EscalationManager.getZoneByName(zonename)
                    if zone then
                        zone.side = zonedata.side
                        zone.level = zonedata.level
                        zone.deadUnits = zonedata.deadUnits or {}
                    end
                end
            end
        end
    end

    function EscalationManager.load()
        local connections = {}
        local index = RED
        for _, zone in ipairs(env.mission.triggers.zones) do
            local properties
            if zone.properties then
                properties = zone.properties
            else
                properties = {}
            end

            local isZone = false
            for _, property in ipairs(properties) do
                if property.key == 'zone' and property.value == 'true' then
                    isZone = true
                    break
                end
            end

            if isZone then
                local name = zone.name
                local point = {
                    x = zone.x,
                    y = 0,
                    z = zone.y
                }
                local radius = zone.radius

                local vertices = nil
                if zone.type == 2 then
                    vertices = {}
                    for _, v in ipairs(zone.verticies) do
                        local vertex = {
                            x = v.x,
                            y = 0,
                            z = v.y
                        }
                        table.insert(vertices, vertex)
                    end
                end

                local side = 0
                local level = 0
                local income = 0
                local canLoadSupplies = false
                local blueStations = {}
                local blueSams = {}
                local bluePatrols = {}
                local blueSupplies = {}
                local blueAttacks = {}
                local redStations = {}
                local redSams = {}
                local redPatrols = {}
                local redSupplies = {}
                local redAttacks = {}
                for _, property in ipairs(properties) do
                    local key = property.key
                    local value = property.value
                    if key and value then
                        if key == 'side' then
                            side = tonumber(value)
                        elseif key == 'level' then
                            level = tonumber(value)
                        elseif key == 'income' then
                            income = tonumber(value)
                        elseif key == 'connections' then
                            for _, to in ipairs(split(value, ',')) do
                                table.insert(connections, {
                                    from = name,
                                    to = to
                                })
                            end
                        elseif key == 'canLoadSupplies' then
                            canLoadSupplies = value == 'true'
                        elseif key == 'blueStations' then
                            blueStations = split(value, ',')
                        elseif key == 'blueSams' then
                            blueSams = split(value, ',')
                        elseif key == 'bluePatrols' then
                            bluePatrols = split(value, ',')
                        elseif key == 'blueSupplies' then
                            blueSupplies = split(value, ',')
                        elseif key == 'blueAttacks' then
                            blueAttacks = split(value, ',')
                        elseif key == 'redStations' then
                            redStations = split(value, ',')
                        elseif key == 'redSams' then
                            redSams = split(value, ',')
                        elseif key == 'redPatrols' then
                            redPatrols = split(value, ',')
                        elseif key == 'redSupplies' then
                            redSupplies = split(value, ',')
                        elseif key == 'redAttacks' then
                            redAttacks = split(value, ',')
                        end
                    end
                end

                local zone = Zone:new(index, name, point, radius, vertices, {
                    side = side,
                    level = level,
                    income = income,
                    canLoadSupplies = canLoadSupplies,
                    stations = {
                        [RED] = redStations,
                        [BLUE] = blueStations
                    },
                    sams = {
                        [RED] = redSams,
                        [BLUE] = blueSams
                    },
                    patrols = {
                        [RED] = redPatrols,
                        [BLUE] = bluePatrols
                    },
                    supplies = {
                        [RED] = redSupplies,
                        [BLUE] = blueSupplies
                    },
                    attacks = {
                        [RED] = redAttacks,
                        [BLUE] = blueAttacks
                    }
                })

                EscalationManager.addZone(zone)

                index = index + 1
            end
        end

        for _, conn in ipairs(connections) do
            local from = EscalationManager.getZoneByName(conn.from)
            local to = EscalationManager.getZoneByName(conn.to)
            EscalationManager.addZoneConnection(from, to)
        end
    end

    function EscalationManager.addZone(zone)
        table.insert(EscalationManager.zones, zone)
        EscalationManager.zoneIndexTable[zone.name] = zone
    end

    function EscalationManager.getZoneByName(name)
        return EscalationManager.zoneIndexTable[name]
    end

    function EscalationManager.getZoneByPoint(point)
        point.y = 0
        for _, zone in ipairs(EscalationManager.zones) do
            if zone:isInside(point) then
                return zone
            end
        end
        return nil
    end

    function EscalationManager.addZoneConnection(from, to)
        if from.name <= to.name then
            table.insert(EscalationManager.connections, {
                from = from,
                to = to
            })
        else
            table.insert(EscalationManager.connections, {
                from = to,
                to = from
            })
        end
        if EscalationManager.zoneIndexTable[from.name] then
            table.insert(EscalationManager.zoneIndexTable[from.name], to)
        else
            EscalationManager.zoneIndexTable[from.name] = {to}
        end
        if EscalationManager.zoneIndexTable[to.name] then
            table.insert(EscalationManager.zoneIndexTable[to.name], from)
        else
            EscalationManager.zoneIndexTable[to.name] = {from}
        end
    end

    function EscalationManager.init()
        local persistenceEnabled = true
        if not io or not lfs then
            persistenceEnabled = false
            trigger.action.outText('Persistance disabled', 30)
        end

        EscalationManager.load()
        if persistenceEnabled then
            EscalationManager.loadSave()
        end

        LogisticsManager.init()
        HercCargoDropSupply.init()

        for _, zone in ipairs(EscalationManager.zones) do
            zone:init()
        end

        for i, conn in ipairs(EscalationManager.connections) do
            trigger.action.lineToAll(-1, 1000 + i, conn.from.point, conn.to.point, {1, 1, 1, 0.5}, 2)
        end

        local ev = {}
        function ev:onEvent(event)
            EscalationManager.onEvent(event)
        end
        world.addEventHandler(ev)
        timer.scheduleFunction(EscalationManager.spawnBlueDispatches, nil,
            timer.getTime() + math.random(5 * MINUTE, 10 * MINUTE))
        timer.scheduleFunction(EscalationManager.spawnRedDispatches, nil,
            timer.getTime() + math.random(5 * MINUTE, 10 * MINUTE))
        timer.scheduleFunction(function()
            EscalationManager.autoRepair(BLUE)
        end, nil, timer.getTime() + math.random(40 * MINUTE, 80 * MINUTE))
        timer.scheduleFunction(function()
            EscalationManager.autoRepair(RED)
        end, nil, timer.getTime() + math.random(40 * MINUTE, 80 * MINUTE))
        mist.scheduleFunction(EscalationManager.checkDispatches, {}, timer.getTime() + 5, 5)
        mist.scheduleFunction(EscalationManager.knowGroundDispatches, {}, timer.getTime() + 1, 1)
        if persistenceEnabled then
            mist.scheduleFunction(EscalationManager.writeSave, {}, timer.getTime() + 30, 30)
        end
    end

    function EscalationManager.spawnDispatches(side, shouldSpawnCount)
        local activeDispatches = EscalationManager.activeDispatches[side]

        local activeDispatchTable = {}
        for _, group in ipairs(activeDispatches) do
            activeDispatchTable[group.name] = true
        end

        local activeDispatchCount = #activeDispatches
        if activeDispatchCount >= shouldSpawnCount then
            return
        end

        local spawnCount = shouldSpawnCount - activeDispatchCount

        local conflictZones = EscalationManager.getConflictZones()

        local groupPool = {}
        for _, conflictZone in ipairs(EscalationManager.getConflictZones()) do
            if conflictZone.side == side or conflictZone.side == 0 then
                -- possible patrol or supply target

                local suppliable = (conflictZone.side == side and
                                       (conflictZone:isUpgradable() or conflictZone:isDegraded())) or
                                       conflictZone:isCapturable(side)
                for _, originZone in ipairs(EscalationManager.getPossiblePatrolOrSupplySpawnZoneForTargetZone(
                    conflictZone, side)) do
                    for _, groupname in ipairs(originZone.patrols[side]) do
                        if not activeDispatchTable[groupname] then
                            table.insert(groupPool, {
                                name = groupname,
                                type = 'patrol',
                                from = originZone,
                                target = conflictZone
                            })
                        end
                    end

                    if suppliable then
                        for _, groupname in ipairs(originZone.supplies[side]) do
                            if not activeDispatchTable[groupname] then
                                table.insert(groupPool, {
                                    name = groupname,
                                    type = 'supply',
                                    from = originZone,
                                    target = conflictZone
                                })
                            end
                        end
                    end
                end
            else
                -- possible attack target

                for _, originZone in ipairs(
                    EscalationManager.getPossibleAttackSpawnZoneForTargetZone(conflictZone, side)) do
                    for _, groupname in ipairs(originZone.attacks[side]) do
                        if not activeDispatchTable[groupname] then
                            table.insert(groupPool, {
                                name = groupname,
                                type = 'attack',
                                from = originZone,
                                target = conflictZone
                            })
                        end
                    end
                end
            end
        end

        local selectedGroups = randomPick(groupPool, spawnCount)

        for _, group in ipairs(selectedGroups) do
            group.state = 'spawned'
            group.lastStateTime = timer.getAbsTime()
            table.insert(activeDispatches, group)
            mist.respawnGroup(group.name)
            timer.scheduleFunction(function()
                local gr = Group.getByName(group.name)
                if gr then
                    local isGround = gr:getCategory() == Group.Category.GROUND
                    if isGround then
                        if group.type == 'patrol' or group.type == 'attack' then
                            local wp = mist.ground.buildWP(mist.getRandomPointInZone(group.target.name), 'On Road', 20)
                            local patrolRoute = {}
                            table.insert(patrolRoute, mist.ground.buildWP(mist.getRandomPointInZone(group.target.name)))
                            table.insert(patrolRoute, mist.ground.buildWP(mist.getRandomPointInZone(group.target.name)))
                            wp.task = {
                                id = 'WrappedAction',
                                params = {
                                    action = {
                                        id = 'Script',
                                        params = {
                                            command = 'mist.ground.patrolRoute(' .. mist.utils.oneLineSerialize({
                                                gpData = group.name,
                                                route = patrolRoute
                                            }) .. ')'
                                        }
                                    }
                                }
                            }
                            mist.goRoute(gr, {mist.ground.buildWP(mist.getLeadPos(gr), 'On Road', 20), wp})
                        else
                            mist.goRoute(gr, {mist.ground.buildWP(mist.getLeadPos(gr), 'On Road', 20),
                                              mist.ground
                                .buildWP(mist.getRandomPointInZone(group.target.name), 'On Road', 20)})
                        end

                        local awacs = Group.getByName('awacs') or Group.getByName('AWACS')
                        if not awacs then
                            return
                        end
                        local awacsUnit = awacs:getUnit(1)
                        if not awacsUnit then
                            return
                        end
                        local awacsCtr = awacsUnit:getController()
                        if not awacsCtr then
                            return
                        end

                        awacsCtr:knowTarget(gr)
                    else
                        local ctr = gr:getController()
                        ctr:popTask()
                        if group.type == 'patrol' then
                            ctr:pushTask({
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
                                    point = mist.utils.makeVec2(group.target.point),
                                    speed = 257,
                                    altitude = 7620
                                }
                            })
                        elseif group.type == 'supply' then
                            ctr:setTask({
                                id = 'Land',
                                params = {
                                    point = mist.getRandomPointInZone(group.target.name)
                                }
                            })
                        elseif group.type == 'attack' then
                            ctr:pushTask({
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
                                    point = mist.utils.makeVec2(group.target.point),
                                    speed = 154,
                                    altitude = 1219
                                }
                            })
                        end
                    end
                end
            end, nil, timer.getTime() + 1)
        end
    end

    function EscalationManager.spawnBlueDispatches()
        local shouldSpawnCount = math.max(2, 5 - math.floor(getPlayerCount() / 3))
        EscalationManager.spawnDispatches(BLUE, shouldSpawnCount)
        return timer.getTime() + math.random(5 * MINUTE, 10 * MINUTE)
    end

    function EscalationManager.spawnRedDispatches()
        local shouldSpawnCount = math.floor(getPlayerCount() / 3) + 2
        EscalationManager.spawnDispatches(RED, shouldSpawnCount)
        return timer.getTime() + math.random(10 * MINUTE, 20 * MINUTE)
    end

    function EscalationManager.checkDispatches()
        local keepFunc = function(t, i)
            local group = t[i]
            local gr = Group.getByName(group.name)
            if mist.groupIsDead(group.name) or not gr then
                return false
            end
            local isGround = gr:getCategory() == Group.Category.GROUND
            if group.state == 'spawned' then
                if isGround then
                    if not isGroupInZone(gr, group.from) then
                        group.state = 'inmission'
                        group.lastStateTime = timer.getAbsTime()
                    else
                        if timer.getAbsTime() - group.lastStateTime > 10 * MINUTE then
                            gr:destroy()
                            return false
                        end
                    end
                else
                    if not isGroupLanded(gr, true) then
                        group.state = 'inmission'
                        group.lastStateTime = timer.getAbsTime()
                    else
                        if timer.getAbsTime() - group.lastStateTime > 10 * MINUTE then
                            gr:destroy()
                            return false
                        end
                    end
                end
            elseif group.state == 'inmission' then
                if isGround then
                    if group.type == 'supply' then
                        if timer.getAbsTime() - group.lastStateTime > 5 * MINUTE and isGroupInZone(gr, group.target) then
                            group.state = 'landed'
                            group.lastStateTime = timer.getAbsTime()
                        end
                    end
                else
                    if timer.getAbsTime() - group.lastStateTime > 5 * MINUTE and isGroupLanded(gr) then
                        group.state = 'landed'
                        group.lastStateTime = timer.getAbsTime()
                    end
                end
            elseif group.state == 'landed' then
                if timer.getAbsTime() - group.lastStateTime > 2 * MINUTE then
                    if group.type == 'supply' then
                        if isGroupInZone(gr, group.target) then
                            if gr:getCoalition() == group.target.side then
                                group.target:upgrade()
                            elseif group.target.side == 0 then
                                group.target:capture(gr:getCoalition())
                            end
                        end
                    end
                    gr:destroy()
                    return false
                end
            end
            return true
        end

        tableKeep(EscalationManager.activeDispatches[BLUE], keepFunc)
        tableKeep(EscalationManager.activeDispatches[RED], keepFunc)
    end

    function EscalationManager.knowGroundDispatches()
        local awacs = Group.getByName('awacs') or Group.getByName('AWACS')
        if not awacs then
            return
        end
        local awacsUnit = awacs:getUnit(1)
        if not awacsUnit then
            return
        end
        local awacsCtr = awacsUnit:getController()
        if not awacsCtr then
            return
        end

        for _, group in ipairs(EscalationManager.activeDispatches[RED]) do
            local gr = Group.getByName(group.name)
            if gr then
                if gr:getCategory() == Group.Category.GROUND then
                    for _, un in ipairs(gr:getUnits()) do
                        awacsCtr:knowTarget(un)
                    end
                end
            end
        end
    end

    function EscalationManager.autoRepair(side)
        local repairableZones = {}
        for _, zone in ipairs(EscalationManager.zones) do
            if zone.side == side and not zone:isConflicting() and zone:isSamDegraded() then
                table.insert(repairableZones, zone)
            end
        end

        if #repairableZones > 0 then
            local zone = repairableZones[math.random(#repairableZones)]
            if zone:trySamRepair() then
                trigger.action.outText(zone.name .. ' is repaired', 20)
            end
        end

        return timer.getTime() + math.random(40 * MINUTE, 80 * MINUTE)
    end

    function EscalationManager.getConnectedZones(zone)
        return EscalationManager.zoneIndexTable[zone.name]
    end

    function EscalationManager.getConflictZones()
        local output = {}
        for _, zone in ipairs(EscalationManager.zones) do
            if zone:isConflicting() then
                table.insert(output, zone)
            end
        end
        return output
    end

    function EscalationManager.getPossiblePatrolOrSupplySpawnZoneForTargetZone(zone, bySide)
        local output = {}
        for _, connzone in ipairs(EscalationManager.getConnectedZones(zone)) do
            if (zone.side == 0 or connzone.side == zone.side) and connzone.side == bySide then
                table.insert(output, connzone)
            end
        end
        return output
    end

    function EscalationManager.getPossibleAttackSpawnZoneForTargetZone(zone, bySide)
        local output = {}
        local outputTable = {}
        for _, connzone in ipairs(EscalationManager.getConnectedZones(zone)) do
            if connzone.side == bySide then
                for _, connzone2 in ipairs(EscalationManager.getConnectedZones(connzone)) do
                    if connzone2.side == bySide and not outputTable[connzone2.name] then
                        table.insert(output, connzone2)
                        outputTable[connzone2.name] = true
                    end
                end
            end
        end
        return output
    end
end

Zone = {}
do
    Zone.index = 0
    Zone.name = ''
    Zone.point = {
        x = 0,
        y = 0,
        z = 0
    }
    Zone.radius = 0
    Zone.vertices = nil
    Zone.side = 0
    Zone.level = 0
    Zone.income = 0
    Zone.stations = {
        [RED] = {},
        [BLUE] = {}
    }
    Zone.sams = {
        [RED] = {},
        [BLUE] = {}
    }
    Zone.patrols = {
        [RED] = {},
        [BLUE] = {}
    }
    Zone.supplies = {
        [RED] = {},
        [BLUE] = {}
    }
    Zone.attacks = {
        [RED] = {},
        [BLUE] = {}
    }
    Zone.income = 0
    Zone.deadUnits = {}

    function Zone:new(index, name, point, radius, vertices, props)
        local obj = props or {}
        obj.index = index
        obj.name = name
        obj.point = point
        obj.radius = radius
        obj.vertices = vertices
        if not obj.side then
            obj.side = 0
        end
        if not obj.level then
            obj.level = 0
        end
        if not obj.income then
            obj.income = 0
        end
        if obj.canLoadSupplies == nil then
            obj.canLoadSupplies = false
        end
        if not obj.stations then
            obj.stations = {
                [RED] = {},
                [BLUE] = {}
            }
        else
            if not obj.stations[RED] then
                obj.stations[RED] = {}
            end
            if not obj.stations[BLUE] then
                obj.stations[BLUE] = {}
            end
        end
        if not obj.sams then
            obj.sams = {
                [RED] = {},
                [BLUE] = {}
            }
        else
            if not obj.sams[RED] then
                obj.sams[RED] = {}
            end
            if not obj.sams[BLUE] then
                obj.sams[BLUE] = {}
            end
        end
        if not obj.patrols then
            obj.patrols = {
                [RED] = {},
                [BLUE] = {}
            }
        else
            if not obj.patrols[RED] then
                obj.patrols[RED] = {}
            end
            if not obj.patrols[BLUE] then
                obj.patrols[BLUE] = {}
            end
        end
        if not obj.supplies then
            obj.supplies = {
                [RED] = {},
                [BLUE] = {}
            }
        else
            if not obj.supplies[RED] then
                obj.supplies[RED] = {}
            end
            if not obj.supplies[BLUE] then
                obj.supplies[BLUE] = {}
            end
        end
        if not obj.attacks then
            obj.attacks = {
                [RED] = {},
                [BLUE] = {}
            }
        else
            if not obj.attacks[RED] then
                obj.attacks[RED] = {}
            end
            if not obj.attacks[BLUE] then
                obj.attacks[BLUE] = {}
            end
        end
        if not obj.deadUnits then
            obj.deadUnits = {}
        end
        setmetatable(obj, self)
        self.__index = self
        return obj
    end

    function Zone:init()
        local zoneAreaColor = neutralZoneAreaColor
        local zoneTextColor = neutralZoneTextColor
        if self.side == RED then
            zoneAreaColor = redZoneAreaColor
            zoneTextColor = redZoneTextColor
        elseif self.side == BLUE then
            zoneAreaColor = blueZoneAreaColor
            zoneTextColor = blueZoneTextColor
        end

        if self.vertices then
            trigger.action.quadToAll(-1, self.index, self.vertices[4], self.vertices[3], self.vertices[2],
                self.vertices[1], zoneAreaColor, zoneAreaColor, 1)
        else
            trigger.action.circleToAll(-1, self.index, self.point, self.radius, zoneAreaColor, zoneAreaColor, 1)
        end
        trigger.action
            .textToAll(-1, 2000 + self.index, self.point, zoneTextColor, zoneTextBackgroundColor, 20, true, '')
        trigger.action.setMarkupText(2000 + self.index, self.name)

        for _, groupname in ipairs(concat(self.sams[BLUE], self.sams[RED], self.stations[BLUE], self.stations[RED],
            self.patrols[BLUE], self.patrols[RED], self.attacks[BLUE], self.attacks[RED], self.supplies[BLUE],
            self.supplies[RED])) do
            local gr = Group.getByName(groupname)
            if gr then
                gr:destroy()
            end
        end
        timer.scheduleFunction(function()
            self:checkAndSpawnGroups()
        end, nil, timer.getTime() + 1)

        mist.scheduleFunction(self.checkDeadUnits, {self}, timer.getTime() + 10, 10)
    end

    function Zone:updateColor()
        local zoneAreaColor = neutralZoneAreaColor
        local zoneTextColor = neutralZoneTextColor
        if self.side == RED then
            zoneAreaColor = redZoneAreaColor
            zoneTextColor = redZoneTextColor
        elseif self.side == BLUE then
            zoneAreaColor = blueZoneAreaColor
            zoneTextColor = blueZoneTextColor
        end

        trigger.action.setMarkupColorFill(self.index, zoneAreaColor)
        trigger.action.setMarkupColor(self.index, zoneAreaColor)
        trigger.action.setMarkupColorFill(2000 + self.index, zoneTextBackgroundColor)
        trigger.action.setMarkupColor(2000 + self.index, zoneTextColor)
    end

    function Zone:checkAndSpawnGroups()
        local isConflicting = self:isConflicting()
        for _, groupname in ipairs(self.sams[self.side] or {}) do
            local deadUnits = self.deadUnits[groupname]
            if not isConflicting and deadUnits ~= true then
                if mist.groupIsDead(groupname) then
                    mist.respawnInZone(groupname, self.name, true)
                    if deadUnits and #deadUnits > 0 then
                        local deadIndex = {}
                        for _, name in ipairs(deadUnits) do
                            deadIndex[name] = true
                        end
                        timer.scheduleFunction(function()
                            local gr = Group.getByName(groupname)
                            if gr then
                                for _, unit in ipairs(gr:getUnits()) do
                                    if deadIndex[unit:getName()] then
                                        unit:destroy()
                                    end
                                end
                            end
                        end, nil, timer.getTime() + 1)
                    end
                end
            else
                if not mist.groupIsDead(groupname) then
                    Group.getByName(groupname):destroy()
                end
            end
        end
        for i, groupname in ipairs(self.stations[self.side] or {}) do
            local deadUnits = self.deadUnits[groupname]
            if isConflicting and i <= self.level and deadUnits ~= true then
                if mist.groupIsDead(groupname) then
                    mist.respawnInZone(groupname, self.name, true)
                    if deadUnits and #deadUnits > 0 then
                        local deadIndex = {}
                        for _, name in ipairs(deadUnits) do
                            deadIndex[name] = true
                        end
                        timer.scheduleFunction(function()
                            local gr = Group.getByName(groupname)
                            if gr then
                                for _, unit in ipairs(gr:getUnits()) do
                                    if deadIndex[unit:getName()] then
                                        unit:destroy()
                                    end
                                end
                            end
                        end, nil, timer.getTime() + 1)
                    end
                end
            else
                if not mist.groupIsDead(groupname) then
                    Group.getByName(groupname):destroy()
                end
            end
        end
    end

    function Zone:isConflicting()
        local otherZones = EscalationManager.getConnectedZones(self)
        for _, otherZone in ipairs(otherZones) do
            if otherZone.side ~= self.side then
                return true
            end
        end
        return false
    end

    function Zone:isInside(point)
        if self.vertices then
            return mist.pointInPolygon(point, self.vertices)
        else
            local dist = mist.utils.get2DDist(point, self.point)
            return dist < self.radius
        end
    end

    function Zone:isUpgradable()
        local stations = self.stations[self.side] or {}
        return self.level < #stations
    end

    function Zone:isDegraded()
        local stations = self.stations[self.side] or {}

        if self.level < #stations then
            return true
        end

        for i, groupname in ipairs(stations) do
            if i <= self.level then
                local group = Group.getByName(groupname)
                if mist.groupIsDead(groupname) or not group or group:getSize() < group:getInitialSize() then
                    return true
                end
            end
        end

        return false
    end

    function Zone:isSamDegraded()
        for _, groupname in ipairs(self.sams[self.side] or {}) do
            local group = Group.getByName(groupname)
            if mist.groupIsDead(groupname) or not group or group:getSize() < group:getInitialSize() then
                return true
            end
        end

        return false
    end

    function Zone:tryRepair()
        for i, groupname in ipairs(self.stations[self.side] or {}) do
            if i <= self.level then
                local group = Group.getByName(groupname)
                if mist.groupIsDead(groupname) or not group or group:getSize() < group:getInitialSize() then
                    mist.respawnInZone(groupname, self.name, true)
                    self.deadUnits[groupname] = {}
                    return true
                end
            end
        end

        return false
    end

    function Zone:trySamRepair()
        for i, groupname in ipairs(self.sams[self.side] or {}) do
            local group = Group.getByName(groupname)
            if mist.groupIsDead(groupname) or not group or group:getSize() < group:getInitialSize() then
                mist.respawnInZone(groupname, self.name, true)
                self.deadUnits[groupname] = {}
                return true
            end
        end

        return false
    end

    function Zone:upgrade()
        if self:tryRepair() then
            trigger.action.outText(self.name .. ' is repaired', 20)
        else
            local newLevel = math.min(self.level + 1, #self.stations[self.side])
            if newLevel > self.level then
                self.deadUnits = {}
                self.level = newLevel
                self:checkAndSpawnGroups()

                trigger.action.outText(self.name .. ' is upgraded', 20)

                EscalationManager.writeSave()
            end
        end
    end

    function Zone:isCapturable(bySide)
        if self.side == 0 then
            local otherZones = EscalationManager.getConnectedZones(self)
            for _, otherZone in ipairs(otherZones) do
                if otherZone.side == bySide then
                    return true
                end
            end
        end
        return false
    end

    function Zone:capture(bySide)
        if self:isCapturable(bySide) then
            local connectedZones = EscalationManager.getConnectedZones(self)
            local indexTable = {}

            for _, zone in ipairs(connectedZones) do
                indexTable[zone.name] = zone:isConflicting()
            end

            self.level = 1
            self.side = bySide
            self.deadUnits = {}

            self:checkAndSpawnGroups()

            self:updateColor()

            trigger.action.outText(self.name .. ' is captured', 20)

            for _, zone in ipairs(connectedZones) do
                if indexTable[zone.name] ~= zone:isConflicting() then
                    zone:checkAndSpawnGroups()
                end
            end

            EscalationManager.writeSave()
        end
    end

    function Zone:checkDeadUnits()
        if self.side == 0 then
            return
        end

        if not self:isConflicting() then
            for _, groupname in ipairs(self.sams[self.side] or {}) do
                local gr = Group.getByName(groupname)
                if not gr or mist.groupIsDead(groupname) then
                    self.deadUnits[groupname] = true
                else
                    self.deadUnits[groupname] = {}
                    if gr:getSize() < gr:getInitialSize() then
                        local aliveTable = {}
                        for _, unit in ipairs(gr:getUnits()) do
                            aliveTable[unit:getName()] = true
                        end
                        for _, unit in pairs(mist.getGroupData(groupname).units) do
                            local name = unit.unitName
                            if not aliveTable[name] then
                                table.insert(self.deadUnits[groupname], name)
                            end
                        end
                    end
                end
            end

            return
        end

        local stations = self.stations[self.side] or {}

        local lastLevel = #stations
        for i = #stations, 1, -1 do
            local groupname = stations[i]
            local gr = Group.getByName(groupname)
            if not gr or mist.groupIsDead(groupname) then
                lastLevel = i - 1
                self.deadUnits[groupname] = true
            else
                self.deadUnits[groupname] = {}
                if gr:getSize() < gr:getInitialSize() then
                    local aliveTable = {}
                    for _, unit in ipairs(gr:getUnits()) do
                        aliveTable[unit:getName()] = true
                    end
                    for _, unit in pairs(mist.getGroupData(groupname).units) do
                        local name = unit.unitName
                        if not aliveTable[name] then
                            table.insert(self.deadUnits[groupname], name)
                        end
                    end
                end
            end
        end

        self.level = lastLevel
        if self.level > 0 then
            return
        end

        local connectedZones = EscalationManager.getConnectedZones(self)
        local indexTable = {}

        for _, zone in ipairs(connectedZones) do
            indexTable[zone.name] = zone:isConflicting()
        end

        self.side = 0
        self.deadUnits = {}

        self:updateColor()

        trigger.action.outText(self.name .. ' is neutralized', 5)

        for _, zone in ipairs(connectedZones) do
            if indexTable[zone.name] ~= zone:isConflicting() then
                zone:checkAndSpawnGroups()
            end
        end

        return
    end
end

LogisticsManager = {}
do
    LogisticsManager.allowedTypes = {}
    LogisticsManager.allowedTypes['Mi-24P'] = true
    LogisticsManager.allowedTypes['UH-1H'] = true
    LogisticsManager.allowedTypes['Mi-8MT'] = true
    LogisticsManager.allowedTypes['CH-47Fbl1'] = true
    LogisticsManager.allowedTypes['Hercules'] = true
    LogisticsManager.allowedTypes['UH-60L'] = true

    LogisticsManager.groupMenus = {} -- groupid = path
    LogisticsManager.carriedCargo = {} -- groupid = source
    LogisticsManager.ejectedPilots = {}
    LogisticsManager.carriedPilots = {} -- groupid = count

    LogisticsManager.maxCarriedPilots = 4

    function LogisticsManager.loadSupplies(groupName)
        local gr = Group.getByName(groupName)
        if gr then
            local un = gr:getUnit(1)
            if un then
                if not isUnitLanded(un, false) then
                    trigger.action.outTextForGroup(gr:getID(), 'Can not load supplies while in air', 10)
                    return
                end

                local zn = EscalationManager.getZoneByPoint(un:getPoint())
                if zn then
                    if zn.side ~= un:getCoalition() or not zn.canLoadSupplies then
                        trigger.action.outTextForGroup(gr:getID(),
                            'Can only load supplies while within a friendly supply zone', 10)
                        return
                    end

                    if LogisticsManager.carriedCargo[gr:getID()] then
                        trigger.action.outTextForGroup(gr:getID(), 'Supplies already loaded', 10)
                        return
                    end

                    LogisticsManager.carriedCargo[gr:getID()] = zn.name
                    trigger.action.setUnitInternalCargo(un:getName(), 800)
                    trigger.action.outTextForGroup(gr:getID(), 'Supplies loaded', 10)
                end
            end
        end
    end

    function LogisticsManager.unloadSupplies(groupName)
        local gr = Group.getByName(groupName)
        if gr then
            local un = gr:getUnit(1)
            if un then
                if not isUnitLanded(un, false) then
                    trigger.action.outTextForGroup(gr:getID(), 'Can not unload supplies while in air', 10)
                    return
                end

                local zn = EscalationManager.getZoneByPoint(un:getPoint())
                if zn then
                    if not (zn.side == un:getCoalition() or zn.side == 0) then
                        trigger.action.outTextForGroup(gr:getID(),
                            'Can only unload supplies while within a friendly or neutral zone', 10)
                        return
                    end

                    if not LogisticsManager.carriedCargo[gr:getID()] then
                        trigger.action.outTextForGroup(gr:getID(), 'No supplies loaded', 10)
                        return
                    end

                    trigger.action.outTextForGroup(gr:getID(), 'Supplies unloaded', 10)
                    if LogisticsManager.carriedCargo[gr:getID()] ~= zn.name then
                        if zn.side == 0 then
                            -- TODO: add credits

                            zn:capture(un:getCoalition())
                        elseif zn.side == un:getCoalition() then
                            -- TODO: add credits

                            zn:upgrade()
                        end
                    end

                    LogisticsManager.carriedCargo[gr:getID()] = nil
                    trigger.action.setUnitInternalCargo(un:getName(), 0)
                end
            end
        end
    end

    function LogisticsManager.loadPilot(groupname)
        local gr = Group.getByName(groupname)
        local groupid = gr:getID()
        if gr then
            local un = gr:getUnit(1)
            if getAGL(un) > 50 then
                trigger.action.outTextForGroup(groupid, 'You are too high', 15)
                return
            end

            if mist.vec.mag(un:getVelocity()) > 5 then
                trigger.action.outTextForGroup(groupid, 'You are moving too fast', 15)
                return
            end

            if LogisticsManager.carriedPilots[groupid] >= LogisticsManager.maxCarriedPilots then
                trigger.action.outTextForGroup(groupid, 'At max capacity', 15)
                return
            end

            for i, v in ipairs(LogisticsManager.ejectedPilots) do
                local dist = mist.utils.get3DDist(un:getPoint(), v:getPoint())
                if dist < 150 then
                    LogisticsManager.carriedPilots[groupid] = LogisticsManager.carriedPilots[groupid] + 1
                    table.remove(LogisticsManager.ejectedPilots, i)
                    v:destroy()
                    trigger.action.outTextForGroup(groupid,
                        'Pilot onboard [' .. LogisticsManager.carriedPilots[groupid] .. '/' ..
                            LogisticsManager.maxCarriedPilots .. ']', 15)
                    return
                end
            end

            trigger.action.outTextForGroup(groupid, 'No ejected pilots nearby', 15)
        end
    end

    function LogisticsManager.unloadPilot(groupname)
        local gr = Group.getByName(groupname)
        local groupid = gr:getID()
        if gr then
            local un = gr:getUnit(1)

            if LogisticsManager.carriedPilots[groupid] == 0 then
                trigger.action.outTextForGroup(groupid, 'No one onboard', 15)
                return
            end

            if not isUnitLanded(un) then
                trigger.action.outTextForGroup(groupid, 'Can not drop off pilots while in air', 15)
                return
            end

            local zn = EscalationManager.getZoneByPoint(un:getPoint())
            if zn and zn.side == gr:getCoalition() then
                local count = LogisticsManager.carriedPilots[groupid]
                trigger.action.outTextForGroup(groupid, 'Pilots dropped off', 15)

                -- TODO: add credit

                LogisticsManager.carriedPilots[groupid] = 0

                return
            end

            trigger.action.outTextForGroup(groupid, 'Can only drop off pilots in a friendly zone', 15)
        end
    end

    function LogisticsManager.markPilot(groupname)
        local gr = Group.getByName(groupname)
        if gr then
            local un = gr:getUnit(1)

            local maxdist = 300000
            local targetpilot = nil
            for i, v in ipairs(LogisticsManager.ejectedPilots) do
                local dist = mist.utils.get3DDist(un:getPoint(), v:getPoint())
                if dist < maxdist then
                    maxdist = dist
                    targetpilot = v
                end
            end

            if targetpilot then
                trigger.action.smoke(targetpilot:getPoint(), 4)
                trigger.action.outTextForGroup(gr:getID(), 'Ejected pilot has been marked with blue smoke', 15)
            else
                trigger.action.outTextForGroup(gr:getID(), 'No ejected pilots nearby', 15)
            end
        end
    end

    function LogisticsManager.flarePilot(groupname)
        local gr = Group.getByName(groupname)
        if gr then
            local un = gr:getUnit(1)

            local maxdist = 300000
            local targetpilot = nil
            for i, v in ipairs(LogisticsManager.ejectedPilots) do
                local dist = mist.utils.get3DDist(un:getPoint(), v:getPoint())
                if dist < maxdist then
                    maxdist = dist
                    targetpilot = v
                end
            end

            if targetpilot then
                trigger.action.signalFlare(targetpilot:getPoint(), 0, math.floor(math.random(0, 359)))
            else
                trigger.action.outTextForGroup(gr:getID(), 'No ejected pilots nearby', 15)
            end
        end
    end

    function LogisticsManager.infoPilot(groupname)
        local gr = Group.getByName(groupname)
        if gr then
            local un = gr:getUnit(1)

            local maxdist = 300000
            local targetpilot = nil
            for i, v in ipairs(LogisticsManager.ejectedPilots) do
                local dist = mist.utils.get3DDist(un:getPoint(), v:getPoint())
                if dist < maxdist then
                    maxdist = dist
                    targetpilot = v
                end
            end

            if targetpilot then
                LogisticsManager.printPilotInfo(targetpilot, gr:getID(), un, 60)
            else
                trigger.action.outTextForGroup(gr:getID(), 'No ejected pilots nearby', 15)
            end
        end
    end

    function LogisticsManager.printPilotInfo(pilotObj, groupid, referenceUnit, duration)
        local pnt = pilotObj:getPoint()
        local toprint = 'Pilot in need of extraction:'

        local lat, lon, alt = coord.LOtoLL(pnt)
        local mgrs = coord.LLtoMGRS(coord.LOtoLL(pnt))
        toprint = toprint .. '\nDDM:  ' .. mist.tostringLL(lat, lon, 3)
        toprint = toprint .. '\nDMS:  ' .. mist.tostringLL(lat, lon, 2, true)
        toprint = toprint .. '\nMGRS: ' .. mist.tostringMGRS(mgrs, 5)
        toprint = toprint .. '\n\nAlt: ' .. math.floor(alt) .. 'm' .. ' | ' .. math.floor(alt * 3.280839895) .. 'ft'

        if referenceUnit then
            local dist = mist.utils.get3DDist(referenceUnit:getPoint(), pilotObj:getPoint())
            local dstkm = string.format('%.2f', dist / 1000)
            local dstnm = string.format('%.2f', dist / 1852)
            toprint = toprint .. '\n\nDist: ' .. dstkm .. 'km' .. ' | ' .. dstnm .. 'nm'

            local brg = getBearing(referenceUnit:getPoint(), pnt)
            toprint = toprint .. '\nBearing: ' .. math.floor(brg)
        end

        trigger.action.outTextForGroup(groupid, toprint, duration)
    end

    function LogisticsManager.onEvent(event)
        if event.id == world.event.S_EVENT_BIRTH then
            if event.initiator and event.initiator.getPlayerName and event.initiator.isExist and
                event.initiator:isExist() then
                local player = event.initiator:getPlayerName()
                if player then
                    local unitType = event.initiator:getDesc()['typeName']
                    local groupid = event.initiator:getGroup():getID()
                    local groupname = event.initiator:getGroup():getName()

                    if LogisticsManager.allowedTypes[unitType] then
                        LogisticsManager.carriedPilots[groupid] = 0
                        LogisticsManager.carriedCargo[groupid] = nil

                        if not LogisticsManager.groupMenus[groupid] then
                            local cargomenu = missionCommands.addSubMenuForGroup(groupid, 'Logistics')
                            missionCommands.addCommandForGroup(groupid, 'Load supplies', cargomenu,
                                LogisticsManager.loadSupplies, groupname)
                            missionCommands.addCommandForGroup(groupid, 'Unload supplies', cargomenu,
                                LogisticsManager.unloadSupplies, groupname)

                            local csar = missionCommands.addSubMenuForGroup(groupid, 'CSAR', cargomenu)
                            missionCommands.addCommandForGroup(groupid, 'Pick up pilot', csar,
                                LogisticsManager.loadPilot, groupname)
                            missionCommands.addCommandForGroup(groupid, 'Drop off pilot', csar,
                                LogisticsManager.unloadPilot, groupname)
                            missionCommands.addCommandForGroup(groupid, 'Info on closest pilot', csar,
                                LogisticsManager.infoPilot, groupname)
                            missionCommands.addCommandForGroup(groupid, 'Deploy smoke at closest pilot', csar,
                                LogisticsManager.markPilot, groupname)
                            missionCommands.addCommandForGroup(groupid, 'Deploy flare at closest pilot', csar,
                                LogisticsManager.flarePilot, groupname)

                            LogisticsManager.groupMenus[groupid] = cargomenu
                        end
                    end
                end
            end
        elseif event.id == world.event.S_EVENT_LANDING_AFTER_EJECTION then
            table.insert(LogisticsManager.ejectedPilots, event.initiator)

            for i, v in pairs(LogisticsManager.groupMenus) do
                LogisticsManager.printPilotInfo(event.initiator, i, nil, 15)
            end
        end
    end

    function LogisticsManager.init()
        local ev = {}
        function ev:onEvent(event)
            LogisticsManager.onEvent(event)
        end
        world.addEventHandler(ev)
    end
end

HercCargoDropSupply = {}
do
    HercCargoDropSupply.allowedCargo = {}
    HercCargoDropSupply.allowedCargo['weapons.bombs.Generic Crate [20000lb]'] = true
    HercCargoDropSupply.herculesRegistry = {} -- {takeoffzone = string, lastlanded = time}

    function HercCargoDropSupply.onEvent(event)
        if event.id == world.event.S_EVENT_SHOT then
            local name = event.weapon:getDesc().typeName
            if HercCargoDropSupply.allowedCargo[name] then
                local alt = getAGL(event.weapon)
                if alt < 5 then
                    HercCargoDropSupply.ProcessCargo(event)
                else
                    timer.scheduleFunction(HercCargoDropSupply.CheckCargo, event, timer.getTime() + 1)
                end
            end
        end

        if event.id == world.event.S_EVENT_TAKEOFF then
            if event.initiator and event.initiator:getDesc().typeName == 'Hercules' then
                local herc = HercCargoDropSupply.herculesRegistry[event.initiator:getName()]

                local zn = EscalationManager.getZoneByPoint(event.initiator:getPoint())
                if zn then
                    if not herc then
                        HercCargoDropSupply.herculesRegistry[event.initiator:getName()] = {
                            takeoffzone = zn.name
                        }
                    elseif not herc.lastlanded or (herc.lastlanded + 30) < timer.getTime() then
                        HercCargoDropSupply.herculesRegistry[event.initiator:getName()].takeoffzone = zn.name
                    end

                end
            end
        end

        if event.id == world.event.S_EVENT_LAND then
            if event.initiator and event.initiator:getDesc().typeName == 'Hercules' then
                local herc = HercCargoDropSupply.herculesRegistry[event.initiator:getName()]

                if not herc then
                    HercCargoDropSupply.herculesRegistry[event.initiator:getName()] = {}
                end

                HercCargoDropSupply.herculesRegistry[event.initiator:getName()].lastlanded = timer.getTime()
            end
        end
    end

    function HercCargoDropSupply.init()
        local ev = {}
        function ev:onEvent(event)
            HercCargoDropSupply.onEvent(event)
        end
        world.addEventHandler(ev)
    end

    function HercCargoDropSupply.ProcessCargo(shotevent)
        local cargo = shotevent.weapon
        local zn = EscalationManager.getZoneByPoint(cargo:getPoint())
        if zn and shotevent.initiator and shotevent.initiator:isExist() then
            local herc = HercCargoDropSupply.herculesRegistry[shotevent.initiator:getName()]
            if not herc or herc.takeoffzone == zn.name then
                cargo:destroy()
                return
            end

            local cargoSide = cargo:getCoalition()
            if zn.side == 0 then
                -- TODO: add credits

                zn:capture(cargoSide)
            elseif zn.side == cargoSide then
                -- TODO: add credits

                zn:upgrade()
            end

            cargo:destroy()
        end
    end

    function HercCargoDropSupply.CheckCargo(shotevent, time)
        local cargo = shotevent.weapon
        if not cargo:isExist() then
            return nil
        end

        local alt = getAGL(cargo)
        if alt < 5 then
            HercCargoDropSupply.ProcessCargo(shotevent)
            return nil
        end
        return time + 1
    end
end

EscalationManager.init()
