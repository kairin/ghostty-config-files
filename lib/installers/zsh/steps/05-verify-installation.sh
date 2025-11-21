#!/usr/bin/env bash
#
# Module: Verify ZSH Installation
# Purpose: Comprehensive verification that ZSH + Oh My ZSH is properly configured
# Prerequisites: All previous ZSH installation steps completed
# Outputs: Verification report and next steps
# Exit Codes:
#   0 - Verification successful
#   1 - Verification failed
#
# Context7 Best Practices:
# - Test ZSH version and availability
# - Verify Oh My ZSH framework installation
# - Check .zshrc configuration
# - Verify plugins are installed
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

main() {
    log "INFO" "Verifying ZSH installation..."

    local all_checks_passed=true

    # Check 1: ZSH binary
    if verify_zsh_installed; then
        local zsh_version
        zsh_version=$(zsh --version 2>&1 | head -n 1)
        log "SUCCESS" "✓ ZSH installed: $zsh_version"
    else
        log "ERROR" "✗ ZSH not found"
        all_checks_passed=false
    fi

    # Check 2: Oh My ZSH framework
    if verify_oh_my_zsh_installed; then
        log "SUCCESS" "✓ Oh My ZSH installed at $OH_MY_ZSH_DIR"
    else
        log "ERROR" "✗ Oh My ZSH not found"
        all_checks_passed=false
    fi

    # Check 3: .zshrc configuration
    if verify_zshrc_exists; then
        log "SUCCESS" "✓ .zshrc exists at $ZSHRC"

        # Check plugins configuration
        if grep -q "plugins=(git docker kubectl zsh-autosuggestions zsh-syntax-highlighting)" "$ZSHRC"; then
            log "SUCCESS" "✓ Plugins configured in .zshrc"
        else
            log "WARNING" "⚠ Plugins may not be fully configured"
        fi
    else
        log "ERROR" "✗ .zshrc not found"
        all_checks_passed=false
    fi

    # Check 4: External plugins
    for plugin in "zsh-autosuggestions" "zsh-syntax-highlighting"; do
        if verify_plugin_installed "$plugin"; then
            log "SUCCESS" "✓ Plugin '$plugin' installed"
        else
            log "WARNING" "⚠ Plugin '$plugin' not found (non-fatal)"
        fi
    done

    # Check 5: Default shell
    local current_shell
    current_shell=$(basename "$SHELL")
    if [ "$current_shell" = "zsh" ]; then
        log "SUCCESS" "✓ ZSH is the default shell"
    else
        log "INFO" "  Current shell: $current_shell"
        log "INFO" "  To set ZSH as default: chsh -s \$(which zsh)"
    fi

    # Final verdict
    if [ "$all_checks_passed" = true ]; then
        log "SUCCESS" "════════════════════════════════════════"
        log "SUCCESS" "✓ ZSH installation verified successfully"
        log "SUCCESS" "════════════════════════════════════════"
        log "INFO" ""
        log "INFO" "Next steps:"
        log "INFO" "  1. Restart terminal or run: source ~/.zshrc"
        log "INFO" "  2. (Optional) Set ZSH as default: chsh -s \$(which zsh)"
        log "INFO" "  3. Logout and login for default shell change to take effect"
        exit 0
    else
        log "ERROR" "✗ ZSH installation verification failed"
        log "ERROR" "  Check logs for errors and retry installation"
        exit 1
    fi
}

main "$@"
