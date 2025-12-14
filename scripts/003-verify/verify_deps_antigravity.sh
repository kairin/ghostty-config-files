#!/bin/bash
# verify_deps_antigravity.sh - Verify dependencies for Google Antigravity

MISSING=0

# Check curl
if ! command -v curl &> /dev/null; then
    echo "curl missing"
    MISSING=1
fi

# Check dpkg
if ! command -v dpkg &> /dev/null; then
    echo "dpkg missing"
    MISSING=1
fi

# Check for basic GTK libraries (needed for Electron-based apps)
if ! dpkg -s libgtk-3-0 &> /dev/null 2>&1; then
    echo "libgtk-3-0 missing (may cause display issues)"
fi

if [[ $MISSING -eq 1 ]]; then
    echo "Some dependencies are missing."
    exit 1
fi

echo "Dependencies verified."
echo "  curl: $(curl --version | head -n 1 | cut -d' ' -f1-2)"
echo "  dpkg: available"
