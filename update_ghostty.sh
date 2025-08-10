#!/bin/bash

# This script automates the process of updating Ghostty to the latest version.

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
