-- File: chaos/client/effects/mandatory_conscription.lua
-- VERSION 4: The Order of Operations Fix

local activeTanks = {}
local playerTankLocks = {}
local activeTankSounds = {}

local function CleanupOldTank(playerServerId)
    local oldTank = activeTanks[playerServerId]
    if oldTank and DoesEntityExist(oldTank) then
        print(("[Tank] Player %s is getting a new Tank. Removing old one (ID: %d)"):format(playerServerId, oldTank))
        if activeTankSounds[oldTank] and exports.xsound:soundExists(activeTankSounds[oldTank]) then
            exports.xsound:Destroy(activeTankSounds[oldTank])
            activeTankSounds[oldTank] = nil
        end
        SetEntityAsMissionEntity(oldTank, false, true)
        DeleteEntity(oldTank)
    end
    activeTanks[playerServerId] = nil
    playerTankLocks[playerServerId] = nil
end

RegisterNetEvent('chaos:mandatoryConscription')
AddEventHandler('chaos:mandatoryConscription', function(targetPlayerServerId, name, type, duration)
    local myServerId = GetPlayerServerId(PlayerId())
    if myServerId == targetPlayerServerId then
        exports.chaos:AddEffectToUI(name, type, duration)
        CleanupOldTank(myServerId)

        Citizen.CreateThread(function()
            -- Get the player's current character entity (the ped)
            local playerPed = PlayerPedId()

            -- 1. Create the vehicle first.
            local tankModel = GetHashKey("RHINO")
            RequestModel(tankModel)
            while not HasModelLoaded(tankModel) do Citizen.Wait(10) end
            
            local coords = GetEntityCoords(playerPed)
            local spawnCoords = coords + (GetEntityForwardVector(playerPed) * 5.0)
            local tank = CreateVehicle(tankModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, GetEntityHeading(playerPed), true, true)
            
            SetModelAsNoLongerNeeded(tankModel)
            SetEntityAsMissionEntity(tank, true, true)
            activeTanks[myServerId] = tank
            playerTankLocks[myServerId] = true
            
            -- 2. Forcefully and immediately place the ped into the vehicle.
            -- We use SetPedIntoVehicle as it's more direct than TaskWarpPedIntoVehicle.
            -- The seat index -1 is the driver's seat.
            SetPedIntoVehicle(playerPed, tank, -1)

            -- 3. ONLY AFTER the player is safely in the tank, we ask the server to change the model.
            -- This fixes the race condition by creating a clear order of operations.
            local soldierModel = GetHashKey("s_m_y_marine_01")
            TriggerServerEvent('chaosrace:serverSetPlayerModel', soldierModel)
        end)
    end

    -- Sound logic remains the same
    Citizen.CreateThread(function()
        Citizen.Wait(500)
        local targetTank = activeTanks[targetPlayerServerId]
        if targetTank and DoesEntityExist(targetTank) then
            local soundName = "soviet_march_" .. targetPlayerServerId
            if not exports.xsound:soundExists(soundName) then
                exports.xsound:PlayUrlPos(soundName, "sounds/soviet_march.ogg", 0.7, GetEntityCoords(targetTank), true)
                exports.xsound:Distance(soundName, 150.0)
                exports.xsound:setSoundLoop(soundName, true)
                activeTankSounds[targetTank] = soundName
            end
        end
    end)
end)

-- The rest of the file (the main logic loop and resource stop) remains unchanged.
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local myServerId = GetPlayerServerId(PlayerId())
        local myTank = activeTanks[myServerId]
        if exports.chaos:IsEffectActive("Mandatory Conscription") then
            if myTank and DoesEntityExist(myTank) and playerTankLocks[myServerId] then
                if GetVehiclePedIsIn(PlayerPedId(), false) == myTank then DisableControlAction(0, 75, true) end
            end
        else
            if myTank and playerTankLocks[myServerId] then
                print(("[Tank] Effect expired for player %s. They keep the tank (ID: %d)."):format(myServerId, myTank))
                local soundName = activeTankSounds[myTank]
                if soundName and exports.xsound:soundExists(soundName) then exports.xsound:Destroy(soundName); activeTankSounds[myTank] = nil end
                if DoesEntityExist(myTank) then SetEntityAsMissionEntity(myTank, false, true) end
                playerTankLocks[myServerId] = false 
            end
        end
        for tank, sound in pairs(activeTankSounds) do
            if tank and DoesEntityExist(tank) and exports.xsound:soundExists(sound) then exports.xsound:Position(sound, GetEntityCoords(tank)) end
        end
    end
end)