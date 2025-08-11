fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'ESX info_car'
version '1.0.4'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

dependencies {
    'es_extended',   -- Dépendance pour ESX
    'oxmysql'        -- Dépendance pour oxmysql
}