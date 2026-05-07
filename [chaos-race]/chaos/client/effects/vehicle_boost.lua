-- File: chaos/client/effects/vehicle_boost.lua

RegisterNetEvent('chaos:vehicleBoost')
AddEventHandler('chaos:vehicleBoost', function(name, type, duration)
    exports.chaos:AddEffectToUI(name, type, duration)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then return end

    -- Apply the boost
    SetVehicleEnginePowerMultiplier(vehicle, 1000.0)
    PlaySoundFromEntity(-1, "BOOST_ACTIVATED", vehicle, "HUD_MINI_GAME_SOUNDSET", true, 0)

    Citizen.CreateThread(function()
        Citizen.Wait(duration)

        -- [[ THE FIX IS HERE ]]
        -- The duration has expired. We now clean up unconditionally.
        -- The faulty 'if not exports.chaos:IsEffectActive(name)' check has been removed.

        -- We get the vehicle again to ensure we are acting on the correct one.
        local vehicleAtCleanup = GetVehiclePedIsIn(PlayerPedId(), false)
        if DoesEntityExist(vehicleAtCleanup) then
            SetVehicleEnginePowerMultiplier(vehicleAtCleanup, 1.0)
            PlaySoundFromEntity(-1, "BOOST_END", vehicleAtCleanup, "HUD_MINI_GAME_SOUNDSET", true, 0)
            print("Vehicle Boost expired. Engine power restored.")
        end
    end)
end)
