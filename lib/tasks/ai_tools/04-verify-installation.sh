#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

main() {
    log "INFO" "Verifying AI tools installation..."
    
    if verify_claude_cli; then
        local claude_version=$(claude --version 2>/dev/null || echo "unknown")
        log "SUCCESS" "✓ Claude CLI: $claude_version"
    else
        log "WARNING" "⚠ Claude CLI not found"
    fi
    
    if verify_gemini_cli; then
        local gemini_version=$(gemini --version 2>/dev/null || echo "unknown")
        log "SUCCESS" "✓ Gemini CLI: $gemini_version"
    else
        log "WARNING" "⚠ Gemini CLI not found"
    fi
    
    if verify_copilot_cli; then
        log "SUCCESS" "✓ GitHub Copilot CLI installed"
    else
        log "INFO" "  GitHub Copilot CLI not installed (optional)"
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
