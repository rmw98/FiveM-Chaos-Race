-- File: chaos/client/effects/peds_riot.lua
-- VERSION 4: The definitive version. Uses a more direct and reliable method
-- to make all nearby peds attack the player.

local isRiotLoopActive = false

local function endRiot()
    print("Peds Riot: Riot has ended.")
    -- When the loop stops, peds will naturally lose their tasks and aggression.
    -- We can force a cleanup by giving them a simple "stand still" task if needed.
    for _, ped in ipairs(GetGamePool('CPed')) do
        if DoesEntityExist(ped) and not IsPedAPlayer(ped) then
            ClearPedTasks(ped)
        end
    end
end

RegisterNetEvent('chaos:pedsRiot')
AddEventHandler('chaos:pedsRiot', function(name, effectType, duration)
    exports.chaos:AddEffectToUI(name, effectType, duration)
    
    if not isRiotLoopActive then
        isRiotLoopActive = true
        print("Starting 'Peds Riot' effect.")

        Citizen.CreateThread(function()
            while exports.chaos:IsEffectActive(name) do
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)
                
                -- This is a reliable way to get all peds in the loaded area of the world.
                for _, ped in ipairs(GetGamePool('CPed')) do
                    if DoesEntityExist(ped) and not IsPedAPlayer(ped) then
                        local distance = #(GetEntityCoords(ped) - playerCoords)
                        
                        -- Only affect peds within a reasonable distance (e.g., 150 meters).
                        if distance < 150.0 then
                            -- We only want to anger human peds, not animals.
                            if IsPedHuman(ped) then
                                -- *** THE NEW, RELIABLE LOGIC IS HERE ***

                                -- 1. Force the ped to see the player as an enemy.
                                SetPedAsEnemy(ped, true)
                                
                                -- 2. Ensure they don't run away.
                                SetPedFleeAttributes(ped, 0, false)
                                SetPedCombatAttributes(ped, 46, true) -- Can fight to the death

                                -- 3. Give them a weapon if they don't have one.
                                if not IsPedArmed(ped, 7) then
                                    GiveWeaponToPed(ped, GetHashKey("WEAPON_PISTOL"), 100, false, true)
                                end

                                -- 4. Explicitly tell them to fight the player.
                                TaskCombatPed(ped, playerPed, 0, 16)
                            end
                        end
                    end
                end
                
                -- Wait for a few seconds before re-evaluating and angering new peds that have spawned in.
                Citizen.Wait(2000)
            end

            -- When the effect ends, run the cleanup.
            endRiot()
            isRiotLoopActive = false
        end)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if isRiotLoopActive then
            endRiot()
        end
    end
end)