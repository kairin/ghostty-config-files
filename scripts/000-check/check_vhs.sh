#!/bin/bash
# check_vhs.sh

if command -v vhs &> /dev/null; then
    VERSION=$(vhs --version | grep -oP '\d+\.\d+\.\d+' || echo "Unknown")
    LOCATION=$(command -v vhs)
    
    if [[ "$LOCATION" == *"/usr/bin/"* ]] && dpkg -l vhs &>/dev/null; then
        METHOD="APT"
    elif [[ "$LOCATION" == *"/usr/local/bin/"* ]]; then
        METHOD="Manual"
    else
        METHOD="Other"
    fi
    
    # charmbracelet/vhs
    LATEST=$(curl -s https://api.github.com/repos/charmbracelet/vhs/releases/latest | grep -oP '"tag_name": "v\K(.*)(?=")' || echo "-")
    
    echo "INSTALLED|$VERSION|$METHOD|$LOCATION|$LATEST"
else
    echo "Not Installed|-|-|-|-"
fi
