#!/usr/bin/env bash
#
# scripts/.template.sh - Template for new scripts
#
# This script demonstrates how to use the modular system.
# Copy this file to create new scripts in the scripts/ directory.
#

set -euo pipefail

# ═════════════════════════════════════════════════════════════
# BOOTSTRAP
# ═════════════════════════════════════════════════════════════

# Source the core bootstrap script
# This handles repo discovery, library sourcing, and initialization
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/../lib/init.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../lib/init.sh"
else
    # Fallback for running from random directories if git is available
    source "$(git rev-parse --show-toplevel)/lib/init.sh"
fi

# ═════════════════════════════════════════════════════════════
# MAIN LOGIC
# ═════════════════════════════════════════════════════════════

main() {
    # 1. Verify environment (optional but recommended)
    if ! run_environment_checks; then
        log "ERROR" "Environment checks failed."
        exit 1
    fi

    # 2. Use TUI features
    show_box "Script Title" "Description of what this script does."

    # 3. Your logic here
    log "INFO" "Starting task..."
    
    if show_confirm "Do you want to proceed?"; then
        show_spinner "Working..." "sleep 2"
        log "SUCCESS" "Task completed successfully."
    else
        log "WARNING" "Task cancelled by user."
    fi
}

main "$@"
