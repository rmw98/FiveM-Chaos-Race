-- File: [chaos-race]/gamemanager/shared/config.lua
-- This file contains all the core settings for the Chaos Race gamemode.

GM_CONFIG = {}

-- The single, universal spawn location for all players when they join the server.
-- Use the /coords command in-game to get these values easily.
GM_CONFIG.LobbySpawn = {
    coords = vector3(130.5, -1299.0, 29.2),
    heading = 255.0
}

-- The one and only character model players will have until they purchase a new one.
-- You can use any ped model name here, including custom ones.
GM_CONFIG.DefaultPedModel = `a_m_m_og_boss_01`

GM_CONFIG.RaceLives = 3


-- The server will always choose the SHORTEST remaining time.
GM_CONFIG.EndRaceTimers = {
    [1] = 600, 
    [2] = 300, 
    [3] = 60,  
}