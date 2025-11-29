#!/bin/bash
# check_fastfetch.sh

if command -v fastfetch &> /dev/null; then
    VERSION=$(fastfetch --version 2>&1 | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo "Unknown")
    LOCATION=$(command -v fastfetch)
    
    # Determine method
    if [[ "$LOCATION" == *"/usr/bin/"* ]] && dpkg -l fastfetch &>/dev/null; then
        METHOD="APT"
    elif [[ "$LOCATION" == *"/usr/local/bin/"* ]]; then
        METHOD="Source"
    else
        METHOD="Other"
    fi
    
    # Get Latest (Optional - for now just placeholder or simple curl if fast)
    # To avoid network delay in dashboard, maybe skip or cache? 
    # The user wants "Latest" column.
    # fastfetch github: fastfetch-cli/fastfetch
    LATEST=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")' || echo "-")
    
    echo "INSTALLED|$VERSION|$METHOD|$LOCATION|$LATEST"
else
    echo "Not Installed|-|-|-|-"
fi
