#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Removing ALL zsh installations..."

removed_count=0

# 1. Remove APT package if installed
if dpkg -l zsh 2>/dev/null | grep -q '^ii'; then
    log "INFO" "Found zsh apt package, removing..."
    if sudo apt-get remove -y zsh; then
        ((removed_count++))
        log "SUCCESS" "zsh APT package removed"
    else
        log "WARNING" "Failed to remove zsh apt package"
    fi
fi

# 2. Remove Snap if installed
if snap list zsh 2>/dev/null | grep -q zsh; then
    log "INFO" "Found zsh snap package, removing..."
    if sudo snap remove zsh; then
        ((removed_count++))
        log "SUCCESS" "Snap package removed"
    else
        log "WARNING" "Failed to remove snap package"
    fi
fi

# 3. Remove Oh My Zsh if installed
if [ -d "$HOME/.oh-my-zsh" ]; then
    log "INFO" "Found Oh My Zsh at ~/.oh-my-zsh, removing..."
    if rm -rf "$HOME/.oh-my-zsh"; then
        ((removed_count++))
        log "SUCCESS" "Removed Oh My Zsh"
    else
        log "WARNING" "Failed to remove Oh My Zsh"
    fi
fi

# 4. Remove from /usr/local/bin (manual install)
if [ -f "/usr/local/bin/zsh" ]; then
    log "INFO" "Found zsh at /usr/local/bin/zsh, removing..."
    if sudo rm -f "/usr/local/bin/zsh"; then
        ((removed_count++))
        log "SUCCESS" "Removed /usr/local/bin/zsh"
    else
        log "WARNING" "Failed to remove /usr/local/bin/zsh"
    fi
fi

# 5. Check for any other zsh binaries in PATH
if command -v zsh &>/dev/null; then
    remaining=$(which zsh)
    log "WARNING" "zsh still found at: $remaining"
    log "WARNING" "This may be a system shell - manual cleanup may be required"
fi

# 6. Report results
if [ $removed_count -eq 0 ]; then
    if ! command -v zsh &>/dev/null; then
        log "INFO" "zsh is not installed, nothing to do"
    else
        log "WARNING" "zsh still found - may be a system default shell"
        log "WARNING" "Ensure you change your default shell before removing zsh"
    fi
else
    if ! command -v zsh &>/dev/null; then
        log "SUCCESS" "All zsh installations removed ($removed_count methods cleaned)"
    else
        remaining=$(which zsh)
        log "WARNING" "Removed $removed_count installations, but zsh still found at: $remaining"
    fi
    log "INFO" "Remember to remove .zshrc and zsh-related config if no longer needed"
fi
