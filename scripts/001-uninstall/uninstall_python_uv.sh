#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Removing ALL uv (Python package manager) installations..."

removed_count=0

# 1. Remove from ~/.local/bin (common install location)
if [ -f "$HOME/.local/bin/uv" ]; then
    log "INFO" "Found uv at ~/.local/bin/uv, removing..."
    if rm -f "$HOME/.local/bin/uv"; then
        ((removed_count++))
        log "SUCCESS" "Removed ~/.local/bin/uv"
    else
        log "WARNING" "Failed to remove ~/.local/bin/uv"
    fi
fi

# Also remove uvx if present
if [ -f "$HOME/.local/bin/uvx" ]; then
    log "INFO" "Found uvx at ~/.local/bin/uvx, removing..."
    rm -f "$HOME/.local/bin/uvx"
fi

# 2. Remove from ~/.cargo/bin (if installed via cargo)
if [ -f "$HOME/.cargo/bin/uv" ]; then
    log "INFO" "Found uv at ~/.cargo/bin/uv, removing..."
    if rm -f "$HOME/.cargo/bin/uv"; then
        ((removed_count++))
        log "SUCCESS" "Removed ~/.cargo/bin/uv"
    else
        log "WARNING" "Failed to remove ~/.cargo/bin/uv"
    fi
fi

# 3. Remove from /usr/local/bin
if [ -f "/usr/local/bin/uv" ]; then
    log "INFO" "Found uv at /usr/local/bin/uv, removing..."
    if sudo rm -f "/usr/local/bin/uv"; then
        ((removed_count++))
        log "SUCCESS" "Removed /usr/local/bin/uv"
    else
        log "WARNING" "Failed to remove /usr/local/bin/uv"
    fi
fi

# 4. Remove uv cache and data directories
if [ -d "$HOME/.local/share/uv" ]; then
    log "INFO" "Removing uv data directory..."
    rm -rf "$HOME/.local/share/uv"
fi

if [ -d "$HOME/.cache/uv" ]; then
    log "INFO" "Removing uv cache directory..."
    rm -rf "$HOME/.cache/uv"
fi

# 5. Check for any other uv binaries in PATH
if command -v uv &>/dev/null; then
    remaining=$(which uv)
    log "WARNING" "uv still found at: $remaining"
    log "WARNING" "Manual cleanup may be required"
fi

# 6. Report results
if [ $removed_count -eq 0 ]; then
    if ! command -v uv &>/dev/null; then
        log "INFO" "uv is not installed, nothing to do"
    else
        log "ERROR" "Could not remove uv - still found in PATH"
        exit 1
    fi
else
    if ! command -v uv &>/dev/null; then
        log "SUCCESS" "All uv installations removed ($removed_count methods cleaned)"
    else
        remaining=$(which uv)
        log "WARNING" "Removed $removed_count installations, but uv still found at: $remaining"
    fi
fi
