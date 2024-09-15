#!/usr/bin/env bash

set -e

# Clean up
rm -rf /var/lib/apt/lists/*

TARGET_PICO_SDK_VERSION="${VERSION:-latest}"
INSTALL_EXAMPLES=${INSTALLEXAMPLES}
INSTALL_EXTRAS=${INSTALLEXTRAS}
INSTALL_PLAYGROUND=${INSTALLPLAYGROUND}
INSTALL_PICOPROBE=${INSTALLPICOPROBE}
INSTALL_PICOTOOL=${INSTALLPICOTOOL}
INSTALL_OPENOCD=${INSTALLOPENOCD}

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Figure out correct version of a three part version number is not passed
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
    echo "${variable_name}=${!variable_name}"
}

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
GIT_DEPS="git ca-certificates"
SDK_DEPS="cmake pkg-config gcc-arm-none-eabi gcc g++ libnewlib-arm-none-eabi libstdc++-arm-none-eabi-newlib"
PICOPROBE_DEPS="libusb-1.0-0-dev python3"
PICOTOOL_DEPS="build-essential libusb-1.0-0-dev"
OPENOCD_DEPS="gdb-multiarch automake autoconf build-essential texinfo libtool libftdi-dev libusb-1.0-0-dev"

DEPS="$GIT_DEPS $SDK_DEPS"
if [[ "$INSTALL_PICOPROBE" == "true" ]]; then
    DEPS="$DEPS $PICOPROBE_DEPS"
fi
if [[ "$INSTALL_PICOTOOL" == "true" ]]; then
    DEPS="$DEPS $PICOTOOLDEPS"
fi
if [[ "$INSTALL_OPENOCD" == "true" ]]; then
    DEPS="$DEPS $OPENOCD_DEPS"
    INSTALL_PICOPROBE="true" # OpenOCD depends on Picoprobe
fi

check_packages $DEPS
if ! type git > /dev/null 2>&1; then
    check_packages git
fi

# Resolve version
OUTDIR="/opt"
GITHUB_PREFIX="https://github.com/raspberrypi/"
GITHUB_SUFFIX=".git"

find_version_from_git_tags TARGET_PICO_SDK_VERSION "${GITHUB_PREFIX}pico-sdk${GITHUB_SUFFIX}" "tags/" "." "true"

# Install pico-sdk
SDK_REPOS="sdk"
if [[ "$INSTALL_EXAMPLES" == "true" ]]; then
    SDK_REPOS="$SDK_REPOS examples"
fi
if [[ "$INSTALL_EXTRAS" == "true" ]]; then
    SDK_REPOS="$SDK_REPOS extras"
fi
if [[ "$INSTALL_PLAYGROUND" == "true" ]]; then
    SDK_REPOS="$SDK_REPOS playground"
fi

for REPO in $SDK_REPOS
do
    cd $OUTDIR
    DEST="$OUTDIR/pico-$REPO"

    SDK_BRANCH="master"
    if [[ "$REPO" == "sdk" ]]; then
        SDK_BRANCH=$TARGET_PICO_SDK_VERSION
    elif [[ "$TARGET_PICO_SDK_VERSION" != "latest" ]]; then
        SDK_BRANCH=sdk-$TARGET_PICO_SDK_VERSION
    fi

    if [ -d $DEST ]; then
        echo "$DEST already exists so skipping"
    else
        REPO_URL="${GITHUB_PREFIX}pico-${REPO}${GITHUB_SUFFIX}"
        echo "Cloning $REPO_URL - $SDK_BRANCH"
        git clone -b $SDK_BRANCH $REPO_URL

        # Any submodules
        cd $DEST
        git submodule update --init

        # add environment variable configurations
	VARNAME="PICO_${REPO^^}_PATH"
        echo "export $VARNAME=$DEST" >> /etc/profile.d/90-setup-pico-sdk.sh
        export ${VARNAME}=$DEST
    fi
done

if [ -e /etc/profile.d/90-setup-ros2.sh ]; then
    chmod +x /etc/profile.d/90-setup-ros2.sh
fi

# Picoprobe and picotool
TOOL_REPOS=""
if [[ "$INSTALL_PICOPROBE" == "true" ]]; then
    TOOL_REPOS="$TOOL_REPOS picoprobe"
fi
if [[ "$INSTALL_PICOTOOL" == "true" ]]; then
    TOOL_REPOS="$TOOL_REPOS picotool"
fi

for REPO in $TOOL_REPOS
do
    cd $OUTDIR
    DEST="$OUTDIR/$REPO"

    SDK_BRANCH="master"
    if [[ "$REPO" == "picoprobe" ]]; then
        case $TARGET_PICO_SDK_VERSION in
            1.*)
                SDK_BRANCH=picoprobe-cmsis-v1.1
                ;;
        esac
    elif [[ "$REPO" == "picotool" ]]; then
        case $TARGET_PICO_SDK_VERSION in
            1.*)
                SDK_BRANCH=1.1.2
                ;;
        esac
    fi

    REPO_URL="${GITHUB_PREFIX}${REPO}${GITHUB_SUFFIX}"
    echo "Cloning $REPO_URL - $SDK_BRANCH"
    git clone -b $SDK_BRANCH $REPO_URL

    # Build both
    cd $DEST
    git submodule update --init
    mkdir build
    cd build
    cmake ../
    make -j$JNUM

    if [[ "$REPO" == "picotool" ]]; then
        echo "Installing picotool to /usr/local/bin/picotool"
        cp picotool /usr/local/bin/
    fi
done

# OpenOCD
if [[ "$INSTALL_OPENOCD" == "true" ]]; then
    cd $OUTDIR
    # Should we include picoprobe support (which is a Pico acting as a debugger for another Pico)
    OPENOCD_BRANCH="sdk-2.0"
    case $TARGET_PICO_SDK_VERSION in
        1.*)
            OPENOCD_BRANCH="rp2040-v0.12.0"
            ;;
    esac

    OPENOCD_CONFIGURE_ARGS="--enable-ftdi --enable-sysfsgpio --enable-bcm2835gpio --enable-picoprobe"
    
    git clone "${GITHUB_PREFIX}openocd${GITHUB_SUFFIX}" -b $OPENOCD_BRANCH --depth=1
    cd openocd
    ./bootstrap
    ./configure $OPENOCD_CONFIGURE_ARGS
    make -j$JNUM
    make install
fi

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"
