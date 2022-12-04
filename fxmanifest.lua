-- Resource Metadata
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Lunar Scripts'
description 'NPC Mechanic'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@es_extended/imports.lua',
    'config.lua'
}
client_scripts {
    '@es_extended/locale.lua',
    'locales/*.lua',
    'client/main.lua'
} 
server_scripts {
    '@es_extended/locale.lua',
    'locales/*.lua',
    'server/main.lua'
} 
