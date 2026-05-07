-- File: chaos/client/effects/england_chant.lua
-- VERSION 4.2: THE TRUE FIX. Based on the user-identified working code.

-- This is the helper function from the version that is confirmed to produce sound.
local function PerformHonk(vehicle, honkDuration, pauseAfter)
    if DoesEntityExist(vehicle) then
        -- Step 1: Start the horn sound.
        StartVehicleHorn(vehicle, honkDuration, GetHashKey("HELDDOWN"), false)

        -- Step 2: Wait for the honk itself to finish playing.
        Citizen.Wait(honkDuration)

        -- Step 3: Wait for the silent pause AFTER the honk is done.
        Citizen.Wait(pauseAfter)
    else
        -- If vehicle is destroyed, just wait for the total time to keep rhythm.
        Citizen.Wait(honkDuration + pauseAfter)
    end
end

RegisterNetEvent('chaos:englandChant')
AddEventHandler('chaos:englandChant', function(name, type, duration)
    exports.chaos:AddEffectToUI(name, type, duration)

    Citizen.CreateThread(function()
        -- Using the correct PlayerPedId() function.
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        if vehicle == 0 then return end

        -- =======================================================================
        -- TIMING VARIABLES - This is the only section being modified.
        -- =======================================================================
        local HONK_LENGTH   = 250 -- Increased for a long, held-down sound.
        local SHORT_GAP     = 80  -- The short silent gap between quick honks.
        local LONG_GAP      = 300 -- The longer silent gap between sets.

        -- --- Sequence Start ---
        PerformHonk(vehicle, HONK_LENGTH, SHORT_GAP)
        PerformHonk(vehicle, HONK_LENGTH, LONG_GAP)

        PerformHonk(vehicle, HONK_LENGTH, SHORT_GAP)
        PerformHonk(vehicle, HONK_LENGTH, SHORT_GAP)
        PerformHonk(vehicle, HONK_LENGTH, LONG_GAP)

        PerformHonk(vehicle, HONK_LENGTH, SHORT_GAP)
        PerformHonk(vehicle, HONK_LENGTH, SHORT_GAP)
        PerformHonk(vehicle, HONK_LENGTH, SHORT_GAP)
        PerformHonk(vehicle, HONK_LENGTH, LONG_GAP)
    end)
end)