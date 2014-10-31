#!/bin/bash

# This script selects random wallpapers from a directory of your choice and applies it/them to your screen(s) using the tool of your choice


## CONFIGURATION

# Configuration file
CONF_FILE="$HOME/.config/randomWallpaper/config"

# Wallpapers directory
WALLS=$HOME/Pictures/todayswalls

# Nitrogen configuration file
NITROGEN_CFG=$HOME/.config/nitrogen/bg-saved.cfg

# Tool to change the wallpaper
# Supported values:
#   nitrogen
#   gsettings (for GNOME 3)
#   feh
#   xfconf-query (for XFCE 4)
#   pcmanfm (for Lubuntu only)
TOOL=""

# Number of screens
NB_SCREENS=2

## END CONFIGURATION


# Try to load the tool to use from the configuration file
function load_tool_config {
    grep 'tool' "${CONF_FILE}" | cut -d\  -f2
}


# Try to guess the best tool to use depending on the environment
function guess_env {
    case "${DESKTOP_SESSION}" in
        *box|awesome|xmonad|i3|spectrwm )
            if [ -d "${NITROGEN_CFG%\/*}" ]; then
                if [ ! -z "$(command -v nitrogen)" ]; then
                    echo "nitrogen"
                fi
            elif [ ! -z "$(command -v feh)" ]; then
                echo "feh"
            fi
            ;;
        gnome* )
            if [ ! -z "$(command -v gsettings)" ]; then
                echo "gsettings"
            fi
            ;;
        xfce*|Xfce* )
            if [ ! -z "$(command -v xfconf-query)" ]; then
                echo "xfconf-query"
            fi
            ;;
        Lubuntu )
            if [ ! -z "$(command -v pcmanfm)" ]; then
                echo "pcmanfm"
            fi
            ;;
        * )
            if [ ! -z "$(command -v zenity)" ]; then
                zenity --list --title='What tool do you want to use?' --column='select' --radiolist --column='tool' --column='label' --hide-column=2 \
                    FALSE 'nitrogen' 'nitrogen' \
                    FALSE 'feh' 'feh' \
                    FALSE 'gsettings' 'gsettings (GNOME)' \
                    FALSE 'xfconf-query' 'xfconf-query (XFCE)'
            elif [ ! -z "$(command -v kdialog)" ]; then
                kdialog --radiolist 'What tool do you want to use?' 'nitrogen' 'nitrogen' off 'feh' 'feh' off 'gsettings' 'gsettings (GNOME)' off 'xfconf-query' 'xfconf-query (XFCE)' off 2>/dev/null
            fi
    esac
}

# Check whether the number of screens provided is an integer
if [ -z "$(echo ${NB_SCREENS} | grep -E '^[0-9]*$')" ]; then
    echo "ERROR: NB_SCREENS must be an integer (value found: '${NB_SCREENS}')" >&2
    exit 3
fi

# Check whether the walls directory exists
if [ ! -d "${WALLS}" ]; then
    echo "ERROR: directory ${WALLS} does not exist" >&2
    exit 1
fi

# Check whether it contains files
if [ -z "$(find ${WALLS} -type f)" ]; then
    echo "ERROR: directory ${WALLS} doesn't contain any file" >&2
    exit 1
fi

# Try to guess desktop environment
if [ -f "${CONF_FILE}" ]; then
    TOOL="$(load_tool_config)"
else
    TOOL="$(guess_env)"
fi

# Check if the chosen tool is installed
if [ -z "$(command -v ${TOOL})" ]; then
    echo "ERROR: ${TOOL} does not seem to be installed, or ${TOOL} is not present in \$PATH" >&2
    echo "\$PATH: [ $PATH ]" >&2
    exit 4
fi

# If there is no configuration file yet, write one
if [ ! -f "${CONF_FILE}" ]; then
    mkdir -p "${CONF_FILE%\/*}"
    echo "tool ${TOOL}" > "${CONF_FILE}"
fi

# Change wallpaper using nitrogen
function wall_nitrogen {

    # Check nitrogen configuration folder
    if [ ! -d "${NITROGEN_CFG%\/*}" ]; then
        echo "ERROR: directory ${NITROGEN_CFG} does not exist" >&2
        exit 2
    fi

    # Empty previous nitrogen configuration
    rm -f "${NITROGEN_CFG}"
    touch "${NITROGEN_CFG}"

    # Loop through the screens
    for i in $(seq 1 ${NB_SCREENS}); do

        # Pick a random wallpaper
        wall="$(find ${WALLS} -type f | shuf -n 1)"
        wall="$(basename ${wall})"

        # Set first wallpaper
        echo "[xin_$((i-1))]" >> "${NITROGEN_CFG}"
        echo "file=${WALLS}/${wall}" >> "${NITROGEN_CFG}"
        echo "mode=0" >> "${NITROGEN_CFG}"
        echo "bgcolor=#000000" >> "${NITROGEN_CFG}"
        echo "" >> "${NITROGEN_CFG}"
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

# Change wallpaper using pcmanfm (Lubuntu only)
# All credit for this method goes to Charles Tassell(http://sourceforge.net/p/pcmanfm/bugs/866/#f74d)
function wall_pcmanfm {

    pcmanfmConfigPath=~/.config/pcmanfm/lubuntu
    # Loop through screens
    for path in "$pcmanfmConfigPath"/desktop-items-*.conf ; do
        # Pick a wallpaper
        wall="$(find ${WALLS} -type f | shuf -n 1)"
        cat "$path" |sed 's|wallpaper=.*|wallpaper='"${wall}"'|' >/tmp/wp.$$
        cp /tmp/wp.$$ "$path"
        rm /tmp/wp.$$
    done
    
    # Refresh wallpapers
    pcmanfm --desktop-off
    sleep 0.5s
    pcmanfm --desktop --profile lubuntu &
}

# Call function to change wallpaper using chosen tool
wall_${TOOL}

