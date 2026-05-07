-- File: chaos/client/effects/mass_hysteria.lua
-- NEW EFFECT (Combined): "Mass Hysteria"
-- Causes nearby drivers to become hostile while pedestrians on foot randomly trip and fall.

local isHysteriaActive = false

-- This function cleans up the effect, returning drivers to normal.
local function endHysteria(enragedDrivers)
    print("'Mass Hysteria' has ended. The city is returning to normal.")
    if enragedDrivers then
        for driver, _ in pairs(enragedDrivers) do
            if DoesEntityExist(driver) and not IsPedAPlayer(driver) then
                ClearPedTasks(driver)
                SetPedAsEnemy(driver, false)
                SetDriverAggressiveness(driver, 0.5) -- Return to default aggressiveness
            end
        end
    end
    isHysteriaActive = false
end

RegisterNetEvent('chaos:massHysteria')
AddEventHandler('chaos:massHysteria', function(name, effectType, duration)
    exports.chaos:AddEffectToUI(name, effectType, duration)
    
    if not isHysteriaActive then
        isHysteriaActive = true
        print("Starting 'Mass Hysteria' effect.")

        Citizen.CreateThread(function()
            -- This table tracks drivers we've already angered to avoid re-tasking them.
            local enragedDrivers = {}

            while exports.chaos:IsEffectActive(name) do
                local playerPed = PlayerId()
                local playerCoords = GetEntityCoords(PlayerPedId())
                
                -- This loop checks ALL peds in the vicinity.
                for _, ped in ipairs(GetGamePool('CPed')) do
                    -- Basic checks: Is the ped valid, human, not a player, and nearby?
                    if DoesEntityExist(ped) and IsPedHuman(ped) and not IsPedAPlayer(ped) and #(GetEntityCoords(ped) - playerCoords) < 150.0 then
                        
                        -- LOGIC BRANCH: Is the ped in a car or on foot?
                        if IsPedInAnyVehicle(ped, false) then
                            -- === DRIVER LOGIC (Go Rogue) ===
                            local vehicle = GetVehiclePedIsIn(ped, false)
                            -- Make sure they are actually the driver and we haven't angered them yet.
                            if GetPedInVehicleSeat(vehicle, -1) == ped and not enragedDrivers[ped] then
                                SetPedAsEnemy(ped, true)
                                SetDriverAggressiveness(ped, 1.0) -- Max aggressiveness
                                TaskCombatPed(ped, PlayerPedId(), 0, 16) -- Use car as weapon
                                enragedDrivers[ped] = true -- Mark as enraged
                            end
                        else
                            -- === PEDESTRIAN LOGIC (Clumsy) ===
                            -- Give them a 20% chance to trip each time we check, if they aren't already on the ground.
                            if math.random(1, 100) <= 20 and not IsPedRagdoll(ped) then
                               SetPedToRagdoll(ped, 1500, 2000, 0, false, false, false)
                            end
                        end
                    end
                end
                
                Citizen.Wait(750) -- Check for new peds to affect every 0.75 seconds.
            end

            -- The effect timer in the UI has run out. Clean up.
            endHysteria(enragedDrivers)
        end)
    end
end)

-- Cleanup if the resource is stopped mid-effect
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName and isHysteriaActive then
        endHysteria(nil)
    end
end)