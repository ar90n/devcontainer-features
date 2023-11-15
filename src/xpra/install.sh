#!/usr/bin/env bash

set -e

DEFAULT_DISPLAY=1
DEFAULT_PORT=20000

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

# Install wget, gnupg other dependencies if missing
check_packages wget gnupg
if ! type git > /dev/null 2>&1; then
    check_packages git
fi

# Add xpra apt repository
echo "deb [arch=amd64] https://xpra.org/ lunar main" > /etc/apt/sources.list.d/xpra.list
wget -q https://xpra.org/gpg.asc -O- | apt-key add -

# Install Xpra
check_packages xpra x11-xserver-utils x11-apps

# Container ENTRYPOINT script
cat << EOF > /usr/local/share/xpra-init.sh
#! /usr/bin/env bash
xpra start :\${DISPLAY:-$DEFAULT_DISPLAY} --bind-tcp=0.0.0.0:\${PORT:-$DEFAULT_PORT} --mdns=no --webcam=no --no-daemon --start="xhost +"
EOF
RUN chmod +x /usr/local/share/xpra-init.sh

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"
