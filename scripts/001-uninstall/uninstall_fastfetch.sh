#!/bin/bash
# uninstall_fastfetch.sh

if command -v fastfetch &> /dev/null; then
    echo "Uninstalling fastfetch..."
    if dpkg -l fastfetch &> /dev/null; then
        sudo apt-get remove -y fastfetch
    else
        # Manual removal if not apt
        LOCATION=$(command -v fastfetch)
        sudo rm -f "$LOCATION"
    fi
    echo "Fastfetch uninstalled."
else
    echo "Fastfetch not installed."
fi
