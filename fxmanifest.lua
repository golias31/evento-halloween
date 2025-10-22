fx_version 'cerulean'
games { 'gta5' }
lua54 'yes'

author 'Halloween VRP Team'
description 'Sistema de Halloween completo para VRP/ESX/QBCore'
version '2.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared.lua',
    'config.lua'
}

server_scripts { 
    '@oxmysql/lib/MySQL.lua',
    'server/bridge-sv.lua',
    'server/function-sv.lua',
    'server/server.lua',
    'server/ghosthunt-sv.lua',
    'server/reward-system.lua',
    'server/vehicle-reward-sv.lua',
    'server/clownsystem-sv.lua',
}

client_scripts { 
    'client/client.lua',
    'client/bridge-cl.lua',
    'client/function-cl.lua',
    'client/ghosthunt-cl.lua',
    'client/pumpkinhunt-cl.lua',
    'client/clownsystem-cl.lua',
}

files {
    'sounds/*.ogg',
    'images/*.png',
}

dependencies {
    'ox_lib',
    'xsound',
    'oxmysql'
}
