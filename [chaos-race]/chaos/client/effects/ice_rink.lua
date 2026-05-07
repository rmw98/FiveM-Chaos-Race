RegisterNetEvent('chaos:iceRink')
AddEventHandler('chaos:iceRink', function(name, type, duration)
    if not exports.chaos:IsEffectActive(name) then
        print("Starting 'Ice Rink' effect.")
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if vehicle ~= 0 then
            local originalGrip = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fTractionCurveMax")
            SetVehicleHandlingFloat(vehicle, "CHandlingData", "fTractionCurveMax", originalGrip * 0.15)
            Citizen.CreateThread(function()
                while exports.chaos:IsEffectActive(name) do Citizen.Wait(500) end
                if DoesEntityExist(vehicle) then
                    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fTractionCurveMax", originalGrip)
                    print("Last 'Ice Rink' effect ended. Grip restored.")
                end
            end)
        end
    end
    exports.chaos:AddEffectToUI(name, type, duration)
end)