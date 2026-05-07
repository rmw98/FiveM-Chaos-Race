-- File: chaos/client/effects/meteor_shower.lua
-- This effect causes meteors to rain from the sky around the player, exploding on impact.
-- VERSION 2: Using the improved, predictive spawning logic from vehicle_rain.

RegisterNetEvent('chaos:meteorShower')
AddEventHandler('chaos:meteorShower', function(name, effectType, duration)
    exports.chaos:AddEffectToUI(name, effectType, duration)
    print("Starting 'Meteor Shower' effect.")

    Citizen.CreateThread(function()
        local meteorModels = {
            `prop_asteroid_01`, `prop_test_boulder_01`, `prop_test_boulder_02`,
            `prop_test_boulder_03`, `prop_test_boulder_04`
        }

        RequestNamedPtfxAsset("core")
        while not HasNamedPtfxAssetLoaded("core") do Citizen.Wait(10) end

        while exports.chaos:IsEffectActive(name) do
            local playerPed = PlayerPedId()
            if DoesEntityExist(playerPed) then
                -- --- COPIED & ADAPTED SPAWN LOGIC ---
                local playerCoords = GetEntityCoords(playerPed)
                local playerSpeed = GetEntitySpeed(playerPed)
                local forwardVector = GetEntityForwardVector(playerPed)

                -- Calculate a spawn point in front of the player, based on their speed.
                -- Using a multiplier of 4.0 for meteors to give a little more reaction time.
                local spawnOffset = forwardVector * (playerSpeed * 4.0)

                -- A lower spawn height for faster impact.
                local spawnHeight = 90.0

                -- Combine for the final spawn position.
                local spawnPos = vector3(
                    playerCoords.x + spawnOffset.x + math.random(-40, 40), -- A medium horizontal spread
                    playerCoords.y + spawnOffset.y + math.random(-40, 40),
                    playerCoords.z + spawnHeight
                )

                local randomModel = meteorModels[math.random(#meteorModels)]
                
                Citizen.CreateThread(function()
                    RequestModel(randomModel)
                    local timeout = 100
                    while not HasModelLoaded(randomModel) and timeout > 0 do
                        Citizen.Wait(10); timeout = timeout - 1
                    end

                    if HasModelLoaded(randomModel) then
                        local meteor = CreateObject(randomModel, spawnPos.x, spawnPos.y, spawnPos.z, true, false, true)
                        
                        UseParticleFxAsset("core")
                        StartParticleFxLoopedOnEntity("ent_sht_flame", meteor, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, false, false, false)
                        ApplyForceToEntity(meteor, 1, 0.0, 0.0, -500.0, 0.0, 0.0, 0.0, 0, true, true, true, true, true)

                        local hasCollided = false
                        local collisionCheckEnd = GetGameTimer() + 8000
                        while not hasCollided and GetGameTimer() < collisionCheckEnd do
                            Citizen.Wait(50)
                            if HasEntityCollidedWithAnything(meteor) then
                                hasCollided = true
                            end
                        end
                        
                        if DoesEntityExist(meteor) then
                            local impactCoords = GetEntityCoords(meteor)
                            AddExplosion(impactCoords.x, impactCoords.y, impactCoords.z, 2, 5.0, true, false, 0.5)
                            DeleteEntity(meteor)
                        end
                    end
                    
                    SetModelAsNoLongerNeeded(randomModel)
                end)
            end
            
            -- Wait before spawning the next meteor
            Citizen.Wait(math.random(250, 750))
        end
        print("'Meteor Shower' effect has ended.")
    end)
end)