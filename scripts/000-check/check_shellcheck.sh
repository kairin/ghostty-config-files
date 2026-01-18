#!/bin/bash
# Check ShellCheck installation status
# Output format: STATUS|VERSION|METHOD|LOCATION|NOTES

if command -v shellcheck &>/dev/null; then
    VERSION=$(shellcheck --version 2>&1 | grep "version:" | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
    LOCATION=$(command -v shellcheck)
    METHOD="APT"
    echo "INSTALLED|$VERSION|$METHOD|$LOCATION|-"
else
    echo "NOT_INSTALLED|-|-|-|-"
fi
