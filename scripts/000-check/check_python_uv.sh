#!/bin/bash
# check_python_uv.sh

if command -v uv &> /dev/null; then
    VERSION=$(uv --version | grep -oP '\d+\.\d+\.\d+' || echo "Unknown")
    LOCATION=$(command -v uv)
    
    if [[ "$LOCATION" == *".cargo/bin"* ]]; then
        METHOD="Cargo"
    elif [[ "$LOCATION" == *".local/bin"* ]]; then
        METHOD="Script"
    else
        METHOD="Other"
    fi
    
    # astral-sh/uv
    LATEST=$(curl -s https://api.github.com/repos/astral-sh/uv/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")' || echo "-")
    
    echo "INSTALLED|$VERSION|$METHOD|$LOCATION|$LATEST"
else
    echo "Not Installed|-|-|-|-"
fi
