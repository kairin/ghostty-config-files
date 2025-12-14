#!/bin/bash
# uninstall_ai_tools.sh - Uninstall Local AI CLI Tools

# Ensure npm global bin is in PATH
if command -v npm &> /dev/null; then
    NPM_BIN=$(npm config get prefix 2>/dev/null)/bin
    export PATH="$NPM_BIN:$PATH"
fi

# Also ensure fnm-managed Node.js is available
if command -v fnm &> /dev/null; then
    eval "$(fnm env --shell bash 2>/dev/null)" || true
fi

echo "Uninstalling AI CLI tools..."

# Uninstall Claude Code
if command -v claude &> /dev/null; then
    echo "Removing Claude Code..."
    npm uninstall -g @anthropic-ai/claude-code 2>/dev/null || true
    echo "Claude Code removed."
else
    echo "Claude Code not installed."
fi

# Uninstall Gemini CLI
if command -v gemini &> /dev/null; then
    echo "Removing Gemini CLI..."
    npm uninstall -g @google/generative-ai-cli 2>/dev/null || true
    echo "Gemini CLI removed."
else
    echo "Gemini CLI not installed."
fi

# Uninstall GitHub Copilot CLI (gh extension)
if command -v gh &> /dev/null && gh extension list 2>/dev/null | grep -q "copilot"; then
    echo "Removing GitHub Copilot CLI..."
    gh extension remove gh-copilot 2>/dev/null || true
    echo "GitHub Copilot CLI removed."
else
    echo "GitHub Copilot CLI not installed."
fi

echo ""
echo "AI CLI tools uninstallation complete."
