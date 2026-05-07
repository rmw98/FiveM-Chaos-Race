-- File: chaos/client/effects/ibiza_2008.lua
-- This effect simulates a rave/club experience based on the song "Infinity 2008".

RegisterNetEvent('chaos:ibiza2008')
AddEventHandler('chaos:ibiza2008', function(name, type, duration)
    -- Prevent the effect from stacking if it's already active
    if exports.chaos:IsEffectActive(name) then return end

    -- Add the effect to the UI timer
    exports.chaos:AddEffectToUI(name, type, duration)
    print("Starting 'IBIZA 2008' effect.")

    -- This thread will manage all the visual and audio components of the effect.
    Citizen.CreateThread(function()
        -- --- CONFIGURATION ---
        local BPM = 128
        -- This path assumes you've created a 'sounds' folder inside your 'chaos' resource.
        local SOUND_FILE = "sounds/infinity.ogg" 
        local SOUND_VOLUME = 0.8
        local SHAKE_INTENSITY = 0.2
        local TIMECYCLE_BASE_STRENGTH = 0.7
        local TIMECYCLE_PULSE_STRENGTH = 1.0

        -- A list of psychedelic AnimPostFX effects, inspired by the single-player drug missions.
        local postFxList = {
            "DMT_flight_intro", "ChopVision", "Success_Neutral",
            "DrugsMichaelAliensFightIn", "HeistCelebPass", "PeyoteEndOut", "DMT_Flight"
        }
        local currentPostFx = nil

        -- A list of timecycle modifiers for intense color shifts and distortion.
        local timecycleList = {
            "spectator6", "drug_drive_blend01", "drug_drive_blend02",
            "drug_flying_01", "MP_Celeb_Win", "MP_Celeb_Lose", "ufo_deathray"
        }
        local currentTimecycle = nil

        -- Helper function to switch the main visual style to keep things interesting.
        local function switchVisuals()
            -- Clean up previous effects
            if currentPostFx and AnimpostfxIsRunning(currentPostFx) then
                AnimpostfxStop(currentPostFx)
            end
            if currentTimecycle then
                ClearTimecycleModifier()
            end

            -- Pick and apply new random effects
            currentPostFx = postFxList[math.random(#postFxList)]
            currentTimecycle = timecycleList[math.random(#timecycleList)]

            AnimpostfxPlay(currentPostFx, 0, false)
            SetTimecycleModifier(currentTimecycle)
            SetTimecycleModifierStrength(TIMECYCLE_BASE_STRENGTH)
        end

        -- --- EFFECT START ---
        local beatInterval = 60000 / BPM -- Calculate milliseconds per beat
        local nextBeatTime = GetGameTimer() + beatInterval
        local beatCounter = 0

        -- Start the initial visuals
        switchVisuals()

        -- Play the sound using xsound
        local soundName = "ibiza2008_sound_" .. math.random(1000)
        exports.xsound:PlayUrl(soundName, SOUND_FILE, SOUND_VOLUME, false)

        -- Main effect loop, runs as long as the effect is active in the UI
        while exports.chaos:IsEffectActive(name) do
            local gameTime = GetGameTimer()

            -- Check if it's time for the next beat
            if gameTime >= nextBeatTime then
                beatCounter = beatCounter + 1

                -- 1. The "Thump": A short, sharp camera shake on the beat.
                ShakeGameplayCam("ROAD_VIBRATION_SHAKE", SHAKE_INTENSITY)

                -- 2. The "Pulse": Quickly flash the timecycle intensity to full strength and back.
                -- This runs in its own tiny thread to not interrupt the main beat timer.
                Citizen.CreateThread(function()
                    SetTimecycleModifierStrength(TIMECYCLE_PULSE_STRENGTH)
                    Citizen.Wait(100) -- Hold the pulse for 100ms
                    -- Check if effect is still active before resetting strength
                    if exports.chaos:IsEffectActive(name) then
                        SetTimecycleModifierStrength(TIMECYCLE_BASE_STRENGTH)
                    end
                end)

                -- 3. The "Switch": Change the entire visual style every 16 beats (usually 4 bars in music).
                if beatCounter % 16 == 0 then
                    switchVisuals()
                end

                -- Schedule the next beat
                nextBeatTime = nextBeatTime + beatInterval
            end

            Citizen.Wait(0) -- Process every frame
        end

        -- --- EFFECT CLEANUP ---
        print("'IBIZA 2008' effect has ended. Cleaning up.")
        if currentPostFx and AnimpostfxIsRunning(currentPostFx) then
            AnimpostfxStop(currentPostFx)
        end
        ClearTimecycleModifier()
        StopGameplayCamShaking(true)
        AnimpostfxStopAll() -- A final safety net to clear any lingering effects.

        -- Stop the sound if it's still playing
        if exports.xsound:soundExists(soundName) then
            exports.xsound:Destroy(soundName)
        end
    end)
end)