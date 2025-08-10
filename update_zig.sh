#!/bin/bash

set -euo pipefail

# This script automates the process of updating Zig to version 0.14.1.

echo "======================================="
echo "  Updating Zig to the latest version"
echo "======================================="

LATEST_VERSION="0.14.1"
FILE_NAME="zig-x86_64-linux-$LATEST_VERSION"
ARCHIVE_NAME="$FILE_NAME.tar.xz"
DOWNLOAD_URL="https://ziglang.org/download/$LATEST_VERSION/$ARCHIVE_NAME"

echo "-> Downloading Zig version $LATEST_VERSION..."
if ! wget "$DOWNLOAD_URL"; then
    echo "   Download failed. Checking for a local file."
    if [ ! -f "$ARCHIVE_NAME" ]; then
        echo "   Local file not found. Please download the file manually."
        exit 1
    else
        echo "   Using local file."
    fi
fi

echo "-> Extracting the archive..."
tar -xf "$ARCHIVE_NAME" || { echo "Error: Failed to extract Zig archive."; exit 1; }

echo "-> Installing Zig..."
sudo rm -rf /usr/local/zig || { echo "Error: Failed to remove existing Zig installation."; exit 1; }
sudo mv "$FILE_NAME" /usr/local/zig || { echo "Error: Failed to move Zig to installation directory."; exit 1; }

echo "-> Cleaning up..."
rm "$ARCHIVE_NAME" || { echo "Warning: Failed to remove Zig archive."; }

echo "======================================="
echo "  Zig Update Summary"
echo "======================================="

# Verify installation
INSTALLED_ZIG_VERSION=$(zig version || echo "")
if [ -z "$INSTALLED_ZIG_VERSION" ]; then
    echo "Status: Failed"
    echo "Zig installation could not be verified."
elif [ "$INSTALLED_ZIG_VERSION" = "$LATEST_VERSION" ]; then
    echo "Status: Success"
    echo "Installed version: $INSTALLED_ZIG_VERSION"
else
    echo "Status: Warning"
    echo "Installed version: $INSTALLED_ZIG_VERSION (Expected: $LATEST_VERSION)"
fi
echo "======================================="