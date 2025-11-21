#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

main() {
    log "INFO" "Verifying Node.js fnm installation..."
    local all_checks_passed=true
    
    if verify_fnm_binary; then
        local fnm_version=$(fnm --version 2>/dev/null || echo "unknown")
        log "SUCCESS" "✓ fnm installed: $fnm_version"
    else
        log "ERROR" "✗ fnm binary not found"
        all_checks_passed=false
    fi
    
    export PATH="${FNM_DIR}:$PATH"
    eval "$(fnm env --use-on-cd)" 2>/dev/null || true
    
    if verify_nodejs_installed; then
        local node_version=$(node --version 2>/dev/null)
        local npm_version=$(npm --version 2>/dev/null || echo "unknown")
        log "SUCCESS" "✓ Node.js installed: $node_version"
        log "SUCCESS" "✓ npm installed: v$npm_version"
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
