RegisterNetEvent('chaos:engineCutoff')
AddEventHandler('chaos:engineCutoff', function(name, type, duration)
    exports.chaos:AddEffectToUI(name, type, duration)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= 0 then SetVehicleFuelLevel(vehicle, 0.0) end
end)