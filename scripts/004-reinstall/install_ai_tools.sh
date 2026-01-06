#!/bin/bash
# install_ai_tools.sh - Install ALL Local AI CLI Tools (non-interactive)
# Installs all 3 tools automatically - no user selection needed
# Claude Code: curl installer (https://claude.ai/install.sh)
# Gemini CLI: npm install -g @google/gemini-cli
# GitHub Copilot: npm install -g @github/copilot

source "$(dirname "$0")/../006-logs/logger.sh"

# Ensure fnm environment is loaded
if command -v fnm &> /dev/null; then
    eval "$(fnm env --use-on-cd 2>/dev/null)" || true
fi

# Ensure npm global bin is in PATH
if command -v npm &> /dev/null; then
    NPM_BIN=$(npm config get prefix 2>/dev/null)/bin
    export PATH="$NPM_BIN:$PATH"
fi

log "INFO" "Installing ALL AI CLI tools (Claude, Gemini, Copilot)..."

# Install Claude Code (official curl installer)
install_claude() {
    echo ""
    log "INFO" "Installing Claude Code..."
    # Remove old npm version if exists
    npm uninstall -g @anthropic-ai/claude-code 2>/dev/null || true
    # Use official installer script
    if curl -fsSL https://claude.ai/install.sh | bash; then
        log "SUCCESS" "Claude Code installed successfully."
        echo "  Run 'claude' to authenticate with Anthropic."
    else
        log "ERROR" "Failed to install Claude Code."
    fi
}

# Install Gemini CLI (npm package @google/gemini-cli)
install_gemini() {
    echo ""
    log "INFO" "Installing Gemini CLI..."
    # Remove old incorrect package if exists
    npm uninstall -g @google/generative-ai-cli 2>/dev/null || true
    if npm install -g @google/gemini-cli@latest; then
        log "SUCCESS" "Gemini CLI installed successfully."
        echo "  Run 'gemini' to start."
    else
        log "ERROR" "Failed to install Gemini CLI."
    fi
}

# Install GitHub Copilot CLI (npm package @github/copilot)
install_copilot() {
    echo ""
    log "INFO" "Installing GitHub Copilot CLI..."
    # Remove old gh extension if exists
    if command -v gh &> /dev/null && gh extension list 2>/dev/null | grep -q "copilot"; then
        log "INFO" "Removing old gh extension..."
        gh extension remove gh-copilot 2>/dev/null || true
    fi
    if npm install -g @github/copilot@latest; then
        log "SUCCESS" "GitHub Copilot CLI installed successfully."
        echo "  Run 'copilot' and use /login to authenticate."
    else
        log "ERROR" "Failed to install GitHub Copilot CLI."
    fi
}

# Install all 3 tools (non-interactive - TUI already selected "AI Tools")
# No user choice needed - always install all tools
install_claude
install_gemini
install_copilot

echo ""
log "SUCCESS" "AI CLI tools installation complete."

# Show shell reload instructions (from logger.sh utility)
show_shell_reload_instructions

echo "Next steps:"
echo "  - Claude Code: Run 'claude' to authenticate with Anthropic"
echo "  - Gemini CLI: Run 'gemini' (uses Google account)"
echo "  - Copilot: Run 'copilot' and use /login to authenticate with GitHub"
echo ""
echo "Verify installation: Run 'claude --version' to test"
