#!/usr/bin/env bash

set -e

# Clean up
rm -rf /var/lib/apt/lists/*

TARGET_TINYGO_VERSION="${VERSION:-latest}"

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Detect architecture
architecture="$(uname -m)"
case ${architecture} in
    x86_64) architecture="amd64";;
    aarch64 | armv8*) architecture="arm64";;
    armv7* | armhf) architecture="armhf";;
    *) echo "(!) Architecture ${architecture} unsupported"; exit 1 ;;
esac

# Figure out correct version of TinyGo to install
find_version_from_git_tags() {
    local variable_name=$1
    local requested_version=${!variable_name}
    if [ "${requested_version}" = "none" ]; then return; fi
    local repository=$2
    local prefix=${3:-"tags/v"}
    local separator=${4:-"."}
    local last_part_optional=${5:-"false"}    
    if [ "$(echo "${requested_version}" | grep -o "." | wc -l)" != "2" ]; then
        local escaped_separator=${separator//./\\.}
        local last_part
        if [ "${last_part_optional}" = "true" ]; then
            last_part="(${escaped_separator}[0-9]+)?"
        else
            last_part="${escaped_separator}[0-9]+"
        fi
        local regex="${prefix}\\K[0-9]+${escaped_separator}[0-9]+${last_part}$"
        local version_list="$(git ls-remote --tags ${repository} | grep -oP "${regex}" | tr -d ' ' | tr "${separator}" "." | sort -rV)"
        if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "current" ] || [ "${requested_version}" = "lts" ]; then
            declare -g ${variable_name}="$(echo "${version_list}" | head -n 1)"
        else
            set +e
            declare -g ${variable_name}="$(echo "${version_list}" | grep -E -m 1 "^${requested_version//./\\.}([\\.\\s]|$)")"
            set -e
        fi
    fi
    if [ -z "${!variable_name}" ] || ! echo "${version_list}" | grep "^${!variable_name//./\\.}$" > /dev/null 2>&1; then
        echo -e "Invalid ${variable_name} value: ${requested_version}\nValid values:\n${version_list}" >&2
        exit 1
    fi
}

# Install dependencies
apt-get update -y
apt-get -y install --no-install-recommends ca-certificates curl git dpkg

# Find version if needed
if [ "${TARGET_TINYGO_VERSION}" != "none" ]; then
    find_version_from_git_tags TARGET_TINYGO_VERSION "https://github.com/tinygo-org/tinygo"
fi

# Download and install TinyGo
echo "Installing TinyGo ${TARGET_TINYGO_VERSION}..."
cd /tmp
tinygo_deb="tinygo_${TARGET_TINYGO_VERSION}_${architecture}.deb"
curl -fsSL -o ${tinygo_deb} "https://github.com/tinygo-org/tinygo/releases/download/v${TARGET_TINYGO_VERSION}/${tinygo_deb}"

# Install the .deb package
dpkg -i ${tinygo_deb}

# Set up TINYGOROOT environment variable
# The .deb package installs to /usr/local, and adds tinygo to /usr/local/bin
echo 'export TINYGOROOT=/usr/local/lib/tinygo' >> /etc/bash.bashrc

# Also set for zsh if available
if [ -f /etc/zsh/zshrc ]; then
    echo 'export TINYGOROOT=/usr/local/lib/tinygo' >> /etc/zsh/zshrc
fi

# Clean up
rm -rf /tmp/${tinygo_deb}
rm -rf /var/lib/apt/lists/*

echo "Done!"