local activeMcQueens = {}

RegisterNetEvent('chaos:kachow')
AddEventHandler('chaos:kachow', function(targetPlayerServerId, name, type, duration)
    local myServerId = GetPlayerServerId(PlayerId())
    local mcqueenModel = GetHashKey("lm95")

    if myServerId == targetPlayerServerId then
        exports.chaos:AddEffectToUI(name, type, duration)
        Citizen.CreateThread(function()
            RequestModel(mcqueenModel)
            while not HasModelLoaded(mcqueenModel) do Citizen.Wait(10) end
            local playerPed = PlayerPedId()
            local oldVehicle = GetVehiclePedIsIn(playerPed, false)
            if oldVehicle == 0 then SetModelAsNoLongerNeeded(mcqueenModel); return end
            local oldCoords, oldHeading, oldVelocity = GetEntityCoords(oldVehicle), GetEntityHeading(oldVehicle), GetEntityVelocity(oldVehicle)
            local mcqueen = CreateVehicle(mcqueenModel, oldCoords.x, oldCoords.y, oldCoords.z, oldHeading, true, true)
            DeleteEntity(oldVehicle)
            activeMcQueens[myServerId] = mcqueen
            SetEntityAsMissionEntity(mcqueen, true, true)
            SetVehicleNumberPlateText(mcqueen, "KACHOW"); SetVehicleColours(mcqueen, 36, 0); SetVehicleDirtLevel(mcqueen, 0.0); SetVehicleEnginePowerMultiplier(mcqueen, 75.0)
            SetVehicleHandlingFloat(mcqueen, "CHandlingData", "fSteeringLock", 28.0); SetVehicleHandlingFloat(mcqueen, "CHandlingData", "fTractionCurveMax", 4.5); SetVehicleHandlingFloat(mcqueen, "CHandlingData", "fTractionCurveMin", 0.8); SetVehicleHandlingFloat(mcqueen, "CHandlingData", "fBrakeForce", 1.8)
            TaskWarpPedIntoVehicle(playerPed, mcqueen, -1)
            SetEntityVelocity(mcqueen, oldVelocity.x, oldVelocity.y, oldVelocity.z)
            SetModelAsNoLongerNeeded(mcqueenModel)
            Citizen.CreateThread(function()
                Citizen.Wait(duration)
                if DoesEntityExist(mcqueen) then
                    if GetVehiclePedIsIn(PlayerPedId(), false) == mcqueen then TaskLeaveVehicle(PlayerPedId(), mcqueen, 4160); Citizen.Wait(500) end
                    SetEntityAsMissionEntity(mcqueen, false, true)
                    DeleteEntity(mcqueen)
                end
                activeMcQueens[myServerId] = nil
            end)
        end)
    end
    Citizen.CreateThread(function()
        Citizen.Wait(500)
        local targetMcQueen = activeMcQueens[targetPlayerServerId]
        if targetMcQueen and DoesEntityExist(targetMcQueen) then
            exports.xsound:PlayUrlPos("kachow_"..targetPlayerServerId, "sounds/kachow.ogg", 0.9, GetEntityCoords(targetMcQueen), false)
        end
    end)
end)