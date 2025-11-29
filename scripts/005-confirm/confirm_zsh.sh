#!/bin/bash
# confirm_zsh.sh

if command -v zsh &> /dev/null; then
    echo "Zsh is installed."
    zsh --version
else
    echo "Zsh is NOT installed."
    exit 1
fi
