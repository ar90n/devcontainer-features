#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
# Since no tools are installed by default, just check that the installation path exists
check "installation path exists" test -d /opt/xpack

# Check that profile script was created
check "profile script exists" test -f /etc/profile.d/xpack.sh

# Report result
reportResults