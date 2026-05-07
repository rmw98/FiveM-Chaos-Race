-- File: chaos/client/main.lua
-- This is the new core client script. It manages state, UI, and exports
-- helper functions for the individual effect scripts to use.

-- =================================================================
--                        CORE STATE & CONFIG
-- =================================================================
local activeEffects = {} -- This table holds the state for the UI

local UI_CONFIG = {
    font = 4,
    textScale = 0.35,
    padding = 0.008,
    boxHeight = 0.035,
    rightEdge = 0.985,
    startY = 0.25,
    spacing = 0.04,
    goodColor = { r = 20, g = 100, b = 20, a = 200 },
    badColor = { r = 120, g = 20, b = 20, a = 200 },
    progressColor = { r = 255, g = 255, b = 255, a = 60 }
}

-- =================================================================
--                   GLOBAL AI RELATIONSHIP SETUP (NEW)
-- =================================================================
-- This is a one-time setup for the entire resource, so it belongs here.
Citizen.CreateThread(function()
    print("Setting up global AI relationships for Cougars...")
    local cougarGroup = GetHashKey("COUGAR")
    local playerGroup = GetHashKey("PLAYER")
    SetRelationshipBetweenGroups(5, cougarGroup, playerGroup)
    SetRelationshipBetweenGroups(5, playerGroup, cougarGroup)
    print("AI Relationship: COUGAR group now HATES PLAYER group.")
end)

-- =================================================================
--                        HELPER FUNCTIONS
-- =================================================================

function GetTextWidth(text, font, scale)
    BeginTextCommandGetWidth("STRING")
    AddTextComponentString(text)
    SetTextFont(font)
    SetTextScale(1.0, scale)
    return EndTextCommandGetWidth(true)
end

-- =================================================================
--                  CORE FUNCTIONS (EXPORTED)
-- =================================================================

function AddEffectToUI(name, type, duration)
    local currentTime = GetGameTimer()
    local effectId = currentTime + math.random(1, 1000) 
    activeEffects[effectId] = {
        id = effectId, 
        name = name, 
        type = type, 
        startTime = currentTime,
        serverDuration = duration, 
        endTime = currentTime + ((duration == 0) and 5000 or duration)
    }
    print("Added new effect '" .. name .. "' with ID: " .. effectId)
    return effectId
end

function IsEffectActive(effectName)
    for _, effect in pairs(activeEffects) do
        if effect and effect.name == effectName then return true end
    end
    return false
end

-- Export the functions for other scripts in this resource to use.
exports('AddEffectToUI', AddEffectToUI)
exports('IsEffectActive', IsEffectActive)


-- =================================================================
--                  CONTEXT CHECKING (NEW)
-- =================================================================
-- This is core communication logic, not an effect, so it belongs here.
function GetPlayerContext()
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        local vehicleClass = GetVehicleClass(vehicle)
        if vehicleClass == 15 or vehicleClass == 16 then return 'plane'
        elseif vehicleClass == 14 then return 'boat'
        elseif vehicleClass == 13 then return 'foot'
        else return 'car' end
    else
        return 'foot'
    end
end

RegisterNetEvent('chaos:requestPlayerContext')
AddEventHandler('chaos:requestPlayerContext', function()
    local context = GetPlayerContext()
    TriggerServerEvent('chaos:sendPlayerContext', context)
end)


-- =================================================================
--                        UI DRAWING & LOOP
-- =================================================================
function DrawChaosUI(effect, y)
    local textWidth = GetTextWidth(effect.name, UI_CONFIG.font, UI_CONFIG.textScale)
    local boxWidth = textWidth + (UI_CONFIG.padding * 2)
    local boxCenterX = UI_CONFIG.rightEdge - (boxWidth / 2)
    local bgColor = (effect.type == 'good') and UI_CONFIG.goodColor or UI_CONFIG.badColor

    DrawRect(boxCenterX, y, boxWidth, UI_CONFIG.boxHeight, bgColor.r, bgColor.g, bgColor.b, bgColor.a)

    if effect.serverDuration > 100 then
        local progress = (effect.endTime - GetGameTimer()) / (effect.endTime - effect.startTime)
        if progress < 0 then progress = 0 end
        
        local progressWidth = boxWidth * progress
        local progressCenterX = (boxCenterX - (boxWidth / 2)) + (progressWidth / 2)
        DrawRect(progressCenterX, y, progressWidth, UI_CONFIG.boxHeight, UI_CONFIG.progressColor.r, UI_CONFIG.progressColor.g, UI_CONFIG.progressColor.b, UI_CONFIG.progressColor.a)
    end

    SetTextFont(UI_CONFIG.font)
    SetTextScale(UI_CONFIG.textScale, UI_CONFIG.textScale)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(2, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString(effect.name)
    DrawText(boxCenterX, y - (UI_CONFIG.boxHeight / 2) + 0.004)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local yOffset = UI_CONFIG.startY
        local currentTime = GetGameTimer()
        local currentActiveEffects = {}
        
        for id, effect in pairs(activeEffects) do
            if effect and currentTime <= effect.endTime then
                table.insert(currentActiveEffects, effect)
            else
                activeEffects[id] = nil
            end
        end

        for _, effect in ipairs(currentActiveEffects) do
            DrawChaosUI(effect, yOffset)
            yOffset = yOffset + UI_CONFIG.spacing
        end
    end
end)

-- This event is triggered by the gamemanager to clear all active chaos effects.
AddEventHandler('chaos:clearEffects', function()
    activeEffects = {}
    
    local playerPed = PlayerPedId()
    if DoesEntityExist(playerPed) then
        SetPedIsDrunk(playerPed, false)
    end
end)

print("Chaos Client CORE Script Loaded.")