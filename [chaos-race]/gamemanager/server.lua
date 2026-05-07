-- Chaos Race Game Manager - server.lua (v5.4 - Spectator Logic)

-- All configuration is now loaded from shared/config.lua

-- GAME STATE
local gameState = 'WAITING'
local playersInRound = {}
local finishers = {}
local playerReadyStatus = {}
local playerLives = {}
local raceEndTimer = { isActive = false, endTime = 0 }
local playersSpectating = {}
local playerData = {}
local STARTING_CASH = 500

-- Helper Functions
function ResetPlayerState(source) TriggerClientEvent('chaosrace:resetPlayerState', source) end
function GetOrdinal(n) local s = {"th", "st", "nd", "rd"}; local v = n%100; return tostring(n) .. (s[(v-20)%10] or s[v] or s[1]); end

-- Add this to the Helper Functions section
function RefreshHauntsList()
    local chaosEffects = exports.chaos:getChaosEffects()
    availableHaunts = {} -- Clear the old list
    if chaosEffects then
        for _, effect in ipairs(chaosEffects) do
            if effect.cost and effect.cost > 0 then
                -- Only add the data the UI needs: name and cost
                table.insert(availableHaunts, { name = effect.name, cost = effect.cost })
            end
        end
    end
    print("Refreshed Haunts list. Found " .. #availableHaunts .. " buyable haunts.")
end

function AwardMoney(source, amount)
    local safeKey = tostring(source)
    local license = GetPlayerIdentifier(source, 0) -- Get the player's license identifier

    if not playerData[license] then
        print("ERROR: Tried to award money to a player with no loaded data: " .. GetPlayerName(source))
        return
    end

    playerData[license].money = (playerData[license].money or 0) + amount
    TriggerClientEvent('chat:addMessage', source, { color = {50, 200, 50}, args = {"[Chaos Cash]", string.format("You have been awarded $%d!", amount)} })
    TriggerClientEvent('chat:addMessage', source, { color = {200, 200, 50}, args = {"[Chaos Cash]", string.format("New Balance: $%d", playerData[license].money)} })
end

-- Core Game Loop Functions
function TryStartGame()
    if gameState ~= 'WAITING' then return end
    local players = GetPlayers()
    if #players < 1 then return end
    local readyPlayers = 0
    for _, p in ipairs(players) do if playerReadyStatus[tostring(p)] then readyPlayers = readyPlayers + 1 end end
    if #players > 0 and #players == readyPlayers then InitiateCountdown() end
end

function InitiateCountdown()
    gameState = 'POST_ROUND'
    local timeBetweenRounds = 5
    print("All players ready. Starting round in " .. timeBetweenRounds .. " seconds.")
    Citizen.CreateThread(function()
        for i = timeBetweenRounds, 1, -1 do
            TriggerClientEvent('chaosrace:updateCountdown', -1, tostring(i), 1.5)
            Citizen.Wait(1000)
        end
        StartNewRound()
    end)
end

function StartNewRound()
    -- ================== NEW AND IMPROVED RESET LOGIC ==================
    print("Forcing all players to exit spectator mode and unfreeze for new round.")
    TriggerClientEvent('chaosrace:exitSpectatorMode', -1) -- Tell EVERYONE to exit spectator mode
    TriggerClientEvent('chaosrace:forceUnfreeze', -1)   -- Tell EVERYONE to unfreeze their character
    
    TriggerClientEvent('chaosrace:setVulnerable', -1)
    -- ================================================================

    gameState = 'IN_RACE'
    playersInRound, finishers, playerReadyStatus, playerLives, playersSpectating = {}, {}, {}, {}, {}
    raceEndTimer = { isActive = false, endTime = 0 }
    TriggerClientEvent('chaosrace:hideEndTimer', -1)
    
    local locations = {
        {name = "TEST START", coords = vector3(-731.07, -151.08, 36.52)},
        {name = "TEST FINISH", coords = vector3(-784.85, -66.02, 37.30)}
    }
    local startIndex, endIndex = math.random(1, #locations), math.random(1, #locations)
    while startIndex == endIndex do endIndex = math.random(1, #locations) end
    local startPoint, endPoint = locations[startIndex], locations[endIndex]
    
    TriggerClientEvent('chaosrace:setVulnerable', -1)
    
    for _, playerSource in ipairs(GetPlayers()) do
        local sKey = tostring(playerSource)
        playersInRound[sKey] = 'alive'; playerLives[sKey] = GM_CONFIG.RaceLives; playerReadyStatus[sKey] = nil
        TriggerEvent('chaos:activateForPlayer', playerSource)
        TriggerClientEvent('chaosrace:startRace', playerSource, startPoint, endPoint, playerLives[sKey])
    end
    
    -- Tell ALL clients to enable friendly fire
    TriggerClientEvent('chaosrace:setFriendlyFire', -1, true)

    TriggerClientEvent('chat:addMessage', -1, {color = {255, 200, 0}, args = {"Server", "NEW RACE! From " .. startPoint.name .. " to " .. endPoint.name .. ". PvP is ON!"}})
end

function EndRaceForDNF()
    TriggerClientEvent('chat:addMessage', -1, { color = {255, 100, 0}, args = {"Server", "Time's up! The race has ended."} })
    for id, status in pairs(playersInRound) do
        if status == 'alive' then
            playersInRound[id] = 'dnf'
        end
    end
    CheckRoundEnd()
end

function CheckRoundEnd()
    local activePlayers = 0
    for _, status in pairs(playersInRound) do
        if status == 'alive' then activePlayers = activePlayers + 1 end
    end
    
    if activePlayers == 0 then
        -- Tell ALL clients to disable friendly fire
        TriggerClientEvent('chaosrace:setFriendlyFire', -1, false)

        gameState = 'WAITING' -- Set state before countdown
        TriggerClientEvent('chat:addMessage', -1, {color = {255, 200, 0}, args = {"Server", "Round over! Next round starting soon..."}})
    TriggerClientEvent('chaosrace:endRace', -1) -- This will hide race UI, etc.
    
    -- Start the process for the next round
    InitiateCountdown()
    end
end

-- Server tick to check if the end timer has expired
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if raceEndTimer.isActive and GetGameTimer() > raceEndTimer.endTime then
            raceEndTimer.isActive = false
            EndRaceForDNF()
        end
    end
end)

-- Event Handlers
RegisterNetEvent('chaosrace:playerFinished')
AddEventHandler('chaosrace:playerFinished', function(finishTime)
    local source = source; local safeKey = tostring(source)
    if not playersInRound[safeKey] or playersInRound[safeKey] ~= 'alive' then return end

    -- Mark player as finished and add to results
    playersInRound[safeKey] = 'finished'
    local place = #finishers + 1
    table.insert(finishers, {name = GetPlayerName(source), time = finishTime})
    
    local formattedTime = string.format("%02d:%02d", math.floor(finishTime / 60), math.floor(finishTime % 60))
    TriggerClientEvent('chat:addMessage', -1, { color = {0, 255, 0}, args = {"Server", GetPlayerName(source) .. " finished in " .. GetOrdinal(place) .. " place with a time of " .. formattedTime .. "!"} })
    
    -- ADD THIS BLOCK to award money based on place
    local winnings = 0
    if place == 1 then
        winnings = 2500
    elseif place == 2 then
        winnings = 1500
    elseif place == 3 then
        winnings = 1000
    end

    if winnings > 0 then
        AwardMoney(source, winnings)
    end
    -- END OF NEW BLOCK

    -- Update the end-race timer logic
    local timerDuration = GM_CONFIG.EndRaceTimers[place]
    if timerDuration then
        local newEndTime = GetGameTimer() + (timerDuration * 1000)
        if not raceEndTimer.isActive or newEndTime < raceEndTimer.endTime then
            raceEndTimer.isActive = true
            raceEndTimer.endTime = newEndTime
            TriggerClientEvent('chaosrace:updateEndTimer', -1, timerDuration)
        end
    end

    ResetPlayerState(source)
    TriggerEvent('chaos:deactivateForPlayer', source)

    TriggerClientEvent('chaosrace:setInvincible', source)

    playersSpectating[safeKey] = true

    local activeRacers = {}
    for id, status in pairs(playersInRound) do
        if status == 'alive' then
            table.insert(activeRacers, { id = tonumber(id), name = GetPlayerName(tonumber(id)) })
        end
    end

    -- Tell ONLY the player who just finished to ENTER spectator mode WITH the haunt list
    TriggerClientEvent('chaosrace:enterSpectatorMode', source, activeRacers, availableHaunts)

    -- Tell ALL OTHER spectators to UPDATE their target list
    for specId, _ in pairs(playersSpectating) do
        if specId ~= safeKey then
            TriggerClientEvent('chaosrace:updateSpectatorList', tonumber(specId), activeRacers)
        end
    end
    -- === END OF FIX ===

    CheckRoundEnd()
end)

RegisterNetEvent('chaosrace:playerDied')
AddEventHandler('chaosrace:playerDied', function()
    local source = source; local safeKey = tostring(source)
    if not playersInRound[safeKey] or playersInRound[safeKey] ~= 'alive' then return end
    
    playerLives[safeKey] = playerLives[safeKey] - 1
    TriggerClientEvent('chat:addMessage', -1, { color = {255, 150, 0}, args = {"Server", GetPlayerName(source) .. " crashed! " .. playerLives[safeKey] .. " lives remaining."} })
    
    if playerLives[safeKey] > 0 then
        TriggerClientEvent('chaosrace:handleRespawn', source, playerLives[safeKey])
    else
        playersInRound[safeKey] = 'dead'
        TriggerClientEvent('chat:addMessage', -1, { color = {255, 0, 0}, args = {"Server", GetPlayerName(source) .. " is out of the race!"} })
        ResetPlayerState(source)
        TriggerEvent('chaos:deactivateForPlayer', source)
        
        TriggerClientEvent('chaosrace:setInvincible', source)
        
        -- === REPLACE THE OLD 'enterSpectatorMode' CALL WITH THIS ===
        playersSpectating[safeKey] = true

        local activeRacers = {}
        for id, status in pairs(playersInRound) do
            if status == 'alive' then
                table.insert(activeRacers, { id = tonumber(id), name = GetPlayerName(tonumber(id)) })
            end
        end

        TriggerClientEvent('chaosrace:enterSpectatorMode', source, activeRacers, availableHaunts)

        for specId, _ in pairs(playersSpectating) do
            if specId ~= safeKey then
                TriggerClientEvent('chaosrace:updateSpectatorList', tonumber(specId), activeRacers)
            end
        end
        -- === END OF REPLACEMENT ===

        CheckRoundEnd()
    end
end)

RegisterNetEvent('chaosrace:playerIsReady')
AddEventHandler('chaosrace:playerIsReady', function()
    local source = source
    local license = GetPlayerIdentifier(source, 0)
    local safeKey = tostring(source) -- <<< THIS IS THE FIX. THIS LINE WAS MISSING.

    -- Load player data from K/V storage
    local savedData = GetResourceKvpString("player_" .. license)
    if savedData then
        playerData[license] = json.decode(savedData)
        print("Loaded data for " .. GetPlayerName(source) .. ": $" .. (playerData[license].money or STARTING_CASH))
    else
        -- This is a new player, give them starting cash
        playerData[license] = {
            money = STARTING_CASH
        }
        print("Created new player data for " .. GetPlayerName(source) .. " with starting cash.")
    end
    
    TriggerClientEvent('chat:addMessage', source, { color = {200, 200, 50}, args = {"[Chaos Cash]", string.format("Welcome! Your current balance is $%d.", playerData[license].money)} })

    -- Check for mid-race join
    if gameState ~= 'WAITING' and gameState ~= 'POST_ROUND' then
        print("Player " .. GetPlayerName(source) .. " joined mid-race. Putting into spectator mode.")
        
        -- 1. Mark them as a spectator immediately
        playersSpectating[safeKey] = true
        -- 2. Mark them as 'dead' in the round so they don't count as an active player
        playersInRound[safeKey] = 'dead'
        
        -- 3. Get the list of players they can spectate
        local activeRacers = {}
        for id, status in pairs(playersInRound) do
            if status == 'alive' then
                local pId = tonumber(id)
                table.insert(activeRacers, {id = pId, name = GetPlayerName(pId)})
            end
        end
        TriggerClientEvent('chaosrace:enterSpectatorMode', source, activeRacers, availableHaunts)
        
        -- This player is joining mid-race, so they are "ready" for the next round by default.
        -- We should not call TryStartGame() for them.
        playerReadyStatus[safeKey] = true
        print("Player " .. GetPlayerName(source) .. " is ready and spectating.")
        return -- We return here because they are not joining the pre-game lobby.
    end

    -- If not joining mid-race, proceed with normal ready-up
    if not playerReadyStatus[safeKey] then
        playerReadyStatus[safeKey] = true
        print("Player " .. GetPlayerName(source) .. " is now confirmed ready.")
    end
    TryStartGame()
end)

AddEventHandler('playerDropped', function()
    local source = source
    local license = GetPlayerIdentifier(source, 0)

    -- Save the player's data before removing them
    if playerData[license] then
        SetResourceKvp("player_" .. license, json.encode(playerData[license]))
        print("Saved data for dropped player " .. GetPlayerName(source) .. ": $" .. playerData[license].money)
    end

    -- Clean up their runtime data
    playerData[license] = nil
    local safeKey = tostring(source)
    playersSpectating[safeKey] = nil
    playerReadyStatus[safeKey] = nil; playersInRound[safeKey] = nil; playerLives[safeKey] = nil
    
    if gameState == 'IN_RACE' then
        CheckRoundEnd()
    else
        TryStartGame()
    end
end)

-- Admin Commands
RegisterCommand('coords', function(source)
    -- Instead of getting coords here, we ask the client to send them to us.
    TriggerClientEvent('chaosrace:getClientCoords', source)
end, true)

RegisterCommand('startrace', function() StartNewRound() end, true)

print("Chaos Race Game Manager (v5.4 - Spectator Logic) Loaded.")

-- ADD THIS NEW EVENT HANDLER anywhere in the server.lua file
RegisterNetEvent('chaosrace:returnClientCoords')
AddEventHandler('chaosrace:returnClientCoords', function(coords, heading)
    local source = source

    -- 1. Format the strings exactly as you need them.
    local coordsString = string.format("coords = vector3(%.2f, %.2f, %.2f),", coords.x, coords.y, coords.z)
    local headingString = string.format("heading = %.1f", heading)

    -- 2. Send the formatted strings back to the client that originally typed the command.
    TriggerClientEvent('chaosrace:printCoordsToConsole', source, coordsString, headingString)
    
    -- We can still keep the chat message here as a quick reference.
    local chatCoords = string.format("v3(%.2f, %.2f, %.2f) H: %.1f", coords.x, coords.y, coords.z, heading)
    TriggerClientEvent('chat:addMessage', source, { color = {0, 255, 0}, args = {"[Coords]", chatCoords} })
end)

Citizen.CreateThread(function()
    Citizen.Wait(1000) -- Wait a moment for other resources to be ready
    RefreshHauntsList()
end)

RegisterNetEvent('haunts:triggerEffect')
AddEventHandler('haunts:triggerEffect', function(targetServerId, hauntName)
    local ghostSource = source
    local ghostLicense = GetPlayerIdentifier(ghostSource, 0)
    
    if not ghostLicense or not playerData[ghostLicense] then return end

    local targetStatus = playersInRound[tostring(targetServerId)]
    local ghostStatus = playersSpectating[tostring(ghostSource)]

    -- Validation Part 1: Player States
    if not ghostStatus then
        print("Haunt Purchase Failed: Source player " .. ghostSource .. " is not a ghost.")
        return
    end
    if not targetStatus or targetStatus ~= 'alive' then
        TriggerClientEvent('chat:addMessage', ghostSource, { color = {255, 50, 50}, args = {"[Haunts]", "Purchase failed. Target is no longer in the race."} })
        return
    end
    
    -- Validation Part 2: Find the Haunt and its Cost
    local chaosEffects = exports.chaos:getChaosEffects()
    local selectedHaunt = nil
    for _, effect in ipairs(chaosEffects) do
        if effect.name == hauntName then
            selectedHaunt = effect
            break
        end
    end

    if not selectedHaunt or not selectedHaunt.cost then
        print("Haunt Purchase Failed: Invalid haunt name '" .. (hauntName or "nil") .. "'")
        return
    end

    -- Validation Part 3: Check Money
    if playerData[ghostLicense].money < selectedHaunt.cost then
        TriggerClientEvent('chat:addMessage', ghostSource, { color = {255, 50, 50}, args = {"[Haunts]", "Not enough Chaos Cash!"} })
        return
    end

    -- ALL CHECKS PASSED: Process the purchase
    playerData[ghostLicense].money = playerData[ghostLicense].money - selectedHaunt.cost
    
    -- Trigger the effect on the target player
    if selectedHaunt.name == "La Lamborghini" or selectedHaunt.name == "Mandatory Conscription" or selectedHaunt.name == "Ejecto Seato Cuz!" or selectedHaunt.name == "Kachow!" then
        TriggerClientEvent(selectedHaunt.clientEvent, -1, targetServerId, selectedHaunt.name, selectedHaunt.type, selectedHaunt.duration)
    else
        TriggerClientEvent(selectedHaunt.clientEvent, targetServerId, selectedHaunt.name, selectedHaunt.type, selectedHaunt.duration)
    end
    
    -- Send feedback messages to everyone involved
    local ghostName = GetPlayerName(ghostSource)
    local targetName = GetPlayerName(targetServerId)
    TriggerClientEvent('chat:addMessage', ghostSource, { color = {50, 200, 50}, args = {"[Haunts]", string.format("You successfully haunted %s with '%s'.", targetName, hauntName)} })
    TriggerClientEvent('chat:addMessage', ghostSource, { color = {200, 200, 50}, args = {"[Chaos Cash]", string.format("New Balance: $%d", playerData[ghostLicense].money)} })
    TriggerClientEvent('chat:addMessage', targetServerId, { color = {255, 100, 0}, args = {"[Haunted!]", string.format("A Ghost has haunted you with '%s'!", hauntName)} })
    print(string.format("Player %s (%s) haunted player %s (%s) with %s for $%d", ghostName, ghostSource, targetName, targetServerId, hauntName, selectedHaunt.cost))
end)

RegisterNetEvent('chaosrace:serverSetPlayerModel')
AddEventHandler('chaosrace:serverSetPlayerModel', function(modelHash)
    local source = source
    
    -- Tell ALL clients that this player is changing their model.
    -- The game's networking layer will handle the desync and resync for us.
    TriggerClientEvent('chaosrace:clientSetPlayerModel', -1, source, modelHash)
    
    print(string.format("Player %s (%s) is changing model to hash %s", GetPlayerName(source), source, modelHash))
end)

RegisterNetEvent('chaosrace:serverSpawnFallingVehicle')
AddEventHandler('chaosrace:serverSpawnFallingVehicle', function(spawnPos)
    -- This list is now on the server.
    local vehicleModels = {
        "panto", "blista", "prairie", "rhapsody", "pigalle", "issi2",
        "dilettante", "cogcabrio", "stalion", "gauntlet", "phoenix",
        "dominator", "sabregt", "buccaneer", "ruiner", "vigero", "manana"
    }

    local randomModelName = vehicleModels[math.random(#vehicleModels)]
    local randomModelHash = GetHashKey(randomModelName)

    -- Create the vehicle on the server. This makes it a networked entity.
    local fallingVehicle = CreateVehicle(randomModelHash, spawnPos.x, spawnPos.y, spawnPos.z, 0.0, true, true)
    
    -- *** THE FIX IS HERE: Give the vehicle a strong downward velocity so it actually falls. ***
    SetEntityVelocity(fallingVehicle, 0.0, 0.0, -30.0)

    print("Spawned a falling vehicle (" .. randomModelName .. ")")
end)
