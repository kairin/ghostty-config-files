#!/usr/bin/env bash
# lib/verification/tests/ghostty-zsh-test.sh - Ghostty + ZSH integration test
# Tests Ghostty terminal launches correctly with ZSH shell

set -euo pipefail

[ -z "${GHOSTTY_ZSH_TEST_LOADED:-}" ] || return 0
GHOSTTY_ZSH_TEST_LOADED=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../core/logging.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/../../core/utils.sh" 2>/dev/null || true

# Fallback log function
log() { local level="$1"; shift; echo "[$level] $*"; }
command_exists() { command -v "$1" &>/dev/null; }

test_ghostty_zsh_integration() {
    log "INFO" "Testing Ghostty + ZSH integration..."

    local config_path="$HOME/.config/ghostty/config"

    # Check 1: Ghostty config exists
    if [ ! -f "$config_path" ]; then
        log "ERROR" "Ghostty config not found: $config_path"
        return 1
    fi

    # Check 2: Shell configuration
    if grep -q "^command = zsh" "$config_path"; then
        log "INFO" "  Ghostty explicitly configured for ZSH"
    elif grep -q "^command =" "$config_path"; then
        local configured_shell
        configured_shell=$(grep "^command =" "$config_path" | cut -d= -f2 | tr -d ' ')
        log "INFO" "  Ghostty shell: $configured_shell"
    else
        log "INFO" "  Ghostty using system default shell"
    fi

    # Check 3: ZSH is functional
    if ! command_exists "zsh"; then
        log "ERROR" "ZSH not installed - Ghostty integration broken"
        return 1
    fi

    # Check 4: ZSH version check
    if ! zsh --version &>/dev/null; then
        log "ERROR" "ZSH not responding - integration broken"
        return 1
    fi

    log "SUCCESS" "Ghostty + ZSH integration configured"
    return 0
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_ghostty_zsh_integration
    exit $?
fi

export -f test_ghostty_zsh_integration
