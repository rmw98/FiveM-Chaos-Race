-- File: [chaos-race]/chaos/client/effects/marked_man.lua (v3.0 - COMBAT AI STRATEGY)
-- Switches to a more direct and aggressive "TaskCombatPed" AI to resolve the "brain-dead" issue.

-- =================================================================
--                        CONFIGURATION (REVISED)
-- =================================================================
local CONFIG = {
    HunterVehicleModel   = `BUFFALO2`,
    NumberOfHunters      = 3,
    HunterColor          = 0,
    HunterPedModel       = `s_m_y_swat_01`,
    EnginePowerMultiplier  = 400.0, -- RE-INTRODUCED: The power the AI can use.
    GripMultiplier         = 4.5,   -- High grip for aggressive cornering.
    MaxDistance            = 150.0,
    RespawnDistance        = 40.0,
    SidewaysImpactForce  = 300.0,
    UpwardImpactForce    = 15.0,
    SlipperyDuration     = 2500,
    CollisionCooldown    = 1500
}
local isEffectActive = false
local activeHunters = {}
local lastPlayerImpactTime = 0
local isPlayerSlippery = false

local function CleanupHunter(hunter)
    if hunter and hunter.blip and DoesBlipExist(hunter.blip) then RemoveBlip(hunter.blip) end
    if hunter and hunter.vehicle and DoesEntityExist(hunter.vehicle) then SetEntityAsMissionEntity(hunter.vehicle, false, true); DeleteEntity(hunter.vehicle) end
    if hunter and hunter.ped and DoesEntityExist(hunter.ped) then SetEntityAsMissionEntity(hunter.ped, false, true); DeleteEntity(hunter.ped) end
end

local function CleanupAllHunters()
    for _, hunter in ipairs(activeHunters) do CleanupHunter(hunter) end
    activeHunters = {}
end

-- =================================================================
--                        CORE AI LOGIC (REVISED)
-- =================================================================
local function SpawnHunter(targetPed, spawnIndex)
    local playerVehicle = GetVehiclePedIsIn(targetPed, false)
    if playerVehicle == 0 then return nil end
    local sideOffset = (spawnIndex - (CONFIG.NumberOfHunters + 1) / 2) * 5.0
    local spawnCoords = GetOffsetFromEntityInWorldCoords(playerVehicle, sideOffset, -CONFIG.RespawnDistance, 1.0)
    local vehicle = CreateVehicle(CONFIG.HunterVehicleModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, GetEntityHeading(playerVehicle), true, true)
    if vehicle == 0 then return nil end
    SetEntityVelocity(vehicle, GetEntityVelocity(playerVehicle))
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleModKit(vehicle, 0); SetVehicleColours(vehicle, CONFIG.HunterColor, CONFIG.HunterColor); SetVehicleDoorsLocked(vehicle, 4)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fTractionCurveMax", CONFIG.GripMultiplier); SetEntityInvincible(vehicle, true)
    
    -- <<< NEW: Apply engine power directly to the vehicle >>>
    SetVehicleEnginePowerMultiplier(vehicle, CONFIG.EnginePowerMultiplier)

    local driver = CreatePedInsideVehicle(vehicle, 4, CONFIG.HunterPedModel, -1, true, true)
    if driver == 0 then CleanupHunter({vehicle = vehicle}); return nil end

    local blip = AddBlipForEntity(vehicle)
    SetBlipSprite(blip, 1); SetBlipColour(blip, 1); SetBlipScale(blip, 0.8); SetBlipAsShortRange(blip, true)

    SetEntityAsMissionEntity(driver, true, true)
    SetDriverAbility(driver, 1.0); SetDriverAggressiveness(driver, 1.0)
    SetPedFleeAttributes(driver, 0, false); SetPedCombatAttributes(driver, 46, true)
    SetPedKeepTask(driver, true)

    -- <<< NEW AI TASK: Tell the driver to attack the player's character >>>
    TaskCombatPed(driver, targetPed, 0, 16)

    return { vehicle = vehicle, ped = driver, blip = blip }
end

-- (ApplyImpactEffect function is correct and remains unchanged)
local function ApplyImpactEffect(playerVehicle)
    if isPlayerSlippery or GetGameTimer() < lastPlayerImpactTime + CONFIG.CollisionCooldown then return end
    lastPlayerImpactTime = GetGameTimer(); isPlayerSlippery = true
    PlaySoundFromEntity(-1, "RAM_CAR", playerVehicle, "CAR_CRASH_SOUNDS", true, 0)
    local rightVector, _, _, _ = GetEntityMatrix(playerVehicle)
    local forceDirection = math.random() > 0.5 and 1 or -1
    ApplyForceToEntity(playerVehicle, 1, rightVector.x * CONFIG.SidewaysImpactForce * forceDirection, rightVector.y * CONFIG.SidewaysImpactForce * forceDirection, CONFIG.UpwardImpactForce, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
    Citizen.CreateThread(function()
        if not DoesEntityExist(playerVehicle) then isPlayerSlippery = false; return end
        local originalGrip = GetVehicleHandlingFloat(playerVehicle, "CHandlingData", "fTractionCurveMax")
        SetVehicleHandlingFloat(playerVehicle, "CHandlingData", "fTractionCurveMax", 0.1)
        Citizen.Wait(CONFIG.SlipperyDuration)
        if DoesEntityExist(playerVehicle) then SetVehicleHandlingFloat(playerVehicle, "CHandlingData", "fTractionCurveMax", originalGrip) end
        isPlayerSlippery = false
    end)
end
-- =================================================================
--                        MAIN EVENT & LOOP
-- =================================================================

RegisterNetEvent('chaos:markedMan')
AddEventHandler('chaos:markedMan', function(name, type, duration)
    exports.chaos:AddEffectToUI(name, type, duration)
    if isEffectActive then return end
    
    local playerPed = PlayerPedId()
    if GetVehiclePedIsIn(playerPed, false) == 0 then return end

    Citizen.CreateThread(function()
        isEffectActive = true

        RequestModel(CONFIG.HunterVehicleModel); RequestModel(CONFIG.HunterPedModel)
        while not HasModelLoaded(CONFIG.HunterVehicleModel) or not HasModelLoaded(CONFIG.HunterPedModel) do Citizen.Wait(50) end
        
        for i = 1, CONFIG.NumberOfHunters do
            local newHunter = SpawnHunter(playerPed, i)
            if newHunter then table.insert(activeHunters, newHunter) end
        end

        while exports.chaos:IsEffectActive(name) do
            Citizen.Wait(100) -- Check every 100ms
            local pPed = PlayerPedId()
            if IsEntityDead(pPed) or GetVehiclePedIsIn(pPed, false) == 0 then break end
            local pVehicle = GetVehiclePedIsIn(pPed, false)
            local pCoords = GetEntityCoords(pVehicle)

            for i = #activeHunters, 1, -1 do
                local hunter = activeHunters[i]
                if hunter and DoesEntityExist(hunter.vehicle) and DoesEntityExist(hunter.ped) and IsPedInVehicle(hunter.ped, hunter.vehicle, false) then
                    local distance = #(GetEntityCoords(hunter.vehicle) - pCoords)
                    if distance > CONFIG.MaxDistance then
                        CleanupHunter(hunter); table.remove(activeHunters, i)
                        local newHunter = SpawnHunter(pPed, i)
                        if newHunter then table.insert(activeHunters, newHunter) end
                    end
                    
                    -- <<< LOOP SIMPLIFIED: No re-tasking needed, TaskCombatPed is very persistent >>>

                    if IsEntityTouchingEntity(pVehicle, hunter.vehicle) then
                        ApplyImpactEffect(pVehicle)
                    end
                else
                    CleanupHunter(hunter); table.remove(activeHunters, i)
                    local newHunter = SpawnHunter(pPed, i)
                    if newHunter then table.insert(activeHunters, newHunter) end
                end
            end
        end

        CleanupAllHunters()
        isEffectActive, lastPlayerImpactTime, isPlayerSlippery = false, 0, false
    end)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName and isEffectActive then
        CleanupAllHunters()
        isEffectActive = false
    end
end)