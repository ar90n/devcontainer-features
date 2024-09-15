#!/usr/bin/env bash

set -e

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
DEPS="curl jq unzip udev lsb-release gnupg gnupg2 ca-certificates"
check_packages $DEPS
if ! type git > /dev/null 2>&1; then
    check_packages git
fi

# Get the download URL for the Ubuntu zip file
DOWNLOAD_URL=$(curl -s https://api.github.com/repos/StanzaOrg/lbstanza/releases | jq -r '.[0].assets[].browser_download_url' | grep ubuntu)
# Download the file
curl -L -o stanza-ubuntu.zip $DOWNLOAD_URL

# Install lbstanza
mkdir -p  /opt/lbstanza
unzip stanza-ubuntu.zip -d /opt/lbstanza

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"
