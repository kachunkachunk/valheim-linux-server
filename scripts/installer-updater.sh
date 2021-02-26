#!/bin/bash
# A simple Valheim Plus Linux server update script
# By https://github.com/kachunkachunk
# v0.1 - 2021/02/23: Base release
# Dependencies: bash, curl, wget, zip, Internet connection

# Set up your constants here (no trailing slashes):

# 1) Valheim Dedicated Server install directory
v_server_dir="/opt/valheim-server/server"
# 2) User that runs the Valheim dedicated server and owns its files
v_server_dir_owner="valheim"
# 3) Group that runs the Valheim dedicated server and owns its files
v_server_dir_group="valheim"
# 4) Your downloads directory for newly-downloaded assets
v_downloads_dir="/opt/downloads/valheim-plus-releases"

#==========================================================

# Check that required variables have been set
if [[ -z "$v_server_dir" || -z "$v_server_dir_owner" || -z "$v_server_dir_group" || -z "$v_downloads_dir" ]]; then
    echo "Missing some configuration constants. Please update the script and try again."
    exit 1
fi

# Check that appropriate dependencies are in place
if ! command -v unzip &> /dev/null; then
    echo -e "\e[31munzip\e[0m is not installed. Please install this dependency."
    echo ""
    exit 1
fi
if ! command -v tar &> /dev/null; then
    echo -e "\e[31mtar\e[0m is not installed. Please install this dependency."
    echo ""
    exit 1
fi
if ! command -v wget &> /dev/null; then
    echo -e "\e[31mwget\e[0m is not installed. Please install this dependency."
    echo ""
    exit 1
fi
if ! command -v curl &> /dev/null; then
    echo -e "\e[31mcurl\e[0m is not installed. Please install this dependency."
    echo ""
    exit 1
fi
#TODO: Find command binary/type dependency
#TODO: bash builtins dependency

# Check that the downloads and server directories are writable
if [[ ! -w "$v_downloads_dir" ]]; then
    echo "The downloads directory is not writeable by the user running this script. Please run this script as a more privileged user."
    echo ""
    exit 1
fi
if [[ ! -w "$v_server_dir" ]]; then
    echo "The server directory is not writeable by the user running this script. Please run this script as a more privileged user."
    echo ""
    exit 1
fi

#==========================================================

# Gather current release version, links to each asset:
v_available_assets=($(curl --silent "https://api.github.com/repos/valheimPlus/ValheimPlus/releases/latest" | grep "browser_download_url" | cut -d '"' -f4))
v_available_version=$(echo "${v_available_assets[0]}" | cut -d '/' -f8)

# Gather currently downloaded assets conforming to a valid naming convention (valheim-plus-{version}-UnixServer.{tar.gz or .zip}):
#v_downloaded_assets=($(find "$v_downloads_dir" -maxdepth 1 -type f -regextype sed -regex '.*valheim-plus-[0-9]\.[0-9]\.[0-9]-UnixServer\.\(zip\|tar\.gz\)'))
v_downloaded_assets=($(find "$v_downloads_dir" -maxdepth 1 -type f -regextype sed -regex '.*valheim-plus-\(\([0-9]\{1,\}\.\)\{1,\}\)\w\+-UnixServer\.\(zip\|tar\.gz\)'))

# Gather installation version (this assumes you use a .valheim_plus_version file, or have run this script's installer previously.
if [[ -e "$v_server_dir/.valheim_plus_version" ]]; then
    v_installed_version=$(cat "$v_server_dir/.valheim_plus_version")
else
    v_installed_version="Unknown. A .valheim_plus_version file was not found in $v_server_dir"
fi

# Set variables
v_count=0
v_input=""

#==========================================================

f_show_versions() {
    echo -e "Currently available release: \e[33m$v_available_version\e[0m"
    echo -e "Currently installed release: \e[33m$v_installed_version\e[0m"
    return
}

f_show_assets() {
    # Print the asset list found on GitHub
    # XXX: The list presented is offset by 1 from the array's index. E.g.: Selecting "1" needs to be resolved to ${v_releases[0]}
    echo "Available Valheim Plus Assets:"
    for v_asset in "${v_available_assets[@]}"; do
        (( v_count++ ))
        echo "$v_count) $v_asset"
    done
    # XXX: $v_count also now represents the number of options there are. Carry this into the next function, as it's run.
    v_asset=""
}

f_menu_download() {
    # Download new assets
    # This assumes that a list of downloadable assets has been listed above, already

    # While the user hasn't specified to go back
    while [[ ! "$v_input" =~ [qQ] ]]; do

        # Prompt for what asset to download, or if we should return
        echo "Select an asset to download, or enter Q to abort"
        echo -ne "\e[33mDownload\e[0m > "
        read -n1 v_input
        echo ""

        # Download the chosen asset, or fall back upon a bad selection
        # Valid options are from 1 to what $v_count previously incremented to, which would be the total number of assets
        if [[ "$v_input" =~ [1-$v_count] ]]; then
            # Show selection, also subtract by 1 to match the array index:
            echo -n "Selected: $v_input) "
            (( v_input-- ))
            echo "${v_available_assets[$v_input]}"

            # Process the filename and download the file
            v_asset="valheim-plus-$(echo "${v_available_assets[$v_input]}" | cut -d "/" -f8,9 | sed 's/\//\-/')"
            wget --no-config -q --show-progress -O "$v_downloads_dir/$v_asset" "${v_available_assets[$v_input]}"
            v_input=""
            v_count=""
            echo ""
            return

        # The user chose to back out, return
        elif [[ "$v_input" =~ [qQ] ]]; then
            v_input=""
            v_count=""
            echo ""
            return

        # Unknown input, loop back and allow another input
        else
            echo "Unrecognized input, please try again."
        fi
    done
}

f_show_downloads() {
    # Gather a list of downloaded and renamed valheim-plus UnixServer assets from $v_downloads_dir
    # XXX: This assumes you're using the script's naming convention of "valheim-plus-$v_release_version-$v_asset"

    echo "Valid Valheim Plus UnixServer assets in the configured download directory:"

    if [[ ${#v_downloaded_assets[@]} -ge 1 ]]; then
        for v_downloaded_asset in "${v_downloaded_assets[@]}"; do
            (( v_count++ ))
            echo "  $v_count) $v_downloaded_asset"
        done
    else
        echo "There are currently no valid installable UnixServer assets in the download directory."
        echo "Please check your download directory parameter, or return and download a UnixServer release."
    fi

    # Reset back to safe, unset values
    # XXX: $v_count also now represents the number of options there are. Carry this into the next function, as it's run.
    v_downloaded_asset=""
}

f_menu_install() {
    # Install downloaded asset

    # TODO: Configuration file merging
    # Compare the old and new configuration files. As long as sections or keys have not been removed, merge the settings into the new file.
    # Back up the new file as a version-specific defaults file.

    # While the user hasn't specified to go back
    while [[ ! "$v_input" =~ [qQ] ]]; do

        # Prompt for what asset to install, or if we should return
        echo "Select an asset to install, or enter Q to abort"
        echo -ne "\e[31mInstall\e[0m > "
        read -n1 v_input
        echo ""

        # Install the chosen asset, or fall back upon a bad selection
        # Valid options are from 1 to what $v_count previously incremented to, which would be the total number of assets
        if [[ "$v_input" =~ [1-$v_count] ]]; then
            # Show selection, also subtract by 1 to match the array index:
            echo -n "Selected: $v_input) "
            (( v_input-- ))
            # Also get the asset name and version
            v_downloaded_asset="${v_downloaded_assets[$v_input]}"
            v_downloaded_asset_version="$(echo "$v_downloaded_asset" | cut -d "/" -f5 | cut -d "-" -f3)"
            echo "$v_downloaded_asset"

            # If it exists, back up the existing valheim_plus.cfg file in $v_install_dir/BepInEx/config/valheim_plus.cfg
            if [[ -e "$v_server_dir/BepInEx/config/valheim_plus.cfg" ]]; then
                cp "$v_server_dir/BepInEx/config/valheim_plus.cfg" "$v_server_dir/BepInEx/config/valheim_plus-$v_installed_version.cfg.bak"
            fi

            # Extract the selected asset to $v_server_dir
            # If it's a zip file:
            if [[ "$v_downloaded_asset" =~ .*zip ]]; then
                 unzip -q "$v_downloaded_asset" -d "$v_server_dir"
            fi
            # If it's a .tgz file:
            if [[ "$v_downloaded_asset" =~ .*gz ]]; then
                 tar xzf "$v_downloaded_asset" -C "$v_server_dir"
            fi

            # Set permissions
            chown -R "$v_server_dir_owner":"$v_server_dir_group" "$v_server_dir"
            echo "Server files extracted and installed, and permissions have been set."

            # Write version file and report a new version has been installed
            echo "$v_downloaded_asset_version" > "$v_server_dir/.valheim_plus_version"
            echo "$v_downloaded_asset installed."

            # Clear selection and counters before returning
            v_input=""
            v_count=""
            echo ""
            return

        # The user chose to back out, return
        elif [[ "$v_input" =~ [qQ] ]]; then
            v_input=""
            v_count=""
            echo ""
            return

        # Unknown input, loop back and allow another input
        else
            echo "Unrecognized input, please try again."
        fi
    done
}

f_menu_main() {
    # Take user selection
    echo -e "Select operation: (\e[33mD\e[0m)ownload latest release assets, (\e[31mI\e[0m)nstall a downloaded asset, (\e[97mQ\e[0m)uit"
    echo -ne "\e[97mMain Menu\e[0m > "
    read -n1 v_input
    echo ""
}

#==========================================================

# One-time header
echo -e "\e[1mLunch Crew Alumni's Valheim Plus Linux server downloader/installer\e[0m"
echo ""
echo -e "Configured downloads path: \e[33m$v_downloads_dir\e[0m"
echo -e "Configured install path: \e[33m$v_server_dir\e[0m"

# Show available vs installed version
f_show_versions
echo "------------------------------"

# Main user interaction loop
while [[ ! "$v_input" =~ [qQ] ]]; do

    # Prompt for a function
    f_menu_main
    echo ""

    # Download
    if [[ "$v_input" =~ [dD] ]]; then
        # Show available assets on GitHub
        f_show_assets

        # Prompt which one to download
        f_menu_download

    # Install
    elif [[ "$v_input" =~ [iI] ]]; then

        # Check if the server is running before proceeding
        if pgrep -f valheim_server.x86_64 &> /dev/null; then
            echo -e "\e[31mOne or more Valheim servers are running - we cannot install anything at the moment. Returning.\e[0m"
            echo ""

        else
            # Show downloaded, installable assets
            f_show_downloads

            # Prompt which one to install
            f_menu_install
        fi

    # Quit
    elif [[ "$v_input" =~ [qQ] ]]; then
        #f_selection_menus_quit
        echo "Quit"
        echo ""
        exit 0

    # Unknown input
    else
        echo "Unrecognized input, please try again."
    fi

done
