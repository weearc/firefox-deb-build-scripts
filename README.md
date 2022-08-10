## NO FIREFOX(SNAP)  ON UBUNTU

### Usage:

Download or clone the repo:
```bash
git clone https://github.com/weearc/firefox-deb-build-scripts firefox-deb
```

Go into the directory and run the script:
```bash
cd firefox-deb

bash update-firefox-release.sh <firefox-channel>
```

`firefox-channel` can be one of the values below:
- "": default, stable version
- beta: beta release version
- dev: dev version
- nightly: nightly version


package names are:
|channel|package name|WMClass|
|-------|------------|-------|
|stable|firefox-bin|firefox|
|beta|firefox-beta-bin|firefox-beta|
|dev|firefox-dev-bin|firefox-aurora|
|nightly|firefox-nightly-bin|firefox-nightly|



This will download firefox binary from Mozilla and build it into a deb package which you can install by package manager. If you want automatical update for the package just use crontab or systemd-timers.
