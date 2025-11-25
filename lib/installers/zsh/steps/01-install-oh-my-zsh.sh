#!/usr/bin/env bash
#
# Module: Install Oh My ZSH Framework
# Purpose: Download and install Oh My ZSH framework (if not already installed)
# Prerequisites: ZSH installed, internet connection
# Outputs: $HOME/.oh-my-zsh/ directory with Oh My ZSH framework
# Exit Codes:
#   0 - Installation successful
#   1 - Installation failed
#   2 - Already installed (skip)
#
# Context7 Best Practices:
# - Official installer from ohmyz.sh
# - Non-interactive installation (--unattended flag)
# - Automatic .zshrc creation and configuration
# - Backup existing .zshrc before installation
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

main() {
    log "INFO" "Installing Oh My ZSH framework..."

    # Idempotency check
    if verify_oh_my_zsh_installed; then
        log "INFO" "↷ Oh My ZSH already installed at $OH_MY_ZSH_DIR"
        exit 2
    fi

    # Backup existing .zshrc
    if [ -f "$ZSHRC" ]; then
        local backup_file
        backup_file="${ZSHRC}.backup-$(date +%Y%m%d-%H%M%S)"
        cp "$ZSHRC" "$backup_file"
        log "INFO" "✓ Backed up existing .zshrc to $backup_file"
    fi

    # Download and run official installer (non-interactive)
    log "INFO" "Downloading Oh My ZSH installer..."

    if ! sh -c "$(curl -fsSL "$OH_MY_ZSH_URL")" "" --unattended 2>&1 | tee -a "$(get_log_file)"; then
        log "ERROR" "✗ Oh My ZSH installation failed"
        log "ERROR" "  Check internet connection and GitHub access"
        log "ERROR" "  Manual installation: https://ohmyz.sh/"
        exit 1
    fi

    # Verify installation
    if ! verify_oh_my_zsh_installed; then
        log "ERROR" "✗ Oh My ZSH directory not created after installation"
        exit 1
    fi

    log "SUCCESS" "✓ Oh My ZSH installed successfully at $OH_MY_ZSH_DIR"
    exit 0
}

main "$@"
