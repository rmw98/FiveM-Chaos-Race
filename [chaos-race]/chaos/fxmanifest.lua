fx_version 'cerulean'
game 'gta5'
author 'You and Your AI Partner'
description 'Handles all chaos effects for the Chaos Race server.'

dependency 'tom_hanks_ped'
dependency 'Walter'
dependency 'JessePinkman'


-- NEW: Load the shared config file first.
-- This makes the 'Config' table available to both server and client scripts.
-- It MUST be listed before any script that uses it.
shared_script 'shared/config.lua'

server_script 'chaos_server.lua'
-- Define the new client-side script loading order
client_scripts {
    'client/main.lua',          -- Load the core logic and exports first.
    'client/effects/*.lua'      -- Load all new, modular effects.
}

exports {
    'getChaosEffects'
}