#!/usr/bin/env bash
# lib/verification/tests/context-menu-test.sh - Context menu + Ghostty integration test
# Tests right-click context menu can launch Ghostty

set -euo pipefail

[ -z "${CONTEXT_MENU_TEST_LOADED:-}" ] || return 0
CONTEXT_MENU_TEST_LOADED=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../core/logging.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/../../core/utils.sh" 2>/dev/null || true

# Fallback log function
log() { local level="$1"; shift; echo "[$level] $*"; }
command_exists() { command -v "$1" &>/dev/null; }

test_context_menu_ghostty_integration() {
    log "INFO" "Testing Context menu + Ghostty integration..."

    # Check 1: Context menu script exists
    local script_path="$HOME/.local/share/nautilus/scripts/Open in Ghostty"
    if [ ! -f "$script_path" ]; then
        log "ERROR" "Context menu script not found: $script_path"
        return 1
    fi

    # Check 2: Script is executable
    if [ ! -x "$script_path" ]; then
        log "ERROR" "Context menu script not executable"
        return 1
    fi

    # Check 3: Script references Ghostty binary
    if ! grep -q "ghostty" "$script_path"; then
        log "ERROR" "Script does not reference Ghostty"
        return 1
    fi
    log "INFO" "  Script references Ghostty"

    # Check 4: Ghostty binary exists
    local ghostty_path="${GHOSTTY_APP_DIR:-$HOME/.local/share/ghostty}/bin/ghostty"
    if [ ! -x "$ghostty_path" ] && ! command_exists "ghostty"; then
        log "ERROR" "Ghostty binary not found or not executable"
        return 1
    fi

    # Check 5: Script uses working directory launch
    if grep -q "NAUTILUS_SCRIPT_CURRENT_URI\|nautilus_script_current_uri" "$script_path"; then
        log "INFO" "  Script configured to open in current directory"
    else
        log "WARNING" "Script may not respect current directory"
    fi

    log "SUCCESS" "Context menu + Ghostty integration working"
    return 0
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_context_menu_ghostty_integration
    exit $?
fi

export -f test_context_menu_ghostty_integration
