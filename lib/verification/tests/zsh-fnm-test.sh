#!/usr/bin/env bash
# lib/verification/tests/zsh-fnm-test.sh - ZSH + fnm integration test
# Tests fnm shell integration works correctly in ZSH environment

set -euo pipefail

[ -z "${ZSH_FNM_TEST_LOADED:-}" ] || return 0
ZSH_FNM_TEST_LOADED=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../core/logging.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/../../core/utils.sh" 2>/dev/null || true

# Fallback log function
log() { local level="$1"; shift; echo "[$level] $*"; }
command_exists() { command -v "$1" &>/dev/null; }

test_zsh_fnm_integration() {
    log "INFO" "Testing ZSH + fnm integration..."

    # Check 1: .zshrc exists
    if [ ! -f "$HOME/.zshrc" ]; then
        log "ERROR" ".zshrc not found - cannot test integration"
        return 1
    fi

    # Check 2: fnm env configured in .zshrc
    if ! grep -q "fnm env" "$HOME/.zshrc"; then
        log "ERROR" "fnm shell integration not configured in .zshrc"
        log "ERROR" "Missing: eval \"\$(fnm env --use-on-cd)\""
        return 1
    fi
    log "INFO" "  fnm env configured in .zshrc"

    # Check 3: fnm is in PATH
    if ! command_exists "fnm"; then
        log "ERROR" "fnm not in current PATH"
        return 1
    fi

    # Check 4: fnm can list versions
    if ! fnm list &>/dev/null; then
        log "ERROR" "fnm list command failed"
        return 1
    fi

    local installed_versions
    installed_versions=$(fnm list 2>&1)
    if [ -z "$installed_versions" ]; then
        log "WARNING" "No Node.js versions installed via fnm"
    else
        log "INFO" "  fnm managing Node.js versions"
    fi

    log "SUCCESS" "ZSH + fnm integration working"
    return 0
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_zsh_fnm_integration
    exit $?
fi

export -f test_zsh_fnm_integration
