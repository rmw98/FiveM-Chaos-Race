RegisterNetEvent('chaos:vehicleRain')
AddEventHandler('chaos:vehicleRain', function(name, type, duration)
    exports.chaos:AddEffectToUI(name, type, duration)

    Citizen.CreateThread(function()
        print("Starting 'Vehicle Rain' effect (Server-Side Spawning).")

        while exports.chaos:IsEffectActive(name) do
            local playerPed = PlayerPedId()
            if DoesEntityExist(playerPed) and not IsEntityDead(playerPed) then
                
                -- The client's ONLY job is to calculate the spawn position.
                local playerCoords = GetEntityCoords(playerPed)
                local playerSpeed = GetEntitySpeed(playerPed)
                local forwardVector = GetEntityForwardVector(playerPed)
                local spawnOffset = forwardVector * (playerSpeed * 3.0)
                local spawnHeight = 40.0

                local spawnPos = vector3(
                    playerCoords.x + spawnOffset.x + math.random(-20, 20),
                    playerCoords.y + spawnOffset.y + math.random(-20, 20),
                    playerCoords.z + spawnHeight
                )
                
                -- Ask the server to spawn a vehicle for us at these coordinates.
                TriggerServerEvent('chaosrace:serverSpawnFallingVehicle', spawnPos)
            end

            -- Wait a short, random amount of time before spawning the next vehicle
            Citizen.Wait(math.random(500, 1500))
        end
        print("'Vehicle Rain' effect has ended.")
    end)
end)