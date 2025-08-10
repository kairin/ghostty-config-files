#!/bin/bash

# This script installs the improved Ghostty configuration and sets it as the default terminal on Ubuntu.

# Create the ghostty config directory if it doesn't exist
mkdir -p ~/.config/ghostty

# Create the config file
cat << EOF > ~/.config/ghostty/config
# Ghostty Configuration File
# A complete list of options can be found by running `ghostty +show-config --default --docs`

config-file = theme.conf
config-file = scroll.conf
config-file = layout.conf
config-file = keybindings.conf

shell-integration = zsh
gtk-tabs-location = top
window-new-tab-position = end
EOF

# Create the keybindings.conf file
cat << EOF > ~/.config/ghostty/keybindings.conf
keybind = ctrl+alt+s=write_screen_file:paste
keybind = ctrl+shift+t=new_tab
keybind = ctrl+alt+d=new_split:right
EOF

# Create the layout.conf file
cat << EOF > ~/.config/ghostty/layout.conf
# Font
font-family = "monospace"
font-size = 14

# Padding
window-padding-x = 10
window-padding-y = 10

# Window Decorations
window-decoration = "auto"

# Recommended additions
background-blur-radius = 20
window-step-resize = true
window-padding-balance = true
EOF

# Create the scroll.conf file
cat << EOF > ~/.config/ghostty/scroll.conf
# Scrollback
scrollback-limit = 10000
EOF

# Create the theme.conf file
cat << EOF > ~/.config/ghostty/theme.conf
# Theme
# A list of available themes can be found by running `ghostty +list-themes`
theme = "catppuccin-mocha"

# Opacity
background-opacity = 0.75
EOF

echo "Ghostty configuration installed successfully!"

# Check if the OS is Ubuntu
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$ID" = "ubuntu" ]; then
        echo "Ubuntu detected. Trying to set Ghostty as the default terminal."

        # Check if ghostty is installed
        if ! command -v ghostty &> /dev/null; then
            echo "Ghostty is not installed or not in your PATH. Please install it first."
            exit 1
        fi

        # Get the path to the ghostty executable
        GHOSTTY_PATH=$(command -v ghostty)

        # Add ghostty to the update-alternatives system
        sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$GHOSTTY_PATH" 50

        # Set ghostty as the default terminal
        sudo update-alternatives --set x-terminal-emulator "$GHOSTTY_PATH"

        echo "Ghostty has been set as the default terminal. You may need to log out and log back in for the changes to take effect."
    fi
fi

echo "You can now run this script on other systems to replicate this configuration."