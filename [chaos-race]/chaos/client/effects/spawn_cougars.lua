local activeCougars = {}
local COUGAR_LIFESPAN = 25000

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000)
        for i = #activeCougars, 1, -1 do
            local cougarData = activeCougars[i]
            if GetGameTimer() > cougarData.expirationTime or not DoesEntityExist(cougarData.handle) or IsEntityDead(cougarData.handle) then
                if DoesEntityExist(cougarData.handle) then
                    SetEntityAsMissionEntity(cougarData.handle, false, true)
                    DeleteEntity(cougarData.handle)
                end
                table.remove(activeCougars, i)
            end
        end
    end
end)

RegisterNetEvent('chaos:spawnCougars')
AddEventHandler('chaos:spawnCougars', function(name, type, duration)
    exports.chaos:AddEffectToUI(name, type, duration)
    Citizen.CreateThread(function()
        local playerPed = PlayerPedId()
        local cougarModel = GetHashKey("a_c_mtlion")
        RequestModel(cougarModel)
        local timeout = 200
        while not HasModelLoaded(cougarModel) and timeout > 0 do timeout = timeout - 1; Citizen.Wait(10) end
        if HasModelLoaded(cougarModel) then
            for i = 1, 5 do
                local spawnPos = GetOffsetFromEntityInWorldCoords(playerPed, (math.random(80) - 40) / 10.0, 6.0 + (math.random() * 2.0), 0.5)
                local foundGround, groundZ = GetGroundZFor_3dCoord(spawnPos.x, spawnPos.y, spawnPos.z + 20.0, false)
                local cougar = CreatePed(4, cougarModel, spawnPos.x, spawnPos.y, (foundGround and groundZ or spawnPos.z), 0.0, true, true)
                if DoesEntityExist(cougar) then
                    SetEntityMaxHealth(cougar, 1000); SetEntityHealth(cougar, 1000); SetPedArmour(cougar, 200); SetPedAsEnemy(cougar, true)
                    SetPedFleeAttributes(cougar, 0, false); SetPedCombatAttributes(cougar, 46, true); SetPedCombatAttributes(cougar, 5, true)
                    TaskCombatPed(cougar, playerPed, 0, 16)
                    table.insert(activeCougars, { handle = cougar, expirationTime = GetGameTimer() + COUGAR_LIFESPAN })
                end
                Citizen.Wait(50)
            end
        end
        SetModelAsNoLongerNeeded(cougarModel)
    end)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print("Chaos script stopping. Cleaning up all active cougars...")
        for _, cougarData in pairs(activeCougars) do
            if DoesEntityExist(cougarData.handle) then DeleteEntity(cougarData.handle) end
        end
        print("Cougar cleanup complete.")
    end
end)