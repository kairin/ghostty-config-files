#!/bin/bash

set -euo pipefail

# Check for sudo access upfront
if ! sudo -n true 2>/dev/null; then
    echo "Error: sudo password is required, but cannot be prompted in this environment."
    echo "Please run 'sudo -v' in your terminal before executing this script."
    exit 1
fi

# This script provides a simple launcher for setting up Ghostty on a fresh Ubuntu 25.04 PC.
# It ensures the Ghostty application is cloned, the configuration repository is present,
# and then runs the necessary installation and update scripts.

# Define paths
GHOSTTY_APP_DIR="$HOME/Apps/ghostty"
GHOSTTY_CONFIG_DIR="$HOME/.config/ghostty"

echo "======================================="
echo "          Ghostty Setup Launcher"
echo "======================================="

# Step 1: Ensure Ghostty application is cloned
if [ ! -d "$GHOSTTY_APP_DIR" ]; then
    echo "-> Ghostty application not found. Cloning into $GHOSTTY_APP_DIR..."
    if ! git clone https://github.com/ghostty-org/ghostty.git "$GHOSTTY_APP_DIR"; then
        echo "Error: Failed to clone Ghostty application. Please check your internet connection and Git installation."
        exit 1
    fi
else
    echo "-> Ghostty application already exists at $GHOSTTY_APP_DIR."
fi

# Step 2: Ensure Ghostty configuration repository is present
# This script is expected to be run from within the cloned Ghostty config directory.
# We'll just confirm we are in the correct directory.
if [ "$(pwd)" != "$GHOSTTY_CONFIG_DIR" ]; then
    echo "Warning: This script is intended to be run from $GHOSTTY_CONFIG_DIR."
    echo "Please navigate to $GHOSTTY_CONFIG_DIR and run ./setup_ghostty.sh"
    exit 1
fi
echo "-> Ghostty configuration repository found at $GHOSTTY_CONFIG_DIR."

# Step 3: Run the Ghostty configuration installation script
echo "-> Running Ghostty configuration installation script..."
if ! "$GHOSTTY_CONFIG_DIR/scripts/install_ghostty_config.sh"; then
    echo "Error: Ghostty configuration installation failed."
    exit 1
fi

# Step 4: Run the Ghostty application update script (builds and installs Ghostty)
echo "-> Running Ghostty application update script..."
if ! "$GHOSTTY_CONFIG_DIR/scripts/update_ghostty.sh"; then
    echo "Error: Ghostty application update/build failed."
    exit 1
fi

echo "======================================="
echo "        Ghostty Setup Complete!"
echo "======================================="
echo "You may need to restart your terminal or log out and back in for changes to take full effect."
