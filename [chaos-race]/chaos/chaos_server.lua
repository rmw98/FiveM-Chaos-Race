-- File: resources/[chaos-race]/chaos/chaos_server.lua
-- Chaos Resource - Server Side (Refactored to use shared/config.lua)
math.randomseed(os.time())

-- NEW HELPER FUNCTION
-- Checks if a value exists in a table
function table.contains(tbl, val)
    for _, value in ipairs(tbl) do
        if value == val then
            return true
        end
    end
    return false
end

-- =================================================================
--                        CHAOS CONFIGURATION
-- =================================================================
-- The chaosEffects table and chaosInterval have been moved to shared/config.lua
-- They are now accessed via Config.Effects and Config.chaosInterval
-- =================================================================

local playerChaosTimers = {}

-- =================================================================
--                    CHAOS SERVER LOOP
-- =================================================================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local currentTime = GetGameTimer()

        for player, nextEffectTime in pairs(playerChaosTimers) do
            if currentTime >= nextEffectTime then
                local playerSource = tonumber(player)
                if GetPlayerName(playerSource) then
                   -- 1. Ask the client what its current situation is.
                   TriggerClientEvent('chaos:requestPlayerContext', playerSource)
                    -- Use the value from the config file
                    playerChaosTimers[player] = currentTime + (Config.chaosInterval * 1000) 
                else
                    playerChaosTimers[player] = nil -- Clean up disconnected player
                end
            end
        end
    end
end)

-- 3. Client has responded with its context, now we pick an effect.
RegisterNetEvent('chaos:sendPlayerContext')
AddEventHandler('chaos:sendPlayerContext', function(playerContext)
    local source = source
    local possibleEffects = {}
    local totalWeight = 0

    -- Create a pool of possible effects based on the new context logic
    for _, effect in ipairs(Config.Effects) do 
        -- An effect is valid if 'any' is in its context table, OR if the player's context is in its table.
        if table.contains(effect.context, 'any') or table.contains(effect.context, playerContext) then
            table.insert(possibleEffects, effect)
            totalWeight = totalWeight + (effect.weight or 1)
        end
    end

    -- The weighted selection logic remains the same from here
    if #possibleEffects > 0 then
        local randomNum = math.random(1, totalWeight)
        local currentWeight = 0

        for _, effect in ipairs(possibleEffects) do
            currentWeight = currentWeight + (effect.weight or 1)
            if randomNum <= currentWeight then
                -- For effects that need to be seen/heard by everyone, broadcast them.
                if effect.name == "La Lamborghini" or effect.name == "Mandatory Conscription" or effect.name == "Ejecto Seato Cuz!" or effect.name == "Kachow!" then 
                    TriggerClientEvent(effect.clientEvent, -1, source, effect.name, effect.type, effect.duration) -- Send to ALL clients
                    print("Selected effect: " .. effect.name .. " for player " .. GetPlayerName(source) .. " (ID: " .. source .. ")")
                else
                    TriggerClientEvent(effect.clientEvent, source, effect.name, effect.type, effect.duration) -- Send only to the target player
                    print("Selected effect: " .. effect.name .. " for player " .. GetPlayerName(source))
                end
                return
            end
        end
    else
        print("No valid chaos effects found for player " .. GetPlayerName(source) .. " with context: " .. playerContext)
    end
end)


-- =================================================================
--          EVENT HANDLERS (LISTENING TO GAMEMANAGER)
-- =================================================================

-- CHANGED: Listening for the new, explicit activation event.
AddEventHandler('chaos:activateForPlayer', function(playerSource)
    local safeKey = tostring(playerSource)
    -- Set the first chaos effect to trigger after exactly `chaosInterval` seconds.
    playerChaosTimers[safeKey] = GetGameTimer() + (Config.chaosInterval * 1000) 
    print("Chaos system ACTIVATED for player " .. GetPlayerName(playerSource))
end)

-- CHANGED: Listening for the new, explicit deactivation event.
AddEventHandler('chaos:deactivateForPlayer', function(playerSource)
    local safeKey = tostring(playerSource)
    -- Stop the chaos timer for this player since their race is over
    playerChaosTimers[safeKey] = nil
    print("Chaos system DEACTIVATED for player " .. GetPlayerName(playerSource))
end)

-- =================================================================
--                 GAMEMANAGER EVENT HANDLER
-- =================================================================
AddEventHandler('gamemanager:fullReset', function()
    -- Gamemanager told us to reset everything.
    playerChaosTimers = {}
    print("Chaos resource has been reset by gamemanager.")
end)


exports('getChaosEffects', function()
    return Config.Effects
end)