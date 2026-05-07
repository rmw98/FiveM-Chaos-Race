-- File: chaos/client/effects/la_lamborghini.lua
-- This effect is a consolidation of the original 'ksi_lambo' resource.

-- Configuration (originally from the top of ksi_lambo/client.lua)
local carModel = "lp700"
local soundFile = "sounds/la_lamborghini.ogg"
local soundVolume = 0.7
local soundDistance = 200.0
local carColor = 145
local liveryIndex = 0

-- State Management (now local to this effect module)
local modelHash = GetHashKey(carModel)
local playerLambos = {}
local playerLocks = {}
local activeSounds = {}

-- Helper Function (now local to this module)
function CleanupOldLambo(playerServerId)
    local oldCar = playerLambos[playerServerId]
    if oldCar and DoesEntityExist(oldCar) then
        print(("[Lambo] Player %s is getting a new Lambo. Removing old one (Car ID: %d)"):format(playerServerId, oldCar))
        if activeSounds[oldCar] and exports.xsound:soundExists(activeSounds[oldCar]) then
            exports.xsound:Destroy(activeSounds[oldCar])
            activeSounds[oldCar] = nil
        end
        SetEntityAsMissionEntity(oldCar, false, true)
        DeleteVehicle(oldCar)
    end
    playerLambos[playerServerId] = nil
    playerLocks[playerServerId] = nil
end

-- Main Event Handler
RegisterNetEvent("chaos:LaLamborghini")
AddEventHandler("chaos:LaLamborghini", function(targetPlayerServerId, name, type, duration)
    local myServerId = GetPlayerServerId(PlayerId())

    if myServerId == targetPlayerServerId then
        -- We now use the main chaos export to manage the UI
        exports.chaos:AddEffectToUI(name, type, duration)
        
        CleanupOldLambo(myServerId)

        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do Citizen.Wait(10) end
        
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local newCar = CreateVehicle(modelHash, coords.x, coords.y, coords.z, GetEntityHeading(playerPed), true, true)
        
        SetEntityAsMissionEntity(newCar, true, true)
        playerLambos[myServerId] = newCar
        playerLocks[myServerId] = true

        TaskWarpPedIntoVehicle(playerPed, newCar, -1)
        SetVehicleRadioEnabled(newCar, false)
        SetVehicleColours(newCar, carColor, carColor)
        SetVehicleLivery(newCar, liveryIndex)
        SetVehicleNumberPlateText(newCar, "K51 FLY")
        SetModelAsNoLongerNeeded(modelHash)
    end

    Citizen.CreateThread(function()
        Citizen.Wait(500)
        local targetCar = playerLambos[targetPlayerServerId]
        if targetCar and DoesEntityExist(targetCar) then
            local soundName = "lambo_" .. targetCar
            if not exports.xsound:soundExists(soundName) then
                exports.xsound:PlayUrlPos(soundName, soundFile, soundVolume, GetEntityCoords(targetCar), true)
                exports.xsound:Distance(soundName, soundDistance)
                exports.xsound:setSoundLoop(soundName, true)
                activeSounds[targetCar] = soundName
            end
        end
    end)
end)

-- The `lambo:unlockPlayer` event was only used by `chaos:ejectPlayer`. We can handle this internally now.
-- In `eject_player.lua`, we simply remove the TriggerEvent call. The player is already being ejected.

-- Main Logic Loop (now uses the main chaos export for checking active status)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local myServerId = GetPlayerServerId(PlayerId())
        local myLambo = playerLambos[myServerId]
        
        if exports.chaos:IsEffectActive("La Lamborghini") then
            if myLambo and DoesEntityExist(myLambo) and playerLocks[myServerId] and GetVehiclePedIsIn(PlayerPedId(), false) == myLambo then
                DisableControlAction(0, 75, true)
            end
        else
            if playerLocks[myServerId] then
                print(("[Lambo] Effect expired for player %s. They keep the car (ID: %d)."):format(myServerId, myLambo))
                local soundName = activeSounds[myLambo]
                if soundName and exports.xsound:soundExists(soundName) then exports.xsound:Destroy(soundName); activeSounds[myLambo] = nil end
                if myLambo and DoesEntityExist(myLambo) then SetEntityAsMissionEntity(myLambo, false, true) end
                playerLocks[myServerId] = false 
            end
        end
        
        for car, sound in pairs(activeSounds) do
            if car and DoesEntityExist(car) and exports.xsound:soundExists(sound) then exports.xsound:Position(sound, GetEntityCoords(car)) end
        end
    end
end)

-- Resource stop cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for car, sound in pairs(activeSounds) do
            if exports.xsound:soundExists(sound) then exports.xsound:Destroy(sound) end
        end
        print("[Lambo] Sounds cleaned up due to resource stop.")
    end
end)