-- File: chaos/client/effects/zombies.lua
-- Spawns zombies that chase the player and explode upon taking significant damage or ragdolling.

local isEffectActive = false
local activeZombies = {}
local ZOMBIE_MODEL = `u_m_y_zombie_01`

local function cleanup()
    if not isEffectActive then return end
    print("Zombies: Cleaning up remaining zombies.")
    for _, zombie in pairs(activeZombies) do
        if DoesEntityExist(zombie) then
            SetEntityAsMissionEntity(zombie, false, true)
            DeleteEntity(zombie)
        end
    end
    activeZombies = {}
    isEffectActive = false
end

RegisterNetEvent('chaos:zombies')
AddEventHandler('chaos:zombies', function(name, type, duration)
    if isEffectActive then
        exports.chaos:AddEffectToUI(name, type, duration)
        return
    end

    isEffectActive = true
    exports.chaos:AddEffectToUI(name, type, duration)
    print("Zombies: The horde is coming...")

    RequestModel(ZOMBIE_MODEL)
    while not HasModelLoaded(ZOMBIE_MODEL) do
        Citizen.Wait(10)
    end

    -- Main effect thread
    Citizen.CreateThread(function()
        local lastSpawnTime = 0
        local spawnInterval = 3000 -- Spawn a new zombie every 3 seconds

        while exports.chaos:IsEffectActive(name) do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            -- 1. Spawn new zombies periodically
            if GetGameTimer() > lastSpawnTime + spawnInterval and #activeZombies < 15 then
                lastSpawnTime = GetGameTimer()
                
                -- Spawn in front of the player
                local spawnPos = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 25.0, 0.0)
                local foundGround, groundZ = GetGroundZFor_3dCoord(spawnPos.x, spawnPos.y, spawnPos.z + 50.0, false)
                
                if foundGround then
                    local zombie = CreatePed(4, ZOMBIE_MODEL, spawnPos.x, spawnPos.y, groundZ, GetEntityHeading(playerPed), true, true)
                    SetPedCombatAttributes(zombie, 46, true) -- Fight to the death
                    SetPedCombatAttributes(zombie, 5, true)  -- Will pursue on foot
                    SetPedFleeAttributes(zombie, 0, false)
                    TaskCombatPed(zombie, playerPed, 0, 16)
                    table.insert(activeZombies, zombie)
                end
            end

            -- 2. Check existing zombies for the explosion condition
            for i = #activeZombies, 1, -1 do
                local zombie = activeZombies[i]
                if DoesEntityExist(zombie) then
                    -- If the zombie is ragdolling or has taken any damage, it explodes.
                    if IsPedRagdoll(zombie) or GetEntityHealth(zombie) < GetEntityMaxHealth(zombie) then
                        local zombieCoords = GetEntityCoords(zombie)
                        AddExplosion(zombieCoords.x, zombieCoords.y, zombieCoords.z, 4, 3.0, true, false, 0.5)
                        DeleteEntity(zombie)
                        table.remove(activeZombies, i)
                    end
                else
                    -- Remove from table if it no longer exists for any reason
                    table.remove(activeZombies, i)
                end
            end

            Citizen.Wait(100)
        end
        
        -- Effect has ended, clean up everything
        cleanup()
        SetModelAsNoLongerNeeded(ZOMBIE_MODEL)
    end)
end)

-- Safety cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        cleanup()
    end
end)