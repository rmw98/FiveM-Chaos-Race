-- File: C:\Users\rober\Desktop\fivem\FXServer\server-data\resources\[chaos-race]\chaos\client\effects\tube_man_army.lua

-- This effect spawns an army of wacky inflatable tube men that chase the player.
-- Their flailing animations and gliding movement create a hilarious and chaotic obstacle.

local isEffectActive = false
local tubeManModel = `prop_air_dancer_01`
local activeTubeMen = {} -- This will store {prop = handle, soundName = "sound_id"}

-- Helper function to normalize a vector (make its length 1)
local function NormalizeVector(vec)
    local magnitude = #(vec)
    if magnitude > 0 then return vec / magnitude end
    return vector3(0.0, 0.0, 0.0)
end

-- This function cleans up all spawned props and sounds.
local function cleanup()
    if not isEffectActive then return end
    print("Tube Man Army: Effect ending. Cleaning up the inflatables.")
    for _, tubeManData in pairs(activeTubeMen) do
        if tubeManData.prop and DoesEntityExist(tubeManData.prop) then
            SetEntityAsMissionEntity(tubeManData.prop, false, true)
            DeleteEntity(tubeManData.prop)
        end
        if tubeManData.soundName and exports.xsound:soundExists(tubeManData.soundName) then
            exports.xsound:Destroy(tubeManData.soundName)
        end
    end
    activeTubeMen = {}
    isEffectActive = false
end

RegisterNetEvent('chaos:tubeManArmy')
AddEventHandler('chaos:tubeManArmy', function(name, type, duration)
    if isEffectActive then
        exports.chaos:AddEffectToUI(name, type, duration)
        return
    end

    isEffectActive = true
    exports.chaos:AddEffectToUI(name, type, duration)
    print("Starting 'Tube Man Army' effect.")

    Citizen.CreateThread(function()
        -- 1. Load the model and sound.
        RequestModel(tubeManModel)
        while not HasModelLoaded(tubeManModel) do Citizen.Wait(10) end
        
        -- 2. Spawn the army in a circle around the player.
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local spawnRadius = 25.0
        local armySize = 15

        for i = 1, armySize do
            local angle = (i / armySize) * 2 * math.pi
            local spawnX = playerCoords.x + spawnRadius * math.cos(angle)
            local spawnY = playerCoords.y + spawnRadius * math.sin(angle)
            local foundGround, groundZ = GetGroundZFor_3dCoord(spawnX, spawnY, playerCoords.z + 10.0, false)
            
            if foundGround then
                local tubeMan = CreateObject(tubeManModel, spawnX, spawnY, groundZ, true, true, true)
                PlaceObjectOnGroundProperly(tubeMan)

                -- Play a blower sound from each tube man
                local soundName = "blower_" .. tubeMan
                -- ASSUMPTION: You have a "blower.ogg" file in your chaos/sounds/ folder
                exports.xsound:PlayUrlPos(soundName, "sounds/blower.ogg", 0.4, GetEntityCoords(tubeMan), true)
                exports.xsound:Distance(soundName, 40.0)

                table.insert(activeTubeMen, { prop = tubeMan, soundName = soundName })
            end
            Citizen.Wait(100) -- Stagger the spawning slightly to avoid hitches
        end

        -- 3. Main logic loop to make them chase the player.
        while exports.chaos:IsEffectActive(name) do
            Citizen.Wait(0)
            local pCoords = GetEntityCoords(PlayerPedId())
            local chaseSpeed = 5.0 -- How fast they glide towards the player

            for _, tubeManData in ipairs(activeTubeMen) do
                local prop = tubeManData.prop
                if DoesEntityExist(prop) then
                    local propCoords = GetEntityCoords(prop)
                    local direction = NormalizeVector(pCoords - propCoords)
                    
                    -- Set their velocity to move them towards the player
                    SetEntityVelocity(prop, direction.x * chaseSpeed, direction.y * chaseSpeed, direction.z * chaseSpeed)

                    -- Update the sound position to follow the prop
                    exports.xsound:Position(tubeManData.soundName, propCoords)
                end
            end
        end

        -- 4. Effect is over, run cleanup.
        cleanup()
        SetModelAsNoLongerNeeded(tubeManModel)
    end)
end)

-- Safety cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        cleanup()
    end
end)