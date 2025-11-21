#!/usr/bin/env bash
#
# Module: Install ZSH Plugins
# Purpose: Install external ZSH plugins (autosuggestions, syntax-highlighting)
# Prerequisites: Oh My ZSH installed, git available
# Outputs: Plugins installed in $ZSH_CUSTOM/plugins/
# Exit Codes:
#   0 - Installation successful
#   1 - Installation failed
#   2 - Already installed (skip)
#
# Context7 Best Practices:
# - zsh-autosuggestions: Fish-like autosuggestions for ZSH
# - zsh-syntax-highlighting: Syntax highlighting for commands
# - Git clone with --depth 1 for faster installation
# - Idempotent installation (skip if already present)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

install_plugin() {
    local plugin_name="$1"
    local plugin_repo="$2"
    local plugin_dir="${ZSH_CUSTOM}/plugins/${plugin_name}"

    if [ -d "$plugin_dir" ]; then
        log "INFO" "  ↷ Plugin '$plugin_name' already installed"
        return 0
    fi

    log "INFO" "  Installing plugin: $plugin_name..."

    if ! git clone --depth 1 "$plugin_repo" "$plugin_dir" 2>&1 | tee -a "$(get_log_file)"; then
        log "WARNING" "  ✗ Failed to install plugin '$plugin_name'"
        return 1
    fi

    log "SUCCESS" "  ✓ Plugin '$plugin_name' installed"
    return 0
}

main() {
    log "INFO" "Installing ZSH plugins..."

    # Verify prerequisites
    if ! verify_oh_my_zsh_installed; then
        log "ERROR" "✗ Oh My ZSH not installed - cannot install plugins"
        exit 1
    fi

    # Install external plugins
    local all_installed=true

    install_plugin "zsh-autosuggestions" "$PLUGIN_AUTOSUGGESTIONS_REPO" || all_installed=false
    install_plugin "zsh-syntax-highlighting" "$PLUGIN_SYNTAX_HIGHLIGHTING_REPO" || all_installed=false

    if [ "$all_installed" = true ]; then
        log "SUCCESS" "✓ All ZSH plugins installed successfully"
        exit 0
    else
        log "WARNING" "⚠ Some plugins failed to install (non-fatal)"
        exit 0  # Non-fatal - continue installation
    fi
}

main "$@"
