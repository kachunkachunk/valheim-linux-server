#!/bin/bash
# A docker run wrapper for deployments of the excellent lloesche/valheim-server-docker, with Valheim Plus enabled.
# This is more of an academic/learning thing with scripts.
# By https://github.com/kachunkachunk
# v0.1 - 2021/03/03: Initial fork, working draft. This one introduces environment file processing for V+ config generation.
# Dependencies: bash, docker

# Requirements:

# Assumptions:
# 1) Use of the lloesche/valheim-server-docker container, and some general knowledge of running docker containers.
# 2) An intention of enabling Valheim Plus (up to you if you still want to disable all sections in your config, for a vanilla experience).
# 3) You have a config file (get the latest from https://github.com/valheimPlus/ValheimPlus/blob/master/valheim_plus.cfg), and
#    Have run the generate_valheim_plus_env.sh script to prodice a docker environment file.
# 4) Docker host vs container port mapping is 1:1 (i.e. 2456-2458 for the host maps to 2456:2458 for the container)
# 5) Check/installation of updates every 15 minutes, though these will not occur if players are connected.
# 6) Hourly backups, on the hour, with two weeks of backup retention
# 7) Use of the Docker syslog driver, and a syslog host listening over UDP at 172.16.2.2
# Remove the syslog lines altogether if you want to just use the Docker local JSON logging driver.

#==========================================================
# Set up your constants here (no trailing slashes for paths).
# The password can be blank if you want a public/open server or use the permitted_list.txt file to secure your world.
# Do not skip any other sections or inputs.

v_vplusenvfile="/opt/docker/valheim/shared/valheim_plus.env"
v_basepath="/opt/docker/valheim"
v_containername="containername"
v_servername="My Server Name"
v_serverpassword=""
v_serverport="2456"
v_serverpublic="0"
v_serverworld="MyWorld"
v_timezone="America/Vancouver"

#==========================================================

# Expand on inputs as needed
v_portrange="$(echo "$v_serverport-$(( v_serverport + 2 ))")"

#==========================================================

f_show_config() {
    # Show what the current parameters are
    echo "Pending configuration:"
    echo "----------------------"
    echo -e "Configured container base path & name: \e[33m$v_basepath/$v_containername\e[0m"
    echo -e "Server Name: \e[33m$v_servername\e[0m"
    if [[ -z $v_serverpassword ]]; then
        # Password is blank, represent that
        echo -e "Server Password: \e[33m<no password>\e[0m"
    else
        echo -e "Server password: \e[33m$v_serverpassword\e[0m"
    fi
    echo -e "Server port: \e[33m$v_serverport\e[0m"
    echo -e "Port range: \e[33m$v_portrange\e[0m"
    echo -e "Server is Public: \e[33m$v_serverpublic\e[0m"
    echo -e "Server world name: \e[33m$v_serverworld\e[0m"
    echo -e "Generated valheim Plus environment file: \e[33m$v_vplusenvfile\e[0m"
}

f_proceed() {
    # Preview pending docker command
    echo "Proposed docker run command:"
    echo -e "docker run --name=\"valheim-\e[33m$v_containername\e[0m\" -d \ "
    echo -e "    -p \e[33m$v_portrange\e[0m:\e[33m$v_portrange\e[0m/udp \ "
    echo -e "    -v \"$v_basepath/\e[33m$v_containername\e[0m/config\":\"/config\" \ "
    echo -e "    -v \"$v_basepath/\e[33m$v_containername\e[0m/data\":\"/opt/valheim\" \ "
    echo -e "    -e SERVER_NAME=\"\e[33m$v_servername\e[0m\" \ "
    echo -e "    -e SERVER_PASS=\"\e[33m$v_serverpassword\e[0m\" \ "
    echo -e "    -e SERVER_PORT=\"\e[33m$v_serverport\e[0m\" \ "
    echo -e "    -e SERVER_PUBLIC=\"\e[33m$v_serverpublic\e[0m\" \ "
    echo -e "    -e WORLD_NAME=\"\e[33m$v_serverworld\e[0m\" \ "
    echo "    -e TZ=\"$v_timezone\" \ "
    echo "    -e UPDATE_CRON=\"*/15 * * * *\" \ "
    echo "    -e UPDATE_IF_IDLE=\"true\" \ "
    echo "    -e RESTART_CRON=\"\" \ "
    echo "    -e BACKUPS=\"true\" \ "
    echo "    -e BACKUPS_CRON=\"0 * * * *\" \ "
    echo "    -e BACKUPS_DIRECTORY=\"/config/backups\" \ "
    echo "    -e BACKUPS_MAX_AGE=\"14\" \ "
    echo "    -e PERMISSIONS_UMASK=\"022\" \ "
    echo "    -e STEAMCMD_ARGS=\"validate\" \ "
    echo "    -e VALHEIM_PLUS=\"true\" \ "
    echo "    --env-file \"$v_vplusenvfile\" \ "
    echo "    --log-driver syslog \ "
    echo "    --log-opt syslog-address=udp://172.16.2.2 \ "
    echo -e "    --log-opt tag=\"valheim-\e[33m$v_containername\e[0m\" \ "
    echo "    --restart unless-stopped \ "
    echo "    lloesche/valheim-server"
    echo ""

    # Prompt for final confirmation
    echo "Proceed?"
    echo -ne "\e[97m(y/N):\e[0m "
    read -r -n1 v_input
    echo ""
    echo ""

    # If yes
    if [[ $v_input =~ [yY] ]]; then
        docker run --name="valheim-$v_containername" -d \
            -p $v_portrange:$v_portrange/udp \
            -v "$v_basepath/$v_containername/config":"/config" \
            -v "$v_basepath/$v_containername/data":"/opt/valheim" \
            -e SERVER_NAME="$v_servername" \
            -e SERVER_PASS="$v_serverpassword" \
            -e SERVER_PORT="$v_serverport" \
            -e SERVER_PUBLIC="$v_serverpublic" \
            -e WORLD_NAME="$v_serverworld" \
            -e TZ="$v_timezone" \
            -e UPDATE_CRON="*/15 * * * *" \
            -e UPDATE_IF_IDLE="true" \
            -e RESTART_CRON="" \
            -e BACKUPS="true" \
            -e BACKUPS_CRON="0 * * * *" \
            -e BACKUPS_DIRECTORY="/config/backups" \
            -e BACKUPS_MAX_AGE="14" \
            -e PERMISSIONS_UMASK="022" \
            -e STEAMCMD_ARGS="validate" \
            -e VALHEIM_PLUS="true" \
            --env-file "$v_vplusenvfile" \
            --log-driver syslog \
            --log-opt syslog-address=udp://172.16.2.2 \
            --log-opt tag="valheim-$v_containername" \
            --restart unless-stopped \
            lloesche/valheim-server

        echo ""
        echo "Container created!"
        docker ps -a

    # If no, or some other input
    else
        echo "Quitting"
        exit
    fi
}

# Header
echo -e "\e[1mLunch Crew Alumni's Valheim (Plus) container wrapper\e[0m"
echo ""
f_show_config
echo ""
f_proceed
echo ""