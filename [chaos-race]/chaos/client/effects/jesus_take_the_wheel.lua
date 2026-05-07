-- File: chaos/client/effects/jesus_take_the_wheel.lua
-- VERSION 5: Aggressive Taxi AI & Blip Color Fix
-- Jesus takes the wheel, locks the player in the passenger seat, and drives like a maniac to a random location.

-- --- Configuration ---
local JESUS_MODEL = `u_m_m_jesus_01`
-- This is a bitmask combining multiple flags for aggressive, law-ignoring driving.
local AGGRESSIVE_DRIVING_STYLE = 1074528293 
local DRIVING_SPEED = 50.0   -- Drive at a high speed (m/s)

local RANDOM_DESTINATIONS = {
    { name = "Top of Mt. Chiliad", coords = vector3(455.1, 5573.5, 781.0) },
    { name = "Altruist Cult Camp", coords = vector3(-1182.1, 4926.8, 221.0) },
    { name = "El Gordo Lighthouse", coords = vector3(3333.9, 5178.5, 20.3) },
    { name = "Humane Labs", coords = vector3(3617.7, 3737.5, 28.7) },
    { name = "Fort Zancudo", coords = vector3(-2267.89, 3121.04, 32.5) }
}

-- --- Effect State ---
local isEffectActive = false
local jesusPed = 0

-- Helper function to find the furthest destination from the player
local function getFurthestDestination(playerCoords)
    local furthestDist = -1.0
    local furthestDest = nil

    for _, dest in ipairs(RANDOM_DESTINATIONS) do
        local distance = #(playerCoords - dest.coords)
        if distance > furthestDist then
            furthestDist = distance
            furthestDest = dest.coords
        end
    end
    return furthestDest
end

RegisterNetEvent('chaos:jesusTakeTheWheel')
AddEventHandler('chaos:jesusTakeTheWheel', function(name, effectType, duration)
    if isEffectActive then return end
    
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= playerPed or IsThisModelAPlane(GetEntityModel(vehicle)) or IsThisModelABoat(GetEntityModel(vehicle)) then
        return
    end

    isEffectActive = true
    exports.chaos:AddEffectToUI(name, effectType, duration)
    print("Starting 'Jesus Take The Wheel' effect.")

    Citizen.CreateThread(function()
        RequestModel(JESUS_MODEL)
        while not HasModelLoaded(JESUS_MODEL) do Citizen.Wait(10) end
        
        if not IsVehicleSeatFree(vehicle, 0) then
            TaskLeaveVehicle(GetPedInVehicleSeat(vehicle, 0), vehicle, 4160)
            Citizen.Wait(500)
        end
        SetPedIntoVehicle(playerPed, vehicle, 0)

        jesusPed = CreatePedInsideVehicle(vehicle, 4, JESUS_MODEL, -1, true, true)
        SetEntityInvincible(jesusPed, true)
        SetPedKeepTask(jesusPed, true)
        SetModelAsNoLongerNeeded(JESUS_MODEL)

        local destination = getFurthestDestination(GetEntityCoords(playerPed))
        
        -- Create a temporary blip for the destination
        local destBlip = AddBlipForCoord(destination.x, destination.y, destination.z)
        -- *** BLIP COLOR FIX: Set to standard GPS blue (38) ***
        SetBlipColour(destBlip, 38)
        SetBlipRoute(destBlip, true)

        -- *** DRIVING AI FIX: Use the aggressive driving style bitmask ***
        TaskVehicleDriveToCoord(jesusPed, vehicle, destination.x, destination.y, destination.z, DRIVING_SPEED, 0, GetEntityModel(vehicle), AGGRESSIVE_DRIVING_STYLE, 15.0, true)

        -- Main loop to keep the player locked in
        while exports.chaos:IsEffectActive(name) do
            Citizen.Wait(0)
            if GetVehiclePedIsIn(PlayerPedId(), false) == vehicle then
                DisableControlAction(0, 75, true) -- INPUT_VEH_EXIT
            else
                break
            end
        end

        -- Cleanup
        print("'Jesus Take The Wheel' has ended.")
        if DoesBlipExist(destBlip) then RemoveBlip(destBlip) end
        ClearGpsPlayerWaypoint()

        if DoesEntityExist(jesusPed) then
            TaskLeaveVehicle(jesusPed, vehicle, 4160)
            Citizen.Wait(2000)
            SetEntityAsMissionEntity(jesusPed, false, true)
            DeleteEntity(jesusPed)
        end
        
        isEffectActive = false
        jesusPed = 0
    end)
end)