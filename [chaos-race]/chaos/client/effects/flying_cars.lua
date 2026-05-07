-- File: chaos/client/effects/flying_cars.lua
-- VERSION 11: The correct flight model. Uses a fixed top speed and pitch-based lift.

-- --- CONTROLS ---
-- W / R2 (Accelerate): Engage Thrusters
-- A / D (Steer):       Turn Left / Right (Yaw)
-- Numpad 8:            Pitch Down (Dive)
-- Numpad 5:            Pitch Up (Climb/Generate Lift)
-- Numpad 4:            Roll Left
-- Numpad 6:            Roll Right
-- ----------------

-- --- TUNING VALUES ---
local targetFlySpeed = 35.0  -- The top speed in the air (in m/s). A fast car is ~50. This is a balanced value.
local pitchToLiftRatio = 2.0 -- How much upward force is applied when you pitch the nose up.
local initialLift = 3.0      -- A powerful burst to get off the ground.
local turnSpeed = 1.0
local pitchSpeed = 0.8
local rollSpeed = 1.2

-- Helper functions to apply/remove invincibility
local function onEffectStart(playerPed, vehicle)
    print("Flying Cars: Applying invincibility.")
    SetEntityInvincible(playerPed, true)
    if vehicle ~= 0 then SetEntityInvincible(vehicle, true) end
end

local function onEffectEnd(playerPed, vehicle)
    print("Flying Cars: Removing invincibility.")
    SetEntityInvincible(playerPed, false)
    if vehicle ~= 0 and DoesEntityExist(vehicle) then SetEntityInvincible(vehicle, false) end
end

local isFlyingCarsLoopActive = false

RegisterNetEvent('chaos:flyingCars')
AddEventHandler('chaos:flyingCars', function(name, effectType, duration)
    exports.chaos:AddEffectToUI(name, effectType, duration)
    
    if not isFlyingCarsLoopActive then
        isFlyingCarsLoopActive = true
        print("Flying Cars: Loop not active, starting new one.")

        Citizen.CreateThread(function()
            local playerPed = PlayerPedId()
            local initialVehicle = GetVehiclePedIsIn(playerPed, false)
            onEffectStart(playerPed, initialVehicle)
            
            while exports.chaos:IsEffectActive(name) do
                Citizen.Wait(0)
                local currentVehicle = GetVehiclePedIsIn(playerPed, false)
                
                if currentVehicle ~= initialVehicle then
                    onEffectEnd(playerPed, initialVehicle)
                    initialVehicle = currentVehicle
                    onEffectStart(playerPed, initialVehicle)
                end
                
                if currentVehicle ~= 0 and GetPedInVehicleSeat(currentVehicle, -1) == playerPed then
                    local vehicleClass = GetVehicleClass(currentVehicle)
                    
                    if vehicleClass ~= 15 and vehicleClass ~= 16 and vehicleClass ~= 14 then
                        if IsControlPressed(2, 71) then -- INPUT_VEH_ACCELERATE (W / R2)
                            
                            -- *** THE NEW SPEED-LIMITED FLIGHT MODEL ***
                            if not IsVehicleOnAllWheels(currentVehicle) then
                                -- In the air: Set a fixed forward speed. No more infinite acceleration!
                                SetVehicleForwardSpeed(currentVehicle, targetFlySpeed)
                                
                                -- Apply lift ONLY when the player is pitching up.
                                local lift = 0.0
                                if IsControlPressed(0, 111) then -- Numpad 5 (Pitch Up)
                                    lift = pitchToLiftRatio
                                end
                                ApplyForceToEntity(currentVehicle, 1, 0.0, 0.0, lift, 0.0, 0.0, 0.0, 0, false, true, true, false, true)

                            else
                                -- On the ground: Apply a burst of lift to take off. Normal car acceleration applies.
                                ApplyForceToEntity(currentVehicle, 1, 0.0, 0.0, initialLift, 0.0, 0.0, 0.0, 0, true, true, true, false, true)
                            end

                            -- Rotational controls are always active when accelerating.
                            local rot = GetEntityRotation(currentVehicle, 2)
                            local newRot = vector3(rot.x, rot.y, rot.z)

                            if IsControlPressed(0, 111) then newRot = newRot + vector3(pitchSpeed, 0.0, 0.0) end
                            if IsControlPressed(0, 112) then newRot = newRot - vector3(pitchSpeed, 0.0, 0.0) end
                            if IsControlPressed(0, 108) then newRot = newRot + vector3(0.0, rollSpeed, 0.0) end
                            if IsControlPressed(0, 109) then newRot = newRot - vector3(0.0, rollSpeed, 0.0) end
                            if IsControlPressed(2, 64) then newRot = newRot - vector3(0.0, 0.0, turnSpeed) end
                            if IsControlPressed(2, 63) then newRot = newRot + vector3(0.0, 0.0, turnSpeed) end

                            SetEntityRotation(currentVehicle, newRot.x, newRot.y, newRot.z, 2, true)
                        end
                    end
                end
            end

            print("Flying Cars: Effect has ended. Cleaning up and resetting loop flag.")
            onEffectEnd(playerPed, GetVehiclePedIsIn(playerPed, false))
            isFlyingCarsLoopActive = false
        end)
    else
        print("Flying Cars: Loop is already active. Timer extended.")
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        local playerPed = PlayerPedId()
        onEffectEnd(playerPed, GetVehiclePedIsIn(playerPed, false))
    end
end)