-- File: chaos/client/effects/need_for_speed.lua
-- VERSION 5: Player Kill Fix
-- Player has a 5-second grace period to be under the speed limit. This timer does not recover.

-- --- Configuration ---
local SPEED_THRESHOLD = 0.70 -- Player must stay above 70% of vehicle's max speed.
local GRACE_PERIOD_TOTAL = 5000 -- 5 seconds total.

-- --- Effect State ---
local isEffectActive = false
local gracePeriodRemaining = GRACE_PERIOD_TOTAL
local lastTick = 0
local tickingSoundId = -1

-- Helper function to get text width for the UI
function GetTextWidth(text, font, scale)
    BeginTextCommandGetWidth("STRING")
    AddTextComponentString(text)
    SetTextFont(font)
    SetTextScale(1.0, scale)
    return EndTextCommandGetWidth(true)
end

-- UI function with red/green background
local function ShowSpeedUI(currentSpeed, minSpeed, isBelowSpeed)
    local text = string.format("SPEED: %.0f | MIN: %.0f | GRACE PERIOD: %.1fs", currentSpeed, minSpeed, math.max(0, gracePeriodRemaining) / 1000)
    local bgColor

    if isBelowSpeed then
        bgColor = {r=180, g=20, b=20, a=200} -- Red background when below speed
    else
        bgColor = {r=0, g=90, b=20, a=190} -- Green background when safe
    end

    -- UI Style
    local font = 4
    local scale = 0.45
    local padding = 0.01
    local boxHeight = 0.04
    local position = { x = 0.5, y = 0.95 }

    -- Calculate width and draw background
    local boxWidth = GetTextWidth(text, font, scale) + padding
    DrawRect(position.x, position.y, boxWidth, boxHeight, bgColor.r, bgColor.g, bgColor.b, bgColor.a)

    -- Draw Text
    SetTextFont(font)
    SetTextScale(0.0, scale)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(2, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(position.x, position.y - (boxHeight / 2) + 0.004)
end

RegisterNetEvent('chaos:needForSpeed')
AddEventHandler('chaos:needForSpeed', function(name, effectType, duration)
    exports.chaos:AddEffectToUI(name, effectType, duration)
    
    if not isEffectActive then
        isEffectActive = true
        
        Citizen.CreateThread(function()
            gracePeriodRemaining = GRACE_PERIOD_TOTAL
            lastTick = GetGameTimer()
            tickingSoundId = GetSoundId()
            PlaySoundFrontend(tickingSoundId, "Bomb_Ticking_Sound_Loop_A", "GTAO_Speed_Convoy_Soundset", true)

            while exports.chaos:IsEffectActive(name) do
                Citizen.Wait(0)
                local playerPed = PlayerPedId()
                local vehicle = GetVehiclePedIsIn(playerPed, false)
                local vehModel = GetEntityModel(vehicle)

                if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == playerPed and not IsThisModelABoat(vehModel) and not IsThisModelAPlane(vehModel) then
                    local maxSpeed = GetVehicleModelEstimatedMaxSpeed(vehModel)
                    local minSpeed = maxSpeed * SPEED_THRESHOLD
                    local currentSpeedMps = GetEntitySpeed(vehicle)
                    
                    local tickDelta = GetGameTimer() - lastTick
                    lastTick = GetGameTimer()

                    local isBelowSpeed = currentSpeedMps < minSpeed

                    if isBelowSpeed then
                        gracePeriodRemaining = gracePeriodRemaining - tickDelta
                    end
                    
                    if gracePeriodRemaining <= 0 then
                        -- *** THE DEFINITIVE FIX IS HERE ***
                        StopSound(tickingSoundId)
                        ReleaseSoundId(tickingSoundId)
                        
                        -- 1. Get vehicle coordinates for the explosion
                        local coords = GetEntityCoords(vehicle)
                        
                        -- 2. Create a large, forceful explosion
                        AddExplosion(coords.x, coords.y, coords.z, 4, 10.0, true, false, 0.0)

                        -- 3. Explicitly kill the player to trigger the gamemanager's death event
                        SetEntityHealth(playerPed, 0)
                        
                        isEffectActive = false
                        return -- EXIT THE THREAD
                    end
                    
                    local currentSpeedMph = currentSpeedMps * 2.23694
                    local minSpeedMph = minSpeed * 2.23694
                    ShowSpeedUI(currentSpeedMph, minSpeedMph, isBelowSpeed)
                else
                    lastTick = GetGameTimer()
                end
            end

            -- This code is only reached if the player survives the full duration.
            StopSound(tickingSoundId)
            ReleaseSoundId(tickingSoundId)
            PlaySoundFrontend(-1, "Bomb_Disarmed", "GTAO_Speed_Convoy_Soundset", true)
            isEffectActive = false
        end)
    end
end)