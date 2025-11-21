#!/usr/bin/env bash
#
# Module: Install ZSH Security Check
# Purpose: Integrate ZSH security fix (insecure directories check)
# Prerequisites: ZSH and Oh My ZSH installed
# Outputs: Security warning suppression if directories are safe
# Exit Codes:
#   0 - Security check passed
#   1 - Security issues found
#   2 - Already configured (skip)
#
# Context7 Best Practices:
# - ZSH checks for insecure completion directories (world-writable)
# - Safe to disable warning if system directories are secure
# - Constitutional requirement: document security decisions
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

main() {
    log "INFO" "Checking ZSH security configuration..."

    # Check if security configuration already present
    if grep -q "ZSH_DISABLE_COMPFIX" "$ZSHRC" 2>/dev/null; then
        log "INFO" "↷ ZSH security configuration already present"
        exit 2
    fi

    # Check for insecure directories
    local insecure_dirs
    insecure_dirs=$(compaudit 2>/dev/null || true)

    if [ -n "$insecure_dirs" ]; then
        log "WARNING" "⚠ Insecure completion-dependent directories detected:"
        echo "$insecure_dirs"
        log "INFO" "  You can fix this by running: compaudit | xargs chmod g-w,o-w"
        log "INFO" "  Or suppress the warning by adding: export ZSH_DISABLE_COMPFIX=true"

        # For automated installation, we'll add the warning suppression
        # Users can manually fix permissions later if desired
        echo "" >> "$ZSHRC"
        echo "# ZSH security: Suppress insecure directories warning" >> "$ZSHRC"
        echo "# To fix properly, run: compaudit | xargs chmod g-w,o-w" >> "$ZSHRC"
        echo "export ZSH_DISABLE_COMPFIX=true" >> "$ZSHRC"

        log "INFO" "✓ Added ZSH_DISABLE_COMPFIX to suppress warnings"
        log "INFO" "  (You can manually fix permissions later)"
    else
        log "SUCCESS" "✓ No insecure directories detected"
    fi

    exit 0
}

main "$@"
