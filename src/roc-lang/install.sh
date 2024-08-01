#!/usr/bin/env bash

set -e

# Clean up
rm -rf /var/lib/apt/lists/*

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
DEPS="curl libc-dev binutils lsb-release gnupg gnupg2 ca-certificates"
check_packages $DEPS
if ! type git > /dev/null 2>&1; then
    check_packages git
fi

# Fetch roc binary
architecture="$(uname -m)"
case $architecture in
    x86_64) architecture="x86_64";;
    aarch64 | armv8*) architecture="arm64";;
    *) echo "(!) Architecture $architecture unsupported"; exit 1 ;;
esac
ARCHIVE_FILE=/tmp/roc_nightly-linux_${architecture}-latest.tar.gz
curl -L -o $ARCHIVE_FILE https://github.com/roc-lang/roc/releases/download/nightly/roc_nightly-linux_${architecture}-latest.tar.gz

# Install roc
mkdir /usr/lib/roc
tar -xvz -f $ARCHIVE_FILE --directory /usr/lib/roc --strip-components=1

# Clean up
rm -rf /var/lib/apt/lists/*
rm $ARCHIVE_FILE

echo "Done!"
