## NO FIREFOX(SNAP)  ON UBUNTU

### Usage:

Download or clone the repo:
```bash
git clone https://github.com/weearc/firefox-deb-build-scripts firefox-deb
```

Go into the directory and run the script:
```bash
cd firefox-deb

bash update-firefox-release.sh
```

This will download firefox binary from Mozilla and build it into a deb package which you can install by package manager. If you want automatical update for the package just use crontab or systemd-timers.
