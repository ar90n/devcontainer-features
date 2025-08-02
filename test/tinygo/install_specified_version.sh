#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "tinygo version" tinygo version

# Check that the correct version is installed
check "tinygo version is 0.38.0" tinygo version | grep "0.38.0"

# Check that TinyGo is in the PATH
check "tinygo in PATH" which tinygo

# Check that TINYGOROOT is set
check "TINYGOROOT is set" test -n "$TINYGOROOT"

# Check that tinygo can run a simple command
check "tinygo help works" tinygo help

# Report result
reportResults