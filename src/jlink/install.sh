#!/usr/bin/env bash

set -e

env
exit 1

# Clean up
rm -rf /var/lib/apt/lists/*

ACCEPT_TERMS_OF_USE=${ACCEPTTERMSOFUSE}

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

apt_get_update()
{
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update
        apt-get -y install --no-install-recommends "$@"
    fi
}

# Install dependencies
DEPS="curl udev lsb-release gnupg gnupg2 ca-certificates"
check_packages $DEPS
if ! type git > /dev/null 2>&1; then
    check_packages git
fi

# Fetch JLink_Linux_x86_64.deb
DEB_FILE=/tmp/JLink_Linux_x86_64.deb
if [[ "$ACCEPT_TERMS_OF_USE" != "true" ]]; then
    echo -e 'Accept Terms of Use to fetch JLink_Linux_x86_64.deb.'
    exit 1
fi

curl -X POST -o $DEB_FILE https://www.segger.com/downloads/jlink/JLink_Linux_x86_64.deb -d 'accept_license_agreement=accepted'

# Create fake udevadm (ref: https://forum.segger.com/index.php/Thread/8953-SOLVED-J-Link-Linux-installer-fails-for-Docker-containers-Error-Failed-to-update/)
cat <<EOF > /usr/bin/udevadm
#!/bin/bash
echo not running udevadm "$@"
EOF
chmod +x /usr/bin/udevadm

# Install JLink_Linux_x86_64.deb
apt install -y $DEB_FILE

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"
