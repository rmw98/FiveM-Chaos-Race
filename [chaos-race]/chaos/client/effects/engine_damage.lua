-- File: chaos/client/effects/engine_damage.lua
-- This is a self-contained module for the "Engine Damage" effect.

RegisterNetEvent('chaos:engineDamage')
AddEventHandler('chaos:engineDamage', function(name, type, duration)
    exports.chaos:AddEffectToUI(name, type, duration)
    
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then return end

    local misfireHealth = 1.0
    local currentEngineHealth = GetVehicleEngineHealth(vehicle)

    if currentEngineHealth <= misfireHealth then
        SetVehicleEngineHealth(vehicle, -1.0)
    else
        SetVehicleEngineHealth(vehicle, misfireHealth)
    end
    print("Applied Engine Damage. New Engine Health: " .. GetVehicleEngineHealth(vehicle))
end)