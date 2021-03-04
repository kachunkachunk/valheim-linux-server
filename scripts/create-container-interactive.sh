#!/bin/bash
# A docker run wrapper to generalize deployments of the excellent lloesche/valheim-server-docker, with Valheim Plus enabled.
# This is more of an academic/learning thing with scripts.
# By https://github.com/kachunkachunk
# v0.1 - 2021/03/02: Initial authoring/draft
# v0.2 - 2021/03/03: Small update for new parameters. No docker environment file processing yet.

# Dependencies: bash, docker, tr (if using POSIX case conversion)

# Assumptions:
# 1) Use of this particular container
# 2) Use of Valheim Plus (or at least BepInEx + unstripped libraries installed)
# 3) Docker host vs container port mapping is 1:1 (i.e. 2456-2458 for the host maps to 2456:2458 for the container)
# 4) Check/installation of updates every 15 minutes, though these will not occur if players are connected.
# 5) Hourly backups, on the hour, with two weeks of backup retention
# 6) Use of Valheim Plus (duh)
# 7) Use of the Docker syslog driver, and a syslog host listening over UDP at 172.16.2.2
# Edit the docker run command constants as needed. I'll probably eventually add some if/input logic.

# Set up your constants here (no trailing slashes):
# Where your Valheim docker container(s) live
v_basepath="/opt/docker/valheim"
v_timezone="America/Vancouver"

#==========================================================

# Check that required variables have been set
if [[ -z "$v_basepath" || -z "$v_timezone" ]]; then
    echo "Missing base path and/or timezone configuration parameters. Please update the script and try again."
    exit 1
fi

# Check that appropriate dependencies are in place
if ! command -v docker &> /dev/null; then
    echo -e "\e[31mdocker\e[0m command not found or available. Please install or address this dependency."
    echo ""
    exit 1
fi
#if ! command -v tr &> /dev/null; then
#    echo -e "\e[31mtr\e[0m command not found or avialable. Please install or address this dependency."
#    echo ""
#    exit 1
#fi

#==========================================================

# Set initial values
v_input="unset"
v_ready="false"
v_containername="unset"
v_servername="unset"
v_serverpassword="ChangeMe"
v_serverport="unset"
v_serverpublic="unset"
v_serverworld="unset"

#==========================================================

# One-time header
echo -e "\e[1mLunch Crew Alumni's Valheim (Plus) container wrapper\e[0m"
echo ""
echo "Please populate all parameters to proceed."

f_show_config() {
    # Show what the current parameters are
    echo ""
    echo "Pending configuration:"
    echo "----------------------"
    echo -e "Configured container base path & name: \e[33m$v_basepath\e[0m/valheim-\e[33m$v_containername\e[0m"
    echo -e "\e[31m1\e[0m) Container Name: valheim-\e[33m$v_containername\e[0m"
    echo -e "\e[31m2\e[0m) Server Name: \e[33m$v_servername\e[0m"
    if [[ -z $v_serverpassword ]]; then
        # Password is blank, represent that
        echo -e "\e[31m3\e[0m) Server Password: \e[33m<no password>\e[0m"
    else
        echo -e "\e[31m3\e[0m) Server password: \e[33m$v_serverpassword\e[0m"
    fi
    echo -e "\e[31m4\e[0m) Server port: \e[33m$v_serverport\e[0m"
    echo -e "\e[31m5\e[0m) Server is Public: \e[33m$v_serverpublic\e[0m"
    echo -e "\e[31m6\e[0m) Server world name: \e[33m$v_serverworld\e[0m"
}

f_input_main() {
    # Prompt for input and check that if all parameters are set yet.
    if [[ "$v_containername" != "unset" && "$v_servername" != "unset" && "$v_serverport" != "unset" && "$v_serverpublic" != "unset" && "$v_serverworld" != "unset" ]]; then
        v_ready="true"
        echo "Required parameters appear to be set."
        echo -e "Select parameter (\e[31m1\e[0m, \e[31m2\e[0m, \e[31m3\e[0m...), (\e[97mP\e[0m)roceed, or (\e[97mQ\e[0m)uit"
        echo -ne "\e[97m>\e[0m "
        read -n1 v_input
        echo ""
    else
        v_ready="false"
        echo -e "Select parameter (\e[31m1\e[0m, \e[31m2\e[0m, \e[31m3\e[0m...), or (\e[97mQ\e[0m)uit"
        echo -ne "\e[97m>\e[0m "
        read -n1 v_input
        echo ""
        # Trap erroneous confirmation; not all values are set yet.
        if [[ "$v_input" == "y" ]]; then
            v_input="n"
        fi
    fi
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
    echo "    --log-driver syslog \ "
    echo "    --log-opt syslog-address=udp://172.16.2.2 \ "
    echo -e "    --log-opt tag=\"valheim-\e[33m$v_containername\e[0m\" \ "
    echo "    --restart unless-stopped \ "
    echo "    lloesche/valheim-server"

    # Prompt for final confirmation
    echo "Proceed?"
    echo -ne "\e[97m(y/N):\e[0m "
    read -n1 v_input
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
            --log-driver syslog \
            --log-opt syslog-address=udp://172.16.2.2 \
            --log-opt tag="valheim-$v_containername" \
            --restart unless-stopped \
            lloesche/valheim-server
        echo ""
        echo "Creating container via docker..."
        echo ""

        # Container creation and launch should be done at this moment.
        # Unset parameters which must be unique, in case the user wants to make another container.
        v_containername="unset"
        v_servername="unset"
        v_serverport="unset"
        # Prompt to continue creating containers, or exit.
        echo "Create another container?"
        echo -ne "\e[97m(y/N):\e[0m "
        read -n1 v_input
        echo ""

        if [[ $v_input =~ [nN] ]]; then
            v_input="q"
            echo "Quit"
            exit 0
        else
            return
        fi

    # If no, or some other input
    else
       return
    fi
}

# Main interaction loop
# While user input is presumed as (n)ot ready, or is not specifying to (q)uit, continue to prompt.
while [[ ! "$v_input" =~ [qQpP] ]]; do
    # Print current effective configuration, as long as we didn't just come back from a bad input (terminal scrolling reduction)
    if [[ "$v_input" != "error" ]]; then
        f_show_config
        echo ""
    fi
    # Prompt for input/selection
    f_input_main
    echo ""

    # Input: Container Name
    if [[ "$v_input" == "1" ]]; then
        echo -ne "\e[97mContainer Name (suffix; must be unique on this host):\e[0m "
        # TODO: Input sanitization, check if the container already exists
        read v_containername
        # Check for unsetting/blank parameter
        if [[ -z $v_containername ]]; then
            v_containername="unset"
        fi
        echo ""

    # Input: Server Name
    elif [[ "$v_input" == "2" ]]; then
        echo -ne "\e[97mServer Name (as it appears in the game):\e[0m "
        # TODO: Input sanitization
        read v_servername
        if [[ -z $v_servername ]]; then
            v_servername="unset"
        fi
        echo ""

    # Input: Password
    elif [[ "$v_input" == "3" ]]; then
        echo -ne "\e[97mPassword (Min 5 chars, or Leave blank for password-less access):\e[0m "
        # TODO: Input sanitization and complexity validation. Length, gracefully handle special characters, like backslashes
        read v_serverpassword
        echo ""

    # Input: Port
    elif [[ "$v_input" == "4" ]]; then
        echo -ne "\e[97mServer Port: (e.g. 2456)\e[0m "
        # TODO: Input sanitization - digits only, and within a specific range (unprivileged, to the limit)
        read v_serverport
        # Take a default value of 2456 if nothing is entered.
        if [[ -z "$v_serverport" ]]; then
            v_serverport="2456"
        fi
        # Convert the inputted port number to a port range (+2) for Valheim
        v_portrange="$(echo "$v_serverport-$(( v_serverport + 2 ))")"
        echo ""

    # Input: Public
    elif [[ "$v_input" == "5" ]]; then
        echo -ne "\e[97mPublic Server? (y/1/n/0)\e[0m "
        read -n1 v_serverpublic
        if [[ "$v_serverpublic" =~ [yY1] ]]; then
            v_serverpublic="1"
        else
            v_serverpublic="0"
        fi
        echo ""

    # Input: Server World Name
    elif [[ "$v_input" == "6" ]]; then
        echo -ne "\e[97mServer World Name (case-sensitive):\e[0m "
        #TODO: Input validation for string length and possibly disallowed characters
        read v_serverworld
        if [[ -z $v_serverworld ]]; then
            v_serverworld="unset"
        fi
        echo ""

    # Proceed if all required parameters are set
    elif [[ "$v_input" =~ [pP] && "$v_ready" == "true" ]]; then
        f_proceed

    # Input: Quit
    elif [[ "$v_input" =~ [qQ] ]]; then
        echo "Quit"
        echo ""
        exit 0

    # Input: Unknown
    else
        echo "Unrecognized input, please try again."
        v_input="error"
    fi
done