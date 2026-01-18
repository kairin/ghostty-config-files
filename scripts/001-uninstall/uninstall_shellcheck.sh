#!/bin/bash
# Uninstall ShellCheck

set -e

echo "Uninstalling ShellCheck..."
sudo apt-get remove -y shellcheck
sudo apt-get autoremove -y

echo "ShellCheck uninstalled successfully"
