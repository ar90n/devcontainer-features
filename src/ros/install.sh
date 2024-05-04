!/usr/bin/env bash

set -e

# Clean up
rm -rf /var/lib/apt/lists/*

TARGET_ROS_DISTRO="${DISTRO:-"noetic"}"
TARGET_ROS_PACKAGE="${PACKAGE:-"desktop"}"

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

# Install curl, build-essential other dependencies if missing
check_packages curl build-essential lsb-release gnupg

# Add ROS apt repository
echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list
curl -k https://raw.githubusercontent.com/ros/rosdistro/master/ros.key | apt-key add -

# Install ROS packages
check_packages \
	ros-${TARGET_ROS_DISTRO}-${TARGET_ROS_PACKAGE} \
	python3-rosinstall \
	python3-rosinstall-generator \
	build-essential \
	python3-vcstool \
	python3-catkin-tools \
	python3-rosdep \
	python3-osrf-pycommon

# Setup ROS environment
ls /etc/ros/rosdep/sources.list.d/20-default.list > /dev/null 2>&1 && rm /etc/ros/rosdep/sources.list.d/20-default.list
rosdep init 
rosdep update

# Add custom profile script
cat <<EOF > /etc/profile.d/90-setup-ros.sh
source /opt/ros/${TARGET_ROS_DISTRO}/setup.bash
source `catkin locate --shell-verbs`
EOF
chmod +x /etc/profile.d/90-setup-ros.sh

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"
