RegisterNetEvent('chaos:leakyBoat')
AddEventHandler('chaos:leakyBoat', function(name, type, duration)
    exports.chaos:AddEffectToUI(name, type, duration)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= 0 then
        Citizen.CreateThread(function()
            local endTime = GetGameTimer() + duration
            while GetGameTimer() < endTime do
                if DoesEntityExist(vehicle) then
                    local currentHealth = GetVehicleEngineHealth(vehicle)
                    SetVehicleEngineHealth(vehicle, currentHealth - 25.0)
                    if GetVehicleEngineHealth(vehicle) < 100.0 then break end
                end
                Citizen.Wait(1000)
            end
        end)
    end
end)