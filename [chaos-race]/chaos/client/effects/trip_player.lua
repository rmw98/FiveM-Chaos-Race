RegisterNetEvent('chaos:tripPlayer')
AddEventHandler('chaos:tripPlayer', function(name, type, duration)
    exports.chaos:AddEffectToUI(name, type, duration)
    local playerPed = PlayerPedId()
    if not IsPedInAnyVehicle(playerPed, false) and not IsPedRagdoll(playerPed) then
        SetPedToRagdoll(playerPed, 1500, 2000, 0, false, false, false)
    end
end)