#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "gemini command exists" command -v gemini
check "gemini version" gemini --version

# Report result
reportResults