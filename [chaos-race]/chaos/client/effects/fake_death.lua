-- File: chaos/client/effects/fake_death.lua
-- VERSION 9: The Definitive Explosion-Proof Fix

RegisterNetEvent('chaos:fakeDeath')
AddEventHandler('chaos:fakeDeath', function(name, type, duration)
    exports.chaos:AddEffectToUI(name, type, duration)

    Citizen.CreateThread(function()
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        local soundId = GetSoundId()

        -- 1. Make the player AND their vehicle invincible and EXPLOSION PROOF.
        -- This is the definitive fix. SetEntityProofs is stronger than SetEntityInvincible for this purpose.
        SetEntityInvincible(playerPed, true)
        SetEntityProofs(playerPed, false, false, true, false, false, false, false, false) -- [[ NEW LINE ]]

        if vehicle ~= 0 then
            SetEntityInvincible(vehicle, true)
            SetEntityProofs(vehicle, false, false, true, false, false, false, false, false) -- [[ NEW LINE ]]
        end

        -- 2. Trigger a visual "death" event
        if vehicle ~= 0 then
            AddExplosion(GetEntityCoords(vehicle), 4, 5.0, true, false, 1.0)
        else
            RequestAnimDict("mp_suicide")
            while not HasAnimDictLoaded("mp_suicide") do Citizen.Wait(10) end
            TaskPlayAnim(playerPed, "mp_suicide", "pistol", 8.0, -1.0, 1150, 1, 0, false, false, false)
            Citizen.Wait(750)
        end

        -- 3. Play the "Wasted" screen effects
        StartAudioScene("DEATH_SCENE")
        AnimpostfxPlay("DeathFailNeutralIn", 0, false)
        PlaySoundFrontend(soundId, "ScreenFlash", "WastedSounds", true)
        PlaySoundFrontend(soundId, "Bed", "WastedSounds", true)
        SetTimeScale(0.1)
        ShakeGameplayCam('DEATH_FAIL_IN_EFFECT_SHAKE', 1.0)
        Citizen.Wait(1500)
        SetTimeScale(1.0)
        
        -- 4. Display the "Wasted" message
        local scaleform = RequestScaleformMovie("MP_BIG_MESSAGE_FREEMODE")
        while not HasScaleformMovieLoaded(scaleform) do Citizen.Wait(10) end
        local subtitles = { "Just kidding, keep playing.", "lol u suck", "Did you really fall for that?", "~g~(You're fine, probably)" }
        local randomSubtitle = subtitles[math.random(#subtitles)]
        BeginScaleformMovieMethod(scaleform, "SHOW_SHARD_WASTED_MP_MESSAGE")
        PushScaleformMovieMethodParameterString("~r~WASTED")
        PushScaleformMovieMethodParameterString(randomSubtitle)
        EndScaleformMovieMethod()
        
        local timeToDisplayMessage = duration - 750 - 1250
        if timeToDisplayMessage < 1000 then timeToDisplayMessage = 1000 end
        
        local scaleformEndTime = GetGameTimer() + timeToDisplayMessage
        while GetGameTimer() < scaleformEndTime do
            DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255, 0)
            Citizen.Wait(0)
        end
        
        -- 5. Cleanup time!
        if DoesEntityExist(playerPed) then ClearPedTasksImmediately(playerPed) end
        AnimpostfxStopAll()
        StopAudioScene("DEATH_SCENE")
        StopGameplayCamShaking(true)
        ReleaseSoundId(soundId)
        SetScaleformMovieAsNoLongerNeeded(scaleform)

        -- Remove all protections from both player and vehicle to return to normal state
        SetEntityInvincible(playerPed, false)
        SetEntityProofs(playerPed, false, false, false, false, false, false, false, false) -- [[ NEW LINE ]]

        if vehicle ~= 0 and DoesEntityExist(vehicle) then
            SetEntityInvincible(vehicle, false)
            SetEntityProofs(vehicle, false, false, false, false, false, false, false, false) -- [[ NEW LINE ]]
        end
    end)
end)