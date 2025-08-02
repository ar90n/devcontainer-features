#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "tinygo version" tinygo version

# Check that TinyGo is in the PATH
check "tinygo in PATH" which tinygo

# Check that TinyGo is installed in the expected location
check "tinygo installed in /usr/local/bin" test -f /usr/local/bin/tinygo

# Check that TINYGOROOT is set
check "TINYGOROOT is set" test -n "$TINYGOROOT"

# Check that tinygo can run a simple command
check "tinygo help works" tinygo help

# Report result
reportResults