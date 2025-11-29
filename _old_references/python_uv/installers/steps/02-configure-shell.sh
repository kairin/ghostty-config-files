#!/usr/bin/env bash
#
# Module: Configure Shell Integration
# Purpose: Add UV to PATH and configure shell completion
# Prerequisites: UV installed
# Outputs: Updated .zshrc/.bashrc with UV configuration
# Exit Codes:
#   0 - Configuration successful
#   1 - Configuration failed
#   2 - Already configured (skip)
#
# Context7 Best Practices:
# - Add ~/.local/bin to PATH if not present
# - Enable shell completion for better UX
# - Support both ZSH and Bash
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

main() {
    log "INFO" "Configuring shell integration..."

    # Add UV to PATH for each shell RC file
    for rc_file in "$HOME/.zshrc" "$HOME/.bashrc"; do
        if [ ! -f "$rc_file" ]; then
            continue
        fi

        # Check if UV already in PATH
        if grep -q "\.local/bin.*uv" "$rc_file" 2>/dev/null; then
            log "INFO" "  ↷ UV already in PATH ($rc_file)"
        else
            echo "" >> "$rc_file"
            echo "# UV (Astral Python package manager)" >> "$rc_file"
            echo "export PATH=\"${UV_BIN_DIR}:\$PATH\"" >> "$rc_file"
            log "INFO" "  ✓ Added UV to PATH in $rc_file"
        fi

        # Add shell completion (if supported)
        if command_exists "uv" && uv --help | grep -q "completion" 2>/dev/null; then
            if ! grep -q "uv.*completion" "$rc_file" 2>/dev/null; then
                echo "" >> "$rc_file"
                echo "# UV shell completion" >> "$rc_file"

                if [[ "$rc_file" == *".zshrc" ]]; then
                    echo 'eval "$(uv completion zsh)"' >> "$rc_file"
                else
                    echo 'eval "$(uv completion bash)"' >> "$rc_file"
                fi

                log "INFO" "  ✓ Added UV completion to $rc_file"
            fi
        fi
    done

    log "SUCCESS" "✓ Shell integration configured"
    exit 0
}

main "$@"
