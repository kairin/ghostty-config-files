#!/bin/bash
# check_gum.sh

if command -v gum &> /dev/null; then
    VERSION=$(gum --version | grep -oP '\d+\.\d+\.\d+' || echo "Unknown")
    LOCATION=$(command -v gum)
    
    if [[ "$LOCATION" == *"/usr/bin/"* ]] && dpkg -l gum &>/dev/null; then
        METHOD="APT"
    elif [[ "$LOCATION" == *"/usr/local/bin/"* ]]; then
        METHOD="Manual"
    elif [[ "$LOCATION" == *"/go/bin/"* ]]; then
        METHOD="Go"
    else
        METHOD="Other"
    fi
    
    # charmbracelet/gum
    LATEST=$(curl -s https://api.github.com/repos/charmbracelet/gum/releases/latest | grep -oP '"tag_name": "v\K(.*)(?=")' || echo "-")
    
    echo "INSTALLED|$VERSION|$METHOD|$LOCATION|$LATEST"
else
    echo "Not Installed|-|-|-|-"
fi
