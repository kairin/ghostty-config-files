#!/bin/bash
# uninstall_vhs.sh

if command -v vhs &> /dev/null; then
    echo "Uninstalling vhs..."
    sudo apt-get remove -y vhs
    echo "VHS uninstalled."
else
    echo "VHS not installed."
fi
