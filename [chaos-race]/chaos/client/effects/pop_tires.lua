-- File: chaos/client/effects/pop_tires.lua
-- This is a self-contained module for the "Pop Tires" effect.

RegisterNetEvent('chaos:popTires')
AddEventHandler('chaos:popTires', function(name, type, duration)
    -- By calling the export *inside* the event handler, we guarantee it exists.
    exports.chaos:AddEffectToUI(name, type, duration)
    
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= 0 then
        -- The tire indices are 0, 1, 4, 5 for most cars.
        SetVehicleTyreBurst(vehicle, 0, false, 1000.0)
        SetVehicleTyreBurst(vehicle, 1, false, 1000.0)
        SetVehicleTyreBurst(vehicle, 4, false, 1000.0)
        SetVehicleTyreBurst(vehicle, 5, false, 1000.0)
    end
end)