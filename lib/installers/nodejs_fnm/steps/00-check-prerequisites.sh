#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

main() {
    log "INFO" "Checking Node.js fnm prerequisites..."
    if verify_nodejs_fnm; then
        log "INFO" "↷ fnm and Node.js already installed"
        exit 2
    fi
    
    log "INFO" "Checking for conflicting version managers..."
    for manager in "${NODEJS_CONFLICTING_MANAGERS[@]}"; do
        if command_exists "$manager"; then
            log "WARNING" "⚠ Conflicting version manager: $manager (constitutional: fnm EXCLUSIVE)"
        fi
    done
    [ -d "${HOME}/.nvm" ] && log "WARNING" "⚠ nvm directory detected: ${HOME}/.nvm"

    # Check for snap-installed Node.js (Priority 2: Snap Detection)
    log "INFO" "Checking for snap-installed Node.js..."
    if command -v snap &>/dev/null; then
        if snap list node 2>/dev/null | grep -q '^node'; then
            log "WARNING" "⚠️  Node.js is installed via SNAP"
            log "WARNING" "    This installation uses fnm (different method) and may conflict"
            log "WARNING" "    Recommendation: sudo snap remove node"
            log "WARNING" "    Both installations can coexist, but fnm will take precedence"
        elif snap list nodejs 2>/dev/null | grep -q '^nodejs'; then
            log "WARNING" "⚠️  Node.js is installed via SNAP (as 'nodejs')"
            log "WARNING" "    This installation uses fnm (different method) and may conflict"
            log "WARNING" "    Recommendation: sudo snap remove nodejs"
            log "WARNING" "    Both installations can coexist, but fnm will take precedence"
        else
            log "INFO" "✓ No snap-installed Node.js detected"
        fi
    fi
    
    log "SUCCESS" "✓ Prerequisites check passed - fnm installation needed"
    exit 0
}

main "$@"
