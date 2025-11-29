#!/bin/bash
# uninstall_zsh.sh

if command -v zsh &> /dev/null; then
    echo "Uninstalling zsh..."
    sudo apt-get remove -y zsh
    echo "Zsh uninstalled."
else
    echo "Zsh not installed."
fi
