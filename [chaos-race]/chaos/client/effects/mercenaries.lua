-- File: chaos/client/effects/mercenaries.lua
-- Spawns two teams of "Walter" mercenaries who hunt the player down.
-- One team is in a helicopter, the other is in an armored truck.
-- They will respawn if their team is wiped out.

-- Configuration for the effect
local walterModel = `Walter` -- This is Walter's model name. 'walter' is not a valid model name in gta v. 
local helicopterModel = `buzzard`
local groundVehicleModel = `mesa3` -- Merryweather Mesa
local weaponHash = GetHashKey("WEAPON_CARBINERIFLE")
local respawnDistance = 350.0

-- State tracking for the active mercenary squads
local activeSquads = {
    heli = { vehicle = 0, peds = {} },
    ground = { vehicle = 0, peds = {} }
}
local relationshipGroup

-- Helper function to clean up a squad's entities
local function CleanupSquad(squad)
    if squad.vehicle and DoesEntityExist(squad.vehicle) then
        SetEntityAsMissionEntity(squad.vehicle, false, true)
        DeleteEntity(squad.vehicle)
    end
    for _, ped in ipairs(squad.peds) do
        if DoesEntityExist(ped) then
            SetEntityAsMissionEntity(ped, false, true)
            DeleteEntity(ped)
        end
    end
    squad.vehicle = 0
    squad.peds = {}
end

-- Spawns a vehicle and fills it with armed "Walters"
local function SpawnSquadVehicle(isHeli)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local vehicleModelHash = isHeli and helicopterModel or groundVehicleModel

    -- Request the models we need
    RequestModel(vehicleModelHash)
    RequestModel(walterModel)
    while not HasModelLoaded(vehicleModelHash) or not HasModelLoaded(walterModel) do
        Citizen.Wait(10)
    end

    -- Determine a safe spawn position
    local spawnPos
    if isHeli then
        spawnPos = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 150.0, 75.0)
    else
        local found, nodePos = GetRandomVehicleNode(playerCoords.x, playerCoords.y, playerCoords.z, 150.0, false, true, true)
        if found then
            spawnPos = nodePos
        else
            spawnPos = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 100.0, 5.0) -- Fallback
        end
    end

    -- Create the vehicle
    local vehicle = CreateVehicle(vehicleModelHash, spawnPos.x, spawnPos.y, spawnPos.z, GetEntityHeading(playerPed), true, true)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetEntityAsMissionEntity(vehicle, true, true)
    
    -- Populate with mercenaries
    local newPeds = {}
    local numSeats = GetVehicleModelNumberOfSeats(vehicleModelHash)
    for seat = -1, numSeats - 2 do
        local ped = CreatePedInsideVehicle(vehicle, 4, walterModel, seat, true, true)
        SetEntityAsMissionEntity(ped, true, true)
        SetPedRelationshipGroupHash(ped, relationshipGroup)
        GiveWeaponToPed(ped, weaponHash, 250, false, true)
        SetPedCombatAttributes(ped, 46, true) -- Make them fight to the death
        SetPedAccuracy(ped, 25) -- Give the player a chance
        TaskCombatPed(ped, playerPed, 0, 16)
        table.insert(newPeds, ped)
    end

    -- Clean up loaded models
    SetModelAsNoLongerNeeded(vehicleModelHash)
    SetModelAsNoLongerNeeded(walterModel)

    return vehicle, newPeds
end

RegisterNetEvent('chaos:sussyBaka')
AddEventHandler('chaos:sussyBaka', function(name, type, duration)
    exports.chaos:AddEffectToUI(name, type, duration)
    print("Starting 'Sussy Baka' effect.")

    Citizen.CreateThread(function()
        -- Setup relationship group to make them hate the player
        relationshipGroup = GetHashKey("SUSSY_BAKAS")
        AddRelationshipGroup(relationshipGroup)
        SetRelationshipBetweenGroups(5, relationshipGroup, GetHashKey("PLAYER")) -- 5 = Hate

        -- Initial spawn
        activeSquads.heli.vehicle, activeSquads.heli.peds = SpawnSquadVehicle(true)
        activeSquads.ground.vehicle, activeSquads.ground.peds = SpawnSquadVehicle(false)

        -- Main loop for the effect's duration
        while exports.chaos:IsEffectActive(name) do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local allSquadsOk = true

            for squadName, squad in pairs(activeSquads) do
                local squadIsWiped = true
                -- Check if any peds are still active in the squad
                for i = #squad.peds, 1, -1 do
                    local ped = squad.peds[i]
                    if DoesEntityExist(ped) and not IsEntityDead(ped) and GetDistanceBetweenCoords(playerCoords, GetEntityCoords(ped)) < respawnDistance then
                        squadIsWiped = false
                        -- Make sure they are still attacking
                        TaskCombatPed(ped, playerPed, 0, 16)
                    else
                        -- Ped is dead or too far, remove them
                        if DoesEntityExist(ped) then
                            SetEntityAsMissionEntity(ped, false, true)
                            DeleteEntity(ped)
                        end
                        table.remove(squad.peds, i)
                    end
                end

                -- If the squad is wiped, clean up the old vehicle and respawn the squad
                if squadIsWiped then
                    print("Sussy Baka squad ("..squadName..") wiped out. Respawning...")
                    allSquadsOk = false
                    CleanupSquad(squad) -- Clean up the old vehicle
                    local isHeli = (squadName == 'heli')
                    squad.vehicle, squad.peds = SpawnSquadVehicle(isHeli)
                end
            end

            -- Only wait if no squads needed respawning this frame
            if allSquadsOk then
                Citizen.Wait(2000)
            else
                Citizen.Wait(100) -- Shorter wait after a respawn
            end
        end

        -- Effect is over, cleanup all entities
        print("'Sussy Baka' effect has ended. Cleaning up.")
        CleanupSquad(activeSquads.heli)
        CleanupSquad(activeSquads.ground)
    end)
end)