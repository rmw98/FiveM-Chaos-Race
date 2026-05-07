-- File: chaos/client/effects/stunt_jump.lua
-- VERSION 21: Added a minimum height requirement for a successful jump.

-- =============================================================================
--                               CONFIGURATION
-- =============================================================================
local CONFIG = {
    -- --- Physics ---
    boostAmount         = 15.0,     -- How much extra speed to add for the jump.
    damageThreshold     = 20.0,     -- How much health the vehicle can lose before the jump is considered "failed".
    minHeightInFeet     = 15.0,     -- *** NEW: The minimum height in feet to be considered a success. ***

    -- --- Timings (in milliseconds) ---
    slowMoDuration      = 1500,     -- How long the slow-motion and cinematic camera are active.
    judgementDelay      = 2500,     -- How long to wait AFTER slow-mo ends before showing the UI.
    uiDisplayTime       = 4000,
    rampDespawnTime     = 10000     -- How long until the ramp is deleted.
}
-- =============================================================================


-- This is the reliable UI function using the "Wasted" style scaleform.
local function ShowStuntResult(isSuccess, distance, height)
    local title = isSuccess and "STUNT JUMP COMPLETED" or "STUNT JUMP FAILED"
    local sound = isSuccess and "Stunt_Jump_Complete" or "Stunt_Jump_Failed"
    local displayHeight = math.max(0, height)
    local statsText = string.format("Distance: %.2fft  Height: %.2fft", distance * 3.281, displayHeight * 3.281)

    local scaleform = RequestScaleformMovie("MP_BIG_MESSAGE_FREEMODE")
    while not HasScaleformMovieLoaded(scaleform) do Citizen.Wait(10) end
    
    BeginScaleformMovieMethod(scaleform, "SHOW_SHARD_WASTED_MP_MESSAGE")
    PushScaleformMovieMethodParameterString(title)
    PushScaleformMovieMethodParameterString(statsText)
    EndScaleformMovieMethod()
    
    local endTime = GetGameTimer() + CONFIG.uiDisplayTime
    while GetGameTimer() < endTime do
        DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255, 0)
        Citizen.Wait(0)
    end

    SetScaleformMovieAsNoLongerNeeded(scaleform)
    PlaySoundFrontend(-1, sound, "HUD_AWARDS", true)
end

RegisterNetEvent('chaos:forcedStunt')
AddEventHandler('chaos:forcedStunt', function(name, effectType, duration)
    exports.chaos:AddEffectToUI(name, effectType, duration)
    print("Starting 'Unscheduled Stunt' effect.")

    Citizen.CreateThread(function()
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= playerPed then return end

        SetEntityInvincible(playerPed, true)
        SetEntityInvincible(vehicle, true)

        local rampModel = `prop_mp_ramp_03`
        RequestModel(rampModel); while not HasModelLoaded(rampModel) do Citizen.Wait(10) end
        local spawnPos = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 15.0, -1.0)
        local ramp = CreateObject(rampModel, spawnPos.x, spawnPos.y, spawnPos.z, true, false, true)
        PlaceObjectOnGroundProperly(ramp)
        SetEntityHeading(ramp, GetEntityHeading(vehicle))
        SetModelAsNoLongerNeeded(rampModel)

        local startCoords = GetEntityCoords(vehicle)
        local startHeight = startCoords.z
        local peakHeight = startHeight
        local initialHealth = GetEntityHealth(vehicle)
        SetVehicleForwardSpeed(vehicle, GetEntitySpeed(vehicle) + CONFIG.boostAmount)
        
        local stuntCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        local camPos = GetOffsetFromEntityInWorldCoords(ramp, 10.0, -5.0, 3.0)
        SetCamCoord(stuntCam, camPos.x, camPos.y, camPos.z)
        RenderScriptCams(true, false, 0, true, true)
        SetTimeScale(0.3)

        local slowMoEndTime = GetGameTimer() + CONFIG.slowMoDuration
        while GetGameTimer() < slowMoEndTime do
            PointCamAtEntity(stuntCam, vehicle, 0.0, 0.0, 0.0, true)
            local currentZ = GetEntityCoords(vehicle).z
            if currentZ > peakHeight then
                peakHeight = currentZ
            end
            Citizen.Wait(0)
        end

        SetTimeScale(1.0)
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(stuntCam, true)
        if DoesEntityExist(vehicle) then SetEntityInvincible(vehicle, false) end
        
        Citizen.Wait(CONFIG.judgementDelay)

        local finalHealth = GetEntityHealth(vehicle)
        local endCoords = GetEntityCoords(vehicle)
        local heightAchievedInMeters = peakHeight - startHeight
        local heightAchievedInFeet = heightAchievedInMeters * 3.281
        local distance = #(endCoords - startCoords)
        
        -- *** THE FIX IS HERE: Added the height check to the success condition. ***
        local wasSuccess = DoesEntityExist(vehicle) 
                           and (finalHealth >= initialHealth - CONFIG.damageThreshold) 
                           and (heightAchievedInFeet >= CONFIG.minHeightInFeet)
        
        ShowStuntResult(wasSuccess, distance, heightAchievedInMeters)

        SetEntityInvincible(playerPed, false)
        Citizen.Wait(CONFIG.rampDespawnTime - CONFIG.slowMoDuration - CONFIG.judgementDelay)
        if DoesEntityExist(ramp) then
            NetworkFadeOutEntity(ramp, true, false); Citizen.Wait(500); DeleteEntity(ramp)
        end
    end)
end)