#!/bin/bash
# check_zsh.sh - Check ZSH, Oh My Zsh, Powerlevel10k, and plugins

if command -v zsh &> /dev/null; then
    # Get ZSH version
    VERSION=$(zsh --version | grep -oP '\d+(\.\d+)+' | head -1 || echo "Unknown")
    LOCATION=$(command -v zsh)

    # Detect installation method
    if [[ "$LOCATION" == *"/usr/bin/"* ]] && dpkg -l zsh &>/dev/null; then
        METHOD="APT"
    else
        METHOD="Other"
    fi

    # Check for Oh My Zsh
    OMZ_STATUS="no"
    if [ -d "$HOME/.oh-my-zsh" ]; then
        OMZ_STATUS="yes"
    fi

    # Check for Powerlevel10k
    P10K_STATUS="no"
    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    if [ -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
        P10K_STATUS="yes"
    fi

    # Check external plugins (3 total: autosuggestions, syntax-highlighting, fzf)
    PLUGIN_COUNT=0
    PLUGIN_TOTAL=3

    if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        ((PLUGIN_COUNT++))
    fi

    if [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        ((PLUGIN_COUNT++))
    fi

    if [ -d "$HOME/.fzf" ]; then
        ((PLUGIN_COUNT++))
    fi

    # Build extra info string
    EXTRA="^omz:$OMZ_STATUS^p10k:$P10K_STATUS^plugins:$PLUGIN_COUNT/$PLUGIN_TOTAL"

    # Get latest version from apt
    LATEST=$(apt-cache policy zsh | grep "Candidate:" | awk '{print $2}' | grep -oP '\d+(\.\d+)+' | head -1 || echo "-")

    echo "INSTALLED|$VERSION|$METHOD|$LOCATION$EXTRA|$LATEST"
else
    echo "Not Installed|-|-|-|-"
fi
