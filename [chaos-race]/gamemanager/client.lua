-- File: resources/[chaos-race]/gamemanager/client.lua (v5.4 - Config Load Fix)

-- =================================================================
--                        CLIENT-SIDE RACE STATE
-- =================================================================
local hasPlayerBeenSpawned = false -- Our new flag to control the initial spawn
local isRaceActive = false
local finishRadius = 25.0
local startTime, destinationBlip, targetLocation, hasDiedThisRound, animCountdown = 0, nil, nil, false, { text = "", startTime = 0, duration = 0, r = 255, g = 255, b = 255, baseScale = 1.0 }
local currentLives = 0 -- We will get this from the server
local raceEndTimestamp = 0 -- 0 means the timer is not active
local isSpectating = false
local spectatorTargetIndex = 1
local spectatingActiveRacers = {}
local isGhostUIActive = false

-- =================================================================
--                   PLAYER SPAWN & STARTUP CONTROL
-- =================================================================

-- This is our main control loop. It will run constantly.
Citizen.CreateThread(function()
    while not hasPlayerBeenSpawned do
        -- Wait until the player is loaded AND our config file is ready.
        if NetworkIsPlayerActive(PlayerId()) and GM_CONFIG then
            
            -- This is our one-time spawn logic.
            DoScreenFadeOut(0)

            -- 1. Set the default player model from our config.
            local model = GM_CONFIG.DefaultPedModel
            RequestModel(model)
            while not HasModelLoaded(model) do Citizen.Wait(50) end
            
            SetPlayerModel(PlayerId(), model)
            SetPedDefaultComponentVariation(PlayerPedId())
            SetModelAsNoLongerNeeded(model)

            -- 2. Place the player at our lobby spawn.
            local spawn = GM_CONFIG.LobbySpawn
            RequestCollisionAtCoord(spawn.coords.x, spawn.coords.y, spawn.coords.z)
            while not HasCollisionLoadedAroundEntity(PlayerPedId()) do Citizen.Wait(50) end
            
            SetEntityCoords(PlayerPedId(), spawn.coords.x, spawn.coords.y, spawn.coords.z, false, false, false, true)
            SetEntityHeading(PlayerPedId(), spawn.heading)
            
            -- Make sure the player is alive and well.
            ResurrectPed(PlayerPedId())
            ClearPedTasksImmediately(PlayerPedId())
            
            -- 3. Fade the screen in and get the player ready for the race.
            ShutdownLoadingScreen()
            if not IsScreenFadedIn() then
                DoScreenFadeIn(1500)
            end
            FreezeEntityPosition(PlayerPedId(), true)

            -- 4. Tell the server we are ready. THIS IS THE ONLY PLACE WE SEND THIS EVENT.
            TriggerServerEvent('chaosrace:playerIsReady')
            print("Forced custom spawn complete. Player is ready.")

            -- 5. Set our flag to true so this logic never runs again.
            hasPlayerBeenSpawned = true
        end
        Citizen.Wait(100)
    end
end)

-- =================================================================
--                      EVENT HANDLERS
-- =================================================================

RegisterNetEvent('chaosrace:updateEndTimer')
AddEventHandler('chaosrace:updateEndTimer', function(durationInSeconds) -- Renamed for clarity
    -- THE FIX: Calculate the end timestamp based on the CLIENT'S local timer.
    raceEndTimestamp = GetGameTimer() + (durationInSeconds * 1000)
end)

RegisterNetEvent('chaosrace:hideEndTimer')
AddEventHandler('chaosrace:hideEndTimer', function()
    raceEndTimestamp = 0
end)

-- Find and REPLACE the chaosrace:enterSpectatorMode handler with this corrected version

RegisterNetEvent('chaosrace:enterSpectatorMode')
AddEventHandler('chaosrace:enterSpectatorMode', function(activeRacerIds, haunts)
    if isSpectating then return end

    print("Entering Spectator Mode.")
    isSpectating = true
    spectatingActiveRacers = activeRacerIds or {}
    spectatorTargetIndex = 1

    local playerPed = PlayerPedId()
    
    -- === THE FIX IS HERE ===
    SetEntityVisible(playerPed, false, false)
    SetEntityCollision(playerPed, false, false) -- Disable collision for the local player
    NetworkSetEntityInvisibleToNetwork(playerPed, true) -- Tell the network this entity is invisible
    -- =======================

    FreezeEntityPosition(playerPed, true)
    SetPlayerControl(PlayerId(), false, 0)

    if #spectatingActiveRacers > 0 and spectatingActiveRacers[spectatorTargetIndex] then
        local targetPlayer = GetPlayerFromServerId(spectatingActiveRacers[spectatorTargetIndex].id)
        if targetPlayer ~= -1 then
            NetworkSetInSpectatorMode(true, GetPlayerPed(targetPlayer))
        end
    end

    -- NEW: Show the Ghost UI
    SetNuiFocus(true, true)
    isGhostUIActive = true
    SendNUIMessage({
        action = "showUI",
        racers = activeRacerIds, -- We will update this to send names too
        haunts = haunts
    })
end)

-- Find and REPLACE the chaosrace:exitSpectatorMode handler with this corrected version

RegisterNetEvent('chaosrace:exitSpectatorMode')
AddEventHandler('chaosrace:exitSpectatorMode', function()
    -- NOTE: The guard clause `if not isSpectating then return end` has been INTENTIONALLY REMOVED.
    -- When the 'gamemanager' resource is restarted, the client-side 'isSpectating' variable resets to `false`,
    -- but the player's ped is still invisible and their controls are locked. Removing the check ensures
    -- that this function ALWAYS runs when called, guaranteeing a full player state reset.

    if isSpectating then
        print("Exiting Spectator Mode.")
    else
        -- This message is helpful for debugging and confirms the fix is working after a resource restart.
        print("Forcing player state reset from spectator mode (isSpectating flag was false).")
    end

    -- --- The rest of the function runs unconditionally to guarantee a clean state ---
    
    isSpectating = false
    spectatingActiveRacers = {}

    NetworkSetInSpectatorMode(false, nil)

    local playerPed = PlayerPedId()

    -- Reverse all changes from enterSpectatorMode
    SetEntityVisible(playerPed, true, false)
    SetEntityCollision(playerPed, true, true)
    NetworkSetEntityInvisibleToNetwork(playerPed, false)
    SetPlayerControl(PlayerId(), true, 0)
    
    -- Teleport back to the lobby spawn and freeze, ready for the next round.
    -- This is safe because the 'startRace' event will unfreeze and move the player if a round starts immediately.
    local spawn = GM_CONFIG.LobbySpawn
    SetEntityCoords(playerPed, spawn.coords.x, spawn.coords.y, spawn.z, false, false, false, true)
    SetEntityHeading(playerPed, spawn.heading)
    FreezeEntityPosition(playerPed, true)

    -- Hide the Ghost UI if it's open
    if isGhostUIActive then
        SetNuiFocus(false, false)
        isGhostUIActive = false
        SendNUIMessage({ action = "hideUI" })
    end
end)

RegisterNetEvent('chaosrace:updateSpectatorList')
AddEventHandler('chaosrace:updateSpectatorList', function(activeRacerIds)
    -- This event is only received by players who are already spectating.
    -- It just updates their list of available targets without re-entering spectator mode.
    if isSpectating then
        spectatingActiveRacers = activeRacerIds or {}
        -- If our current target is no longer in the list, reset to the first one
        local currentTargetStillActive = false
        for _, racerData in ipairs(spectatingActiveRacers) do
            -- We check if the ID from the racerData table matches our current target
            if GetPlayerFromServerId(racerData.id) == spectatorTargetIndex then
                currentTargetStillActive = true
                break
            end
        end
        if not currentTargetStillActive then
            spectatorTargetIndex = 1
        end
        print("Spectator target list updated.")

        -- NEW: Update the UI with the new racer list
        if isGhostUIActive then
            SendNUIMessage({
                action = "updateRacers",
                racers = activeRacerIds -- We will update this to send names too
            })
        end
    end
end)

RegisterNetEvent('chaosrace:setInvincible')
AddEventHandler('chaosrace:setInvincible', function()
    print("Setting local player as invincible.")
    SetEntityInvincible(PlayerPedId(), true)
end)

RegisterNetEvent('chaosrace:setVulnerable')
AddEventHandler('chaosrace:setVulnerable', function()
    print("Setting local player as vulnerable.")
    SetEntityInvincible(PlayerPedId(), false)
end)

RegisterNetEvent('chaosrace:forceReadyUp')
AddEventHandler('chaosrace:forceReadyUp', function()
    isRaceActive = false
    if destinationBlip ~= nil then RemoveBlip(destinationBlip); destinationBlip = nil end
    FreezeEntityPosition(PlayerPedId(), true)
    TriggerServerEvent('chaosrace:playerIsReady')
end)

RegisterNetEvent('chaosrace:startRace')
AddEventHandler('chaosrace:startRace', function(startPoint, endPoint, lives)
    isSpectating = false -- <<< ADD THIS SAFEGUARD

    SafeTeleport(startPoint.coords)
    animCountdown.text = "GO!"; animCountdown.startTime = GetGameTimer(); animCountdown.duration = 1500; animCountdown.baseScale = 2.0; animCountdown.r, animCountdown.g, animCountdown.b = 114, 204, 114
    PlaySoundFrontend(-1, "GO", "HUD_MINI_GAME_SOUNDSET", true)
    FreezeEntityPosition(PlayerPedId(), false)
    local foundGround, groundZ = GetGroundZFor_3dCoord(endPoint.coords.x, endPoint.coords.y, 1000.0, false)
    if foundGround then targetLocation = vector3(endPoint.coords.x, endPoint.coords.y, groundZ) else targetLocation = endPoint.coords end
    if destinationBlip ~= nil then RemoveBlip(destinationBlip) end
    destinationBlip = AddBlipForCoord(targetLocation.x, targetLocation.y, targetLocation.z)
    SetBlipSprite(destinationBlip, 1); SetBlipRoute(destinationBlip, true); SetBlipColour(destinationBlip, 5)
    isRaceActive = true; hasDiedThisRound = false; startTime = GetGameTimer()
    currentLives = lives
end)

RegisterNetEvent('chaosrace:endRace')
AddEventHandler('chaosrace:endRace', function()
    isRaceActive = false
    raceEndTimestamp = 0 -- Hide end timer when race ends
    if destinationBlip ~= nil then RemoveBlip(destinationBlip); destinationBlip = nil end
    FreezeEntityPosition(PlayerPedId(), true)
end)

RegisterNetEvent('chaosrace:updateCountdown')
AddEventHandler('chaosrace:updateCountdown', function(text, scale)
    animCountdown.text = text; animCountdown.startTime = GetGameTimer(); animCountdown.duration = 950; animCountdown.baseScale = scale
    animCountdown.r, animCountdown.g, animCountdown.b = 255, 235, 150
    PlaySoundFrontend(-1, "TIMER_COUNTDOWN", "HUD_MINI_GAME_SOUNDSET", true)
end)

RegisterNetEvent('chaosrace:resetPlayerState')
AddEventHandler('chaosrace:resetPlayerState', function()
    local playerPed = PlayerPedId()
    SetEntityHealth(playerPed, GetEntityMaxHealth(playerPed))
    SetPedArmour(playerPed, 100)
    SetPlayerWantedLevel(PlayerId(), 0, false)
    SetPlayerWantedLevelNow(PlayerId(), false)
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if vehicle ~= 0 then
        SetVehicleFixed(vehicle)
        SetVehicleDirtLevel(vehicle, 0.0)
    end
    ClearPedBloodDamage(playerPed)
    TriggerEvent('chaos:clearEffects')
end)

RegisterNetEvent('chaosrace:handleRespawn')
AddEventHandler('chaosrace:handleRespawn', function(livesRemaining)
    currentLives = livesRemaining
    local playerPed = PlayerPedId()
    local deathCoords = GetEntityCoords(playerPed)
    DoScreenFadeOut(800)
    Citizen.Wait(800)
    local found, spawnPoint = GetSafeCoordForPed(deathCoords.x + math.random(-20,20), deathCoords.y + math.random(-20,20), deathCoords.z, true, 16)
    if not found then spawnPoint = deathCoords + vector3(0.0, 0.0, 5.0) end
    RequestCollisionAtCoord(spawnPoint.x, spawnPoint.y, spawnPoint.z)
    SetEntityCoords(playerPed, spawnPoint.x, spawnPoint.y, spawnPoint.z, false, false, false, true)
    while not HasCollisionLoadedAroundEntity(playerPed) do Citizen.Wait(10) end
    ResurrectPed(playerPed)
    StopEntityFire(playerPed)
    ClearPedTasksImmediately(playerPed)
    hasDiedThisRound = false
    Citizen.Wait(500)
    DoScreenFadeIn(1000)
end)

-- =================================================================
--                         UI & DRAW THREAD
-- =================================================================

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if hasPlayerBeenSpawned then -- Only run race logic after we've been spawned
            local timer = GetGameTimer()
            if timer < animCountdown.startTime + animCountdown.duration then
                DrawAnimatedCountdownText(animCountdown.text, animCountdown.baseScale * (1.0 - ((timer - animCountdown.startTime) / animCountdown.duration)), animCountdown.r, animCountdown.g, animCountdown.b, 255)
            end
            DrawEndRaceTimer()

            if isRaceActive then
                local playerPed = PlayerPedId()
                if IsEntityDead(playerPed) and not hasDiedThisRound and not exports.chaos:IsEffectActive('Fake Death') then
                    hasDiedThisRound = true;
                    TriggerServerEvent('chaosrace:playerDied')
                end
                
                if isRaceActive then
                    local playerCoords = GetEntityCoords(playerPed)
                    if #(playerCoords - targetLocation) < finishRadius then
                        isRaceActive = false
                        TriggerServerEvent('chaosrace:playerFinished', (timer - startTime) / 1000.0)
                        if destinationBlip ~= nil then RemoveBlip(destinationBlip); destinationBlip = nil end
                    else
                        local elapsedTime = (timer - startTime) / 1000
                        local minutes, seconds = math.floor(elapsedTime / 60), math.floor(elapsedTime % 60)
                        DrawRaceTimer(minutes, seconds)
                        DrawLivesCounter()
                        DrawMarker(1, targetLocation.x, targetLocation.y, targetLocation.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, finishRadius * 2.0, finishRadius * 2.0, 1.0, 0, 255, 0, 100, false, false, 2, false, nil, nil, false)
                    end
                end
            end

            -- ADD THIS NEW BLOCK FOR SPECTATOR CONTROLS
            if isSpectating then
                -- Disable the standard game HUD
                HideHudAndRadarThisFrame()

                -- Show a little UI hint for the spectator
                SetTextFont(4)
                SetTextScale(0.4, 0.4)
                SetTextColour(255, 255, 255, 200)
                SetTextDropshadow(2, 0, 0, 0, 255)
                SetTextEntry("STRING")
                AddTextComponentString("SPECTATING\n~INPUT_CELLPHONE_LEFT~ / ~INPUT_CELLPHONE_RIGHT~ to switch player")
                DrawText(0.5, 0.9)

                -- Check for input to switch targets (Left/Right Arrow Keys)
                if IsControlJustReleased(0, 174) then -- Left Arrow
                    spectatorTargetIndex = spectatorTargetIndex - 1
                    if spectatorTargetIndex < 1 then spectatorTargetIndex = #spectatingActiveRacers end
                elseif IsControlJustReleased(0, 175) then -- Right Arrow
                    spectatorTargetIndex = spectatorTargetIndex + 1
                    if spectatorTargetIndex > #spectatingActiveRacers then spectatorTargetIndex = 1 end
                end

                -- If the target list is not empty, switch the camera
                if #spectatingActiveRacers > 0 then
                    local targetPlayer = GetPlayerFromServerId(spectatingActiveRacers[spectatorTargetIndex].id)
                    if targetPlayer ~= -1 then
                        NetworkSetInSpectatorMode(true, GetPlayerPed(targetPlayer))
                    end
                else
                    -- No one left to spectate, just idle
                    NetworkSetInSpectatorMode(false, nil)
                end
            end
        end
    end
end)

-- =================================================================
--                         HELPER FUNCTIONS
-- =================================================================

function GetTextWidth(text, font, scale)
    BeginTextCommandGetWidth("STRING")
    AddTextComponentString(text)
    SetTextFont(font)
    SetTextScale(1.0, scale)
    return EndTextCommandGetWidth(true)
end

function DrawEndRaceTimer()
    if raceEndTimestamp == 0 then return end

    local timeLeft = (raceEndTimestamp - GetGameTimer()) / 1000
    if timeLeft <= 0 then
        -- Once time is up, hide the timer.
        raceEndTimestamp = 0
        return
    end

    -- THE FIX: Format the time into MM:SS for clarity.
    local minutes = math.floor(timeLeft / 60)
    local seconds = math.floor(timeLeft % 60)
    local text = string.format("RACE ENDS IN: %02d:%02d", minutes, seconds)
    
    -- UI Style (Big, centered, and red to indicate urgency)
    SetTextFont(7) -- Pricedown font
    SetTextScale(1.2, 1.2)
    SetTextColour(220, 50, 50, 255)
    SetTextDropshadow(2, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(0.5, 0.15) -- Draw it below the main race timer
end

function DrawLivesCounter()
    if not isRaceActive or currentLives <= 0 then return end
    local hearts = "♥"
    local text = string.rep(hearts .. " ", currentLives)
    local font = 4; local scale = 0.4; local x = 0.03; local y = 0.02
    local r, g, b, a = 220, 50, 50, 255
    SetTextFont(font); SetTextScale(0.0, scale); SetTextColour(r, g, b, a)
    SetTextDropshadow(2, 0, 0, 0, 255); SetTextEdge(1, 0, 0, 0, 255)
    SetTextJustification(0); SetTextEntry("STRING"); AddTextComponentString(text)
    DrawText(x, y)
end

function DrawRaceTimer(minutes, seconds)
    local text = string.format("Time: %02d:%02d", minutes, seconds)
    local font = 4; local scale = 0.5; local padding = 0.01; local boxHeight = 0.04
    local position = { x = 0.5, y = 0.035 }; local bgColor = { r = 0, g = 0, b = 0, a = 180 }
    local textWidth = GetTextWidth(text, font, scale); local boxWidth = textWidth + (padding * 2)
    DrawRect(position.x, position.y, boxWidth, boxHeight, bgColor.r, bgColor.g, bgColor.b, bgColor.a)
    local textY = position.y - (boxHeight / 2) + 0.005
    SetTextFont(font); SetTextScale(0.0, scale); SetTextColour(255, 255, 255, 255); SetTextDropshadow(2, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255); SetTextCentre(true); SetTextEntry("STRING"); AddTextComponentString(text); DrawText(position.x, textY)
end

function SafeTeleport(coords)
    local playerPed = PlayerPedId(); FreezeEntityPosition(playerPed, true)
    DoScreenFadeOut(800); Citizen.Wait(800)
    RequestCollisionAtCoord(coords.x, coords.y, coords.z); SetEntityCoords(playerPed, coords.x, coords.y, coords.z, false, false, false, true)
    while not HasCollisionLoadedAroundEntity(playerPed) do RequestCollisionAtCoord(coords.x, coords.y, coords.z); Citizen.Wait(10) end
    DoScreenFadeIn(800)
end

function DrawAnimatedCountdownText(text, scale, r, g, b, alpha) SetTextFont(7); SetTextProportional(1); SetTextScale(scale, scale); SetTextColour(r, g, b, alpha); SetTextDropshadow(2, 0, 0, 0, 255); SetTextEdge(1, 0, 0, 0, 255); SetTextCentre(true); SetTextEntry("STRING"); AddTextComponentString(text); DrawText(0.5, 0.4) end
RegisterNetEvent('chaosrace:getClientCoords')
AddEventHandler('chaosrace:getClientCoords', function()
    -- Get our own ped and its current, accurate coordinates.
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)

    -- Send the accurate data back to the server.
    TriggerServerEvent('chaosrace:returnClientCoords', coords, heading)
end)
RegisterNetEvent('chaosrace:printCoordsToConsole')
AddEventHandler('chaosrace:printCoordsToConsole', function(coordsStr, headingStr)
    -- The print() function on the client side prints to the F8 console.
    print(coordsStr)
    print(headingStr)
end)
RegisterNUICallback('hideUI', function(data, cb)
    SetNuiFocus(false, false)
    isGhostUIActive = false
    cb({ ok = true })
end)

RegisterNUICallback('purchaseHaunt', function(data, cb)
    if data.targetServerId and data.hauntName then
        -- We will create this server event in the next task
        TriggerServerEvent('haunts:triggerEffect', data.targetServerId, data.hauntName)
        cb({ success = true })
    else
        cb({ success = false })
    end
end)

RegisterNetEvent('chaosrace:forceUnfreeze')
AddEventHandler('chaosrace:forceUnfreeze', function()
    FreezeEntityPosition(PlayerPedId(), false)
end)

RegisterNetEvent('chaosrace:clientSetPlayerModel')
AddEventHandler('chaosrace:clientSetPlayerModel', function(playerServerId, modelHash)
    local targetPlayer = GetPlayerFromServerId(playerServerId)
    if targetPlayer == -1 then return end
    
    -- This event is received by EVERYONE.
    -- Each client will now apply the model change for the target player.
    RequestModel(modelHash)
    Citizen.CreateThread(function()
        local timeout = 200
        while not HasModelLoaded(modelHash) and timeout > 0 do
            timeout = timeout - 1
            Citizen.Wait(10)
        end
        if HasModelLoaded(modelHash) then
            SetPlayerModel(targetPlayer, modelHash)
            SetPedDefaultComponentVariation(GetPlayerPed(targetPlayer)) -- IMPORTANT: Apply default clothes
        end
        SetModelAsNoLongerNeeded(modelHash)
    end)
end)

RegisterNetEvent('chaosrace:setFriendlyFire')
AddEventHandler('chaosrace:setFriendlyFire', function(enabled)
    -- This is a global setting that helps enforce the PvP state
    NetworkSetFriendlyFireOption(enabled)
    
    -- This applies the setting specifically to our player's ped
    SetCanAttackFriendly(PlayerPedId(), enabled, true)

    -- A little print message to confirm it's working in the F8 console
    if enabled then
        print("PvP has been ENABLED by the server.")
    else
        print("PvP has been DISABLED by the server.")
    end
end)
