-- File: chaos/client/effects/detach_wheel.lua
-- VERSION 11: The Smart Check
-- Only detaches a front wheel if one is actually attached.

RegisterNetEvent('chaos:detachWheel')
AddEventHandler('chaos:detachWheel', function(name, type, duration)
    -- We add to the UI first so the player knows the effect was chosen.
    exports.chaos:AddEffectToUI(name, type, duration)

    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

    if vehicle ~= 0 and GetVehicleClass(vehicle) < 13 then

        -- *** THE NEW LOGIC IS HERE ***

        local attachedWheels = {}
        -- Check if the Front Left wheel (index 0) is intact.
        -- We check if it's NOT burst. If it's not burst, it's attached.
        if not IsVehicleTyreBurst(vehicle, 0, false) then
            table.insert(attachedWheels, 0)
        end
        -- Check if the Front Right wheel (index 1) is intact.
        if not IsVehicleTyreBurst(vehicle, 1, false) then
            table.insert(attachedWheels, 1)
        end

        -- Check if we found any attached wheels.
        if #attachedWheels > 0 then
            -- Randomly pick one of the available, attached wheels.
            local wheelToDetach = attachedWheels[math.random(#attachedWheels)]
            
            -- Use the confirmed working call to detach it.
            BreakOffVehicleWheel(vehicle, wheelToDetach, false, false)
            
            -- Play the sound since we know we're detaching something.
            SetVehicleTyreBurst(vehicle, wheelToDetach, true, 1000.0)
            PlaySoundFromEntity(-1, "Tyre_Bust", vehicle, "CAR_CRASH_SOUNDS", true, 0)

            print("Detached front wheel with index: " .. wheelToDetach)
        else
            -- If the 'attachedWheels' table is empty, it means both front wheels are already gone.
            print("Unscheduled Pit Stop: Both front wheels are already detached. Effect did nothing.")
        end
    end
end)