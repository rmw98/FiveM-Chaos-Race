-- File: chaos/client/effects/drunk_driving.lua
-- This is a self-contained module for the "Drunk Driving" effect.

RegisterNetEvent('chaos:drunkCam')
AddEventHandler('chaos:drunkCam', function(name, type, duration)
    -- This effect has a loop that needs to check if it's already active.
    -- We use the exported function here.
    if not exports.chaos:IsEffectActive(name) then
        print("Starting 'Drunk Driving' effect for the first time.")
        ShakeGameplayCam('DRUNK_SHAKE', 1.0)
        
        Citizen.CreateThread(function()
            -- This loop runs as long as the effect is active.
            while exports.chaos:IsEffectActive(name) do
                local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                if DoesEntityExist(vehicle) then
                    local steerBias = math.random() > 0.5 and 1.80 or -1.80
                    SetVehicleSteerBias(vehicle, steerBias)
                    Citizen.Wait(math.random(750, 2000))
                    if DoesEntityExist(vehicle) then
                       SetVehicleSteerBias(vehicle, 0.0)
                    end
                    Citizen.Wait(math.random(500, 1000))
                else
                    Citizen.Wait(500)
                end
            end
            
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            if DoesEntityExist(vehicle) then
                SetVehicleSteerBias(vehicle, 0.0)
            end
            StopGameplayCamShaking(true)
            print("Last 'Drunk Driving' effect ended. Stopping effects.")
        end)
    end

    -- Add the effect to the UI. This happens EVERY time.
    exports.chaos:AddEffectToUI(name, type, duration)
end)