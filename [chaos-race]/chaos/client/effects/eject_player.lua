RegisterNetEvent('chaos:ejectPlayer')
AddEventHandler('chaos:ejectPlayer', function(targetPlayerServerId, name, type, duration)
    local myServerId = GetPlayerServerId(PlayerId())
    if myServerId == targetPlayerServerId then
        exports.chaos:AddEffectToUI(name, type, duration)
        exports.xsound:PlayUrl("eject_local", "sounds/ejectseat.ogg", 0.8, false)
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        if vehicle ~= 0 then
            -- The unlock event is no longer needed as the lambo logic is self-contained.
            -- TriggerEvent('lambo:unlockPlayer')
            TaskLeaveVehicle(playerPed, vehicle, 4160)
        end
    else
        local targetPlayer = GetPlayerFromServerId(targetPlayerServerId)
        if targetPlayer == -1 then return end
        local targetPed = GetPlayerPed(targetPlayer)
        if DoesEntityExist(targetPed) then
            exports.xsound:PlayUrlPos("eject_" .. targetPlayerServerId, "sounds/ejectseat.ogg", 0.8, GetEntityCoords(targetPed), false)
        end
    end
end)