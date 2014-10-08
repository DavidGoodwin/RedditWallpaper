#!/bin/bash

# This script goes to http://www.reddit.com/r/wallpapers, fetches a few images, and writes them to the directory of your choice.
# Everytime you execute it, it backs up the wallpapers from the last execution to the directory of your choice.

# Wallpapers directory
WALLS_DIR="~/Pictures/todayswalls"

# Backup directory
OLD_DIR="~/Pictures/oldwalls"

# Check if said directories exist
mkdir -p "${WALLS_DIR}" "${OLD_DIR}"

# Backup last execution's wallpapers to the backup directory
mv "${WALLS_DIR}"/* "${OLD_DIR}/"

# Go to reddit.com/r/wallpapers, find parts of the page source that look like 'http[s?]://...png|jpg', cut the URLs out, and download them to the wallpapers directory
curl "www.reddit.com/r/wallpapers/" 2>/dev/null | tr \< \\n | grep -E 'https?://[^"]*\.[jpng]*"' | sed -e 's!.*https\?://\([^"]*\.[jpng]*\).*!\1!g' | sort -u | while read line; do
    FILENAME="$(basename $line)"
    wget "$line" -O "${WALLS_DIR}/${FILENAME}"
done

