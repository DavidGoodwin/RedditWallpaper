RedditWallpaper
==========
redditWallpaper.sh
------------------
This downloads some wallpapers from http://www.reddit.com/r/wallpapers "hot" page to a directory of your choice. It backs up the ones from the previous execution to another directory of your choice.

randomWallpaper.sh
--------------------
This picks any number of wallpapers from a directory of your choice (according to the number of screens you have defined) and sets them using the tool of your choice.

Tools supported so far:

+ nitrogen
+ feh
+ gsettings (for GNOME 3)
+ xfconf-query (for XFCE 4)
+ pcmanfm (with Lubuntu)

Installation
------------
First change to the directory to which you want to place the scripts, for example a folder called source in your home folder.
```bash
$ cd ~/source
```
Then download the scripts and open your crontab.
```bash
$ git clone https://github.com/Alfred456654/RedditWallpaper.git
$ crontab -e
```
Then enter into the crontab the following lines. Though note that you have to replace \<your wm\> with the name of your window manager of choice, and change the path to the scripts if you downloaded them to another folder:
```cron
1      1   *   *   *   /path/to/RedditWallpaper/redditWallpaper.sh
*/15   *   *   *   *   DESKTOP_SESSION=<your wm> DISPLAY=:0.0 /path/to/randomWallpaper.sh
```

Known Bugs
------------
Sometimes, the configuration file written by `randomWallpaper.sh` for `nitrogen` isn't right (by default, `$HOME/.config/nitrogen/bg-saved.cfg`). The names of the sections created by `randomWallpaper.sh` are `[xin_0]`, `[xin_1]`... but nitrogen sometimes uses sections named `[:0.0]`, ...
Modify the script according to your needs.
