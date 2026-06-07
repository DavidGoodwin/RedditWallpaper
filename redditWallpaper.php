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

define('DEBUG', 1);

# Reddit blocks generic and browser-spoofed User-Agents with "403 Blocked".
# It explicitly asks for a unique, descriptive UA in the form:
#   <platform>:<app id>:<version> (by /u/<username>)
# Using one of these is the single most effective way to stop being blocked.
define('USER_AGENT', 'linux:redditwallpaper:v2.0 (by /u/thegingerdog)');

# How many times to attempt a request before giving up.
define('MAX_ATTEMPTS', 5);

# Polite pause (microseconds) between image downloads to ease off rate limits.
define('DOWNLOAD_DELAY', 750000);

function _log_it($msg) {
    if(DEBUG == 1) {
        echo " DEBUG : $msg \n";
    }
}

# Fetch a URL with a descriptive UA, retrying with exponential backoff + jitter
# on the transient / rate-limit / block statuses Reddit throws (403, 429, 5xx).
# Returns the response body on success, or false if every attempt failed.
function http_get($url) {
    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL            => $url,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_FOLLOWLOCATION => true,
        CURLOPT_MAXREDIRS      => 3,
        CURLOPT_USERAGENT      => USER_AGENT,
        CURLOPT_CONNECTTIMEOUT => 10,
        CURLOPT_TIMEOUT        => 30,
        CURLOPT_ENCODING       => '', // advertise gzip/deflate, let curl decode
    ]);

    for($attempt = 1; $attempt <= MAX_ATTEMPTS; $attempt++) {
        $body = curl_exec($ch);
        $code = curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
        $err  = curl_errno($ch);

        if($err === 0 && $code >= 200 && $code < 300) {
            curl_close($ch);
            return $body;
        }

        $retryable = $err !== 0 || in_array($code, [403, 429, 500, 502, 503, 504]);
        if(!$retryable || $attempt === MAX_ATTEMPTS) {
            _log_it("Fetch failed for $url (HTTP $code" . ($err ? ", curl: " . curl_error($ch) : "") . ") after $attempt attempt(s)");
            break;
        }

        # Exponential backoff with jitter: ~2s, 4s, 8s, 16s, capped at 60s.
        $wait = min(60, 1 << $attempt) + random_int(0, 1000) / 1000;
        _log_it("Fetch $url got HTTP $code (attempt $attempt/" . MAX_ATTEMPTS . "); sleeping " . round($wait, 1) . "s");
        usleep((int)($wait * 1000000));
    }

    curl_close($ch);
    return false;
}
## END CONFIGURATION

if(DEBUG == 1) {
    error_reporting(E_ALL);
    ini_set('display_errors', 'on');
}


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
    if(in_array(basename($file),[ 'image.list', 'index.list'] )) {
        continue;
    }

    if(filesize($file) == 0) {
        _log_it("$file is empty; nuking");
        unlink($file);
        continue;
    }

    $mimetype = finfo_file($finfo, $file);
    if(in_array($mimetype, ['image/gif', 'image/jpeg', 'image/png', 'image/webp'])) {
        _log_it("moving $file to OLD_DIR");
        rename($file, OLD_DIR . '/'. basename($file));
    }
    else {
        _log_it("Weird mimetype - for $file " . json_encode(['file' => $file, 'mimetype' => $mimetype]));
    }
}

file_put_contents(WALLS_DIR . '/index.list', "# xfce backdrop list\n" );

$raw = http_get(URL);
if($raw === false) {
    die("Failed to fetch listing from " . URL . " - giving up.\n");
}
$data = json_decode($raw, true);

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

    _log_it("Candidate Image: $src");
    if(!preg_match('/i\.redd\.it/', $src)) {
        continue; // avoid imgur
    }

    $created = $node['data']['created'] ?? 0;
    $created_human = date('c', $created);
    $abit_ago = strtotime('4 days ago');
    if($created < $abit_ago) {
        _log_it(" - too old: $src - skipping - {$created}/{$created_human} vs {$abit_ago}");
        continue;
    }
    $dest = WALLS_DIR . '/'. basename($src);
    if(file_exists($dest)) {
        _log_it(" - already exists: $src - skipping");
        continue;
    }

    usleep(DOWNLOAD_DELAY);
    $raw = http_get($src);

    if($raw === false) {
        _log_it("Download of $src failed - no content returned.");
        continue;
    }
    file_put_contents($dest, $raw);
    $counter++;

    $mimetype = finfo_file($finfo, $dest);
    if($mimetype == 'image/webp') {
        // try and convert from webp to png?
        if(file_exists('/usr/bin/dwebp')) {
            $dest_png = $dest . '.png';
            $output = system("dwebp $dest -o $dest_png", $retval);

            if($retval != 0) {
                _log_it("Tried to convert $dest to $dest_png but failed? $output");
            }
        }
    }
    file_put_contents(WALLS_DIR . '/index.list', $dest . "\n", FILE_APPEND);
}

_log_it("Downloaded: $counter images to " . WALLS_DIR);
