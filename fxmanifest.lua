fx_version "cerulean"
game "gta5"
lua54 "yes"

name "filo_tow"
author "filo studios."
discord "https://discord.gg/bErPEKvRXg"
description ""
version "1.0.0"

shared_scripts {
    "@ox_lib/init.lua",
    "config.lua"
}

server_scripts {
    "server/*"
}

client_scripts {
    "client/*"
}

escrow_ignore {
    "config.lua"
}