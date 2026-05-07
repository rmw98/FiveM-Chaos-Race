local isForrestGumpRunning = false

RegisterNetEvent('chaos:forceRun')
AddEventHandler('chaos:forceRun', function(name, type, duration)
    exports.chaos:AddEffectToUI(name, type, duration)

    -- This thread handles the one-time model change and sound.
    Citizen.CreateThread(function()
        local playerPed = PlayerPedId()
        if not IsPedInAnyVehicle(playerPed, false) then
            -- === THE FIX IS HERE ===
            -- Ask the server to change our model to Tom Hanks.
            local gumpModel = GetHashKey("tom_hanks")
            TriggerServerEvent('chaosrace:serverSetPlayerModel', gumpModel)
        end
        
        -- The sound logic can stay as it is.
        local soundName = "run_forrest_" .. math.random(1, 10000)
        exports.xsound:PlayUrl(soundName, "sounds/run_forrest_run.ogg", 0.7, false)
        Citizen.Wait(4500)
        if exports.xsound:soundExists(soundName) then exports.xsound:Destroy(soundName) end
    end)

    -- This loop handles the physical "force run" action.
    if not isForrestGumpRunning then
        isForrestGumpRunning = true
        Citizen.CreateThread(function()
            while exports.chaos:IsEffectActive(name) do
                local ped = PlayerPedId()
                if not IsPedInAnyVehicle(ped, false) then
                    SetPlayerSprint(PlayerId(), true)
                    RestorePlayerStamina(PlayerId(), 100.0)
                    local target_coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 100.0, 0.0)
                    TaskGoStraightToCoord(ped, target_coords.x, target_coords.y, target_coords.z, 4.0, -1, 0.0, 0)
                end
                Citizen.Wait(0)
            end
            ClearPedTasks(PlayerPedId())
            isForrestGumpRunning = false
            print("Last 'Run Forrest, Run!' effect ended. Stopping physical loop.")
        end)
    end
end)