#!/usr/bin/php 
<?php

# This script goes to http://www.reddit.com/r/wallpapers.json and fetches a few images, 
# and writes them to the directory of your choice (WALLS_DIR)

# On each run, it backs up the wallpapers from the last run to the directory of your choice (OLD_DIR)

## CONFIGURATION

# URL of the page to parse
define('URL',"https://www.reddit.com/r/wallpapers.json");
define('WALLS_DIR', '/home/david/Pictures/todayswalls');
define('OLD_DIR', '/home/david/Pictures/oldwalls');
define('LAST_EXEC', '/home/david/Pictures/oldwalls/.last_exec');

# Put this parameter to 1 to only allow 1 execution per day.
# That way, if you ever have to close & reopen your session several times, 
# this won't execute the same thing over and over.
define('ONCE_PER_DAY',0);

define('DEBUG', 0);

function _log_it($msg) {
    if(DEBUG == 1) {
        echo " DEBUG : $msg \n";
    }
}
## END CONFIGURATION



if(!is_dir(WALLS_DIR) || !is_dir(OLD_DIR)) {
    die(" WALLS_DIR or OLD_DIR do not exist; check config. \n");
}

# Check whether script has already been executed today, if this is the wanted behaviour. 
# Exit without error if it is the case.
if(ONCE_PER_DAY == 1 && file_exists(LAST_EXEC)) {
    $dates = stat(LAST_EXEC);
    $last_time = date('Y-m-d', $dates['mtime']);
    if(date('Y-m-d') == $last_time) {
        _log_it("Already run today.");
        exit(0);
    }
}

# Mark that last execution is now
touch(LAST_EXEC);

$finfo = finfo_open(FILEINFO_MIME_TYPE);
foreach(glob(WALLS_DIR .'/*') as $file) {
    if(basename($file) == 'image.lst') {
        continue;
    }

    $mimetype = finfo_file($finfo, $file);
    if(in_array($mimetype, ['image/gif', 'image/jpeg', 'image/png'])) {
        _log_it("moving $file to OLD_DIR");
        rename($file, OLD_DIR . '/'. basename($file));
    }
    else {
        _log_it("Weird mimetpye - $mimetype for $file");
    }
}

file_put_contents(WALLS_DIR . '/index.list', "# xfce backdrop list\n" );


$raw = file_get_contents('https://reddit.com/r/wallpapers.json');
if(empty($raw)) {
    die("HTTP Error?");
}
$data = json_decode(file_get_contents("https://reddit.com/r/wallpapers.json"), true); 

if(empty($data)) {
    die("JSON error?");
}

$counter = 0;

foreach($data["data"]["children"] as $node) { 

    if(!isset($node['data']['post_hint'])) {
        continue;
    }

    if($node['data']['post_hint'] != 'image') {
        continue;
    }

    $src = $node['data']['url'];

    if(!preg_match('/i\.redd\.it/', $src)) {
        continue; // avoid imgur
    }

    _log_it("Image: $src");
    $dest = WALLS_DIR . '/'. basename($src);
    if(file_exists($dest)) {
        continue;
    }

    $raw = file_get_contents($src);
    file_put_contents($dest, $raw);
    $counter++;
    file_put_contents(WALLS_DIR . '/index.list', $dest . "\n", FILE_APPEND);
}

echo "Downloaded: $counter images to " . WALLS_DIR;
