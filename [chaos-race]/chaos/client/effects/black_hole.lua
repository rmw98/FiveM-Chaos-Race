-- File: chaos/client/effects/black_hole.lua (v3 - Velocity Control)
-- Creates a black hole that pulls in nearby entities and grows over time.

local isBlackHoleActive = false
local blackHolePos = nil
local currentRadius = 0.0

-- Helper function to normalize vectors
local function NormalizeVector(vec)
    local magnitude = #(vec)
    if magnitude > 0 then return vec / magnitude end
    return vector3(0.0, 0.0, 0.0)
end

-- Cleanup function
local function cleanup()
    if not isBlackHoleActive then return end
    print("Black Hole: Cleaning up.")
    StopGameplayCamShaking(true)
    isBlackHoleActive = false
    blackHolePos = nil
    currentRadius = 0.0
end

RegisterNetEvent('chaos:blackHole')
AddEventHandler('chaos:blackHole', function(name, type, duration)
    if isBlackHoleActive then
        exports.chaos:AddEffectToUI(name, type, duration)
        return
    end

    isBlackHoleActive = true
    exports.chaos:AddEffectToUI(name, type, duration)
    print("Black Hole: Starting effect (Velocity Control).")

    Citizen.CreateThread(function()
        local playerPed = PlayerPedId()
        
        -- 1. Determine a spawn position, ensuring it's not too close to the player.
        local playerPos = GetEntityCoords(playerPed)
        local offsetX = math.random(100, 200) * (math.random(0, 1) == 0 and -1 or 1)
        local offsetY = math.random(100, 200) * (math.random(0, 1) == 0 and -1 or 1)
        
        blackHolePos = vector3(
            playerPos.x + offsetX,
            playerPos.y + offsetY,
            playerPos.z + math.random(60, 120) -- Spawn it in the air
        )
        currentRadius = 0.1

        -- 2. Main effect loop.
        while exports.chaos:IsEffectActive(name) do
            -- Grow the black hole's radius more slowly.
            if currentRadius < 150.0 then
                currentRadius = currentRadius + (0.15 * (GetFrameTime() * 100))
            end

            -- Draw the visual sphere.
            DrawSphere(blackHolePos.x, blackHolePos.y, blackHolePos.z, currentRadius, 0, 0, 0, 0.4)
            -- Drastically reduced camera shake intensity.
            ShakeGameplayCam("DRUNK_SHAKE", currentRadius / 1500.0)

            -- 3. Apply physics to nearby entities.
            for _, veh in ipairs(GetGamePool('CVehicle')) do
                if DoesEntityExist(veh) then
                    local vehPos = GetEntityCoords(veh)
                    local distance = #(vehPos - blackHolePos)

                    if distance < 400.0 then
                        -- >>> THE NEW VELOCITY-BASED LOGIC IS HERE <<<

                        -- Calculate the direction towards the black hole.
                        local direction = NormalizeVector(blackHolePos - vehPos)
                        
                        -- Calculate the strength of the pull. It gets stronger closer to the center.
                        -- The 15.0 is a multiplier we can easily tune. Let's start low.
                        local pullStrength = (400.0 - distance) / 15.0
                        
                        -- Get the vehicle's current velocity.
                        local currentVelocity = GetEntityVelocity(veh)
                        
                        -- Add the pull force to the current velocity.
                        local newVelocity = currentVelocity + (direction * pullStrength * GetFrameTime())
                        
                        -- Apply the new velocity. This is a much smoother "pull" than a physical force.
                        SetEntityVelocity(veh, newVelocity.x, newVelocity.y, newVelocity.z)

                        -- If a non-player vehicle enters the event horizon, delete it.
                        if distance < currentRadius and GetPedInVehicleSeat(veh, -1) ~= PlayerPedId() then
                            SetEntityAsMissionEntity(veh, false, true)
                            DeleteEntity(veh)
                        end
                    end
                end
            end
            
            Citizen.Wait(0)
        end
        
        -- 4. Effect timer finished, run cleanup.
        cleanup()
    end)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        cleanup()
    end
end)