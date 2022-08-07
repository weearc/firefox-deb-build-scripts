#!/bin/bash
set -euxo pipefail
# Parmas
LANG=zh-CN
PLATFORM=linux64
CHANNEL=firefox-latest

SRCDIR=$BUILD_DIR/src
PKGDIR=$BUILD_DIR/pkg
PKGNAME=firefox
_PKGNAME=Firefox
hostname=$(hostnamectl | grep "Static" | awk '{print $3}')
PKGARCH=amd64



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

prepare() {
firefox_latest


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

echo "Package: $PKGNAME
Version: $PKGVER
Architecture: amd64
Maintainer: $hostname-$(whoami)
Installed-Size: $PKGSIZE
Depends: fontconfig, procps, debianutils
Recommends: libavcodeclibavcodec.so | libavcodec-extralibavcodec.so | libavcodec59 | libavcodec-extra59 | libavcodec58 | libavcodec-extra58 | libavcodec57 | libavcodec-extra57 | libavcodec56 | libavcodec-extra56 | libavcodec55 | libavcodec-extra55 | libavcodec54 | libavcodec-extra54 | libavcodec53 | libavcodec-extra53
Suggests: fonts-stix | otf-stix, fonts-lmodern, libgssapi-krb5-2 | libkrb53, libcanberra0, pulseaudio
Breaks: xul-ext-torbutton
Provides: gnome-www-browser, www-browser
Section: web
Priority: optional
Description: Mozilla Firefox web browser
 Firefox is a powerful, extensible web browser with support for modern
 web application technologies." > $PKGDIR/DEBIAN/control
 

echo "[Desktop Entry]
Actions=new-window;new-private-window;
Categories=Network;WebBrowser;
Comment[zh_CN]=网络浏览器
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
StartupWMClass=$_PKGNAME
Terminal=false
Type=Application

[Desktop Action new-private-window]
Exec=/usr/bin/$PKGNAME --class=$_PKGNAME --private-window %u
Name[zh_CN]=新建隐私窗口
Name=New Private Window

[Desktop Action new-window]
Exec=/usr/bin/$PKGNAME --class=$_PKGNAME --new-window %u
Name[zh_CN]=新建窗口
Name=New Window" > $PKGDIR/usr/share/applications/firefox.desktop && \
chmod 755 $PKGDIR/usr/share/applications/firefox.desktop


 
 
echo "#!/bin/bash
/opt/firefox/firefox $@" > $PKGDIR/usr/bin/$PKGNAME && chmod a+x $PKGDIR/usr/bin/$PKGNAME
 
 
for i in 16 32 48 64 128
do
mkdir -p $PKGDIR/usr/share/icons/hicolor/${i}x${i}/apps
cp /tmp/build/firefox-release-deb/src/firefox/browser/chrome/icons/default/default$i.png $PKGDIR/usr/share/icons/hicolor/${i}x${i}/apps/$PKGNAME.png
done

cp -rf $SRCDIR/$PKGNAME $PKGDIR/opt/$PKGNAME

# Create postinst

echo '#!/bin/sh -e

if [ "$1" = "configure" ] || [ "$1" = "abort-upgrade" ] ; then
    update-alternatives --install /usr/bin/x-www-browser \
        x-www-browser /usr/bin/firefox 70 
    update-alternatives --remove mozilla /usr/bin/firefox
    update-alternatives --install /usr/bin/gnome-www-browser \
        gnome-www-browser /usr/bin/firefox 70
fi

if [ "$1" = "configure" ] ; then
    rm -rf /opt/firefox/firefox/updater
fi' > $PKGDIR/DEBIAN/postinst && chmod 755 $PKGDIR/DEBIAN/postinst 

# Create prerm

echo '#!/bin/sh -e

if [ "$1" = "remove" ] || [ "$1" = "deconfigure" ] ; then
    update-alternatives --remove x-www-browser /usr/bin/firefox
    update-alternatives --remove gnome-www-browser /usr/bin/firefox
fi

if [ "$1" = "remove" ]; then
    rm -rf /opt/firefox/firefox/updater
fi' > $PKGDIR/DEBIAN/prerm && chmod 755 $PKGDIR/DEBIAN/prerm

}


package() {
cd /tmp/build
dpkg-deb -b --root-owner-group "$PKGDIR" "$PKGNAME-$PKGVER-$PKGARCH.deb"
}



prepare
package

dpkg -i /tmp/build/"$PKGNAME-$PKGVER-$PKGARCH.deb"

rm -rf $BUILD_DIR




