#!/bin/bash
# confirm_glow.sh

if command -v glow &> /dev/null; then
    echo "Glow is installed."
    glow --version
else
    echo "Glow is NOT installed."
    exit 1
fi
