-- File: chaos/client/effects/news_team.lua
-- Spawns a news helicopter that follows the player with a cinematic camera and a "Breaking News" overlay.

local heli, pilot, heliCam, scaleform = 0, 0, 0, 0
local isNewsTeamActive = false

-- A list of text pairs for the news overlay. {Header, Sub-header}
local breakingNewsTexts = {
    {"LIVE", "HIGH-SPEED CHASE IN PROGRESS"},
    {"WEEZEL NEWS", "RACER CAUSES CHAOS ACROSS LOS SANTOS"},
    {"LIVE", "WILL THEY MAKE IT TO THE FINISH?"},
    {"WEEZEL NEWS", "RACE OFFICIALS HAVE LOST CONTROL"},
    {"LIVE", "UNBELIEVABLE SCENES ON THE HIGHWAY"},
    {"WEEZEL NEWS", "THIS IS MADNESS!"}
}

-- This function handles all cleanup to prevent leftover cameras or entities.
local function cleanup()
    if not isNewsTeamActive then return end
    print("News Team: Cleaning up resources.")

    RenderScriptCams(false, true, 500, true, true)
    if DoesCamExist(heliCam) then DestroyCam(heliCam, true) end
    if DoesEntityExist(pilot) then
        SetEntityAsMissionEntity(pilot, false, true)
        DeleteEntity(pilot)
    end
    if DoesEntityExist(heli) then
        SetEntityAsMissionEntity(heli, false, true)
        DeleteEntity(heli)
    end
    if scaleform ~= 0 then SetScaleformMovieAsNoLongerNeeded(scaleform) end
    
    heli, pilot, heliCam, scaleform, isNewsTeamActive = 0, 0, 0, 0, false
end

RegisterNetEvent('chaos:newsTeam')
AddEventHandler('chaos:newsTeam', function(name, type, duration)
    -- Don't start a new one if it's already running, just let the UI handle the timer.
    if isNewsTeamActive then
        exports.chaos:AddEffectToUI(name, type, duration)
        return
    end
    
    isNewsTeamActive = true
    exports.chaos:AddEffectToUI(name, type, duration)
    print("News Team: Starting effect.")

    Citizen.CreateThread(function()
        local playerPed = PlayerId()

        -- 1. Load all required models and the scaleform
        local heliModel = GetHashKey("FROGGER")
        local pilotModel = GetHashKey("s_m_m_pilot_01")
        RequestModel(heliModel); RequestModel(pilotModel)
        scaleform = RequestScaleformMovie("breaking_news")
        while not HasModelLoaded(heliModel) or not HasModelLoaded(pilotModel) or not HasScaleformMovieLoaded(scaleform) do
            Citizen.Wait(10)
        end

        -- 2. Spawn the helicopter and the pilot
        local spawnPos = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 20.0, 40.0, 60.0)
        heli = CreateVehicle(heliModel, spawnPos.x, spawnPos.y, spawnPos.z, GetEntityHeading(PlayerPedId()), true, true)
        pilot = CreatePedInsideVehicle(heli, 26, pilotModel, -1, true, true)
        SetVehicleEngineOn(heli, true, true, false)
        SetHeliBladesSpeed(heli, 1.0)
        SetEntityInvincible(heli, true); SetEntityInvincible(pilot, true)
        SetPedKeepTask(pilot, true)

        -- 3. Set up the camera
        heliCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        AttachCamToEntity(heliCam, heli, 0.0, -2.5, -1.2, true) -- Attach camera to the front/bottom of heli
        SetCamFov(heliCam, 75.0)
        
        -- 4. Set up the news UI
        local newsText = breakingNewsTexts[math.random(#breakingNewsTexts)]
        BeginScaleformMovieMethod(scaleform, "SET_TEXT")
        ScaleformMovieMethodAddParamPlayerNameString(newsText[1])
        ScaleformMovieMethodAddParamPlayerNameString(newsText[2])
        EndScaleformMovieMethod()

        -- 5. Main loop that runs for the duration of the effect
        while exports.chaos:IsEffectActive(name) do
            local target = IsPedInAnyVehicle(PlayerPedId(), false) and GetVehiclePedIsIn(PlayerPedId(), false) or PlayerPedId()
            
            -- Keep the pilot chasing the player
            TaskHeliChase(pilot, target, 15.0, 15.0, 20.0)
            -- Keep the camera pointed at the player
            PointCamAtEntity(heliCam, target, 0.0, 0.0, 0.0, true)
            
            -- Render the custom camera and the UI
            RenderScriptCams(true, false, 0, true, true)
            DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255, 0)

            Citizen.Wait(0)
        end

        -- 6. Effect has finished, run the cleanup.
        cleanup()
    end)
end)

-- Ensure cleanup runs if the resource is stopped
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        cleanup()
    end
end)