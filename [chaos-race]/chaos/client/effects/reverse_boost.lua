RegisterNetEvent('chaos:reverseBoost')
AddEventHandler('chaos:reverseBoost', function(name, type, duration)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then return end
    PlaySoundFromEntity(-1, "BOOST_ACTIVATED", vehicle, "HUD_MINI_GAME_SOUNDSET", true, 0)
    exports.chaos:AddEffectToUI(name, type, duration)
    Citizen.CreateThread(function()
        local endTime = GetGameTimer() + duration
        while GetGameTimer() < endTime do
            local currentVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            if DoesEntityExist(currentVehicle) then
                ApplyForceToEntity(currentVehicle, 1, GetEntityForwardVector(currentVehicle).x * 2.0, GetEntityForwardVector(currentVehicle).y * 2.0, 0.0, 0.0, 0.0, 0.0, 0, true, true, true, false, true)
            else
                break
            end
            Citizen.Wait(50)
        end
        -- NOTE: This effect doesn't properly remove itself from the UI list in main.lua
        -- We will address this in a future refactor if needed.
        if not exports.chaos:IsEffectActive(name) then
            PlaySoundFromEntity(-1, "BOOST_END", vehicle, "HUD_MINI_GAME_SOUNDSET", true, 0)
        end
    end)
end)