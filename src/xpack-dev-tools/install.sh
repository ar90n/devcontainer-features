#!/usr/bin/env bash

set -e

# Clean up
rm -rf /var/lib/apt/lists/*

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Detect architecture
architecture="$(uname -m)"
case ${architecture} in
    x86_64) xpack_arch="x64";;
    aarch64 | armv8*) xpack_arch="arm64";;
    armv7*) xpack_arch="arm";;
    *) echo "(!) Architecture ${architecture} unsupported"; exit 1 ;;
esac

# Function to check if packages are installed
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt-get update -y
        apt-get -y install --no-install-recommends "$@"
    fi
}

# Install dependencies
check_packages curl ca-certificates jq tar

# Base installation path
INSTALL_PATH="${INSTALLPATH:-/opt/xpack}"
mkdir -p "${INSTALL_PATH}"

# Function to get latest version from GitHub
get_latest_version() {
    local repo="$1"
    curl -s "https://api.github.com/repos/xpack-dev-tools/${repo}/releases/latest" | jq -r '.tag_name' | sed 's/^v//'
}

# Function to install an xPack tool
install_xpack_tool() {
    local tool_name="$1"
    local repo_name="$2"
    local version="$3"
    local binary_name="${4:-$tool_name}"
    
    if [ -z "$version" ] || [ "$version" = "" ]; then
        echo "Skipping ${tool_name} installation"
        return
    fi
    
    echo "Installing ${tool_name} version ${version}..."
    
    # Get latest version if requested
    if [ "$version" = "latest" ]; then
        version=$(get_latest_version "$repo_name")
        echo "Latest version for ${tool_name}: ${version}"
    fi
    
    # Construct download URL
    local filename="xpack-${binary_name}-${version}-linux-${xpack_arch}.tar.gz"
    local download_url="https://github.com/xpack-dev-tools/${repo_name}/releases/download/v${version}/${filename}"
    
    echo "Downloading from: ${download_url}"
    
    # Download and extract
    cd /tmp
    curl -fsSL -o "${filename}" "${download_url}" || {
        echo "Failed to download ${tool_name} version ${version}"
        return 1
    }
    
    # Extract to installation path
    local tool_path="${INSTALL_PATH}/${tool_name}"
    mkdir -p "${tool_path}"
    tar -xzf "${filename}" -C "${tool_path}" --strip-components=1
    
    # Clean up
    rm -f "${filename}"
    
    echo "${tool_name} ${version} installed successfully"
}

# Install tools based on options
echo "Installing xPack Dev Tools..."

# Compiler toolchains
install_xpack_tool "arm-none-eabi-gcc" "arm-none-eabi-gcc-xpack" "${ARMNONEEABIGCC}"
install_xpack_tool "aarch64-none-elf-gcc" "aarch64-none-elf-gcc-xpack" "${AARCH64NONEELFGCC}"
install_xpack_tool "riscv-none-elf-gcc" "riscv-none-elf-gcc-xpack" "${RISCVNONEELFGCC}"
install_xpack_tool "gcc" "gcc-xpack" "${GCC}"
install_xpack_tool "clang" "clang-xpack" "${CLANG}"

# Build tools
install_xpack_tool "cmake" "cmake-xpack" "${CMAKE}"
install_xpack_tool "meson-build" "meson-build-xpack" "${MESONBUILD}"
install_xpack_tool "ninja-build" "ninja-build-xpack" "${NINJABUILD}"
install_xpack_tool "pkg-config" "pkg-config-xpack" "${PKGCONFIG}"

# Debug/Emulation tools
install_xpack_tool "openocd" "openocd-xpack" "${OPENOCD}"
install_xpack_tool "qemu-arm" "qemu-arm-xpack" "${QEMUARM}"
install_xpack_tool "qemu-riscv" "qemu-riscv-xpack" "${QEMURISCV}"

# Create profile.d script to add tools to PATH
PROFILE_SCRIPT="/etc/profile.d/xpack.sh"
echo "#!/bin/bash" > "${PROFILE_SCRIPT}"
echo "# xPack Dev Tools PATH configuration" >> "${PROFILE_SCRIPT}"

# Add each installed tool to PATH
for tool_dir in "${INSTALL_PATH}"/*; do
    if [ -d "$tool_dir" ]; then
        tool_name=$(basename "$tool_dir")
        echo "# ${tool_name}" >> "${PROFILE_SCRIPT}"
        
        # Find bin directory
        if [ -d "$tool_dir/bin" ]; then
            echo "export PATH=\"\$PATH:$tool_dir/bin\"" >> "${PROFILE_SCRIPT}"
        fi
        
        # Some tools might have additional subdirectories
        for subdir in "$tool_dir"/*; do
            if [ -d "$subdir/bin" ] && [ "$subdir" != "$tool_dir/bin" ]; then
                echo "export PATH=\"\$PATH:$subdir/bin\"" >> "${PROFILE_SCRIPT}"
            fi
        done
    fi
done

chmod +x "${PROFILE_SCRIPT}"

# Also add to bashrc and zshrc for immediate availability
if [ -f /etc/bash.bashrc ]; then
    echo "source ${PROFILE_SCRIPT}" >> /etc/bash.bashrc
fi

if [ -f /etc/zsh/zshrc ]; then
    echo "source ${PROFILE_SCRIPT}" >> /etc/zsh/zshrc
fi

# Clean up
rm -rf /var/lib/apt/lists/*

echo "xPack Dev Tools installation completed!"
echo "Installed tools in: ${INSTALL_PATH}"
echo "PATH configuration: ${PROFILE_SCRIPT}"