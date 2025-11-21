#!/usr/bin/env bash
#
# Module: Python UV Prerequisites Check
# Purpose: Check if UV is already installed and warn about conflicting package managers
# Prerequisites: None
# Outputs: Exit code 0 if UV not installed, 2 if already installed
# Exit Codes:
#   0 - UV not installed (proceed with installation)
#   1 - Error checking
#   2 - Already installed (skip)
#
# Context7 Best Practices:
# - UV is the modern Python package manager (Astral Systems)
# - Constitutional requirement: UV EXCLUSIVE (no pip/poetry/pipenv allowed)
# - Check for conflicts before installation
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

main() {
    log "INFO" "Checking Python UV prerequisites..."

    # Idempotency check
    if verify_python_uv; then
        local uv_version
        uv_version=$(uv --version 2>/dev/null || echo "unknown")
        log "INFO" "↷ UV already installed: $uv_version"
        exit 2
    fi

    # Check for conflicting package managers (warnings only)
    log "INFO" "Checking for conflicting package managers..."
    local conflicts_found=0

    for manager in "${PYTHON_CONFLICTING_MANAGERS[@]}"; do
        if command_exists "$manager"; then
            log "WARNING" "⚠ Conflicting package manager detected: $manager"
            log "WARNING" "  Constitutional requirement: UV EXCLUSIVE"
            log "WARNING" "  Recommendation: Uninstall $manager to avoid conflicts"
            conflicts_found=1
        fi
    done

    if [ $conflicts_found -eq 0 ]; then
        log "SUCCESS" "✓ No conflicting package managers detected"
    else
        log "INFO" ""
        log "INFO" "Constitutional Compliance Note:"
        log "INFO" "  - UV is the EXCLUSIVE Python package manager for this project"
        log "INFO" "  - pip/poetry/pipenv usage is PROHIBITED"
        log "INFO" "  - To remove conflicts: sudo apt remove python3-pip python3-poetry"
    fi

    log "SUCCESS" "✓ Prerequisites check passed - UV installation needed"
    exit 0
}

main "$@"
