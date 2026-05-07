-- File: C:\Users\rober\Desktop\fivem\FXServer\server-data\resources\[chaos-race]\chaos\client\effects\realistic_la.lua
-- VERSION 3: Definitive Traffic Fix (No Empty Cars)

-- This effect creates the "Realistic LA" experience: lots of traffic and homeless people.
-- It works by drastically increasing the density multipliers, and by manually spawning 
-- additional cars WITH drivers to flood the streets with controlled chaos.

local isEffectActive = false

-- --- PED CONFIG ---
local homelessModels = { `a_m_m_tramp_01`, `a_m_o_tramp_01`, `u_m_o_tramp_01` }
local spawnedPeds = {}

-- --- VEHICLE & DRIVER CONFIG ---
local trafficVehicleModels = {
    `blista`, `primo`, `asea`, `stratum`, `ingot`, `dilettante`, `emperor`, `taxi`, `panto`, `issi2`, `prairie`, `rancherxl`, `primo2`, `cogcabrio`
}
-- We now use a predefined list of civilian models to ensure drivers look normal and load quickly.
local civilianDriverModels = {
    `s_m_y_airworker`, `a_m_y_business_02`, `a_f_y_business_02`, `s_m_y_busboy_01`, `s_f_y_clerk_01`, `a_f_y_eastsa_02`, `a_m_y_ktown_01`,
    `s_m_y_construct_01`, `s_f_y_factory_01`, `s_m_y_garbage`, `a_f_y_hipster_01`, `a_m_y_hipster_02`, `a_m_y_runner_01`, `s_f_y_shop_mid`
}
local spawnedVehicles = {}

-- This function is crucial for cleaning up after the effect ends.
local function cleanup()
    if not isEffectActive then return end
    print("Realistic LA: Effect ending, cleaning up all spawned entities.")
    for _, ped in pairs(spawnedPeds) do
        if DoesEntityExist(ped) then
            SetEntityAsMissionEntity(ped, false, true); DeleteEntity(ped)
        end
    end
    spawnedPeds = {}
    for _, vehicle in pairs(spawnedVehicles) do
        if DoesEntityExist(vehicle) then
            SetEntityAsMissionEntity(vehicle, false, true); DeleteEntity(vehicle)
        end
    end
    spawnedVehicles = {}
    isEffectActive = false
end

-- This is the event handler that the chaos mod will trigger.
RegisterNetEvent('chaos:realisticLA')
AddEventHandler('chaos:realisticLA', function(name, type, duration)
    if isEffectActive then
        exports.chaos:AddEffectToUI(name, type, duration)
        return
    end

    isEffectActive = true
    exports.chaos:AddEffectToUI(name, type, duration)
    print("Starting 'Realistic LA' effect (v3 - Definitive Traffic Fix).")

    Citizen.CreateThread(function()
        -- Request all models we'll need at the start for better performance.
        for _, model in ipairs(homelessModels) do RequestModel(model) end
        for _, model in ipairs(trafficVehicleModels) do RequestModel(model) end
        for _, model in ipairs(civilianDriverModels) do RequestModel(model) end
        while not HasModelLoaded(civilianDriverModels[1]) or not HasModelLoaded(trafficVehicleModels[1]) do Citizen.Wait(50) end
        print("Realistic LA: All required models are loaded.")

        local lastPedSpawnTime = 0
        local lastVehicleSpawnTime = 0

        while exports.chaos:IsEffectActive(name) do
            Citizen.Wait(0) -- Run this logic every frame.
            
            SetVehicleDensityMultiplierThisFrame(10.0)
            SetPedDensityMultiplierThisFrame(5.0)

            local gameTime = GetGameTimer()
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            -- === SPAWN HOMELESS PEDS === (Unchanged, already working well)
            if gameTime > lastPedSpawnTime + 500 and #spawnedPeds < 60 then
                lastPedSpawnTime = gameTime
                local spawnPos = GetOffsetFromEntityInWorldCoords(playerPed, (math.random(80, 150) / 10.0) * (math.random() > 0.5 and 1 or -1), (math.random(80, 150) / 10.0) * (math.random() > 0.5 and 1 or -1), 0.0)
                local foundGround, groundZ = GetGroundZFor_3dCoord(spawnPos.x, spawnPos.y, spawnPos.z + 20.0, false)
                if foundGround then
                    local randomModel = homelessModels[math.random(#homelessModels)]
                    if HasModelLoaded(randomModel) then
                        local ped = CreatePed(4, randomModel, spawnPos.x, spawnPos.y, groundZ, 0.0, true, true)
                        if DoesEntityExist(ped) then
                            table.insert(spawnedPeds, ped)
                            TaskWanderStandard(ped, 10.0, 10)
                        end
                    end
                end
            end

            -- === SPAWN EXTRA TRAFFIC (THE DEFINITIVE FIX) ===
            if gameTime > lastVehicleSpawnTime + 500 and #spawnedVehicles < 35 then
                lastVehicleSpawnTime = gameTime
                local found, nodePos = GetRandomVehicleNode(playerCoords.x, playerCoords.y, playerCoords.z, 150.0, false, true, true)
                if found then
                    local randomVehicleModel = trafficVehicleModels[math.random(#trafficVehicleModels)]
                    local randomDriverModel = civilianDriverModels[math.random(#civilianDriverModels)]

                    if HasModelLoaded(randomVehicleModel) and HasModelLoaded(randomDriverModel) then
                        local vehicle = CreateVehicle(randomVehicleModel, nodePos, GetEntityHeading(playerPed), true, true)
                        if DoesEntityExist(vehicle) then
                            table.insert(spawnedVehicles, vehicle)
                            -- The fix for empty cars is here: Create the ped directly inside the vehicle.
                            local driver = CreatePedInsideVehicle(vehicle, 4, randomDriverModel, -1, true, true)
                            SetPedAsEnemy(driver, false) -- Ensure they aren't hostile
                            TaskVehicleDriveWander(driver, vehicle, 25.0, 786603) -- 786603 = Obey traffic laws
                        end
                    end
                end
            end
        end

        cleanup()
        
        for _, model in ipairs(homelessModels) do SetModelAsNoLongerNeeded(model) end
        for _, model in ipairs(trafficVehicleModels) do SetModelAsNoLongerNeeded(model) end
        for _, model in ipairs(civilianDriverModels) do SetModelAsNoLongerNeeded(model) end
    end)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then cleanup() end
end)