local function ApplyMaxUpgrades(vehicle)
    SetVehicleModKit(vehicle, 0)
    SetVehicleMod(vehicle, 11, GetNumVehicleMods(vehicle, 11) - 1, false); SetVehicleMod(vehicle, 12, GetNumVehicleMods(vehicle, 12) - 1, false); SetVehicleMod(vehicle, 13, GetNumVehicleMods(vehicle, 13) - 1, false); SetVehicleMod(vehicle, 15, GetNumVehicleMods(vehicle, 15) - 1, false); ToggleVehicleMod(vehicle, 18, true)
    SetVehicleMod(vehicle, 0, GetNumVehicleMods(vehicle, 0) -1, false); SetVehicleMod(vehicle, 1, GetNumVehicleMods(vehicle, 1) -1, false); SetVehicleMod(vehicle, 2, GetNumVehicleMods(vehicle, 2) -1, false); SetVehicleMod(vehicle, 3, GetNumVehicleMods(vehicle, 3) -1, false); SetVehicleMod(vehicle, 4, GetNumVehicleMods(vehicle, 4) -1, false); SetVehicleMod(vehicle, 6, GetNumVehicleMods(vehicle, 6) -1, false); SetVehicleMod(vehicle, 7, GetNumVehicleMods(vehicle, 7) -1, false); SetVehicleMod(vehicle, 10, GetNumVehicleMods(vehicle, 10) -1, false)
    SetVehicleMod(vehicle, 23, GetNumVehicleMods(vehicle, 23) - 1, true); SetVehicleWheelType(vehicle, 7); ToggleVehicleMod(vehicle, 22, true)
    SetVehicleNumberPlateText(vehicle, "Tyrone"); SetVehicleColours(vehicle, 12, 0); SetVehicleExtraColours(vehicle, 1, 156); SetVehicleWindowTint(vehicle, 1)
end

RegisterNetEvent('chaos:instantSupercar')
AddEventHandler('chaos:instantSupercar', function(name, type, duration)
    if not exports.chaos:IsEffectActive(name) then
        print("Starting 'Instant Supercar' effect.")
        Citizen.CreateThread(function()
            local playerPed = PlayerPedId()
            if IsPedInAnyVehicle(playerPed, false) then return end
            local vehicleModel = GetHashKey("PARIAH")
            RequestModel(vehicleModel)
            while not HasModelLoaded(vehicleModel) do Citizen.Wait(10) end
            local coords = GetEntityCoords(playerPed)
            local forward_vector = GetEntityForwardVector(playerPed)
            local spawnCoords = coords + (forward_vector * 5.0)
            local vehicle = CreateVehicle(vehicleModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, GetEntityHeading(playerPed), true, true)
            SetModelAsNoLongerNeeded(vehicleModel)
            ApplyMaxUpgrades(vehicle)
            TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
        end)
    end
    exports.chaos:AddEffectToUI(name, type, duration)
end)