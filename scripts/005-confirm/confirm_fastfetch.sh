#!/bin/bash
# confirm_fastfetch.sh

if command -v fastfetch &> /dev/null; then
    echo "Fastfetch is installed."
    fastfetch --version
else
    echo "Fastfetch is NOT installed."
    exit 1
fi
