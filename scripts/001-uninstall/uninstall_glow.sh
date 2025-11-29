#!/bin/bash
# uninstall_glow.sh

if command -v glow &> /dev/null; then
    echo "Uninstalling glow..."
    sudo apt-get remove -y glow
    echo "Glow uninstalled."
else
    echo "Glow not installed."
fi
