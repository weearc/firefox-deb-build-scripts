#!/bin/bash
set -euxo pipefail
# Parmas
LANG=zh-CN
PLATFORM=linux64
BUILD_DIR=/tmp/build/firefox-release-deb
SRCDIR=$BUILD_DIR/src
PKGDIR=$BUILD_DIR/pkg
hostname=$(hostnamectl | grep "Static" | awk '{print $3}')
PKGARCH=amd64

case $@ in
    stable|"")
        CHANNEL=firefox-latest
        PKGNAME=firefox
        _PKGNAME=Firefox
        WMCLASS=firefox
        ;;
    beta)
        CHANNEL=firefox-beta-latest-ssl
        PKGNAME=firefox-beta
        _PKGNAME=Firefox-beta
        WMCLASS=firefox-beta
        ;;
    dev|develop)
        CHANNEL=firefox-devedition-latest-ssl
        PKGNAME=firefox-dev
        _PKGNAME=Firefox-dev
        WMCLASS=firefox-aurora
        ;;
    nightly|canary)
        CHANNEL=firefox-nightly-latest-ssl
        PKGNAME=firefox-nightly
        _PKGNAME=Firefox-nightly
        WMCLASS=firefox-nightly
        ;;
esac



check_curl() {
if [ ! -f /usr/bin/curl ];then
	echo "Install curl first:
sudo apt install curl"
	exit
fi
}



mkdir -p $BUILD_DIR



firefox_latest() {
# Get latest version

RES=$(curl -sSf https://download.mozilla.org/\?product\=$CHANNEL\&os\=$PLATFORM\&lang\=$LANG)
PKGVER=$(echo $RES |
	awk -F '/releases/' '{print $2}'|
	awk '{split($0,b,"/linux");print b[1]}')
FILE_=$(echo $RES |
	awk -F "/$LANG/" '{print $2}'|
	awk '{split($0,b,"\">");print b[1]}')

cd $BUILD_DIR
if [ ! -f $FILE_ ];then
	wget https://download.mozilla.org/\?product\=$CHANNEL\&os\=$PLATFORM\&lang\=$LANG -O $BUILD_DIR/$FILE_
fi

}

firefox_nightly() {
# Get nightly version

RES=$(curl -sSf https://download.mozilla.org/\?product\=$CHANNEL\&os\=$PLATFORM\&lang\=$LANG)
FILE_=$(echo $RES |
	awk -F "/latest-mozilla-central/" '{print $2}'|
	awk '{split($0,b,"\">");print b[1]}')
PKGVER=$(echo $FILE_ |
    awk -F 'firefox-' '{print $2}' |
    awk '{split($0,b,".en-US");print b[1]}')


cd $BUILD_DIR
if [ ! -f $FILE_ ];then
	wget https://download.mozilla.org/\?product\=$CHANNEL\&os\=$PLATFORM\&lang\=$LANG -O $BUILD_DIR/$FILE_
fi

}


prepare() {

mkdir -p $SRCDIR
mkdir -p $PKGDIR

install -d $PKGDIR/DEBIAN
install -d $PKGDIR/opt
install -d $PKGDIR/usr
install -d $PKGDIR/usr/share
install -d $PKGDIR/usr/share/applications
install -d $PKGDIR/usr/share/icons
install -d $PKGDIR/usr/share/icons/hicolor
install -d $PKGDIR/usr/bin


cd $BUILD_DIR
tar -xvf $FILE_ -C $SRCDIR/

cd $SRCDIR/firefox
PKGSIZE=$(du | grep '\.$' | awk '{print $1}')

echo "Package: $PKGNAME-bin
Version: $PKGVER
Architecture: $PKGARCH
Maintainer: $hostname-$(whoami)
Installed-Size: $PKGSIZE
Depends: fontconfig, procps, debianutils
Recommends: libavcodeclibavcodec.so | libavcodec-extralibavcodec.so | libavcodec59 | libavcodec-extra59 | libavcodec58 | libavcodec-extra58 | libavcodec57 | libavcodec-extra57 | libavcodec56 | libavcodec-extra56 | libavcodec55 | libavcodec-extra55 | libavcodec54 | libavcodec-extra54 | libavcodec53 | libavcodec-extra53
Suggests: fonts-stix | otf-stix, fonts-lmodern, libgssapi-krb5-2 | libkrb53, libcanberra0, pulseaudio
Breaks: xul-ext-torbutton
Provides: gnome-www-browser, www-browser
Conflicts: $PKGNAME, firefox-esr
Replaces: $PKGNAME
Section: web
Priority: optional
Description: Mozilla Firefox web browser
 Firefox is a powerful, extensible web browser with support for modern
 web application technologies." > $PKGDIR/DEBIAN/control
 

echo "[Desktop Entry]
Actions=new-window;new-private-window;
Categories=Network;WebBrowser;
Comment[zh_CN]=???????????????
Comment=Browse the web
Exec=/usr/bin/$PKGNAME
GenericName[zh_CN]=Firefox
GenericName=Firefox
Icon=$PKGNAME
Keywords=web;browser;internet;
MimeType=text/html;application/xml;application/xhtml+xml;application/vnd.mozilla.xul+xml;
Name[zh_CN]=$_PKGNAME
Name=$_PKGNAME
StartupNotify=true
StartupWMClass=$WMCLASS
Terminal=false
Type=Application

[Desktop Action new-private-window]
Exec=/usr/bin/$PKGNAME --private-window %u
Name[zh_CN]=??????????????????
Name=New Private Window

[Desktop Action new-window]
Exec=/usr/bin/$PKGNAME --new-window %u
Name[zh_CN]=????????????
Name=New Window" > $PKGDIR/usr/share/applications/$_PKGNAME.desktop && \
chmod 755 $PKGDIR/usr/share/applications/$_PKGNAME.desktop


 
 
echo "#!/bin/bash
/opt/$PKGNAME/firefox $@" > $PKGDIR/usr/bin/$PKGNAME && chmod a+x $PKGDIR/usr/bin/$PKGNAME
 
 
for i in 16 32 48 64 128
do
mkdir -p $PKGDIR/usr/share/icons/hicolor/${i}x${i}/apps
cp /tmp/build/firefox-release-deb/src/firefox/browser/chrome/icons/default/default$i.png $PKGDIR/usr/share/icons/hicolor/${i}x${i}/apps/$PKGNAME.png
done

cp -rf $SRCDIR/firefox $PKGDIR/opt/$PKGNAME

# Create postinst

echo "#!/bin/sh -e

if [ \"\$1\" = \"configure\" ] || [ \"\$1\" = \"abort-upgrade\" ] ; then
    update-alternatives --install /usr/bin/x-www-browser \\
        x-www-browser /usr/bin/$PKGNAME 70 
    update-alternatives --remove mozilla /usr/bin/$PKGNAME
    update-alternatives --install /usr/bin/gnome-www-browser \\
        gnome-www-browser /usr/bin/$PKGNAME 70
fi

if [ \"\$1\" = \"configure\" ] ; then
    rm -rf /opt/$PKGNAME/updater
fi" > $PKGDIR/DEBIAN/postinst && chmod 755 $PKGDIR/DEBIAN/postinst 

# Create prerm

echo "#!/bin/sh -e

if [ \"\$1\" = \"remove\" ] || [ \"\$1\" = \"deconfigure\" ] ; then
    update-alternatives --remove x-www-browser /usr/bin/$PKGNAME
    update-alternatives --remove gnome-www-browser /usr/bin/$PKGNAME
fi

if [ \"\$1\" = \"remove\" ]; then
    rm -rf /opt/$PKGNAME/updater
fi" > $PKGDIR/DEBIAN/prerm && chmod 755 $PKGDIR/DEBIAN/prerm

}


package() {
cd /tmp/build
dpkg-deb -b --root-owner-group "$PKGDIR" "$PKGNAME-$PKGVER-$PKGARCH.deb"
}


check_curl
case $CHANNEL in

    "firefox-latest")
        firefox_latest
        ;;
    "firefox-beta-latest-ssl")
        firefox_latest
        ;;
    "firefox-devedition-latest-ssl")
        firefox_latest
        ;;
    "firefox-nightly-latest-ssl")
        firefox_nightly
        ;;
esac
    
prepare
package

sudo dpkg -i /tmp/build/"$PKGNAME-$PKGVER-$PKGARCH.deb"

rm -rf $BUILD_DIR




