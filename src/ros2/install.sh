!/usr/bin/env bash

set -e

# Clean up
rm -rf /var/lib/apt/lists/*

TARGET_ROS_DISTRO="${DISTRO:-"rolling"}"
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
check_packages curl build-essential lsb-release gnupg gnupg2

# Add ROS2 apt repository
echo "deb http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/ros2.list
curl -k https://raw.githubusercontent.com/ros/rosdistro/master/ros.key | apt-key add -

# Install ROS packages
check_packages \
	ros-${TARGET_ROS_DISTRO}-${TARGET_ROS_PACKAGE} \
	ros-${TARGET_ROS_DISTRO}-gazebo-ros-pkgs \
        ros-${TARGET_ROS_DISTRO}-ros-ign-gazebo \
	python3-vcstool \
	python3-rosdep \
	python3-rosinstall \
        python3-argcomplete \
        python3-colcon-common-extensions


# Setup ROS environment
rosdep init
rosdep update

# Add custom profile script
cat <<EOF > /etc/profile.d/90-setup-ros2.sh
source /opt/ros/${TARGET_ROS_DISTRO}/setup.bash
source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash
EOF
chmod +x /etc/profile.d/90-setup-ros2.sh

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"
