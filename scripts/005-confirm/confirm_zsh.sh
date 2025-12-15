#!/bin/bash
# confirm_zsh.sh
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Confirming zsh installation..."

if command -v zsh &> /dev/null; then
    VERSION=$(zsh --version 2>/dev/null | head -1)
    PATH_LOC=$(command -v zsh)
    log "SUCCESS" "zsh is installed at $PATH_LOC"
    log "SUCCESS" "Version: $VERSION"

    # Check for Oh My Zsh
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log "SUCCESS" "Oh My Zsh is installed at $HOME/.oh-my-zsh"
    else
        log "WARNING" "Oh My Zsh is not installed"
    fi

    # Generate artifact manifest for future verification
    SCRIPT_DIR="$(dirname "$0")"
    VERSION_NUM=$(echo "$VERSION" | grep -oP '\d+\.\d+' || echo "unknown")
    "$SCRIPT_DIR/generate_manifest.sh" zsh "$VERSION_NUM" apt > /dev/null 2>&1 || log "WARNING" "Failed to generate manifest"
    log "SUCCESS" "Artifact manifest generated for pre-reinstall verification"
else
    log "ERROR" "zsh is NOT installed"
    exit 1
fi
