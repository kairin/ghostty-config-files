#!/bin/bash

# This script automates the process of updating Zig to version 0.14.1.

LATEST_VERSION="0.14.1"

echo "Updating Zig to version $LATEST_VERSION"

# Download the latest version
wget "https://ziglang.org/download/$LATEST_VERSION/zig-linux-x86_64-$LATEST_VERSION.tar.xz"

# Extract the archive
tar -xf "zig-linux-x86_64-$LATEST_VERSION.tar.xz"

# Remove the old Zig installation
sudo rm -rf /usr/local/zig

# Move the new version
sudo mv "zig-linux-x86_64-$LATEST_VERSION" /usr/local/zig

# Verify the new version
zig version

# Clean up the downloaded archive
rm "zig-linux-x86_64-$LATEST_VERSION.tar.xz"

echo "Zig has been updated to version $LATEST_VERSION"
