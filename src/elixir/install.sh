#!/usr/bin/env bash

set -e

# Clean up
rm -rf /var/lib/apt/lists/*

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Function to check if packages are installed
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt-get update -y
        apt-get -y install --no-install-recommends "$@"
    fi
}

echo "Installing Elixir..."

# Install required packages for adding repositories
check_packages software-properties-common gnupg ca-certificates

# Add RabbitMQ Erlang PPA
# This provides up-to-date Erlang and Elixir packages
echo "Adding RabbitMQ Erlang PPA..."
add-apt-repository -y ppa:rabbitmq/rabbitmq-erlang

# Update package lists
apt-get update -y

# Install Erlang and Elixir
echo "Installing Erlang and Elixir..."
apt-get install -y erlang elixir

# Verify installations
echo "Verifying installations..."
elixir --version
erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"