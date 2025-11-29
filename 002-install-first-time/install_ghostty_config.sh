#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Installing Ghostty configurations..."

CONFIG_SRC="$(dirname "$0")/../configs/ghostty"
CONFIG_DEST="$HOME/.config/ghostty"

if [ ! -d "$CONFIG_SRC" ]; then
    log "ERROR" "Config source not found: $CONFIG_SRC"
    exit 1
fi

mkdir -p "$CONFIG_DEST"

# Copy all config files
cp -r "$CONFIG_SRC"/* "$CONFIG_DEST/"

log "SUCCESS" "Ghostty configurations installed to $CONFIG_DEST"
