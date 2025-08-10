#!/bin/bash

# Function to get Ghostty version
get_ghostty_version() {
    if command -v ghostty &> /dev/null; then
        ghostty --version 2>/dev/null | head -n 1 | awk '{print $NF}'
    else
        echo ""
    fi
}

# This script automates the process of updating Ghostty to the latest version.

# List of required dependencies
REQUIRED_DEPS=(
    libgtk-4-dev
    libadwaita-1-dev
    blueprint-compiler
    libgtk4-layer-shell-dev
    libfreetype-dev
    libharfbuzz-dev
    libfontconfig-dev
    libpng-dev
    zlib1g-dev
    libglib2.0-dev
    libgio-2.0-dev
    libpango1.0-dev
    libgdk-pixbuf-2.0-dev
    libcairo2-dev
    libvulkan-dev
    libgraphene-1.0-dev
    libx11-dev
    libwayland-dev
)

MISSING_DEPS=()
for dep in "${REQUIRED_DEPS[@]}"; do
    if ! dpkg -s "$dep" >/dev/null 2>&1; then
        MISSING_DEPS+=("$dep")
    fi
done

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    echo "Required dependencies are not installed: ${MISSING_DEPS[*]}"
    echo "Please run the following command manually to install them, then re-run this script:"
    echo "sudo apt update && sudo apt install -y ${MISSING_DEPS[*]}"
    exit 1
fi

OLD_VERSION=$(get_ghostty_version)

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

NEW_VERSION=$(get_ghostty_version)

if [ -z "$OLD_VERSION" ] && [ -z "$NEW_VERSION" ]; then
    echo "Status: Failed"
    echo "Ghostty was not found before or after the update. Please check your installation."
elif [ -z "$OLD_VERSION" ] && [ -n "$NEW_VERSION" ]; then
    echo "Status: Success"
    echo "Ghostty has been installed/updated to version: $NEW_VERSION"
elif [ "$OLD_VERSION" = "$NEW_VERSION" ]; then
    echo "Status: Already up to date"
    echo "Ghostty is already at the latest version: $NEW_VERSION"
else
    echo "Status: Success"
    echo "Ghostty updated from version $OLD_VERSION to $NEW_VERSION."
fi
echo "======================================="