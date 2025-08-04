!/usr/bin/env bash

set -e

# Clean up
rm -rf /var/lib/apt/lists/*

TARGET_KICAD_VERSION="${VERSION:-"7.0"}"

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
        apt-get update -y
        DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends "$@"
    fi
}

check_packages_with_recommends() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt-get update -y
        DEBIAN_FRONTEND=noninteractive apt-get -y install --install-recommends "$@"
    fi
}

# Install curl and other dependencies if missing
check_packages curl lsb-release gnupg gnupg2 software-properties-common bc

# Add KiCad apt repository
. /etc/os-release
if [ "${ID}" = "ubuntu" ] ; then
    add-apt-repository --yes ppa:kicad/kicad-${TARGET_KICAD_VERSION}-releases
fi

# Install KiCad packages
#check_packages_with_recommends kicad
check_packages kicad

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"
