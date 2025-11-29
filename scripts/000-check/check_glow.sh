#!/bin/bash
# check_glow.sh

if command -v glow &> /dev/null; then
    VERSION=$(glow --version 2>&1 | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo "Unknown")
    LOCATION=$(command -v glow)
    
    if [[ "$LOCATION" == *"/usr/bin/"* ]] && dpkg -l glow &>/dev/null; then
        METHOD="APT"
    elif [[ "$LOCATION" == *"/snap/bin/"* ]]; then
        METHOD="Snap"
    elif [[ "$LOCATION" == *"/usr/local/bin/"* ]]; then
        METHOD="Manual"
    else
        METHOD="Other"
    fi
    
    # charmbracelet/glow
    LATEST=$(curl -s https://api.github.com/repos/charmbracelet/glow/releases/latest | grep -oP '"tag_name": "v\K(.*)(?=")' || echo "-")
    
    echo "INSTALLED|$VERSION|$METHOD|$LOCATION|$LATEST"
else
    echo "Not Installed|-|-|-|-"
fi
