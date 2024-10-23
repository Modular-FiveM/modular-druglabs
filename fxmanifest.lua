fx_version 'cerulean'
game 'gta5'
lua54 'yes'

client_scripts {
    '@es_extended/imports.lua',
    'src/client/*.lua'
}

server_scripts {
    'webhooks.lua',
    'src/server/*.lua'
}

shared_scripts { '@ox_lib/init.lua', 'config.lua' }

dependencies { 'ox_inventory', 'oxmysql', 'ox_lib' }

escrow_ignore { 'config.lua', 'src/client/mission.lua' }