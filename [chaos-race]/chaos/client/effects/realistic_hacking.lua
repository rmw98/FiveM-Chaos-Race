-- File: chaos/client/effects/realistic_hacking.lua
-- Forces the player into a hacking mini-game. Failure results in death.
-- Ported from the C++ ChaosModV effect by DrUnderscore (James). (v2 - Loop Fix)

local ROULETTE_WORDS = {
    "ROCKSTAR", "PONGO123", "DRUNDER_", "LAST0XYG", "TAKE_TWO", "DAVEYYYY", "MWEATHER", "RED_DEAD", "CHAOSMOD",
    "HACKING!", "ALXBLADE", "DVIPERAU", "HCKERMAN", "JIZZLEDS", "BURHAC!!", "SAURUS88", "TORIKSLV", "TOASTYYY",
    "ELIAS_GR", "KOLYA_VE", "LU7YOSHI", "P.BIDDLE", "SLOTHBEE", "ELI_RICK", "JUHANA!!", "LOSCHIKA", "BYHEMECH",
    "$$WASTED", "JOSHUAX8", "SSOBOSS1", "DZWDZWDZ", "BIRD1338", "BRANDWAR", "YZIMRONI", "T_AVENGE", "HUGO_ONE",
    "GATMUN!!", "MO_11___", "HUNTER2_", "PASSWORD", "1+4=-2+7", "_MATRIX_", "{RANDOM}", "ROULETTE", "PASS1234",
    "/HACK_R*", "FRANKLIN", "MICHAEL_", "TREVOR__", "LESTER__", "SYNFETIC",
}

local WIN_PHRASES = {
    "Rockstar: Creating realistic hacking since 1998.", "I swear that was made for a child, by a child.",
    "I wonder what would happen if you failed...", "I'll make it harder next time, I promise!",
    "https://youtube.com/watch?v=dQw4w9WgXcQ", "I'm not sure what you hacked, but it's now hacked.",
    "i ran out of phrases to put here. please pity me.", "I should get Linux.", "Yay, hacking!",
    "ping rockstargames.com", "You obviously must know something about something...", "I can read machine code!",
    "Well that wasn't fun", "Was that a promotion?",
    "We'll get right back to normal gameplay, hope you weren't doing anything important", "I use arch btw",
    "Vim > Emacs", "loooool cool hacker reference xdd", "You wouldn't download a car...", "Needs more blockchain",
    "HTML is my favorite programming language.", "Don't worry, it's not like you were mining cryptocurrencies for us...",
    "What? You wanted a witty win phrase? Too bad!", "sudo rm -rf /",
    "can you hack my friends instagram account plz?????", "Good thing I have 2FA", "/hack GTA5.exe",
    "Well that certainly was... something.", "Good job! You didn't lose a single time!",
    "Dude, that's illegal, I'm calling the cops.", "It's a bird! It's a plane! It's xx_thehackerman2006_xx!",
    "GTA Online just went down... I'm sure it's unrelated.", "int* hacked = true;", "Matrix reference",
    "\"I'm in the mainframe\"", "Aaaand... bingo!", "Access encoded... Gigabyte o'RAM should do the trick... We're in!",
    "Kernel bitrate overclocked!", "[ Hacking skill raised by 1 ]",
    "Ah ah ah, you didn't say the magic word!", "I frequent r/ProgrammerHumor.",
}

local isHackingActive = false

-- Helper to push text to a scaleform method
local function PushScaleformString(text)
    BeginTextCommandScaleformString("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandScaleformString()
end

-- Cleanup function to ensure player control is returned
local function cleanup(scaleform)
    if not isHackingActive then return end
    
    if scaleform and scaleform ~= 0 then
        SetScaleformMovieAsNoLongerNeeded(scaleform)
    end
    SetPlayerControl(PlayerId(), true, 0)
    isHackingActive = false
    print("Realistic Hacking: Effect has ended.")
end

RegisterNetEvent('chaos:realisticHacking')
AddEventHandler('chaos:realisticHacking', function(name, type, duration)
    if isHackingActive then return end

    isHackingActive = true
    exports.chaos:AddEffectToUI(name, type, 30000)
    print("Realistic Hacking: Starting effect.")

    Citizen.CreateThread(function()
        local playerPed = PlayerPedId()
        SetPlayerControl(PlayerId(), false, 0)
        local lives = 2

        -- Load the hacking scaleform
        local scaleform = RequestScaleformMovieInteractive("Hacking_PC")
        while not HasScaleformMovieLoaded(scaleform) do Citizen.Wait(0) end

        -- Setup the minigame
        CallScaleformMovieMethod(scaleform, "SET_BACKGROUND", 0)
        CallScaleformMovieMethod(scaleform, "SET_LIVES", lives, 2)
        CallScaleformMovieMethod(scaleform, "RUN_PROGRAM", 4) -- These specific program IDs are used to initialize the roulette game
        CallScaleformMovieMethod(scaleform, "RUN_PROGRAM", 83)
        
        BeginScaleformMovieMethod(scaleform, "SET_ROULETTE_WORD")
        PushScaleformString(ROULETTE_WORDS[math.random(#ROULETTE_WORDS)])
        EndScaleformMovieMethod()

        for i = 0, 7 do
            CallScaleformMovieMethod(scaleform, "SET_COLUMN_SPEED", i, math.random(400, 900) / 10.0)
        end
        
        local finished = false
        local selectHandle = 0 -- Handle for the async return value

        -- --- THE FIX IS HERE: RESTRUCTURED MAIN LOOP ---
        while not finished do
            DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255, 0)

            -- If we are not waiting for a result, we can process input
            if selectHandle == 0 then
                -- Handle directional input (Up, Down, Left, Right)
                local inputs = {{172, 8}, {173, 9}, {174, 10}, {175, 11}}
                for _, inputData in ipairs(inputs) do
                    if IsControlJustPressed(2, inputData[1]) then
                        PlaySoundFrontend(-1, "HACKING_MOVE_CURSOR", 0, true)
                        CallScaleformMovieMethod(scaleform, "SET_INPUT_EVENT", inputData[2])
                    end
                end
                
                -- Handle select/enter input
                if IsControlJustPressed(2, 201) then -- ENTER
                    BeginScaleformMovieMethod(scaleform, "SET_INPUT_EVENT_SELECT")
                    selectHandle = EndScaleformMovieMethodReturnValue()
                end
            else
                -- We are waiting for a result, so we check if it's ready
                if IsScaleformMovieMethodReturnValueReady(selectHandle) then
                    local result = GetScaleformMovieMethodReturnValueInt(selectHandle)
                    
                    if result == 86 then -- SUCCESS
                        PlaySoundFrontend(-1, "HACKING_SUCCESS", 0, true)
                        BeginScaleformMovieMethod(scaleform, "SET_ROULETTE_OUTCOME")
                        ScaleformMovieMethodAddParamBool(true)
                        PushScaleformString(WIN_PHRASES[math.random(#WIN_PHRASES)])
                        EndScaleformMovieMethod()
                        Citizen.Wait(2500)
                        finished = true
                    elseif result == 87 then -- FAILED ONE COLUMN
                        PlaySoundFrontend(-1, "HACKING_CLICK_BAD", 0, true)
                        lives = lives - 1
                        CallScaleformMovieMethod(scaleform, "SET_LIVES", lives, 2)
                        
                        if lives <= 0 then
                            PlaySoundFrontend(-1, "HACKING_FAILURE", 0, true)
                            SetEntityHealth(PlayerPedId(), 0)
                            finished = true
                        else
                            CallScaleformMovieMethod(scaleform, "STOP_ROULETTE")
                            Citizen.Wait(500)
                            CallScaleformMovieMethod(scaleform, "RESET_ROULETTE")
                        end
                    elseif result == 92 then -- CORRECT CHARACTER
                        PlaySoundFrontend(-1, "HACKING_CLICK", 0, true)
                    end
                    
                    -- Reset the handle so we can accept new input
                    selectHandle = 0
                end
            end
            Citizen.Wait(0)
        end
        
        cleanup(scaleform)
    end)
end)

-- Safety cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        cleanup()
    end
end)