
--file: [chaos-race]/gamemanager/fxmanifest.lua



resource_manifest_version '44febabe-d386-4d18-afbe-5e627f4af937'
fx_version 'cerulean'
game 'gta5'


-- This ensures our resource loads AFTER the default managers, allowing us to override them.
load_after 'spawnmanager'

-- This loads our new config file so both server and client can access it.
shared_script 'shared/config.lua'



author 'Tyrone'
description 'The main game manager for the Chaos Race server.'
version '4.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}


client_script 'client.lua'
server_script 'server.lua'
