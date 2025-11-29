#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Uninstalling Node.js (fnm)..."

# Remove fnm directory
if [ -d "$HOME/.local/share/fnm" ]; then
    rm -rf "$HOME/.local/share/fnm"
    log "SUCCESS" "Removed $HOME/.local/share/fnm"
else
    log "INFO" "fnm directory not found"
fi

# Remove legacy location if exists
if [ -d "$HOME/.fnm" ]; then
    rm -rf "$HOME/.fnm"
    log "SUCCESS" "Removed $HOME/.fnm"
fi

log "WARNING" "Please manually remove fnm configuration from your shell rc files (.zshrc, .bashrc)"
log "SUCCESS" "Node.js (fnm) uninstallation complete"
