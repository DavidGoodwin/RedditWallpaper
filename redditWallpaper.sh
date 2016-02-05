#!/bin/bash

# This script goes to http://www.reddit.com/r/wallpapers, fetches a few images, 
# and writes them to the directory of your choice (WALLS_DIR)

# On each run, it backs up the wallpapers from the last run to the directory of your choice (OLD_DIR)

# abort on error.
set -e

## CONFIGURATION

# URL of the page to parse
URL="https://www.reddit.com/r/wallpapers/.rss"

# Wallpapers directory
WALLS_DIR="$HOME/Pictures/todayswalls"

# Backup directory
OLD_DIR="$HOME/Pictures/oldwalls"

# Files to ignore
IGNORE_FILES="pixel.png icon.png"

# Put this parameter to 1 to only allow 1 execution per day.
# That way, if you ever have to close & reopen your session several times, 
# this won't execute the same thing over and over.
ONCE_PER_DAY=0

## END CONFIGURATION


# File dated to the last execution
LAST_EXEC="${OLD_DIR}/.last_exec"

# Make sure that said directories exist
mkdir -p "${WALLS_DIR}" "${OLD_DIR}"

# Check whether script has already been executed today, if this is the wanted behaviour. 
# Exit without error if it is the case.
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

cd "${WALLS_DIR}" && find ./  -maxdepth 1 -mindepth 1 -mtime +1 -type f -exec mv -t ${OLD_DIR} {} +

echo "# xfce backdrop list" > "${WALLS_DIR}"/index.list

# Go to reddit.com/r/wallpapers, 
# find parts of the page source that look like 'http[s?]://...png|jpg', 
# cut the URLs out, and download them to the wallpapers directory
FILE_LIST=$( wget -q -O - "$URL" 2>/dev/null | \
    perl -ne 'for (/&quot;(https?\:\/\/[^s]+?[jpgng])&quot;&gt;\[link/g) { print $_ ."\n" }' | sort -u )

OIFS="$IFS"
IFS=$'\n'

counter=0

for IMAGE_URL in $FILE_LIST 
do
    FILENAME=$(basename "$IMAGE_URL")
    DEST_FILENAME="${WALLS_DIR}/${FILENAME}"

    # don't duplicate/waste bandwidth
    [ -f "$DEST_FILENAME" ] && continue

    if echo "${IGNORE_FILES}" | grep -q "${FILENAME}"; then
        continue
    fi

    wget --no-use-server-timestamps -q "$IMAGE_URL" -O "$DEST_FILENAME"
    counter=$(( $counter + 1 ))

    echo "${WALLS_DIR}/${FILENAME}" >> "${WALLS_DIR}"/index.list
done

IFS="$OIFS"

echo "Downloaded: $counter images to $WALLS_DIR"
