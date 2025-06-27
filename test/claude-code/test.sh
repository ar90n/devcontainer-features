#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "claude command exists" command -v claude
check "claude version" claude --version

# Report result
reportResults