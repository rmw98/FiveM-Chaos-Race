RegisterNetEvent('chaos:engineFailure')
AddEventHandler('chaos:engineFailure', function(name, type, duration)
    exports.chaos:AddEffectToUI(name, type, duration)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= 0 then
        SetVehicleEngineOn(vehicle, false, true, false)
        Citizen.CreateThread(function()
            for i = 1, 5 do
                if DoesEntityExist(vehicle) then
                    SetVehicleEngineOn(vehicle, false, true, false)
                    Citizen.Wait(math.random(500, 1000))
                end
            end
        end)
    end
end)