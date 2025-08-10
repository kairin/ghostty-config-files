#!/bin/bash

# This script automates the process of updating Zig to version 0.14.1.

LATEST_VERSION="0.14.1"
FILE_NAME="zig-x86_64-linux-$LATEST_VERSION"
ARCHIVE_NAME="$FILE_NAME.tar.xz"
DOWNLOAD_URL="https://ziglang.org/download/$LATEST_VERSION/$ARCHIVE_NAME"


echo "Updating Zig to version $LATEST_VERSION"

# Try to download the latest version
if ! wget "$DOWNLOAD_URL"; then
    echo "Could not download the file from the URL. Checking for a local file."
    if [ ! -f "$ARCHIVE_NAME" ]; then
        echo "Local file not found. Please download the file manually and place it in the same directory as the script."
        exit 1
    else
        echo "Using local file."
    fi
fi

# Extract the archive
tar -xf "$ARCHIVE_NAME"

# Remove the old Zig installation
sudo rm -rf /usr/local/zig

# Move the new version
sudo mv "$FILE_NAME" /usr/local/zig

# Verify the new version
zig version

# Clean up the downloaded archive if it was downloaded
if [ -f "$ARCHIVE_NAME" ]; then
    rm "$ARCHIVE_NAME"
fi


echo "Zig has been updated to version $LATEST_VERSION"
