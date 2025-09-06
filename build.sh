#/bin/bash

#https://learn.microsoft.com/en-us/windows/wsl/build-custom-distro

#https://cdn.amazonlinux.com/al2023/os-images/latest/

MYDISTRO=AL2023

#URL="https://cdn.amazonlinux.com/al2023/os-images/2023.8.20250818.0/container-minimal-arm64/al2023-container-minimal-2023.8.20250818.0-arm64.tar.xz"
URL="https://cdn.amazonlinux.com/al2023/os-images/2023.8.20250818.0/container-arm64/al2023-container-2023.8.20250818.0-arm64.tar.xz"
XZFILE=$(echo $URL |sed -e 's:.*/::')
ARCH=$(echo $URL | sed -e 's:.*-::' -e 's:\.tar\.xz::' )

if [ "$ARCH" = "" ]
then
    echo Cannot determine ARCH from $XZFILE
    exit 1
fi

if [ "$USER" != "root" ]
then
    echo Must run as root
    exit 1
fi

LASTDIR="$PWD"

TEMP_DIR=$(mktemp -d -t $(basename $0).XXXXXX)

trap 'rm -rf "$TEMP_DIR"' EXIT

echo TEMP_DIR: $TEMP_DIR

cd $TEMP_DIR

echo XZFILE: $XZFILE

wget "$URL"

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

tar -xf ../$XZFILE || exit 1

#[ ! -f etc/fstab ] || rm etc/fstab

mkdir -p etc/sudoers.d/

echo '%adm	ALL=(ALL)	NOPASSWD: ALL' > etc/sudoers.d/adm

cat <<EOWD > etc/wsl-distribution.conf
[oobe]
command = /etc/oobe.sh
defaultUid = 1000
defaultName = $MYDISTRO

[shortcut]
enabled = false

[windowsterminal]
enabled = true
ProfileTemplate = /usr/lib/wsl/terminal-profile.json
EOWD

cat <<EOWP >usr/lib/wsl/terminal-profile.json
{
  "profiles": [
    {
      "antialiasingMode": "aliased",
      "fontWeight": "bold",
      "colorScheme": "Postmodern Tango Light"
    }
  ],
  "schemes": [
    {
      "name": "Postmodern Tango Light",
      "black": "#0C0C0C",
      "red": "#C50F1F",
      "green": "#13A10E",
      "yellow": "#C19C00",
      "blue": "#0037DA",
      "purple": "#881798",
      "cyan": "#3A96DD",
      "white": "#CCCCCC",
      "brightBlack": "#767676",
      "brightRed": "#E74856",
      "brightGreen": "#16C60C",
      "brightYellow": "#F9F1A5",
      "brightBlue": "#3B78FF",
      "brightPurple": "#B4009E",
      "brightCyan": "#61D6D6",
      "brightWhite": "#F2F2F2"
    }
  ]
}
EOWP

cat <<EOWO >etc/oobe.sh
#!/bin/bash

set -ue

DEFAULT_GROUPS='adm,cdrom'
DEFAULT_UID='1000'

[ -x /usr/sbin//usr/sbin/automount ] || dnf install -y autofs || exit 1
[ -x /usr/sbin/adduser ] || dnf install -y shadow-utils || exit 1
[ -x /usr/sbin/sudo ] || dnf install -y sudo || exit 1

echo 'Please create a default UNIX user account. The username does not need to match your Windows username.'
echo 'For more information visit: https://aka.ms/wslusers'

if getent passwd "\$DEFAULT_UID" > /dev/null ; then
  echo 'User account already exists, skipping creation'
  exit 0
fi

if [ ! -x /usr/sbin/adduser ]
then
    echo 'Cannot create users with out adduser command'
    exit 0
fi

while true; do

  # Prompt from the username
  read -p 'Enter new UNIX username: ' username

  # Create the user
  if /usr/sbin/adduser --uid "\$DEFAULT_UID" "\$username"; then

    if /usr/sbin/usermod "\$username" -aG "\$DEFAULT_GROUPS"; then
      break
    else
      /usr/sbin/deluser "\$username"
    fi
  fi
done
EOWO

chmod a+x etc/oobe.sh

cat <<EOW > etc/wsl.conf
[boot]
systemd=false

[automount]
#enabled=false 
mountFsTab=false

EOW

tar --numeric-owner --absolute-names -c  * | gzip --best > $LASTDIR/install.tar.gz

cd $LASTDIR

mv install.tar.gz $MYDISTRO-$ARCH.wsl
