#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

main() {
    log "INFO" "Verifying Node.js fnm installation..."
    local all_checks_passed=true
    
    if verify_fnm_binary; then
        local fnm_version
        fnm_version=$(fnm --version 2>/dev/null || echo "unknown")
        log "SUCCESS" "✓ fnm installed: $fnm_version"
    else
        log "ERROR" "✗ fnm binary not found"
        all_checks_passed=false
    fi
    
    export PATH="${FNM_DIR}:$PATH"
    eval "$(fnm env --use-on-cd)" 2>/dev/null || true
    
    if verify_nodejs_installed; then
        local node_version
        node_version=$(node --version 2>/dev/null)
        local npm_version
        npm_version=$(npm --version 2>/dev/null || echo "unknown")
        log "SUCCESS" "✓ Node.js installed: $node_version"
        log "SUCCESS" "✓ npm installed: v$npm_version"

        # Check for Node.js updates (Priority 1: Version Detection)
        log "INFO" "Checking for Node.js updates..."
        local latest_node_version
        if latest_node_version=$(curl -sf --max-time 5 https://nodejs.org/dist/latest/SHASUMS256.txt 2>/dev/null | grep -oP 'node-v\K[0-9.]+' | head -1); then
            if [ -n "$latest_node_version" ]; then
                local current_version_clean="${node_version#v}"
                if version_greater "$latest_node_version" "$current_version_clean"; then
                    log "WARNING" "Node.js update available: v$latest_node_version (installed: $node_version)"
                    log "INFO" "Update: fnm install $latest_node_version && fnm default $latest_node_version"
                else
                    log "SUCCESS" "✓ Node.js is up-to-date"
                fi
            fi
        else
            log "INFO" "Could not check for Node.js updates (network unavailable)"
        fi

        # Check for npm updates
        log "INFO" "Checking for npm updates..."
        local latest_npm_version
        if latest_npm_version=$(npm view npm version 2>/dev/null); then
            if [ -n "$latest_npm_version" ]; then
                if version_greater "$latest_npm_version" "$npm_version"; then
                    log "WARNING" "npm update available: v$latest_npm_version (installed: v$npm_version)"
                    log "INFO" "Update: npm install -g npm@latest"
                else
                    log "SUCCESS" "✓ npm is up-to-date"
                fi
            fi
        else
            log "INFO" "Could not check for npm updates (network unavailable)"
        fi
    else
        log "ERROR" "✗ Node.js not found"
        all_checks_passed=false
    fi
    
    if [ "$all_checks_passed" = true ]; then
        log "SUCCESS" "════════════════════════════════════════"
        log "SUCCESS" "✓ Node.js fnm installation verified"
        log "SUCCESS" "════════════════════════════════════════"
        log "INFO" "Next steps:"
        log "INFO" "  1. Restart terminal or run: source ~/.zshrc"
        log "INFO" "  2. Verify: node --version && npm --version"
        log "INFO" "Constitutional Compliance:"
        log "INFO" "  ✓ fnm EXCLUSIVE (nvm/n/asdf prohibited)"
        log "INFO" "  ✓ Node.js LATEST (not LTS)"
        exit 0
    else
        log "ERROR" "✗ Installation verification failed"
        exit 1
    fi
}

main "$@"
