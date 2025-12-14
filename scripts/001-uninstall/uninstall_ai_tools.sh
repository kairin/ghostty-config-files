#!/bin/bash
# uninstall_ai_tools.sh - Uninstall Local AI CLI Tools
# Claude Code: installed via curl script to ~/.claude/
# Gemini CLI: npm package @google/gemini-cli
# GitHub Copilot: npm package @github/copilot

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

log "INFO" "Uninstalling AI CLI tools..."

# Uninstall Claude Code (installed via curl script)
if command -v claude &> /dev/null; then
    log "INFO" "Removing Claude Code..."
    # Claude Code installs to ~/.claude/ - remove the directory
    rm -rf "$HOME/.claude" 2>/dev/null || true
    # Also remove old npm version if exists
    npm uninstall -g @anthropic-ai/claude-code 2>/dev/null || true
    # Remove from PATH additions in shell rc files
    sed -i '/\.claude/d' "$HOME/.bashrc" 2>/dev/null || true
    sed -i '/\.claude/d' "$HOME/.zshrc" 2>/dev/null || true
    log "SUCCESS" "Claude Code removed."
else
    log "INFO" "Claude Code not installed."
fi

# Uninstall Gemini CLI (npm package)
if command -v gemini &> /dev/null; then
    log "INFO" "Removing Gemini CLI..."
    npm uninstall -g @google/gemini-cli 2>/dev/null || true
    # Also remove old incorrect package if exists
    npm uninstall -g @google/generative-ai-cli 2>/dev/null || true
    log "SUCCESS" "Gemini CLI removed."
else
    log "INFO" "Gemini CLI not installed."
fi

# Uninstall GitHub Copilot CLI (npm package)
if command -v copilot &> /dev/null; then
    log "INFO" "Removing GitHub Copilot CLI..."
    npm uninstall -g @github/copilot 2>/dev/null || true
    log "SUCCESS" "GitHub Copilot CLI removed."
else
    log "INFO" "GitHub Copilot CLI not installed."
fi

# Also remove old gh extension if exists
if command -v gh &> /dev/null && gh extension list 2>/dev/null | grep -q "copilot"; then
    log "INFO" "Removing old gh copilot extension..."
    gh extension remove gh-copilot 2>/dev/null || true
    log "SUCCESS" "Old gh extension removed."
fi

echo ""
log "SUCCESS" "AI CLI tools uninstallation complete."
