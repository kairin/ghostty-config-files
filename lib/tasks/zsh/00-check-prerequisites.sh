#!/usr/bin/env bash
#
# Module: ZSH Prerequisites Check
# Purpose: Check if ZSH is installed and Oh My ZSH framework is already configured
# Prerequisites: None
# Outputs: Exit code 0 if ZSH available, 2 if already fully configured
# Exit Codes:
#   0 - ZSH installed, proceed with configuration
#   1 - ZSH not installed (error)
#   2 - Already fully configured (skip)
#
# Context7 Best Practices:
# - Ubuntu 25.10 includes ZSH by default
# - Oh My ZSH is idempotent-safe
# - Check for existing customizations before modification
#

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

main() {
    log "INFO" "Checking ZSH prerequisites..."

    # Check if already fully configured (idempotency)
    if verify_zsh_configured; then
        log "INFO" "↷ ZSH + Oh My ZSH already installed and configured"
        exit 2  # Skip code
    fi

    # Check if ZSH is installed
    if ! verify_zsh_installed; then
        log "ERROR" "✗ ZSH not found - installation required"
        exit 1
    fi

    local zsh_version
    zsh_version=$(zsh --version 2>&1 | head -n 1)
    log "INFO" "✓ ZSH installed: $zsh_version"

    # Check default shell
    local current_shell
    current_shell=$(basename "$SHELL")
    if [ "$current_shell" = "zsh" ]; then
        log "INFO" "✓ ZSH is already the default shell"
    else
        log "INFO" "  Current shell: $current_shell (can be changed with: chsh -s \$(which zsh))"
    fi

    log "SUCCESS" "✓ Prerequisites check passed - ZSH configuration needed"
    exit 0
}

main "$@"
