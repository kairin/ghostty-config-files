#!/bin/bash
# Check if Node.js is installed

# Ensure fnm is in PATH and initialized
export PATH="$HOME/.local/bin:$PATH"
if command -v fnm &> /dev/null; then
    eval "$(fnm env --shell bash)"
fi

# Get Latest Version
LATEST_VER=""
if command -v fnm &> /dev/null; then
    # Get latest version (including Current, not just LTS) to avoid downgrading suggestions
    # fnm ls-remote | tail -n 1
    LATEST_VER=$(fnm ls-remote | tail -n 1)
fi

if command -v node &> /dev/null; then
    VERSION=$(node -v)
    LOCATION=$(which node)
    
    if command -v fnm &> /dev/null; then
        METHOD="fnm"
        FNM_VER=$(fnm --version | head -n 1 | cut -d ' ' -f 2)
    else
        METHOD="System"
        FNM_VER=""
    fi
    
    NPM_VER=""
    if command -v npm &> /dev/null; then
        NPM_VER=$(npm -v)
    fi
    
    # Append extra info to location field, separated by ^
    EXTRA=""
    if [ -n "$NPM_VER" ]; then EXTRA="$EXTRA^npm: v$NPM_VER"; fi
    if [ -n "$FNM_VER" ]; then EXTRA="$EXTRA^fnm: v$FNM_VER"; fi
    
    echo "INSTALLED|$VERSION|$METHOD|$LOCATION$EXTRA|$LATEST_VER"
else
    echo "Not Installed|-|-|-|$LATEST_VER"
fi
