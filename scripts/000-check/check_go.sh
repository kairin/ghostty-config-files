#!/bin/bash
# check_go.sh

if command -v go &> /dev/null; then
    VERSION=$(go version | grep -oP 'go\d+\.\d+\.\d+' | sed 's/go//' || echo "Unknown")
    LOCATION=$(command -v go)
    
    if [[ "$LOCATION" == *"/usr/local/go/bin/"* ]]; then
        METHOD="Official"
    elif [[ "$LOCATION" == *"/usr/bin/"* ]]; then
        METHOD="APT"
    else
        METHOD="Other"
    fi
    
    # golang/go tags are complex, maybe just check go.dev/dl?
    # Or just skip latest for go as it's heavy to parse html.
    # Actually, https://go.dev/VERSION?m=text
    LATEST=$(curl -s https://go.dev/VERSION?m=text | head -n 1 | sed 's/go//' || echo "-")
    
    echo "INSTALLED|$VERSION|$METHOD|$LOCATION|$LATEST"
else
    echo "Not Installed|-|-|-|-"
fi
