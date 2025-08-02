#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "elixir version" elixir --version

# Check that Elixir is in the PATH
check "elixir in PATH" which elixir

# Check that Erlang is installed
check "erlang version" erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell

# Check that iex (Interactive Elixir) works
check "iex available" which iex

# Check that mix (build tool) is available
check "mix available" mix --version

# Check hex (package manager) can be installed
check "hex installable" mix local.hex --force

# Report result
reportResults