#!/bin/bash

# This script selects random wallpapers from a directory of your choice and applies it/them to your screen(s) using the tool of your choice

# Wallpapers directory
WALLS=$HOME/Pictures/todayswalls

# Check whether the walls directory exists
if [ ! -d "${WALLS}" ]; then
    echo "ERROR: directory ${WALLS} does not exist" > /dev/stderr
    exit 1
fi

# Check whether it contains files
if [ -z "$(find ${WALLS} -type f)" ]; then
    echo "ERROR: directory ${WALLS} doesn't contain any file" > /dev/stderr
    exit 1
fi

# Tool to change the wallpaper (so far, nitrogen (for Openbox) and gsettings (for GNOME 3) are supported)
TOOL="nitrogen"

## PART FOR NITROGEN
if [ "${TOOL}" = "nitrogen" ]; then

    # Nitrogen configuration files
    WALL_CFG=$HOME/.config/nitrogen/bg-saved.cfg

    # Number of screens
    NB_SCREENS=2

    # Check configuration
    if [ ! -d "${WALL_CFG%\/*}" ]; then
        echo "ERROR: directory ${WALL_CFG} does not exist" > /dev/stderr
        exit 2
    fi
    if [ -z "$(echo ${NB_SCREENS} | grep -E '^[0-9]*$')" ]; then
        echo "ERROR: NB_SCREENS must be an integer (value found: '${NB_SCREENS}')" > /dev/stderr
        exit 3
    fi
    if [ -z "$(command -v nitrogen)" ]; then
        echo 'ERROR: nitrogen does not seem to be installed, or nitrogen is not present in $PATH' > /dev/stderr
        echo "\$PATH: [ $PATH ]" > /dev/stderr
        exit 4
    fi

    # Empty previous nitrogen configuration
    rm -f "${WALL_CFG}"
    touch "${WALL_CFG}"

    # Loop through the screens
    for i in $(seq 1 ${NB_SCREENS}); do

        # Pick a random wallpaper
        wall="$(find ${WALLS} -type f | shuf -n 1)"
        wall="$(basename ${wall})"

        # Set first wallpaper
        echo "[xin_$((i-1))]" >> "${WALL_CFG}"
        echo "file=${WALLS}/${wall}" >> "${WALL_CFG}"
        echo "mode=0" >> "${WALL_CFG}"
        echo "bgcolor=#000000" >> "${WALL_CFG}"
        echo "" >> "${WALL_CFG}"
    done

    nitrogen --restore

## PART FOR GSETTINGS (GNOME 3)
elif [ "${TOOL}" = "gsettings" ]; then
    
    # Check configuration
    if [ -z "$(command -v gsettings)" ]; then
        echo "ERROR: gsettings does not seem to be installed. Are you running GNOME 3?" > /dev/stderr
        exit 4
    fi

    # Picka  wallpaper
    wall="$(find ${WALLS} -type f | shuf -n 1)"
    wall="$(basename ${wall})"

    # Set wallpaper
    gsettings set org.gnome.desktop.background picture-uri "file:///${WALLS}/${wall}"
fi
