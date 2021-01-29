fx_version 'cerulean'
game 'gta5'


author 'Ekhion'
description 'Economy - Cargo'
version '1.0'

client_scripts {
    '@es_extended/locale.lua',
    'locales/*.lua',
    'config.lua',
    'libs/*.lua',
    'client/main.lua',
    'client/monitoring.lua',
    'client/cruise_control.lua',
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    '@es_extended/locale.lua',
    'locales/*.lua',
    'config.lua',
    'libs/helper.lua',
    'server/main.lua',
}

ui_page 'html/ui.html'

files {
    'html/ui.html',
    'html/styles.css',
    'html/js/*.js',
    'html/img/*.*'
}

dependencies {
    'es_extended'
}