#!/bin/bash
# Install ShellCheck via APT

set -e

echo "Installing ShellCheck..."
sudo apt-get update -qq
sudo apt-get install -y shellcheck

echo "ShellCheck installed successfully"
shellcheck --version
