----[[ ##### SCRIPT CONFIGURATION ##### ]]----
local splashDamageOptions = {
    ['staticDamageBoost'] = 2000, -- apply extra damage to Unit.Category.STRUCTUREs with wave explosions
    ['waveExplosions'] = true, -- secondary explosions on top of game objects, radiating outward from the impact point and scaled based on size of object and distance from weapon impact point
    ['blastSearchRadius'] = 100, -- this is the max size of any blast wave radius, since we will only find objects within this zone
    ['cascadeDamageThreshold'] = 0.1, -- if the calculated blast damage doesn't exeed this value, there will be no secondary explosion damage on the unit.  If this value is too small, the appearance of explosions far outside of an expected radius looks incorrect.
    ['rocketMultiplier'] = 1.3 -- multiplied by the explTable value for rockets
}

local refreshRate = 1

local explTable = {
    ['FAB_100'] = 45,
    ['FAB_250'] = 100,
    ['FAB_250M54TU'] = 100,
    ['FAB_500'] = 213,
    ['FAB_1500'] = 675,
    ['BetAB_500'] = 98,
    ['BetAB_500ShP'] = 107,
    ['KH-66_Grom'] = 108,
    ['M_117'] = 201,
    ['Mk_81'] = 60,
    ['Mk_82'] = 118,
    ['AN_M64'] = 121,
    ['Mk_83'] = 274,
    ['Mk_84'] = 582,
    ['MK_82AIR'] = 118,
    ['MK_82SNAKEYE'] = 118,
    ['GBU_10'] = 582,
    ['GBU_12'] = 118,
    ['GBU_16'] = 274,
    ['KAB_1500Kr'] = 675,
    ['KAB_500Kr'] = 213,
    ['KAB_500'] = 213,
    ['GBU_31'] = 582,
    ['GBU_31_V_3B'] = 582,
    ['GBU_31_V_2B'] = 582,
    ['GBU_31_V_4B'] = 582,
    ['GBU_32_V_2B'] = 202,
    ['GBU_38'] = 118,
    ['AGM_62'] = 400,
    ['GBU_24'] = 582,
    ['X_23'] = 111,
    ['X_23L'] = 111,
    ['X_28'] = 160,
    ['X_25ML'] = 89,
    ['X_25MP'] = 89,
    ['X_25MR'] = 140,
    ['X_58'] = 140,
    ['X_29L'] = 320,
    ['X_29T'] = 320,
    ['X_29TE'] = 320,
    ['AGM_84E'] = 488,
    ['AGM_88C'] = 89,
    ['AGM_88'] = 89,
    ['AGM_84S'] = 500,
    ['AGM_122'] = 15,
    ['AGM_123'] = 274,
    ['AGM_130'] = 582,
    ['AGM_119'] = 176,
    ['AGM_154C'] = 305,
    ['AGM_154'] = 305,
    ['S-24A'] = 24,
    ['S-24B'] = 123,
    ['S-25OF'] = 194,
    ['S-25OFM'] = 150,
    ['S-25O'] = 150,
    ['S_25L'] = 190,
    ['S-5M'] = 1,
    ['C_8'] = 4,
    ['C_8OFP2'] = 3,
    ['C_13'] = 21,
    ['C_24'] = 123,
    ['C_25'] = 151,
    ['HYDRA_70M15'] = 3,
    ['Zuni_127'] = 5,
    ['ARAKM70BHE'] = 4,
    ['BR_500'] = 118,
    ['Rb 05A'] = 217,
    ['RBK_500AO'] = 256,
    ['RBK_250'] = 128,
    ['HEBOMB'] = 40,
    ['HEBOMBD'] = 40,
    ['MK-81SE'] = 60,
    ['AN-M57'] = 56,
    ['AN-M64'] = 180,
    ['AN-M65'] = 295,
    ['AN-M66A2'] = 536,
    ['HYDRA_70_M151'] = 4,
    ['HYDRA_70_MK5'] = 4,
    ['Vikhr_M'] = 11,
    ['British_GP_250LB_Bomb_Mk1'] = 100, -- ('250 lb GP Mk.I')
    ['British_GP_250LB_Bomb_Mk4'] = 100, -- ('250 lb GP Mk.IV')
    ['British_GP_250LB_Bomb_Mk5'] = 100, -- ('250 lb GP Mk.V')
    ['British_GP_500LB_Bomb_Mk1'] = 213, -- ('500 lb GP Mk.I')
    ['British_GP_500LB_Bomb_Mk4'] = 213, -- ('500 lb GP Mk.IV')
    ['British_GP_500LB_Bomb_Mk4_Short'] = 213, -- ('500 lb GP Short tail')
    ['British_GP_500LB_Bomb_Mk5'] = 213, -- ('500 lb GP Mk.V')
    ['British_MC_250LB_Bomb_Mk1'] = 100, -- ('250 lb MC Mk.I')
    ['British_MC_250LB_Bomb_Mk2'] = 100, -- ('250 lb MC Mk.II')
    ['British_MC_500LB_Bomb_Mk1_Short'] = 213, -- ('500 lb MC Short tail')
    ['British_MC_500LB_Bomb_Mk2'] = 213, -- ('500 lb MC Mk.II')
    ['British_SAP_250LB_Bomb_Mk5'] = 100, -- ('250 lb S.A.P.')
    ['British_SAP_500LB_Bomb_Mk5'] = 213, -- ('500 lb S.A.P.')
    ['British_AP_25LBNo1_3INCHNo1'] = 4, -- ('RP-3 25lb AP Mk.I')
    ['British_HE_60LBSAPNo2_3INCHNo1'] = 4, -- ('RP-3 60lb SAP No2 Mk.I')
    ['British_HE_60LBFNo1_3INCHNo1'] = 4, -- ('RP-3 60lb F No1 Mk.I')
    ['WGr21'] = 4, -- ('Werfer-Granate 21 - 21 cm UnGd air-to-air rocket')
    ['3xM8_ROCKETS_IN_TUBES'] = 4, -- ('4.5 inch M8 UnGd Rocket')
    ['AN_M30A1'] = 45, -- ('AN-M30A1 - 100lb GP Bomb LD')
    ['AN_M57'] = 100, -- ('AN-M57 - 250lb GP Bomb LD')
    ['AN_M65'] = 400, -- ('AN-M65 - 1000lb GP Bomb LD')
    ['AN_M66'] = 800, -- ('AN-M66 - 2000lb GP Bomb LD')
    ['SC_50'] = 20, -- ('SC 50 - 50kg GP Bomb LD')
    ['ER_4_SC50'] = 20, -- ('4 x SC 50 - 50kg GP Bomb LD')
    ['SC_250_T1_L2'] = 100, -- ('SC 250 Type 1 L2 - 250kg GP Bomb LD')
    ['SC_501_SC250'] = 100, -- ('SC 250 Type 3 J - 250kg GP Bomb LD')
    ['Schloss500XIIC1_SC_250_T3_J'] = 100, -- ('SC 250 Type 3 J - 250kg GP Bomb LD')
    ['SC_501_SC500'] = 213, -- ('SC 500 J - 500kg GP Bomb LD')
    ['SC_500_L2'] = 213, -- ('SC 500 L2 - 500kg GP Bomb LD')
    ['SD_250_Stg'] = 100, -- ('SD 250 Stg - 250kg GP Bomb LD')
    ['SD_500_A'] = 213, -- ('SD 500 A - 500kg GP Bomb LD')
    ['AB_250_2_SD_2'] = 100, -- ('AB 250-2 - 144 x SD-2, 250kg CBU with HE submunitions')
    ['AB_250_2_SD_10A'] = 100, -- ('AB 250-2 - 17 x SD-10A, 250kg CBU with 10kg Frag/HE submunitions')
    ['AB_500_1_SD_10A'] = 213, -- ('AB 500-1 - 34 x SD-10A, 500kg CBU with 10kg Frag/HE submunitions')
    ['AGM_114K'] = 10,
    ['HYDRA_70_M229'] = 8,
    ['AGM_65D'] = 130,
    ['AGM_65E'] = 300,
    ['AGM_65F'] = 300,
    ['AGM_65H'] = 130,
    ['AGM_65G'] = 300,
    ['AGM_65K'] = 300,
    ['AGM_65L'] = 300,
    ['HOT3'] = 15,
    ['AGR_20A'] = 8,
    ['AGR_20_M282'] = 8, -- A10C APKWS  															 
    ['GBU_54_V_1B'] = 118,
    ['Durandal'] = 100,
    ['SNEB_TYPE251_F1B'] = 8,
    ['SNEB_TYPE252_F1B'] = 8,
    ['SNEB_TYPE253_F1B'] = 8,
    ['SNEB_TYPE256_F1B'] = 8,
    ['SNEB_TYPE257_F1B'] = 8,
    ['SNEB_TYPE251_F4B'] = 4,
    ['SNEB_TYPE252_F4B'] = 4,
    ['SNEB_TYPE253_F4B'] = 5,
    ['SNEB_TYPE256_F4B'] = 6,
    ['SNEB_TYPE257_F4B'] = 8,
    ['SNEB_TYPE251_H1'] = 4,
    ['SNEB_TYPE252_H1'] = 4,
    ['SNEB_TYPE253_H1'] = 5,
    ['SNEB_TYPE256_H1'] = 6,
    ['SNEB_TYPE257_H1'] = 8,
    ['CBU_52B'] = 32, -- CBUs
    ['CBU_87'] = 32,
    ['CBU_97'] = 32,
    ['CBU_99'] = 32,
    ['ROCKEYE'] = 32,
    ['MATRA_F4_SNEBT251'] = 8, -- Mirage F1 Section
    ['MATRA_F4_SNEBT253'] = 8,
    ['MATRA_F4_SNEBT256'] = 8,
    ['MATRA_F1_SNEBT253'] = 8,
    ['MATRA_F1_SNEBT256'] = 8,
    ['SAMP400LD'] = 274,
    ['SAMP400HD'] = 274,
    ['SAMP250LD'] = 118,
    ['SAMP250HD'] = 118,
    ['SAMP125LD'] = 64,
    ['BR_250'] = 118,
    ['BELOUGA'] = 32,
    ['BLG66_BELOUGA'] = 32,
    ['BLU107B_DURANDAL'] = 274,
    ['FFAR Mk5 HEAT'] = 8, -- Rockets
    ['FFAR Mk1 HE'] = 8,
    ['C5'] = 8 -- Mig19P Rockets
}

----[[ ##### End of SCRIPT CONFIGURATION ##### ]]----

----[[ ##### HELPER/UTILITY FUNCTIONS ##### ]]----

local function getDistance(point1, point2)
    local x1 = point1.x
    local y1 = point1.y
    local z1 = point1.z
    local x2 = point2.x
    local y2 = point2.y
    local z2 = point2.z
    local dX = math.abs(x1 - x2)
    local dZ = math.abs(z1 - z2)
    local distance = math.sqrt(dX * dX + dZ * dZ)
    return distance
end

local function getDistance3D(point1, point2)
    local x1 = point1.x
    local y1 = point1.y
    local z1 = point1.z
    local x2 = point2.x
    local y2 = point2.y
    local z2 = point2.z
    local dX = math.abs(x1 - x2)
    local dY = math.abs(y1 - y2)
    local dZ = math.abs(z1 - z2)
    local distance = math.sqrt(dX * dX + dZ * dZ + dY * dY)
    return distance
end

local function vec3Mag(speedVec)
    local mag = speedVec.x * speedVec.x + speedVec.y * speedVec.y + speedVec.z * speedVec.z
    mag = math.sqrt(mag)
    return mag
end

local function lookahead(speedVec)
    local speed = vec3Mag(speedVec)
    local dist = speed * refreshRate * 1.5
    return dist
end

local function debugLog(text)
    trigger.action.outText('DEBUG: ' .. tostring(text), 5)
    env.info('ESCALATION SPLASH DAMAGE DEBUG: ' .. tostring(text))
end

local function errorLog(text)
    trigger.action.outText('ERROR: ' .. tostring(text), 30)
    env.error('ESCALATION SPLASH DAMAGE ERROR: ' .. tostring(text))
end

local function protectedCall(...)
    local ok, msg = pcall(...)
    if not ok then
        errorLog(msg)
    end
end

----[[ ##### End of HELPER/UTILITY FUNCTIONS ##### ]]----

local wpnHandler = {}
local trackedWeapons = {}
local trackedPossibleDeadUnits = {}

local function getWeaponExplosive(name)
    if explTable[name] then
        return explTable[name]
    else
        return 0
    end
end

local function onFoundObjectWithinBlastWave(obj, point, power, init)
    if splashDamageOptions.waveExplosions ~= true then
        return
    end

    if not obj:isExist() then
        return
    end
    local desc = obj:getDesc()
    if not desc or not desc.box then
        return
    end
    local box = desc.box

    local objLocation = obj:getPoint()
    local distance = getDistance(point, objLocation)
    local timing = distance / 500

    local length = box.max.x + math.abs(box.min.x)
    local height = box.max.y + math.abs(box.min.y)
    local depth = box.max.z + math.abs(box.min.z)
    if depth > length then
        local tmp = depth
        depth = length
        length = tmp
    end
    local surfaceDistance = distance - depth / 2
    local intensity = power / (4 * 3.14 * surfaceDistance * surfaceDistance)
    local surfaceArea = length * height
    local damageForSurface = intensity * surfaceArea
    if damageForSurface > splashDamageOptions.cascadeDamageThreshold then
        local explosionSize = damageForSurface
        if desc.category == Unit.Category.STRUCTURE then
            explosionSize = intensity * splashDamageOptions.staticDamageBoost
        end
        if explosionSize > power then
            explosionSize = power
        end -- secondary explosions should not be larger than the explosion that created it
        if explosionSize > 0 then
            timer.scheduleFunction(function()
                trigger.action.explosion(objLocation, explosionSize)
            end, nil, timer.getTime() + timing) -- create the explosion on the object location
            if desc.category == Unit.Category.GROUND_UNIT and obj:getCategory() == Object.Category.UNIT then
                trackedPossibleDeadUnits[obj:getID()] = {
                    init = init
                }
            end
        end
    end
end

local function blastWave(point, power, init)
    local volS = {
        id = world.VolumeType.SPHERE,
        params = {
            point = point,
            radius = splashDamageOptions.blastSearchRadius
        }
    }
    local foundFunc = function(obj)
        protectedCall(onFoundObjectWithinBlastWave, obj, point, power, init)
        return true
    end
    world.searchObjects(Object.Category.UNIT, volS, foundFunc)
    world.searchObjects(Object.Category.STATIC, volS, foundFunc)
    world.searchObjects(Object.Category.SCENERY, volS, foundFunc)
    world.searchObjects(Object.Category.CARGO, volS, foundFunc)
end

local function trackWpns()
    for wpnId, wpnData in pairs(trackedWeapons) do
        if wpnData.wpn:isExist() then -- just update speed, position and direction.
            wpnData.pos = wpnData.wpn:getPosition().p
            wpnData.dir = wpnData.wpn:getPosition().x
            wpnData.speed = wpnData.wpn:getVelocity()
        else -- wpn no longer exists, must be dead.
            local ip = land.getIP(wpnData.pos, wpnData.dir, lookahead(wpnData.speed)) -- terrain intersection point with weapon's nose.  Only search out 20 meters though.
            local impactPoint
            if not ip then -- use last calculated IP
                impactPoint = wpnData.pos
            else -- use intersection point
                impactPoint = ip
            end
            local explosive = getWeaponExplosive(wpnData.name)
            if explosive and explosive > 0 then
                if splashDamageOptions.rocketMultiplier > 0 and wpnData.cat == Weapon.Category.ROCKET then
                    explosive = explosive * splashDamageOptions.rocketMultiplier
                end
                blastWave(impactPoint, explosive, wpnData.init)
            end
            trackedWeapons[wpnId] = nil
        end
    end
end

local function onShotEvent(event)
    if not event.weapon then
        return
    end

    local ordnance = event.weapon
    local weaponDesc = ordnance:getDesc()
    local weaponType = ordnance:getTypeName()
    if string.find(weaponType, 'weapons.shells') then
        return -- we wont track these types of weapons, so exit here
    end

    if not explTable[weaponType] then
        env.warning(weaponType .. ' missing from Splash Damage script')
        return
    end
    if weaponDesc.category ~= 0 and event.initiator then
        if weaponDesc.category ~= 1 or (weaponDesc.MissileCategory ~= 1 and weaponDesc.MissileCategory ~= 2) then
            trackedWeapons[event.weapon.id_] = {
                wpn = ordnance,
                init = event.initiator:getName(),
                pos = ordnance:getPoint(),
                dir = ordnance:getPosition().x,
                name = weaponType,
                speed = ordnance:getVelocity(),
                cat = ordnance:getCategory()
            }
        end
    end
end

local function onDeadEvent(event)
    if not EscalationManager then
        return
    end
    if event.initiator and event.initiator.getID and event.initiator:getID() then
        local tracked = trackedPossibleDeadUnits[event.initiator:getID()]
        if tracked then
            EscalationManager.registerCollateralDamage(tracked.init, event.initiator)
        end
    end
end

local function onEvent(event)
    if event.id == world.event.S_EVENT_SHOT then
        onShotEvent(event)
    elseif event.id == world.event.S_EVENT_DEAD then
        onDeadEvent(event)
    end
end

timer.scheduleFunction(function(_, time)
    protectedCall(trackWpns)
    return time + refreshRate
end, {}, timer.getTime() + refreshRate)
local ev = {}
function ev:onEvent(event)
    protectedCall(onEvent, event)
end
world.addEventHandler(ev)
