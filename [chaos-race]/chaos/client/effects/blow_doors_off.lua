-- File: chaos/client/effects/blow_doors_off.lua
-- Blows all doors off the player's current vehicle.

RegisterNetEvent('chaos:blowDoorsOff')
AddEventHandler('chaos:blowDoorsOff', function(name, type, duration)
    exports.chaos:AddEffectToUI(name, type, duration)

    local playerPed = PlayerId()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

    if vehicle ~= 0 and GetVehicleClass(vehicle) < 13 then
        PlaySoundFromEntity(-1, "Air_Defence_Turret_Explode", vehicle, "Trevors_Rampage_Sounds", true, 0)
        
        -- Doors are indexed 0-5 (FrontL, FrontR, BackL, BackR, Hood, Trunk)
        for i = 0, 5 do
            SetVehicleDoorBroken(vehicle, i, true)
        end
    end
end)