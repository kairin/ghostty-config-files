#!/bin/bash

# This script automates the process of updating Ghostty to the latest version.

# Check for dependencies and install them if they are missing
if ! dpkg -s libgtk-4-dev >/dev/null 2>&1 || ! dpkg -s libadwaita-1-dev >/dev/null 2>&1; then
    echo "Required dependencies are not installed."
    echo "Installing them now..."
    sudo apt update && sudo apt install -y libgtk-4-dev libadwaita-1-dev
fi

echo "======================================="
echo "  Updating Ghostty to the latest version"
echo "======================================="

# Navigate to the Ghostty repository
cd ~/Apps/ghostty

echo "-> Pulling the latest changes..."
git pull

echo "-> Building Ghostty..."
DESTDIR=/tmp/ghostty zig build --prefix /usr -Doptimize=ReleaseFast -Dcpu=baseline

echo "-> Installing Ghostty..."
sudo cp -r /tmp/ghostty/usr/* /usr/

echo "======================================="
echo "  Ghostty Update Summary"
echo "======================================="
echo "Status: Success"
echo "Ghostty has been updated to the latest version."
echo "======================================="
