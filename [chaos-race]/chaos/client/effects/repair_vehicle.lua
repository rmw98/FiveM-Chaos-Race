-- File: chaos/client/effects/repair_vehicle.lua
-- This is a self-contained module for the "Repair Vehicle" effect.

RegisterNetEvent('chaos:repairVehicle')
AddEventHandler('chaos:repairVehicle', function(name, type, duration)
    exports.chaos:AddEffectToUI(name, type, duration)
    
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= 0 then
        SetVehicleFixed(vehicle)
        SetVehicleDirtLevel(vehicle, 0.0)
        SetVehicleFuelLevel(vehicle, 100.0)
        print("Vehicle repaired!")
    end
end)