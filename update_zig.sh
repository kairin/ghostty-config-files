#!/bin/bash

# This script automates the process of updating Zig to version 0.14.1.

LATEST_VERSION="0.14.1"
FILE_NAME="zig-linux-x86_64-$LATEST_VERSION"
ARCHIVE_NAME="$FILE_NAME.tar.xz"
DOWNLOAD_URL="https://ziglang.org/download/$LATEST_VERSION/$ARCHIVE_NAME"


echo "Updating Zig to version $LATEST_VERSION"

# Download the latest version
wget "$DOWNLOAD_URL"

# Extract the archive
tar -xf "$ARCHIVE_NAME"

# Remove the old Zig installation
sudo rm -rf /usr/local/zig

# Move the new version
sudo mv "$FILE_NAME" /usr/local/zig

# Verify the new version
zig version

# Clean up the downloaded archive
rm "$ARCHIVE_NAME"

echo "Zig has been updated to version $LATEST_VERSION"