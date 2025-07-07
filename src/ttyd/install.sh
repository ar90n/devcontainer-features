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
        DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends "$@"
    fi
}

# Install dependencies
check_packages curl ca-certificates

# Detect architecture
architecture="$(uname -m)"
case $architecture in
    x86_64) architecture="x86_64";;
    aarch64 | armv8*) architecture="aarch64";;
    i686 | i386) architecture="i686";;
    *) echo "(!) Architecture $architecture unsupported"; exit 1 ;;
esac

# Download ttyd binary
TTYD_VERSION="1.7.7"
DOWNLOAD_URL="https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.${architecture}"

echo "Downloading ttyd ${TTYD_VERSION} for ${architecture}..."
curl -L -o /usr/local/bin/ttyd "${DOWNLOAD_URL}"

# Make executable
chmod +x /usr/local/bin/ttyd

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"