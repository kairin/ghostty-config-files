#!/bin/bash
# check_zsh.sh

if command -v zsh &> /dev/null; then
    # Fix regex to handle X.Y or X.Y.Z
    VERSION=$(zsh --version | grep -oP '\d+(\.\d+)+' | head -1 || echo "Unknown")
    LOCATION=$(command -v zsh)
    
    if [[ "$LOCATION" == *"/usr/bin/"* ]] && dpkg -l zsh &>/dev/null; then
        METHOD="APT"
    else
        METHOD="Other"
    fi
    
    # Check for Oh My Zsh
    OMZ_STATUS=""
    if [ -d "$HOME/.oh-my-zsh" ]; then
        OMZ_STATUS="^OMZ: Installed"
    fi
    
    LATEST=$(apt-cache policy zsh | grep "Candidate:" | awk '{print $2}' | grep -oP '\d+(\.\d+)+' | head -1 || echo "-")
    
    echo "INSTALLED|$VERSION|$METHOD|$LOCATION$OMZ_STATUS|$LATEST"
else
    echo "Not Installed|-|-|-|-"
fi
