#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "ttyd command exists" command -v ttyd
check "ttyd executable" test -x /usr/local/bin/ttyd
check "ttyd version" ttyd --version

# Report result
reportResults