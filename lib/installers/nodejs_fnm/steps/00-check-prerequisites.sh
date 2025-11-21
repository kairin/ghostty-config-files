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
    
    log "SUCCESS" "✓ Prerequisites check passed - fnm installation needed"
    exit 0
}

main "$@"
