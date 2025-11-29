#!/bin/bash
# confirm_vhs.sh

if command -v vhs &> /dev/null; then
    echo "VHS is installed."
    vhs --version
else
    echo "VHS is NOT installed."
    exit 1
fi
