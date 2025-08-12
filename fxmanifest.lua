fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'Système d’Infos Véhicules Proches'
version '1.0.0'
author 'tom2440'

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
    'es_extended',  
    'oxmysql'       
}
