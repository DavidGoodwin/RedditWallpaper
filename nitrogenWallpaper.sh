#!/bin/bash

# This script selects random wallpapers from a directory of your choice and applies it/them to your screen(s) using nitrogen

# Wallpapers directory
WALLS=~/Pictures/todayswalls

# Nitrogen configuration files
WALL_CFG=~/.config/nitrogen/bg-saved.cfg

# Number of screens
NB_SCREENS=2

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
