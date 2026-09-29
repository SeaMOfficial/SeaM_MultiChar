fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'SeaM_MultiChar'
author 'SeaM'
description 'Character selection for SeaM_Core'
version '1.0.0'

shared_script 'config.lua'

client_scripts {
    'client/appearance.lua',
    'client/scene.lua',
    'client/main.lua',
}

server_script 'server/main.lua'

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/assets/*.js',
    'web/dist/assets/*.css',
}

dependency 'SeaM_Core'
