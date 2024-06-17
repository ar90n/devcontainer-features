!/usr/bin/env bash

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
check_packages libhidapi-hidraw0 python3-pip python3-venv python-is-python3

# Install PlatformIO packages
pip install platformio

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"
