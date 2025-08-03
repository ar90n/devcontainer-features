#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "arm-none-eabi-gcc installed" which arm-none-eabi-gcc
check "arm-none-eabi-gcc version" arm-none-eabi-gcc --version

check "arm-none-eabi-g++ installed" which arm-none-eabi-g++
check "arm-none-eabi-gdb installed" which arm-none-eabi-gdb

# Check installation path
check "arm gcc in xpack" test -d /opt/xpack/arm-none-eabi-gcc

# Report result
reportResults