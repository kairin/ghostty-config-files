#!/bin/bash

set -euo pipefail

CONFIG_UPDATED=false
APP_UPDATED=false

# Function to get Ghostty version
get_ghostty_version() {
    if command -v ghostty &> /dev/null; then
        if ghostty --version 2>/dev/null | head -n 1 | awk '{print $NF}'; then
            ghostty --version 2>/dev/null | head -n 1 | awk '{print $NF}'
        else
            echo ""
        fi
    else
        echo ""
    fi
}

# This script automates the process of updating Ghostty to the latest version.

# Pull latest changes for the config repository itself
echo "-> Pulling latest changes for Ghostty config..."
if ! CONFIG_PULL_OUTPUT=$(git pull 2>&1); then
    echo "Error: Failed to pull Ghostty config changes."
    exit 1
fi


if [[ "$CONFIG_PULL_OUTPUT" == *"Already up to date."* ]]; then
    echo "Ghostty config is already up to date."
    CONFIG_UPDATED=false
else
    echo "$CONFIG_PULL_OUTPUT"
    echo "Ghostty config updated."
    CONFIG_UPDATED=true
fi

echo "Starting dependency check..."

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
    echo "Checking dependency: $dep"
    if ! dpkg -s "$dep" >/dev/null 2>&1; then
        echo "dpkg -s exit code: $?"
        MISSING_DEPS+=("$dep")
    fi
done

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    echo "Required dependencies are not installed: ${MISSING_DEPS[*]}"
    echo "Please run the following command manually to install them, then re-run this script:"
    echo "sudo apt update && sudo apt install -y ${MISSING_DEPS[*]}"
    exit 1
fi

echo "Getting old Ghostty version..."
OLD_VERSION=$(get_ghostty_version)

echo "======================================="
echo "  Updating Ghostty to the latest version"
echo "======================================="

# Navigate to the Ghostty repository
cd ~/Apps/ghostty || { echo "Error: Ghostty application directory not found at ~/Apps/ghostty."; exit 1; }

echo "-> Pulling the latest changes for Ghostty app..."
if ! APP_PULL_OUTPUT=$(git pull 2>&1); then
    echo "Error: Failed to pull Ghostty app changes."
    exit 1
fi

if [[ "$APP_PULL_OUTPUT" == *"Already up to date."* ]]; then
    echo "Ghostty app is already up to date."
    APP_UPDATED=false
else
    echo "$APP_PULL_OUTPUT"
    echo "Ghostty app updated."
    APP_UPDATED=true
fi

echo "-> Building Ghostty..."
if ! DESTDIR=/tmp/ghostty zig build --prefix /usr -Doptimize=ReleaseFast -Dcpu=baseline; then
    echo "Error: Ghostty build failed."
    APP_UPDATED=false
    exit 1
fi

echo "-> Installing Ghostty..."
if ! sudo cp -r /tmp/ghostty/usr/* /usr/; then
    echo "Error: Ghostty installation failed."
    APP_UPDATED=false
    exit 1
fi

# Return to config directory to pull latest config changes


echo "======================================="
echo "  Ghostty Update Summary"
echo "======================================="

NEW_VERSION=$(get_ghostty_version)

if [ "$CONFIG_UPDATED" = true ]; then
    echo "Ghostty config: Updated"
else
    echo "Ghostty config: Already up to date"
fi

if [ "$APP_UPDATED" = true ]; then
    echo "Ghostty app: Updated to version $NEW_VERSION"
elif [ -n "$NEW_VERSION" ]; then
    echo "Ghostty app: Already at version $NEW_VERSION"
else
    echo "Ghostty app: Not found or not updated"
fi

if [ -z "$OLD_VERSION" ] && [ -z "$NEW_VERSION" ]; then
    echo "Overall Status: Failed (Ghostty not found)"
elif [ "$CONFIG_UPDATED" = true ] || [ "$APP_UPDATED" = true ]; then
    echo "Overall Status: Success (Updates applied)"
else
    echo "Overall Status: Already up to date"
fi
echo "======================================="