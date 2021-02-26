#!/bin/bash
# TODO: Not server-agnostic yet. Need config section, conditions, etc.
# This script depends upon, and runs, steamcmd via docker to download Valheim dedicated server files.
# Presumes use of a valheim service user and group.
#
# Does not run +validate for steamcmd. This is so an update doesn't overwrite modified files, but this may not be a problem anymore.
# Typically the unstripped DLLs can be loaded explicitly now; the /valheim_server_Data/Managed directory and its contents are no longer overwritten.
# Will amend this script later when I am a bit more sure, and have a better idea of how I want to handle automatic updates.

docker run --rm -it -v /opt/valheim-server/server:/opt/valheim-server/server steamcmd/steamcmd:latest +login anonymous +force_install_dir /opt/valheim-server/server +app_update 896660 +quit
chown -R valheim:valheim /opt/valheim-server/server
