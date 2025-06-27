#!/usr/bin/env bash

set -e

# Clean up
rm -rf /var/lib/apt/lists/*

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Install Gemini CLI globally
echo "Installing Gemini CLI..."
npm install -g @google/gemini-cli

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"