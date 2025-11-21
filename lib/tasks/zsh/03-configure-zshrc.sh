#!/usr/bin/env bash
#
# Module: Configure .zshrc
# Purpose: Configure ZSH plugins and dircolors in .zshrc
# Prerequisites: Oh My ZSH installed, plugins installed
# Outputs: Updated $HOME/.zshrc with plugin configuration
# Exit Codes:
#   0 - Configuration successful
#   1 - Configuration failed
#   2 - Already configured (skip)
#
# Context7 Best Practices:
# - Preserve existing user customizations
# - Use sed for idempotent configuration updates
# - XDG-compliant dircolors loading
# - Enable recommended plugins for productivity
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

main() {
    log "INFO" "Configuring .zshrc..."

    # Verify prerequisites
    if ! verify_zshrc_exists; then
        log "ERROR" "✗ .zshrc not found - Oh My ZSH installation may have failed"
        exit 1
    fi

    # Configure plugins in .zshrc
    local plugins_line="plugins=(${RECOMMENDED_PLUGINS[*]})"

    if grep -q "^plugins=(" "$ZSHRC"; then
        # Check if already configured with recommended plugins
        if grep -q "plugins=(git docker kubectl zsh-autosuggestions zsh-syntax-highlighting)" "$ZSHRC"; then
            log "INFO" "↷ Plugins already configured in .zshrc"
        else
            # Update existing plugins line
            log "INFO" "  Updating plugins configuration..."
            sed -i.bak "s/^plugins=(.*)/plugins=(${RECOMMENDED_PLUGINS[*]})/" "$ZSHRC"
            log "SUCCESS" "  ✓ Plugins configuration updated"
        fi
    else
        # Add plugins line if missing
        log "INFO" "  Adding plugins configuration..."
        echo "" >> "$ZSHRC"
        echo "# Plugins (configured by installation script)" >> "$ZSHRC"
        echo "$plugins_line" >> "$ZSHRC"
        log "SUCCESS" "  ✓ Plugins configuration added"
    fi

    # Configure dircolors (XDG-compliant)
    local dircolors_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
    local dircolors_file="${dircolors_config_dir}/dircolors"
    local dircolors_line='eval "$(dircolors ${XDG_CONFIG_HOME:-$HOME/.config}/dircolors)"'

    if [ -f "$dircolors_file" ]; then
        if ! grep -q "dircolors.*XDG_CONFIG_HOME" "$ZSHRC" 2>/dev/null; then
            log "INFO" "  Adding XDG-compliant dircolors configuration..."
            echo "" >> "$ZSHRC"
            echo "# XDG-compliant dircolors configuration" >> "$ZSHRC"
            echo "$dircolors_line" >> "$ZSHRC"
            log "SUCCESS" "  ✓ Dircolors configuration added"
        else
            log "INFO" "  ↷ Dircolors already configured"
        fi
    else
        log "INFO" "  Dircolors file not found at $dircolors_file"
        log "INFO" "  Will be deployed by main installation script"
    fi

    log "SUCCESS" "✓ .zshrc configured successfully"
    log "INFO" "  Plugins enabled: ${RECOMMENDED_PLUGINS[*]}"
    exit 0
}

main "$@"
