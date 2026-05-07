-- File: chaos/client/effects/void_touch.lua
-- Effect: Void Touch
-- When active, any vehicle the player touches with their own vehicle will disappear.

local isEffectActive = false

-- Note: The event name was changed from midasTouch to voidTouch in config.lua
RegisterNetEvent('chaos:voidTouch')
AddEventHandler('chaos:voidTouch', function(name, type, duration)
    -- This prevents the effect's logic from running in multiple threads simultaneously.
    if isEffectActive then
        exports.chaos:AddEffectToUI(name, type, duration) -- Just extend the timer on the UI
        return
    end

    isEffectActive = true
    exports.chaos:AddEffectToUI(name, type, duration)
    
    Citizen.CreateThread(function()
        -- The main loop runs as long as the effect is active according to the UI manager
        while exports.chaos:IsEffectActive(name) do
            Citizen.Wait(0)
            local playerPed = PlayerPedId()
            
            -- This effect requires the player to be in a vehicle.
            if IsPedInAnyVehicle(playerPed, false) then
                local playerVehicle = GetVehiclePedIsIn(playerPed, false)

                -- Check against all other vehicles in the game's entity pool
                for _, otherVehicle in ipairs(GetGamePool('CVehicle')) do
                    -- Conditions:
                    -- 1. The other vehicle exists.
                    -- 2. It's not the player's own vehicle.
                    -- 3. The player's vehicle is physically touching it.
                    if DoesEntityExist(otherVehicle) and otherVehicle ~= playerVehicle and IsEntityTouchingEntity(playerVehicle, otherVehicle) then
                        
                        -- The effect's action: simply delete the other vehicle.
                        DeleteEntity(otherVehicle)
                    end
                end
            end
        end

        -- The effect's timer has run out, so we reset the active flag.
        isEffectActive = false
    end)
end)