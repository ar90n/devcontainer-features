#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "cmake installed" which cmake
check "cmake version 3.28.6-1" cmake --version | grep "3.28.6"

check "gcc installed" which gcc
check "gcc version" gcc --version

check "openocd installed" which openocd
check "openocd version 0.12.0-4" openocd --version 2>&1 | grep "0.12.0"

# Check installation paths
check "cmake in xpack" test -d /opt/xpack/cmake
check "gcc in xpack" test -d /opt/xpack/gcc
check "openocd in xpack" test -d /opt/xpack/openocd

# Report result
reportResults