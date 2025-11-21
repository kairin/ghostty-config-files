#!/usr/bin/env bash
#
# Module: Verify UV Installation
# Purpose: Comprehensive verification that UV is properly installed and functional
# Prerequisites: All previous UV installation steps completed
# Outputs: Verification report and next steps
# Exit Codes:
#   0 - Verification successful
#   1 - Verification failed
#
# Context7 Best Practices:
# - Test UV binary availability
# - Verify version command works
# - Check PATH configuration
# - Provide usage examples
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

main() {
    log "INFO" "Verifying UV installation..."

    local all_checks_passed=true

    # Check 1: UV binary exists
    if verify_uv_binary; then
        log "SUCCESS" "✓ UV binary installed at $UV_BINARY"
    else
        log "ERROR" "✗ UV binary not found"
        all_checks_passed=false
    fi

    # Check 2: UV command available in PATH
    if command_exists "uv"; then
        log "SUCCESS" "✓ UV command available in PATH"
    else
        log "WARNING" "⚠ UV not in current PATH (restart terminal to update)"
    fi

    # Check 3: UV version check
    if verify_uv_version; then
        local uv_version
        uv_version=$(uv --version 2>/dev/null || echo "unknown")
        log "SUCCESS" "✓ UV version: $uv_version"
    else
        log "ERROR" "✗ UV version check failed"
        all_checks_passed=false
    fi

    # Check 4: Constitutional compliance
    log "INFO" "Checking constitutional compliance..."
    local conflicts_found=0

    for manager in "${PYTHON_CONFLICTING_MANAGERS[@]}"; do
        if command_exists "$manager"; then
            log "WARNING" "⚠ Conflicting package manager still present: $manager"
            conflicts_found=1
        fi
    done

    if [ $conflicts_found -eq 0 ]; then
        log "SUCCESS" "✓ No conflicting package managers detected"
    else
        log "WARNING" "⚠ Conflicting package managers detected (consider removing)"
    fi

    # Final verdict
    if [ "$all_checks_passed" = true ]; then
        log "SUCCESS" "════════════════════════════════════════"
        log "SUCCESS" "✓ UV installation verified successfully"
        log "SUCCESS" "════════════════════════════════════════"
        log "INFO" ""
        log "INFO" "Next steps:"
        log "INFO" "  1. Restart terminal or run: source ~/.zshrc (or ~/.bashrc)"
        log "INFO" "  2. Verify: uv --version"
        log "INFO" "  3. Usage: uv pip install <package>"
        log "INFO" "  4. Documentation: https://github.com/astral-sh/uv"
        log "INFO" ""
        log "INFO" "Constitutional Compliance:"
        log "INFO" "  ✓ UV EXCLUSIVE Python package manager"
        log "INFO" "  ✓ pip/poetry/pipenv usage PROHIBITED"
        exit 0
    else
        log "ERROR" "✗ UV installation verification failed"
        log "ERROR" "  Check logs for errors and retry installation"
        exit 1
    fi
}

main "$@"
