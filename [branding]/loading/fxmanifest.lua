fx_version 'cerulean'
game 'gta5'
author 'You & Your AI Partner'

-- This tells FiveM that this resource is a loading screen
loadscreen 'html/index.html'

-- This lists all the files the loading screen needs
-- CORRECTED from bg.jpg to bg.png to match your CSS file
files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/assets/logo.png',
    'html/assets/bg.png', -- <<< THE FIX IS HERE
    'html/assets/music.ogg'
}