#!/bin/bash
# Conversion/parsing script for a customized Valheim Plus configuration file

# Produce a Docker environment variable list out of a valheim_plus.cfg file, for use with https://github.com/lloesche/valheim-server-docker.
# Read this in with docker run [...] --env-file valheim_plus.env
# Assumes dos2unix is installed

# Convert from Windows to Unix format to address CRLF issues
dos2unix valheim_plus.cfg

# Read in the valheim_plus.cfg file in question
# (and use command subsitution to avoid losing variable contents in each loop due to subshell)
while IFS= read -r line; do

    # Each section starts with a square bracket. We need to strip the square brackets and retain the name of the section.
    if [[ "$line" =~ (^\[) ]]; then
	export v_section=$(echo "$line" | sed 's/[][]//g')
        # The next if condition will not match (for this [section] processing), so we will loop around again to the next line.
	# Importantly, we still have $v_section populated, with the section name.

    # This will match on subsequent loops, on lines that are not section headers, and rather key=value pairs.
    # Apply a "VPCFG_" prefix, the retained section name without square brackets, an underscore character, then the remainder of the key=value pair or line.
    elif [[ "$line" =~ (^[a-zA-Z]) ]]; then
	echo "VPCFG_${v_section}_${line}" >> valheim_plus.env

    # No further matches. We aren't retaining comments, or other weird stuff.
    fi

    # Continue iterating through the rest of the file, until complete.
done < <(cat valheim_plus.cfg)
echo 'valheim_plus.env file written. You may now append "--env-file valheim_plus.env" to your docker run command.'
