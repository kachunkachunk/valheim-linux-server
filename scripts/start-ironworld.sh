#!/bin/sh
# From https://github.com/valheimPlus/ValheimPlus
# Mostly unchanged. As a general practice, you need to copy the included loader file and modify it for your server's needs.
# This just happens to be one of our server start configs.

export templdpath=$LD_LIBRARY_PATH

# BepInEx-specific settings
# NOTE: Do not edit unless you know what you are doing!
####
export DOORSTOP_ENABLE=TRUE
export DOORSTOP_INVOKE_DLL_PATH=./BepInEx/core/BepInEx.Preloader.dll
export DOORSTOP_CORLIB_OVERRIDE_PATH=./unstripped_corlib

export LD_LIBRARY_PATH=./doorstop_libs:$LD_LIBRARY_PATH
export LD_PRELOAD=libdoorstop_x64.so:$LD_PRELOAD
####

export LD_LIBRARY_PATH=./linux64:$LD_LIBRARY_PATH
export SteamAppId=892970

echo "Starting server PRESS CTRL-C to exit"

# Tip: Make a local copy of this script to avoid it being overwritten by steam.
# NOTE: Minimum password length is 5 characters & Password cant be in the server name.
# NOTE: You need to make sure the ports 2456-2458 is being forwarded to your server through your local router & firewall.
#./valheim_server.x86_64 -name "My server" -port 2456 -world "Dedicated" -password "secret"
./valheim_server.x86_64 -name "Lunch Crew Alumni (IronWorld)" -password "password" -nographics -batchmode -port 3456 -world "IronWorld" -savedir "/opt/valheim-server/config" -public 1

export LD_LIBRARY_PATH=$templdpath
