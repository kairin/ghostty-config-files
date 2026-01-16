#!/bin/bash
# update_ai_tools.sh - Update AI CLI tools in-place
#
# Updates:
# - Claude Code (standalone binary via curl)
# - Gemini CLI (npm global package)
# - GitHub Copilot CLI (npm global package)
#
# This script uses npm update instead of uninstall/reinstall to preserve configs

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../006-logs/logger.sh"

# Initialize fnm for npm access
FNM_PATH="$HOME/.local/share/fnm"
if [[ -d "$FNM_PATH" ]]; then
    export PATH="$FNM_PATH:$PATH"
    eval "$(fnm env --use-on-cd 2>/dev/null)"
fi

# Ensure npm global bin is in PATH
if command -v npm &> /dev/null; then
    NPM_BIN=$(npm config get prefix 2>/dev/null)/bin
    export PATH="$NPM_BIN:$PATH"
fi

UPDATED=0

# Update Claude Code (standalone binary)
if command -v claude &> /dev/null; then
    log "INFO" "Updating Claude Code..."
    CLAUDE_BEFORE=$(claude --version 2>/dev/null | head -n 1)

    # Re-run installer (idempotent, updates in-place)
    if curl -fsSL https://claude.ai/install.sh | bash; then
        CLAUDE_AFTER=$(claude --version 2>/dev/null | head -n 1)
        log "SUCCESS" "Claude Code: $CLAUDE_BEFORE -> $CLAUDE_AFTER"
        UPDATED=$((UPDATED + 1))
    else
        log "WARNING" "Claude Code update failed"
    fi
else
    log "INFO" "Claude Code not installed, skipping"
fi

# Update npm-based tools
if command -v npm &> /dev/null; then
    # Update Gemini CLI
    if npm list -g @google/gemini-cli &> /dev/null; then
        log "INFO" "Updating Gemini CLI..."
        GEMINI_BEFORE=$(gemini --version 2>/dev/null | head -n 1)

        if npm update -g @google/gemini-cli 2>/dev/null || npm install -g @google/gemini-cli@latest; then
            GEMINI_AFTER=$(gemini --version 2>/dev/null | head -n 1)
            log "SUCCESS" "Gemini CLI: $GEMINI_BEFORE -> $GEMINI_AFTER"
            UPDATED=$((UPDATED + 1))
        else
            log "WARNING" "Gemini CLI update failed"
        fi
    else
        log "INFO" "Gemini CLI not installed, skipping"
    fi

    # Update GitHub Copilot CLI
    if npm list -g @github/copilot &> /dev/null; then
        log "INFO" "Updating GitHub Copilot CLI..."
        COPILOT_BEFORE=$(copilot --version 2>/dev/null | head -n 1)

        if npm update -g @github/copilot 2>/dev/null || npm install -g @github/copilot@latest; then
            COPILOT_AFTER=$(copilot --version 2>/dev/null | head -n 1)
            log "SUCCESS" "GitHub Copilot: $COPILOT_BEFORE -> $COPILOT_AFTER"
            UPDATED=$((UPDATED + 1))
        else
            log "WARNING" "GitHub Copilot update failed"
        fi
    else
        log "INFO" "GitHub Copilot not installed, skipping"
    fi
else
    log "WARNING" "npm not available, skipping npm-based tools"
fi

if [[ $UPDATED -gt 0 ]]; then
    log "SUCCESS" "Updated $UPDATED AI tool(s)"
else
    log "INFO" "No AI tools were updated"
fi
