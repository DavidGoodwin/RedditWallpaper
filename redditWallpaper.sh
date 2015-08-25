#!/bin/bash

# This script goes to http://www.reddit.com/r/wallpapers, fetches a few images, and writes them to the directory of your choice.
# Everytime you execute it, it backs up the wallpapers from the last execution to the directory of your choice.

# abort on error.
set -e

## CONFIGURATION

# URL of the page to parse
URL="https://www.reddit.com/r/wallpapers/"

# Wallpapers directory
WALLS_DIR="$HOME/Pictures/todayswalls"

# Backup directory
OLD_DIR="$HOME/Pictures/oldwalls"

# Files to ignore
IGNORE_FILES="pixel.png icon.png"

# Put this parameter to 1 to only allow 1 execution per day.
# That way, if you ever have to close & reopen your session several times, this won't execute the same thing over and over.
ONCE_PER_DAY=1

## END CONFIGURATION


# File dated to the last execution
LAST_EXEC="${OLD_DIR}/.last_exec"

# Make sure that said directories exist
mkdir -p "${WALLS_DIR}" "${OLD_DIR}"

# Check whether script has already been executed today, if this is the wanted behaviour. Exit without error if it is the case.
if [ "$ONCE_PER_DAY" -eq 1 -a -f $LAST_EXEC ]; then
    OLD_DATE=$(date -r "$LAST_EXEC" +%D)
    TODAY=$(date +%D)
    if [ "$OLD_DATE" = "$TODAY" ]; then
        exit 0
    fi
fi

# Mark that last execution is now
touch "$LAST_EXEC"

# Backup last execution's wallpapers to the backup directory
cd "${WALLS_DIR}" && find ./  -maxdepth 1 -mindepth 1 -type f -exec mv -t ${OLD_DIR} {} +

# Go to reddit.com/r/wallpapers, find parts of the page source that look like 'http[s?]://...png|jpg', cut the URLs out, and download them to the wallpapers directory
wget -q -O - "$URL" 2>/dev/null | tr \< \\n | grep -E 'https?://[^"]*\.[jpng]*"' | sed -e 's!.*https\?://\([^"]*\.[jpng]*\).*!\1!g' | sort -u | while read line; do
    FILENAME=$(basename "$line")
    if ! echo "${IGNORE_FILES}" | grep -q "${FILENAME}"; then
        wget "$line" -O "${WALLS_DIR}/${FILENAME}"
    fi
done

