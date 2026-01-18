#!/bin/bash
# Update ShellCheck via APT

set -e

echo "Updating ShellCheck..."
sudo apt-get update -qq
sudo apt-get install -y --only-upgrade shellcheck

echo "ShellCheck updated successfully"
shellcheck --version
