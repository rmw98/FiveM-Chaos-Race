-- File: chaos/client/effects/bouncy_castle.lua
-- VERSION 2: Crash Fix & Improved Physics
-- Makes all vehicles super bouncy on collision.

local isEffectActive = false
local bouncedVehicles = {}
local BOUNCE_COOLDOWN = 500 -- Cooldown per vehicle (in ms) to prevent physics bugs
local BOUNCE_FORCE = 5.0    -- How strong the upward bounce is

RegisterNetEvent('chaos:bouncyCastle')
AddEventHandler('chaos:bouncyCastle', function(name, type, duration)
    -- This effect can't stack its logic thread
    if isEffectActive then
        exports.chaos:AddEffectToUI(name, type, duration) -- Extend the timer
        return
    end

    isEffectActive = true
    exports.chaos:AddEffectToUI(name, type, duration)
    
    Citizen.CreateThread(function()
        while exports.chaos:IsEffectActive(name) do
            Citizen.Wait(0)
            
            -- Get all vehicles currently in the world
            for _, veh in ipairs(GetGamePool('CVehicle')) do
                -- Check if the vehicle exists and has collided with anything
                if DoesEntityExist(veh) and HasEntityCollidedWithAnything(veh) then
                    
                    -- *** THE FIX IS HERE ***
                    -- The vehicle handle 'veh' is already a unique number, so we can use it directly as the key.
                    local vehId = veh

                    -- Only bounce the vehicle if its cooldown has expired
                    if not bouncedVehicles[vehId] or GetGameTimer() > bouncedVehicles[vehId] then
                        
                        -- Get the vehicle's current velocity to make the bounce more natural
                        local velocity = GetEntityVelocity(veh)
                        
                        -- Apply a strong upward force and a slightly opposing force to create a "bounce"
                        ApplyForceToEntity(
                            veh,
                            1, -- Force type
                            -velocity.x * 0.5, -velocity.y * 0.5, BOUNCE_FORCE, -- Force vector (X, Y, Z)
                            0.0, 0.0, 0.0,  -- No rotational force
                            false,          -- isLocal
                            true,           -- ignoreUpward
                            true,           -- isStrong
                            true,           -- isMassRel
                            true            -- unk
                        )
                        
                        -- Set the cooldown for this specific vehicle
                        bouncedVehicles[vehId] = GetGameTimer() + BOUNCE_COOLDOWN
                    end
                end
            end
        end
        
        -- Effect has ended, clear the cooldown table for the next activation
        bouncedVehicles = {}
        isEffectActive = false
    end)
end)