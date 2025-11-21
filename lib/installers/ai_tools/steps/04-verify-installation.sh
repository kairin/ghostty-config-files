#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

main() {
    log "INFO" "Verifying AI tools installation..."

    local tools_to_check=()

    if verify_claude_cli; then
        local claude_version=$(claude --version 2>/dev/null || echo "unknown")
        log "SUCCESS" "✓ Claude CLI: $claude_version"
        tools_to_check+=("@anthropic-ai/claude-code")
    else
        log "WARNING" "⚠ Claude CLI not found"
    fi

    if verify_gemini_cli; then
        local gemini_version=$(gemini --version 2>/dev/null || echo "unknown")
        log "SUCCESS" "✓ Gemini CLI: $gemini_version"
        tools_to_check+=("@google/gemini-cli")
    else
        log "WARNING" "⚠ Gemini CLI not found"
    fi

    if verify_copilot_cli; then
        log "SUCCESS" "✓ GitHub Copilot CLI installed"
        tools_to_check+=("@github/copilot")
    else
        log "INFO" "  GitHub Copilot CLI not installed (optional)"
    fi

    # Check for npm package updates (Priority 1: Version Detection)
    if [ ${#tools_to_check[@]} -gt 0 ] && command -v npm &>/dev/null; then
        log "INFO" "Checking for AI tool updates..."

        for tool in "${tools_to_check[@]}"; do
            local current_version latest_version

            # Get currently installed version
            current_version=$(npm list -g "$tool" 2>/dev/null | grep -oP "$tool@\K[0-9.]+" | head -1)

            # Get latest available version
            if latest_version=$(npm view "$tool" version 2>/dev/null); then
                if [ -n "$current_version" ] && [ -n "$latest_version" ]; then
                    if version_greater "$latest_version" "$current_version"; then
                        log "WARNING" "Update available for $tool: v$latest_version (installed: v$current_version)"
                        log "INFO" "Update: npm install -g $tool@latest"
                    else
                        log "SUCCESS" "✓ $tool is up-to-date (v$current_version)"
                    fi
                fi
            else
                log "INFO" "Could not check updates for $tool (network unavailable)"
            fi
        done
    fi
    
    log "SUCCESS" "════════════════════════════════════════"
    log "SUCCESS" "✓ AI tools installation complete"
    log "SUCCESS" "════════════════════════════════════════"
    log "INFO" "Next steps:"
    log "INFO" "  1. Claude Code: claude"
    log "INFO" "  2. Gemini CLI: gemini"
    log "INFO" "  3. GitHub Copilot: github-copilot-cli"
    exit 0
}

main "$@"
