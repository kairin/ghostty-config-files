#!/bin/bash
# uninstall_gum.sh

if command -v gum &> /dev/null; then
    LOCATION=$(command -v gum)
    echo "Uninstalling gum from $LOCATION..."
    
    if [[ "$LOCATION" == *"/usr/bin/"* ]] && dpkg -l gum &>/dev/null; then
        sudo apt-get remove -y gum
    else
        # Assume manual/go install
        rm -f "$LOCATION"
        echo "Removed binary $LOCATION"
    fi
    
    echo "Gum uninstalled."
else
    echo "Gum not installed."
fi
