#/bin/bash

if [ "$1" = "" ]
then
  echo Configuration file required
  exit 1
fi

if [ ! -f "$1" ]
then
  echo Cannot find configuration file: $1
  exit 1
fi

source "$1" || exit 1

if [ ! -f terminal-profile.json ] || [ ! -f wsl.conf ] || [ ! -f wsl-distribution.conf ] || [ ! -f ec2icon.svg ]
then
  echo Working directory does not contain all files to include in distro
  exit 1
fi

if [ "$BUILD_URL" = "" ]
then
  echo BUILD_URL is a required configuration file variable
  exit 1
fi

if [ "$BUILD_ARCH" = "" ]
then
  echo BUILD_ARCH is a required configuration file variable
  exit 1
fi

if [ "$BUILD_DISTRO" = "" ]
then
  echo BUILD_DISTRO is a required configuration file variable
  exit 1
fi

XZFILE=$(echo $BUILD_URL |sed -e 's:.*/::')

if [ "$XZFILE" = "" ]
then
  echo Cannot determine XZFILE from $BUILD_URL
  exit 1
fi

if ! type -P convert >/dev/null
then
  echo Cannot find convert. Please install ImageMagick
  exit 1
fi

if [ "$USER" != "root" ]
then
  echo Must run as root
  exit 1
fi

LASTDIR="$PWD"

[ ! -f "$BUILD_DISTRO-$BUILD_ARCH.wsl" ] || rm $BUILD_DISTRO-$BUILD_ARCH.wsl

TEMP_DIR=$(mktemp -d -t $(basename $0).XXXXXX)

trap 'rm -rf "$TEMP_DIR"' EXIT

echo TEMP_DIR: $TEMP_DIR

cd $TEMP_DIR || exit 1

echo XZFILE: $XZFILE

wget "$BUILD_URL"

if [ ! -f $XZFILE ]
then
    echo $XZFILE not found
    echo ------
    ls
    exit 1
fi

mkdir rootfs || exit 1
cd rootfs || exit 1
mkdir -p usr/lib/wsl || exit 1

echo Extracting $XZFILE

tar -xf ../$XZFILE || exit 1

echo Adding adm group to sudoers

mkdir -p etc/sudoers.d/ || exit 1

echo '%adm	ALL=(ALL)	NOPASSWD: ALL' > etc/sudoers.d/adm
chmod 400 etc/sudoers.d/adm || exit 1

echo Adding etc/wsl-distribution.conf

sed -e "s/{BUILD_DISTRO}/$BUILD_DISTRO/g" \
  $LASTDIR/wsl-distribution.conf > etc/wsl-distribution.conf || exit 1

echo Adding etc/terminal-profile.json

cp $LASTDIR/terminal-profile.json usr/lib/wsl/terminal-profile.json || exit 1

echo Adding etc/oobe.sh

cp $LASTDIR/oobe.sh etc/oobe.sh || exit 1

chmod a+x etc/oobe.sh || exit 1

echo Adding etc/wsl.conf

cp $LASTDIR/wsl.conf etc/wsl.conf || exit 1

echo Creating usr/lib/wsl/ec2.ico

convert -density 256x256 -background transparent \
  -define icon:auto-resize=256,128,96,64,48,32,16 $LASTDIR/ec2icon.svg usr/lib/wsl/ec2.ico

echo Creating root/.bash_profile
echo 'bash /etc/oobe.sh || exit 1' > root/.bash_profile
chmod u+x root/.bash_profile

echo Creating $BUILD_DISTRO-$BUILD_ARCH.wsl

tar --numeric-owner --absolute-names -c * | \
  gzip --best > $LASTDIR/$BUILD_DISTRO-$BUILD_ARCH.wsl || exit 1

cd $LASTDIR || exit 1
