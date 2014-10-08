#!/bin/bash

# This script selects random wallpapers from a directory of your choice and applies it/them to your screen(s) using the tool of your choice


## CONFIGURATION

# Wallpapers directory
WALLS=$HOME/Pictures/todayswalls

# Tool to change the wallpaper
# Supported values:
#   nitrogen
#   gsettings (for GNOME 3)
#   feh
#   xfconf-query
TOOL="nitrogen"

# Number of screens
NB_SCREENS=2

## END CONFIGURATION


# Check whether the number of screens provided is an integer
if [ -z "$(echo ${NB_SCREENS} | grep -E '^[0-9]*$')" ]; then
    echo "ERROR: NB_SCREENS must be an integer (value found: '${NB_SCREENS}')" > /dev/stderr
    exit 3
fi

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

# Check if the chosen tool is installed
if [ -z "$(command -v ${TOOL})" ]; then
    echo "ERROR: ${TOOL} does not seem to be installed, or ${TOOL} is not present in \$PATH" > /dev/stderr
    echo "\$PATH: [ $PATH ]" > /dev/stderr
    exit 4
fi

# Change wallpaper using nitrogen
function wall_nitrogen {

    # Nitrogen configuration file
    WALL_CFG=$HOME/.config/nitrogen/bg-saved.cfg

    # Check nitrogen configuration folder
    if [ ! -d "${WALL_CFG%\/*}" ]; then
        echo "ERROR: directory ${WALL_CFG} does not exist" > /dev/stderr
        exit 2
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
}

# Change wallpaper using gsettings
function wall_gsettings {

    # Picka  wallpaper
    wall="$(find ${WALLS} -type f | shuf -n 1)"
    wall="$(basename ${wall})"

    # Set wallpaper
    gsettings set org.gnome.desktop.background picture-uri "file:///${WALLS}/${wall}"
}

# Change wallpaper using feh
function wall_feh {
    
    # Pick random wallpapers for all screens
    feh --randomize --bg-scale "${WALLS}"/* &
}

# Change wallpaper using xfconf-query (XFCE 4)
function wall_xfconf-query {

    # Loop through screens
    xfconf-query -c xfce4-desktop -l | grep -E '/backdrop/screen.*/monitor.*/image-path' | while read line; do

        # Pick a wallpaper
        wall="$(find ${WALLS} -type f | shuf -n 1)"

        # Set it on the current screen
        xfconf-query -c xfce4-desktop -p "${line}" -s "${wall}"
    done
}

# Call function to change wallpaper using chosen tool
wall_${TOOL}

