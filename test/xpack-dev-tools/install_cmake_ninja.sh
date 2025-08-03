#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "cmake installed" which cmake
check "cmake version" cmake --version

check "ninja installed" which ninja
check "ninja version" ninja --version

# Check installation paths
check "cmake in xpack" test -d /opt/xpack/cmake
check "ninja in xpack" test -d /opt/xpack/ninja-build

# Report result
reportResults