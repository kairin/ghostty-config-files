#!/bin/bash
# confirm_gum.sh

if command -v gum &> /dev/null; then
    echo "Gum is installed."
    gum --version
else
    echo "Gum is NOT installed."
    exit 1
fi
