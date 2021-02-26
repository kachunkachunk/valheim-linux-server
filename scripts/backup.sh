#!/bin/bash
# Adapted from the valheim-backup supervisor script in: https://github.com/lloesche/valheim-server-docker
# Modified to not take and rotate backups when the Valheim dedicated server process is not running.
# This hopefully reduces the chance of rotating out your last good copy, when the server was last running OK.
# Call this script via cron, or on-demand.

BACKUPS=${BACKUPS:-true}
BACKUPS_INTERVAL=${BACKUPS_INTERVAL:-3600}
BACKUPS_DIRECTORY=${BACKUPS_DIRECTORY:-/opt/valheim-server/config/backups}
BACKUPS_MAX_AGE=${BACKUPS_MAX_AGE:-7}
BACKUPS_DIRECTORY_PERMISSIONS=${BACKUPS_DIRECTORY_PERMISSIONS:-755}
BACKUPS_FILE_PERMISSIONS=${BACKUPS_FILE_PERMISSIONS:-644}

# Remove trailing slash if any
BACKUPS_DIRECTORY=${BACKUPS_DIRECTORY%/}

main() {
    cd /opt/valheim-server/config
    while :; do
        backup
        flush_old
        echo "Waiting $BACKUPS_INTERVAL seconds before next backup run"
        sleep $BACKUPS_INTERVAL
    done
}

backup() {
    if [ ! -d "/opt/valheim-server/config/worlds" ]; then
        echo "No Valheim worlds to backup"
        return
    fi
    if ! pgrep -f valheim_server.x86_64 &> /dev/null; then
        echo "No Valheim servers are running. Skipping backups."
        return
    fi
    local backup_file="$BACKUPS_DIRECTORY/worlds-$(date +%Y%m%d-%H%M%S).zip"
    echo "Backing up Valheim server worlds to $backup_file"
    mkdir -p "$BACKUPS_DIRECTORY"
    chmod $BACKUPS_DIRECTORY_PERMISSIONS "$BACKUPS_DIRECTORY"
    zip -r "$backup_file" "worlds/"
    chmod $BACKUPS_FILE_PERMISSIONS "$backup_file"
}

flush_old() {
    if [ ! -d "$BACKUPS_DIRECTORY" ]; then
        echo "No old backups to remove"
        return
    fi
    if ! pgrep -f valheim_server.x86_64 &> /dev/null; then
        echo "No Valheim servers are running. Skipping backup cleanup."
        return
    fi
    echo "Removing backups older than $BACKUPS_MAX_AGE days"
    find "$BACKUPS_DIRECTORY" -type f -mtime +$BACKUPS_MAX_AGE -name 'worlds-*.zip' -print -exec rm -f "{}" \;
}

if [ "X$BACKUPS" = Xtrue ]; then
    main
else
    echo "Backups have been turned off by env BACKUPS=$BACKUPS"
    systemctl stop valheim-server-backups
fi
